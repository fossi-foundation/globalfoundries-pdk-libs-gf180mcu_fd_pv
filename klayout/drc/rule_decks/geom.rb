# frozen_string_literal: true

################################################################################################
# Copyright 2023 GlobalFoundries PDK Authors
#
# Licensed under the Apache License, Version 2.0 (the 'License');
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an 'AS IS' BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
################################################################################################

#================================================
#-----------------GEOMETRY RULES-----------------
#================================================

# Shared helper in same file
def offgrid_angle_check(layer, name)
  logger.info("Executing rule #{name}_OFFGRID")
  layer.ongrid(0.005).output("#{name}_OFFGRID", "OFFGRID : OFFGRID vertex on #{name}")
  layer.edges.without_angle(0).without_angle(45).without_angle(90)
       .without_angle(-45).output("#{name}_angle", "ACUTE : non 45 degree angle #{name}")
end

# =========================================================
# FEOL / marker / misc (no metal-level dependency)
# =========================================================
GF180_DRC_REGISTRY.register(
  id: 'geom_base_1',
  path: __FILE__,
  priority: 10,
  tags: %w[all offgrid geom]
) do
  logger.info('OFFGRID-ANGLES section (geom_base_1)')

  offgrid_angle_check(comp, 'comp')
  offgrid_angle_check(dnwell, 'dnwell')
  offgrid_angle_check(nwell, 'nwell')
  offgrid_angle_check(lvpwell, 'lvpwell')
  offgrid_angle_check(dualgate, 'dualgate')
  offgrid_angle_check(poly2, 'poly2')
  offgrid_angle_check(nplus, 'nplus')
  offgrid_angle_check(pplus, 'pplus')
  offgrid_angle_check(sab, 'sab')
  offgrid_angle_check(esd, 'esd')
  offgrid_angle_check(resistor, 'resistor')
  offgrid_angle_check(fhres, 'fhres')
  offgrid_angle_check(fusetop, 'fusetop')
  offgrid_angle_check(fusewindow_d, 'fusewindow_d')
  offgrid_angle_check(polyfuse, 'polyfuse')
  offgrid_angle_check(mvsd, 'mvsd')
  offgrid_angle_check(mvpsd, 'mvpsd')
  offgrid_angle_check(nat, 'nat')
  offgrid_angle_check(comp_dummy, 'comp_dummy')
  offgrid_angle_check(poly2_dummy, 'poly2_dummy')
  offgrid_angle_check(schottky_diode, 'schottky_diode')
  offgrid_angle_check(zener, 'zener')
  offgrid_angle_check(res_mk, 'res_mk')
  offgrid_angle_check(opc_drc, 'opc_drc')
  offgrid_angle_check(ndmy, 'ndmy')
  offgrid_angle_check(pmndmy, 'pmndmy')
  offgrid_angle_check(v5_xtor, 'v5_xtor')
  offgrid_angle_check(cap_mk, 'cap_mk')
  offgrid_angle_check(mos_cap_mk, 'mos_cap_mk')
  offgrid_angle_check(ind_mk, 'ind_mk')
  offgrid_angle_check(diode_mk, 'diode_mk')
  offgrid_angle_check(drc_bjt, 'drc_bjt')
  offgrid_angle_check(lvs_bjt, 'lvs_bjt')
end

GF180_DRC_REGISTRY.register(
  id: 'geom_base_2',
  path: __FILE__,
  priority: 10,
  tags: %w[all offgrid geom]
) do
  logger.info('OFFGRID-ANGLES section (geom_base_2)')

  offgrid_angle_check(mim_l_mk, 'mim_l_mk')
  offgrid_angle_check(latchup_mk, 'latchup_mk')
  offgrid_angle_check(guard_ring_mk, 'guard_ring_mk')
  offgrid_angle_check(otp_mk, 'otp_mk')
  offgrid_angle_check(mtpmark, 'mtpmark')
  offgrid_angle_check(neo_ee_mk, 'neo_ee_mk')
  offgrid_angle_check(sramcore, 'sramcore')
  offgrid_angle_check(lvs_rf, 'lvs_rf')
  offgrid_angle_check(lvs_drain, 'lvs_drain')
  offgrid_angle_check(hvpolyrs, 'hvpolyrs')
  offgrid_angle_check(lvs_io, 'lvs_io')
  offgrid_angle_check(probe_mk, 'probe_mk')
  offgrid_angle_check(esd_mk, 'esd_mk')
  offgrid_angle_check(lvs_source, 'lvs_source')
  offgrid_angle_check(well_diode_mk, 'well_diode_mk')
  offgrid_angle_check(ldmos_xtor, 'ldmos_xtor')
  offgrid_angle_check(plfuse, 'plfuse')
  offgrid_angle_check(efuse_mk, 'efuse_mk')
  offgrid_angle_check(mcell_feol_mk, 'mcell_feol_mk')
  offgrid_angle_check(ymtp_mk, 'ymtp_mk')
  offgrid_angle_check(dev_wf_mk, 'dev_wf_mk')
  offgrid_angle_check(comp_label, 'comp_label')
  offgrid_angle_check(poly2_label, 'poly2_label')
  offgrid_angle_check(mdiode, 'mdiode')
