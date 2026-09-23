function [fov, act, trials] = resample_activity(fov, act, trials, varargin)
% Resample all fovs' activity to a common frequency
IP = inputParser;
addRequired( IP, 'fov', @isstruct ) % iscell
addRequired( IP, 'act', @isstruct )
addRequired( IP, 'trials', @isstruct )
addParameter( IP, 'rate', 30, @isnumeric )
addParameter( IP, 'show', true, @islogical ) % whether or not to make the plot
addParameter( IP, 'save', '', @ischar ) % directory to save the plot to
parse( IP, fov, act, trials, varargin{:} );
f_common = IP.Results.rate;
show = IP.Results.show;
save_dir = IP.Results.save;

% Set up resampling
resamp_denom = 10000;
resamp_num = round(resamp_denom*f_common./[fov.framerate]); %[31, 31, 32, 32]; % 2*
%f_resamp = [resamp_num/resamp_denom].*[fov.framerate];

% Apply resampling to each FOV
n_fov = numel(fov); %n_trial = size(act(1).trial,3);
act_resamp = cell(1,n_fov); %act_temp = cell(1,n_fov);
for a = find(~isnan([fov.framerate])) %1:n_fov
    act_resamp{a} = permute(resample(permute(act(a).trial, [2,1,3]), resamp_num(a), resamp_denom), [2,1,3]); % resample works along the first dimension
    act_resamp{a}(act_resamp{a} < 0) = 0; % deconvolved activity shouldn't be negative, but filtering can add neg values
    fov(a).f_resamp = f_common;
    fov(a).T_resamp = (0:size(act_resamp{a},2)-1)'/f_common;
    %n_frame = size(fov(a).T_trial, 2);
    % convert event onset timings to resampled frames
    for tr = 1:trials.n_all
        if ~isempty(trials.all(tr).events) 
            for ev = 1:numel(trials.all(tr).events{a})
                if ~isnan(trials.all(tr).events{a}(ev).first_frame)
                    temp_event_time = fov(a).T_trial(trials.all(tr).events{a}(ev).first_frame); % event timings in original frames
                    [~,  min_diff_ind] = min(abs(fov(a).T_resamp-temp_event_time)); 
                    trials.all(tr).events{a}(ev).resamp_frame = min_diff_ind; % event timings in resampled frames
                else
                    trials.all(tr).events{a}(ev).resamp_frame = NaN;
                end
            end
        end
    end
end

% Make a figure showing how resampling affects the activity traces (optional)
if show
    FS = 14; TL = 0.002;
    clearvars sp; close all;
    Resamp_examp_fig = figure('WindowState','maximized','Color','w');
    tiledlayout(4,1)
    for tr = 1 %randsample(size(act(a).trial,3), 10)'
        for a = 1:n_fov
            [~,roi_max] = max(act(a).trial_sum(:,tr));
            sp(a) = nexttile;
            plot((0:length(act(a).trial(roi_max,:,tr))-1)'/fov(a).framerate, act(a).trial(roi_max,:,tr)); hold on
            plot(fov(a).T_resamp, act_resamp{a}(roi_max,:,tr));
            title(sprintf('%s, ROI %i', fov(a).name, roi_max));
            ylabel('Activity');
            set(gca,'Fontsize',FS, 'TickDir','out', 'TickLength',[TL,0])
            if a == 1, legend('Deconv', sprintf('Resampled (%2.1f Hz)',f_common), 'AutoUpdate','off', 'Location','NorthWest'); end
        end
        linkaxes(sp,'x')
        xlim([-Inf,Inf])
        xlabel('Time (s)');
        sgtitle(sprintf('Trial %i', tr), 'FontSize',FS);
        %pause; %clf;
    end
    % Save the figure (optional)
    if ~isempty(save_dir)
        save_path = fullfile(save_dir, sprintf('Resamp_examp_%dHz.pdf',f_common));
        fprintf('\nSave %s', save_path);
        exportgraphics(Resamp_examp_fig, save_path)
    end
end

% Cut the trials down to equalize frame # between fovs, then concatenate
min_frames = min(cellfun(@numel, {fov.T_resamp}));
for a = 1:n_fov
    fov(a).T_resamp = fov(a).T_resamp(1:min_frames);
    act(a).trial_resamp = act_resamp{a}(:,1:min_frames,:);
end
end