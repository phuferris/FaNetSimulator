function [NewEvents] = action(event, log_file)

% debug:
% TTL is determined at network layer only
% one way transmission received, reverse transmission fails, why?
    % mainly because randomness in the 'shadowing' model: solved...same distance generates same random number
    % friis model works fine
    % tworay model is mostly the same as friis because crossover distance = 100 m
    % freq should be 2.4G instead of 2.4M, white_noise_variance is changed correspondingly
% Duplicated packets due to early time out and retransmission: this is ok, just provide a larger timeout
% queue waiting problem: net_queue is actually always empty, all NET packets stack at mac_queue
    % mac_queue is accompanied by mac_status
% Question 1: how to decide the priority of broadcast, unicast transmission and receptioin?

% to add virtual carrier sense: done
% to add RTS-CTS: done
% to add ad hoc routing: done
% to add application layer actions:
% to add figures or animations to show network and traffic change: not critical

global adebug bdebug;
global Gt Gr freq L ht hr pathLossExp std_db d0 rmodel;
global cs_threshold white_noise_variance rv_threshold rv_threshold_delta;
global slot_time CW_min CW_max turnaround_time max_retries SIFS DIFS cca_time basic_rate default_power;
global max_size_mac_body size_mac_header size_rts size_cts size_ack size_plcp;
global n node Event_list;
global packet_id retransmit pending_id mac_queue backoff_attmpt backoff_counter backoff_attempt;
global nav;
global ack_tx_time cts_tx_time rts_tx_time;
global default_rate default_ttl;
global size_rreq size_rrep;
global rreq_timeout net_queue net_pending net_max_retries;
global rrep_table;  % id, route, metric
global bcast_table;
global mac_status;
global adebug bdebug cdebug ddebug;
global rreq_out rreq_in rreq_forward;
global rreq_out_crosslayer rreq_in_crosslayer rreq_forward_crosslayer;
global rrep_out rrep_in rrep_forward;
global rrep_out_crosslayer rrep_in_crosslayer rrep_forward_crosslayer rrep_destination_crosslayer;

NewEvents = [];

switch event.type    
    case 'send_phy'
        t = event.instant;
        i = event.node;
        j = event.pkt.rv;
        if adebug, disp(['send_phy at time ' num2str(t) ' node ' num2str(i) ' will send a packet to node ' num2str(j)]); end
        txtime = tx_time(event.pkt);
        if node(i, 4) == 0 & (nav(i).start > (t+txtime) | nav(i).end < t) % idle and no nav
            node(i, 3) = event.pkt.power;
            node(i, 4) = 1; % switch to transmit mode, assume turnaround time is zero
            % set up the receiver
            if j == 0   % broadcast from node i
                for k=1:n
                    % due to broadcast nature in wireless channel, every idle node may capture/sense this transmission
                    if node(k, 4)~=0 | k==i, continue; end
                    if overlap(t, t+txtime, nav(k).start, nav(k).end), continue; end
                    node(k, 4) = 2; % receiver switches to receiving mode
                    newevent = event;
                    newevent.instant = t + txtime;
                    newevent.type = 'recv_phy';
                    newevent.node = k;
                    NewEvents = [NewEvents; newevent]; clear newevent;
                end
                % when there is no node to receive this broadcast, still send it.
                % because I do not know if any node will respond, but actually node node will respond.
%                 if length(NewEvents) <= 0
%                     if ddebug, disp(['send_phy: node ' num2str(i) ' broadcasts to no nodes']); end
%                     newevent = event;
%                     newevent.instant = t;
%                     newevent.type = 'send_phy_finish';
%                     newevent.node = i;
%                     NewEvents = [NewEvents; newevent]; clear newevent;
%                     return;
%                 end
            else    % unicast from i to j
                if node(j, 4) ~= 0 | overlap(t, t+txtime, nav(j).start, nav(j).end)
                    if ddebug, disp(['send_phy: receiving node ' num2str(j) ' is not ready to receive from node ' num2str(i)]); end
                    % At physical layer, I cannot synchronize with the receiver, so I know I do not need to actually transmit?
                    % We sill transmit this packet, but no actual reception.
                    %                     newevent = event;
                    %                     newevent.instant = t;
                    %                     newevent.type = 'send_phy_finish';
                    %                     newevent.node = i;
                    %                     NewEvents = [NewEvents; newevent]; clear newevent;
                    %                     return;
                else
                    node(j, 4) = 2; % receiver is switched to receiving mode
                    newevent = event;
                    newevent.instant = t + txtime;
                    newevent.type = 'recv_phy';
                    newevent.node = j;
                    NewEvents = [NewEvents; newevent]; clear newevent;
                end
                for k=1:n
                    % due to broadcast nature in wireless channel, every idle node may capture/sense this transmission
                    if node(k, 4)~=0 | k==i | k==j, continue; end
                    if overlap(t, t+txtime, nav(k).start, nav(k).end), continue; end
                    node(k, 4) = 2; % receiver switches to receiving mode
                    newevent = event;
                    newevent.instant = t + txtime;
                    newevent.type = 'recv_phy';
                    newevent.node = k;
                    NewEvents = [NewEvents; newevent]; clear newevent;
                end
            end
            % setup the transmitter
            newevent = event;
            newevent.instant = t + txtime + eps;
            newevent.type = 'send_phy_finish';
            newevent.node = i;
            NewEvents = [NewEvents; newevent]; clear newevent;
            if strcmp(event.pkt.type, 'rts')
                % set timeout timer for RTS
                newevent = event;
                newevent.instant = t + (txtime + SIFS + cts_tx_time) * 2;   % question: how to choose this timeout limit?
                newevent.type = 'timeout_rts';
                newevent.node = i;
                NewEvents = [NewEvents; newevent]; clear newevent;
                if retransmit(i) <= 0 & pending_id(i) > 0
                    error(['send_phy: node ' num2str(i) ' there is already a pending packet, cannot send a new RTS packet']);
                end
                pending_id(i) = event.pkt.id;
            end
            if strcmp(event.pkt.type, 'data') & j ~= 0
                % set timeout timer for DATA
                newevent = event;
                newevent.instant = t + (txtime + SIFS + ack_tx_time) * 2;   % double check
                newevent.type = 'timeout_data';
                newevent.node = i;
                NewEvents = [NewEvents; newevent]; clear newevent;
                if retransmit(i) <= 0 & pending_id(i) > 0
                    error(['send_phy: node ' num2str(i) ' there is already a pending packet, cannot send a new DATA packet']);
                end
                pending_id(i) = event.pkt.id;
            end
        else    % radio hardware is not idle or nav block
            if adebug, disp(['send_phy at time ' num2str(t) ' node ' num2str(i) ' is not ready to send a packet to node ' num2str(j)]); end
            if adebug, disp(['--- node(i, 4)=' num2str(node(i, 4)) 'nav.start=' num2str(nav(i).start) 'nav.end=' num2str(nav(i).end)]); end
            % Since the node status is already checked at MAC layer, it must be due to NAV virtual carrier sense
            % I am a hiddent node: physical carrier sense is okay, but blocked by virtual carrier sense
            % I should go back to MAC and try later.
            newevent = event;
            newevent.instant = t + cca_time;
            newevent.type = 'wait_for_channel';
            newevent.node = i;
            NewEvents = [NewEvents; newevent]; clear newevent;
            % Drop the packet, and try next MAC packet if any
