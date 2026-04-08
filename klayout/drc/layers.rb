# frozen_string_literal: true

module GF180DRC
  # Extracts layer from design
  # rubocop:disable Metrics/ModuleLength
  module Layers
    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def self.extract(ctx)
      ctx.logger.info('Read in polygons from layers')

      merge = (ctx.options[:run_mode] != 'deep')

      # Helper for readability
      ex = lambda do |name, layer, datatype|
        ctx.extract!(name, layer, datatype, merge: merge)
        if ctx.raw[name.to_sym].respond_to?(:count)
          ctx.logger.info("#{name} has #{ctx.raw[name.to_sym].count} polygons")
        end
      end

      ex.call(:comp, 22, 0)
      ex.call(:dnwell, 12, 0)
      ex.call(:nwell, 21, 0)
      ex.call(:lvpwell, 204, 0)
      ex.call(:dualgate, 55, 0)
      ex.call(:poly2, 30, 0)
      ex.call(:nplus, 32, 0)
      ex.call(:pplus, 31, 0)
      ex.call(:sab, 49, 0)
      ex.call(:esd, 24, 0)
      ex.call(:resistor, 62, 0)
      ex.call(:fhres, 227, 0)
      ex.call(:fusetop, 75, 0)
      ex.call(:fusewindow_d, 96, 1)
      ex.call(:polyfuse, 220, 0)
      ex.call(:mvsd, 210, 0)
      ex.call(:mvpsd, 11, 39)
      ex.call(:nat, 5, 0)
      ex.call(:comp_dummy, 22, 4)
      ex.call(:poly2_dummy, 30, 4)
      ex.call(:schottky_diode, 241, 0)
      ex.call(:zener, 178, 0)
      ex.call(:res_mk, 110, 5)
      ex.call(:opc_drc, 124, 5)
      ex.call(:v5_xtor, 112, 1)
      ex.call(:cap_mk, 117, 5)
      ex.call(:mos_cap_mk, 166, 5)
      ex.call(:ind_mk, 151, 5)
      ex.call(:diode_mk, 115, 5)
      ex.call(:drc_bjt, 127, 5)
      ex.call(:lvs_bjt, 118, 5)
      ex.call(:mim_l_mk, 117, 10)
      ex.call(:latchup_mk, 137, 5)
      ex.call(:guard_ring_mk, 167, 5)
      ex.call(:otp_mk, 173, 5)
      ex.call(:mtpmark, 122, 5)
      ex.call(:neo_ee_mk, 88, 17)
      ex.call(:sramcore, 108, 5)
      ex.call(:lvs_rf, 100, 5)
      ex.call(:lvs_drain, 100, 7)
      ex.call(:ind_mk, 151, 5)
      ex.call(:hvpolyrs, 123, 5)
      ex.call(:lvs_io, 119, 5)
      ex.call(:probe_mk, 13, 17)
      ex.call(:esd_mk, 24, 5)
      ex.call(:lvs_source, 100, 8)
      ex.call(:well_diode_mk, 153, 51)
      ex.call(:ldmos_xtor, 226, 0)
      ex.call(:plfuse, 125, 5)
      ex.call(:efuse_mk, 80, 5)
      ex.call(:mcell_feol_mk, 11, 17)
      ex.call(:ymtp_mk, 86, 17)
      ex.call(:dev_wf_mk, 128, 17)
      ex.call(:comp_label, 22, 10)
      ex.call(:poly2_label, 30, 10)
      ex.call(:mdiode, 116, 5)
      ex.call(:ndmy, 111, 5)
      ex.call(:pmndmy, 152, 5)
      ex.call(:pad, 37, 0)
      ex.call(:ubmpperi, 183, 0)
      ex.call(:ubmparray, 184, 0)
      ex.call(:ubmeplate, 185, 0)
      ex.call(:pr_bndry, 0, 0)
      ex.call(:border, 63, 0)

      ex.call(:contact, 33, 0)
      ex.call(:metal1_drawn, 34, 0)
      ex.call(:metal1_slot, 34, 3)
      ex.call(:metal1_dummy, 34, 4)
      ex.call(:metal1_label, 34, 10)
      ex.call(:metal1_blk, 34, 5)
      ex.call(:metal1_res, 110, 11)

      ex.call(:via1, 35, 0)
      ex.call(:metal2_drawn, 36, 0)
      ex.call(:metal2_slot, 36, 3)
      ex.call(:metal2_dummy, 36, 4)
      ex.call(:metal2_blk, 36, 5)
      ex.call(:metal2_label, 36, 10)
      ex.call(:metal2_res, 110, 12)

      if ctx.metal_level_numerical >= 3
        ex.call(:via2, 38, 0)
        ex.call(:metal3_drawn, 42, 0)
        ex.call(:metal3_slot, 42, 3)
        ex.call(:metal3_dummy, 42, 4)
        ex.call(:metal3_blk, 42, 5)
        ex.call(:metal3_label, 42, 10)
        ex.call(:metal3_res, 110, 13)
      end

      if ctx.metal_level_numerical >= 4
        ex.call(:via3, 40, 0)
        ex.call(:metal4_drawn, 46, 0)
        ex.call(:metal4_slot, 46, 3)
        ex.call(:metal4_dummy, 46, 4)
        ex.call(:metal4_blk, 46, 5)
        ex.call(:metal4_label, 46, 10)
        ex.call(:metal4_res, 110, 14)
      end

      if ctx.metal_level_numerical >= 5
        ex.call(:via4, 41, 0)
        ex.call(:metal5_drawn, 81, 0)
        ex.call(:metal5_slot, 81, 3)
        ex.call(:metal5_dummy, 81, 4)
        ex.call(:metal5_blk, 81, 5)
        ex.call(:metal5_label, 81, 10)
        ex.call(:metal5_res, 110, 15)
      end

      if ctx.metal_level_numerical >= 6
        ex.call(:via5, 82, 0)
        ex.call(:metaltop_drawn, 53, 0)
        ex.call(:metaltop_slot, 53, 3)
        ex.call(:metaltop_dummy, 53, 4)
        ex.call(:metaltop_blk, 53, 5)
        ex.call(:metaltop_label, 53, 10)
        ex.call(:metal6_res, 110, 16)
      end

      ctx
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/ModuleLength
  end
end
