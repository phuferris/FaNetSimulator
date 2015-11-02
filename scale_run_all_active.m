function [Nodes_list, TotPower, events_graph_height]=scale_run_all_active(Nodes_list, Events_list, max_run_time)
    % Simulate SCALE network when all nodes are kept active

    global sentEvents;
    global forwardedEvents;
    global lifeTime;
    global timeInterval;
    global powerOvertime;
    global initial_power;
    global numNodes;

    % Set nodes to be active
    for k=1:numel(Nodes_list)
       Nodes_list(k).status = 1; 
       Nodes_list(k).on_duty = 1;
    end

    clock = 0;
    sentEvents = 0;
    forwardedEvents = 0;
    scale_reset_events_arrived_at_APs();


    powerOvertime=zeros(numNodes,1+floor(max_run_time/timeInterval));
    powerOvertime(:,1)=initial_power;
    countInterval=1;

    % Loop until clock is reach 
    % the maximum run time thredhold
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

            action = [];
            action.type = 'active';
            action.time = 1;
            Nodes_list(k).power = scale_power_consumption(Nodes_list(k).power, action);

             %record power every time interval
            if(mod(clock,timeInterval)==0)
               powerOvertime(k,countInterval)=Nodes_list(k).power;
            end

            % Send beacon message to neighbors to update
            % its current status for every 10 seconds
            if mod(clock, 10) == 0

                Nodes_list = scale_send_beacon_message(Nodes_list, k);

                action = [];
                action.type = 'broadcast_beacon';
                Nodes_list(k).power = scale_power_consumption(Nodes_list(k).power, action);
            end

            event = [];
            if ~isempty(events)
                event_index = find([events(:).source] == k, 1);
                if ~isempty(event_index)
                   event = events(event_index); 
                end
            end

            % Check to see if it has any any event from the event queue
            if(~isempty(event) && event.instant == clock && event.source == k)    
                sentEvents = sentEvents + 1;
                % record total generated events for each node
                Nodes_list(k).generated_events = Nodes_list(k).generated_events + 1; 
                Nodes_list = scale_send_event(Nodes_list, event); 

            % Check to see if there is any event in the buffer to be sent    
            else
                if(~isempty(Nodes_list(k).buffer))
                   buffered_event = Nodes_list(k).buffer(1); % pick to the oldest event
                   Nodes_list(k).buffer(1) = []; % remove sent event from buffer
                   Nodes_list = scale_send_event(Nodes_list, buffered_event);
                end
            end   
        end
    end

    TotPower = scale_power_graph(Nodes_list,'One Hop Broadcast Data Dissemination Schema');

    events_graph_height = scale_events_graph(Nodes_list,'One Hop Broadcast Data Dissemination Events', 0);

    return;
end