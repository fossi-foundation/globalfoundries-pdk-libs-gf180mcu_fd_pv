# frozen_string_literal: true

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

# rubocop:disable Metrics/ParameterLists
# rubocop:disable Naming/MethodParameterName
# rubocop:disable Layout/LineLength

# Shared helper (same file)

# ANTENNADIFFSIDEAREARATIO-like antenna check
def antenna_check_gf180mcu(gate, antenna_layer, thickness, limit, n_diode, p_diode, nwell, mf)
  expression = 'var garea = area; var darea = area(n_diode) + area(p_diode) + area(nwell); var per = perimeter(antenna_layer) * thickness; ' \
               'var ar = per / (garea + mf * darea); skip(ar < limit); ' \
               "put('GATE_AREA', garea); put('DIODES_AREA', darea); put('ANT_PERIMETER', per); put('RATIO', ar); copy(ar >= limit, limit=1000);"
  variables = { 'thickness' => thickness, 'mf' => mf, 'limit' => limit }
  evaluate_nets(gate,
                { 'antenna_layer' => antenna_layer, 'n_diode' => n_diode, 'p_diode' => p_diode, 'nwell' => nwell }, expression, variables)
end

# ANTENNADIFFAREARATIO-like antenna check
def antenna_check_gf180mcu_area(gate, antenna_layer, limit, n_diode, p_diode, nwell, mf)
  expression = 'var garea = area; var darea = area(n_diode) + area(p_diode) + area(nwell); var aarea = area(antenna_layer); ' \
               'var ar = aarea / (garea + mf * darea); skip(ar < limit); ' \
               "put('GATE_AREA', garea); put('DIODES_AREA', darea); put('ANT_AREA', aarea); put('RATIO', ar); copy(ar >= limit, limit=1000);"
  variables = { 'mf' => mf, 'limit' => limit }
  evaluate_nets(gate,
                { 'antenna_layer' => antenna_layer, 'n_diode' => n_diode, 'p_diode' => p_diode, 'nwell' => nwell }, expression, variables)
end

# =========================================================
# POLY
# =========================================================
GF180_DRC_REGISTRY.register(
  id: 'antenna_poly2',
  path: __FILE__,
  priority: 10,
  tags: %w[all feol antenna]
) do
  # Clear all connections so far
  clear_connections

  # Set up the connections for the antenna check
  connect(poly2_drawn, tgate)
  connect(poly2_drawn, nom_gate)
  connect(poly2_drawn, thick_gate)

  logger.info('Executing rule ANT.1')
  antenna_check(tgate, perimeter_only(poly2_drawn, 0.2.um), 200)
    .output('ANT.1',
            'ANT.1: Maximum ratio of Poly2 perimeter area to related gate oxide area: 200')
end
# =========================================================
# CONTACT
# =========================================================
GF180_DRC_REGISTRY.register(
  id: 'antenna_contact',
  path: __FILE__,
  priority: 10,
  tags: %w[all feol antenna]
) do
  # Clear all connections so far
  clear_connections

  # Set up the connections for the antenna check
  connect(poly2_drawn, tgate)
  connect(poly2_drawn, nom_gate)
  connect(poly2_drawn, thick_gate)
  connect(poly2_drawn, contact)
  connect(contact, n_diode) # N-diode
  connect(contact, p_diode) # P-diode
  connect(contact, ntap)
  connect(ntap, nwell) # Nwell

  logger.info('Executing rule ANT.8')
  antenna_check(tgate, contact, 10)
    .output('ANT.8',
            'ANT.8: Maximum ratio of contact area to related gate oxide area: 10')
