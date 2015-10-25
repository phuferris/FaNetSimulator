function scale_dutyLifetime_graph(protocol1,protocol2, protocol3, ActLife, RandLife, CustLife, ActDuty, RandDuty, CustDuty)

figure;
Life=[ActLife,RandLife,CustLife];
Duty=[ActDuty,RandDuty,CustDuty];
clr=['m','g','y'];


    for n = 1:3
        if(n==1)
            hold on;
        end
          plot(Duty(n),Life(n),['.',clr(n)],'MarkerSize',30);    
    end
 % set(gca,'XTick',[1 2 3]);  

legend(protocol1,protocol2,protocol3);

plot(Duty,Life,'r--');
hold off;

title('SCALE Lifetime vs Duty Cycle');
    
xlabel('Duty Cycle (%)');
ylabel('Lifetime (Unit Time)');

end