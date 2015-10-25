function [TotPower]=scale_run_custom_sleep(Nodes_list, Events_list, max_run_time, prob_sleeping)
% Simulate SCALE network when all nodes are kept active

global sentEvents;
global forwardedEvents;
global lifeTime;
global activeTime;
global active_sleep_periods;
global numNodes;
global timeInterval;
global powerOvertime;
global initial_power;


lifeTime=0;
activeTime=zeros(numNodes,1);

%prob_sleeping = 0.6;
prob_active = 1-prob_sleeping;


% Initialize nodes' active and inactive time
for k=1:numel(Nodes_list)
    
     trans = [prob_active (1-prob_active); (1-prob_sleeping), prob_sleeping];
     [state, seq] = scale_marko_chain_state_transition(trans);
     time = active_sleep_periods(state, seq);
     
     if state == 1
         Nodes_list(k).status = 1;
         Nodes_list(k).active_time_left = time;
         Nodes_list(k).sleeping_time_left = 0;
     else
         Nodes_list(k).status = 0;
         Nodes_list(k).active_time_left = 0;
         Nodes_list(k).sleeping_time_left = time;
     end
end

clock = 0;
sentEvents = 0;
forwardedEvents = 0;
scale_reset_events_arrived_at_APs();

powerOvertime=zeros(numNodes,1+floor(max_run_time/timeInterval));
powerOvertime(:,1)=initial_power;
countInterval=1;

