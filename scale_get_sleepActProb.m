function [Psleep, Pactive]=scale_get_sleepActProb(currentPs, Node)
global powerWeight;
global neighborWeight;
global distanceWeight;

%number of neighbors
m=numel(Node.neighbors);

%number of hops to AP
if (~isempty(Node.AP_Connections) && Node.AP_Connections.through_neighbor > 0)
    hop = Node.AP_Connections.num_hops;
else
    if(m > 0)
        best_neighbor = Node.neighbors(1);
        for i=2:numel(Node.neighbors)
            if(Node.neighbors(i).status == 1 && Node.neighbors(i).AP_connection == 1) 
                if(Node.neighbors(i).AP_connection_hop_count < best_neighbor.AP_connection_hop_count)
                    best_neighbor = Node.neighbors(i);
                end
            end
        end
        hop = best_neighbor.AP_connection_hop_count;
    else
        hop = 1000; 
        % When node does not have connection 
        % to an AP, set number of hops to AP to infinity
    end
end

%hop cannot be 0, but there are many zero AP_connection_hop_count in list
if (hop==0)
Psleep = currentPs - powerWeight*sqrt(log(Node.power)) + neighborWeight*m/(m+7);
else
Psleep = currentPs - powerWeight*sqrt(log(Node.power)) + neighborWeight*m/(m+7) + distanceWeight*sqrt(1/hop);    
end

%{
a = powerWeight*sqrt(log(Node.power));
b = neighborWeight*m/(m+7);
c = distanceWeight*sqrt(1/hop);
disp(sprintf('a= %f, b= %f, c= %f', a, b, c));
disp(sprintf('Number of neighbors %d, num hops %d, old Prob %f, new Prob %f', m, hop, currentPs, Psleep));
%}

% set limit to probability
if Psleep < 0.1
    Psleep = 0.1;
elseif Psleep > 0.9
    Psleep = 0.9;
end

Pactive = 1 - Psleep;

