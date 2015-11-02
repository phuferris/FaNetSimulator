function [Nodes_list] = scale_send_event(Nodes_list, event)
% Send an event from a node to an access point or a neighbor node

    scale_parameter;
    global bufferSize;
    global forwardedEvents;

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
    current_node_neighbors = current_node.neighbors;
    
    if(~isempty(current_node.AP_Connections))
        node_AP_connections = current_node.AP_Connections;
        
        % Current node has direct connection to an access point
        if(node_AP_connections.through_neighbor == current_node.id)
            scale_send_to_AP(node_AP_connections.AP_issid);
            
            if( event.source == event.originator)
                % record total sent events for each node
                current_node.sent_events = current_node.sent_events + 1;
            end
            
            forwardedEvents = forwardedEvents + 1;
            event.ttl = event.ttl - 1;
            Nodes_list = scale_send_to_all_neighbors(Nodes_list, event);
            
            % need to reduce current node power due to sending activity
            current_node.power = scale_power_consumption(current_node.power, action);
        % Forward the event to a nearby neighbor
        else
            if node_AP_connections.through_neighbor ~= 0
                if( event.source == event.originator)
                    % record total sent events for each node
                    current_node.sent_events = current_node.sent_events + 1;
                end
                
                forwardedEvents = forwardedEvents + 1;
                event.ttl = event.ttl - 1;
                
                % CHECK ANDY!
                %Nodes_list = scale_send_to_neighbor(Nodes_list, event, node_AP_connections.through_neighbor);
                Nodes_list = scale_send_to_all_neighbors(Nodes_list, event);
                
                % need to reduce current node power due to sending activity
                current_node.power = scale_power_consumption(current_node.power, action);
            
            else
                if numel(current_node.buffer) < bufferSize
                    current_node.buffer = [current_node.buffer, event];
                end
            end
        end
    else
        % find and update its path to an AP through a neighbor
        if(~isempty(current_node_neighbors))
            %disp(sprintf('This node does not have direct connection. Check neighbors'));
            best_neighbor = current_node_neighbors(1);
            for i=2:numel(current_node_neighbors)
                if(current_node_neighbors(i).status == 1 && current_node_neighbors(i).AP_connection == 1)
                    if(current_node_neighbors(i).AP_connection_hop_count < best_neighbor.AP_connection_hop_count)
                        best_neighbor = current_node_neighbors(i);
                    end
                end
            end
          
            node_AP_connections = [];
            if(best_neighbor.status == 1 && best_neighbor.AP_connection == 1 )
                node_AP_connections.through_neighbor = best_neighbor.AP_connection_through_node_id;
                node_AP_connections.num_hops = best_neighbor.AP_connection_hop_count + 1;
                node_AP_connections.AP_issid = best_neighbor.AP_connection_AP_issid;
            else % all neighbors are not active
                node_AP_connections.through_neighbor = 0;
                node_AP_connections.num_hops = 0;
                node_AP_connections.AP_issid = 0;
            end

            current_node.AP_Connections = node_AP_connections; 
            
            % Reduce node power due to finding
            % the best neighbor to forward event operation
            current_node.power = scale_power_consumption(current_node.power, action_computing);

            if(node_AP_connections.through_neighbor ~= 0)
                %disp(sprintf('Found a neighbor that can forward event to an AP, neighbor Id %d ', node_AP_connections.through_neighbor));
                
                % record total sent events for each node
                current_node.sent_events = current_node.sent_events + 1;
                
                forwardedEvents = forwardedEvents + 1;              
                event.ttl = event.ttl - 1;
                
                Nodes_list = scale_send_to_neighbor(Nodes_list, event, node_AP_connections.through_neighbor);
                Nodes_list = scale_send_to_all_neighbors(Nodes_list, event);
                
                current_node.power = scale_power_consumption(current_node.power, action);
                
            else % no neighbor is active or has connection to an AP, buffering the event
                if numel(current_node.buffer) < bufferSize
                    current_node.buffer = [current_node.buffer, event];
                end
            end
        else
            if numel(current_node.buffer) < bufferSize
                current_node.buffer = [current_node.buffer, event];
            end
        end      
    end
    
    Nodes_list(event.source) = current_node; % update source node info
    
    return;
end
