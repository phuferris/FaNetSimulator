function scale_total_events_comparison_graph(Nodes_list, Nodes_list_FaNet)
broadcast_total_generated_events = 0;
broadcast_total_received_events = 0;
broadcast_total_duplicated_events = 0;

fanet_total_generated_events = 0;

fanet_total_received_events = 0;

fanet_total_duplicated_events = 0;

for k=1:numel(Nodes_list)
    broadcast_total_generated_events = broadcast_total_generated_events + Nodes_list(k).generated_events;
    broadcast_total_received_events = broadcast_total_received_events + Nodes_list(k).received_events;
    broadcast_total_duplicated_events = broadcast_total_duplicated_events + Nodes_list(k).duplicated_events;
    
    fanet_total_generated_events = fanet_total_generated_events + Nodes_list_FaNet(k).generated_events;
    fanet_total_received_events = fanet_total_received_events + Nodes_list_FaNet(k).received_events;
    fanet_total_duplicated_events = fanet_total_duplicated_events + Nodes_list_FaNet(k).duplicated_events;
    
end

% Draw graph to compare 

generated = [broadcast_total_generated_events, fanet_total_generated_events];
received = [broadcast_total_received_events, fanet_total_received_events];
duplicated = [broadcast_total_duplicated_events, fanet_total_duplicated_events];

max_generated = max(generated);
max_received = max(received);
max_duplicated = max(duplicated);

height = max([max_generated max_received max_duplicated]) + 2;

figure
myC= [0 0.9 0; 1 0.6 0.1; 1 0 0];

H = bar(1:2, [generated' received' duplicated'], 1);
axis([0 3 0 height]);
set(gca, 'XTick', 1:2);

% Add title and axis labels
title('Dissemination Performance Comparison', 'FontSize', 20);
xlabel('Broadcast v.s. FaNet', 'FontSize', 14);
ylabel('Total number of messages', 'FontSize', 14)


for k=1:3
  set(H(k),'facecolor',myC(k,:))
end

legend(H, {'Generated messages','Recieved messages','Duplicated messages'}, 'Location','northwest','FontSize',14);

%{
% Create dissemination rate graph chart

broadcast_dissemination_rate = round(100*((broadcast_total_received_events)/broadcast_total_generated_events));
fanet_dissemination_rate = round(100*((fanet_total_received_events)/fanet_total_generated_events));


% Draw data dissemination rate comparison
figure;
Dissemination_rate = [broadcast_dissemination_rate fanet_dissemination_rate];
clr=['m','g'];

ygap = 1;  % vertical gap between the bar and label

for n = 1:2           
        b=bar(n,Dissemination_rate(n));
        set(b,'FaceColor',clr(n));
        if n == 1
            hold on;
        end    
        xpos = get(b,'XData');        
        ypos = get(b,'YData') + ygap; 
        text(xpos,ypos,[num2str(Dissemination_rate(n)) '%'],'HorizontalAlignment','center','VerticalAlignment','bottom');        
end

set(gca,'XTick',[1 2]);
hold off;
ylim([0, max(get(gca,'Ylim')) + 10]);
legend('Multi Hops Broadcast', 'FaNet', 'Location','northwest');

title('Multi Hops Broadcast and FaNet Dissemination Rate', 'FontSize', 20);
    
xlabel('Dissemination Schema', 'FontSize', 14);
ylabel('Local Dissemination Rate (%)', 'FontSize', 14);


% Draw cloud delivery rate comparison
figure;

broadcast_cloud_delivery_rate = round((broadcast_AP_total_received_events/broadcast_total_generated_events), 2)*100;
fanet_cloud_delivery_rate = round((FaNet_AP_total_received_events/fanet_total_generated_events),2)*100;

Dissemination_rate = [broadcast_cloud_delivery_rate fanet_cloud_delivery_rate];
clr=['m','g'];

ygap = 1;  % vertical gap between the bar and label

for n = 1:2           
        b=bar(n,Dissemination_rate(n));
        set(b,'FaceColor',clr(n));
        if n == 1
            hold on;
        end    
        xpos = get(b,'XData');        
        ypos = get(b,'YData') + ygap; 
        text(xpos,ypos,[num2str(Dissemination_rate(n)) '%'],'HorizontalAlignment','center','VerticalAlignment','bottom');        
end

set(gca,'XTick',[1 2]);
hold off;
ylim([0, max(get(gca,'Ylim')) + 10]);
legend('Multi Hops Broadcast', 'FaNet', 'Location','northwest');

title('Multi Hops Broadcast and FaNet Cloud Delivery Rate', 'FontSize', 20);
    
xlabel('Dissemination Schema', 'FontSize', 14);
ylabel('Cloud Delivery Rate (%)', 'FontSize', 14);

%}

return;
