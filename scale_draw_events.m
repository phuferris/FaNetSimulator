function scale_draw_events(sentStatistics)

figure;
data=[sentStatistics.act_sentEvent, sentStatistics.act_forwardedEvents, sentStatistics.act_totalReceived;
      sentStatistics.random_sentEvent, sentStatistics.random_forwardedEvents, sentStatistics.random_totalReceived;
      sentStatistics.cust_sentEvent, sentStatistics.cust_forwardedEvents, sentStatistics.cust_totalReceived];


 b=bar(data);
 set(b(2),'FaceColor','y');
 set(b(3),'FaceColor','g');
 
 ylim([0,max(get(gca,'Ylim'))+100]);  
legend('Sent Event', 'Forwarded Event','Received Event');


ygap =0.1;  % vertical gap between the bar and label

    for n = 1:length(b)
        x=get(get(b(n),'Children'),'XData');
        y=get(get(b(n),'Children'),'YData');
        for k=1:size(x,2)
            xpos = x(1,k)+(x(3,k)-x(1,k))/2;      
            ypos = y(2,k) + ygap; 
            text(xpos,ypos,[num2str(y(2,k),3)],'HorizontalAlignment','center','VerticalAlignment','bottom');  
        end
    end
  
    
title('SCALE Network Events');
    
xlabel('Sleeping Protocol');
ylabel('Count (Number)');


end

