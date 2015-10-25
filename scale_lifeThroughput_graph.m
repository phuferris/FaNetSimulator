function scale_lifeThroughput_graph(protocol1,protocol2, protocol3, ActLife, RandLife, CustLife,sentStatistics)

figure;
Life=[ActLife,RandLife,CustLife];
Thrput(1)=floor(sentStatistics.act_totalReceived/sentStatistics.act_sentEvent*100);
Thrput(2)=floor(sentStatistics.random_totalReceived/sentStatistics.random_sentEvent*100);
Thrput(3)=floor(sentStatistics.cust_totalReceived/sentStatistics.cust_sentEvent*100);
clr=['m','g','y'];


    for n = 1:3
        if(n==1)
            hold on;
        end
          plot(Life(n),Thrput(n),['.',clr(n)],'MarkerSize',30); 
    end
 % set(gca,'XTick',[1 2 3]);  
 
legend(protocol1,protocol2,protocol3);
plot(Life,Thrput,'r--');
hold off;
title('SCALE Throughput vs Lifetime');
    
xlabel('Lifetime (Unit Time)');
ylabel('Packet Delivery Rate(%)');

end

