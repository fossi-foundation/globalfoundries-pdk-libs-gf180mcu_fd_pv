# frozen_string_literal: true

# =========================================================
# Shared helpers (outside registrations)
# =========================================================

# rubocop:disable Naming/VariableNumber
# rubocop:disable Metrics/AbcSize

def via_rule_1(via:, idx:, name:)
  l = via.edges.without_length(0.26.um)
  l.output("V#{idx}.1", "V#{idx}.1 : Min/max #{name} size . : 0.26µm")
  l.forget
end

def via_rule_2a(via:, idx:, name:)
  l = via.space(0.26.um, euclidian)
  l.output("V#{idx}.2a", "V#{idx}.2a : min. #{name} spacing : 0.26µm")
  l.forget
end

def via_rule_2b(via:, idx:, name:)
  edge_len = (0.26 * 3) + (3 * 0.36)
  poss_4_4 = via.sized(0.2, 'square_limit').merged.sized(-0.2, 'square_limit')
  all_4x4 = poss_4_4.with_bbox_min(edge_len..nil).interacting(via, 16..nil)
  loc_exc = all_4x4.width(edge_len, projection_limits(edge_len..(1000 * edge_len))).polygons
  loc = all_4x4.not_interacting(loc_exc)
  selected = via.interacting(loc)
  l = selected.space(0.36.um, projecting >= 0.26.um)
  l.output("V#{idx}.2b", "V#{idx}.2b : #{name} Space in 4x4 or larger #{name} array : 0.36µm")
  l.forget
  poss_4_4.forget
  all_4x4.forget
  loc_exc.forget
  loc.forget
  selected.forget
end

def via_rule_3a(via:, idx:, name:, lower_metal:)
  l = via.not(lower_metal)
  l.output("V#{idx}.3a", "V#{idx}.3a : #{lower_metal} overlap of #{name} >= 0")
  l.forget
end

def via_rule_3b(via:, idx:, name:, lower_metal:)
  l1 = via.not(lower_metal)
  l2 = via.enclosed(lower_metal, 0.01, euclidian).polygons(0.001.um)
  l = l1.or(l2)
  l.output("V#{idx}.3b", "V#{idx}.3b : #{lower_metal} overlap of #{name} >= 0.01")
  l1.forget
  l2.forget
  l.forget
end

def via_rule_3c(via:, idx:, lower_metal:)
  cond = lower_metal.width(0.34.um + 1.dbu).with_length(0.28.um, nil, both)
  eol_allowed = lower_metal.edges.with_length(nil, 0.34.um)
  e1 = cond.first_edges
  e2 = cond.second_edges
  eol = eol_allowed.interacting(e1).interacting(e2).not(e1).not(e2)
  l = via.edges.enclosed(eol, 0.06.um, projection)
  l.output("V#{idx}.3c", "V#{idx}.3c : #{lower_metal} (< 0.34um) end-of-line overlap : 0.06µm")
  l.forget
  cond.forget
  eol_allowed.forget
  e1.forget
  e2.forget
  eol.forget
end

def via_rule_3d(via:, idx:, name:, lower_metal:)
  via_edges = via.edges
  cond_edges = via_edges.not_outside(via.enclosed(lower_metal, 0.04.um, projection).edges)
  check_corner = cond_edges.extended_in(0.002.um)
  check = via_edges.interacting(check_corner).not(cond_edges)
  cond_corner = cond_edges.width(0.002.um, angle_limit(135)).polygons
  l1 = check.enclosed(lower_metal.edges, 0.06.um, projection).polygons
  l2 = via.interacting(cond_corner)
  l = l1.or(l2)
  l.output("V#{idx}.3d",
           "V#{idx}.3d : If #{lower_metal} overlap #{name} by < 0.04um on one side, " \
           "adjacent #{lower_metal} edges overlap. : 0.06µm")
  l.forget
  l1.forget
  l2.forget
  cond_edges.forget
  check_corner.forget
  check.forget
  cond_corner.forget
end