%             if ~isempty(mac_queue(i).list)
%                 % more packets are waiting to be sent
%                 mac_status(i) = 1;
%                 newevent = mac_queue(i).list(1);
%                 mac_queue(i).list(1) = [];
%                 newevent.instant = t + cca_time;   % question: should cca_time or other be used here?
%                 newevent.type = 'wait_for_channel';
%                 newevent.node = i;
%                 NewEvents = [NewEvents; newevent]; clear newevent;
%             else
%                 mac_status(i) = 0;
%             end
        end
    case 'send_phy_finish'
        t = event.instant;
        i = event.node;
        j = event.pkt.rv;
        if bdebug, disp(['send_phy_finish @ node ' num2str(i)]); end
        if node(i, 4) ~= 1
            error(['send_phy_finish: node ' num2str(i) ' should be in transmission mode']);
        end
        node(i, 4) = 0; % after all receivings, go back to idle
        node(i, 3) = 0;
        if j==0 % | strcmp(event.pkt.type, 'ack')
            % finished broadcast % or finished RTS-CTS-DATA-ACK for unicast
            if ~isempty(mac_queue(i).list)
                % more packets are waiting to be sent
                mac_status(i) = 1;
                newevent = mac_queue(i).list(1);
                mac_queue(i).list(1) = [];
                newevent.instant = t + cca_time;   % question: should cca_time or other be used here?
                newevent.type = 'wait_for_channel';
                newevent.node = i;
                NewEvents = [NewEvents; newevent]; clear newevent;
            else
                mac_status(i) = 0;
            end
        end
    case 'recv_phy'
        t = event.instant;
        i = event.pkt.tx;
        j = event.node;
        if bdebug, disp(['recv_phy @ node ' num2str(j)]); end
        if node(j, 4) ~= 2 
            error(['recv_phy: node ' num2str(j) ' is not in receive mode']);
        end
        node(j, 4) = 0; % receiver switches back to idle mode
        if t > nav(j).start & t < nav(j).end
            % this has already been checked when sending
            % but nav may be changed during transmission, so double check
            if ddebug, disp(['recv_phy: packet virtual collision at node ' num2str(j)]); end
            % just drop the packet
        else
            [pr, snr] = recv_phy(i, j, rmodel);
            % disp(['recv_phy: node ' num2str(i) ' to node ' num2str(j) ' with snr= ' num2str(snr) ' and distance=' num2str(topo_dist(i, j))]); 
            t1 = rv_threshold_delta;
            if snr >= (rv_threshold+t1)
                probability_receive = 1;
            elseif snr < (rv_threshold-t1)
                probability_receive = 0;
            elseif rand <= (snr-(rv_threshold-t1))/(t1+t1)
                probability_receive = 1;
            else
                probability_receive = 0;
            end
            if probability_receive
                if event.pkt.rv == 0 | event.pkt.rv == j   % broadcast or unicast to this receiver
                    % TTL is taken care of at network layer
                    % event.pkt.ttl = event.pkt.ttl - 1;
                    % if event.pkt.ttl < 0
                    %     if adebug, disp(['recv_phy: TTL from node ' num2str(i) ' to node ' num2str(j) ' is negative, drop the packet']); end
                    %     return;
                    % end
                    % there is already a MAC layer packet waiting for transmission, but this incoming packet should be 
                    % received first, no futher receiving is possible (see send_phy)
                    % if mac_status(j)
                    %     if adebug, disp(['recv_phy: node ' num2str(j) ' is waiting to transmit, so cannot receive']); end
                    newevent = event;
                    newevent.instant = t;
                    newevent.type = 'recv_mac';
                    newevent.node = j;
                    NewEvents = [NewEvents; newevent]; clear newevent;
                elseif event.pkt.nav > 0    % this packet is not for me, but use its nav
                    if nav(j).start < t
                        nav(j).start = t;
                    end
                    if nav(j).end < (t+event.pkt.nav)
                        % question: debug
                        nav(j).end = t + event.pkt.nav;
                    end
                end
            else
                if bdebug, disp(['recv_phy: packet from node ' num2str(i) ' cannot be successfully received at node' num2str(j)]); end
            end
        end
    case 'send_mac'
        t = event.instant;
        i = event.node;
        j = event.pkt.rv;
        
        disp(['In send mac']);
   
        if bdebug, disp(['send_mac: node ' num2str(i) ' to send to node ' num2str(j) ' isempty(mac_queue)=' num2str(isempty(mac_queue(i).list)) ' mac_status=' num2str(mac_status(i))]); end
        event.pkt.id = new_id(i);
        event.pkt.type = 'data';    % used in function call of 'tx_time'
        % the tx_time should be the same as in 'send_phy'
        event.pkt.nav = SIFS + cts_tx_time + SIFS + tx_time(event.pkt) + SIFS + ack_tx_time;
        % if ddebug, disp(['send_mac node ' num2str(i) ' will reserve NAV=' num2str(event.pkt.nav)]); end
        if j ~= 0
            % for unicast, RTS should be sent first
            event.pkt.type = 'rts';
        end
        % keep the data body size and rate for transmitting data later
        if ~isempty(mac_queue(i).list) & ~mac_status(i)
            error(['send_mac: node ' num2str(i) ' channel is free, but there is still packets waiting at MAC...this should not happen']);
        end
        if ~isempty(mac_queue(i).list) | mac_status(i)
            % old packets are waiting to be sent, just wait behind them
            % or one packet is being transmitted at MAC layer, just wait in the MAC queue
            mac_queue(i).list = [mac_queue(i).list event];
        else
            mac_status(i) = 1;
            % newevent.instant = t + turnaround_time; % swith to transmit
            newevent = event;
            newevent.instant = t + cca_time;    % check channel status
            newevent.type = 'wait_for_channel';
            newevent.node = i;
            NewEvents = [NewEvents; newevent]; clear newevent;
        end
    case 'wait_for_channel'
        t = event.instant;
        i = event.node;
        j = event.pkt.rv;
        
        if bdebug, disp(['wait_for_channel @ node ' num2str(i)]); end
