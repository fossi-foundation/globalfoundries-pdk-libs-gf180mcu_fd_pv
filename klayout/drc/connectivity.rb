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
      %i[contact metal1],
      %i[metal1 via1],
      %i[via1 metal2]
    ].freeze

    METAL_STACK = [
      [3, :metal2, :via2, :metal3],
      [4, :metal3, :via3, :metal4],
      [5, :metal4, :via4, :metal5],
      [6, :metal5, :via5, :metaltop]
    ].freeze

    def self.build(ctx, drc)
      BASE_CONNECTIONS.each { |a, b| drc.connect(ctx[a], ctx[b]) }

      METAL_STACK.each do |level, from, via, to|
        next unless ctx.metal_level_numerical >= level

        drc.connect(ctx[from], ctx[via])
        drc.connect(ctx[via], ctx[to])
        drc.connect(ctx[to], ctx[:fusetop]) if ctx.mim_option == 'A'
      end

      drc.connect(ctx[:top_metal], ctx[:fusetop]) if ctx.mim_option == 'B'
    end
  end
end
