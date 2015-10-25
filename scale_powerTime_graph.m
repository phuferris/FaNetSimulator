function scale_powerTime_graph(A,NA,Power,max_run_time, protocol)
global timeInterval;


clr=['r','g','b','k'];

figure;
hold on;
for x=1:4
plot(0:timeInterval:max_run_time,Power(x,:),[clr(x),'-'],'LineWidth',2);
end
hold off;

legend(sprintf('AP Node #%d',A(1)),sprintf('AP Node #%d',A(numel(A))),sprintf('Node #%d',NA(1)),sprintf('Node #%d',NA(numel(NA))));
title(['Power vs Time for ',protocol,' Sleep Protocol']);
xlabel('Clock(Unit Time)');
ylabel('Power(mAh)');