def via_rule_4a(via:, idx:, name:, upper_metal:)
  l1 = via.enclosed(upper_metal, 0.01.um, euclidian).polygons(0.001.um)
  l2 = via.not(upper_metal)
  l = l1.or(l2)
  l.output("V#{idx}.4a", "V#{idx}.4a : #{upper_metal} overlap of #{name} >= 0.01 upper_metal")
  l.forget
  l1.forget
  l2.forget
end

def via_rule_4b(via:, idx:, upper_metal:)
  cond = upper_metal.width(0.34.um + 1.dbu).with_length(0.28.um, nil, both)
  eol_allowed = upper_metal.edges.with_length(nil, 0.34.um)
  eol = eol_allowed.interacting(cond.first_edges).interacting(cond.second_edges)
                   .not(cond.first_edges).not(cond.second_edges)
  l = via.edges.enclosed(eol, 0.06.um, projection)
  l.output("V#{idx}.4b", "V#{idx}.4b : #{upper_metal} (< 0.34um) end-of-line overlap : 0.06µm")
  l.forget
  cond.forget
  eol_allowed.forget
  eol.forget
end

def via_rule_4c(via:, idx:, name:, upper_metal:)
  via_edges = via.edges
  cond_edges = via_edges.not_outside(via.enclosed(upper_metal, 0.04.um, projection).edges)
  check_corner = cond_edges.extended_in(0.002.um)
  check = via_edges.interacting(check_corner).not(cond_edges)
  cond_corner = cond_edges.width(0.002.um, angle_limit(135)).polygons
  l1 = check.enclosed(upper_metal.edges, 0.06.um, projection).polygons
  l2 = via.interacting(cond_corner)
  l = l1.or(l2)
  l.output("V#{idx}.4c",
           "V#{idx}.4c : If #{upper_metal} overlap #{name} by < 0.04um on one side, " \
           "adjacent #{upper_metal} edges overlap. : 0.06µm")
  l.forget
  l1.forget
  l2.forget
  cond_edges.forget
  check_corner.forget
  check.forget
  cond_corner.forget
end

# rubocop:enable Naming/VariableNumber
# rubocop:enable Metrics/AbcSize

# =========================================================
# VIA1 registrations
# =========================================================

GF180_DRC_REGISTRY.register(id: 'via1_v1_1', path: __FILE__, priority: 15, tags: %w[all beol via1]) do
  logger.info('Executing rule V1.1')
  via_rule_1(via: via1, idx: 1, name: 'via1')
end
GF180_DRC_REGISTRY.register(id: 'via1_v1_2a', path: __FILE__, priority: 15, tags: %w[all beol via1]) do
  logger.info('Executing rule V1.2a')
  via_rule_2a(via: via1, idx: 1, name: 'via1')
end
GF180_DRC_REGISTRY.register(id: 'via1_v1_2b', path: __FILE__, priority: 15, tags: %w[all beol via1]) do
  logger.info('Executing rule V1.2b')
  via_rule_2b(via: via1, idx: 1, name: 'via1')
end
GF180_DRC_REGISTRY.register(id: 'via1_v1_3a', path: __FILE__, priority: 15, tags: %w[all beol via1]) do
  logger.info('Executing rule V1.3b')
  via_rule_3a(via: via1, idx: 1, name: 'via1', lower_metal: metal1)
end
GF180_DRC_REGISTRY.register(id: 'via1_v1_3c', path: __FILE__, priority: 15, tags: %w[all beol via1]) do
  logger.info('Executing rule V1.3c')
  via_rule_3c(via: via1, idx: 1, lower_metal: metal1)
end
GF180_DRC_REGISTRY.register(id: 'via1_v1_3d', path: __FILE__, priority: 15, tags: %w[all beol via1]) do
  logger.info('Executing rule V1.3d')
  via_rule_3d(via: via1, idx: 1, name: 'via1', lower_metal: metal1)
end
GF180_DRC_REGISTRY.register(id: 'via1_v1_4a', path: __FILE__, priority: 15, tags: %w[all beol via1]) do
  logger.info('Executing rule V1.4a')
  via_rule_4a(via: via1, idx: 1, name: 'via1', upper_metal: metal2)
end
GF180_DRC_REGISTRY.register(id: 'via1_v1_4b', path: __FILE__, priority: 15, tags: %w[all beol via1]) do
  logger.info('Executing rule V1.4b')
  via_rule_4b(via: via1, idx: 1, upper_metal: metal2)
