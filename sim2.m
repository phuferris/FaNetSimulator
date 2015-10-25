% Simulation for mobility

clear;
% Initialize random number generator
rand('state', 0);
randn('state', 0);

global n node;
global rreq_out rreq_in rreq_forward;
global rreq_out_crosslayer rreq_in_crosslayer rreq_forward_crosslayer;
global rrep_out rrep_in rrep_forward;
global rrep_out_crosslayer rrep_in_crosslayer rrep_forward_crosslayer rrep_destination_crosslayer;
global mobility_model pos maxspeed maxpause;
global maxx maxy;

% Parameters
apptype = 'crosslayer_searching';    % or 'dht_searching'
log_file = 'log_mobility_crosslayer_';
n = 10;
maxx = 100;
maxy = 100;
nmobility = 2;
nrepeat = 2;
interval = 10;  % second
itraffic = 5;
max_time = 100 + interval * (nrepeat + 1);

for imobility = 1:nmobility
    % Use the same initial topology
    rand('state', 1);
    randn('state', 1);
    % Generate a random network topology
    node = topo(n, maxx, maxy, 0);
    node = [node, zeros(n, 2)];
    % Reset the parameters
    parameter;
    % Set parameters for mobility
    mobility_model = 'random_waypoint';
    maxpause = 1;
    maxspeed = imobility;
    disp([' ===== Maximum speed = ' num2str(maxspeed) ' =====']);
    % Initialize and start mobility
    position_init;
    clear Event_list;
    for k=1:itraffic
        clear tempe;
        tempe.instant = 1 + 100*k*slot_time;
        tempe.type = 'send_app';
        tempe.node = k;
        tempe.app.type = apptype;
        tempe.app.key = n+1-k;
        tempe.app.id1 = k;
        tempe.app.id2 = 0;
        tempe.app.route = [];
        tempe.app.hopcount = 0;
        tempe.net = [];
        tempe.pkt = [];
        for h = 1:nrepeat
            tempe.instant = tempe.instant + interval;
            tempe.app.id2 = h;
            Event_list((k-1)*nrepeat+h) = tempe;
        end
    end
    % Run the simulation
    tstart = clock;
    run(Event_list', max_time, [log_file, num2str(maxspeed)]);
    disp(sprintf('--- Maximum speed= %d, Running time=%g \n', maxspeed, etime(clock, tstart)));
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
    fid = fopen([log_file num2str(maxspeed) '_rreqrrep'], 'a');
    if fid == -1, error(['Cannot open log file for RREQ and RREP']); end
    fprintf(fid, '%d %d %d %d %d %d %d %d %d %d %d %d %d %d \n', [maxspeed; n1; n2; n3; n4; n5; n6; n7; n8; n9; n10; n11; n12; n13]);
    fclose(fid);
end
