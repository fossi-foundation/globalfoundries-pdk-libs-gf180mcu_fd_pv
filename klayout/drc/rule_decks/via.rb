# frozen_string_literal: true

# =========================================================
# Shared helpers (outside registrations)
# =========================================================
# rubocop:disable Naming/VariableNumber
# rubocop:disable Metrics/AbcSize

def via_rule_1(idx:)
  via = ctx[METAL_MAP[idx][:via]]
  l = via.edges.without_length(0.26.um)
  l.output("V#{idx}.1", "V#{idx}.1 : Min/max #{METAL_MAP[idx][:via]} size . : 0.26µm")
  l.forget
end

def via_rule_2a(idx:)
  via = ctx[METAL_MAP[idx][:via]]
  l = via.space(0.26.um, euclidian)
  l.output("V#{idx}.2a", "V#{idx}.2a : min. #{METAL_MAP[idx][:via]} spacing : 0.26µm")
  l.forget
end

def via_rule_2b(idx:)
  via = ctx[METAL_MAP[idx][:via]]

  edge_len = (0.26 * 3) + (3 * 0.36)
  poss_4_4 = via.sized(0.2, 'square_limit').merged.sized(-0.2, 'square_limit')
  all_4x4 = poss_4_4.with_bbox_min(edge_len..nil).interacting(via, 16..nil)
  loc_exc = all_4x4.width(edge_len, projection_limits(edge_len..(1000 * edge_len))).polygons
  loc = all_4x4.not_interacting(loc_exc)
  selected = via.interacting(loc)
  l = selected.space(0.36.um, projecting >= 0.26.um)
  l.output("V#{idx}.2b", "V#{idx}.2b : Space in 4x4 or larger #{METAL_MAP[idx][:via]} array : 0.36µm")
  l.forget
  poss_4_4.forget
  all_4x4.forget
  loc_exc.forget
  loc.forget
  selected.forget
end

def via_rule_3(idx:)
  if idx == 1
    via_rule_3a(idx)
  else
    via_rule_3b(idx)
  end
end

def via_rule_3a(idx:)
  via_name = METAL_MAP[idx][:via]
  via = ctx[via_name]
  lower_metal_name = METAL_MAP[idx][:lower_metal]
  lower_metal = ctx[lower_metal_name]

  l = via.not(lower_metal)
  l.output("V#{idx}.3a", "V#{idx}.3a : #{lower_metal_name} overlap of #{via_name} >= 0")
  l.forget
end

def via_rule_3b(idx:)
  via_name = METAL_MAP[idx][:via]
  via = ctx[via_name]
  lower_metal_name = METAL_MAP[idx][:lower_metal]
  lower_metal = ctx[lower_metal_name]

  l1 = via.not(lower_metal)
  l2 = via.enclosed(lower_metal, 0.01, euclidian).polygons(0.001.um)
  l = l1.or(l2)
  l.output("V#{idx}.3b", "V#{idx}.3b : #{lower_metal_name} overlap of #{via_name} >= 0.01")
  l1.forget
  l2.forget
  l.forget
end

def via_rule_3c(idx:)
  via_name = METAL_MAP[idx][:via]
  via = ctx[via_name]
  lower_metal_name = METAL_MAP[idx][:lower_metal]
  lower_metal = ctx[lower_metal_name]

  cond = lower_metal.width(0.34.um + 1.dbu).with_length(0.28.um, nil, both)
  eol_allowed = lower_metal.edges.with_length(nil, 0.34.um)
  e1 = cond.first_edges
  e2 = cond.second_edges
  eol = eol_allowed.interacting(e1).interacting(e2).not(e1).not(e2)
  l = via.edges.enclosed(eol, 0.06.um, projection)
  l.output("V#{idx}.3c", "V#{idx}.3c : #{lower_metal_name} (< 0.34um) end-of-line overlap of #{via_name}: 0.06µm")
  l.forget
  cond.forget
  eol_allowed.forget
  e1.forget
  e2.forget
  eol.forget
end

def via_rule_3d(idx:)
  via_name = METAL_MAP[idx][:via]
  via = ctx[via_name]
  lower_metal_name = METAL_MAP[idx][:lower_metal]
  lower_metal = ctx[lower_metal_name]

  via_edges = via.edges
  cond_edges = via_edges.not_outside(via.enclosed(lower_metal, 0.04.um, projection).edges)
  check_corner = cond_edges.extended_in(0.002.um)
  check = via_edges.interacting(check_corner).not(cond_edges)
  cond_corner = cond_edges.width(0.002.um, angle_limit(135)).polygons
  l1 = check.enclosed(lower_metal.edges, 0.06.um, projection).polygons
  l2 = via.interacting(cond_corner)
  l = l1.or(l2)
  l.output("V#{idx}.3d",
           "V#{idx}.3d : If #{lower_metal_name} overlap #{via_name} by < 0.04um on one side, " \
           "adjacent #{lower_metal_name} edges overlap. : 0.06µm")
  l.forget
  l1.forget
  l2.forget
  cond_edges.forget
  check_corner.forget
  check.forget
  cond_corner.forget
