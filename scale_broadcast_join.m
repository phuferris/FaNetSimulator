function [nodes_list] = scale_broadcast_join(nodes_list, message)
% Send join message to all wireless sensor 
% nodes within its current wireless cover range

    global wireless_range;
    
    sender_id = message.id;
    sender_x_coordinate = message.node_x_coordinate;
    sender_y_coordinate = message.node_y_coordinate;
    
    for k=1:numel(nodes_list)
        % Don't broadcast join message
        % to itself
        if(sender_id ~= k)
            distance_to_potential_receiver = sqrt((nodes_list(k).x_coordinate - sender_x_coordinate)^2 + (nodes_list(k).y_coordinate - sender_y_coordinate)^2);
            if(distance_to_potential_receiver < wireless_range)
                disp(sprintf('Sender ID: %d, Potential receiver ID: %d --- Distance to the receiver: %g, wireless conver range %g', sender_id, k, distance_to_potential_receiver, wireless_range));
                
                % The broadcast join message reaches this node
                % It will add the sender into its neighbor list
                % who will receive its beacon message later
                
                new_neighbor_info = message;
                
                disp(sprintf('Add node ID %d into neighbor list of node ID %d \n', sender_id, k));       
                
                current_neighbors_list = nodes_list(k).neighbors;
                
                new_neighbors_list = scale_add_remove_neighbor(current_neighbors_list, new_neighbor_info, 'add');
                nodes_list(k).neighbors = new_neighbors_list;
                
                clear new_neighbor_info;
                clear current_neighbors_list;
                clear new_neighbors_list;
                
                action = [];
                action.type = 'computing';
                nodes_list(k).power = scale_power_consumption(nodes_list(k).power, action);
            end
        end
    end
    return;
end

