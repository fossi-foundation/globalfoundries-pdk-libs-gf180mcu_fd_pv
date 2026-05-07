# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright 2026 GlobalFoundries PDK Authors
# SPDX-License-Identifier: Apache License 2.0

def unconn_errors_check(net1, net2, unconnected_errors)
  if !net1 || !net2
    logger.error("Connectivity check encountered 2 nets that doesn't exist. Potential issue in klayout...")
  elsif net1.circuit != net2.circuit || net1.cluster_id != net2.cluster_id
    # unconnected
    unconnected_errors.data.insert(ep)
  end
  unconnected_errors
end

def get_nets(_data, layer1, layer2, edge_pairs)
  net1 = l2n_data.probe_net(layer1.data, edge_pairs.first.p1)
  net2 = l2n_data.probe_net(layer2.data, edge_pairs.second.p1)
  [net1, net2]
end

def conn_space_viol(layer, conn_val, mode)
  connected_output = layer.space(conn_val.um, mode).polygons(0.001.um)
  singularity_errors = layer.space(0.001.um, mode).polygons(0.001.um)
  [connected_output, singularity_errors]
end

def conn_space_check(layer, not_conn_val, mode)
  unconnected_errors_unfiltered = layer.space(not_conn_val.um, mode)
  connected_output, singularity_errors = conn_space_viol(layer, conn_val, mode)
  # Filter out the errors arising from the same net
  unconnected_errors = DRC::DRCLayer.new(self, RBA::EdgePairs.new)
  unconnected_errors_unfiltered.data.each do |ep|
    net1, net2 = get_nets(l2n_data, layer, layer, ep)
    unconnected_errors = unconn_errors_check(net1, net2, unconnected_errors)
  end
  unconnected_output = unconnected_errors.polygons.join(singularity_errors)
  [connected_output, unconnected_output]
end

def conn_space_nets(layer, conn_val, not_conn_val, mode)
  nets = layer.nets
  connected_output = nets.space(conn_val.um, mode, props_eq).polygons(0.001.um)
  singularity_errors = nets.space(0.001.um, mode).polygons(0.001.um)
  unconnected_output = nets.space(not_conn_val.um, mode, props_ne).polygons(0.001.um).join(singularity_errors)
  [connected_output, unconnected_output]
end

def conn_space(layer, conn_val, not_conn_val, mode)
  if layer.respond_to?(:nets) # KLayout version (>=0.28.4) which supports "nets"
    connected_output, unconnected_output = conn_space_nets(layer, conn_val, not_conn_val, mode)
  else
    raise 'ERROR : Wrong connectivity implementation' if conn_val > not_conn_val

    connected_output, unconnected_output = conn_space_check(layer, not_conn_val, mode)
  end
  [connected_output, unconnected_output]
end

def sep_viol_nets(layer1, layer2, conn_val, not_conn_val, mode)
  connected_output   = layer1.nets.separation(layer2.nets, conn_val.um,     mode, props_eq).polygons(0.001.um)
  unconnected_output = layer1.nets.separation(layer2.nets, not_conn_val.um, mode, props_ne).polygons(0.001.um)
  [connected_output, unconnected_output]
end

def unconn_separation_check(layer1, layer2, not_conn_val, mode)
  unconnected_errors_unfiltered = layer1.separation(layer2, not_conn_val.um, mode)
  # Filter out the errors arising from the same net
  unconnected_errors = DRC::DRCLayer.new(self, RBA::EdgePairs.new)
  unconnected_errors_unfiltered.data.each do |ep|
    net1, net2 = get_nets(l2n_data, layer1, layer2, ep)
    unconnected_errors = unconn_errors(net1, net2, unconnected_errors)
  end
  unconnected_errors
end

def conn_separation(layer1, layer2, conn_val, not_conn_val, mode)
  if layer1.respond_to?(:nets) # KLayout version (>=0.28.4) which supports "nets"
    connected_output, unconnected_output = sep_viol_nets(layer1, layer2, conn_val, not_conn_val, mode)
  else
    raise 'ERROR : Wrong connectivity implementation' if conn_val > not_conn_val

    connected_output = layer1.separation(layer2, conn_val.um, mode).polygons(0.001.um)
    unconnected_errors = unconn_separation_check(layer1, layer2, not_conn_val, mode)
    unconnected_output = unconnected_errors.polygons(0.001.um)
  end
  [connected_output, unconnected_output]
end

def size_overunder_in_layers(large_layer, size_layer, size_value)
  out_layer = DRC::DRCLayer.new(self, RBA::Region.new)
  large_layer.data.each do |ep|
    curr_large_layer = DRC::DRCLayer.new(self, RBA::Region.new(ep))
    curr_large_layer = curr_large_layer.and(size_layer)
    curr_large_layer = curr_large_layer.sized(size_value, 'square_limit').merged.sized(-size_value, 'square_limit')
    out_layer.data.insert(curr_large_layer.data)
  end
  out_layer
end
