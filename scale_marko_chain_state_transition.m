function [state, time] = scale_marko_chain_state_transition(trans)
    global active_sleep_periods;
    [time,state] = hmmgenerate(1,trans,active_sleep_periods);
    