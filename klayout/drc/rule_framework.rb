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

    def select(include_tags: nil, exclude_tags: nil, raise_on_empty: true)
      decks = include_decks(include_tags)
      decks = exclude_decks(decks, exclude_tags)
      validate_not_empty!(decks, include_tags) if raise_on_empty
      decks
    end

    private

    def include_decks(include_tags)
      return all unless filtering?(include_tags)

      warn_unknown_tags(include_tags)
      all.select { |d| (d.tags & include_tags).any? }
    end

    def exclude_decks(decks, exclude_tags)
      return decks unless filtering?(exclude_tags)

      warn_unknown_tags(exclude_tags)
      decks.reject { |d| (d.tags & exclude_tags).any? }
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
    class Parallel < Base
      def initialize(ctx, num_workers: 1)
        super(ctx)
        @num_workers = num_workers
        timestamp = Time.now.strftime('drc_run_%Y_%m_%d_%H_%M_%S__')
        @tmpdir = Dir.mktmpdir(timestamp)
      end

      def run(decks)
        logger.info("Starting DRC in isolated parallel mode: executing #{decks.size} deck(s).")
        _run(decks)
      end

      private

      def _run(decks)
        results = run_all(decks.dup)
        aggregate_results(results)
      ensure
        FileUtils.rm_rf(@tmpdir)
      end

      def run_all(queue)
        in_flight = {} # pid => result_pipe
        results = []

        until queue.empty? && in_flight.empty?
          # Spawn new workers up to the concurrency limit
          while in_flight.size < @num_workers && !queue.empty?
            deck = queue.shift
            pid, pipe = fork_worker(deck.id)
            in_flight[pid] = { pipe: pipe, id: deck.id }
          end

          # Wait for any one worker to finish
          pid, _status = Process.wait2
          worker = in_flight.delete(pid)
          results << collect_result(worker)
        end

        results
      end

      def fork_worker(id)
        result_r, result_w = IO.pipe

        pid = fork do
          result_r.close
          result = execute_deck(id)
          result_w.write(JSON.dump(result))
          result_w.close
          exit
        end

        result_w.close
        [pid, result_r]
      end

      def collect_result(worker)
        result = JSON.parse(worker[:pipe].read, symbolize_names: true)
        worker[:pipe].close
        result
      rescue StandardError => e
        { id: worker[:id], error: "Failed to read result: #{e.message}", timestamp: Time.now.iso8601 }
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
        logger.info("Executing deck : #{id}")
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
