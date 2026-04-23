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
#================================================
#--------------------CONTACT---------------------
#================================================

GF180_DRC_REGISTRY.register(id: 'CO.1_min_max_contact_size', path: __FILE__, priority: 0, tags: %w[all feol contact]) do
  logger.info('Executing rule CO.1')
  co1_l1 = contact.edges.without_length(0.22.um)
  co1_l1.output('CO.1', 'CO.1 : Min/max contact size. : 0.22µm')
  co1_l1.forget
end

GF180_DRC_REGISTRY.register(id: 'CO.2a_min_contact_spacing', path: __FILE__, priority: 0, tags: %w[all feol contact]) do
  logger.info('Executing rule CO.2a')
  co2a_l1 = contact.space(0.25.um, euclidian)
  co2a_l1.output('CO.2a', 'CO.2a : min. contact spacing : 0.25µm')
  co2a_l1.forget
end

GF180_DRC_REGISTRY.register(id: 'CO.2b_contact_array_spacing', path: __FILE__, priority: 0,
                            tags: %w[all feol contact]) do
  logger.info('Executing rule CO.2b')

  co2b_egde_length = (0.22 * 3) + (3 * 0.28)
  poss_4_4_contact = contact.sized(0.16, 'square_limit').merged.sized(-0.16, 'square_limit')

  co_4x4_all = poss_4_4_contact.with_bbox_min(co2b_egde_length..nil)
                               .interacting(contact, 16..nil)

  co_4x4_loc_exc = co_4x4_all.width(
    co2b_egde_length,
    projection_limits(co2b_egde_length..(1000 * co2b_egde_length))
  ).polygons

  co_4x4_loc = co_4x4_all.not_interacting(co_4x4_loc_exc)
  selected_co = contact.interacting(co_4x4_loc)

  co2b_l1 = selected_co.space(0.28.um, euclidian)
  co2b_l1.output('CO.2b', 'CO.2b : Space in 4x4 or larger contact array. : 0.28µm')
end

GF180_DRC_REGISTRY.register(id: 'CO.3_poly2_overlap', path: __FILE__, priority: 0, tags: %w[all feol contact]) do
  logger.info('Executing rule CO.3')

  main_contact = contact.not(sramcore)
  co3_l1 = main_contact.enclosed(poly2, 0.07.um, euclidian).polygons(0.001.um)
  co3_l2 = main_contact.not_outside(poly2).not(poly2)
  co3_l = co3_l1.or(co3_l2)

  co3_l.output('CO.3', 'CO.3 : Poly2 overlap of contact. : 0.07µm')

  co3_l.forget
  co3_l1.forget
  co3_l2.forget
end

GF180_DRC_REGISTRY.register(id: 'CO.4_comp_overlap', path: __FILE__, priority: 0, tags: %w[all feol contact]) do
  logger.info('Executing rule CO.4')

  main_contact = contact.not(sramcore)
  co4_l1 = main_contact.enclosed(comp, 0.07.um, euclidian).polygons(0.001.um)
  co4_l2 = main_contact.not_outside(comp).not(comp)
  co4_l = co4_l1.or(co4_l2)

  co4_l.output('CO.4', 'CO.4 : COMP overlap of contact. : 0.07µm')

  co4_l.forget
  co4_l1.forget
  co4_l2.forget
end

GF180_DRC_REGISTRY.register(id: 'CO.5a_nplus_overlap_butted', path: __FILE__, priority: 0,
                            tags: %w[all feol contact]) do
  logger.info('Executing rule CO.5a')

  co_5a_ncomp_butted = ncomp.interacting(pcomp).not_overlapping(pcomp)
  co_ncomp_check = contact.interacting(co_5a_ncomp_butted)

  co5a_l1 = co_ncomp_check.enclosed(co_5a_ncomp_butted, 0.1.um, euclidian)
  co5a_l1.output('CO.5a', 'CO.5a : Nplus overlap of contact on COMP (butted N+/P+) : 0.1µm')

  co5a_l1.forget
  co_ncomp_check.forget
  co_5a_ncomp_butted.forget
end

GF180_DRC_REGISTRY.register(id: 'CO.5b_pplus_overlap_butted', path: __FILE__, priority: 0,
                            tags: %w[all feol contact]) do
  logger.info('Executing rule CO.5b')

  co_5b_pcomp_butted = pcomp.interacting(ncomp).not_overlapping(ncomp)
  co_pcomp_check = contact.interacting(co_5b_pcomp_butted)

  co5b_l1 = co_pcomp_check.enclosed(co_5b_pcomp_butted, 0.1.um, euclidian)
  co5b_l1.output('CO.5b', 'CO.5b : Pplus overlap of contact on COMP (butted N+/P+) : 0.1µm')

  co5b_l1.forget
  co_pcomp_check.forget
  co_5b_pcomp_butted.forget
end

