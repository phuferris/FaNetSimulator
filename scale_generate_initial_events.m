function [Events_list] = scale_generate_initial_events(Events_list, numNodes, numEvents, eventsPeriod)

%numEvents = 5;

i = 0;
while(i < numEvents)
    event = [];
    event.id = i;
    event.ttl = 5;
    event.source = round(rand()*numNodes) - 1;
    event.from_node = event.source;
    event.originator = event.source;
    event.destination = 99999; % address of remote server on the cloud
    event.instant = ceil(rand()*eventsPeriod);
    event.size = rand()*100*8; % 100 kb max
    
    %disp(sprintf('event info generated at %g ', event.created_at));
    %disp(event);     
    
    Events_list = [Events_list; event];
    i = i + 1;
end;

return;