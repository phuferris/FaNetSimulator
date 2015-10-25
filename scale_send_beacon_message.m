function [nodes_list] = scale_send_beacon_message(nodes_list, k)
% send beacon message to neighbor inform status change

    message = [];
    message.id = nodes_list(k).id;
    message.status = nodes_list(k).status;
    message.node_x_coordinate = nodes_list(k).x_coordinate;
    message.node_y_coordinate = nodes_list(k).y_coordinate;

    if(~isempty(nodes_list(k).AP_Connections))
        message.AP_connection = 1;
        node_AP_connections = nodes_list(k).AP_Connections;
        message.AP_connection_through_node_id = node_AP_connections.through_neighbor;
        message.AP_connection_hop_count = node_AP_connections.num_hops + 1;
        message.AP_connection_AP_issid = node_AP_connections.AP_issid;
    else
        message.AP_connection = 0;
        message.AP_connection_through_node_id = 0;
        message.AP_connection_hop_count = 0;
        message.AP_connection_AP_issid = 0;
    end

    message.power_status = nodes_list(k).power;
    message.sleeping_time_left = nodes_list(k).sleeping_time_left;
    message.active_time_left = nodes_list(k).active_time_left;

    for n=1:numel(nodes_list(k).neighbors)
        %check to see if neighbor is active
        if(nodes_list(nodes_list(k).neighbors(n).id).status == 1)
           %check if node already in neighbors list
            idx=find([nodes_list(nodes_list(k).neighbors(n).id).neighbors.id] == k);
            if(isempty(idx))
                 %add node to neighbors list 
                 new_neighbor_info = message;
                 disp(sprintf('Add node ID %d into neighbor list of node ID %d \n', k, nodes_list(k).neighbors(n).id));       
                 current_neighbors_list = nodes_list(nodes_list(k).neighbors(n).id).neighbors;
                 new_neighbors_list = scale_add_remove_neighbor(current_neighbors_list, new_neighbor_info, 'add');
                 nodes_list(nodes_list(k).neighbors(n).id).neighbors = new_neighbors_list;
                 
                 clear new_neighbor_info;
                 clear current_neighbors_list;
                 clear new_neighbors_list;
            else
                 %update the existing node status in neighbors list        
                 nodes_list(nodes_list(k).neighbors(n).id).neighbors(idx) = message;
            end
        end
    end
    return;
end
