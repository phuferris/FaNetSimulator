function scale_total_power_graph(k,protocol1,protocol2,TotPower1,TotPower2)
    global initial_power;
    figure;
    TotPower=[TotPower1,TotPower2];
    clr=['m','g'];
    ygap =0.1;  % vertical gap between the bar and label

    total_network_battery_power = initial_power*k;
    
    percentages = [];
    for n = 1:2   
        percent = (total_network_battery_power - TotPower(n))/total_network_battery_power;
        percent = round(percent, 2)*100;

        b=bar(n,percent);
        set(b,'FaceColor',clr(n));
        if n == 1
        ylim([0, 100]);
        hold on;
        end    
        xpos = get(b,'XData');        
        ypos = get(b,'YData') + ygap;   
        text(xpos,ypos,[num2str(percent), '%'],'HorizontalAlignment','center','VerticalAlignment','bottom');        
    end
    
    set(gca,'XTick',[1 2]);  
    hold off;
    legend(protocol1,protocol2);

    title('Network Total Power Comsumption Comparison', 'FontSize', 20);

    xlabel('One Hop Broadcast v.s. FaNet Dissemination Schema', 'FontSize', 14);
    ylabel('Percent of Network Power Consumption');
    
    figure;
    colormap summer;
    
    percent = (total_network_battery_power - TotPower(1))/total_network_battery_power;
    percent = round(percent, 2)*100;
    
    labels = {'Network Power Remain', 'Network Power Consumed'};
    ax1 = subplot(1,2,1);
    pie3(ax1, [(100 - percent), percent], labels);
    title(ax1,'One Hop Broadcast Share', 'FontSize', 18);
    
    percent = (total_network_battery_power - TotPower(2))/total_network_battery_power;
    percent = round(percent, 2)*100;
    ax2 = subplot(1,2,2);
    pie3(ax2,[(100 - percent), percent],labels);
    title(ax2,'FaNet Dissemination', 'FontSize', 18);
    
    
end

