function [Nodes_list] = scale_initial_broadcast_join(Nodes_list)
% Simulation for SCALE Wireless Sensor Box

% Initial broadcast join messages
for k=1:numel(Nodes_list)
    message = [];
    message.id = Nodes_list(k).id;
    message.status = 1; % Everynode broadcast active when it first joins the network
    message.node_x_coordinate = Nodes_list(k).x_coordinate;
    message.node_y_coordinate = Nodes_list(k).y_coordinate;
    
    if(~isempty(Nodes_list(k).AP_Connections))
        message.AP_connection = 1;
        
        node_AP_connections = Nodes_list(k).AP_Connections;
        message.AP_connection_through_node_id = node_AP_connections.through_neighbor;
        message.AP_connection_hop_count = node_AP_connections.num_hops + 1;
        message.AP_connection_AP_issid = node_AP_connections.AP_issid;
    else
        message.AP_connection = 0;
        message.AP_connection_through_node_id = 0;
        message.AP_connection_hop_count = 0;
        message.AP_connection_AP_issid = 0;
    end
     %power left after sending beacon
       
    
  %neighbor fields needs to be consistent as fields updated in beacon
  %messages (they need to exist, else compile error)
   message.power_status = Nodes_list(k).power;
   
   message.sleeping_time_left = Nodes_list(k).sleeping_time_left;
   message.active_time_left = Nodes_list(k).active_time_left;    
   
   Nodes_list = scale_broadcast_join(Nodes_list, message);
   
   action = [];
   action.type = 'broadcast_join';
   Nodes_list(k).power = scale_power_consumption(Nodes_list(k).power, action);
 
end
return;