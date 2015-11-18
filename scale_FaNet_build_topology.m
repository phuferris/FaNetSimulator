function [Nodes_list] = scale_FaNet_build_topology(Nodes_list)
    % Simulation for SCALE Wireless Sensor Box
    attemps = 200;
    
    
    while (attemps > 0)
        attemps = attemps - 1; 
        % Broadcast join message if the node has 
        % not belong into any tree
        for k=1:numel(Nodes_list)
             random_num_mod = mod(round(rand(1)*100), 20);
            if (Nodes_list(k).level == -9999 || (Nodes_list(k).level > 2 && random_num_mod == 0))    
                message = [];
                message.source = k;
                message.node_x_coordinate = Nodes_list(k).x_coordinate;
                message.node_y_coordinate = Nodes_list(k).y_coordinate;
                
                Nodes_list = broadcast_join_message(Nodes_list, message);
                
                action = [];
                action.type = 'broadcast_join';
                Nodes_list(k).power = scale_power_consumption(Nodes_list(k).power, action);
            end
        end

        
        % Process offer-to-join messages
        Nodes_list = process_join_offer_messages(Nodes_list);
        
        % Expire old join offering messages
        Nodes_list = expired_old_join_offering_messages(Nodes_list);
        
    end
    return;
end

function [Nodes_list] = process_join_offer_messages(Nodes_list)
    %loop through the nodes list
    for k=1:numel(Nodes_list)
        if ~isempty(Nodes_list(k).offers)
           [sorted_join_offers index] = sortStruct(Nodes_list(k).offers, 'parent_node_level');

           % Processs the join offers by empty out its queue first
           Nodes_list(k).offers = [];

           if (~isempty(Nodes_list(k).parents))
               primary_parent_offer = sorted_join_offers(1);

               accept_join_offer = [];
               accept_join_offer.child_node_id = k;
               accept_join_offer.parent_node_id = primary_parent_offer.parent_node_id;
               Nodes_list = process_accept_join_offer(Nodes_list, accept_join_offer);

               % swaping primary parent when the node find a better one
               if Nodes_list(k).level > primary_parent_offer.parent_node_level + 1
                    if (strcmp(Nodes_list(k).primary_tree_id, primary_parent_offer.parent_node_primary_tree_id) == 1)
                        Nodes_list(k).parents(1) = primary_parent_offer;
                        Nodes_list(k).primary_parent_id = primary_parent_offer.parent_node_id;
                        Nodes_list(k).level = primary_parent_offer.parent_node_level + 1;
                    else
                        Nodes_list(k).parents(2) = Nodes_list(k).parents(1);
                        Nodes_list(k).parents(1) = primary_parent_offer;
                        Nodes_list(k).primary_parent_id = primary_parent_offer.parent_node_id;
                        Nodes_list(k).primary_tree_id = primary_parent_offer.parent_node_primary_tree_id;
                        Nodes_list(k).level = primary_parent_offer.parent_node_level + 1;  
                    end

                    % need to update its parent with new tree ID and
                    % level
                    Nodes_list = update_children_info(Nodes_list, k);
               else
                  % Check to see if the offer is better than current secondary parents
                  if(~isempty(Nodes_list(k).parents) && ... 
                          numel(Nodes_list(k).parents) > 2 && ...
                          ~isempty(Nodes_list(k).parents(2)))
                      if Nodes_list(k).parents(2).parent_node_level > primary_parent_offer.parent_node_level + 1
                          Nodes_list(k).parents(2) = primary_parent_offer;
                      else
                          if((numel(Nodes_list(k).parents) == 2) || ... 
                                  (Nodes_list(k).parents(3).parent_node_level > primary_parent_offer.parent_node_level + 1))
                              Nodes_list(k).parents(3) = primary_parent_offer;
                          end      
                      end
                  else
                      Nodes_list(k).parents(2) = primary_parent_offer;
                  end
               end
           else
               primary_parent_offer = sorted_join_offers(1);

               accept_join_offer = [];
               accept_join_offer.child_node_id = k;
               accept_join_offer.parent_node_id = primary_parent_offer.parent_node_id;
               Nodes_list = process_accept_join_offer(Nodes_list, accept_join_offer);

               Nodes_list(k).parents = [Nodes_list(k).parents; primary_parent_offer];
               Nodes_list(k).primary_tree_id = primary_parent_offer.parent_node_primary_tree_id;
               Nodes_list(k).primary_parent_id = primary_parent_offer.parent_node_id;
               Nodes_list(k).level = primary_parent_offer.parent_node_level + 1;

               % Remove all offers that come from the same tree of the
               % primary parent offer
               sorted_join_offers = update_join_offers(sorted_join_offers, primary_parent_offer.parent_node_primary_tree_id); 

               if (~isempty(sorted_join_offers))
                   % Find the first secondary parent
                   secondary_parent_offer = find_secondary_parent(sorted_join_offers, primary_parent_offer);
                   if (~isempty(secondary_parent_offer)) 
                       Nodes_list(k).parents = [Nodes_list(k).parents; secondary_parent_offer];

                       accept_join_offer = [];
                       accept_join_offer.child_node_id = k;
                       accept_join_offer.parent_node_id = secondary_parent_offer.parent_node_id;
                       Nodes_list = process_accept_join_offer(Nodes_list, accept_join_offer);

                       % Remove all offers that come from the same tree of the
                       % secondary parent offer
                       sorted_join_offers = update_join_offers(sorted_join_offers, secondary_parent_offer.parent_node_primary_tree_id); 

                       if (~isempty(sorted_join_offers))
                           % Find the second secondary parent
                           secondary_parent_offer = find_secondary_parent(sorted_join_offers, secondary_parent_offer);
                           if (~isempty(secondary_parent_offer))
                               Nodes_list(k).parents = [Nodes_list(k).parents; secondary_parent_offer];
                               accept_join_offer = [];
                               accept_join_offer.child_node_id = k;
                               accept_join_offer.parent_node_id =secondary_parent_offer.parent_node_id;
                               Nodes_list = process_accept_join_offer(Nodes_list, accept_join_offer);
                           end
                       end
                   end
               end  
           end
        end
    end
        
    return;    
