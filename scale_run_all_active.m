function [Nodes_list]=scale_run_all_active(Nodes_list, ttl, max_run_time)
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
    
    event_id = 1;

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

            % Assume that an earthquake occurs at clock = 5;
            if clock == 5
                event = [];
                event.id = event_id;
                event.recieved_time = clock;
                event.ttl = ttl;
                event.source = k;
                event.from_node = event.source;
                event.originator = event.source;
                event.destination = 99999; % address of remote server on the cloud
                event.instant = clock;
                event.size = 1*100*8; % 100 kb max
                
                Nodes_list(k).generated_events = 1; 
                Nodes_list = scale_send_event(Nodes_list, event);
                event_id = event_id + 1;
            end
        end
    end

   
    %TotPower = scale_power_graph(Nodes_list,'Multi Hops Broadcast Data Dissemination Schema');
    %events_graph_height = scale_events_graph(Nodes_list,'Multi Hops Broadcast Data Dissemination Events', 0);

    return;
end