end

# =========================================================
# M1/M2 + VIA1/CONTACT
# =========================================================
GF180_DRC_REGISTRY.register(
  id: 'geom_m1m2',
  path: __FILE__,
  priority: 10,
  tags: %w[all offgrid geom]
) do
  logger.info('OFFGRID-ANGLES section (geom_m1m2)')

  offgrid_angle_check(contact, 'contact')
  offgrid_angle_check(metal1, 'metal1')
  offgrid_angle_check(metal1_slot, 'metal1_slot')
  offgrid_angle_check(metal1_blk, 'metal1_blk')
  offgrid_angle_check(metal1_label, 'metal1_label')
  offgrid_angle_check(metal1_res, 'metal1_res')
  offgrid_angle_check(via1, 'via1')
  offgrid_angle_check(metal2, 'metal2')
  offgrid_angle_check(metal2_label, 'metal2_label')
  offgrid_angle_check(metal2_slot, 'metal2_slot')
  offgrid_angle_check(metal2_blk, 'metal2_blk')
  offgrid_angle_check(metal2_res, 'metal2_res')
end

# =========================================================
# M3/VIA2
# =========================================================
GF180_DRC_REGISTRY.register(
  id: 'geom_m3',
  path: __FILE__,
  priority: 10,
  tags: %w[all offgrid geom]
) do
  next unless ctx.metal_level_numerical >= 3

  logger.info('OFFGRID-ANGLES section (geom_m3)')

  offgrid_angle_check(via2, 'via2')
  offgrid_angle_check(metal3, 'metal3')
  offgrid_angle_check(metal3_dummy, 'metal3_dummy')
  offgrid_angle_check(metal3_label, 'metal3_label')
  offgrid_angle_check(metal3_blk, 'metal3_blk')
  offgrid_angle_check(metal3_res, 'metal3_res')
end

# =========================================================
# M4/VIA3
# =========================================================
GF180_DRC_REGISTRY.register(
  id: 'geom_m4',
  path: __FILE__,
  priority: 10,
  tags: %w[all offgrid geom]
) do
  next unless ctx.metal_level_numerical >= 4

  logger.info('OFFGRID-ANGLES section (geom_m4)')

  offgrid_angle_check(via3, 'via3')
  offgrid_angle_check(metal4, 'metal4')
  offgrid_angle_check(metal4_dummy, 'metal4_dummy')
  offgrid_angle_check(metal4_label, 'metal4_label')
  offgrid_angle_check(metal4_blk, 'metal4_blk')
  offgrid_angle_check(metal4_res, 'metal4_res')
end

# =========================================================
# M5/VIA4
# =========================================================
GF180_DRC_REGISTRY.register(
  id: 'geom_m5',
  path: __FILE__,
  priority: 10,
  tags: %w[all offgrid geom]
) do
  next unless ctx.metal_level_numerical >= 5

  logger.info('OFFGRID-ANGLES section (geom_m5)')

  offgrid_angle_check(via4, 'via4')
  offgrid_angle_check(metal5, 'metal5')
  offgrid_angle_check(metal5_dummy, 'metal5_dummy')
  offgrid_angle_check(metal5_label, 'metal5_label')
  offgrid_angle_check(metal5_blk, 'metal5_blk')
  offgrid_angle_check(metal5_res, 'metal5_res')
end

# =========================================================
# METALTOP/VIA5
# =========================================================
GF180_DRC_REGISTRY.register(
  id: 'geom_metaltop',
  path: __FILE__,
  priority: 10,
  tags: %w[all offgrid geom]
) do
  next unless ctx.metal_level_numerical >= 6

  logger.info('OFFGRID-ANGLES section (geom_metaltop)')

  offgrid_angle_check(via5, 'via5')
  offgrid_angle_check(metaltop, 'metaltop')
  offgrid_angle_check(metaltop_dummy, 'metaltop_dummy')
  offgrid_angle_check(metaltop_label, 'metaltop_label')
  offgrid_angle_check(metaltop_blk, 'metaltop_blk')
  offgrid_angle_check(metal6_res, 'metal6_res')
end

# =========================================================
# Top-level/package markers
# =========================================================
GF180_DRC_REGISTRY.register(
  id: 'geom_topmarkers',
  path: __FILE__,
  priority: 10,
  tags: %w[all offgrid geom]
) do
  logger.info('OFFGRID-ANGLES section (geom_topmarkers)')

  offgrid_angle_check(pad, 'pad')
  offgrid_angle_check(ubmpperi, 'ubmpperi')
  offgrid_angle_check(ubmparray, 'ubmparray')
  offgrid_angle_check(ubmeplate, 'ubmeplate')
  offgrid_angle_check(pr_bndry, 'pr_bndry')
  offgrid_angle_check(border, 'border')
end
