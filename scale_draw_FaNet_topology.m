function scale_draw_FaNet_topology(Nodes_list, APs_list, maxx, maxy)
% make background white, run only once

%colordef none,  whitebg

figure;
axis equal
hold on;
box on;

for k=1:numel(Nodes_list)

    if Nodes_list(k).level ~= 0
       % plot wireless member sensor nodes
        h1 = plot(Nodes_list(k).x_coordinate,Nodes_list(k).y_coordinate,'k.', 'MarkerSize', 30);
        text(Nodes_list(k).x_coordinate+5, Nodes_list(k).y_coordinate+0.1, [num2str(k) '-' Nodes_list(k).primary_tree_id]);
    else    
        % plot wireless root nodes
        h2 = plot(Nodes_list(k).x_coordinate,Nodes_list(k).y_coordinate,'k.', 'MarkerSize', 35, 'Color', [1 0.4 0]);
        text(Nodes_list(k).x_coordinate+5, Nodes_list(k).y_coordinate+0.1, [num2str(k) '-' Nodes_list(k).primary_tree_id], 'Color', 'r');
    end
    
    %connect each node to their parents
    if (~isempty(Nodes_list(k).parents))
        for n=1:numel(Nodes_list(k).parents)
            line = 'g-';
            if (strcmp(Nodes_list(k).primary_tree_id, Nodes_list(Nodes_list(k).parents(n).parent_node_id).primary_tree_id) == 1)
                line = 'm-';
            end
            plot([Nodes_list(k).x_coordinate, Nodes_list(Nodes_list(k).parents(n).parent_node_id).x_coordinate],[Nodes_list(k).y_coordinate, Nodes_list(Nodes_list(k).parents(n).parent_node_id).y_coordinate], line);
        end
    end
    
    %connect each node to their children
    if (~isempty(Nodes_list(k).children))
        for m=1:numel(Nodes_list(k).children)  
            line = 'g-';
            if (strcmp(Nodes_list(k).primary_tree_id, Nodes_list(Nodes_list(k).children(m)).primary_tree_id) == 1)
                line = 'm-';
            end
            plot([Nodes_list(k).x_coordinate, Nodes_list(Nodes_list(k).children(m)).x_coordinate],[Nodes_list(k).y_coordinate, Nodes_list(Nodes_list(k).children(m)).y_coordinate], line);
        end
    end
end

for k=1:numel(APs_list)
    % plot wireless access points
    h3 = plot(APs_list(k).x_coordinate,APs_list(k).y_coordinate, 'b.', 'MarkerSize', 40);
    text(APs_list(k).x_coordinate+5, APs_list(k).y_coordinate+0.1, ['AP-' num2str(k)],'Color','b');
    %connect access points to nodes
    plot([APs_list(k).x_coordinate, Nodes_list(APs_list(k).connect_node_id).x_coordinate], [APs_list(k).y_coordinate, Nodes_list(APs_list(k).connect_node_id).y_coordinate], 'b-');
end

hold off;

title('FaNet Data Dissemination Network Topology', 'FontSize', 20);
    
xlabel('X Coordinate');
ylabel('Y Coordinate');

axis([0, maxx, 0, maxy]);
set(gca, 'XTick', [0; maxx]);
set(gca, 'YTick', [maxy]);
legend([h1 h2 h3],{'Sensor Node', 'Root Node', 'Access Point'});


end