end
# =========================================================
# METAL1
# =========================================================
GF180_DRC_REGISTRY.register(
  id: 'antenna_metal1',
  path: __FILE__,
  priority: 10,
  tags: %w[all feol antenna]
) do
  # Clear all connections so far
  clear_connections

  # Set up the connections for the antenna check
  connect(poly2_drawn, tgate)
  connect(poly2_drawn, nom_gate)
  connect(poly2_drawn, thick_gate)
  connect(poly2_drawn, contact)
  connect(contact, n_diode) # N-diode
  connect(contact, p_diode) # P-diode
  connect(contact, ntap)
  connect(ntap, nwell) # Nwell
  connect(contact, metal1_drawn)

  logger.info('Executing rule ANT.16_i_ANT.2')
  # Rule ANT.16_i_ANT.2: Diode filtering for ANT.2 [thin gate] , MF = 2
  antenna_check_gf180mcu(nom_gate, metal1_drawn, 0.54, 400, n_diode, p_diode, nwell, 2)
    .output('ANT.16_i_ANT.2',
            'ANT.16_i_ANT.2: Maximum ratio of Metal1 perimeter area to related thin gate oxide area: 400')
  logger.info('Executing rule ANT.16_ii_ANT.2')
  # Rule ANT.16_ii_ANT.2: Diode filtering for ANT.2 [thick gate] , MF = 15
  antenna_check_gf180mcu(thick_gate, metal1_drawn, 0.54, 400, n_diode, p_diode, nwell, 15)
    .output('ANT.16_ii_ANT.2',
            'ANT.16_ii_ANT.2: Maximum ratio of Metal1 perimeter area to related thick gate oxide area: 400')
end
# =========================================================
# VIA1
# =========================================================
GF180_DRC_REGISTRY.register(
  id: 'antenna_via1',
  path: __FILE__,
  priority: 10,
  tags: %w[all feol antenna]
) do
  # Clear all connections so far
  clear_connections

  # Set up the connections for the antenna check
  connect(poly2_drawn, tgate)
  connect(poly2_drawn, nom_gate)
  connect(poly2_drawn, thick_gate)
  connect(poly2_drawn, contact)
  connect(contact, n_diode) # N-diode
  connect(contact, p_diode) # P-diode
  connect(contact, ntap)
  connect(ntap, nwell) # Nwell
  connect(contact, metal1_drawn)
  connect(metal1_drawn, via1)

  logger.info('Executing rule ANT.16_i_ANT.9')
  antenna_check_gf180mcu_area(nom_gate, via1, 20, n_diode, p_diode, nwell, 2)
    .output('ANT.16_i_ANT.9',
            'ANT.16_i_ANT.9: Maximum ratio of Via1 area to related thin gate oxide area: 20')
  logger.info('Executing rule ANT.16_ii_ANT.9')
  antenna_check_gf180mcu_area(thick_gate, via1, 20, n_diode, p_diode, nwell, 15)
    .output('ANT.16_ii_ANT.9',
            'ANT.16_ii_ANT.9: Maximum ratio of Via1 area to related thick gate oxide area: 20')
end
# =========================================================
# METAL2
# =========================================================
GF180_DRC_REGISTRY.register(
  id: 'antenna_metal2',
  path: __FILE__,
  priority: 10,
  tags: %w[all feol antenna]
) do
  # Clear all connections so far
  clear_connections

  # Set up the connections for the antenna check
  connect(poly2_drawn, tgate)
  connect(poly2_drawn, nom_gate)
  connect(poly2_drawn, thick_gate)
  connect(poly2_drawn, contact)
  connect(contact, n_diode) # N-diode
  connect(contact, p_diode) # P-diode
  connect(contact, ntap)
  connect(ntap, nwell) # Nwell
  connect(contact, metal1_drawn)
  connect(metal1_drawn, via1)
  connect(via1, metal2_drawn)

  logger.info('Executing rule ANT.16_i_ANT.3')
  antenna_check_gf180mcu(nom_gate, metal2_drawn, 0.54, 400, n_diode, p_diode, nwell, 2)
    .output('ANT.16_i_ANT.3',
            'ANT.16_i_ANT.3: Maximum ratio of Metal2 perimeter area to related gate oxide area: 400')
  logger.info('Executing rule ANT.16_ii_ANT.3')
  antenna_check_gf180mcu(thick_gate, metal2_drawn, 0.54, 400, n_diode, p_diode, nwell, 15)
    .output('ANT.16_ii_ANT.3',
            'ANT.16_ii_ANT.3: Maximum ratio of Metal2 perimeter area to related gate oxide area: 400')
