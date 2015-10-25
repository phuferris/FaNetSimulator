function [Nodes_list] = scale_run(Nodes_list, Events_list, max_run_time, spleeping_protocol)

clock = 0;

% 
while 1
    clock = clock + 1;
    [min_instant, min_index] = min([Events_list(:).instant]);
    
    if (clock > max_run_time)
        break;
    end
    event = Events_list(min_index);
    
    disp(sprintf('Min instant %f, min index %d', min_instant, min_index));
    disp(sprintf('event info '));
    disp(event);
    
    for k=1:numel(Nodes_list)
        disp(sprintf('Node ID %d status %d', k, Nodes_list(k).status));
        
        if Nodes_list(k).status == 1
           Nodes_list(k).active_time_left = Nodes_list(k).active_time_left - 1;
           
           % Check to see if it has any any event from the event queue
           if(~isempty(event) && event.instant == clock && event.source == k)
               Nodes_list = scale_send_event(Nodes_list, event); % get new events from sending the latest one
               Events_list(min_index) = [];
               if(~isempty(newEvents))
                   Events_list = [Events_list; newEvents];
               end
           end

         
        % beacon message
        message=[];
        message.id=k;
        message.node_x_coordinate = nodes_list(k).x_coordinate;
        message.node_y_coordinate = nodes_list(k).y_coordinate;

        if(~isempty(nodes_list(k).AP_Connections))
            message.AP_connection = 1;

            node_AP_connections = nodes_list(k).AP_Connections;
            message.AP_connection_through_node_id = node_AP_connections.through_neighbor;
            message.AP_connection_hop_count = node_AP_connections.num_hops + 1;
        else
            message.AP_connection = 0;
            message.AP_connection_through_node_id = 0;
            message.AP_connection_hop_count = 0;
        end

        %power left after sending beacon
        action = [];
        action.type = 'broadcast_beacon';
        nodes_list(k).power= scale_power_consumption(nodes_list(k).power, action);
        message.power_status = nodes_list(k).power;

        message.sleeping_time_left = nodes_list(k).sleeping_time_left;  %need update (re-calculate)? 
        message.active_time_left = nodes_list(k).active_time_left;        %need re-calculate? If so, have to use get time function with sleep protocol 


           % Send out beacon message to annouce its active
           Nodes_list = scale_send_beacon_message(Nodes_list, k, message);

           if Nodes_list(k).active_time_left == 0
               Nodes_list(k).status = 0;
               Nodes_list(k).sleeping_time_left = scale_get_sleeping_time(Nodes_list, spleeping_protocol);
           end
        else
           Nodes_list(k).sleeping_time_left = Nodes_list(k).sleeping_time_left - 1;
           if Nodes_list(k).sleeping_time_left == 0
               Nodes_list(k).satus = 1;
               Nodes_list(k).active_time_left = scale_get_active_time(Nodes_list, spleeping_protocol);
           end
        end    
    end
end

return;