beacon_broadcast_action = [];
beacon_broadcast_action.type = 'broadcast_beacon';
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
       
    %keep track of time interval
        if(mod(clock,timeInterval)==0)
           countInterval= countInterval+1;
        end
        
    for k=1:numel(Nodes_list)
        
         %record power every time interval
        if(mod(clock,timeInterval)==0)
           powerOvertime(k,countInterval)=Nodes_list(k).power;
        end
        
        % Node is active
        if Nodes_list(k).status == 1 && Nodes_list(k).active_time_left > 0
            %disp(sprintf('Node id# %d, active ...  time left %d', k, Nodes_list(k).active_time_left));
            
            action = [];
            action.type = 'active';
            action.time = 1;
            Nodes_list(k).power = scale_power_consumption(Nodes_list(k).power, action);
        
            %calculate total active Time
            % don't know what this is ued for.
            % the data may not be correct
            activeTime(k)=activeTime(k)+1;
            
            % Check to see if any neighbor of the node is active. Node can
           % go back to sleep if at least one of its neighbors can forward
           % packets to the access point
           current_active_neighbors = scale_check_active_neighbors(Nodes_list(k).neighbors);
           
           disp(sprintf('CUSTOM CURRENT NEIGHBORS %d', current_active_neighbors));
            
           % Check to see if the node has send beacon message to its
           % neighbors to info their update statas
           if (Nodes_list(k).beacon_broadcasted == 0 && current_active_neighbors ==0)
               
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
               disp(sprintf('Node ID %d status %d', k, Nodes_list(k).status));
               disp(sprintf('Event instant %d, current clock %d, event source %d', event.instant, clock, event.source));
               %disp(sprintf('Found 1 event for node #%d, Sent the event to its destination', k));
               %disp(event);  
               
               % Node has event of its own, start to send
               sentEvents = sentEvents + 1;
               Nodes_list = scale_send_event(Nodes_list, event); 

           else % Check to see if the node has any event being buffered
               if(~isempty(Nodes_list(k).buffer))
                   buffered_event = Nodes_list(k).buffer(1); % pick to the oldest event 
                   
                   disp(sprintf('BUFFER Node ID %d status %d', k, Nodes_list(k).status));
                   disp(sprintf('Buffer Event instant %d, current clock %d, buffer event source %d', buffered_event.instant, clock, buffered_event.source));
                   %disp(sprintf('BUFFER Found 1 event for node #%d, Sent the event to its destination', k));
                   
                   %disp(buffered_event);   

                   Nodes_list(k).buffer(1) = []; % remove sent event from buffer
                   Nodes_list = scale_send_event(Nodes_list, buffered_event);
               end
           end    
           
           if(current_active_neighbors == 0)
               Nodes_list = scale_send_beacon_message(Nodes_list, k);

               action = [];
               action.type = 'broadcast_beacon';
               Nodes_list(k).power = scale_power_consumption(Nodes_list(k).power, action);

               % Calculate next sleeping and active time
               if Nodes_list(k).active_time_left > 1
                   Nodes_list(k).active_time_left = Nodes_list(k).active_time_left - 1;

               else
                   % Adjust new active/sleeping probability for the node based on its current conditions 
                   [prob_sleeping, prob_active] = scale_get_sleepActProb(prob_sleeping, Nodes_list(k));
                   trans = [prob_active (1-prob_active); (1-prob_sleeping), prob_sleeping];

                   [state, seq] = scale_marko_chain_state_transition(trans);

                   time = active_sleep_periods(state, seq);

                   %disp(sprintf('Node ID# %d, state: %d, time in state: %d, seq# %d', k, state, time, seq)); 

                   % Node continues to be in active state
                   if state == 1
                      Nodes_list(k).active_time_left = time; 
                   else
                       Nodes_list(k).status = 0;
                       Nodes_list(k).active_time_left = 0;
                       Nodes_list(k).sleeping_time_left = time;
                   end

                   action = [];
                   action.type = 'computing';
                   Nodes_list(k).power = scale_power_consumption(Nodes_list(k).power, action);

                   % Node ends another beacon message to its neighbors 
                   % before going back to sleep
                   Nodes_list = scale_send_beacon_message(Nodes_list, k);
                   Nodes_list(k).beacon_broadcasted = 0; %reset broadcast beacon tag
                   Nodes_list(k).power = scale_power_consumption(Nodes_list(k).power, beacon_broadcast_action);
               end
           else % Node go back to sleep 
               Nodes_list(k).status = 0;
               Nodes_list(k).active_time_left = 0;
               Nodes_list(k).sleeping_time_left = scale_get_sleeping_time(Nodes_list, 'random');
                
               action = [];
               action.type = 'computing';
               Nodes_list(k).power = scale_power_consumption(Nodes_list(k).power, action);
           end
               
           
        else % Node is sleeping
            %disp(sprintf('Node id# %d, sleeping ... ', k));
            action = [];
            action.type = 'sleeping';
            action.time = 1;
            Nodes_list(k).power = scale_power_consumption(Nodes_list(k).power, action);
        
            if Nodes_list(k).sleeping_time_left > 1
                Nodes_list(k).sleeping_time_left = Nodes_list(k).sleeping_time_left -1;
            else
               % Node is waking up, switching from sleeping status to
               % active, so it consumes more energy that other cycles
               action = [];
               action.type = 'wakeup';
               Nodes_list(k).power = scale_power_consumption(Nodes_list(k).power, action);
               
               Nodes_list = scale_send_beacon_message(Nodes_list, k);
               Nodes_list(k).beacon_broadcasted = 1;
               Nodes_list(k).power = scale_power_consumption(Nodes_list(k).power, beacon_broadcast_action);
               
               % Adjust new active/sleeping probability for the node based on its current conditions 
               [prob_sleeping, prob_active] = scale_get_sleepActProb(prob_sleeping, Nodes_list(k));
               
               trans = [prob_active (1-prob_active); (1-prob_sleeping), prob_sleeping];
               [state, seq] = scale_marko_chain_state_transition(trans);
               
               time = active_sleep_periods(state, seq);
               
               %disp(sprintf('Waking up, Node ID# %d, state: %d, time in state: %d, seq# %d', k, state, time, seq)); 
               
               % Node is waking up, changing from
               % sleeping state to active stage
               if(state == 1)
                   Nodes_list(k).status = 1;
                   Nodes_list(k).sleeping_time_left = 0;
                   Nodes_list(k).active_time_left = time;
               else
                   Nodes_list(k).sleeping_time_left = time;
               end
            end
        end
    end
end

%scale_display_nodes_info(Nodes_list);

%disp(sprintf('Total Custom Run Forwarded Events: %d', forwardedEvents));
TotPower=scale_power_graph(Nodes_list, 'Optimized Sleep Schema');

return;