end
# =========================================================
# VIA2
# =========================================================
GF180_DRC_REGISTRY.register(
  id: 'antenna_via2',
  path: __FILE__,
  priority: 10,
  tags: %w[all feol antenna]
) do
  next unless ctx.metal_level_numerical >= 3

  # Clear all connections so far
  clear_connections

  # Set up the connections for the antenna check
  connect(poly2_drawn, tgate)
  connect(poly2_drawn, nom_gate)
  connect(poly2_drawn, thick_gate)
  connect(poly2_drawn, contact)
  connect(contact, n_diode) # N-diode
  connect(contact, p_diode) # P-diode
  connect(contact, ntap)
  connect(ntap, nwell) # Nwell
  connect(contact, metal1_drawn)
  connect(metal1_drawn, via1)
  connect(via1, metal2_drawn)
  connect(metal2_drawn, via2)

  # MIM A is between Metal2 and Metal3
  connect(via2, fusetop) if ctx.mim_option == 'A'

  logger.info('Executing rule ANT.16_i_ANT.10')
  antenna_check_gf180mcu_area(nom_gate, via2, 20, n_diode, p_diode, nwell, 2)
    .output('ANT.16_i_ANT.10',
            'ANT.16_i_ANT.10: Maximum ratio of Via2 area to related thin gate oxide area: 20')
  logger.info('Executing rule ANT.16_ii_ANT.10')
  antenna_check_gf180mcu_area(thick_gate, via2, 20, n_diode, p_diode, nwell, 15)
    .output('ANT.16_ii_ANT.10',
            'ANT.16_ii_ANT.10: Maximum ratio of Via2 area to related thick gate oxide area: 20')
  if ctx.mim_option == 'A'
    logger.info('Executing rule ANT.16_iii_ANT.15_V2_MIMA')
    antenna_check_gf180mcu_area(fusetop, via2, 20, n_diode, p_diode, nwell, 15)
      .output('ANT.16_iii_ANT.15_V2_MIMA',
              'ANT.16_iii_ANT.15_V2_MIMA: Maximum ratio of Via2 area to related MIM area is 20')
  end
end
# =========================================================
# METAL3
# =========================================================
GF180_DRC_REGISTRY.register(
  id: 'antenna_metal3',
  path: __FILE__,
  priority: 10,
  tags: %w[all feol antenna]
) do
  next unless ctx.metal_level_numerical >= 3

  # Clear all connections so far
  clear_connections

  # Set up the connections for the antenna check
  connect(poly2_drawn, tgate)
  connect(poly2_drawn, nom_gate)
  connect(poly2_drawn, thick_gate)
  connect(poly2_drawn, contact)
  connect(contact, n_diode) # N-diode
  connect(contact, p_diode) # P-diode
  connect(contact, ntap)
  connect(ntap, nwell) # Nwell
  connect(contact, metal1_drawn)
  connect(metal1_drawn, via1)
  connect(via1, metal2_drawn)
  connect(metal2_drawn, via2)
  connect(via2, metal3_drawn)

  # MIM A is between Metal2 and Metal3
  connect(via2, fusetop) if ctx.mim_option == 'A'

  # Is this the topmost metal layer?
  met_thick = ctx.metal_level_numerical == 3 ? metal_top_thickness : 0.54

  logger.info('Executing rule ANT.16_i_ANT.4')
  antenna_check_gf180mcu(nom_gate, metal3_drawn, met_thick, 400, n_diode, p_diode, nwell, 2)
    .output('ANT.16_i_ANT.4',
            'ANT.16_i_ANT.4: Maximum ratio of Metal3 perimeter area to related thin gate oxide area: 400')
  logger.info('Executing rule ANT.16_ii_ANT.4')
  antenna_check_gf180mcu(thick_gate, metal3_drawn, met_thick, 400, n_diode, p_diode, nwell, 15)
    .output('ANT.16_ii_ANT.4',
            'ANT.16_ii_ANT.4: Maximum ratio of Metal3 perimeter area to related thick gate oxide area: 400')
  if ctx.mim_option == 'A'
    logger.info('Executing rule ANT.16_iii_ANT.15_M3_MIMA')
    antenna_check_gf180mcu(fusetop, metal3_drawn, met_thick, 400, n_diode, p_diode, nwell, 15)
      .output('ANT.16_iii_ANT.14_M3_MIMA',
              'ANT.16_iii_ANT.14_M3_MIMA: Maximum ratio of Metal3 perimeter area to related MIM area is 400')
  end
