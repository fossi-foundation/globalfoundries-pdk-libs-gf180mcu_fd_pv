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

METAL_MAP_CUP = {
  1 => { metal_drawn: 'metal1_drawn' },
  2 => { metal_drawn: 'metal2_drawn' },
  3 => { metal_drawn: 'metal3_drawn' },
  4 => { metal_drawn: 'metal4_drawn' },
  5 => { metal_drawn: 'metal5_drawn' },
  6 => { metal_drawn: 'metaltop_drawn' }
}.freeze

GF180_DRC_REGISTRY.register(
  id: File.basename(__FILE__, File.extname(__FILE__)),
  path: __FILE__,
  priority: 0,
  tags: %w[all beol cup]
) do
  #================================================
  #---------- Circuit-Under-Pad (CUP) -------------
  #================================================

  (1..6).each do |lvl|
    next unless ctx.metal_level_numerical >= lvl

    metal_drawn = ctx[METAL_MAP_CUP[lvl][:metal_drawn]]

    logger.info('Executing rule CUP.2')
    cup2_l1 = metal_drawn.interacting(pad).not_interacting(guard_ring_mk).width(1.um).interacting(pad)
    cup2_l1.output('CUP.2', "CUP.2 : Minimum width of Metal#{lvl} line used for bond pads: 1")
    cup2_l1.forget

    logger.info('Executing rule CUP.3')
    cup3_l1 = metal_drawn.interacting(pad).not_interacting(guard_ring_mk).notch(1.um).interacting(pad)
    cup3_l1.output('CUP.3', "CUP.3 : Minimum space of Metal#{lvl} line used for bond pads (slots): 1")
    cup3_l1.forget
  end
end
