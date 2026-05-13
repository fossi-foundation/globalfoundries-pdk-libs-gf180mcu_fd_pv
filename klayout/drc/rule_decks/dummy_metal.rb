# frozen_string_literal: true

################################################################################################
# Copyright 2023 GlobalFoundries PDK Authors
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

# rubocop:disable Layout/LineLength
# rubocop:disable Metrics/AbcSize

def dummy_metal_rules(idx:)
  #================================================
  #----------------- Dummy METAL ------------------
  #================================================

  metal_dummy = ctx[METAL_MAP_DUMMY[idx][:metal_dummy]]
  metal_drawn = ctx[METAL_MAP_DUMMY[idx][:metal_drawn]]

  # Rule DM.2b: Min Dummy metal line space (for DRC): 0.98
  logger.info("Executing rule DM#{idx}.2b")
  dm_2b_l1 = metal_dummy.space(0.98.um, euclidian)
  dm_2b_l1.output("DM#{idx}.2b", "DM#{idx}.2b : Min Dummy metal line space (for DRC): 0.98")
  dm_2b_l1.forget

  # Rule DM.3: Minimum space between dummy metal and circuit Metal line: 2
  logger.info("Executing rule DM#{idx}.3")
  dm_3_l1 = metal_dummy.separation(metal_drawn, 2.um, euclidian)
  dm_3_l1.output("DM#{idx}.3", "DM#{idx}.3 : Minimum space between dummy metal and circuit Metal line: 2")
  dm_3_l1.forget

  # if DUMMY_SUB_PREV
  #
  #  # Rule DM.4_DM.6: Dummy Metal space (no overlap) to Subsequent Metal layer: 1
  #  logger.info("Executing rule DM#{idx}.4_DM#{idx}.6")
  #  dm_4_dm_6_l1 = metal_dummy.separation(metal2_drawn, 1.um, euclidian)
  #  dm_4_dm_6_l1.output("DM#{idx}.4_DM#{idx}.6", "DM#{idx}.4_DM#{idx}.6 : Dummy Metal space (no overlap) to Subsequent Metal layer: 1")
  #  dm_4_dm_6_l1.forget
  #
  #  # Rule DM.5_DM.7: Dummy Metal space (no overlap) to Previous Metal layer: 1
  #  logger.info("Executing rule DM#{idx}.5_DM#{idx}.7")
  #  dm_5_dm_7_l1 = metal_dummy.separation(poly2, 1.um, euclidian)
  #  dm_5_dm_7_l1.output("DM#{idx}.5_DM#{idx}.7", "DM#{idx}.5_DM#{idx}.7 : Dummy Metal space (no overlap) to Previous Metal layer: 1")
  #  dm_5_dm_7_l1.forget
  #
  # end

  # Rule DM.8: Minimum space between dummy metal and FuseTop, POLYFUSE, FUSEWINDOW_D, PMNDMY, MTPMK, OTP_MK: 6
  logger.info("Executing rule DM#{idx}.8")
  dm_8_l1 = metal_dummy.separation(fusetop, 6.um, euclidian)
  dm_8_l1 += metal_dummy.separation(polyfuse, 6.um, euclidian)
  dm_8_l1 += metal_dummy.separation(fusewindow_d, 6.um, euclidian)
  dm_8_l1 += metal_dummy.separation(pmndmy, 6.um, euclidian)
  dm_8_l1 += metal_dummy.separation(mtpmark, 6.um, euclidian)
  dm_8_l1 += metal_dummy.separation(otp_mk, 6.um, euclidian)
  dm_8_l1.output("DM#{idx}.8",
                 "DM#{idx}.8 : Minimum space between dummy metal and FuseTop, POLYFUSE, FUSEWINDOW_D, PMNDMY, MTPMK, OTP_MK: 6")
  dm_8_l1.forget
end

METAL_MAP_DUMMY = {
  1 => { metal_dummy: 'metal1_dummy', metal_drawn: 'metal1_drawn' },
  2 => { metal_dummy: 'metal2_dummy', metal_drawn: 'metal2_drawn' },
  3 => { metal_dummy: 'metal3_dummy', metal_drawn: 'metal3_drawn' },
  4 => { metal_dummy: 'metal4_dummy', metal_drawn: 'metal4_drawn' },
  5 => { metal_dummy: 'metal5_dummy', metal_drawn: 'metal5_drawn' },
  6 => { metal_dummy: 'metaltop_dummy', metal_drawn: 'metaltop_drawn' }
}.freeze

(1..6).each do |lvl|
  reg_id = "dummy_metal#{lvl}"
  tags = %w[all beol dummy] + [reg_id]

  GF180_DRC_REGISTRY.register(id: reg_id, path: __FILE__, priority: 0, tags: tags) do
    next unless ctx.metal_level_numerical >= lvl

    dummy_metal_rules(idx: lvl)
  end
end

# rubocop:enable Layout/LineLength
# rubocop:enable Metrics/AbcSize