end
# =========================================================
# VIA3
# =========================================================
GF180_DRC_REGISTRY.register(
  id: 'antenna_via3',
  path: __FILE__,
  priority: 10,
  tags: %w[all feol antenna]
) do
  next unless ctx.metal_level_numerical >= 4

  # Clear all connections so far
  clear_connections

  # Set up the connections for the antenna check
  connect(poly2_drawn, tgate)
  connect(poly2_drawn, nom_gate)
  connect(poly2_drawn, thick_gate)
  connect(poly2_drawn, contact)
  connect(contact, n_diode) # N-diode
  connect(contact, p_diode) # P-diode
  connect(contact, ntap)
  connect(ntap, nwell) # Nwell
  connect(contact, metal1_drawn)
  connect(metal1_drawn, via1)
  connect(via1, metal2_drawn)
  connect(metal2_drawn, via2)
  connect(via2, metal3_drawn)
  connect(metal3_drawn, via3)

  # MIM A is between Metal2 and Metal3
  connect(via2, fusetop) if ctx.mim_option == 'A'

  # MIM B is between TopMetal-1 and TopMetal
  connect(via3, fusetop) if ctx.mim_option == 'B'

  logger.info('Executing rule ANT.16_i_ANT.11')
  antenna_check_gf180mcu_area(nom_gate, via3, 20, n_diode, p_diode, nwell, 2)
    .output('ANT.16_i_ANT.11',
            'ANT.16_i_ANT.11: Maximum ratio of Via3 area to related thin gate oxide area: 20')
  logger.info('Executing rule ANT.16_ii_ANT.11')
  antenna_check_gf180mcu_area(thick_gate, via3, 20, n_diode, p_diode, nwell, 15)
    .output('ANT.16_ii_ANT.11',
            'ANT.16_ii_ANT.11: Maximum ratio of Via3 area to related thick gate oxide area: 20')
  if %w[A B].include? ctx.mim_option
    logger.info("Executing rule ANT.16_iii_ANT.15_V3_MIM#{ctx.mim_option}")
    antenna_check_gf180mcu_area(fusetop, via3, 20, n_diode, p_diode, nwell, 15)
      .output("ANT.16_iii_ANT.15_V3_MIM#{ctx.mim_option}",
              "ANT.16_iii_ANT.15_V3_MIM#{ctx.mim_option}: Maximum ratio of Via3 area to related MIM area is 20")
  end
