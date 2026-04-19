# frozen_string_literal: true

# GF180-specific option parsing/normalization.

module GF180DRC
  # Provides access functions to options. This is used in the Option class,
  # and is expected to be used to extend the Context.
  module OptionHelpers
    def beol? = !!@options[:beol]
    def offgrid? = !!@options[:offgrid]
    def slow_via? = !!@options[:slow_via]
    def antenna? = !!@options[:antenna]
    def density? = !!@options[:density]
    def connectivity? = !!@options[:connectivity]

    def metal_level = @options[:metal_level]
    def metal_top = @options[:metal_top]
    def mim_option = @options[:mim_option]
    def metal_level_numerical = @options[:metal_level_numerical]

    def verbose? = !!@options[:verbose]
    def thr = @options[:thr]
    def run_mode = @options[:run_mode]
    def variant = @options[:variant]
    def decks = @options[:decks]

    def input = @options[:input]
    def report = @options[:report]
    def topcell = @options[:topcell]
  end

  # Handles resolution and validation of raw klayout parameters into
  # normalized values. Mixed into Options as private instance methods,
  # and also used as class methods via `extend`.
  module ParamResolution
    def merge_defaults_with_raw(raw_params)
      Options::DEFAULTS.each_with_object({}) do |(k, v), params|
        val = raw_params.key?(k) ? raw_params[k] : nil
        params[k] = val.nil? ? v : val
      end
    end

    def validate_and_normalize_input(input_str)
      raise ArgumentError, 'input is a required argument' unless input_str

      path = Pathname.new(File.expand_path(input_str))
      raise ArgumentError, "input file #{path} does not exist" unless path.exist?

      path
    end

    def resolve_report_path(report_param)
      if report_param
        Pathname.new(report_param)
      else
        layout_dir = Pathname.new(RBA::CellView.active.filename).parent.realpath
        layout_dir.join('gf180_drc.lyrdb').expand_path
      end
    end

    def resolve_variant_config(variant_key)
      Options::VARIANTS.fetch(variant_key) do
        raise ArgumentError,
              "Unknown GF180 variant #{variant_key.inspect}. Supported: #{Options::VARIANTS.keys.join(', ')}"
      end
    end

    def select_decks(registry, select_decks_param)
      if select_decks_param
        registry.select(include_tags: select_decks_param.split(','))
      else
        registry.all
      end
    end

    def calculate_threads(thr_param)
      (thr_param || Etc.nprocessors).to_i
    end

    def validate_metal_level(variant_level, override_level)
      final_level = override_level || variant_level
      metal_level_num = Options::METAL_LEVEL_MAP[final_level]

      unless metal_level_num
        raise ArgumentError,
              "Metal level not recognized: #{final_level.inspect}. " \
              "Supported: #{Options::METAL_LEVEL_MAP.keys.join(', ')}"
      end

      metal_level_num
    end
  end

  # Class-level factory helpers for building an Options from raw params.
  module Construction
    def bool?(input)
      input.to_s.downcase == 'true'
    end

    BOOLEAN_PARAMS = %i[beol offgrid slow_via antenna density verbose connectivity].freeze

    def resolved_booleans(base_params)
      BOOLEAN_PARAMS.to_h { |key| [key, bool?(base_params[key])] }
    end

    # Builds a normalized Options object from klayout `-rd` parameters.
    # `raw_params` is a hash of raw strings/values (e.g. `$variant`, etc.).
    def from_klayout_params(raw_params:, registry:)
      base_params = merge_defaults_with_raw(raw_params)
      variant_config = resolve_variant_config(base_params[:variant])

      params = {
        input: validate_and_normalize_input(base_params[:input]),
        report: resolve_report_path(base_params[:report]),
        variant: base_params[:variant],
        topcell: base_params[:topcell],
        run_mode: base_params[:run_mode],
        metal_level: variant_config[:metal_level],
        metal_top: variant_config[:metal_top],
        mim_option: variant_config[:mim_option],
        metal_level_numerical: validate_metal_level(variant_config[:metal_level], base_params[:metal_level]),
        thr: calculate_threads(base_params[:thr]),
        decks: select_decks(registry, base_params[:select_decks])
      }

      new(**params, **resolved_booleans(base_params)).freeze
    end
  end

  # Provides parsing of the command line options, and storing of the results
  class Options
    include OptionHelpers
    extend  Construction
    extend  ParamResolution

    # Defaults that apply when input is nil (or missing).
    DEFAULTS = {
      topcell: nil,
      input: nil,
      report: nil,

      connectivity: 'false',
      offgrid: 'false',
      beol: 'false',
      slow_via: 'false',
      antenna: 'false',
      density: 'false',
      verbose: 'false',

      # run control
      thr: nil,
      run_mode: 'deep',

      # technology selection
      variant: 'C',

      # Optional explicit overrides; nil means "use variant-provided default"
      mim_option: nil,
      metal_top: nil,
      metal_level: nil,

      select_decks: nil
    }.freeze

    VARIANTS = {
      'A' => { metal_top: '30K', mim_option: 'A', metal_level: '3LM' },
      'B' => { metal_top: '11K', mim_option: 'B', metal_level: '4LM' },
      'C' => { metal_top: '9K',  mim_option: 'B', metal_level: '5LM' },
      'D' => { metal_top: '11K', mim_option: 'B', metal_level: '5LM' },
      'E' => { metal_top: '9K',  mim_option: 'B', metal_level: '6LM' },
      'F' => { metal_top: '9K',  mim_option: 'A', metal_level: '6LM' }
    }.freeze

    METAL_LEVEL_MAP = {
      '2LM' => 2,
      '3LM' => 3,
      '4LM' => 4,
      '5LM' => 5,
      '6LM' => 6
    }.freeze

    def initialize(**options)
      @options = options
    end

    def [](name)
      @options[name.to_sym]
    end

    def log_to(logger)
      {
        'Input file' => input,
        'DRC Run Report' => report,
        'Connectivity enabled' => connectivity?,
        'MIM Option selected' => mim_option,
        'Offgrid enabled' => offgrid?,
        'BEOL enabled' => beol?,
        'Slow via enabled' => slow_via?,
        'antenna enabled' => antenna?,
        'density enabled' => density?,
        'Verbose enabled' => verbose?,
        'Threads for DRC functions' => thr,
        'Run mode' => run_mode,
        'metal_top selected' => metal_top,
        'metal_level selected' => metal_level,
        'Selected decks' => decks.map(&:id).join(', ')
      }.each { |label, value| logger.info("#{label}: #{value}") }
    end
  end
end