end
GF180_DRC_REGISTRY.register(id: 'via1_v1_4c', path: __FILE__, priority: 15, tags: %w[all beol via1]) do
  logger.info('Executing rule V1.4c')
  via_rule_4c(via: via1, idx: 1, name: 'via1', upper_metal: metal2)
end

# =========================================================
# VIA2 registrations
# =========================================================

GF180_DRC_REGISTRY.register(id: 'via2_v2_1', path: __FILE__, priority: 15, tags: %w[all beol via2]) do
  next unless ctx.metal_level_numerical > 2

  logger.info('Executing rule V2.1')
  via_rule_1(via: via2, idx: 2, name: 'via2')
end
GF180_DRC_REGISTRY.register(id: 'via2_v2_2a', path: __FILE__, priority: 15, tags: %w[all beol via2]) do
  next unless ctx.metal_level_numerical > 2

  logger.info('Executing rule V2.2a')
  via_rule_2a(via: via2, idx: 2, name: 'via2')
end
GF180_DRC_REGISTRY.register(id: 'via2_v2_2b', path: __FILE__, priority: 15, tags: %w[all beol via2]) do
  next unless ctx.metal_level_numerical > 2

  logger.info('Executing rule V2.2b')
  via_rule_2b(via: via2, idx: 2, name: 'via2')
end
GF180_DRC_REGISTRY.register(id: 'via2_v2_3b', path: __FILE__, priority: 15, tags: %w[all beol via2]) do
  next unless ctx.metal_level_numerical > 2

  logger.info('Executing rule V2.3b')
  via_rule_3b(via: via2, idx: 2, name: 'via2', lower_metal: metal2)
end
GF180_DRC_REGISTRY.register(id: 'via2_v2_3c', path: __FILE__, priority: 15, tags: %w[all beol via2]) do
  next unless ctx.metal_level_numerical > 2

  logger.info('Executing rule V2.3c')
  via_rule_3c(via: via2, idx: 2, lower_metal: metal2)
end
GF180_DRC_REGISTRY.register(id: 'via2_v2_3d', path: __FILE__, priority: 15, tags: %w[all beol via2]) do
  next unless ctx.metal_level_numerical > 2

  logger.info('Executing rule V2.3d')
  via_rule_3d(via: via2, idx: 2, name: 'via2', lower_metal: metal2)
end
GF180_DRC_REGISTRY.register(id: 'via2_v2_4a', path: __FILE__, priority: 15, tags: %w[all beol via2]) do
  next unless ctx.metal_level_numerical > 2

  logger.info('Executing rule V2.4a')
  via_rule_4a(via: via2, idx: 2, name: 'via2', upper_metal: metal3)
end
GF180_DRC_REGISTRY.register(id: 'via2_v2_4b', path: __FILE__, priority: 15, tags: %w[all beol via2]) do
  next unless ctx.metal_level_numerical > 2

  logger.info('Executing rule V2.4b')
  via_rule_4b(via: via2, idx: 2, upper_metal: metal3)
end
GF180_DRC_REGISTRY.register(id: 'via2_v2_4c', path: __FILE__, priority: 15, tags: %w[all beol via2]) do
  next unless ctx.metal_level_numerical > 2

  logger.info('Executing rule V2.4c')
  via_rule_4c(via: via2, idx: 2, name: 'via2', upper_metal: metal3)
end

# =========================================================
# VIA3 registrations
# =========================================================

GF180_DRC_REGISTRY.register(id: 'via3_v3_1', path: __FILE__, priority: 15, tags: %w[all beol via3]) do
  next unless ctx.metal_level_numerical > 3

  logger.info('Executing rule V3.1')
  via_rule_1(via: via3, idx: 3, name: 'via3')
end
GF180_DRC_REGISTRY.register(id: 'via3_v3_2a', path: __FILE__, priority: 15, tags: %w[all beol via3]) do
  next unless ctx.metal_level_numerical > 3

  logger.info('Executing rule V3.2a')
  via_rule_2a(via: via3, idx: 3, name: 'via3')