end
# =========================================================
# METAL4
# =========================================================
GF180_DRC_REGISTRY.register(
  id: 'antenna_metal4',
  path: __FILE__,
  priority: 10,
  tags: %w[all feol antenna]
) do
  next unless ctx.metal_level_numerical >= 4

  # Clear all connections so far
  clear_connections

  # Set up the connections for the antenna check
  connect(poly2_drawn, tgate)
  connect(poly2_drawn, nom_gate)
  connect(poly2_drawn, thick_gate)
  connect(poly2_drawn, contact)
  connect(contact, n_diode) # N-diode
  connect(contact, p_diode) # P-diode
  connect(contact, ntap)
  connect(ntap, nwell) # Nwell
  connect(contact, metal1_drawn)
  connect(metal1_drawn, via1)
  connect(via1, metal2_drawn)
  connect(metal2_drawn, via2)
  connect(via2, metal3_drawn)
  connect(metal3_drawn, via3)
  connect(via3, metal4_drawn)

  # MIM A is between Metal2 and Metal3
  connect(via2, fusetop) if ctx.mim_option == 'A'

  # MIM B is between TopMetal-1 and TopMetal
  connect(via3, fusetop) if ctx.mim_option == 'B'

  # Is this the topmost metal layer?
  met_thick = ctx.metal_level_numerical == 4 ? metal_top_thickness : 0.54

  logger.info('Executing rule ANT.16_i_ANT.5')
  antenna_check_gf180mcu(nom_gate, metal4_drawn, met_thick, 400, n_diode, p_diode, nwell, 2)
    .output('ANT.16_i_ANT.5',
            'ANT.16_i_ANT.5: Maximum ratio of Metal4 perimeter area to related gate oxide area: 400')
  logger.info('Executing rule ANT.16_ii_ANT.5')
  antenna_check_gf180mcu(thick_gate, metal4_drawn, met_thick, 400, n_diode, p_diode, nwell, 15)
    .output('ANT.16_ii_ANT.5',
            'ANT.16_ii_ANT.5: Maximum ratio of Metal4 perimeter area to related gate oxide area: 400')
  if %w[A B].include? ctx.mim_option
    logger.info("Executing rule ANT.16_iii_ANT.15_M4_MIM#{ctx.mim_option}")
    antenna_check_gf180mcu(fusetop, metal4_drawn, met_thick, 400, n_diode, p_diode, nwell, 15)
      .output("ANT.16_iii_ANT.14_M4_MIM#{ctx.mim_option}",
              "ANT.16_iii_ANT.14_M4_MIM#{ctx.mim_option}: Maximum ratio of Metal4 perimeter area to related MIM area is 400")
  end
end
# =========================================================
# VIA4
# =========================================================
GF180_DRC_REGISTRY.register(
  id: 'antenna_via4',
  path: __FILE__,
  priority: 10,
  tags: %w[all feol antenna]
) do
  next unless ctx.metal_level_numerical >= 5

  # Clear all connections so far
  clear_connections

  # Set up the connections for the antenna check
  connect(poly2_drawn, tgate)
  connect(poly2_drawn, nom_gate)
  connect(poly2_drawn, thick_gate)
  connect(poly2_drawn, contact)
  connect(contact, n_diode) # N-diode
  connect(contact, p_diode) # P-diode
  connect(contact, ntap)
  connect(ntap, nwell) # Nwell
  connect(contact, metal1_drawn)
  connect(metal1_drawn, via1)
  connect(via1, metal2_drawn)
  connect(metal2_drawn, via2)
  connect(via2, metal3_drawn)
  connect(metal3_drawn, via3)
  connect(via3, metal4_drawn)
  connect(metal4_drawn, via4)

  # MIM A is between Metal2 and Metal3
  connect(via2, fusetop) if ctx.mim_option == 'A'

  # MIM B is between TopMetal-1 and TopMetal
  connect(via4, fusetop) if ctx.mim_option == 'B'

  logger.info('Executing rule ANT.16_i_ANT.12')
  antenna_check_gf180mcu_area(nom_gate, via4, 20, n_diode, p_diode, nwell, 2)
    .output('ANT.16_i_ANT.12',
            'ANT.16_i_ANT.12: Maximum ratio of Via4 area to related thin gate oxide area: 20')
  logger.info('Executing rule ANT.16_ii_ANT.12')
  antenna_check_gf180mcu_area(thick_gate, via4, 20, n_diode, p_diode, nwell, 15)
    .output('ANT.16_ii_ANT.12',
            'ANT.16_ii_ANT.12: Maximum ratio of Via4 area to related thick gate oxide area: 20')
  if %w[A B].include? ctx.mim_option
    logger.info("Executing rule ANT.16_iii_ANT.15_V4_MIM#{ctx.mim_option}")
    antenna_check_gf180mcu_area(fusetop, via4, 20, n_diode, p_diode, nwell, 15)
      .output("ANT.16_iii_ANT.15_V4_MIM#{ctx.mim_option}",
              "ANT.16_iii_ANT.15_V4_MIM#{ctx.mim_option}: Maximum ratio of Via4 area to related MIM area is 20")
  end
