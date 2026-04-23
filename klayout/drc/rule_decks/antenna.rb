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
# Shared helper (same file)
def antenna_met_top_thick(ctx)
  case ctx.metal_top
  when '6K'  then 0.69.um
  when '9K'  then 0.99.um
  when '11K' then 1.19.um
  when '30K' then 3.035.um
  else
    raise ArgumentError, 'metal_top not recognized'
  end
end
# =========================================================
# POLY
# =========================================================
GF180_DRC_REGISTRY.register(
  id: 'antenna_poly2',
  path: __FILE__,
  priority: 10,
  tags: %w[feol antenna]
) do
  logger.info('Executing rule ANT.1')
  antenna_check(tgate, perimeter_only(poly2, 0.2.um), 200)
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
  tags: %w[feol antenna]
) do
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
  tags: %w[feol antenna]
) do
  logger.info('Executing rule ANT.16_i_ANT.2')
  antenna_check(nom_gate, perimeter_only(metal1, 0.54.um), 400, [ncomp, 800])
    .output('ANT.16_i_ANT.2',
            'ANT.16_i_ANT.2: Maximum ratio of Metal1 perimeter area to related thin gate oxide area: 400')
  logger.info('Executing rule ANT.16_ii_ANT.2')
  antenna_check(thick_gate, perimeter_only(metal1, 0.54.um), 400, [ncomp, 6000])
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
  tags: %w[feol antenna]
) do
  logger.info('Executing rule ANT.16_i_ANT.9')
  antenna_check(nom_gate, via1, 20, [ncomp, 40])
    .output('ANT.16_i_ANT.9',
            'ANT.16_i_ANT.9: Maximum ratio of Via1 area to related thin gate oxide area: 20')
  logger.info('Executing rule ANT.16_ii_ANT.9')
  antenna_check(thick_gate, via1, 20, [ncomp, 300])
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
  tags: %w[feol antenna]
) do
  logger.info('Executing rule ANT.16_i_ANT.3')
  antenna_check(nom_gate, perimeter_only(metal2, 0.54.um), 400, [ncomp, 800])
    .output('ANT.16_i_ANT.3',
            'ANT.16_i_ANT.3: Maximum ratio of Metal2 perimeter area to related gate oxide area: 400')
  logger.info('Executing rule ANT.16_ii_ANT.3')
  antenna_check(thick_gate, perimeter_only(metal2, 0.54.um), 400, [ncomp, 6000])
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
  tags: %w[feol antenna]
) do
  next unless ctx.metal_level_numerical >= 3

  logger.info('Executing rule ANT.16_i_ANT.10')
  antenna_check(nom_gate, via2, 20, [ncomp, 40])
    .output('ANT.16_i_ANT.10',
            'ANT.16_i_ANT.10: Maximum ratio of Via2 area to related thin gate oxide area: 20')
  logger.info('Executing rule ANT.16_ii_ANT.10')
  antenna_check(thick_gate, via2, 20, [ncomp, 300])
    .output('ANT.16_ii_ANT.10',
            'ANT.16_ii_ANT.10: Maximum ratio of Via2 area to related thick gate oxide area: 20')
  if ctx.mim_option == 'A'
    logger.info('Executing rule ANT.16_iii_ANT.15_V2_MIMA')
    antenna_check(fusetop, via2, 20, [ncomp, 300])
      .output('ANT.16_iii_ANT.15_V2_MIMA',
              'ANT.16_iii_ANT.15_V2_MIMA: Maximum ratio of each of Via2 area to related MIM area is 20')
  end
end
# =========================================================
# METAL3
# =========================================================
GF180_DRC_REGISTRY.register(
  id: 'antenna_metal3',
  path: __FILE__,
  priority: 10,
  tags: %w[feol antenna]
) do
  next unless ctx.metal_level_numerical >= 3

  logger.info('Executing rule ANT.16_i_ANT.4')
  antenna_check(nom_gate, perimeter_only(metal3, 0.54.um), 400, [ncomp, 800])
    .output('ANT.16_i_ANT.4',
            'ANT.16_i_ANT.4: Maximum ratio of Metal3 perimeter area to related thin gate oxide area: 400')
  logger.info('Executing rule ANT.16_ii_ANT.4')
  antenna_check(thick_gate, perimeter_only(metal3, 0.54.um), 400, [ncomp, 6000])
    .output('ANT.16_ii_ANT.4',
            'ANT.16_ii_ANT.4: Maximum ratio of Metal3 perimeter area to related thick gate oxide area: 400')
  if ctx.mim_option == 'A'
    logger.info('Executing rule ANT.16_iii_ANT.14_M3_MIMA')
    antenna_check(fusetop, perimeter_only(metal3, 0.54.um), 400, [ncomp, 6000])
      .output('ANT.16_iii_ANT.14_M3_MIMA',
              'ANT.16_iii_ANT.14_M3_MIMA: Maximum ratio of each of the metal3 ' \
              'layer perimeter area to related MIM area is 400')
  end
