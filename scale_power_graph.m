function [TotPower]=scale_power_graph(Nodes_list,protocol)
global initial_power;
figure;
b=bar([Nodes_list.id],[Nodes_list.power], 'g');
set(gca, 'XTick', [Nodes_list.id]);

title([protocol, ' Power Consumption'], 'FontSize', 20);
    
xlabel('Node ID');
ylabel('Power (mAh)');


%label percentage

x = get(b,'XData');
y = get(b,'YData');
ygap = 3;  % vertical gap between the bar and label
xgap = 1;

ylim([ 0, initial_power + 500]);% Increase y limit for labels
TotPower = 0.00;
    for n = 1:length(x)  
            xpos = x(n);        
            ypos = y(n) + ygap; 
            TotPower= TotPower + round(Nodes_list(n).power, 2);
            percent=floor(Nodes_list(n).power/initial_power*100);
            text(xpos,ypos,[num2str(percent), '%'],'HorizontalAlignment','left','Rotation',90);        
    end
        
end









