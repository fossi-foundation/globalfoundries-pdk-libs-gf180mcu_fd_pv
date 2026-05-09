# frozen_string_literal: true

################################################################################################
# Copyright 2025 GlobalFoundries PDK Authors
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
# rubocop:disable Layout/LineLength

def mslot_rules(idx:)
  #================================================
  #------------ Metal Slotting rules --------------
  #================================================

  logger.info('Starting Metal Slotting rules derivations')

  # TODO: share between all layers?
  top_metal_under_pad = (top_metal & pad).sized(5.um)
  mim_bottom_under_fusetop = (metal4_drawn & fusetop).sized(5.um)
  top_metal_under_fusewindow_d = (top_metal & fusewindow_d).sized(5.um)
  top_metal_under_ubm = (top_metal & ubmpperi).sized(5.um) | (top_metal & ubmparray).sized(5.um) | (top_metal & ubmeplate).sized(5.um)

  dont_slot = top_metal_under_pad | mim_bottom_under_fusetop | top_metal_under_fusewindow_d | top_metal_under_ubm

  metal_slot = ctx[METAL_MAP_MSLOT[idx][:metal_slot]]
  metal_drawn = ctx[METAL_MAP_MSLOT[idx][:metal_drawn]]
  via_below = ctx[METAL_MAP_MSLOT[idx][:via_below]]
  via_above = ctx.metal_level_numerical == idx ? polygon_layer : ctx[METAL_MAP_MSLOT[idx][:via_above]]

  logger.info("Checking slots for Metal#{idx}")

  metal_slotted = metal_drawn - metal_slot - dont_slot - via_below.sized(0.2) - via_above.sized(0.2)
  metal_slot_rectangles = metal_slot.rectangles
  metal_slot_non_rectangles = metal_slot.non_rectangles

  # Implied rule
  metal_slot_non_rectangles.output("MSLOT#{idx}.0", "MSLOT#{idx}.0 : Slot is not a rectangle")

  # Rule MSLOT.1: Maximum metal width without slotting: 30µm
  logger.info("Executing rule MSLOT#{idx}.1")
  mslot1_l1 = metal_slotted.sized(0, -15.um).sized(-15.um, 0).sized(0, 15.um).sized(15.um, 0)
  mslot1_l1.output("MSLOT#{idx}.1", "MSLOT#{idx}.1 : Maximum metal width without slotting: 30µm")
  mslot1_l1.forget

  # Rule MSLOT.2: Minimum slot width (slot mark layers): 2µm
  logger.info("Executing rule MSLOT#{idx}.2")
  mslot2_l1 = metal_slot_rectangles.drc(bbox_min < 2.um)
  mslot2_l1.output("MSLOT#{idx}.2", "MSLOT#{idx}.2 : Minimum slot width (slot mark layers): 2µm")
  mslot2_l1.forget

  # Rule MSLOT.3: Slot length (slot mark layers): min 10µm, max 250µm
  logger.info("Executing rule MSLOT#{idx}.3")
  mslot3_l1 = metal_slot_rectangles.drc((bbox_max < 10.um) + (bbox_max > 250.um))
  mslot3_l1.output("MSLOT#{idx}.3", "MSLOT#{idx}.3 : Slot length (slot mark layers): min 10µm, max 250µm")
  mslot3_l1.forget

  # Rule MSLOT.4: Slot space (slot mark layers): min 10µm
  logger.info("Executing rule MSLOT#{idx}.4")
  mslot4_l1 = metal_slot_rectangles.drc(space < 10.um)
  mslot4_l1.output("MSLOT#{idx}.4", "MSLOT#{idx}.4 : Slot space (slot mark layers): min 10µm")
  mslot4_l1.forget

  # Rule MSLOT.5: Minimum slot (slot mark layers) to metal edge spacing: 10µm
  logger.info("Executing rule MSLOT#{idx}.5")
  mslot5_l1 = metal_slot_rectangles.drc(enclosed(metal_drawn) < 10.um)
  mslot5_l1.output("MSLOT#{idx}.5", "MSLOT#{idx}.5 : Minimum slot (slot mark layers) to metal edge spacing: 10µm")
  mslot5_l1.forget

  # Rule MSLOT.7: Minimum space from via-n to metal-n slot: 0.2µm
  logger.info("Executing rule MSLOT#{idx}.7")
  mslot7_l1 = metal_slot_rectangles.drc(separation(via_above) < 0.2.um)
  mslot7_l1.output("MSLOT#{idx}.7", "MSLOT#{idx}.7 : Minimum space from via-n to metal-n slot: 0.2µm")
  mslot7_l1.forget

  # Rule MSLOT.8: Minimum space from via-(n-1) / contact to metal-n slot: 0.2µm
  logger.info("Executing rule MSLOT#{idx}.8")
  mslot8_l1 = metal_slot_rectangles.drc(separation(via_below) < 0.2.um)
  mslot8_l1.output("MSLOT#{idx}.8", "MSLOT#{idx}.8 : Minimum space from via-(n-1) / contact to metal-n slot: 0.2µm")
  mslot8_l1.forget

  # Rule MSLOT.9: Minimum distance to these layers: 5µm
  logger.info("Executing rule MSLOT#{idx}.9")
  mslot9_l1 = metal_slot_rectangles.drc(separation(dont_slot) < 5.um)
  mslot9_l1.output("MSLOT#{idx}.9", "MSLOT#{idx}.9 : Minimum distance to these layers: 5µm")
  mslot9_l1.forget

  metal_slotted.forget
  metal_slot_rectangles.forget
  metal_slot_non_rectangles.forget

  top_metal_under_pad.forget
  mim_bottom_under_fusetop.forget
  top_metal_under_fusewindow_d.forget
  top_metal_under_ubm.forget

  dont_slot.forget
end

METAL_MAP_MSLOT = {
  1 => { metal_slot: 'metal1_slot',   metal_drawn: 'metal1_drawn',   via_below: 'contact', via_above: 'via1' },
  2 => { metal_slot: 'metal2_slot',   metal_drawn: 'metal2_drawn',   via_below: 'via1',    via_above: 'via2' },
  3 => { metal_slot: 'metal3_slot',   metal_drawn: 'metal3_drawn',   via_below: 'via2',    via_above: 'via3' },
  4 => { metal_slot: 'metal4_slot',   metal_drawn: 'metal4_drawn',   via_below: 'via3',    via_above: 'via4' },
  5 => { metal_slot: 'metal5_slot',   metal_drawn: 'metal5_drawn',   via_below: 'via4',    via_above: 'via5' },
  6 => { metal_slot: 'metaltop_slot', metal_drawn: 'metaltop_drawn', via_below: 'via5',    via_above: 'none' }
}.freeze

(1..6).each do |lvl|
  reg_id = "mslot#{lvl}"
  tags = %w[all beol mslot] + [reg_id]

  GF180_DRC_REGISTRY.register(id: reg_id, path: __FILE__, priority: 0, tags: tags) do
    next unless ctx.metal_level_numerical >= lvl

    mslot_rules(idx: lvl)
  end
end

# rubocop:enable Metrics/AbcSize
# rubocop:enable Metrics/MethodLength
# rubocop:enable Layout/LineLength