end
# =========================================================
# METAL5
# =========================================================
GF180_DRC_REGISTRY.register(
  id: 'antenna_metal5',
  path: __FILE__,
  priority: 10,
  tags: %w[all feol antenna]
) do
  next unless ctx.metal_level_numerical >= 5

  # Clear all connections so far
  clear_connections

  # Set up the connections for the antenna check
  connect(poly2_drawn, tgate)
  connect(poly2_drawn, nom_gate)
  connect(poly2_drawn, thick_gate)
  connect(poly2_drawn, contact)
  connect(contact, n_diode) # N-diode
  connect(contact, p_diode) # P-diode
  connect(contact, ntap)
  connect(ntap, nwell) # Nwell
  connect(contact, metal1_drawn)
  connect(metal1_drawn, via1)
  connect(via1, metal2_drawn)
  connect(metal2_drawn, via2)
  connect(via2, metal3_drawn)
  connect(metal3_drawn, via3)
  connect(via3, metal4_drawn)
  connect(metal4_drawn, via4)
  connect(via4, metal5_drawn)

  # MIM A is between Metal2 and Metal3
  connect(via2, fusetop) if ctx.mim_option == 'A'

  # MIM B is between TopMetal-1 and TopMetal
  connect(via4, fusetop) if ctx.mim_option == 'B'

  # Is this the topmost metal layer?
  met_thick = ctx.metal_level_numerical == 5 ? metal_top_thickness : 0.54

  logger.info('Executing rule ANT.16_i_ANT.6')
  antenna_check_gf180mcu(nom_gate, metal5_drawn, met_thick, 400, n_diode, p_diode, nwell, 2)
    .output('ANT.16_i_ANT.6',
            'ANT.16_i_ANT.6: Maximum ratio of Metal5 perimeter area to related thin gate oxide area: 400')
  logger.info('Executing rule ANT.16_ii_ANT.6')
  antenna_check_gf180mcu(thick_gate, metal5_drawn, met_thick, 400, n_diode, p_diode, nwell, 15)
    .output('ANT.16_ii_ANT.6',
            'ANT.16_ii_ANT.6: Maximum ratio of Metal5 perimeter area to related thick gate oxide area 400')
  if %w[A B].include? ctx.mim_option
    logger.info("Executing rule ANT.16_iii_ANT.15_M5_MIM#{ctx.mim_option}")
    antenna_check_gf180mcu(fusetop, metal5_drawn, met_thick, 400, n_diode, p_diode, nwell, 15)
      .output("ANT.16_iii_ANT.14_M5_MIM#{ctx.mim_option}",
              "ANT.16_iii_ANT.14_M5_MIM#{ctx.mim_option}: Maximum ratio of Metal5 perimeter area to related MIM area is 400")
  end
end
# =========================================================
# VIA5
# =========================================================
GF180_DRC_REGISTRY.register(
  id: 'antenna_via5',
  path: __FILE__,
  priority: 10,
  tags: %w[all feol antenna]
) do
  next unless ctx.metal_level_numerical >= 6

  # Clear all connections so far
  clear_connections

  # Set up the connections for the antenna check
  connect(poly2_drawn, tgate)
  connect(poly2_drawn, nom_gate)
  connect(poly2_drawn, thick_gate)
  connect(poly2_drawn, contact)
  connect(contact, n_diode) # N-diode
  connect(contact, p_diode) # P-diode
  connect(contact, ntap)
  connect(ntap, nwell) # Nwell
  connect(contact, metal1_drawn)
  connect(metal1_drawn, via1)
  connect(via1, metal2_drawn)
  connect(metal2_drawn, via2)
  connect(via2, metal3_drawn)
  connect(metal3_drawn, via3)
  connect(via3, metal4_drawn)
  connect(metal4_drawn, via4)
  connect(via4, metal5_drawn)
  connect(metal5_drawn, via5)

  # MIM A is between Metal2 and Metal3
  connect(via2, fusetop) if ctx.mim_option == 'A'

  # MIM B is between TopMetal-1 and TopMetal
  connect(via5, fusetop) if ctx.mim_option == 'B'

  logger.info('Executing rule ANT.16_i_ANT.13')
  antenna_check_gf180mcu_area(nom_gate, via5, 20, n_diode, p_diode, nwell, 2)
    .output('ANT.16_i_ANT.13',
            'ANT.16_i_ANT.13: Maximum ratio of Via5 area to related thin gate oxide area: 20')
  logger.info('Executing rule ANT.16_ii_ANT.13')
  antenna_check_gf180mcu_area(thick_gate, via5, 20, n_diode, p_diode, nwell, 15)
    .output('ANT.16_ii_ANT.13',
            'ANT.16_ii_ANT.13: Maximum ratio of Via5 area to related thick gate oxide area: 20')
  if %w[A B].include? ctx.mim_option
    logger.info("Executing rule ANT.16_iii_ANT.15_V5_MIM#{ctx.mim_option}")
    antenna_check_gf180mcu_area(fusetop, via5, 20, n_diode, p_diode, nwell, 15)
      .output("ANT.16_iii_ANT.15_V5_MIM#{ctx.mim_option}",
              "ANT.16_iii_ANT.15_V5_MIM#{ctx.mim_option}: Maximum ratio of Via5 area to related MIM area is 20")
  end