end

def via_rule_4a(idx:)
  via_name = METAL_MAP[idx][:via]
  via = ctx[via_name]
  upper_metal_name = METAL_MAP[idx][:upper_metal]
  upper_metal = ctx[upper_metal_name]

  l1 = via.enclosed(upper_metal, 0.01.um, euclidian).polygons(0.001.um)
  l2 = via.not(upper_metal)
  l = l1.or(l2)
  l.output("V#{idx}.4a", "V#{idx}.4a : #{upper_metal_name} overlap of #{via_name} >= 0.01 upper_metal")
  l.forget
  l1.forget
  l2.forget
end

def via_rule_4b(idx:)
  via_name = METAL_MAP[idx][:via]
  via = ctx[via_name]
  upper_metal_name = METAL_MAP[idx][:upper_metal]
  upper_metal = ctx[upper_metal_name]

  cond = upper_metal.width(0.34.um + 1.dbu).with_length(0.28.um, nil, both)
  eol_allowed = upper_metal.edges.with_length(nil, 0.34.um)
  eol = eol_allowed.interacting(cond.first_edges).interacting(cond.second_edges)
                   .not(cond.first_edges).not(cond.second_edges)
  l = via.edges.enclosed(eol, 0.06.um, projection)
  l.output("V#{idx}.4b", "V#{idx}.4b : #{upper_metal_name} (< 0.34um) end-of-line overlap of #{via_name} : 0.06µm")
  l.forget
  cond.forget
  eol_allowed.forget
  eol.forget
end

def via_rule_4c(idx:)
  via_name = METAL_MAP[idx][:via]
  via = ctx[via_name]
  upper_metal_name = METAL_MAP[idx][:upper_metal]
  upper_metal = ctx[upper_metal_name]

  via_edges = via.edges
  cond_edges = via_edges.not_outside(via.enclosed(upper_metal, 0.04.um, projection).edges)
  check_corner = cond_edges.extended_in(0.002.um)
  check = via_edges.interacting(check_corner).not(cond_edges)
  cond_corner = cond_edges.width(0.002.um, angle_limit(135)).polygons
  l1 = check.enclosed(upper_metal.edges, 0.06.um, projection).polygons
  l2 = via.interacting(cond_corner)
  l = l1.or(l2)
  l.output("V#{idx}.4c",
           "V#{idx}.4c : If #{upper_metal_name} overlap #{via_name} by < 0.04um on one side, " \
           "adjacent #{upper_metal_name} edges overlap. : 0.06µm")
  l.forget
  l1.forget
  l2.forget
  cond_edges.forget
  check_corner.forget
  check.forget
  cond_corner.forget
end

VIA_RULE_DEFS_1 = {
  '1' => :via_rule_1,
  '2a' => :via_rule_2a,
  '2b' => :via_rule_2b,
  '3a' => :via_rule_3a,
  '3c' => :via_rule_3c,
  '3d' => :via_rule_3d,
  '4a' => :via_rule_4a,
  '4b' => :via_rule_4b,
  '4c' => :via_rule_4c
}.freeze

VIA_RULE_DEFS_2_5 = {
  '1' => :via_rule_1,
  '2a' => :via_rule_2a,
  '2b' => :via_rule_2b,
  '3b' => :via_rule_3b,
  '3c' => :via_rule_3c,
  '3d' => :via_rule_3d,
  '4a' => :via_rule_4a,
  '4b' => :via_rule_4b,
  '4c' => :via_rule_4c
}.freeze

METAL_MAP = {
  1 => { via: 'via1', lower_metal: 'metal1', upper_metal: 'metal2', rules: VIA_RULE_DEFS_1 },
  2 => { via: 'via2', lower_metal: 'metal2', upper_metal: 'metal3', rules: VIA_RULE_DEFS_2_5 },
  3 => { via: 'via3', lower_metal: 'metal3', upper_metal: 'metal4', rules: VIA_RULE_DEFS_2_5 },
  4 => { via: 'via4', lower_metal: 'metal4', upper_metal: 'metal5', rules: VIA_RULE_DEFS_2_5 },
  5 => { via: 'via5', lower_metal: 'metal5', upper_metal: 'metaltop', rules: VIA_RULE_DEFS_2_5 }
}.freeze

(1..5).each do |lvl|
  METAL_MAP[lvl][:rules].each do |name, func|
    reg_id = "V#{lvl}.#{name}"
    tags = %w[all beol via] + [METAL_MAP[lvl][:via].to_s, reg_id]
    log_msg = "Executing rule #{reg_id}"

    GF180_DRC_REGISTRY.register(id: reg_id, path: __FILE__, priority: 15, tags: tags) do
      next unless ctx.metal_level_numerical > lvl

      logger.info(log_msg)

      send(func, idx: lvl)
    end
  end
end

# rubocop:enable Naming/VariableNumber
# rubocop:enable Metrics/AbcSize
