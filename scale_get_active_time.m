function [next_active_time] = scale_get_active_time(Nodes_list, spleeping_protocol)
% Calculate next sleeping time for each node for specific
% spleeping protocol

scale_parameter;

global maxRandomActiveTime;

switch spleeping_protocol    
    case 'none'
        next_active_time = 0;
    case 'random'
        next_active_time = round(rand()*maxRandomActiveTime) + 4; % from 5 to 15 seconds
    case 'customize'
        next_active_time = 3; % need to construct Markov chain to calculate next active time
end
return;