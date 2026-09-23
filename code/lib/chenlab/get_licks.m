function [licks,n_trial_licks] = get_licks(data_struct)
licks = [];
n_trial_licks = NaN;
if isfield(data_struct, 'licks')
    licks = data_struct.licks;
    n_trial_licks = numel(licks);
    get_lick_frac = @(x)(mean(x(1,:),2));
    for tr = flip(1:n_trial_licks)
        licks(tr).frac = get_lick_frac(licks(tr).lick_vector);
        licks(tr).time = datetime(licks(tr).time_stamp, "Format","HH:mm:ss");
    end
else
    warning('Licks data is missing!');
end
end