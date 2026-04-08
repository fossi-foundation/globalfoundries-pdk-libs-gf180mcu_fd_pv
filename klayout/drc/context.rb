# frozen_string_literal: true

module GF180DRC
  # Defines the context for DRC execution: the runtime options and generic layers
  class Context
    attr_reader :logger, :options, :raw, :derived, :drc

    def initialize(drc_engine:, logger:, options:)
      @drc = drc_engine
      @logger = logger
      @options = options
      @raw = {}
      @derived = {}
    end

    # Common option helpers
    def feol? = !!options[:feol]
    def beol? = !!options[:beol]
    def offgrid? = !!options[:offgrid]
    def split_deep? = !!options[:split_deep]
    def slow_via? = !!options[:slow_via]
    def antenna? = !!options[:antenna]
    def density? = !!options[:density]
    def connectivity? = !!options[:connectivity]
    def connectivity_rules = options[:connectivity_rules]
    def metal_level = options[:metal_level]
    def metal_top = options[:metal_top]
    def mim_option = options[:mim_option]
    def metal_level_numerical = options[:metal_level_numerical]
    def chip_area = options[:chip_area]

    # Extract polygons via KLayout DRC engine and store by symbol key
    def extract!(name, layer, datatype, merge)
      ps = @drc.polygons(layer, datatype)
      ps = ps.merged if merge
      raw[name.to_sym] = ps
    end

    # Derived layer memoization.
    # Use ctx.derive(:foo) { ctx[:bar].and(ctx[:baz]) }
    def derive(name, &block)
      key = name.to_sym
      return derived[key] if derived.key?(key)

      derived[key] = block.call
    end

    # Unified accessor: derived overrides raw.
    def [](name)
      key = name.to_sym
      return derived[key] if derived.key?(key)

      raw.fetch(key)
    end

    def key?(name)
      key = name.to_sym
      derived.key?(key) || raw.key?(key)
    end
  end
end