end
# =========================================================
# VIA3
# =========================================================
GF180_DRC_REGISTRY.register(
  id: 'antenna_via3',
  path: __FILE__,
  priority: 10,
  tags: %w[feol antenna]
) do
  next unless ctx.metal_level_numerical >= 4

  logger.info('Executing rule ANT.16_i_ANT.11')
  antenna_check(nom_gate, via3, 20, [ncomp, 40])
    .output('ANT.16_i_ANT.11',
            'ANT.16_i_ANT.11: Maximum ratio of Via3 area to related thin gate oxide area: 20')
  logger.info('Executing rule ANT.16_ii_ANT.11')
  antenna_check(thick_gate, via3, 20, [ncomp, 300])
    .output('ANT.16_ii_ANT.11',
            'ANT.16_ii_ANT.11: Maximum ratio of Via3 area to related thick gate oxide area: 20')
  if ctx.mim_option == 'A'
    logger.info('Executing rule ANT.16_iii_ANT.15_V3_MIMA')
    antenna_check(fusetop, via3, 20, [ncomp, 300])
      .output('ANT.16_iii_ANT.15_V3_MIMA',
              'ANT.16_iii_ANT.15_V3_MIMA: Maximum ratio of each of Via3 area to related MIM area: 20')
  end
end
# =========================================================
# METAL4
# =========================================================
GF180_DRC_REGISTRY.register(
  id: 'antenna_metal4',
  path: __FILE__,
  priority: 10,
  tags: %w[feol antenna]
) do
  next unless ctx.metal_level_numerical >= 4

  logger.info('Executing rule ANT.16_i_ANT.5')
  antenna_check(nom_gate, perimeter_only(metal4, 0.54.um), 400, [ncomp, 800])
    .output('ANT.16_i_ANT.5',
            'ANT.16_i_ANT.5: Maximum ratio of Metal4 perimeter area to related gate oxide area: 400')
  logger.info('Executing rule ANT.16_ii_ANT.5')
  antenna_check(thick_gate, perimeter_only(metal4, 0.54.um), 400, [ncomp, 6000])
    .output('ANT.16_ii_ANT.5',
            'ANT.16_ii_ANT.5: Maximum ratio of Metal4 perimeter area to related gate oxide area: 400')
  if ctx.mim_option == 'A'
    logger.info('Executing rule ANT.16_iii_ANT.14_M4_MIMA')
    antenna_check(fusetop, perimeter_only(metal4, 0.54.um), 400, [ncomp, 6000])
      .output('ANT.16_iii_ANT.14_M4_MIMA',
              'ANT.16_iii_ANT.14_M4_MIMA: Maximum ratio of each of the metal4 ' \
              'layer perimeter area to related MIM area is 400')
  end
end
# =========================================================
# VIA4
# =========================================================
GF180_DRC_REGISTRY.register(
  id: 'antenna_via4',
  path: __FILE__,
  priority: 10,
  tags: %w[feol antenna]
) do
  next unless ctx.metal_level_numerical >= 5

  logger.info('Executing rule ANT.16_i_ANT.12')
  antenna_check(nom_gate, via4, 20, [ncomp, 40])
    .output('ANT.16_i_ANT.12',
            'ANT.16_i_ANT.12: Maximum ratio of Via4 area to related thin gate oxide area: 20')
  logger.info('Executing rule ANT.16_ii_ANT.12')
  antenna_check(thick_gate, via4, 20, [ncomp, 300])
    .output('ANT.16_ii_ANT.12',
            'ANT.16_ii_ANT.12: Maximum ratio of Via4 area to related thick gate oxide area: 20')
  if ctx.mim_option == 'A'
    logger.info('Executing rule ANT.16_iii_ANT.15_V4_MIMA')
    antenna_check(fusetop, via4, 20, [ncomp, 300])
      .output('ANT.16_iii_ANT.15_V4_MIMA',
              'ANT.16_iii_ANT.15_V4_MIMA: Maximum ratio of each of Via4 area to related MIM area is 20')
  end