%         if mac_status(i) == 0
%             % Reset by timeout_rreq after many RREQ retries
%             if ddebug, disp(['wait_for_channel: node ' num2str(i) 'mac_status reset because so many RREQ retries at network layer']); end
%             return;
%         end
        if node(i, 4) == 0 & carrier_sense(i) == 0
            % question: I want to transmit, but have to capture from many neighbors
            % the node is idle and the channel is free, can backoff now
            if backoff_counter(i) > 0   % resume the backoff
                newevent = event;
                newevent.instant = t + slot_time;
                newevent.type = 'backoff';
                newevent.node = i;
                NewEvents = [NewEvents; newevent]; clear newevent;
            else                        % start from DIFS first
                newevent = event;
                newevent.instant = t + DIFS;
                newevent.type = 'backoff_start';
                newevent.node = i;
                NewEvents = [NewEvents; newevent]; clear newevent;
            end
        else
            % the node is not idle; must be receiving...wait until this receiving is finished
            % or the channel is not free; wait until the channel is free
            newevent = event;
            newevent.instant = t + cca_time;
            newevent.type = 'wait_for_channel';
            newevent.node = i;
            NewEvents = [NewEvents; newevent]; clear newevent;
        end
    case 'backoff_start'  % after DIFS, start backoff
        t = event.instant;
        i = event.node;
        j = event.pkt.rv;
        if bdebug, disp(['backoff_start @ node ' num2str(i)]); end
        if node(i, 4) == 0 & carrier_sense(i) == 0
            % the node is still idle and the channel is free, start backoff
            % question: what if the channel was busy during this DIFS period?
            backoff_attempt(i) = 0;
            temp = min(backoff_attempt(i)+CW_min,CW_max);
            backoff_counter(i) = floor((2^temp-1)*rand);
            newevent = event;
            newevent.instant = t + slot_time;
            newevent.type = 'backoff';
            newevent.node = i;
            NewEvents = [NewEvents; newevent]; clear newevent;
        else
            % channel becomes busy during DIFS, wait until the channel is free
            newevent = event;
            newevent.instant = t + cca_time;
            newevent.type = 'wait_for_channel';
            newevent.node = i;
            NewEvents = [NewEvents; newevent]; clear newevent;
        end
    case 'backoff'
        t = event.instant;
        i = event.node;
        j = event.pkt.rv;
        if bdebug, disp(['backoff @ node ' num2str(i)]); end
        if node(i, 4) == 0 & carrier_sense(i) == 0
            % the node is still idle and the channel is free, continue backoff
            if backoff_counter(i) > 1
                backoff_counter(i) = backoff_counter(i) - 1;
                newevent = event;
                newevent.instant = t + slot_time;
                newevent.type = 'backoff';
                newevent.node = i;
                NewEvents = [NewEvents; newevent]; clear newevent;
            else    % ready to send the packet
                backoff_counter(i) = 0; % reset counter for next use
                newevent = event;
                newevent.instant = t;
                newevent.type = 'send_phy';
                newevent.node = i;
                NewEvents = [NewEvents; newevent]; 
                % txtime = tx_time(newevent.pkt);
                clear newevent;
                % mac_queue will be taken care of after really send this packet in 'send_phy_finish'
%                 if j == 0   % broadcast: the real data is sent here
%                     % we can send the next packet from mac_queue now
%                     if ~isempty(mac_queue(i).list)
%                         % more packets are waiting to be sent
%                         newevent = mac_queue(i).list(1);
%                         mac_queue(i).list(1) = [];
%                         newevent.instant = t + txtime + cca_time;   % question: should cca_time or other be used here?
%                         newevent.type = 'wait_for_channel';
%                         newevent.node = i;
%                         NewEvents = [NewEvents; newevent]; clear newevent;
%                     else
%                         % will reset in 'send_phy_finish'
%                         % mac_status(i) = 0;
%                     end
%                 else
%                     % unicast: the RTS is sent here, will wait for CTS or timeout_rts
%                     % do nothing here
%                 end
            end
        else   % channel becomes busy during backoff count-down
            if backoff_counter(i) > 1
                backoff_counter(i) = backoff_counter(i) - 1;
            else
                % start a new backoff counter when count-down is zero
                backoff_attempt(i) = backoff_attempt(i) + 1;
                temp = min(backoff_attempt(i)+CW_min,CW_max);
                backoff_counter(i) = floor((2^temp-1)*rand);
            end
            newevent = event;
            newevent.instant = t + cca_time;
            newevent.type = 'wait_for_channel';
            newevent.node = i;
            NewEvents = [NewEvents; newevent]; clear newevent;
        end
    case 'timeout_rts'
        t = event.instant;
        i = event.node;
        j = event.pkt.rv;
        if adebug, disp(['timeout_rts @ node ' num2str(i)]); end
        if pending_id(i) == event.pkt.id % not acknowledged yet, retransmit
            if cdebug, disp(['timeout_rts: node ' num2str(i) ' pending_id=' num2str(pending_id(i)) ' event_id=' num2str(event.pkt.id)]); end
            retransmit(i) = retransmit(i) + 1;
            if retransmit(i) > max_retries
                % so many retries, drop the packet
                if cdebug, disp(['timeout_rts: node ' num2str(i) ' has retried so many times to transmit RTS']); end
                retransmit(i) = 0;
                pending_id(i) = 0;
                % question: what if there are waiting packets in mac_queue?
                % answer: should send them anyway as if the current packet is done.
                % similar to the the operation when ACK is received
                if ~isempty(mac_queue(i).list)
                    % more packets are waiting to be sent
                    % newevent.instant = t + turnaround_time; % switch from receive to transmit
                    mac_status(i) = 1;
                    newevent = mac_queue(i).list(1);
                    mac_queue(i).list(1) = [];
                    newevent.instant = t + cca_time;    % question: cca_time or other
                    newevent.type = 'wait_for_channel';
                    newevent.node = i;
                    % packet setup is already done in 'send_mac' before put into the mac_queue
                    NewEvents = [NewEvents; newevent]; clear newevent;
                else
                    % cannot send RTS successfully, reset MAC layer
                    mac_status(i) = 0;
                end
                return;
            end
            if adebug, disp(['timeout_rts: node ' num2str(i) ' to retransmit RTS']); end
            % retransmit the RTS
            newevent = event;
            newevent.instant = t + cca_time;    % check channel status
            newevent.type = 'wait_for_channel';
            newevent.node = i;
            NewEvents = [NewEvents; newevent]; clear newevent;
        else
            % if pending_id(i) ~= 0 & ddebug, disp(['timeout_rts at node ' num2str(i) ' pending id=' num2str(pending_id(i)) ' does not match the waiting RTS id=' num2str(event.pkt.id)]); end
        end
    case 'timeout_data'
        t = event.instant;
        i = event.node;
        j = event.pkt.rv;
        if adebug, disp(['timeout_data @ node ' num2str(i)]); end
