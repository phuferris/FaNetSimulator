function [Nodes_list] = scale_send_to_all_neighbors(Nodes_list, event)
% Send an event to a neighbor node    
    if isempty(Nodes_list(event.source).neighbors)
        return;
    end
    
    % drop the message if its ttl is expired
    if(event.ttl <= 0)
       return; 
    end
    

    event.ttl = event.ttl - 1;
    event.recieved_time = event.recieved_time + 1;
    
    neighbors = Nodes_list(event.source).neighbors;
    
    %disp(sprintf('EVENT with message id# %d FORWARDED TO Neighbor ID %d', neighbor_id, event.id));
    for k=1:numel(neighbors)
        neighbor_id = neighbors(k).id;
        
        %record total replayed_events
        Nodes_list(event.source).relayed_events = Nodes_list(event.source).relayed_events + 1; 
        
        if ~isempty(Nodes_list(neighbor_id))
            if Nodes_list(neighbor_id).status == 1

               % record total received events
               Nodes_list(neighbor_id).received_events = Nodes_list(neighbor_id).received_events + 1;
               
               %Check to see if the node has received this event
               if ~isempty(Nodes_list(neighbor_id).recieved_events_queue)
                   event_queue_index = find([Nodes_list(neighbor_id).recieved_events_queue(:).id] == event.id, 1);
                   if(isempty(event_queue_index)) 
                       Nodes_list(neighbor_id).recieved_events_queue = [Nodes_list(neighbor_id).recieved_events_queue, event];
                   else
                       Nodes_list(neighbor_id).duplicated_events =  Nodes_list(neighbor_id).duplicated_events + 1; 
                   end
               else
                   Nodes_list(neighbor_id).recieved_events_queue = [Nodes_list(neighbor_id).recieved_events_queue, event];
               end

               action = [];
               action.type = 'receiving';
               action.packet_size = event.size;
               Nodes_list(neighbor_id).power = scale_power_consumption(Nodes_list(neighbor_id).power, action);

              
               % record total replayed events
               Nodes_list(neighbor_id).relayed_events = Nodes_list(neighbor_id).relayed_events + 1; 
    
               % add the event into the neighbor's buffer
               event.source = neighbor_id;
               event.ttl = event.ttl - 1;
               Nodes_list = scale_send_event(Nodes_list, event); 
            else
               Nodes_list(neighbor_id).buffer = [Nodes_list(neighbor_id).buffer, event];
            end
        end
    end
   
    return;
end
