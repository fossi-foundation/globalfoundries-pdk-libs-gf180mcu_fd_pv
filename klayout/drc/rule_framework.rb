# frozen_string_literal: true

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

  Deck = Struct.new(:id, :path, :tags, :code, keyword_init: true)

  # Registers all available drc checks. Could be extended to provide filtering
  class Registry
    def initialize
      @decks_by_id = {}
      @order = []
    end

    def register(id:, path:, tags: [], &code)
      raise ArgumentError, "register requires a block for deck '#{id}'" unless block_given?

      raise ArgumentError, "Deck #{id} has already been defined" if @decks_by_id.key?(id)

      @decks_by_id[id] = Deck.new(id: id, path: path, tags: tags, code: code)
      @order << id
    end

    def all
      @order.map { |id| @decks_by_id.fetch(id) }
    end

    # include_tags: array; match if any tag overlaps
    def select(include_tags: nil, raise_on_empty: true)
      decks = all

      decks = decks.select { |d| (d.tags & include_tags).any? } if include_tags && !include_tags.empty?

      if raise_on_empty && decks.empty?
        raise ArgumentError,
              'Deck selection matched no decks. ' \
              "Filters: include_tags=#{include_tags.inspect} " \
              "Available tags : #{all.map(&:tag).join(', ')}"
      end

      decks
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
  end
end
