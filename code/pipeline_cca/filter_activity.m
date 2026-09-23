function act_out = filter_activity(act, CCA_params, show) % , fov
% prepare_CCA_data applies a Gaussian filter to activity data
% act = raw activity data for each ROI. dimensions should be frames x ROI x trials
% CCA_params = structure setting all parameters for analysis. here only gauss_filt, n_PC and PCA_params are relevant
% OUTPUTS
% act_out = filtered version of activity
if nargin < 3, show = false; end

if ~isempty(CCA_params.gauss_filt) %~isnan(CCA_params.filt_sigma)
    n_trial = size(act{1},3);
    n_fov = numel(act);
    find_missing_trial = @(x)(any(isnan(x),'all'));
    act_filt = cell(n_fov, n_trial); % intermediate version to handle missing trials
    act_out = cell(1,n_fov); % final output version
    for a = flip(1:n_fov)
        % Gather the activity data for each trial into its own cell and filter it
        act_filt(a,:) = mat2cell(act{a}, size(act{a},1), size(act{a},2), ones(n_trial,1) ); % act(a).trial_resamp
        
        % Apply Gaussian filter 
        for tr = find(~any(cellfun(find_missing_trial, act_filt(a,:)), 1)) % 1:n_trial
            act_filt{a,tr} = filtfilt(CCA_params.gauss_filt, 1, act_filt{a,tr});
        end

        % illustrate the results (optional)
        if show
            roi_show = 1;
            tr_show = 1;
            T_show = CCA_params.frame_dur*((1:size(act{a},1))-1);
            figure; %filt_example_fig =
            h(1) = plot(T_show, act{a}(:,roi_show,tr_show)); hold on;
            h(2) = plot(T_show, act_filt{a,tr_show}(:,roi_show), 'linewidth',2);
            legend(h, 'Original','Filtered', 'location','best')
            xlabel('Trial time (s)'); ylabel('Deconvolved activity');
            title(sprintf('Guassian filtering: %s = %2.2f s', '\sigma', CCA_params.filt_sigma))
            axis tight; box off;
            %fig_path = ChenLabFilepath('Z:\Dropbox\Chen Lab Dropbox\Chen Lab Team Folder\Projects\Sensorimotor\Figures\filt_example.png');
            %fprintf('\nExporting %s', fig_path)
            %exportgraphics(filt_example_fig, fig_path); % , 'append',true
        end
        %}

        % Restore the data to arrays
        act_out{a} = cat(3, act_filt{a,:});
    end
else
    fprintf('CCA_params.gauss_filt is empty. Skipping filter_activity!')
    act_out = act;
end
end