# frozen_string_literal: true

require 'tmpdir'
require 'json'
require 'time'

module RuleFramework
  # Defines the context for DRC execution: the runtime options and generic layers
  class Context
    attr_reader :logger, :options, :drc

    def initialize(drc_engine:, logger:, options:)
      @drc = drc_engine
      @logger = logger
      @options = options
      @layers = {}
    end

    # Use ctx.register_layer(:foo) { ctx[:bar].and(ctx[:baz]) }
    def register_layer(name, &block)
      key = name.to_sym

      raise "Derived layer #{key} already defined" if @layers.key?(key)

      @layers[key] = block.call
    end

    def [](name)
      key = name.to_sym

      @layers[key]
    end

    def key?(name)
      key = name.to_sym

      @layers.key?(key)
    end
  end

  # Provides access to the global drc function and generic layers without
  # the need for accessors. It does not allow to add new entries to the layers,
  # but the object that is return could be theoretically edited.
  class DeckEnv
    attr_reader :ctx

    def initialize(ctx)
      @ctx = ctx
    end

    def drc = ctx.drc

    # Common “globals” from old style decks
    def logger = @ctx.logger

    def method_missing(name, *args, &block)
      # First: layer access (only for zero-arg calls)
      return ctx[name] if args.empty? && block.nil? && ctx.key?(name)

      # Second: delegate to KLayout DRC engine (polygons, extent, connect, euclidian, ...)
      return drc.public_send(name, *args, &block) if drc.respond_to?(name)

      super
    end

    def respond_to_missing?(name, include_private = false)
      ctx.key?(name) || drc.respond_to?(name) || super
    end
  end

  Deck = Struct.new(:id, :path, :priority, :tags, :code, keyword_init: true)

  # Registers all available drc checks. Could be extended to provide filtering
  class Registry
    def initialize
      @decks_by_id = {}
      @order = []
    end

    def register(id:, path:, priority:, tags: [], &code)
      raise ArgumentError, "register requires a block for deck '#{id}'" unless block_given?

      raise ArgumentError, "Deck #{id} has already been defined" if @decks_by_id.key?(id)

      @decks_by_id[id] = Deck.new(id: id, path: path, priority: priority, tags: tags, code: code)
      @order << id
    end

    def all
      @order
        .map { |id| @decks_by_id.fetch(id) }
        .sort_by { |d| [-(d.priority || 0), d.id.to_s] }
    end

    def select(include_tags: nil, raise_on_empty: true)
      decks = filter_decks(include_tags)
      validate_not_empty!(decks, include_tags) if raise_on_empty
      decks
    end

    private

    def filter_decks(include_tags)
      return all unless filtering?(include_tags)

      warn_unknown_tags(include_tags)
      all.select { |d| (d.tags & include_tags).any? }
    end

    def filtering?(include_tags)
      include_tags && !include_tags.empty?
    end

    def warn_unknown_tags(include_tags)
      available_tags = all.flat_map(&:tags).uniq
      unknown_tags = include_tags - available_tags
      warn "Warning: unknown tags: #{unknown_tags.join(', ')}" unless unknown_tags.empty?
    end

    def validate_not_empty!(decks, include_tags)
      return unless decks.empty?

      raise ArgumentError,
            'Deck selection matched no decks. ' \
            "Filters: include_tags=#{include_tags.inspect} " \
            "Available tags : #{all.map(&:tags).join(', ')}"
    end
  end

  module Runners
    # Provides the base for the runners.
    # Subclasses should implement #run(decks)
    class Base
      attr_reader :ctx

      def initialize(ctx)
        @ctx = ctx
      end

      def logger = ctx.logger
    end

    # Runs the deck one by one, single threaded.
    # There is theoretically a possibility of one rule poisoning
    # the environment of subsequent rules
    class Sequential < Base
      def run(decks)
        report('', ctx.options.report.to_s)

        logger.info("Starting DRC: executing #{decks.size} deck(s).")
        decks.each do |deck|
          run_deck(deck)
        end
      end

      private

      def run_deck(deck)
        logger.info("Executing deck #{deck.id} from #{deck.path}")

        # Maybe could be setup once as class variables for optimization?
        env = RuleFramework::DeckEnv.new(ctx)
        env.instance_exec(&deck.code)
      end
    end

    # Runs the decks in parallel in fully isolated environments
    class Parallel < Base # rubocop:disable Metrics/ClassLength
      def initialize(ctx, num_workers: 4)
        super(ctx)
        @num_workers = num_workers
        timestamp = Time.now.strftime('drc_run_%Y_%m_%d_%H_%M_%S__')
        @tmpdir = Dir.mktmpdir(timestamp)
      end

      def run(decks)
        logger.info("Starting DRC in parallel: executing #{decks.size} deck(s).")
        _run(decks)
      end

      private

      def _run(decks)
        all_workers, active_puppets = spawn_workers
        dispatch_queue(decks.dup, active_puppets)
        results = collect_results(all_workers)
        aggregate_results(results)
      ensure
        FileUtils.rm_rf(@tmpdir)
      end

      def spawn_workers
        all_workers = []
        active_puppets = []
        @num_workers.times do |i|
          worker = spawn_worker(i)
          all_workers << worker
          active_puppets << worker
        end
        [all_workers, active_puppets]
      end

      def spawn_worker(worker_idx)
        result_r, result_w = IO.pipe
        master_to_puppet_r, master_to_puppet_w = IO.pipe
        puppet_to_master_r, puppet_to_master_w = IO.pipe

        pid = fork do
          result_r.close
          master_to_puppet_w.close
          puppet_to_master_r.close
          run_worker_loop(worker_idx, master_to_puppet_r, puppet_to_master_w, result_w)
          exit
        end

        result_w.close
        master_to_puppet_r.close
        puppet_to_master_w.close

        { pid: pid, to_puppet: master_to_puppet_w, from_puppet: puppet_to_master_r, result_pipe: result_r }
      end

      def run_worker_loop(worker_idx, input, output, result_w)
        chunk_results = []
        output.puts 'ready'

        loop do
          task = input.gets&.chomp
          next sleep(0.01) if task.nil?
          break if task == 'shutdown'

          chunk_results << process_task(worker_idx, task)
          output.puts 'ready'
        end

        logger.info("Worker #{worker_idx}: Shutting down")
        result_w.write(JSON.dump(chunk_results))
        result_w.close
      end

      def process_task(worker_idx, task)
        logger.info("Worker #{worker_idx}: Processing deck #{task}")
        result = execute_deck(task)
        logger.info("Worker #{worker_idx}: Done processing #{task}")
        result
      rescue StandardError => e
        logger.info("Worker #{worker_idx}: Error processing #{task}: #{e.message}")
        { id: task, error: err.message, timestamp: Time.now.iso8601 }
      end

      def dispatch_queue(queue, active_puppets)
        while !queue.empty? || active_puppets.any?
          ready_pipes = IO.select(active_puppets.map { |p| p[:from_puppet] }, nil, nil, 0.05)&.first || []
          ready_pipes.each { |pipe| handle_ready_puppet(pipe, queue, active_puppets) }
        end
      end

      def handle_ready_puppet(pipe, queue, active_puppets)
        pipe.gets
        puppet = active_puppets.find { |p| p[:from_puppet] == pipe }

        if queue.empty?
          puppet[:to_puppet].puts 'shutdown'
          puppet[:to_puppet].flush
          active_puppets.delete(puppet)
        else
          puppet[:to_puppet].puts queue.shift.id
          puppet[:to_puppet].flush
        end
      end

      def collect_results(all_workers)
        all_workers.each_with_object([]) do |worker, results|
          chunk_results = JSON.parse(worker[:result_pipe].read, symbolize_names: true)
          results.concat(chunk_results)
          worker[:result_pipe].close
          Process.wait(worker[:pid])
        end
      end

      def aggregate_results(results)
        raise_on_errors(results)
        report = merge_reports(results)
        report.save(ctx.options.report)
        report
      end

      def raise_on_errors(results)
        errors = results.select { |r| r[:error] }
        return if errors.empty?

        errors.each { |err| logger.error("Deck #{err[:id]} failed: #{err[:error]}") }
        raise "DRC failed for decks: #{errors.map { |err| err[:id] }.join(', ')}"
      end

      def merge_reports(results)
        first, *rest = results
        aggregated = RBA::ReportDatabase.new
        aggregated.load(first[:result])

        rest.each do |element|
          incoming = RBA::ReportDatabase.new
          incoming.load(element[:result])
          aggregated = aggregated.merge(incoming)
        end

        aggregated
      end

      def execute_deck(id)
        report_location = File.join(@tmpdir, "#{id}.lyrdb")
        rep = ctx.drc.report("Report for #{id}", report_location)
        env = RuleFramework::DeckEnv.new(ctx)

        deck = ctx.options.decks.find { |d| d.id == id } or
          raise ArgumentError, "No deck found for id #{id}"

        begin
          env.instance_exec(&deck.code)
          rep.rdb.save(report_location)
          { id: id, result: report_location, timestamp: Time.now.iso8601 }
        rescue StandardError => e
          { id: id, error: e.message, timestamp: Time.now.iso8601 }
        end
      end
    end
  end
end