end
GF180_DRC_REGISTRY.register(id: 'via3_v3_2b', path: __FILE__, priority: 15, tags: %w[all beol via3]) do
  next unless ctx.metal_level_numerical > 3

  logger.info('Executing rule V3.2b')
  via_rule_2b(via: via3, idx: 3, name: 'via3')
end
GF180_DRC_REGISTRY.register(id: 'via3_v3_3b', path: __FILE__, priority: 15, tags: %w[all beol via3]) do
  next unless ctx.metal_level_numerical > 3

  logger.info('Executing rule V3.3b')
  via_rule_3b(via: via3, idx: 3, name: 'via3', lower_metal: metal3)
end
GF180_DRC_REGISTRY.register(id: 'via3_v3_3c', path: __FILE__, priority: 15, tags: %w[all beol via3]) do
  next unless ctx.metal_level_numerical > 3

  logger.info('Executing rule V3.3c')
  via_rule_3c(via: via3, idx: 3, lower_metal: metal3)
end
GF180_DRC_REGISTRY.register(id: 'via3_v3_3d', path: __FILE__, priority: 15, tags: %w[all beol via3]) do
  next unless ctx.metal_level_numerical > 3

  logger.info('Executing rule V3.3d')
  via_rule_3d(via: via3, idx: 3, name: 'via3', lower_metal: metal3)
end
GF180_DRC_REGISTRY.register(id: 'via3_v3_4a', path: __FILE__, priority: 15, tags: %w[all beol via3]) do
  next unless ctx.metal_level_numerical > 3

  logger.info('Executing rule V3.4a')
  via_rule_4a(via: via3, idx: 3, name: 'via3', upper_metal: metal4)
end
GF180_DRC_REGISTRY.register(id: 'via3_v3_4b', path: __FILE__, priority: 15, tags: %w[all beol via3]) do
  next unless ctx.metal_level_numerical > 3

  logger.info('Executing rule V3.4b')
  via_rule_4b(via: via3, idx: 3, upper_metal: metal4)
end
GF180_DRC_REGISTRY.register(id: 'via3_v3_4c', path: __FILE__, priority: 15, tags: %w[all beol via3]) do
  next unless ctx.metal_level_numerical > 3

  logger.info('Executing rule V3.4c')
  via_rule_4c(via: via3, idx: 3, name: 'via3', upper_metal: metal4)
end

# =========================================================
# VIA4 registrations
# =========================================================

GF180_DRC_REGISTRY.register(id: 'via4_v4_1', path: __FILE__, priority: 15, tags: %w[all beol via4]) do
  next unless ctx.metal_level_numerical > 4

  logger.info('Executing rule V4.1')
  via_rule_1(via: via4, idx: 4, name: 'via4')
end
GF180_DRC_REGISTRY.register(id: 'via4_v4_2a', path: __FILE__, priority: 15, tags: %w[all beol via4]) do
  next unless ctx.metal_level_numerical > 4

  logger.info('Executing rule V4.2a')
  via_rule_2a(via: via4, idx: 4, name: 'via4')
end
GF180_DRC_REGISTRY.register(id: 'via4_v4_2b', path: __FILE__, priority: 15, tags: %w[all beol via4]) do
  next unless ctx.metal_level_numerical > 4

  logger.info('Executing rule V4.2b')
  via_rule_2b(via: via4, idx: 4, name: 'via4')
end
GF180_DRC_REGISTRY.register(id: 'via4_v4_3b', path: __FILE__, priority: 15, tags: %w[all beol via4]) do
  next unless ctx.metal_level_numerical > 4

  logger.info('Executing rule V4.3b')
  via_rule_3b(via: via4, idx: 4, name: 'via4', lower_metal: metal4)
end
GF180_DRC_REGISTRY.register(id: 'via4_v4_3c', path: __FILE__, priority: 15, tags: %w[all beol via4]) do
  next unless ctx.metal_level_numerical > 4

  logger.info('Executing rule V4.3c')
  via_rule_3c(via: via4, idx: 4, lower_metal: metal4)
end
GF180_DRC_REGISTRY.register(id: 'via4_v4_3d', path: __FILE__, priority: 15, tags: %w[all beol via4]) do
  next unless ctx.metal_level_numerical > 4

  logger.info('Executing rule V4.3d')
  via_rule_3d(via: via4, idx: 4, name: 'via4', lower_metal: metal4)
