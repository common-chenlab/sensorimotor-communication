function params = setup_windows(n_frame, params) % , align_frame]

% window steps
if isfinite(params.WindowLength) && params.TimeStep > 0
    win_frame = MakeChunkLims(1, n_frame, n_frame, 'partial',0.5, 'size',params.TimeStep); % 0.5
    params.win_lim(:,2) = win_frame(:,1) + params.WindowLength - 1;
    params.win_lim(:,1) = win_frame(:,1);
    params.win_lim(params.win_lim > n_frame) = n_frame; params.win_lim(params.win_lim<1) = 1;
    params.win_lim( diff(params.win_lim, 1, 2) ~= params.WindowLength - 1,:) = []; % remove incomplete windows
elseif ~isfinite(params.WindowLength)
    params.win_lim = [1,n_frame];
end
params.n_step = size(params.win_lim,1);

if isfield(params, 't_align') && ~isempty(params.t_align)
    align_frame = find(params.t_align == 0); % frame, not step, that data was aligned to (event onset)
else
    align_frame = 1;
end
params.t_step = mean(params.frame_dur*(params.win_lim - align_frame), 2); 

% delays
if params.DelayStep > 0
    params.delay_shift = -params.MaxDelay:params.DelayStep:params.MaxDelay;
    params.t_delay = params.delay_shift*-params.frame_dur; % seconds, :+ delay means src leads tgt, - delay  means tgt leads source
    params.n_delay = numel(params.delay_shift);
    params.dl_zero = find(params.t_delay == 0);
else
    params.delay_shift = 0;
    params.t_delay = 0; % seconds, :+ delay means src leads tgt, - delay  means tgt leads source
    params.n_delay = 1;
    params.dl_zero = 1; % the index dl corresponding to zero delay
end

end