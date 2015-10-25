function [TotPower]=scale_run_custom(Nodes_list, Events_list, max_run_time)
% Simulate SCALE network when all nodes are kept active

global sentEvents;
global forwardedEvents;
global lifeTime;
global cyclePeriod;
global numCycles;
global numNodes;
global DutyTime;

DutyTime=zeros(numNodes,numCycles);


% Initialize nodes' active and inactive time
for k=1:numel(Nodes_list)
    Nodes_list(k).active_time_left = scale_get_active_time(Nodes_list, 'random');
    Nodes_list(k).sleeping_time_left = scale_get_sleeping_time(Nodes_list, 'random');
end

clock = 0;
sentEvents = 0;
forwardedEvents = 0;
scale_get_events_arrived_at_APs();

beacon_broadcast_action = [];
beacon_broadcast_action.type = 'broadcast_beacon';

cycleNo=1;
% 
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
    
    
    
    events = [];
    events = scale_get_events(Events_list, events, clock);
  
        
    for k=1:numel(Nodes_list)
        % Node is active
        if Nodes_list(k).status == 1 && Nodes_list(k).active_time_left > 0
            action = [];
            action.type = 'active';
            action.time = 1;
            Nodes_list(k).power = scale_power_consumption(Nodes_list(k).power, action);
        
            DutyTime(k,cycleNo)=DutyTime(k,cycleNo)+1;
            
           % Check to see if the node has send beacon message to its
           % neighbors to info their update statas
           if Nodes_list(k).beacon_broadcasted == 0
               
               % Node is waking up, switching from sleeping status to
               % active, so it consumes more energy that other cycles
               action = [];
               action.type = 'wakeup';
               Nodes_list(k).power = scale_power_consumption(Nodes_list(k).power, action);
               
               Nodes_list = scale_send_beacon_message(Nodes_list, k);
               Nodes_list(k).beacon_broadcasted = 1;
               Nodes_list(k).power = scale_power_consumption(Nodes_list(k).power, beacon_broadcast_action);
           end
            
           % Check to see if it has any event to send
           event = [];
           if ~isempty(events)
               event_index = find([events(:).source] == k, 1);
               if ~isempty(event_index)
                   event = events(event_index); 
               end
           end
        
           % Check to see if it has any any event from the event queue
           if(~isempty(event) && event.instant == clock && event.source == k)
               %disp(sprintf('Node ID %d status %d', k, Nodes_list(k).status));
               %disp(sprintf('Event instant %d, currrent clock %d, event source %d', event.instant, clock, event.source));
               %disp(sprintf('Found 1 event for node #%d, Sent the event to its destination', k));
               %disp(event);  
               
               % Node has event of its own, start to send 
               % or forward it. 
               sentEvents = sentEvents + 1;
               Nodes_list = scale_send_event(Nodes_list, event); 

           else % Check to see if the node has any event being buffered
               if(~isempty(Nodes_list(k).buffer))
                   buffered_event = Nodes_list(k).buffer(1); % pick to the oldest event 
                   
                   %disp(sprintf('BUFFER Node ID %d status %d', k, Nodes_list(k).status));
                   %disp(sprintf('Buffer Event instant %d, currrent clock %d, buffer event source %d', buffered_event.instant, clock, buffered_event.source));
                   %disp(sprintf('BUFFER Found 1 event for node #%d, Sent the event to its destination', k));
                   
                   %disp(buffered_event);   

                   Nodes_list(k).buffer(1) = []; % remove sent event from buffer
                   forwardedEvents = forwardedEvents + 1;
                   Nodes_list = scale_send_event(Nodes_list, buffered_event);
               end
           end    
            
           Nodes_list = scale_send_beacon_message(Nodes_list, k);
            
           action = [];
           action.type = 'broadcast_beacon';
           Nodes_list(k).power = scale_power_consumption(Nodes_list(k).power, action);
               
           % Calculate next sleeping and active time
           if Nodes_list(k).active_time_left > 1
               Nodes_list(k).active_time_left = Nodes_list(k).active_time_left - 1;
               
           else
               Nodes_list(k).status = 0;
               Nodes_list(k).active_time_left = scale_get_active_time(Nodes_list, 'random');
               Nodes_list(k).sleeping_time_left = scale_get_sleeping_time(Nodes_list, 'random');
               
               action = [];
               action.type = 'computing';
               Nodes_list(k).power = scale_power_consumption(Nodes_list(k).power, action);
               
               % Node ends another beacon message to its neighbors 
               % before going back to sleep
               Nodes_list = scale_send_beacon_message(Nodes_list, k);
               Nodes_list(k).beacon_broadcasted = 0; %reset broadcast beacon tag
               Nodes_list(k).power = scale_power_consumption(Nodes_list(k).power, beacon_broadcast_action);
           end
           
        else % Node is sleeping
            action = [];
            action.type = 'sleeping';
            action.time = 1;
            Nodes_list(k).power = scale_power_consumption(Nodes_list(k).power, action);
        
            if Nodes_list(k).sleeping_time_left > 1
                Nodes_list(k).sleeping_time_left = Nodes_list(k).sleeping_time_left -1;
            else
                Nodes_list(k).status = 1;
                Nodes_list(k).sleeping_time_left = 0;
            end
        end
    end
    
     % keep track of cycle number
    if (mod(clock,cyclePeriod)==0)
        cycleNo=cycleNo+1;
    end
    
end

%scale_display_nodes_info(Nodes_list);

disp(sprintf('Total forwarded events: %d', forwardedEvents));
TotPower=scale_power_graph(Nodes_list, 'Random Sleep');

return;