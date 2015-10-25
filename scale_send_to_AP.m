function scale_send_to_AP(issid)
    global APs_list;
    APs_list(issid).arrived_events = APs_list(issid).arrived_events + 1;
    return;
end
