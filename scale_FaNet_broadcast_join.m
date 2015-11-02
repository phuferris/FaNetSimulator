function [nodes_list] = scale_FaNet_broadcast_join(nodes_list, message)
% Send join message to all wireless sensor 
% nodes within its current wireless cover range

    global wireless_range;
    sender_id = message.source;
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
                % It will check to see if it accepts the join
                % message and send back a offer join message
                
    
                nodes_list = process_join_message(nodes_list, message);
                  
           
                
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