end
# =========================================================
# METALTOP (+ MIM-B top rule)
# =========================================================
GF180_DRC_REGISTRY.register(
  id: 'antenna_metaltop',
  path: __FILE__,
  priority: 10,
  tags: %w[all feol antenna]
) do
  next unless ctx.metal_level_numerical >= 6

  # Clear all connections so far
  clear_connections

  # Set up the connections for the antenna check
  connect(poly2_drawn, tgate)
  connect(poly2_drawn, nom_gate)
  connect(poly2_drawn, thick_gate)
  connect(poly2_drawn, contact)
  connect(contact, n_diode) # N-diode
  connect(contact, p_diode) # P-diode
  connect(contact, ntap)
  connect(ntap, nwell) # Nwell
  connect(contact, metal1_drawn)
  connect(metal1_drawn, via1)
  connect(via1, metal2_drawn)
  connect(metal2_drawn, via2)
  connect(via2, metal3_drawn)
  connect(metal3_drawn, via3)
  connect(via3, metal4_drawn)
  connect(metal4_drawn, via4)
  connect(via4, metal5_drawn)
  connect(metal5_drawn, via5)
  connect(via5, metaltop_drawn)

  # MIM A is between Metal2 and Metal3
  connect(via2, fusetop) if ctx.mim_option == 'A'

  # MIM B is between TopMetal-1 and TopMetal
  connect(via5, fusetop) if ctx.mim_option == 'B'

  met_top_thick = metal_top_thickness
  logger.info('Executing rule ANT.16_i_ANT.7')
  antenna_check_gf180mcu(nom_gate, metaltop_drawn, met_top_thick, 400, n_diode, p_diode, nwell, 2)
    .output('ANT.16_i_ANT.7',
            'ANT.16_i_ANT.7: Maximum ratio of Metaltop perimeter area to related thin gate oxide area: 400')
  logger.info('Executing rule ANT.16_ii_ANT.7')
  antenna_check_gf180mcu(thick_gate, metaltop_drawn, met_top_thick, 400, n_diode, p_diode, nwell, 15)
    .output('ANT.16_ii_ANT.7',
            'ANT.16_ii_ANT.7: Maximum ratio of Metaltop perimeter area to related thick gate oxide area: 400')
  if %w[A B].include? ctx.mim_option
    logger.info("Executing rule ANT.16_iii_ANT.15_MT_MIM#{ctx.mim_option}")
    antenna_check_gf180mcu(fusetop, metaltop_drawn, met_top_thick, 400, n_diode, p_diode, nwell, 15)
      .output("ANT.16_iii_ANT.14_MT_MIM#{ctx.mim_option}",
              "ANT.16_iii_ANT.14_MT_MIM#{ctx.mim_option}: Maximum ratio of Metaltop perimeter area to related MIM area is 400")
  end
end

# rubocop:enable Metrics/ParameterLists
# rubocop:enable Naming/MethodParameterName
# rubocop:enable Layout/LineLength
