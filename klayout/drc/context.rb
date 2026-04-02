# frozen_string_literal: true

module GF180DRC
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
end