GF180_DRC_REGISTRY.register(id: 'CO.6_metal1_overlap', path: __FILE__, priority: 0, tags: %w[all feol contact]) do
  logger.info('Executing rule CO.6')

  co6_l1 = contact.enclosed(metal1, 0.005.um, euclidian).polygons(0.001.um)
  co6_l2 = contact.not(metal1)
  co6_l = co6_l1.or(co6_l2)

  co6_l.output('CO.6', 'CO.6 : Metal1 overlap of contact >= 0.005 um')

  co6_l1.forget
  co6_l2.forget
  co6_l.forget
end

GF180_DRC_REGISTRY.register(id: 'CO.6a_metal1_eol_overlap', path: __FILE__, priority: 0, tags: %w[all feol contact]) do
  logger.info('Executing rule CO.6a')

  cont_6a_cond = metal1.width(0.34.um + 1.dbu).with_length(0.24.um, nil, both)
  edge1 = cont_6a_cond.first_edges
  edge2 = cont_6a_cond.second_edges

  cont_6a_eol = metal1.edges.with_length(nil, 0.34.um)
                      .interacting(edge1).interacting(edge2)
                      .not(edge1).not(edge2)

  cont_6a_l1 = contact.edges.enclosed(cont_6a_eol, 0.06.um, projection)

  cont_6a_l1.output('CO.6a', 'CO.6a : Metal1 EOL overlap (<0.34µm lines) : 0.06µm')

  cont_6a_l1.forget
  cont_6a_cond.forget
  cont_6a_eol.forget
  edge1.forget
  edge2.forget
end

GF180_DRC_REGISTRY.register(id: 'CO.6b_adjacent_edge_overlap', path: __FILE__, priority: 0,
                            tags: %w[all feol contact]) do
  logger.info('Executing rule CO.6b')

  main_contact = contact.not(sramcore)
  main_contact_edges = main_contact.edges

  cond_edges = main_contact_edges.not_outside(
    main_contact.enclosed(metal1, 0.04.um, projection).edges
  )

  check_corner = cond_edges.extended_in(0.002.um)
  check = main_contact_edges.interacting(check_corner).not(cond_edges)

  cond_corner = cond_edges.width(0.002.um, angle_limit(135)).polygons(0.001.um)

  l1 = check.enclosed(metal1.edges, 0.06.um, projection).polygons(0.001.um)
  l2 = main_contact.interacting(cond_corner)

  result = l1.or(l2)

  result.output('CO.6b', 'CO.6b : Adjacent metal1 edge overlap : 0.06µm')

  result.forget
  l1.forget
  l2.forget
  cond_corner.forget
  check.forget
  check_corner.forget
  cond_edges.forget
end

# CO.6c guideline (intentionally not implemented)

GF180_DRC_REGISTRY.register(id: 'CO.7_comp_to_poly_spacing', path: __FILE__, priority: 0, tags: %w[all feol contact]) do
  logger.info('Executing rule CO.7')

  co7_l1 = contact.and(comp).not(otp_mk)
                  .separation(tgate.not(otp_mk), 0.15.um, euclidian)

  co7_l1.output('CO.7', 'CO.7 : Space from COMP contact to Poly2 : 0.15µm')
  co7_l1.forget
end

GF180_DRC_REGISTRY.register(id: 'CO.8_poly_to_comp_spacing', path: __FILE__, priority: 0, tags: %w[all feol contact]) do
  logger.info('Executing rule CO.8')

  co8_l1 = contact.and(poly2).separation(comp, 0.17.um, euclidian)

  co8_l1.output('CO.8', 'CO.8 : Space from Poly2 contact to COMP : 0.17µm')
  co8_l1.forget
end

GF180_DRC_REGISTRY.register(id: 'CO.9_no_contact_on_butting_edge', path: __FILE__, priority: 0,
                            tags: %w[all feol contact]) do
  logger.info('Executing rule CO.9')

  co9_l1 = contact.interacting(ncomp.edges.and(pcomp.edges))

  co9_l1.output('CO.9', 'CO.9 : Contact must not straddle NCOMP/PCOMP butting edge')
  co9_l1.forget
end

GF180_DRC_REGISTRY.register(id: 'CO.10_no_contact_on_poly_gate', path: __FILE__, priority: 0,
                            tags: %w[all feol contact]) do
  logger.info('Executing rule CO.10')

  co10_l1 = contact.and(tgate)

  co10_l1.output('CO.10', 'CO.10 : Contact on Poly2 gate over COMP is forbidden')
  co10_l1.forget
end

GF180_DRC_REGISTRY.register(id: 'CO.11_no_contact_on_field_oxide', path: __FILE__, priority: 0,
                            tags: %w[all feol contact]) do
  logger.info('Executing rule CO.11')

  co11_l1 = contact.not(poly2).not(comp)

  co11_l1.output('CO.11', 'CO.11 : Contact on field oxide is forbidden')
  co11_l1.forget
end
