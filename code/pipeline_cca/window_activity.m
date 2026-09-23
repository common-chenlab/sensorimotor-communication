function [Xwin, Ywin, Xshuff, Xwin_trial, Ywin_trial] = window_activity(act, params, show) % , Yshuff
if nargin < 3, show = false; end
% act should be a 1x2 cell with each cell containing simultaneous activity from 2 FOV (X and Y), each organized as # ROIs x # frames x # trials
% Convert act into two cell arrays, with each element being a window of the activity at a given timestep and, for act{2}, delay relative to act{1}
[n_frame,n_trial] = size(act{1},[2,3]);
Xwin = cell(params.n_step, 1); Ywin = cell(params.n_step, params.n_delay);
Xwin_trial = cell(params.n_step, n_trial); Ywin_trial = cell(params.n_step, params.n_delay, n_trial);
Xshuff = cell(params.n_step, params.n_shuff);
if show, figure('WindowState','maximized'); end
for tp = 1:params.n_step
    % Prepare X
    win_frames = params.win_lim(tp,1):params.win_lim(tp,2);
    Xbin = BinTime( act{1}(:,win_frames,:), params.BinWidth );
    Xwin{tp,1} = Squash( Xbin )'; % after binning, concatenate this window from all trials

    for tr = 1:n_trial
        Xwin_trial{tp,tr} = Squash( BinTime( act{1}(:,win_frames,tr), params.BinWidth ) )';
    end

    for sh = 1:params.n_shuff
        Xshuff{tp,sh} = Squash( Xbin(:,:,randperm(size(Xbin,3))) )';
    end

    % Prepare Y shifts ASB way
    if show, sp(1) = subplot(2,1,1); imagesc(Xwin{tp,1}'); title( sprintf('Time step = %i', tp) ); end
    for dl = 1:params.n_delay
        delay_frames = win_frames - params.delay_shift(dl); % shift by delay_points frames, relative to the X matrix   t1_frames
        delay_frames(delay_frames < 1 | delay_frames > n_frame) = []; % exclude frames beyond the edges of the data
        Ybin = BinTime( act{2}(:,delay_frames,:), params.BinWidth );
        pad_vec = [0, size(Xbin,2)-numel(delay_frames), 0]; % pad to make sure the lengths are equal
        if params.delay_shift(dl) < 0
            Ybin = padarray(Ybin, pad_vec, NaN, 'pre'); % n_frame
        elseif params.delay_shift(dl) > 0
            Ybin = padarray(Ybin, pad_vec, NaN, 'post');
        end
        Ywin{tp,dl} = Squash( Ybin )'; % Y(:,:,dl)
        for tr = 1:n_trial
            Ywin_trial{tp,dl,tr} = Squash( BinTime( act{2}(:,delay_frames,tr), params.BinWidth ) )';
        end
        
        if show
            sp(2) = subplot(2,1,2); imagesc(Ywin{tp,dl}'); 
            title( sprintf('Delay = %i', params.delay_shift(dl)) ); 
            linkaxes(sp,'xy'); pause; cla;
        end
    end
end
%act_win = {Xwin, Ywin};
end