end


function [Nodes_list] = expired_old_join_offering_messages(Nodes_list)
    for k=1:numel(Nodes_list)
       if (~isempty(Nodes_list(k).offerings))
           
          updated_offering_messages = [];
          for n=1:numel(Nodes_list(k).offerings)
             if (Nodes_list(k).offerings(n).ttl > 1) 
                Nodes_list(k).offerings(n).ttl = Nodes_list(k).offerings(n).ttl -1 ;
                updated_offering_messages = [updated_offering_messages, Nodes_list(k).offerings(n)];
             end
          end
          Nodes_list(k).offerings = updated_offering_messages;
          
       end
    end
    
    return;
end

function [Nodes_list] = process_accept_join_offer(Nodes_list, join_offer)
    if isempty(join_offer.parent_node_id)
        return;
    end
    
    parent_node_id = join_offer.parent_node_id;
    
    if isempty(Nodes_list(parent_node_id).offerings)
       return; 
    end
    
    offering_index = find([Nodes_list(parent_node_id).offerings(:).join_node_id] == join_offer.child_node_id, 1);
    
    if ~isempty(offering_index)
       Nodes_list(parent_node_id).offerings(offering_index) = [];
       Nodes_list(parent_node_id).children = [Nodes_list(parent_node_id).children, join_offer.child_node_id];
    end

    return;
end

function [Nodes_list] = update_children_info(Nodes_list, parent_id)
    if isempty(Nodes_list(parent_id).children)
        return;
    end
    
    for n=1:numel(Nodes_list(parent_id).children)
        child_node_id = Nodes_list(parent_id).children(n);
        if ~isempty(Nodes_list(child_node_id))
           Nodes_list(child_node_id).level = Nodes_list(parent_id).level + 1;
           Nodes_list(child_node_id).primary_tree_id = Nodes_list(parent_id).primary_tree_id;
           Nodes_list(child_node_id).primary_parent_id = Nodes_list(parent_id).primary_parent_id;
           
           % Recursively update child nodes until it reaches to the leaf
           % nodes who don't have any child
           Nodes_list = update_children_info(Nodes_list, child_node_id);
        end
    end
