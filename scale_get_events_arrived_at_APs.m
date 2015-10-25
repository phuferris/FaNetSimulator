function scale_get_events_arrived_at_APs()
% Display events that have arrived at all available access points
    global APs_list;
    global sentEvents;
    global forwardedEvents;
    global totalReceived;
    
    totalReceived = 0;
    for k=1:numel(APs_list)
       disp(sprintf('AP issid #%d, received events: %d', k, APs_list(k).arrived_events)); 
       totalReceived = totalReceived + APs_list(k).arrived_events;
    end
    
    disp(sprintf('Total events sent from originator: %d', sentEvents));
    disp(sprintf('Total events forwarded: %d', forwardedEvents));
    disp(sprintf('Total events arrived at APs: %d', totalReceived));
    
end