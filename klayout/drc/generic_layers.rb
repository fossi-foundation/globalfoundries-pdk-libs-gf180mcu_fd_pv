# frozen_string_literal: true

module GF180DRC
  # Extracts layer from design
  # rubocop:disable Metrics/ModuleLength
  module GenericLayers
    def self.generate_generic_layers(ctx)
      extract_layers_from_design(ctx)
      compute_generic_layers(ctx)

      ctx
    end

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def self.extract_layers_from_design(ctx)
      ctx.logger.info('Read in polygons from layers')

      merge = (ctx.options.run_mode != 'deep')

      # Extract polygons from the layout database.
      # Uses register_layer so it cannot be redefined later by accident.
      extract_single_layer_from_design = lambda do |name, layer, datatype|
        ctx.register_layer(name) do
          ps = ctx.drc.polygons(layer, datatype)
          merge ? ps.merged : ps
        end

        count = ctx[name].count
        ctx.logger.info("#{name} has #{count} polygons") if count
      end

      extract_single_layer_from_design.call(:comp, 22, 0)
      extract_single_layer_from_design.call(:dnwell, 12, 0)
      extract_single_layer_from_design.call(:nwell, 21, 0)
      extract_single_layer_from_design.call(:lvpwell, 204, 0)
      extract_single_layer_from_design.call(:dualgate, 55, 0)
      extract_single_layer_from_design.call(:poly2, 30, 0)
      extract_single_layer_from_design.call(:nplus, 32, 0)
      extract_single_layer_from_design.call(:pplus, 31, 0)
      extract_single_layer_from_design.call(:sab, 49, 0)
      extract_single_layer_from_design.call(:esd, 24, 0)
      extract_single_layer_from_design.call(:resistor, 62, 0)
      extract_single_layer_from_design.call(:fhres, 227, 0)
      extract_single_layer_from_design.call(:fusetop, 75, 0)
      extract_single_layer_from_design.call(:fusewindow_d, 96, 1)
      extract_single_layer_from_design.call(:polyfuse, 220, 0)
      extract_single_layer_from_design.call(:mvsd, 210, 0)
      extract_single_layer_from_design.call(:mvpsd, 11, 39)
      extract_single_layer_from_design.call(:nat, 5, 0)
      extract_single_layer_from_design.call(:comp_dummy, 22, 4)
      extract_single_layer_from_design.call(:poly2_dummy, 30, 4)
      extract_single_layer_from_design.call(:schottky_diode, 241, 0)
      extract_single_layer_from_design.call(:zener, 178, 0)
      extract_single_layer_from_design.call(:res_mk, 110, 5)
      extract_single_layer_from_design.call(:opc_drc, 124, 5)
      extract_single_layer_from_design.call(:v5_xtor, 112, 1)
      extract_single_layer_from_design.call(:cap_mk, 117, 5)
      extract_single_layer_from_design.call(:mos_cap_mk, 166, 5)
      extract_single_layer_from_design.call(:ind_mk, 151, 5)
      extract_single_layer_from_design.call(:diode_mk, 115, 5)
      extract_single_layer_from_design.call(:drc_bjt, 127, 5)
      extract_single_layer_from_design.call(:lvs_bjt, 118, 5)
      extract_single_layer_from_design.call(:mim_l_mk, 117, 10)
      extract_single_layer_from_design.call(:latchup_mk, 137, 5)
      extract_single_layer_from_design.call(:guard_ring_mk, 167, 5)
      extract_single_layer_from_design.call(:otp_mk, 173, 5)
      extract_single_layer_from_design.call(:mtpmark, 122, 5)
      extract_single_layer_from_design.call(:neo_ee_mk, 88, 17)
      extract_single_layer_from_design.call(:sramcore, 108, 5)
      extract_single_layer_from_design.call(:lvs_rf, 100, 5)
      extract_single_layer_from_design.call(:lvs_drain, 100, 7)
      extract_single_layer_from_design.call(:hvpolyrs, 123, 5)
      extract_single_layer_from_design.call(:lvs_io, 119, 5)
      extract_single_layer_from_design.call(:probe_mk, 13, 17)
      extract_single_layer_from_design.call(:esd_mk, 24, 5)
      extract_single_layer_from_design.call(:lvs_source, 100, 8)
      extract_single_layer_from_design.call(:well_diode_mk, 153, 51)
      extract_single_layer_from_design.call(:ldmos_xtor, 226, 0)
      extract_single_layer_from_design.call(:plfuse, 125, 5)
      extract_single_layer_from_design.call(:efuse_mk, 80, 5)
      extract_single_layer_from_design.call(:mcell_feol_mk, 11, 17)
      extract_single_layer_from_design.call(:ymtp_mk, 86, 17)
      extract_single_layer_from_design.call(:dev_wf_mk, 128, 17)
      extract_single_layer_from_design.call(:comp_label, 22, 10)
      extract_single_layer_from_design.call(:poly2_label, 30, 10)
      extract_single_layer_from_design.call(:mdiode, 116, 5)
      extract_single_layer_from_design.call(:ndmy, 111, 5)
      extract_single_layer_from_design.call(:pmndmy, 152, 5)
      extract_single_layer_from_design.call(:pad, 37, 0)
      extract_single_layer_from_design.call(:ubmpperi, 183, 0)
      extract_single_layer_from_design.call(:ubmparray, 184, 0)
      extract_single_layer_from_design.call(:ubmeplate, 185, 0)
      extract_single_layer_from_design.call(:pr_bndry, 0, 0)
      extract_single_layer_from_design.call(:border, 63, 0)

      extract_single_layer_from_design.call(:contact, 33, 0)
      extract_single_layer_from_design.call(:metal1_drawn, 34, 0)
      extract_single_layer_from_design.call(:metal1_slot, 34, 3)
      extract_single_layer_from_design.call(:metal1_dummy, 34, 4)
      extract_single_layer_from_design.call(:metal1_label, 34, 10)
      extract_single_layer_from_design.call(:metal1_blk, 34, 5)
      extract_single_layer_from_design.call(:metal1_res, 110, 11)

      extract_single_layer_from_design.call(:via1, 35, 0)
      extract_single_layer_from_design.call(:metal2_drawn, 36, 0)
      extract_single_layer_from_design.call(:metal2_slot, 36, 3)
      extract_single_layer_from_design.call(:metal2_dummy, 36, 4)
      extract_single_layer_from_design.call(:metal2_blk, 36, 5)
      extract_single_layer_from_design.call(:metal2_label, 36, 10)
      extract_single_layer_from_design.call(:metal2_res, 110, 12)

      if ctx.metal_level_numerical >= 3
        extract_single_layer_from_design.call(:via2, 38, 0)
        extract_single_layer_from_design.call(:metal3_drawn, 42, 0)
        extract_single_layer_from_design.call(:metal3_slot, 42, 3)
        extract_single_layer_from_design.call(:metal3_dummy, 42, 4)
        extract_single_layer_from_design.call(:metal3_blk, 42, 5)
        extract_single_layer_from_design.call(:metal3_label, 42, 10)
        extract_single_layer_from_design.call(:metal3_res, 110, 13)
      end

      if ctx.metal_level_numerical >= 4
        extract_single_layer_from_design.call(:via3, 40, 0)
        extract_single_layer_from_design.call(:metal4_drawn, 46, 0)
        extract_single_layer_from_design.call(:metal4_slot, 46, 3)
        extract_single_layer_from_design.call(:metal4_dummy, 46, 4)
        extract_single_layer_from_design.call(:metal4_blk, 46, 5)
        extract_single_layer_from_design.call(:metal4_label, 46, 10)
        extract_single_layer_from_design.call(:metal4_res, 110, 14)
      end

      if ctx.metal_level_numerical >= 5
        extract_single_layer_from_design.call(:via4, 41, 0)
        extract_single_layer_from_design.call(:metal5_drawn, 81, 0)
        extract_single_layer_from_design.call(:metal5_slot, 81, 3)
        extract_single_layer_from_design.call(:metal5_dummy, 81, 4)
        extract_single_layer_from_design.call(:metal5_blk, 81, 5)
        extract_single_layer_from_design.call(:metal5_label, 81, 10)
        extract_single_layer_from_design.call(:metal5_res, 110, 15)
      end

      if ctx.metal_level_numerical >= 6
        extract_single_layer_from_design.call(:via5, 82, 0)
        extract_single_layer_from_design.call(:metaltop_drawn, 53, 0)
        extract_single_layer_from_design.call(:metaltop_slot, 53, 3)
        extract_single_layer_from_design.call(:metaltop_dummy, 53, 4)
        extract_single_layer_from_design.call(:metaltop_blk, 53, 5)
        extract_single_layer_from_design.call(:metaltop_label, 53, 10)
        extract_single_layer_from_design.call(:metal6_res, 110, 16)
      end

      ctx
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/ModuleLength

    STATIC_LAYERS = [
      # --- Wells & Taps ---
      { name: :dnwell_n, calc: ->(ctx) { ctx[:dnwell].not(ctx[:lvpwell]) } },
      { name: :dnwell_p,        calc: ->(ctx) { ctx[:dnwell].and(ctx[:lvpwell]) } },
      { name: :all_nwell,       calc: ->(ctx) { ctx[:dnwell_n].join(ctx[:nwell]) } },

      # --- Comps & Gates ---
      { name: :ncomp,           calc: ->(ctx) { ctx[:comp].and(ctx[:nplus]) } },
      { name: :pcomp,           calc: ->(ctx) { ctx[:comp].and(ctx[:pplus]) } },
      { name: :tgate,           calc: ->(ctx) { ctx[:poly2].and(ctx[:comp]).not(ctx[:res_mk]) } },

      # --- N-Device Logic ---
      { name: :nactive,         calc: ->(ctx) { ctx[:ncomp].not(ctx[:all_nwell]) } },
      { name: :ngate,           calc: ->(ctx) { ctx[:nactive].and(ctx[:tgate]) } },
      { name: :nsd,             calc: lambda { |ctx|
        ctx[:nactive].interacting(ctx[:ngate]).not(ctx[:ngate]).not(ctx[:res_mk])
      } },
      { name: :ptap,            calc: ->(ctx) { ctx[:pcomp].not(ctx[:all_nwell]).not(ctx[:res_mk]) } },

      # --- P-Device Logic ---
      { name: :pactive,         calc: ->(ctx) { ctx[:pcomp].and(ctx[:all_nwell]) } },
      { name: :pgate,           calc: ->(ctx) { ctx[:pactive].and(ctx[:tgate]) } },
      { name: :psd,             calc: lambda { |ctx|
        ctx[:pactive].interacting(ctx[:pgate]).not(ctx[:pgate]).not(ctx[:res_mk])
      } },
      { name: :ntap,            calc: ->(ctx) { ctx[:ncomp].and(ctx[:all_nwell]).not(ctx[:res_mk]) } },

      # --- Deep Well Logic ---
      { name: :ngate_dn,        calc: ->(ctx) { ctx[:ngate].and(ctx[:dnwell_p]) } },
      { name: :ptap_dn,         calc: ->(ctx) { ctx[:ptap].and(ctx[:dnwell_p]).outside(ctx[:well_diode_mk]) } },
      { name: :pgate_dn,        calc: ->(ctx) { ctx[:pgate].and(ctx[:dnwell_n]) } },
      { name: :ntap_dn,         calc: ->(ctx) { ctx[:ntap].and(ctx[:dnwell_n]) } },

      # --- Complex Deep Well SD (using blocks for readability) ---
      { name: :psd_dn,          calc: lambda { |ctx|
        ctx[:pcomp].and(ctx[:dnwell_n]).interacting(ctx[:pgate_dn]).not(ctx[:pgate_dn]).not(ctx[:res_mk])
      } },
      { name: :nsd_dn, calc: lambda { |ctx|
        ctx[:ncomp].and(ctx[:dnwell_p]).interacting(ctx[:ngate_dn]).not(ctx[:ngate_dn]).not(ctx[:res_mk])
      } },

      { name: :natcomp,         calc: ->(ctx) { ctx[:nat].and(ctx[:comp]) } },

      # --- Gate Voltage Classes ---
      { name: :nom_gate,        calc: ->(ctx) { ctx[:tgate].not(ctx[:dualgate]) } },
      { name: :thick_gate,      calc: ->(ctx) { ctx[:tgate].and(ctx[:dualgate]) } },
      { name: :ngate_56v,       calc: ->(ctx) { ctx[:ngate].and(ctx[:dualgate]) } },
      { name: :pgate_56v,       calc: ->(ctx) { ctx[:pgate].and(ctx[:dualgate]) } },
      { name: :ngate_5v,        calc: ->(ctx) { ctx[:ngate_56v].and(ctx[:v5_xtor]) } },
      { name: :pgate_5v,        calc: ->(ctx) { ctx[:pgate_56v].and(ctx[:v5_xtor]) } },
      { name: :ngate_6v,        calc: ->(ctx) { ctx[:ngate_56v].not(ctx[:v5_xtor]) } },
      { name: :pgate_6v,        calc: ->(ctx) { ctx[:pgate_56v].not(ctx[:v5_xtor]) } },

      # --- DNWELL Voltage Classes ---
      { name: :dnwell_3p3v,     calc: lambda { |ctx|
        ctx[:dnwell].not_interacting(ctx[:v5_xtor]).not_interacting(ctx[:dualgate])
      } },
      { name: :dnwell_56v,      calc: ->(ctx) { ctx[:dnwell].overlapping(ctx[:dualgate]) } },

      # --- LVPWELL Logic ---
      { name: :lvpwell_dn,      calc: ->(ctx) { ctx[:lvpwell].interacting(ctx[:dnwell]) } },
      { name: :lvpwell_out,     calc: ->(ctx) { ctx[:lvpwell].not_interacting(ctx[:dnwell]) } },
      { name: :lvpwell_dn3p3v,  calc: ->(ctx) { ctx[:lvpwell].and(ctx[:dnwell_3p3v]) } },
      { name: :lvpwell_dn56v,   calc: ->(ctx) { ctx[:lvpwell].and(ctx[:dnwell_56v]) } },

      # --- NWELL Logic ---
      { name: :nwell_dn,        calc: ->(ctx) { ctx[:nwell].interacting(ctx[:dnwell]) } },
      { name: :nwell_n_dn,      calc: ->(ctx) { ctx[:nwell].not_interacting(ctx[:dnwell]) } }
    ].freeze

    METAL_STACK_MAP = {
      2 => { top_via: :via1, topmin1_via: :contact, top_metal: :metal2, topmin1_metal: :metal1 },
      3 => { top_via: :via2, topmin1_via: :via1,   top_metal: :metal3, topmin1_metal: :metal2 },
      4 => { top_via: :via3, topmin1_via: :via2,   top_metal: :metal4, topmin1_metal: :metal3 },
      5 => { top_via: :via4, topmin1_via: :via3,   top_metal: :metal5, topmin1_metal: :metal4 },
      6 => { top_via: :via5, topmin1_via: :via4,   top_metal: :metaltop, topmin1_metal: :metal5 }
    }.freeze

    METAL_NAMES = {
      1 => { metal_drawn: :metal1_drawn, metal_dummy: :metal1_dummy, metal_result: :metal1 },
      2 => { metal_drawn: :metal2_drawn, metal_dummy: :metal2_dummy, metal_result: :metal2 },
      3 => { metal_drawn: :metal3_drawn, metal_dummy: :metal3_dummy, metal_result: :metal3 },
      4 => { metal_drawn: :metal4_drawn, metal_dummy: :metal4_dummy, metal_result: :metal4 },
      5 => { metal_drawn: :metal5_drawn, metal_dummy: :metal5_dummy, metal_result: :metal5 },
      6 => { metal_drawn: :metaltop_drawn, metal_dummy: :metaltop_dummy, metal_result: :metaltop }
    }.freeze

    def self.compute_generic_layers(ctx)
      register_metal_layers(ctx)
      STATIC_LAYERS.each do |config|
        ctx.register_layer(config[:name]) { config[:calc].call(ctx) }
      end
      ctx
    end

    private_class_method def self.register_metal_layers(ctx)
      metal_level = ctx.metal_level_numerical
      validate_metal_level!(metal_level)
      register_numbered_metal_layers(ctx, metal_level)
      register_stack_alias_layers(ctx, METAL_STACK_MAP[metal_level])
    end

    private_class_method def self.validate_metal_level!(metal_level)
      return if METAL_STACK_MAP.key?(metal_level)

      logger.error("Unknown metal stack #{metal_level}")
      raise ArgumentError, "Unsupported metal level: #{metal_level}"
    end

    private_class_method def self.register_numbered_metal_layers(ctx, metal_level)
      (1..metal_level).each do |level|
        names = METAL_NAMES[level]
        ctx.register_layer(names[:metal_result]) { ctx[names[:metal_drawn]] + ctx[names[:metal_dummy]] }
      end
    end

    private_class_method def self.register_stack_alias_layers(ctx, stack)
      stack.each_key do |key|
        ctx.register_layer(key) { ctx[stack[key]] }
      end
    end
  end
end
