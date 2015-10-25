function scale_percent_compare(k,protocol1,protocol2,protocol3,TotPower1,TotPower2,TotPower3,sentStatistics)
global initial_power;
figure;
TotPower=[TotPower1,TotPower2,TotPower3];
data=zeros(3,2);
data(:,1)=floor(TotPower(:)./(initial_power*k).*100);
data(1,2)=floor(sentStatistics.act_totalReceived/sentStatistics.act_sentEvent*100);
data(2,2)=floor(sentStatistics.random_totalReceived/sentStatistics.random_sentEvent*100);
data(3,2)=floor(sentStatistics.cust_totalReceived/sentStatistics.cust_sentEvent*100);


 b=bar(data);
 set(b(2),'FaceColor','y');
 ylim([0,120]);  
legend('Total Power', 'Successful Transmission' );




ygap =0.1;  % vertical gap between the bar and label

    for n = 1:length(b)
        x=get(get(b(n),'Children'),'XData');
        y=get(get(b(n),'Children'),'YData');
        for k=1:size(x,2)
            xpos = x(1,k)+(x(3,k)-x(1,k))/2;      
            ypos = y(2,k) + ygap; 
            text(xpos,ypos,[num2str(y(2,k),3), '%'],'HorizontalAlignment','center','VerticalAlignment','bottom');  
        end
    end
  
    

title('SCALE Network Statistics');
    
xlabel('Sleeping Protocol');
ylabel('Percentage (%)');

end