end

function [sorted_join_offers] = update_join_offers(sorted_join_offers, exclude_node_tree_id)

    if isempty(sorted_join_offers) 
       return; 
    end

    updated_sorted_join_offers = [];
    for k=1:numel(sorted_join_offers)
       if (~strcmp(sorted_join_offers(k).parent_node_primary_tree_id, exclude_node_tree_id))
           updated_sorted_join_offers = [updated_sorted_join_offers, sorted_join_offers(k)];
       end
    end
    
    sorted_join_offers = updated_sorted_join_offers;
    return;
end

function [secondary_parent] =find_secondary_parent(sorted_join_offers, primary_parent_offer)
    for k=1:numel(sorted_join_offers)
       if (~strcmp(sorted_join_offers(k).parent_node_primary_tree_id, primary_parent_offer.parent_node_primary_tree_id))
          secondary_parent = sorted_join_offers(k);
          return;
       end
    end
    
    secondary_parent = '';
    return;
end

function [converged] = is_converged(Nodes_list)
    
    for k=1:numel(Nodes_list)
        if Nodes_list(k).level == -9999
            converged = 0;
            return;
        end
    end
    
    converged = 1;
    return;
end


function [Nodes_list] = broadcast_join_message(Nodes_list, message)
% Send join message to all wireless sensor 
% nodes within its current wireless cover range

    global wireless_range;
    
    sender_id = message.source;
    sender_x_coordinate = message.node_x_coordinate;
    sender_y_coordinate = message.node_y_coordinate;
    
    for k=1:numel(Nodes_list)
        % Don't broadcast join message
        % to itself
        if(sender_id ~= k)
            distance_to_potential_receiver = sqrt((Nodes_list(k).x_coordinate - sender_x_coordinate)^2 + (Nodes_list(k).y_coordinate - sender_y_coordinate)^2);
            if(distance_to_potential_receiver < wireless_range)
                % The broadcast join message reaches this node
                % It will check to see if it accepts the join
                % message and send back a offer join message
                Nodes_list = send_offer_message(Nodes_list, k, sender_id);
            end
        end
    end
    return;
end