%         if pending_id(i) == event.pkt.id % not acknowledged yet
%             if adebug, disp(['timeout_data: node ' num2str(i) ' failed to transmit DATA, go back to transmit RTS']); end
%             % remove the pending id for DATA
%             pending_id(i) = 0;
%             retransmit(i) = 0;
%             % go back to send RTS
%             newevent = event;
%             newevent.instant = t + cca_time;    % check channel status
%             newevent.type = 'wait_for_channel';
%             newevent.node = i;
%             newevent.pkt.type = 'data';
%             newevent.pkt.nav = SIFS + cts_tx_time + SIFS + tx_time(newevent.pkt) + SIFS + ack_tx_time;
%             newevent.pkt.type = 'rts';
%             % create a new id for the new RTS
%             newevent.pkt.id = new_id(i);
%             NewEvents = [NewEvents; newevent]; clear newevent;
%         end
        if pending_id(i) == event.pkt.id % not acknowledged yet
            if cdebug, disp(['timeout_data: node ' num2str(i) ' pending_id=' num2str(pending_id(i)) ' event_id=' num2str(event.pkt.id)]); end
            retransmit(i) = retransmit(i) + 1;
            if retransmit(i) > max_retries
                % so many retries, drop the data packet
                if cdebug, disp(['timeout_data: node ' num2str(i) ' has retried so many times to transmit DATA']); end
                retransmit(i) = 0;
                pending_id(i) = 0;
                if ~isempty(mac_queue(i).list)
                    % more packets are waiting to be sent
                    mac_status(i) = 1;
                    newevent = mac_queue(i).list(1);
                    mac_queue(i).list(1) = [];
                    newevent.instant = t + cca_time;    % question: cca_time or other
                    newevent.type = 'wait_for_channel';
                    newevent.node = i;
                    NewEvents = [NewEvents; newevent]; clear newevent;
                else
                    % Cannot send DATA successfully, reset MAC layer
                    mac_status(i) = 0;
                end
                return;
            end
            if adebug, disp(['timeout_data: node ' num2str(i) ' to retransmit DATA']); end
            % retransmit the DATA
            newevent = event;
            newevent.instant = t + cca_time;    % check channel status
            newevent.type = 'wait_for_channel';
            newevent.node = i;
            % newevent.pkt.type = 'data';
            newevent.pkt.nav = SIFS + ack_tx_time; % necessary for retransmission because the initial DATA has NAV=0
            NewEvents = [NewEvents; newevent]; clear newevent;
        end
    case 'recv_mac'
        t = event.instant;
        i = event.pkt.tx;
        j = event.node;
        if adebug, disp(['recv_mac @ node ' num2str(j)]); end
        if event.pkt.rv == 0 & strcmp(event.pkt.type, 'data') == 0
            % broadcast but not data packet
            error(['recv_mac: node ' num2str(j) ' receives a broadcast packet with a wrong type: ' event.pkt.type]);
        end
        if j == i
            % I myself sent this packet, no action
            return;
        end
        switch event.pkt.type
            case 'rts'
                % send back a CTS
                newevent = event;
                newevent.instant = t + SIFS;
                newevent.type = 'send_phy';
                newevent.node = j;
                % keep the data size, rate, and id as RTS packet
                newevent.pkt.type = 'cts';
                newevent.pkt.tx=j;
                newevent.pkt.rv=i;
                newevent.pkt.nav=event.pkt.nav - SIFS - cts_tx_time;
                NewEvents = [NewEvents; newevent]; clear newevent;
            case 'cts'
                % remove pending id for RTS
                if pending_id(j) ~= event.pkt.id
                    if ddebug, disp(['the received CTS id ' num2str(event.pkt.id) ' does not match the pending RTS id ' num2str(pending_id(j))]); end
                    % probably this CTS is in response to an earlier RTS,
                    % but I have retransmitted a new RTS which is replied
                    % already or I have retransmitted so many times and given up
                    % so we just ignore this CTS.
                    return;
                end
                pending_id(j) = 0;
                retransmit(j) = 0;
                % send DATA
                newevent = event;
                newevent.instant = t + SIFS;
                newevent.type = 'send_phy';
                newevent.node = j;
                % keep the data size and rate as before
                % newevent.pkt.ttl = 1;
                newevent.pkt.type = 'data';
                newevent.pkt.tx=j;
                newevent.pkt.rv=i;
                % creat a new id for the data packet
                newevent.pkt.id = new_id(j);
                newevent.pkt.nav = 0; % not necessary because RTS already did so
                NewEvents = [NewEvents; newevent]; clear newevent;
            case 'data'
                % should check that this is not a duplicated or out-of-order packet
                if event.pkt.rv ~= 0    % send ACK if not broadcast
                    % send back an ACK
                    newevent = event;
                    newevent.instant = t + SIFS;
                    newevent.type = 'send_phy';
                    newevent.node = j;
                    % keep the data size, rate, and id the same as DATA packet
                    newevent.pkt.type = 'ack';
                    newevent.pkt.tx=j;
                    newevent.pkt.rv=i;
                    newevent.pkt.nav=0; % not necessary because CTS already did so
                    NewEvents = [NewEvents; newevent]; clear newevent;
                end
                % send data up to network layer
                newevent = event;
                % Make sure the ACK is sent out before processing this data packet in
                % the upper layers because the upper layers may immediately
                % send more packets upon receiving this data packet.
                if event.pkt.rv ~= 0, 
                    newevent.instant = t + SIFS + ack_tx_time + 2*eps;
                else
                    newevent.instant = t + 2*eps;
                end
                newevent.type = 'recv_net';
                newevent.node = j;
                NewEvents = [NewEvents; newevent]; clear newevent;
            case 'ack'
                % make sure the acknowledged packet is the just sent DATA packet
                if pending_id(j) ~= event.pkt.id
                    if ddebug, disp(['the received ACK id=' num2str(event.pkt.id) ' does not match the pending DATA id=' num2str(pending_id(j))]); end
                    % probably this is a duplicated ACK (same reason as the above CTS case)
                    return;
                end
                % remove pending id for DATA
                pending_id(j) = 0;
                retransmit(j) = 0;
                if ~isempty(mac_queue(j).list)
                    % more packets are waiting to be sent
                    % newevent.instant = t + turnaround_time; % switch from receive to transmit
                    % if ddebug, disp('recv_mac: after receiving ACK, take the next packet from mac_queue'); end
                    mac_status(j) = 1;
                    newevent = mac_queue(j).list(1);
                    mac_queue(j).list(1) = [];
                    newevent.instant = t + cca_time;
                    newevent.type = 'wait_for_channel';
                    newevent.node = j;
                    % the packet setup is already done in 'send_mac'
                    NewEvents = [NewEvents; newevent]; clear newevent;
                else
                    mac_status(j) = 0;
                end
            otherwise
                disp(['recv_mac: Undefined mac packet type: ' event.pkt.type]);
        end
    case 'send_net'
        % event provides net.dst, net.src, net.size
        t = event.instant;
        i = event.node;
        j = event.net.dst;
        if adebug, disp(['send_net @ node ' num2str(i)]); end
        % net_queue
        if ~isempty(net_queue(i).list)
            % this is redundant; net_queue is always empty
            % old packets are waiting to be sent, just wait behind them
            % if cdebug, disp(['time ' num2str(t) ' node ' num2str(i) ' queue a packet to node ' num2str(j)]); end
            net_queue(i).list = [net_queue(i).list event];
        else
            newevent = event;
            newevent.type = 'send_net2';
            NewEvents = [NewEvents; newevent]; clear newevent;
        end
    case 'send_net2'
        t = event.instant;
        i = event.node;
        j = event.net.dst;
        
        if adebug, disp(['send_net2 @ node ' num2str(i)]); end
        % if ddebug, disp(['send_net2: time ' num2str(t) ' node ' num2str(i) ' starts to send a packet to node ' num2str(j)]); end
        if j == 0   % broadcast
            newevent = event;
            newevent.instant = t;
            newevent.type = 'send_mac';
            newevent.node = i;
            newevent.net.type = 'data';
            newevent.net.id = new_id(i);
            newevent.net.route = [];
            newevent.net.metric = 0;
            newevent.pkt.tx=i; % or event.net.src
            newevent.pkt.rv=0;
            newevent.pkt.type='data';
            newevent.pkt.size=event.net.size;   % assume no header in network layer
