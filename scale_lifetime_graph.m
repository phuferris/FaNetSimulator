function scale_lifetime_graph(protocol1,protocol2, protocol3, ActLife, RandLife, CustLife)

figure;
Life=[ActLife,RandLife,CustLife];
clr=['m','g','y'];
ygap =0.1;  % vertical gap between the bar and label

    for n = 1:3           
            b=bar(n,Life(n));
            set(b,'FaceColor',clr(n));
            if n == 1
            hold on;
            end    
            xpos = get(b,'XData');        
            ypos = get(b,'YData') + ygap; 
            text(xpos,ypos,[num2str(Life(n))],'HorizontalAlignment','center','VerticalAlignment','bottom');        
    end
  set(gca,'XTick',[1 2 3]);  
 hold off;
 ylim([0, max(get(gca,'Ylim'))+500]);
legend(protocol1,protocol2,protocol3);

title('SCALE Lifetime');
    
xlabel('Sleeping Protocol');
ylabel('Clock (Unit Time)');

end

