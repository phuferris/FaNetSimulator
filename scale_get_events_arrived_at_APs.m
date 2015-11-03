function [AP_total_received_events] = scale_get_events_arrived_at_APs(APs_list)
    
    AP_total_received_events = 0;
    for k=1:numel(APs_list)
       AP_total_received_events = AP_total_received_events + APs_list(k).arrived_events;
    end
    return;
end