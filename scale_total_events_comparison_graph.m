function scale_total_events_comparison_graph(Nodes_list, Nodes_list_FaNet, ...
                                            broadcast_AP_total_received_events, FaNet_AP_total_received_events)
broadcast_total_generated_events = 0;
broadcast_total_sent_events = 0;
broadcast_total_received_events = 0;
broadcast_total_relayed_events = 0;
broadcast_total_duplicated_events = 0;

fanet_total_generated_events = 0;
fanet_total_sent_events = 0;
fanet_total_received_events = 0;
fanet_total_relayed_events = 0;
fanet_total_duplicated_events = 0;

for k=1:numel(Nodes_list)
    broadcast_total_generated_events = broadcast_total_generated_events + Nodes_list(k).generated_events;
    broadcast_total_sent_events = broadcast_total_sent_events + Nodes_list(k).sent_events;
    broadcast_total_received_events = broadcast_total_received_events + Nodes_list(k).received_events;
    broadcast_total_relayed_events = broadcast_total_relayed_events + Nodes_list(k).relayed_events;
    broadcast_total_duplicated_events = broadcast_total_duplicated_events + Nodes_list(k).duplicated_events;
    
    fanet_total_generated_events = fanet_total_generated_events + Nodes_list_FaNet(k).generated_events;
    fanet_total_sent_events = fanet_total_sent_events + Nodes_list_FaNet(k).sent_events;
    fanet_total_received_events = fanet_total_received_events + Nodes_list_FaNet(k).received_events;
    fanet_total_relayed_events = fanet_total_relayed_events + Nodes_list_FaNet(k).relayed_events;
    fanet_total_duplicated_events = fanet_total_duplicated_events + Nodes_list_FaNet(k).duplicated_events;
    
end

% Draw graph to compare 

sent = [broadcast_total_sent_events, fanet_total_sent_events];
    
received = [broadcast_total_received_events, fanet_total_received_events];
relayed = [broadcast_total_relayed_events, fanet_total_relayed_events];
duplicated = [broadcast_total_duplicated_events, fanet_total_duplicated_events];

max_sent = max(sent);
max_received = max(received);
max_relayed = max(relayed);
max_duplicated = max(duplicated);


height = max([max_sent max_received max_relayed max_duplicated]) + 2;


figure
myC= [0 0.3 1; 0 0.7 .6; 1 0.6 0.1; 0 0.9 0];

H = bar(1:2, [sent' received' relayed' duplicated'], 1);
axis([0 3 0 height]);
set(gca, 'XTick', 1:2);

% Add title and axis labels
title('One Hop Broadcast and FaNet Total Events Comparison', 'FontSize', 20);
xlabel('One Hop Broadcast v.s. FaNet Dissemination', 'FontSize', 14);
ylabel('Total number of events', 'FontSize', 14)


for k=1:4
  set(H(k),'facecolor',myC(k,:))
end

legend(H, {'Sent Events','Successful Shared Events','Relayed Events','Duplicated Event'}, 'Location','northwest','FontSize',14);

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
legend('One Hop Broadcast', 'FaNet', 'Location','northwest');

title('One Hop Broadcast and FaNet Local Dissemination Rate', 'FontSize', 20);
    
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
legend('One Hop Broadcast', 'FaNet', 'Location','northwest');

title('One Hop Broadcast and FaNet Cloud Delivery Rate', 'FontSize', 20);
    
xlabel('Dissemination Schema', 'FontSize', 14);
ylabel('Cloud Delivery Rate (%)', 'FontSize', 14);

return;
