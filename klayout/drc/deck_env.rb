# frozen_string_literal: true

module GF180DRC
  # Provides access to the global drc function and generic layers without
  # the need for accessors
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