%             if event.pkt.ttl <= 0, newevent.pkt.ttl = default_ttl; end
%             if event.pkt.rate <= 0, newevent.pkt.rate=default_rate; end
%             if event.pkt.power <= 0, newevent.pkt.power=default_power; end            
            newevent.pkt.ttl = default_ttl;
            newevent.pkt.rate=default_rate;
            newevent.pkt.power=default_power;
            newevent.pkt.id=0;
            newevent.pkt.nav=0;
            disp(newevent);
            NewEvents = [NewEvents; newevent]; clear newevent;
        else    % unicast: find the route by RREP-RREQ
            % assume no neighbor table, find route even dst. is in the neighborhood
            % assume no routing table, RREP will contain whole route
            newevent = event;
            newevent.instant = t;
            newevent.type = 'send_mac';
            newevent.node = i;
            newevent.net.type = 'rreq';
            rreq_out(i) = rreq_out(i) + 1;
            
            if strcmp(newevent.app.type, 'crosslayer_searching')
                rreq_out_crosslayer(i) = rreq_out_crosslayer(i) + 1;
            end
            % if ddebug, disp(['rreq_out(' num2str(i) ')=' num2str(rreq_out(i))]); end
            newevent.net.id = new_id(i);
            newevent.net.route = [i];
            newevent.net.metric = 0;    % no use for now
            newevent.pkt.tx=i;  % or event.net.src
            newevent.pkt.rv=0;  % broadcast RREQ
            newevent.pkt.type='data';
            newevent.pkt.size=size_rreq;
%             if event.pkt.ttl <= 0, newevent.pkt.ttl = default_ttl; end
%             if event.pkt.rate <= 0, newevent.pkt.rate=default_rate; end
%             if event.pkt.power <= 0, newevent.pkt.power=default_power; end
            newevent.pkt.ttl = default_ttl;
            newevent.pkt.rate=default_rate;
            newevent.pkt.power=default_power;
            newevent.pkt.id=0;
            newevent.pkt.nav=0;
            NewEvents = [NewEvents; newevent];
            % set timeout timer for RREQ
            newevent.instant = t + rreq_timeout;   % question: how large should this timeout be?
            newevent.type = 'timeout_rreq';
            NewEvents = [NewEvents; newevent];
            net_pending(i).id = [net_pending(i).id newevent.net.id];   % save the id of pending RREQ
            net_pending(i).retransmit = [net_pending(i).retransmit 0];
            clear newevent;
        end
    case 'timeout_rreq'
        t = event.instant;
        i = event.node;
        j = event.net.dst;
        
        if bdebug, disp(['timeout_rreq @ node ' num2str(i)]); end
        temp = find(net_pending(i).id == event.net.id);
        if isempty(temp)
            % The RREQ is already acknowledged and is not pending anymore, do nothing
            return;
        end
        if length(temp) > 1
            error(['timeout_rreq: node ' num2str(i) ' has more than one pending RREQs with id=' num2str(event.net.id)]);
        end
        % The RREQ is not acknowledged yet by an RREP
        if ddebug, disp(['timeout_rreq: at time: ' num2str(t) ' node ' num2str(i) ' pending RREQ id=' num2str(net_pending(i).id(temp))]); end
        net_pending(i).retransmit(temp) = net_pending(i).retransmit(temp) + 1;
        if net_pending(i).retransmit(temp) > net_max_retries
            % so many retries, drop the RREQ
            % An RREP may come later, will just ignore
            if ddebug, disp(['timeout_rreq: node ' num2str(i) ' has retried so many times to transmit RREQ']); end
            net_pending(i).id(temp) = [];
            net_pending(i).retransmit(temp) = [];
