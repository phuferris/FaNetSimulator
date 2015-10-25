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

global powerWeight;
global neighborWeight;
global distanceWeight;

Nodes_list = [];

sentStatistics = [];

APs_list = [];
sentEvents = 0;
forwardedEvents = 0;
totalReceived = 0;



Nodes_coordinates = zeros(numNodes, 2);

% Initialize sensor direct connection to a nearest Access Point AP
% Initialize sensor status
issid = 0;
for k=1:numNodes
    Nodes_list(k).id = k;
    Nodes_list(k).x_coordinate = rand()*maxx; % 250 feets
    Nodes_list(k).y_coordinate = rand()*maxy; % 250 feets
    
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
    if(random_AP == 0 || random_AP == 1 || random_AP == 2)
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

% Display initial network topology
disp(sprintf('\n Network Initial Tepology\n'));
scale_display_nodes_info(Nodes_list);

% disp(sprintf('Before calling drawing \n')); 
% disp(Nodes_cooordinates);

% Not allow to pass a matrix to  function
%scale_draw_network_topology(Nodes_list, APs_list, maxx, maxy);

% Initial broadcast join messages
Nodes_list = scale_initial_broadcast_join(Nodes_list);

% Display nodes' info after running network initialization
disp(sprintf('\n New Network Information after Initialization\n'));
scale_display_nodes_info(Nodes_list);
scale_draw_network_topology(Nodes_list, APs_list, maxx, maxy); % draw network with neighbor connections

%Generate initial events which could occur within the SCALE network
% within 1 hour

Events_list = [];
Events_list = scale_generate_initial_events(Events_list, numNodes, maxEvents, eventsPeriod);

% Now, it is time to run network topology and generate events to 
% be sent to its access points, every while loop will count as 
% 1 second of sensors' clock.

max_run_time = 3000;


% Run 1 ...

% ################### Begin of optimized schema ####################

% Optimized sleeping schema with Marko Chain
powerWeight = 0.02;
neighborWeight = 0.06;
distanceWeight = 0.05;
prob_sleeping1 = 0.1;
run1_Power = scale_run_custom_sleep(Nodes_list, Events_list, max_run_time, prob_sleeping1);

scale_get_events_arrived_at_APs();

sentStatistics.run1_sentEvent = sentEvents;
sentStatistics.run1_forwardedEvents = forwardedEvents;
sentStatistics.run1_totalReceived = totalReceived;
sentStatistics.run1_power = round(run1_Power);

% ################### End of optimized schema ####################


% Run 2 ... 
powerWeight = 0.02;
neighborWeight =0.06;
distanceWeight = 0.05;
prob_sleeping2 = 0.3;

% ################### Begin of optimized schema ####################

% Optimized sleeping schema with Marko Chain
run2_Power = scale_run_custom_sleep(Nodes_list, Events_list, max_run_time, prob_sleeping2);
scale_get_events_arrived_at_APs();

sentStatistics.run2_sentEvent = sentEvents;
sentStatistics.run2_forwardedEvents = forwardedEvents;
sentStatistics.run2_totalReceived = totalReceived;
sentStatistics.run2_power = round(run2_Power);

% ################### End of optimized schema ####################

disp(sprintf('Sent Statistics'));
disp(sentStatistics);

% Run 3 ... 
powerWeight = 0.02;
neighborWeight = 0.06;
distanceWeight = 0.05;
prob_sleeping3 = 0.5;

% ################### Begin of optimized schema ####################

% Optimized sleeping schema with Marko Chain
run3_Power = scale_run_custom_sleep(Nodes_list, Events_list, max_run_time, prob_sleeping3);
scale_get_events_arrived_at_APs();

sentStatistics.run3_sentEvent = sentEvents;
sentStatistics.run3_forwardedEvents = forwardedEvents;
sentStatistics.run3_totalReceived = totalReceived;
sentStatistics.run3_power = round(run3_Power);

% ################### End of optimized schema ####################

% Run 4 ... 
powerWeight = 0.02;
neighborWeight = 0.06;
distanceWeight = 0.05;
prob_sleeping4 = 0.7;

% ################### Begin of optimized schema ####################

% Optimized sleeping schema with Marko Chain
run4_Power = scale_run_custom_sleep(Nodes_list, Events_list, max_run_time, prob_sleeping4);
scale_get_events_arrived_at_APs();

sentStatistics.run4_sentEvent = sentEvents;
sentStatistics.run4_forwardedEvents = forwardedEvents;
sentStatistics.run4_totalReceived = totalReceived;
sentStatistics.run4_power = round(run4_Power);

% ################### End of optimized schema ####################


% Run 5 ... 
powerWeight = 0.02;
neighborWeight = 0.06;
distanceWeight = 0.05;
prob_sleeping5 = 1;

% ################### Begin of optimized schema ####################

% Optimized sleeping schema with Marko Chain
run5_Power = scale_run_custom_sleep(Nodes_list, Events_list, max_run_time, prob_sleeping5);
scale_get_events_arrived_at_APs();

sentStatistics.run5_sentEvent = sentEvents;
sentStatistics.run5_forwardedEvents = forwardedEvents;
sentStatistics.run5_totalReceived = totalReceived;
sentStatistics.run5_power = round(run5_Power);

% ################### End of optimized schema ####################


disp(sprintf('Sent Statistics'));
disp(sentStatistics);

%draw power graph
scale_custom_power_graph(prob_sleeping1, prob_sleeping2, prob_sleeping3, prob_sleeping4, prob_sleeping5, sentStatistics);
