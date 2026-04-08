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

GF180_DRC_REGISTRY.register(
  id: File.basename(__FILE__, File.extname(__FILE__)),
  path: __FILE__,
  tags: %w[feol nat_split]
) do
  #================================================
  #-----------------NATIVE VT NMOS-----------------
  #================================================
  next unless ctx.feol? && ctx.split_deep?

  if ctx.connectivity?
    logger.info('ctx.connectivity? section')
    _connected_nat, unconnected_nat = conn_space(natcomp, 10, 10, transparent)

    # Rule NAT.6: Two or more COMPs if connected to different potential
    ## are not allowed under same NAT layer.
    logger.info('Executing rule NAT.6')
    nat6_l1 = comp.and(nat).interacting(unconnected_nat.inside(nat.covering(comp, 2)).not(poly2))
    nat6_l1.output('NAT.6', "NAT.6 : Two or more COMPs if connected to different potential
                          are not allowed under same NAT layer.")
    nat6_l1.forget
  end
  natcomp.forget
end