%             Should take care of MAC layer queue
%             if ~isempty(mac_queue(i).list)
%                 % more packets are waiting to be sent
%                 % newevent.instant = t + turnaround_time; % switch from receive to transmit
%                 mac_status(i) = 1;
%                 newevent = mac_queue(i).list(1);
%                 mac_queue(i).list(1) = [];
%                 newevent.instant = t + cca_time;    % question: cca_time or other
%                 newevent.type = 'wait_for_channel';
%                 newevent.node = i;
%                 % packet setup is already done in 'send_mac' before put into the mac_queue
%                 NewEvents = [NewEvents; newevent]; clear newevent;
%             else
%                 % cannot send RREQ successfully, reset MAC layer
%                 mac_status(i) = 0;
%             end
            if ~isempty(net_queue(i).list)
                % this is redundant, net_queue is always empty
                % more packets are waiting to be sent
                error(['timeout_rreq: node ' num2str(i) ' have a non-empty network layer queue']);
                newevent = net_queue(i).list(1);
                net_queue(i).list(1) = [];
                newevent.instant = t;
                newevent.type = 'send_net2';
                NewEvents = [NewEvents; newevent]; clear newevent;
            end
            return;
        end
        if adebug, disp(['timeout_rreq: node ' num2str(i) ' to retransmit RREQ']); end
        % retransmit the RREQ
        newevent = event;
        newevent.instant = t;
        newevent.type = 'send_mac';
        newevent.net.id = new_id(i);  % question: do we need a new id for this retransmission? answer: yes, for bcast_table
        net_pending(i).id(temp) = newevent.net.id;
        rreq_out(i) = rreq_out(i) + 1;
        if strcmp(newevent.app.type, 'crosslayer_searching')
            rreq_out_crosslayer(i) = rreq_out_crosslayer(i) + 1;
        end
        NewEvents = [NewEvents; newevent];
        % set timeout timer for the retransmitted RREQ
        newevent.instant = t + rreq_timeout;   % question: same as above
        newevent.type = 'timeout_rreq';
        NewEvents = [NewEvents; newevent]; 
        net_pending(i).id(temp) = newevent.net.id;   % save the new id of the pending RREQ
        clear newevent;
    case 'recv_net'
        t = event.instant;
        i = event.net.src;
        j = event.node;
        if bdebug, disp(['time ' num2str(t) ' recv_net @ node ' num2str(j)]); end
        % take care of TTL at network layer
        event.pkt.ttl = event.pkt.ttl - 1;
        if event.pkt.ttl < 0
            if bdebug, disp(['recv_net: TTL from node ' num2str(i) ' to ' num2str(j) ' is negative, drop the packet']); end
            return;
        end
        if j == i | j == event.pkt.tx
            % I myself sent this packet, no action
            return;
        end
        % if cdebug, disp(['time ' num2str(t) 'node ' num2str(event.pkt.tx) ' -> node ' num2str(j) ' with type ' event.net.type]); end
        switch event.net.type
            case 'rreq'
                rreq_in(j) = rreq_in(j) + 1;
                if strcmp(event.app.type, 'crosslayer_searching')
                    rreq_in_crosslayer(j) = rreq_in_crosslayer(j) + 1;
                end
                if sum(ismember(event.net.route, j))
                    % I am already in the found route
                    return;
                end
                event.net.route = [event.net.route j];
                if j == event.net.dst
                    % I am the destination of this RREQ: send RREP back
                    % check if I have already replied to the same RREQ
                    % if ~isempty(rrep_table) & sum(ismember(rrep_table, [i event.net.id], 'rows'))
                    % we currently use: rrep_table.id, rrep_table.metric, rrep_table.route
                    send_rrep = -1;
                    if isempty(rrep_table(j).list)
                        k = 1;
                        send_rrep = 1;
                    else
                        % rrep_table is not empty
                        for k=1:length(rrep_table(j).list)
                            if rrep_table(j).list(k).route(1)==i
                                % find a early saved RREQ from the same src
                                % assume this is the only saved RREQ from the same src
                                if rrep_table(j).list(k).id < event.net.id
                                    % I replied to an older RREQ: take the new one and reply
                                    send_rrep = 1;
                                elseif rrep_table(j).list(k).id == event.net.id
                                    % I replied to the same RREQ: should I reply to again?
                                    if event.net.metric < rrep_table(j).list(k).metric
                                        % metric: the samller the better
                                        % This is a better route, take it and reply
                                        send_rrep = 1;
                                    else
                                        % not a better route: ignore
                                        send_rrep = 0;
                                    end
                                else
                                    % I replied to a newer RREQ: ignore
                                    send_rrep = 0;
                                end
                                break;
                            end
                        end
                    end
                    if send_rrep ~= 0
                        rrep_out(j) = rrep_out(j) + 1;
                        if strcmp(event.app.type, 'crosslayer_searching')
                            rrep_out_crosslayer(j) = rrep_out_crosslayer(j) + 1;
                        end
                        if send_rrep < 0
                            % no early saved RREQ from this src: add one
                            k = length(rrep_table(j).list) + 1; % same as: k = k + 1;
                        end
                        rrep_table(j).list(k).id = event.net.id;
                        rrep_table(j).list(k).metric = event.net.metric;
                        rrep_table(j).list(k).route = event.net.route;
                        newevent = event;
                        newevent.instant = t;
                        newevent.type = 'send_mac';
                        newevent.net.type = 'rrep';
                        newevent.net.src = j;
                        newevent.net.dst = i;
                        newevent.pkt.tx = j;
                        newevent.pkt.rv = newevent.net.route(length(newevent.net.route)-1); % next hop
                        newevent.pkt.type='data';
                        newevent.pkt.size=size_rrep;
                        newevent.pkt.rate=default_rate;
                        newevent.pkt.ttl = default_ttl;   % unicast question: what value for this TTL?
                        newevent.pkt.power=default_power;
                        newevent.pkt.id=0;  % will be updated in 'send_phy'
                        newevent.pkt.nav=0; % will be updated in lower layer
                        NewEvents = [NewEvents; newevent]; clear newevent;
                        if cdebug, disp(['node ' num2str(j) ' will send an RREP with route ' num2str(event.net.route) ' at time ' num2str(t)]); end
                    end
                    return;
                end
                % I am not the destination of this RREQ: just re-broadcast it
                % maybe one of my previous RREPs contains the route to the
                % requesting source node, but do not worry for now
                if event.pkt.ttl < 0
                    % already checked above, no use
                    % cannot go further: drop it
                else
                    if event.net.id > bcast_table(j, event.net.src)
                        % forward this RREQ only if I have not forwarded the
                        % same broadcast RREQ from the same source before
                        rreq_forward(j) = rreq_forward(j) + 1;
                        if strcmp(event.app.type, 'crosslayer_searching')
                            rreq_forward_crosslayer(j) = rreq_forward_crosslayer(j) + 1;
                        end
                        bcast_table(j, event.net.src) = event.net.id;
                        newevent = event;
                        newevent.instant = t + rand*slot_time;  % question: random delay before rebroadcasting
                        newevent.type = 'send_mac';
                        newevent.node = j;
                        newevent.pkt.tx=j;
                        newevent.pkt.rv=0;
                        NewEvents = [NewEvents; newevent]; clear newevent;
                    end
                end
            case 'rrep'
                % if cdebug, disp(['time ' num2str(t) ' node ' num2str(j) ' receives a RREP with route: ' num2str(event.net.route)]); end
                rrep_in(j) = rrep_in(j) + 1;
                if strcmp(event.app.type, 'crosslayer_searching')
                    rrep_in_crosslayer(j) = rrep_in_crosslayer(j) + 1;
                end
                if isempty(event.net.route)
                    warning(['recv_net: node ' num2str(j) ' is receiving a RREP without any route entry']);
                    return;
                end
                temp = find(event.net.route == j);
                if length(temp) > 1
                    warning(['recv_net: node ' num2str(j) ' appears more than once in a RREP']);
                    return;
                end
                if length(temp) <= 0
                    warning(['recv_net: node ' num2str(j) ' does not appear in a RREP it receives']);
                    return;
                end
                if temp == 1
                    % I am the requesting node so this RREP is what I am waiting for
                    if cdebug, disp(['time ' num2str(t) ' node ' num2str(j) ' receives a RREP with route: ' num2str(event.net.route)]); end
                    temp2 = find(net_pending(j).id == event.net.id);
                    if isempty(temp2)
                        % no RREQ waiting for this RREP; 
                        % probably this is an RREP for an earlier timeout RREQ, but I have already received an RREP for the latest RREQ.
                        if ddebug, disp(['recv_net: node ' num2str(j) ' receives an RREP without a corresponding pending RREQ']); end
                        return;
                    end
                    if length(temp2) > 1
                        error(['recv_net: node ' num2str(j) ' receives an RREP with more than one pending RREQ']);
                    end
                    % Removes the pending RREQ
                    net_pending(j).id(temp2) = [];
                    net_pending(j).retransmit(temp2) = [];
                    if strcmp(event.app.type, 'crosslayer_searching')
                        % cross-layer searching application, no data to transmit
                        % send the packet up to the application layer
                        rrep_destination_crosslayer(j) = rrep_destination_crosslayer(j) + 1;
                        newevent = event;
                        newevent.instant = t;
                        newevent.node = j;
                        newevent.type = 'recv_app';
                        NewEvents = [NewEvents; newevent]; clear newevent;
                    else    % a regular RREP at network layer received
                        % send the following data packet by this route
                        newevent = event;
                        newevent.instant = t;
                        newevent.type = 'send_mac';
                        newevent.node = j;
                        newevent.net.type = 'data';
                        newevent.net.id = new_id(j);
                        newevent.net.src = j;
                        newevent.net.dst = i;
                        % keep net.size, net.route
                        newevent.pkt.tx = j;
                        newevent.pkt.rv = newevent.net.route(2); % next hop
                        newevent.pkt.type='data';
                        newevent.pkt.size=newevent.net.size;
                        newevent.pkt.rate=default_rate;
                        newevent.pkt.ttl = length(newevent.net.route) + 1;
                        newevent.pkt.power=default_power;
                        newevent.pkt.id=0;  % will be updated in 'send_phy'
                        newevent.pkt.nav=0; % will be updated in lower layer
                        NewEvents = [NewEvents; newevent];
                        clear newevent;
                    end
                    % no ACK at network layer
                    % the net_queue is always empty, so no next network layer packet to send
                else
                    % I need to forward this RREP back to the next hop towards the source
                    rrep_forward(j) = rrep_forward(j) + 1;
                    if strcmp(event.app.type, 'crosslayer_searching')
                        rrep_forward_crosslayer(j) = rrep_forward_crosslayer(j) + 1;
                    end
                    newevent = event;
                    newevent.instant = t;
                    newevent.type = 'send_mac';
                    newevent.node = j;
                    newevent.net.type = 'rrep';
                    newevent.pkt.tx = j;
                    newevent.pkt.rv = newevent.net.route(temp - 1); % next hop
                    % if cdebug, disp(['time ' num2str(t) ' node ' num2str(j) ' will forward RREP to node ' num2str(newevent.pkt.rv)]); end
                    NewEvents = [NewEvents; newevent]; clear newevent;
                end
            case 'data'
                if event.net.dst == 0
                    % a network layer broadcast packet
                    if event.pkt.rv ~= 0
                        warning(['recv_net: node ' num2str(j) ' receives a broadcast at NET, but not at MAC']);
                    end
                    if event.net.id > bcast_table(j, event.net.src)
                        bcast_table(j, event.net.src) = event.net.id;
                        newevent = event;
                        newevent.instant = t + rand*slot_time;
                        newevent.type = 'send_mac';
                        newevent.pkt.tx = j;
                        NewEvents = [NewEvents; newevent]; clear newevent;
                    end
                    return;
                end
                % receives a unicast data packet at network layer
                if isempty(event.net.route)
                    warning(['recv_net: node ' num2str(j) ' is receiving a Net_DATA without any route entry']);
                    return;
                end
                temp = find(event.net.route == j);
                if length(temp) > 1
                    warning(['recv_net: node ' num2str(j) ' appears more than once in a route for data packet']);
                    return;
                end
                if length(temp) <= 0
                    warning(['recv_net: node ' num2str(j) ' does not appear in a data packet it receives']);
                    return;
                end
                if j == event.net.dst   % or temp == length(event.net.route)
                    % I am the destination
                    newevent = event;
                    newevent.instant = t;
                    newevent.type = 'recv_app';
                    newevent.node = j;
                    NewEvents = [NewEvents; newevent]; clear newevent;
                else
                    % I should forward this data packet to the next hop towards the destination
                    newevent = event;
                    newevent.instant = t;
                    newevent.type = 'send_mac';
                    newevent.pkt.tx = j;
                    newevent.pkt.rv = newevent.net.route(temp + 1); % next hop
                    NewEvents = [NewEvents; newevent]; clear newevent;
                end
            otherwise
                disp(['recv_net: Undefined network layer packet type: ' event.net.type]);
        end
    case 'send_app'
        t = event.instant;
        i = event.node;
        switch event.app.type
            case 'crosslayer_searching'
                if ddebug, disp(['send_app: time ' num2str(t) ' node ' num2str(i) ' sends a crosslayer searching request for key(node) ' num2str(event.app.key)]); end
                fid = fopen(log_file, 'a');
                if fid == -1, error(['Cannot open file', log_file]); end
                % Record traffic_id, topo_id, start_time, start_hop_count(=0), requesting node, requesting key
                fprintf(fid, '%d %d %g %d %d %d \n', [event.app.id1; event.app.id2; t; 0; i; event.app.key]);
                fclose(fid);
                newevent = event;
                newevent.type = 'send_net';
                newevent.net.src = i;
                newevent.net.dst = newevent.app.key;
                newevent.net.size = 100*8;
                NewEvents = [NewEvents; newevent]; clear newevent;
            case 'dht_searching'
                newevent = event;
                newevent.type = 'send_net';
                newevent.net.src = i;
                newevent.net.size = 100*8;
                if isempty(newevent.app.route)
                    % Initiate the overlay searching
                    newevent.app.route = [i];
                    tempn = floor(rand*log2(n));
                    if tempn > 0
                        for tempi = 1:tempn
                            while 1
                                tempx = ceil(rand*n);   % 1 to n
                                if isempty(find([newevent.app.route newevent.app.key]==tempx)), break; end
                            end
                            newevent.app.route = [newevent.app.route tempx];
                        end
                    end
                    newevent.app.route = [newevent.app.route newevent.app.key];
                    fid = fopen(log_file, 'a');
                    if fid == -1, error(['Cannot open file', log_file]); end
                    % Record traffic_id, topo_id, start_time, start_hop_count(=0), requesting node, requesting key,overlay route length
                    fprintf(fid, '%d %d %g %d %d %d %d \n', [newevent.app.id1; newevent.app.id2; t; 0; i; newevent.app.key; tempn + 1]);
                    fclose(fid);
                    newevent.net.dst = newevent.app.route(2);
                    if ddebug, disp(['send_app: at time ' num2str(t) ' node ' num2str(i) ' sends a DHT searching request for key(node) ' num2str(newevent.app.key) ' through overlay route: ' num2str(newevent.app.route)]); end
                else
                    disp(['send_app: at time ' num2str(t) ' node ' num2str(i) ' should not have a non-empty DHT overlay route ' num2str(event.app.route)]);
                    % forward the request to the next hop in the overlay
                    % tempi = find(newevent.app.route==i);
                    % if isempty(tempi) | length(tempi)>1 | tempi >= length(newevent.app.route)
                    %     error(['send_app: dht_searching: node ' num2str(i) ' is not supposed to send such an overlay searching request']);
                    % end
                    % newevent.net.dst = newevent.app.route(tempi+1);
                end
                NewEvents = [NewEvents; newevent]; clear newevent;
            otherwise
                disp(['send_app: Undefined application layer type: ' event.app.type]);
        end
    case 'recv_app'
        t = event.instant;
        j = event.node;
        if bdebug, disp(['recv_app @ node ' num2str(j)]); end
        switch event.app.type
            case 'crosslayer_searching'
                if ddebug, disp(['recv_app: time ' num2str(t) ' node ' num2str(j) ' receives the reply of crosslayer searching with route ' num2str(event.net.route)]); end
                fid = fopen(log_file, 'a');
                if fid == -1, error(['Cannot open file', log_file]); end
                % Record traffic_id, topo_id, end_time, hop_count, requesting node, requesting key
                fprintf(fid, '%d %d %g %d %d %d \n', [event.app.id1; event.app.id2; t; length(event.net.route)-1; j; event.app.key]);
                fclose(fid);
            case 'dht_searching'
                tempi = find(event.app.route==j);
                if isempty(tempi) | length(tempi)>1
                    if ddebug, disp(['recv_app: dht_searching: node ' num2str(j) ' receives a wrong DHT searching request with route: ' num2str(event.app.route)]); end
                    return;
                end
                if tempi == length(event.app.route)
                    % I am the destination of this overlay request: send the answer back to the requestor
                    % if ddebug, disp(['recv_app: at time ' num2str(t) ' destination node ' num2str(j) ' receives the DHT request from node ' num2str(event.app.route(1))]); end
                    newevent = event;
                    newevent.type = 'send_net';
                    % Make sure the previous ACK at MAC layer is finished
                    newevent.instant = t; % already taken care of in MAC layer. + SIFS + ack_tx_time + 2*eps;
                    newevent.app.hopcount = newevent.app.hopcount + length(newevent.net.route) - 1;
                    newevent.net.src = j;
                    newevent.net.dst = newevent.app.route(1);
                    newevent.net.size = 100*8;
                    NewEvents = [NewEvents; newevent]; clear newevent;
                elseif tempi == 1
                    % I am the requester: just received the answer from the destination
                    if ddebug, disp(['recv_app: at time ' num2str(t) ' node ' num2str(j) ' receives the DHT reply']); end
                    fid = fopen(log_file, 'a');
                    if fid == -1, error(['Cannot open file', log_file]); end
                    % Record traffic_id, topo_id, start_time, start_hop_count(=0), requesting node, requesting key, overlay route length
                    fprintf(fid, '%d %d %g %d %d %d %d \n', [event.app.id1; event.app.id2; t; event.app.hopcount; j; event.app.key; length(event.app.route)-1]);
                    fclose(fid);
                else
                    % if ddebug, disp(['recv_app: at time ' num2str(t) ' overlay node ' num2str(j) ' will forward the DHT request to next overlay node ' num2str(event.app.route(tempi + 1))]); end
                    % I should send request to the next hop in overlay
                    newevent = event;
                    newevent.type = 'send_net';
                    % Make sure the previous ACK at MAC layer is finished
                    newevent.instant = t;   % alread taken care of in MAC layer. + SIFS + ack_tx_time + 2*eps;
                    newevent.app.hopcount = event.app.hopcount + length(event.net.route) - 1;
                    newevent.net.src = j;
                    newevent.net.dst = event.app.route(tempi + 1);
                    newevent.net.size = 100*8;
                    NewEvents = [NewEvents; newevent]; clear newevent;
                end
            otherwise
                disp(['recv_app: Undefined application layer type: ' event.app.type]);
            end
        otherwise
            disp(['action: Undefined event type: ' event.type]);
        end;
        
        return;