# frozen_string_literal: true

module GF180DRC
  # Any generic layer that has to be computed rather than extracted
  module DerivedLayers
    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity
    def self.build(ctx)
      ctx.derive(:metal1) { ctx[:metal1_drawn] + ctx[:metal1_dummy] }

      ctx.derive(:metal2) { ctx[:metal2_drawn] + ctx[:metal2_dummy] } if ctx.metal_level_numerical >= 2

      ctx.derive(:metal3) { ctx[:metal3_drawn] + ctx[:metal3_dummy] } if ctx.metal_level_numerical >= 3

      ctx.derive(:metal4) { ctx[:metal4_drawn] + ctx[:metal4_dummy] } if ctx.metal_level_numerical >= 4

      ctx.derive(:metal5) { ctx[:metal5_drawn] + ctx[:metal5_dummy] } if ctx.metal_level_numerical >= 5

      ctx.derive(:metaltop) { ctx[:metaltop_drawn] + ctx[:metaltop_dummy] } if ctx.metal_level_numerical >= 6

      case ctx.metal_level_numerical
      when 2
        ctx.derive(:top_via) { ctx[:via1] }
        ctx.derive(:topmin1_via) { ctx[:contact] }
        ctx.derive(:top_metal) { ctx[:metal2] }
        ctx.derive(:topmin1_metal) { ctx[:metal1] }
      when 3
        ctx.derive(:top_via) { ctx[:via2] }
        ctx.derive(:topmin1_via) { ctx[:via1] }
        ctx.derive(:top_metal) { ctx[:metal3] }
        ctx.derive(:topmin1_metal) { ctx[:metal2] }
      when 4
        ctx.derive(:top_via) { ctx[:via3] }
        ctx.derive(:topmin1_via) { ctx[:via2] }
        ctx.derive(:top_metal) { ctx[:metal4] }
        ctx.derive(:topmin1_metal) { ctx[:metal3] }
      when 5
        ctx.derive(:top_via) { ctx[:via4] }
        ctx.derive(:topmin1_via) { ctx[:via3] }
        ctx.derive(:top_metal) { ctx[:metal5] }
        ctx.derive(:topmin1_metal) { ctx[:metal4] }
      when 6
        ctx.derive(:top_via) { ctx[:via5] }
        ctx.derive(:topmin1_via) { ctx[:via4] }
        ctx.derive(:top_metal) { ctx[:metaltop] }
        ctx.derive(:topmin1_metal) { ctx[:metal5] }
      else
        logger.error("Unknown metal stack #{METAL_LEVEL}")
        raise
      end

      ctx.derive(:dnwell_n)  { ctx[:dnwell].not(ctx[:lvpwell]) }
      ctx.derive(:dnwell_p)  { ctx[:dnwell].and(ctx[:lvpwell]) }
      ctx.derive(:all_nwell) { ctx[:dnwell_n].join(ctx[:nwell]) }

      ctx.derive(:ncomp) { ctx[:comp].and(ctx[:nplus]) }
      ctx.derive(:pcomp) { ctx[:comp].and(ctx[:pplus]) }

      ctx.derive(:tgate) { ctx[:poly2].and(ctx[:comp]).not(ctx[:res_mk]) }

      ctx.derive(:nactive) { ctx[:ncomp].not(ctx[:all_nwell]) }
      ctx.derive(:ngate) { ctx[:nactive].and(ctx[:tgate]) }
      ctx.derive(:nsd) { ctx[:nactive].interacting(ctx[:ngate]).not(ctx[:ngate]).not(ctx[:res_mk]) }
      ctx.derive(:ptap) { ctx[:pcomp].not(ctx[:all_nwell]).not(ctx[:res_mk]) }

      ctx.derive(:pactive) { ctx[:pcomp].and(ctx[:all_nwell]) }
      ctx.derive(:pgate) { ctx[:pactive].and(ctx[:tgate]) }
      ctx.derive(:psd) { ctx[:pactive].interacting(ctx[:pgate]).not(ctx[:pgate]).not(ctx[:res_mk]) }
      ctx.derive(:ntap) { ctx[:ncomp].and(ctx[:all_nwell]).not(ctx[:res_mk]) }

      ctx.derive(:ngate_dn) { ctx[:ngate].and(ctx[:dnwell_p]) }
      ctx.derive(:ptap_dn) { ctx[:ptap].and(ctx[:dnwell_p]).outside(ctx[:well_diode_mk]) }

      ctx.derive(:pgate_dn) { ctx[:pgate].and(ctx[:dnwell_n]) }
      ctx.derive(:ntap_dn) { ctx[:ntap].and(ctx[:dnwell_n]) }

      ctx.derive(:psd_dn) do
        ctx[:pcomp].and(ctx[:dnwell_n]).interacting(ctx[:pgate_dn]).not(ctx[:pgate_dn]).not(ctx[:res_mk])
      end
      ctx.derive(:nsd_dn) do
        ctx[:ncomp].and(ctx[:dnwell_p]).interacting(ctx[:ngate_dn]).not(ctx[:ngate_dn]).not(ctx[:res_mk])
      end

      ctx.derive(:natcomp) { ctx[:nat].and(ctx[:comp]) }

      # Gate
      ctx.derive(:nom_gate) { ctx[:tgate].not(ctx[:dualgate]) }
      ctx.derive(:thick_gate) { ctx[:tgate].and(ctx[:dualgate]) }

      ctx.derive(:ngate_56v) { ctx[:ngate].and(ctx[:dualgate]) }
      ctx.derive(:pgate_56v) { ctx[:pgate].and(ctx[:dualgate]) }

      ctx.derive(:ngate_5v) { ctx[:ngate_56v].and(ctx[:v5_xtor]) }
      ctx.derive(:pgate_5v) { ctx[:pgate_56v].and(ctx[:v5_xtor]) }

      ctx.derive(:ngate_6v) { ctx[:ngate_56v].not(ctx[:v5_xtor]) }
      ctx.derive(:pgate_6v) { ctx[:pgate_56v].not(ctx[:v5_xtor]) }

      # DNWELL
      ctx.derive(:dnwell_3p3v) { ctx[:dnwell].not_interacting(ctx[:v5_xtor]).not_interacting(ctx[:dualgate]) }
      ctx.derive(:dnwell_56v) { ctx[:dnwell].overlapping(ctx[:dualgate]) }

      # LVPWELL
      ctx.derive(:lvpwell_dn) { ctx[:lvpwell].interacting(ctx[:dnwell]) }
      ctx.derive(:lvpwell_out) { ctx[:lvpwell].not_interacting(ctx[:dnwell]) }

      ctx.derive(:lvpwell_dn3p3v) { ctx[:lvpwell].and(ctx[:dnwell_3p3v]) }
      ctx.derive(:lvpwell_dn56v) { ctx[:lvpwell].and(ctx[:dnwell_56v]) }

      # NWELL
      ctx.derive(:nwell_dn) { ctx[:nwell].interacting(ctx[:dnwell]) }
      ctx.derive(:nwell_n_dn) { ctx[:nwell].not_interacting(ctx[:dnwell]) }

      ctx
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity
  end
end
