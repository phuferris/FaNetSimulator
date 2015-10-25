function scale_draw_network_topology(Nodes_list, APs_list, maxx, maxy)
% make background white, run only once

colordef none,  whitebg

figure(1);
axis equal
hold on;
box on;

for k=1:numel(Nodes_list)
    % plot wireless sensor nodes  
    h1=plot(Nodes_list(k).x_coordinate,Nodes_list(k).y_coordinate,'k.', 'MarkerSize', 30);
    text(Nodes_list(k).x_coordinate+5, Nodes_list(k).y_coordinate+0.1, num2str(k),'Color','r');
    %connect neighbors
if (~isempty(Nodes_list(k).neighbors))
    for n=1:numel(Nodes_list(k).neighbors)
        plot([Nodes_list(k).x_coordinate, Nodes_list(k).neighbors(n).node_x_coordinate],[Nodes_list(k).y_coordinate, Nodes_list(k).neighbors(n).node_y_coordinate],'m-');
    end
end
end

for k=1:numel(APs_list)
% plot wireless access points
h2=plot(APs_list(k).x_coordinate,APs_list(k).y_coordinate, 'b.', 'MarkerSize', 40);
text(APs_list(k).x_coordinate+5, APs_list(k).y_coordinate+0.1, num2str(k),'Color','g');
%connect access points to nodes
plot([APs_list(k).x_coordinate, Nodes_list(APs_list(k).connect_node_id).x_coordinate], [APs_list(k).y_coordinate, Nodes_list(APs_list(k).connect_node_id).y_coordinate], 'b-');
end

hold off;

title('SCALE Network Topology');
    
xlabel('X Coordinate');
ylabel('Y Coordinate');

axis([0, maxx, 0, maxy]);
set(gca, 'XTick', [0; maxx]);
set(gca, 'YTick', [maxy]);
legend([h1 h2],{'Sensor Node','Access Point'});


end
