function [num_active_neighbors] = scale_check_active_neighbors(Neighbors)
    
if (isempty(Neighbors))
    num_active_neighbors = 0;
else
    num_active_neighbors = 0;
    for i=1:numel(Neighbors)
        if(Neighbors(i).status == 1 && Neighbors(i).AP_connection == 1) 
            num_active_neighbors = num_active_neighbors + 1;
        end
    end
    return;
end