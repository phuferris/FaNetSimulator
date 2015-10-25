function scale_reset_events_arrived_at_APs()
% Display events that have arrived at all available access points
    global APs_list;

    for k=1:numel(APs_list)
       APs_list(k).arrived_events = 0;
    end
    
end