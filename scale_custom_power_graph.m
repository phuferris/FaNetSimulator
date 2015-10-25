function scale_custom_power_graph(prob_sleeping1, prob_sleeping2, prob_sleeping3, prob_sleeping4, prob_sleeping5, sentStatistics)
global initial_power;
global numNodes;
figure;
PowerStat=[sentStatistics.run1_power,sentStatistics.run2_power,sentStatistics.run3_power, sentStatistics.run4_power,sentStatistics.run5_power];
clr=['m','g','y','b','c'];
ygap=0.1;
Prob=[prob_sleeping1, prob_sleeping2, prob_sleeping3, prob_sleeping4, prob_sleeping5];
    for n = 1:5           
           b=plot(Prob(n),PowerStat(n),[clr(n), '.'], 'MarkerSize', 30);
            if n == 1
            %ylim([0, initial_power*numNodes+10^4]);
            hold on;
            end    
            xpos = get(b,'XData');        
            ypos = get(b,'YData')+ygap; 
            percent=floor(PowerStat(n)/(initial_power*numNodes)*100);
            text(xpos,ypos,[num2str(percent), '%'],'HorizontalAlignment','center','VerticalAlignment','bottom');        
    end
    plot(Prob,PowerStat,'r--');
 xlim([0 1]); 
 hold off;

title('SCALE Power vs Sleeping Probability for Custom Sleep Protocol ');
    
xlabel('Sleeping Probability');
ylabel('Power (mAh)');

end
