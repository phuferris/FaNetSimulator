function [events] = scale_get_events(Events_list, events, clock)
    
    events_indexes = find([Events_list(:).instant] == clock);

    if ~isempty(events_indexes)
       for k=1:numel(events_indexes)
           event = Events_list(events_indexes(k));
           events = [events; event];
       end
    end
    return;
end