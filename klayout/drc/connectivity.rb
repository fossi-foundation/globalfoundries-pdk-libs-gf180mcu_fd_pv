# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright 2026 GlobalFoundries PDK Authors
# SPDX-License-Identifier: Apache License 2.0

module GF180DRC
  # Connects electrically the appropriate layers
  module Connectivity
    BASE_CONNECTIONS = [
      %i[tgate poly2],
      %i[nom_gate poly2],
      %i[thick_gate poly2],
      %i[poly2 contact],
      %i[dnwell ncomp],
      %i[lvpwell_out pcomp],
      %i[lvpwell_dn pcomp],
      %i[nwell ncomp],
      %i[mvsd ncomp],
      %i[mvpsd pcomp],
      %i[ncomp contact],
      %i[pcomp contact],
      %i[natcomp contact],
      %i[contact metal1_drawn],
      %i[metal1_drawn via1],
      %i[via1 metal2_drawn]
    ].freeze

    METAL_STACK = [
      [3, :metal2_drawn, :via2, :metal3_drawn],
      [4, :metal3_drawn, :via3, :metal4_drawn],
      [5, :metal4_drawn, :via4, :metal5_drawn],
      [6, :metal5_drawn, :via5, :metaltop_drawn]
    ].freeze

    def self.build(ctx, drc)
      BASE_CONNECTIONS.each { |a, b| drc.connect(ctx[a], ctx[b]) }

      METAL_STACK.each do |level, from, via, to|
        next unless ctx.metal_level_numerical >= level

        drc.connect(ctx[from], ctx[via])
        drc.connect(ctx[via], ctx[to])
        drc.connect(ctx[to], ctx[:fusetop]) if ctx.mim_option == 'A'
      end

      drc.connect(ctx[:top_metal_drawn], ctx[:fusetop]) if ctx.mim_option == 'B'
    end
  end
end
