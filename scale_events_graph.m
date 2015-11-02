function [height] = scale_events_graph(Nodes_list, graph_title, height)

generated_events = [];
sent_events = [];
received_events = [];
relayed_events = [];

for k=1:numel(Nodes_list)
    generated_events = [generated_events, Nodes_list(k).generated_events];
    sent_events = [sent_events, Nodes_list(k).sent_events];
    received_events = [received_events, Nodes_list(k).received_events];
    relayed_events = [relayed_events, Nodes_list(k).relayed_events];
end

if height == 0
    max_generated = max(generated_events);

    max_sent = max(sent_events);
    max_received = max(received_events);
    max_relayed = max(relayed_events);

    heights = [max_generated max_sent max_received max_relayed];

    height = max(heights) + 2;
end

% Create a stacked bar chart using the bar function
figure
myC= [0 0.3 1; 0 0.7 1; 1 0.6 0.1; 0 0.9 0];

H = bar(1:25, [generated_events' sent_events' relayed_events' received_events'], 1);
axis([0 26 0 height]);
set(gca, 'XTick', 1:25);

% Add title and axis labels
title(graph_title, 'FontSize', 20);
xlabel('Node ID#', 'FontSize', 14)
ylabel('Number of events', 'FontSize', 14)


for k=1:4
  set(H(k),'facecolor',myC(k,:))
end

legend(H, {'Generated Events','Sent Events','Relayed Events','Successful Shared Events'}, 'Location','northwest','FontSize',14);

return;
