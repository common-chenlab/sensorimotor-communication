function [data_out, PCA, act_filt, trial_frames] = prepare_CCA_data(act, CCA_params) % , fov
% prepare_CCA_data applies a Gaussian filter to activity data, and then performs PCA if desired
% act = raw activity data for each ROI. dimensions should be frames x ROI x trials
% CCA_params = structure setting all parameters for analysis. here only gauss_filt, n_PC and PCA_params are relevant

% OUTPUTS
% data_out = final, processed version of activity data. may be PCs or cell-level activity
% PCA = strucutre array containing PCA results for each area
% act_filt = filtered version of activity
% trial_frames = frames associated with each trial, to deconcatenate PCA results

n_trial = size(act{1},3);  
%n_ROI = cellfun(@width, act);

% which frames belong to which trials, for deconcatenation. trial frames are the same for all areas due to resampling
n_frame_trial = cellfun(@height, act);
trial_frames = cell(1, n_trial);
for tr = 1:n_trial
    trial_frames{1,tr} = n_frame_trial(1)*(tr-1)+1:n_frame_trial(1)*tr; 
end

n_fov = numel(act);
find_missing_trial = @(x)(any(isnan(x),'all'));
act_filt = cell(n_fov, n_trial); 
act_proc = cell(n_fov, n_trial); data_out = cell(1,n_fov); % PCA = cell(1,n_fov); 
for a = flip(1:n_fov)
    % Gather the activity data for each trial into its own cell and filter it
    act_filt(a,:) = mat2cell(act{a}, size(act{a},1), size(act{a},2), ones(n_trial,1) ); % act(a).trial_resamp
    % Apply Gaussian filter (optional)
    if ~isempty(CCA_params.gauss_filt) %~isnan(CCA_params.filt_sigma)
        for tr = find(~any(cellfun(find_missing_trial, act_filt(a,:)), 1)) % 1:n_trial
            act_filt{a,tr} = filtfilt(CCA_params.gauss_filt, 1, act_filt{a,tr});
        end
    end

    %{
    roi_show = 1;
    tr_show = 5;
    T_show = CCA_params.frame_dur*((1:size(act{a},1))-1);
    filt_example_fig = figure;
    h(1) = plot(T_show, act{a}(:,roi_show,tr_show)); hold on;
    h(2) = plot(T_show, act_filt{a,tr_show}(:,roi_show), 'linewidth',2);
    legend(h, 'Original','Filtered', 'location','best')
    xlabel('Trial time (s)'); ylabel('Deconvolved activity');
    title(sprintf('Guassian filtering: %s = %2.2f s', '\sigma', CCA_params.filt_sigma))
    axis tight; box off;
    fig_path = ChenLabFilepath([smout('figures') 'filt_example.png']);
    fprintf('\nExporting %s', fig_path)
    exportgraphics(filt_example_fig, fig_path); % , 'append',true
    %}

    % Perform PCA?
    if CCA_params.n_PC > 0
        % Perform PCA on the concatenated data
        PCA(a) = run_PCA_SM(vertcat(act_filt{a,:}), CCA_params.PCA_params, 'show',false); %#ok<AGROW> %  'name',fov_name{a} , 'save','' 
        %, 'save',ChenLabFilepath('Z:\Dropbox\Chen Lab Dropbox\Chen Lab Team Folder\Projects\Sensorimotor\Figures\PCA_SM_std.pdf')
        % De-concatenate the PCA data to preserve trial-specificity
        for tr = 1:n_trial
            act_proc{a,tr} = PCA(a).result.score(trial_frames{1,tr}, :); % 1:PCA(a).param.dim_max PCA(a).param.dim_recon
        end
    else
        act_proc(a,:) = act_filt(a,:);
    end

    % Restore the data to arrays
    data_out{a} = cat(3, act_proc{a,:});
end
end