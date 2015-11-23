function [Nodes_list] = scale_send_event(Nodes_list, event)
% Send an event from a node to an access point or a neighbor node

    scale_parameter;

    if isempty(Nodes_list(event.source))
        return;
    end
    
    if event.ttl <= 0
        return;
    end
    
    
    action = [];
    action.type = 'sending';
    action.packet_size = event.size; 
    
    action_computing = [];
    action_computing.type = 'computing';
            
    current_node = Nodes_list(event.source);
    
    if(~isempty(current_node.AP_Connections) && event.destination == 99999)
        node_AP_connections = current_node.AP_Connections;
        if (node_AP_connections.through_neighbor == event.source)
            event.destination = -99999;
            scale_send_to_AP(node_AP_connections.AP_issid);
            current_node.sent_events = current_node.sent_events + 1;
        end
    end

    Nodes_list = scale_send_to_all_neighbors(Nodes_list, event);

    % need to reduce current node power due to sending activity
    current_node.power = scale_power_consumption(current_node.power, action);
            
    Nodes_list(event.source) = current_node; % update source node info
    
    return;
end