end
GF180_DRC_REGISTRY.register(id: 'via4_v4_4a', path: __FILE__, priority: 15, tags: %w[all beol via4]) do
  next unless ctx.metal_level_numerical > 4

  logger.info('Executing rule V4.4a')
  via_rule_4a(via: via4, idx: 4, name: 'via4', upper_metal: metal5)
end
GF180_DRC_REGISTRY.register(id: 'via4_v4_4b', path: __FILE__, priority: 15, tags: %w[all beol via4]) do
  next unless ctx.metal_level_numerical > 4

  logger.info('Executing rule V4.4b')
  via_rule_4b(via: via4, idx: 4, upper_metal: metal5)
end
GF180_DRC_REGISTRY.register(id: 'via4_v4_4c', path: __FILE__, priority: 15, tags: %w[all beol via4]) do
  next unless ctx.metal_level_numerical > 4

  logger.info('Executing rule V4.4c')
  via_rule_4c(via: via4, idx: 4, name: 'via4', upper_metal: metal5)
end

# =========================================================
# VIA5 registrations
# =========================================================

GF180_DRC_REGISTRY.register(id: 'via5_v5_1', path: __FILE__, priority: 15, tags: %w[all beol via5]) do
  next unless ctx.metal_level_numerical > 5

  logger.info('Executing rule V5.1')
  via_rule_1(via: via5, idx: 5, name: 'via5')
end
GF180_DRC_REGISTRY.register(id: 'via5_v5_2a', path: __FILE__, priority: 15, tags: %w[all beol via5]) do
  next unless ctx.metal_level_numerical > 5

  logger.info('Executing rule V5.2a')
  via_rule_2a(via: via5, idx: 5, name: 'via5')
end
GF180_DRC_REGISTRY.register(id: 'via5_v5_2b', path: __FILE__, priority: 15, tags: %w[all beol via5]) do
  next unless ctx.metal_level_numerical > 5

  logger.info('Executing rule V5.2b')
  via_rule_2b(via: via5, idx: 5, name: 'via5')
end
GF180_DRC_REGISTRY.register(id: 'via5_v5_3b', path: __FILE__, priority: 15, tags: %w[all beol via5]) do
  next unless ctx.metal_level_numerical > 5

  logger.info('Executing rule V5.3b')
  via_rule_3b(via: via5, idx: 5, name: 'via5', lower_metal: metal5)
end
GF180_DRC_REGISTRY.register(id: 'via5_v5_3c', path: __FILE__, priority: 15, tags: %w[all beol via5]) do
  next unless ctx.metal_level_numerical > 5

  logger.info('Executing rule V5.3c')
  via_rule_3c(via: via5, idx: 5, lower_metal: metal5)
end
GF180_DRC_REGISTRY.register(id: 'via5_v5_3d', path: __FILE__, priority: 15, tags: %w[all beol via5]) do
  next unless ctx.metal_level_numerical > 5

  logger.info('Executing rule V5.3d')
  via_rule_3d(via: via5, idx: 5, name: 'via5', lower_metal: metal5)
end
GF180_DRC_REGISTRY.register(id: 'via5_v5_4a', path: __FILE__, priority: 15, tags: %w[all beol via5]) do
  next unless ctx.metal_level_numerical > 5

  logger.info('Executing rule V5.4a')
  via_rule_4a(via: via5, idx: 5, name: 'via5', upper_metal: metaltop)
end
GF180_DRC_REGISTRY.register(id: 'via5_v5_4b', path: __FILE__, priority: 15, tags: %w[all beol via5]) do
  next unless ctx.metal_level_numerical > 5

  logger.info('Executing rule V5.4b')
  via_rule_4b(via: via5, idx: 5, upper_metal: metaltop)
end
GF180_DRC_REGISTRY.register(id: 'via5_v5_4c', path: __FILE__, priority: 15, tags: %w[all beol via5]) do
  next unless ctx.metal_level_numerical > 5

  logger.info('Executing rule V5.4c')
  via_rule_4c(via: via5, idx: 5, name: 'via5', upper_metal: metaltop)
end
