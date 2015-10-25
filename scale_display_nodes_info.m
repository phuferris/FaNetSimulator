function scale_display_nodes_info(Nodes_list)
% Display nodes' current info
    
    for k=1:numel(Nodes_list)
       disp(sprintf('--- Node ID:  %d, X coordinate: %g, Y coordinate: %g', Nodes_list(k).id,  Nodes_list(k).x_coordinate,  Nodes_list(k).y_coordinate));
       disp(sprintf('--- Status:  %d, Power: %g mAh, Next idle time: %g seconds', Nodes_list(k).status, Nodes_list(k).power, Nodes_list(k).sleeping_time_left));    
       disp(sprintf('--- Generated event:  %d, Sent events: %d, Relayed events: %d, Received events: %d', Nodes_list(k).generated_events, Nodes_list(k).sent_events, Nodes_list(k).relayed_events, Nodes_list(k).received_events));
       
       % Display connection to AP list
       for index = 1:numel(Nodes_list(k).AP_Connections)
           AP_connection = Nodes_list(k).AP_Connections(index);
           disp(sprintf('--- AP connection: through node ID# %d by %d hops, AP Issid %s', AP_connection.through_neighbor, AP_connection.num_hops, AP_connection.AP_issid));
       end
       
       
       % Display neighbors list
       for index = 1:numel(Nodes_list(k).neighbors)
           neighbor = Nodes_list(k).neighbors(index);
           disp(sprintf('Neighbor ID# %d: connect to an AP %d, through node ID# %d, Hops count %d', neighbor.id, neighbor.AP_connection, neighbor.AP_connection_through_node_id, neighbor.AP_connection_hop_count));
       end
       
       disp(sprintf('\n'));   
    end
end