function [Nodes_list] = send_offer_message(Nodes_list, parent_node_id, join_node_id)

    global max_children;
    global max_height;
    
    global fatnet_offer_message_size;
    
    % Dont allow new children if it has reached 
    % the limit
    if (numel(Nodes_list(parent_node_id).children) > max_children || Nodes_list(parent_node_id).level > max_height)
       return;
    end
    
    % Check to see if the broadcast join message 
    % is not from the children node
    if ~isempty(Nodes_list(parent_node_id).children)
        child_node_id_index = ismember(join_node_id, (Nodes_list(parent_node_id).children));
        if child_node_id_index ~= 0
           % Don't send join offer to nodes that are already children
           return; 
        end
    end
    
    % Check to see the join node is already in the parent tree
    if (strcmp(Nodes_list(parent_node_id).primary_tree_id, Nodes_list(join_node_id).primary_tree_id) == 1)
       return;
    end
    
    
    % parent node belongs a tree
    if (numel(Nodes_list(parent_node_id).parents) > 0)
        
        opened_slots = max_children - numel(Nodes_list(parent_node_id).children);
        if (numel(Nodes_list(parent_node_id).offerings) < opened_slots)      
            % Add an offer join message to parent node
            % to keep the offer
            offer = [];
            offer.join_node_id = join_node_id;
            offer.ttl = 3;
            Nodes_list(parent_node_id).offerings = [Nodes_list(parent_node_id).offerings, offer];
            
            action = [];
            action.type = 'computing';
            Nodes_list(parent_node_id).power = scale_power_consumption(Nodes_list(parent_node_id).power, action);
            
            
            % Add an offer join message to the join node 
            % so that it can select the best offer for their interest
            join_offer = [];
            join_offer.parent_node_id = parent_node_id;
            join_offer.parent_node_level = Nodes_list(parent_node_id).level;
            join_offer.parent_node_primary_tree_id = Nodes_list(parent_node_id).primary_tree_id;
            
            Nodes_list(join_node_id).offers = [Nodes_list(join_node_id).offers, join_offer];
            action = [];
            action.type = 'sending';
            action.packet_size = fatnet_offer_message_size; 
            Nodes_list(join_node_id).power = scale_power_consumption(Nodes_list(join_node_id).power, action);
            
        else
           return; 
        end
    else
        % Node does not belong to any tree and qualify to be the root node
        % The node nominates ifself
        if (~isempty(Nodes_list(parent_node_id).AP_Connections) && ...
                isempty( Nodes_list(parent_node_id).parents) && ...
                Nodes_list(parent_node_id).level == -9999 && ...
                isempty(Nodes_list(parent_node_id).offers))
            
                % Nodes randommly nominate themselve to be root if 
                % they are   qualified and have not found any tree to join
                random_num = mod(round(rand(1)*10), 5);
                if (random_num == 0) 
                    Nodes_list(parent_node_id).level = 0;
                    Nodes_list(parent_node_id).primary_tree_id = strcat('TREE-', num2str(round(rand(1)*100)));

                    % Add an offer join message to parent node
                    % to keep the offer
                    offer = [];
                    offer.join_node_id = join_node_id;
                    offer.ttl = 3;
                    Nodes_list(parent_node_id).offerings = [Nodes_list(parent_node_id).offerings, offer];

                    action = [];
                    action.type = 'computing';
                    Nodes_list(parent_node_id).power = scale_power_consumption(Nodes_list(parent_node_id).power, action);


                    % Add an offer join message to the join node 
                    % so that it can select the best offer for their interest
                    join_offer = [];
                    join_offer.parent_node_id = parent_node_id;
                    join_offer.parent_node_level = Nodes_list(parent_node_id).level;
                    join_offer.parent_node_primary_tree_id = Nodes_list(parent_node_id).primary_tree_id;

                    Nodes_list(join_node_id).offers = [Nodes_list(join_node_id).offers, join_offer];

                    action = [];
                    action.type = 'sending';
                    action.packet_size = fatnet_offer_message_size; 
                    Nodes_list(join_node_id).power = scale_power_consumption(Nodes_list(join_node_id).power, action);
                end
            
        end
    end
    
                
    return;
end

function [sortedStruct index] = sortStruct(aStruct, fieldName, direction)
    % [sortedStruct index] = sortStruct(aStruct, fieldName, direction)
    % sortStruct returns a sorted struct array, and can also return an index vector. The
    % (one-dimensional) struct array (aStruct) is sorted based on the field specified by the
    % string fieldName. The field must a single number or logical, or a char array (usually a
    % simple string).
    %
    % direction is an optional argument to specify whether the struct array should be sorted
    % in ascending or descending order. By default, the array will be sorted in ascending
    % order. If supplied, direction must equal 1 to sort in ascending order or -1 to sort in
    % descending order.

    %% check inputs
    if ~isstruct(aStruct)
        error('first input supplied is not a struct.')
    end % if

    if sum(size(aStruct)>1)>1 % if more than one non-singleton dimension
        error('I don''t want to sort your multidimensional struct array.')
    end % if

    if ~ischar(fieldName) || ~isfield(aStruct, fieldName)
        error('second input is not a valid fieldname.')
    end % if

    if nargin < 3
        direction = 1;
    elseif ~isnumeric(direction) || numel(direction)>1 || ~ismember(direction, [-1 1])
        error('direction must equal 1 for ascending order or -1 for descending order.')
    end % if

    %% figure out the field's class, and find the sorted index vector
    fieldEntry = aStruct(1).(fieldName);

    if (isnumeric(fieldEntry) || islogical(fieldEntry)) && numel(fieldEntry) == 1 % if the field is a single number
        [dummy index] = sort([aStruct.(fieldName)]);
    elseif ischar(fieldEntry) % if the field is char
        [dummy index] = sort({aStruct.(fieldName)});
    else
        error('%s is not an appropriate field by which to sort.', fieldName)
    end % if ~isempty

    %% apply the index to the struct array
    if direction == 1 % ascending sort
        sortedStruct = aStruct(index);
    else % descending sort
        sortedStruct = aStruct(index(end:-1:1));
    end
end