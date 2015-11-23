% Simulation for SCALE Wireless Sensor Box

clear;
close all;

scale_parameter;

global numNodes;
global initial_power;
global maxx;
global maxy;
global maxEvents;
global eventsPeriod;
global APs_list;
global sentEvents;
global forwardedEvents;
global totalReceived;
global timeInterval;

global powerWeight;
global neighborWeight;
global distanceWeight;

timeInterval= 1; %record power of each node every time interval
powerWeight = 0.02;
neighborWeight = 0.06;
distanceWeight = 0.05;

prob_sleeping = 0.6;

sentStatistics = [];

APs_list = [];
sentEvents = 0;
forwardedEvents = 0;
totalReceived = 0;

Nodes_list = [];
Events_list = [];



Nodes_coordinates = zeros(numNodes, 2);

% Initialize sensor direct connection to a nearest Access Point AP
% Initialize sensor status
issid = 0;
for k=1:numNodes
    Nodes_list(k).id = k;
    Nodes_list(k).x_coordinate = rand()*maxx; % 250 feets
    Nodes_list(k).y_coordinate = rand()*maxy; % 250 feets
    
    Nodes_list(k).generated_events = 0;
    Nodes_list(k).sent_events = 0;
    Nodes_list(k).relayed_events = 0;
    Nodes_list(k).received_events = 0;
    Nodes_list(k).duplicated_events = 0;
    Nodes_list(k).recieved_events_queue = [];
    
    % For FaNet
    Nodes_list(k).parents = [];
    Nodes_list(k).children = [];
    Nodes_list(k).level = -9999;
    Nodes_list(k).offers = [];
    Nodes_list(k).offerings = [];
    Nodes_list(k).primary_tree_id = 0;
    Nodes_list(k).primary_parent_id = 0;
    

    Nodes_list(k).buffer = [];
    Nodes_list(k).neighbors = [];
    Nodes_list(k).status = 0; % get_status(node_id, neighors), 0 = sleep, 1 = active
    Nodes_list(k).on_duty = 0; % 0 is not fowarding neighbors' traffic, 1 is
    Nodes_list(k).power = initial_power;
    Nodes_list(k).active_time_left = 0; % initial value
    Nodes_list(k).sleeping_time_left = 0; % 0 initial value
    Nodes_list(k).beacon_broadcasted = 0; % 0 initial value
    Nodes_list(k).AP_Connections = [];
    
    AP_Connections = [];
    random_AP = mod(round(rand(1)*100), k);
    if(random_AP == 0 || random_AP == 1)
        issid = issid + 1;
        
         % Add new Access Point into APs_list
        AP = [];
        AP.issid = issid;
        AP.connect_node_id = k;     %direct connection node id
        AP.x_coordinate = Nodes_list(k).x_coordinate + 5;
        AP.y_coordinate = Nodes_list(k).y_coordinate + 5;
        AP.arrived_events = 0;
        APs_list = [APs_list; AP]; 
        
        Connection.through_neighbor = k; % need a function for this
        Connection.num_hops = 1; % need a function for this
        Connection.AP_issid = AP.issid;
        AP_Connections = [AP_Connections; Connection]; 
        Nodes_list(k).AP_Connections = AP_Connections;
        
        clear Connection;
        clear AP_Connections;
        clear AP;
         
    end    
end

% Clone Nodes_list to Nodes_list_Fanet for later use
Nodes_list_FaNet = Nodes_list;

% Display initial network topology
%disp(sprintf('\n Network Initial Tepology\n'));
%scale_display_nodes_info(Nodes_list);

% Initial broadcast join messages
Nodes_list = scale_initial_broadcast_join(Nodes_list);
scale_draw_network_topology(Nodes_list, APs_list, maxx, maxy); % draw network with neighbor connections

%Generate initial events which could occur within the SCALE network
% within 1 hour
Events_list = scale_generate_initial_events(Events_list, numNodes, maxEvents, eventsPeriod);

% Now, it is time to run network topology and generate events to 
% be sent to its access points, every while loop will count as 
% 1 second of sensors' clock.

Nodes_list_FaNet = scale_FaNet_build_topology(Nodes_list_FaNet);
scale_draw_FaNet_topology(Nodes_list_FaNet, APs_list, maxx, maxy);

max_run_time = 45;

% ################### Begin of all active schema ####################

run_data = [];
for n=1:10
    temp_nodes_list = Nodes_list;
    temp_nodes_list_fanet = Nodes_list_FaNet;
    
    % First sleeping schema: every node stay awake
    [temp_nodes_list] = scale_run_all_active(temp_nodes_list, n, max_run_time);
    % Run the FaNet data dissemination schema here
    [temp_nodes_list_fanet] = scale_run_FaNet(temp_nodes_list_fanet, n, max_run_time);
    if n == 5
        scale_total_events_comparison_graph(temp_nodes_list, temp_nodes_list_fanet);
    end

    run_data = scale_collect_data(run_data, temp_nodes_list, temp_nodes_list_fanet, n);
end

broadcast_received_events = [];
fanet_received_events = [];

broadcast_dup_events = [];
fanet_dup_events = [];

broadcast_remained_power = [];
fanet_remained_power = [];


for k=1:numel(run_data)
    broadcast_received_events = [broadcast_received_events, run_data(k).broadcast.ave_received];
    fanet_received_events = [fanet_received_events, run_data(k).fanet.ave_received];
    
    broadcast_dup_events = [broadcast_dup_events, run_data(k).broadcast.ave_dup];
    fanet_dup_events = [fanet_dup_events, run_data(k).fanet.ave_dup];
    
    broadcast_remained_power = [broadcast_remained_power, run_data(k).broadcast.ave_power];
    fanet_remained_power = [fanet_remained_power, run_data(k).fanet.ave_power];
end

eb = 1:10;

% Average received messages per node
figure
semilogy(eb, broadcast_received_events, 'bo-');
hold on
semilogy(eb, fanet_received_events, 'r^-');


% Add title and axis labels
title('Average Received Packages Per Node', 'FontSize', 20)
xlabel('number of hops', 'FontSize', 14)
ylabel('Number of Packages', 'FontSize', 14)
legend({'Broadcast','FaNet'}, 'FontSize', 14);


% Average duplicated per node
figure
semilogy(eb, broadcast_dup_events, 'b^-');
hold on
semilogy(eb, fanet_dup_events, 'g^-');


% Add title and axis labels
title('Average Duplicated Packages Per Node', 'FontSize', 20)
xlabel('Number of hops', 'FontSize', 14)
ylabel('Number of packages', 'FontSize', 14)

legend({'Broadcast','FaNet'}, 'FontSize', 14);


% Average Consumed Power
figure
semilogy(eb, broadcast_remained_power, 'c^-');
hold on
semilogy(eb, fanet_remained_power, 'r^-');

% Add title and axis labels
title('Average Power Consumption Per Node', 'FontSize', 20)
xlabel('number of hops', 'FontSize', 14)
ylabel('Power (mAh)', 'FontSize', 14)

legend({'Broadcast','FaNet'}, 'FontSize', 14);