end
# =========================================================
# METAL5
# =========================================================
GF180_DRC_REGISTRY.register(
  id: 'antenna_metal5',
  path: __FILE__,
  priority: 10,
  tags: %w[feol antenna]
) do
  next unless ctx.metal_level_numerical >= 5

  logger.info('Executing rule ANT.16_i_ANT.6')
  antenna_check(nom_gate, perimeter_only(metal5, 0.54.um), 400, [ncomp, 800])
    .output('ANT.16_i_ANT.6',
            'ANT.16_i_ANT.6: Maximum ratio of Metal5 perimeter area to related thin gate oxide area: 400')
  logger.info('Executing rule ANT.16_ii_ANT.6')
  antenna_check(thick_gate, perimeter_only(metal5, 0.54.um), 400, [ncomp, 6000])
    .output('ANT.16_ii_ANT.6',
            'ANT.16_ii_ANT.6: Maximum ratio of Metal5 perimeter area to related thick gate oxide area 400')
  if ctx.mim_option == 'A'
    logger.info('Executing rule ANT.16_iii_ANT.14_M5_MIMA')
    antenna_check(fusetop, perimeter_only(metal5, 0.54.um), 400, [ncomp, 6000])
      .output('ANT.16_iii_ANT.14_M5_MIMA',
              'ANT.16_iii_ANT.14_M5_MIMA: Maximum ratio of each of the metal5 ' \
              'layer perimeter area to related MIM area is 400')
  end
end
# =========================================================
# VIA5
# =========================================================
GF180_DRC_REGISTRY.register(
  id: 'antenna_via5',
  path: __FILE__,
  priority: 10,
  tags: %w[feol antenna]
) do
  next unless ctx.metal_level_numerical >= 6

  logger.info('Executing rule ANT.16_i_ANT.13')
  antenna_check(nom_gate, via5, 20, [ncomp, 40])
    .output('ANT.16_i_ANT.13',
            'ANT.16_i_ANT.13: Maximum ratio of Via5 area to related thin gate oxide area: 20')
  logger.info('Executing rule ANT.16_ii_ANT.13')
  antenna_check(thick_gate, via5, 20, [ncomp, 300])
    .output('ANT.16_ii_ANT.13',
            'ANT.16_ii_ANT.13: Maximum ratio of Via5 area to related thick gate oxide area: 20')
  if ctx.mim_option == 'A'
    logger.info('Executing rule ANT.16_iii_ANT.15_V5_MIMA')
    antenna_check(fusetop, via5, 20, [ncomp, 300])
      .output('ANT.16_iii_ANT.15_V5_MIMA',
              'ANT.16_iii_ANT.15_V5_MIMA: Maximum ratio of each of Via5 area to related MIM area: 20')
  end
end
# =========================================================
# METALTOP (+ MIM-B top rule)
# =========================================================
GF180_DRC_REGISTRY.register(
  id: 'antenna_metaltop',
  path: __FILE__,
  priority: 10,
  tags: %w[feol antenna]
) do
  met_top_thick = antenna_met_top_thick(ctx)
  if ctx.metal_level_numerical >= 6
    logger.info('Executing rule ANT.16_i_ANT.7')
    antenna_check(nom_gate, perimeter_only(metaltop, met_top_thick), 400, [ncomp, 800])
      .output('ANT.16_i_ANT.7',
              'ANT.16_i_ANT.7: Maximum ratio of Metaltop perimeter area to related thin gate oxide area: 400')
    logger.info('Executing rule ANT.16_ii_ANT.7')
    antenna_check(thick_gate, perimeter_only(metaltop, met_top_thick), 400, [ncomp, 6000])
      .output('ANT.16_ii_ANT.7',
              'ANT.16_ii_ANT.7: Maximum ratio of Metaltop perimeter area to related thick gate oxide area: 400')
    if ctx.mim_option == 'A'
      logger.info('Executing rule ANT.16_iii_ANT.14_MT_MIMA')
      antenna_check(fusetop, perimeter_only(metaltop, met_top_thick), 400, [ncomp, 6000])
        .output('ANT.16_iii_ANT.14_MT_MIMA',
                'ANT.16_iii_ANT.14_MT_MIMA: Maximum ratio of each of the Metaltop ' \
                'layer perimeter area to related MIM area is 400')
    end
  end
  if ctx.mim_option == 'B'
    logger.info('Executing rule ANT.16_iii_ANT.14_MT_MIMB')
    antenna_check(fusetop, perimeter_only(top_metal, met_top_thick), 400, [ncomp, 6000])
      .output('ANT.16_iii_ANT.14_MT_MIMB',
              'ANT.16_iii_ANT.14_MT_MIMB: Maximum ratio of each of the Top metal ' \
              'layer perimeter area to related MIM area is 400')
  end
end
