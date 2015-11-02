function scale_events_comparison_graph(Nodes_list, Nodes_list_FaNet, type, graph_title)

broadcast_events = [];
FaNet_events = [];

for k=1:numel(Nodes_list)
    switch type
        case 'received'
            broadcast_events = [broadcast_events, Nodes_list(k).received_events];
            FaNet_events = [FaNet_events, Nodes_list_FaNet(k).received_events];
         case 'sent'
            broadcast_events = [broadcast_events, Nodes_list(k).sent_events];
            FaNet_events = [FaNet_events, Nodes_list_FaNet(k).sent_events];
       
         case 'duplicated'
            broadcast_events = [broadcast_events, Nodes_list(k).duplicated_events];
            FaNet_events = [FaNet_events, Nodes_list_FaNet(k).duplicated_events];
        otherwise
            return;
    end
end

% Create a stacked bar chart using the bar function
figure
myColor= [0 1 1; 1 0.6 1];


max_broadcast_event = max(broadcast_events);
max_FaNet_event = max(FaNet_events);

heights = [max_broadcast_event max_FaNet_event];

height = max(heights) + 2;

H = bar(1:25, [broadcast_events' FaNet_events'], 1);
axis([0 26 0 height]);
set(gca, 'XTick', 1:25);

% Add title and axis labels
title(graph_title);
xlabel('Node ID#')
ylabel('Number of events')

set(H(1),'facecolor',myColor(1,:));
set(H(2),'facecolor',myColor(2,:));

legend(H, {'One Hop Broadcast Node','FaNet Node'}, 'Location','Best','FontSize',12);

return;
