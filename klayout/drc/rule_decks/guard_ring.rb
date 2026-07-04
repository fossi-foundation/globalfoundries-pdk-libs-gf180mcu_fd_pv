# frozen_string_literal: true

################################################################################################
# Copyright 2022 GlobalFoundries PDK Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
################################################################################################

METAL_MAP_GUARD_RING = {
  1 => { metal: 'metal1' },
  2 => { metal: 'metal2' },
  3 => { metal: 'metal3' },
  4 => { metal: 'metal4' },
  5 => { metal: 'metal5' },
  6 => { metal: 'metaltop' }
}.freeze

GF180_DRC_REGISTRY.register(
  id: File.basename(__FILE__, File.extname(__FILE__)),
  path: __FILE__,
  priority: 0,
  tags: %w[all beol guard_ring]
) do
  #================================================
  #------------ Guard Ring / Seal Ring ------------
  #================================================

  guard_ring_comp = comp.interacting(guard_ring_mk)

  # Rule GR.1: Min/Max GUARD_RING_MK overlap of guard ring comp: 0
  logger.info('Executing rule GR.1')
  gr1_l1 = guard_ring_mk.not_in(guard_ring_comp)
  gr1_l1.output('GR.1', 'GR.1 : Min/Max GUARD_RING_MK overlap of guard ring comp: 0')
  gr1_l1.forget

  # Rule GR.2: Min GUARD_RING_MK space to prime die COMP, NWELL, Poly2, Metal 1, 2, 3, 4, 5 and metal Top: 10
  logger.info('Executing rule GR.2')
  gr2_l1 = comp.separation(guard_ring_mk, 10.um)
  gr2_l1.output('GR.2', 'GR.2 : Min GUARD_RING_MK space to prime die COMP: 10')
  gr2_l1.forget
  gr2_l1 = nwell.separation(guard_ring_mk, 10.um)
  gr2_l1.output('GR.2', 'GR.2 : Min GUARD_RING_MK space to prime die NWELL: 10')
  gr2_l1.forget
  gr2_l1 = poly2.separation(guard_ring_mk, 10.um)
  gr2_l1.output('GR.2', 'GR.2 : Min GUARD_RING_MK space to prime die Poly2: 10')
  gr2_l1.forget

  (1..6).each do |lvl|
    next unless ctx.metal_level_numerical >= lvl

    metal = ctx[METAL_MAP_GUARD_RING[lvl][:metal]]

    gr2_l1 = metal.separation(guard_ring_mk, 10.um)
    gr2_l1.output('GR.2', "GR.2 : Min GUARD_RING_MK space to prime die Metal#{lvl}: 10")
    gr2_l1.forget
  end

  # Rule GR.3: Minimum Pplus overlap of PCOMP inside guard ring: 0
  logger.info('Executing rule GR.3')
  gr3_l1 = guard_ring_comp.not_in(pplus)
  gr3_l1.output('GR.3', 'GR.3 : Minimum Pplus overlap of PCOMP inside guard ring: 0')
  gr3_l1.forget

  # Rule GR.4: Minimum metal-n width (n= 1 to 6): 12
  logger.info('Executing rule GR.4')
  (1..6).each do |lvl|
    next unless ctx.metal_level_numerical >= lvl

    metal = ctx[METAL_MAP_GUARD_RING[lvl][:metal]]

    gr4_l1 = metal.not_outside(guard_ring_mk).width(12.um)
    gr4_l1.output('GR.4', "GR.4 : Minimum Metal width#{lvl}: 12")
    gr4_l1.forget
  end

  # Rule GR.6: Min PCOMP width: 16
  logger.info('Executing rule GR.6')
  gr6_l1 = comp.not_outside(guard_ring_mk).width(16.um)
  gr6_l1.output('GR.6', 'GR.6 : Min PCOMP width: 16')
  gr6_l1.forget

  guard_ring_comp.forget
end

GF180_DRC_REGISTRY.register(
  id: "#{File.basename(__FILE__, File.extname(__FILE__))}_wedge",
  path: __FILE__,
  priority: 0,
  tags: %w[all beol guard_ring wedge]
) do
  #================================================
  #------------ Guard Ring / Seal Ring ------------
  #------------      Wedge bonding     -----------
  #================================================

  # Rule GR.11: Pad opening on top of GUARD_RING_MK layer
  logger.info('Executing rule GR.11')
  gr11_l1 = guard_ring_mk.not_interacting(pad)
  gr11_l1.output('GR.11', 'GR.11 : Pad opening on top of GUARD_RING_MK layer')
  gr11_l1.forget
end
