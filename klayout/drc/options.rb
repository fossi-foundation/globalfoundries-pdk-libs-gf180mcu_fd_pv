# frozen_string_literal: true

# GF180-specific option parsing/normalization.

module GF180DRC
  # Provides access functions to options. This is used in the Option class,
  # and is expected to be used to extend the Context.
  module OptionHelpers
    def metal_level = @options[:metal_level]
    def metal_top = @options[:metal_top]
    def mim_option = @options[:mim_option]
    def metal_level_numerical = @options[:metal_level_numerical]

    def verbose? = !!@options[:verbose]
    def workers = @options[:workers]
    def threads = @options[:threads]
    def run_mode = @options[:run_mode]
    def variant = @options[:variant]
    def decks = @options[:decks]

    def input = @options[:input]
    def report = @options[:report]
    def topcell = @options[:topcell]
  end

  # Holds shared variables
  module Config
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

    ALLOWED_VALUES = {
      metal_level: METAL_LEVEL_MAP.keys,
      metal_top: %w[9K 11K 30K],
      mim_option: %w[A B],
      variant: VARIANTS.keys,
      run_mode: %w[deep flat tiling]
    }.freeze
  end

  # Builds and prints usage information derived from the canonical option
  # definitions in Config and Options::DEFAULTS.
  module Help
    OPTION_DOCS = {
      input: { required: true, desc: 'Path to the input GDS/OASIS layout file' },
      report: { required: false, desc: 'Path for the DRC report output file (.lyrdb format)' },
      topcell: { required: false, desc: 'Top cell name (default: auto-detect)' },
      run_mode: { required: false, desc: 'Execution mode' },
      verbose: { required: false, desc: 'Enable verbose output' },
      workers: { required: false, desc: 'Number of parallel workers. \'max\' for number of available cores' },
      threads: { required: false,
                 desc: 'Number of parallel threads to use in klayout DRC functions. ' \
                       '\'max\' for number of available cores' },
      variant: { required: false, desc: 'PDK variant; superseded by metal_level, metal_top, and mim_option' },
      metal_level: { required: false, desc: 'Metal stack configuration (default: from variant)' },
      metal_top: { required: false, desc: 'Top metal thickness (default: from variant)' },
      mim_option: { required: false, desc: 'MIM capacitor option (default: from variant)' },
      decks: { required: false,
               desc: 'Comma-separated list of decks to run. ' \
                     'A leading "-" means that matching decks should be excluded.  ' \
                     'Example: "-rd decks=all,-beol,metal1" means all except feol, but including metal1 decks. ' \
                     'If no non-negative tags are provided, all decks are included.' },
      help: { required: false, desc: 'Print this message and exit' }
    }.freeze

    def help_text
      [header_lines, option_lines, variant_lines, example_lines].flatten.join("\n")
    end

    private

    def header_lines
      [
        '',
        'GF180MCU KLayout DRC Rule Deck',
        '==============================',
        '',
        'Usage:',
        '  klayout -b -r gf180mcu.drc -rd input=<file> -rd report=<file> [options...]',
        '',
        'Options (* = required):'
      ]
    end

    def option_lines
      col = OPTION_DOCS.keys.map(&:length).max + 2
      OPTION_DOCS.map { |name, doc| format_option_line(name, doc, col) }
    end

    def format_option_line(name, doc, col)
      marker = doc[:required] ? '*' : ' '
      "  #{marker} #{name.to_s.ljust(col)}#{doc[:desc]}#{option_suffix(name, doc)}"
    end

    def option_suffix(name, doc)
      allowed = Config::ALLOWED_VALUES[name]
      default = Options::DEFAULTS[name]

      detail = []
      detail << "allowed: #{allowed.join(', ')}" if allowed
      detail << "default: #{default}"            if !default.nil? && !doc[:required]
      detail.empty? ? '' : "  (#{detail.join('; ')})"
    end

    def variant_lines
      lines = ['', 'Variant presets:']
      Config::VARIANTS.each do |v, cfg|
        lines << "    #{v}  =>  metal_level: #{cfg[:metal_level].ljust(4)}  " \
                 "metal_top: #{cfg[:metal_top].ljust(4)}  mim_option: #{cfg[:mim_option]}"
      end
      lines
    end

    def example_lines
      [
        '',
        'Example:',
        '  klayout -b -r gf180mcu.drc \\',
        '    -rd input=design.gds \\',
        '    -rd report=drc_results.lyrdb \\',
        '    -rd metal_level=5LM \\',
        '    -rd run_mode=deep',
        ''
      ]
    end
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

    def validate_allowed_params!(params)
      GF180DRC::Config::ALLOWED_VALUES.each do |key, allowed|
        value = params[key]
        next if value.nil?

        unless allowed.include?(value)
          raise ArgumentError,
                "Invalid #{key}: #{value.inspect}. Supported: #{allowed.join(', ')}"
        end
      end
    end
  end

  # Class-level factory helpers for building an Options from raw params.
  module Construction
    def bool?(input)
      input.to_s.downcase == 'true'
    end

    BOOLEAN_PARAMS = %i[verbose].freeze

    PARALLEL_PARAMS = %i[workers threads].freeze

    def resolved_booleans(base_params)
      BOOLEAN_PARAMS.to_h { |key| [key, bool?(base_params[key])] }
    end

    def resolved_parallel(base_params)
      PARALLEL_PARAMS.to_h do |key|
        value = base_params[key]

        resolved =
          if value.to_s == 'max'
            Etc.nprocessors
          else
            value.to_i
          end

        [key, resolved]
      end
    end

    def resolve_decks(decks, registry)
      tokens = decks.split(',').map(&:strip)
      result = []

      tokens.each do |token|
        if token.start_with?('-')
          tag = token.delete_prefix('-')
          warn_unknown_tag(tag, registry)
          result.reject! { |d| d.tags.include?(tag) }
        else
          warn_unknown_tag(token, registry)
          additions = registry.all.select { |d| d.tags.include?(token) }
          result |= additions
        end
      end

      result
    end

    def from_klayout_params(raw_params:, registry:)
      if bool?(raw_params[:help])
        puts help_text
        exit 0
      end

      base = merge_defaults_with_raw(raw_params)
      validate_allowed_params!(base)

      variant_config = variant_config_for(base[:variant])
      params = build_params(base: base, registry: registry, variant_config: variant_config)
      new(**params, **resolved_booleans(base), **resolved_parallel(base)).freeze
    end

    def variant_config_for(variant)
      GF180DRC::Config::VARIANTS.fetch(variant)
    end

    def build_params(base:, registry:, variant_config:)
      metal_level = base[:metal_level] || variant_config[:metal_level]

      {
        input: validate_and_normalize_input(base[:input]),
        report: resolve_report_path(base[:report]),
        variant: base[:variant],
        topcell: base[:topcell],
        run_mode: base[:run_mode],

        metal_level: metal_level,
        metal_top: base[:metal_top] || variant_config[:metal_top],
        mim_option: base[:mim_option] || variant_config[:mim_option],

        metal_level_numerical: metal_level_numerical(metal_level),
        decks: resolve_decks(base[:decks], registry)
      }
    end

    def metal_level_numerical(metal_level)
      GF180DRC::Config::METAL_LEVEL_MAP.fetch(metal_level)
    end

    private

    def warn_unknown_tag(tag, registry)
      available_tags = registry.all.flat_map(&:tags).uniq
      warn "Warning: unknown tag: #{tag}" unless available_tags.include?(tag)
    end
  end

  # Provides parsing of the command line options, and storing of the results
  class Options
    include OptionHelpers
    extend  Construction
    extend  ParamResolution
    extend  Help

    # Defaults that apply when input is nil (or missing).
    DEFAULTS = {
      topcell: nil,
      input: nil,
      report: nil,

      verbose: 'false',

      # run control
      workers: '1',
      threads: 'max',
      run_mode: 'deep',

      # technology selection
      variant: 'C',

      # Optional explicit overrides; nil means "use variant-provided default"
      mim_option: nil,
      metal_top: nil,
      metal_level: nil,

      decks: 'all'
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
        'MIM Option selected' => mim_option,
        'Verbose enabled' => verbose?,
        'Number of parallel workers' => workers,
        'Number of threads for DRC functions' => threads,
        'Run mode' => run_mode,
        'metal_top selected' => metal_top,
        'metal_level selected' => metal_level,
        'Selected decks' => decks.map(&:id).join(', ')
      }.each { |label, value| logger.info("#{label}: #{value}") }
    end
  end
end
