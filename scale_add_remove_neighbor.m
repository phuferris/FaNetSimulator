function [Neighbors_list] = scale_add_remove_neighbor(Neighbors_list, neighbor_node, action)
% Add or remove a specific neighbor from the neighbor list for a specific
% node
    if(strcmp(action, 'add')) 
        if(~isempty(Neighbors_list))
            for k=1:numel(Neighbors_list)
                if(Neighbors_list(k).id == neighbor_node.id)
                    return; % skip adding target_node into the neighbor
                    % list if it has been added
                end
            end
        end
        
        Neighbors_list = [Neighbors_list; neighbor_node];       
    end
    
    if(strcmp(action, 'remove'))
        if(~isempty(Neighbors_list))
            for k=1:numel(Neighbors_list)
                if(Neighbors_list(k).id == neighbor_node.id)
                    Neighbors_list(k) = []; % remove the target node from current neighbors list.
                end
            end
        end
    end 
    return;
end