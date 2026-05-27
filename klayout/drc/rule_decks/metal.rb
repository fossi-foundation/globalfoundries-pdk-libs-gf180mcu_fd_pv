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

# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/MethodLength
# rubocop:disable Style/IdenticalConditionalBranches

def metal_rules(idx:)
  #================================================
  #---------------------METAL----------------------
  #================================================

  metal_drawn = ctx[METAL_MAP_METAL[idx][:metal_drawn]]
  min_width  = METAL_MAP_METAL[idx][:min_width]
  min_space  = METAL_MAP_METAL[idx][:min_space]

  # For Metal1 the 3.3V SRAM is handled by S.M1.1_LV
  if idx == 1
    logger.info("Executing rule M#{idx}.1")
    sram_lv = sramcore.not_interacting(v5_xtor).not_interacting(dualgate)
    m1_l1 = metal_drawn.not(sram_lv).width(min_width.um, euclidian)
    m1_l1.output("M#{idx}.1", "M#{idx}.1 : min. metal#{idx} width : #{min_width}µm")
    m1_l1.forget
    sram_lv.forget
  else
    logger.info("Executing rule M#{idx}.1")
    m1_l1 = metal_drawn.width(min_width.um, euclidian)
    m1_l1.output("M#{idx}.1", "M#{idx}.1 : min. metal#{idx} width : #{min_width}µm")
    m1_l1.forget
  end

  logger.info("Executing rule M#{idx}.2a")
  m2a_l1 = metal_drawn.space(min_space.um, euclidian)
  m2a_l1.output("M#{idx}.2a", "M#{idx}.2a : min. metal#{idx} spacing : #{min_space}µm")
  m2a_l1.forget

  logger.info("Executing rule M#{idx}.2b")
  # Get all edge pairs that are smaller than 10um
  # (we can't do (width >= 10.um) since there's no definition for "opposite edge")
  # Subtract this from metal1 to obtain the wide metal
  # wide_m = metal_drawn - metal_drawn.drc(width < 10.um).polygons
  # For now use this rule since the other is too slow
  wide_m = metal_drawn.sized(-5.um, 0.um).sized(0.um, -5.um).sized(5.um, 0.um).sized(0.um, 5.um).and(metal_drawn)
  m2b_l1 = metal_drawn.separation(wide_m, 0.3.um, euclidian, without_touching_edges)
  m2b_l1.output("M#{idx}.2b", "M#{idx}.2b : Space to wide Metal#{idx} (length & width > 10um) : 0.3µm")
  m2b_l1.forget
  wide_m.forget

  logger.info("Executing rule M#{idx}.3")
  m3_l1 = metal_drawn.with_area(nil, 0.1444.um)
  m3_l1.output("M#{idx}.3", "M#{idx}.3 : Minimum metal#{idx} area : 0.1444µm²")
  m3_l1.forget
end

# All the metal layer that can be not topmetal
METAL_MAP_METAL = {
  1 => { metal_drawn: 'metal1_drawn', min_width: 0.23, min_space: 0.23 },
  2 => { metal_drawn: 'metal2_drawn', min_width: 0.28, min_space: 0.28 },
  3 => { metal_drawn: 'metal3_drawn', min_width: 0.28, min_space: 0.28 },
  4 => { metal_drawn: 'metal4_drawn', min_width: 0.28, min_space: 0.28 },
  5 => { metal_drawn: 'metal5_drawn', min_width: 0.28, min_space: 0.28 }
}.freeze

(1..5).each do |lvl|
  reg_id = "metal#{lvl}"
  tags = %w[all beol metal] + [reg_id]

  GF180_DRC_REGISTRY.register(id: reg_id, path: __FILE__, priority: 0, tags: tags) do
    # Only run the deck if max metal layer is larger than the level
    # The top metal is handled separately
    next unless ctx.metal_level_numerical > lvl

    metal_rules(idx: lvl)
  end
end

# rubocop:enable Metrics/AbcSize
# rubocop:enable Metrics/MethodLength
# rubocop:enable Style/IdenticalConditionalBranches
