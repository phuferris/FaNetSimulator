function [next_sleeping_time] = scale_get_sleeping_time(Nodes_list, spleeping_protocol)
% Calculate next sleeping time for each node for specific
% spleeping protocol

scale_parameter;

global maxRandomSleepingTime;

switch spleeping_protocol    
    case 'none'
        next_sleeping_time = 0;
    case 'random'
        next_sleeping_time = round(rand()*maxRandomSleepingTime) + 4; % from 5 to 15 seconds
    case 'customize'
        next_sleeping_time = 3 ; % need to construct a Markov chain for this
end
return;