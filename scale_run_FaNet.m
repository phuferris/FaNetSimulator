function [Nodes_list]=scale_run_FaNet(Nodes_list, ttl, max_run_time)
    % Simulate SCALE network when all nodes are kept active

    global sentEvents;
    global forwardedEvents;
    global lifeTime;
    global activeTime;
    global numNodes;
    global powerOvertime;
    global initial_power;
    global timeInterval;



    clock = 0;
    sentEvents = 0;
    forwardedEvents = 0;
    scale_reset_events_arrived_at_APs();
    lifeTime=0;
    activeTime=zeros(numNodes,1);

    powerOvertime=zeros(numNodes,1+floor(max_run_time/timeInterval));
    powerOvertime(:,1)=initial_power;
    countInterval=1;
    
    event_id = 1;

    while 1
        clock = clock + 1;

        % Check to see if the network topology is still active
        network_status = scale_check_topology_connectors(Nodes_list);
        if network_status == 0
           lifeTime=clock;
           disp(sprintf('At clock %d, all nodes that have access to APs are died', clock));
           break;
        end

        if (clock > max_run_time)
            break;
        end

        %keep track of time interval
        if(mod(clock,timeInterval)==0)
            countInterval= countInterval+1;
        end

        for k=1:numel(Nodes_list)

             %record power every time interval
            if(mod(clock,timeInterval)==0)
               powerOvertime(k,countInterval)=Nodes_list(k).power;
            end

           
            action = [];
            action.type = 'active';
            action.time = 1;
            Nodes_list(k).power = scale_power_consumption(Nodes_list(k).power, action);
            
           % Assume that an earthquake occurs at clock = 5;
            if clock == 5
                event = [];
                event.id = event_id;
                event.ttl = ttl + 1;
                event.source = k;
                event.from_node = event.source;
                event.originator = event.source;
                event.destination = 99999; % address of remote server on the cloud
                event.instant = clock;
                event.size = 1*100*8; % 100 kb max
                event.recieved_time = clock;

                Nodes_list(k).generated_events = 1; 
                Nodes_list = disseminate_event(Nodes_list, event);
                
                
                event_id = event_id + 1;
            end
        end
    end

    %TotPower=scale_power_graph(Nodes_list, 'FaNet Data Dissemination Schema');
    %events_graph_height = scale_events_graph(Nodes_list,'FaNet Data Dissemination Events', events_graph_height);
 
    return;
end
    

function [Nodes_list] = disseminate_event(Nodes_list, event)
    global sentEvents;
    global forwardedEvents;
    
    if event.from_node ~= event.source
        Nodes_list(event.source).received_events =  Nodes_list(event.source).received_events + 1; 
    end

    %Check to see if the node has received this event
    if ~isempty(Nodes_list(event.source).recieved_events_queue)
       event_queue_index = find([Nodes_list(event.source).recieved_events_queue(:).id] == event.id, 1);
       if(isempty(event_queue_index)) 
           Nodes_list(event.source).recieved_events_queue = [Nodes_list(event.source).recieved_events_queue, event];
       else
           Nodes_list(event.source).duplicated_events =  Nodes_list(event.source).duplicated_events + 1;
           return;
       end
    else
       Nodes_list(event.source).recieved_events_queue = [Nodes_list(event.source).recieved_events_queue, event];
    end
    
    
    % receiving node get its own event
    if event.from_node ~= event.source && event.originator == event.source
        Nodes_list(event.source).duplicated_events =  Nodes_list(event.source).duplicated_events + 1;
        return;
    end
    
    % Stop dissemination process 
    if event.ttl < 1
        return;
    end
    
    sent_events = 0;
    
    % when nodes do not belong to any tree, 
    % check to see if it has accept to AP
    if isempty(Nodes_list(event.source).parents) && ...
            isempty(isempty(Nodes_list(event.source).children)) && ...
        	isempty(Nodes_list(event.source).AP_Connections)
        
        Nodes_list(event.source).buffer = [Nodes_list(event.source).buffers, event];
       
    end
    
    % Send to the cloud when the connection is availble
    if(~isempty(Nodes_list(event.source).AP_Connections))
        
        % Only send event to the clound when 
        % It has not been done so
        if event.destination == 99999
            sent_events = sent_events + 1;
            scale_send_to_AP(Nodes_list(event.source).AP_Connections.AP_issid);

            action = [];
            action.type = 'sending';
            action.packet_size = event.size; 
            Nodes_list(event.source).power = scale_power_consumption(Nodes_list(event.source).power, action);
            
            event.destination = -99999;
        end
            
    end
    
    relayed_events = 0;
    % Relay events to parent nodes
    if ~isempty(Nodes_list(event.source).parents)
        for k=1:numel(Nodes_list(event.source).parents)
            
            if (k > numel(Nodes_list(event.source).parents))
                continue;
            end
            
            if Nodes_list(event.source).parents(k).parent_node_id ~= event.originator && ...
                    Nodes_list(event.source).parents(k).parent_node_id ~= event.from_node
                
                event.from_node = event.source;
                event.source = Nodes_list(event.source).parents(k).parent_node_id;
                
                % initial relay
                if event.originator == event.source
                    sent_events = sent_events + 1;
                else
                    relayed_events = relayed_events + 1;
                    event.ttl = event.ttl - 1;
                end
                
                event.recieved_time = event.recieved_time +1;
                Nodes_list = disseminate_event(Nodes_list, event);
                
                action = [];
                action.type = 'sending';
                action.packet_size = event.size; 
                Nodes_list(event.source).power = scale_power_consumption(Nodes_list(event.source).power, action);
            end
      
        end
    end
    
    % Relay events to children nodes
    if ~isempty(Nodes_list(event.source).children)
        for k=1:numel(Nodes_list(event.source).children)
            
            if (k > numel(Nodes_list(event.source).children))
                continue;
            end
            
            if Nodes_list(event.source).children(k) ~= event.originator && ...
                    Nodes_list(event.source).children(k) ~= event.from_node
                 
                % recursively send the event to all children
                event.from_node = event.source;
                event.source = Nodes_list(event.source).children(k);
                
                % Initial relay
                if event.originator == event.source
                    sent_events = sent_events + 1;
                else
                    relayed_events = relayed_events + 1;
                    event.ttl = event.ttl - 1;
                end    
                
                event.recieved_time = event.recieved_time +1;
                Nodes_list = disseminate_event(Nodes_list, event);
                
                action = [];
                action.type = 'sending';
                action.packet_size = event.size; 
                Nodes_list(event.source).power = scale_power_consumption(Nodes_list(event.source).power, action);
            end
      
        end
    end
    
    % Update global sent events and global relayed events
    sentEvents = sentEvents + sent_events;
    forwardedEvents = forwardedEvents + relayed_events;
    
    Nodes_list(event.source).sent_events =  Nodes_list(event.source).sent_events + sent_events;
    Nodes_list(event.source).relayed_events =  Nodes_list(event.source).relayed_events + relayed_events;
    
    return;
    
end


