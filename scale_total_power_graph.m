function scale_total_power_graph(k,protocol1,protocol2,protocol3,TotPower1,TotPower2,TotPower3)
global initial_power;
figure;
TotPower=[TotPower1,TotPower2,TotPower3];
clr=['m','g','y'];
ygap =0.1;  % vertical gap between the bar and label

    for n = 1:3           
            b=bar(n,TotPower(n));
            set(b,'FaceColor',clr(n));
            if n == 1
            ylim([0, initial_power*k+10^4]);
            hold on;
            end    
            xpos = get(b,'XData');        
            ypos = get(b,'YData') + ygap; 
            percent=floor(TotPower(n)/(initial_power*k)*100);
            text(xpos,ypos,[num2str(percent), '%'],'HorizontalAlignment','center','VerticalAlignment','bottom');        
    end
  set(gca,'XTick',[1 2 3]);  
 hold off;
legend(protocol1,protocol2,protocol3);

title('SCALE Total Power');
    
xlabel('Sleeping Protocol');
ylabel('Power (mAh)');

end

