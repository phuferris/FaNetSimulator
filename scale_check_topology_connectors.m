function [status] = scale_check_topology_connectors(Nodes_list)
% Display events that have arrived at all available access points
    global APs_list;

    for k=1:numel(APs_list)
       if Nodes_list(APs_list(k).connect_node_id).power > 0
          status = 1;
          return;
       end
    end
    
    status = 0;
    return;
end