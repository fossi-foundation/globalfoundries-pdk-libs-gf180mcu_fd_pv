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

GF180_DRC_REGISTRY.register(
  id: File.basename(__FILE__, File.extname(__FILE__)),
  path: __FILE__,
  priority: 0,
  tags: %w[all density]
) do
  chip_area = extent.sized(0.0).area

  # Rule DCF.1b: Minimum global density for active layers (COMP+ Dummy COMP) shall be 25%.
  logger.info('Executing rule DCF.1b')
  comp_ratio = (comp + comp_dummy).area / chip_area
  logger.info("COMP ratio: #{comp_ratio * 100} %")
  if comp_ratio * 100 < 25
    extent.output('DCF.1b',
                  'DCF.1b : Global density for active layers (COMP+ Dummy COMP) shall be >= 25%')
  end

  # Rule DCF.1d: Maximum global density for active layers (COMP+ Dummy COMP) shall be 70%.
  logger.info('Executing rule DCF.1d')
  if comp_ratio * 100 > 70
    extent.output('DCF.1d',
                  'DCF.1d : Global density for active layers (COMP+ Dummy COMP) shall be <= 70%')
  end

  # Rule PL.8: Poly2 coverage over the entire die shall be 14%.
  ## Dummy poly2 lines must be added to meet the minimum poly2 density requirement.
  logger.info('Executing rule PL.8')
  poly2_ratio = poly2.area / chip_area
  logger.info("Poly2 ratio: #{poly2_ratio * 100} %")
  if poly2_ratio * 100 < 14
    extent.output('PL.8',
                  'PL.8 : Poly2 coverage over the entire die shall be 14%.
                  Dummy poly2 lines must be added to meet the minimum poly2 density requirement. : 14%')
  end

  # Rule M1.4: Metal1 coverage over the entire die shall be >30%
  ## (Refer to section 13.0 for Dummy Metal fill guidelines.
  ## Customer needs to ensure enough dummy metal to satisfy Metal1 coverage)
  logger.info('Executing rule M1.4')
  metal1_ratio = metal1.area / chip_area
  logger.info("Metal1 ratio: #{metal1_ratio * 100} %")
  if metal1_ratio * 100 < 30
    extent.output('M1.4',
                  'M1.4 : Metal1 coverage over the entire die shall be >30%
                  (Refer to section 13.0 for Dummy Metal fill guidelines.
                   Customer needs to ensure enough dummy metal to satisfy Metal1 coverage) : 30%')
  end

  # Rule M2.4: Metal2 coverage over the entire die shall be >30%
  ## (Refer to section 13.0 for Dummy Metal fill guidelines.
  ## Customer needs to ensure enough dummy metal to satisfy Metal2 coverage)
  logger.info('Executing rule M2.4')
  metal2_ratio = metal2.area / chip_area
  logger.info("Metal2 ratio: #{metal2_ratio * 100} %")
  if metal2_ratio * 100 < 30
    extent.output('M2.4',
                  'M2.4 : Metal2 coverage over the entire die shall be >30%
                  (Refer to section 13.0 for Dummy Metal fill guidelines.
                   Customer needs to ensure enough dummy metal to satisfy Metal2 coverage) : 30%')
  end

  if ctx.metal_level_numerical >= 3
    # Rule M3.4: metal3 coverage over the entire die shall be >30%
    ## (Refer to section 13.0 for Dummy Metal fill guidelines.
    ## Customer needs to ensure enough dummy metal to satisfy metal3 coverage)
    logger.info('Executing rule M3.4')
    metal3_ratio = metal3.area / chip_area
    logger.info("Metal3 ratio: #{metal3_ratio * 100} %")
    if metal3_ratio * 100 < 30
      extent.output('M3.4',
                    'M3.4 : metal3 coverage over the entire die shall be >30%
                      (Refer to section 13.0 for Dummy Metal fill guidelines.
                      Customer needs to ensure enough dummy metal to satisfy metal3 coverage) : 30%')
    end
  end

  if ctx.metal_level_numerical >= 4
    # Rule M4.4: metal4 coverage over the entire die shall be >30%
    ## (Refer to section 13.0 for Dummy Metal fill guidelines.
    ## Customer needs to ensure enough dummy metal to satisfy metal4 coverage)
    logger.info('Executing rule M4.4')
    metal4_ratio = metal4.area / chip_area
    logger.info("Metal4 ratio: #{metal4_ratio * 100} %")
    if metal4_ratio * 100 < 30
      extent.output('M4.4',
                    'M4.4 : metal4 coverage over the entire die shall be >30%
                      (Refer to section 13.0 for Dummy Metal fill guidelines.
                      Customer needs to ensure enough dummy metal to satisfy metal4 coverage) : 30%')
    end
  end

  if ctx.metal_level_numerical >= 5
    # Rule M5.4: metal5 coverage over the entire die shall be >30%
    ## (Refer to section 13.0 for Dummy Metal fill guidelines.
    ## Customer needs to ensure enough dummy metal to satisfy metal5 coverage)
    logger.info('Executing rule M5.4')
    metal5_ratio = metal5.area / chip_area
    logger.info("Metal5 ratio: #{metal5_ratio * 100} %")
    if metal5_ratio * 100 < 30
      extent.output('M5.4',
                    'M5.4 : metal5 coverage over the entire die shall be >30%
                      (Refer to section 13.0 for Dummy Metal fill guidelines.
                      Customer needs to ensure enough dummy metal to satisfy metal5 coverage) : 30%')
    end
  end

  if ctx.metal_top == '30K'
    # Rule MT30.7: Thick MetalTop coverage over the entire die shall be >30%
    ## (Refer to section 13.0 for Dummy Metal-fill guidelines.
    ## Customer needs to ensure enough dummy metal to satisfy Metaln coverage).
    logger.info('Executing rule MT30.7')
    top_metal_ratio = top_metal.area / chip_area
    logger.info("MetalTop ratio: #{top_metal_ratio * 100} %")
    if top_metal_ratio * 100 < 30
      extent.output('MT30.7',
                    'MT30.7 : Thick MetalTop coverage over the entire die shall be >30%
                                  (Refer to section 13.0 for Dummy Metal-fill guidelines.
                                  Customer needs to ensure enough dummy metal to satisfy Metaln coverage). : 30%')
    end
  else
    # Rule MT.3: MetalTop coverage over the entire die shall be >30%
    ## (Refer to section 10.3 for Dummy Metal-fill guidelines.
    ## Customer needs to ensure enough dummy metal to satisfy Metaln coverage)
    logger.info('Executing rule MT.3')
    top_metal_ratio = top_metal.area / chip_area
    logger.info("MetalTop ratio: #{top_metal_ratio * 100} %")
    if top_metal_ratio * 100 < 30
      extent.output('MT.3',
                    'MT.3 : MetalTop coverage over the entire die shall be >30%
                                  (Refer to section 10.3 for Dummy Metal-fill guidelines.
                                  Customer needs to ensure enough dummy metal to satisfy Metaln coverage) : 30%')
    end
  end
end
