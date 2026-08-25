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

GF180_DRC_REGISTRY.register(
  id: File.basename(__FILE__, File.extname(__FILE__)),
  path: __FILE__,
  priority: 0,
  tags: %w[all beol dummy dummy_comp]
) do
  #================================================
  #----------------------COMP----------------------
  #================================================

  logger.info('Starting dummy comp derivations')

  # Dummy comp derivations

  # For DCF.6abcd
  nwell_ring    = nwell.sized(1.um)    - nwell.sized(-1.um)
  dnwell_ring   = dnwell.sized(2.um)   - dnwell.sized(-2.um)
  lvpwell_ring  = lvpwell.sized(1.um)  - lvpwell.sized(-1.um)
  dualgate_ring = dualgate.sized(1.um) - dualgate.sized(-1.um)

  # Rule DCF.1a: All area between active polygons (COMP) (with spacing greater than equal to this rule)
  #              must be filled with "Dummy COMP": 20
  #              except area marked by NDMY, RES_MK, Pad and IND_MK, as well as the region defined by
  #              DCF.6a, 6b, 6c, 6d, 6e.
  logger.info('Executing rule DCF.1a')
  dcf1a_l1 = extent.sized(-10.um) # full chip area minus border
  dcf1a_l2 = ndmy + res_mk + pad + ind_mk + nwell_ring + dnwell_ring + lvpwell_ring + dualgate_ring # keepout area
  dcf1a_l3 = (dcf1a_l1 - (comp + comp_dummy) - dcf1a_l2).sized(-10.um).sized(10.um)
  dcf1a_l3.output('DCF.1a',
                  'DCF.1a : All area between active polygons (COMP) (with spacing greater than equal to this rule)' \
                  'must be filled with "Dummy COMP" (see exceptions): 20')
  dcf1a_l1.forget
  dcf1a_l2.forget
  dcf1a_l3.forget

  nwell_ring.forget
  dnwell_ring.forget
  lvpwell_ring.forget
  dualgate_ring.forget

  # Rule DCF.2b: Resulted minimum space between Dummy active in all directions: 1.9
  logger.info('Executing rule DCF.2b')
  dcf2b_l1 = comp_dummy.space(1.9.um, euclidian)
  dcf2b_l1.output('DCF.2b', 'DCF.2b : Resulted minimum space between Dummy active in all directions: 1.9')
  dcf2b_l1.forget

  # Rule DCF.4: Space from dummy COMP to COMP (circuit COMP): 3.5
  logger.info('Executing rule DCF.4')
  dcf4_l1 = comp_dummy.separation(comp, 3.5.um, euclidian)
  dcf4_l1.output('DCF.4', 'DCF.4 : Space from dummy COMP to COMP (circuit COMP): 3.5')
  dcf4_l1.forget

  # Rule DCF.5: Space from dummy COMP to poly2: 1.5
  logger.info('Executing rule DCF.5')
  dcf5_l1 = comp_dummy.separation(poly2_drawn, 1.5.um, euclidian)
  dcf5_l1.output('DCF.5', 'DCF.5 : Space from dummy COMP to poly2: 1.5')
  dcf5_l1.forget

  # Rule DCF.6a: Space from dummy COMP to Nwell boundary: 1.3
  logger.info('Executing rule DCF.6a')
  dcf6a_l1 = comp_dummy.separation(nwell, 1.3.um, euclidian)
  dcf6a_l1.output('DCF.6a', 'DCF.6a : Space from dummy COMP to Nwell boundary: 1.3')
  dcf6a_l1.forget

  # Rule DCF.6b: Space from dummy COMP to DNWELL boundary: 4
  logger.info('Executing rule DCF.6b')
  dcf6b_l1 = comp_dummy.separation(dnwell, 4.um, euclidian)
  dcf6b_l1.output('DCF.6b', 'DCF.6b : Space from dummy COMP to DNWELL boundary: 4')
  dcf6b_l1.forget

  # Rule DCF.6c: Space from dummy COMP to LVPWELL boundary: 1.3
  logger.info('Executing rule DCF.6c')
  dcf6c_l1 = comp_dummy.separation(lvpwell, 1.3.um, euclidian)
  dcf6c_l1.output('DCF.6c', 'DCF.6c : Space from dummy COMP to LVPWELL boundary: 1.3')
  dcf6c_l1.forget

  # Rule DCF.6d: Space from dummy COMP to Dualgate boundary: 1.3
  logger.info('Executing rule DCF.6d')
  dcf6d_l1 = comp_dummy.separation(dualgate, 1.3.um, euclidian)
  dcf6d_l1.output('DCF.6d', 'DCF.6d : Space from dummy COMP to Dualgate boundary: 1.3')
  dcf6d_l1.forget

  # Rule DCF.8a: Space from dummy COMP to Resistor marking layer (RES_MK): 3.5
  logger.info('Executing rule DCF.8a')
  dcf8a_l1 = comp_dummy.separation(res_mk, 3.5.um, euclidian)
  dcf8a_l1.output('DCF.8a', 'DCF.8a : Space from dummy COMP to Resistor marking layer (RES_MK): 3.5')
  dcf8a_l1.forget

  # Rule DCF.11a: Space from dummy COMP to dummy COMP excluding layer (NDMY): 3.5
  logger.info('Executing rule DCF.11a')
  dcf11a_l1 = comp_dummy.separation(ndmy, 3.5.um, euclidian)
  dcf11a_l1.output('DCF.11a', 'DCF.11a : Space from dummy COMP to dummy COMP excluding layer (NDMY): 3.5')
  dcf11a_l1.forget

  # Rule DCF.12: Minimum dummy COMP space to IND_MK layer: 3
  logger.info('Executing rule DCF.12')
  dcf12_l1 = comp_dummy.separation(ind_mk, 3.um, euclidian)
  dcf12_l1.output('DCF.12', 'DCF.12 : Minimum dummy COMP space to IND_MK layer: 3')
  dcf12_l1.forget
end
