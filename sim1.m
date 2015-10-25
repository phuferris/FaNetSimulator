% Simulation for different network size

clear;
% Initialize random number generator
rand('state', 0);
randn('state', 0);

global n node;
global rreq_out rreq_in rreq_forward;
global rreq_out_crosslayer rreq_in_crosslayer rreq_forward_crosslayer;
global rrep_out rrep_in rrep_forward;
global rrep_out_crosslayer rrep_in_crosslayer rrep_forward_crosslayer rrep_destination_crosslayer;

% Parameters
apptype = 'crosslayer_searching';    % or 'dht_searching'
log_file = 'log_crosslayer_';
max_time = 100;
ntopo = 2;
nsize = 2;
itraffic = 5;

for isize = 10:15:(10*nsize)
    n = isize;
    maxx = sqrt(100*100*n/30);
    maxy = maxx;
    disp([' ===== Network size = ' num2str(n) '  maxx = maxy = ' num2str(maxx) ' =====']);
    for itopo = 1:ntopo
        % Reset the parameters
        parameter;
        rand('state', itopo);
        randn('state', itopo);
        % Generate a random network topology
        node = topo(n, maxx, maxy, 1);
        node = [node, zeros(n, 2)];
        Event_list = [];
        for k=1:itraffic
            Event_list(k).instant = 1+100*k*slot_time;
            Event_list(k).type = 'send_app';
            Event_list(k).node = k;
            Event_list(k).app.type = apptype;
            Event_list(k).app.key = n+1-k;
            Event_list(k).app.id1 = k;
            Event_list(k).app.id2 = itopo;
            Event_list(k).app.route = [];
            Event_list(k).app.hopcount = 0;
            Event_list(k).net = [];
            Event_list(k).pkt = [];
        end
        % Run the simulation
        tstart = clock;
        run(Event_list', max_time, [log_file, num2str(n)]);
        disp(sprintf('--- Network size= %d, Topology id=%d, Running time=%g \n', n, itopo, etime(clock, tstart)));
        % Log the numbers of RREQ and RREP
        n1=sum(rreq_out);
        n2=sum(rreq_in);
        n3=sum(rreq_forward);
        n4=sum(rreq_out_crosslayer);
        n5=sum(rreq_in_crosslayer);
        n6=sum(rreq_forward_crosslayer);
        n7=sum(rrep_out);
        n8=sum(rrep_in);
        n9=sum(rrep_forward);
        n10=sum(rrep_out_crosslayer);
        n11=sum(rrep_in_crosslayer);
        n12=sum(rrep_forward_crosslayer);
        n13=sum(rrep_destination_crosslayer);
        fid = fopen([log_file num2str(n) '_rreqrrep'], 'a');
        if fid == -1, error(['Cannot open log file for RREQ and RREP']); end
        fprintf(fid, '%d %d %d %d %d %d %d %d %d %d %d %d %d %d \n', [itopo; n1; n2; n3; n4; n5; n6; n7; n8; n9; n10; n11; n12; n13]);
        fclose(fid);
    end
end
