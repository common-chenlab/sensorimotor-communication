function Ca = deconvolve_traces(Ca, params)
% FOR USE WITH CHEN_2P_Pipeline_Step_07_SLM
Ca.deconv_params = params; % save deconvolution parameters to the results structure
% Use curated ROIs (ref_ROI) or original CNMF ROIs?
if strcmpi(params.ROI_type, 'REF')
    if strcmpi(params.signal_type, 'denoised')
        F_dF = Ca.F_df_REF;
    else
        F_dF = Ca.F_df_raw;
    end
    ROI = Ca.ROIs_REF;
else
    F_dF = Ca.F_dF;
    ROI = Ca.ROIs;
end
n_ROI = numel(ROI);
n_trial = numel(Ca.F_df_REF); % Ca.F_dF
framerate = Ca.sampling_rate; % makes parfor work better to pull this variable out of Ca

% Concatenate subtrial movies - use this for cases where a long, continuous trial is divided across multiple movies, as in SLM experiments
if params.concatenate
    if isfield(Ca, 'trial_table')
        % SLM 
        tr_unq = unique(Ca.trial_table.Trial_ind)';
        n_trial = numel(tr_unq);
        F_dF_cat = cell(1, n_trial);
        for tr = tr_unq
            F_dF_cat{tr} = cat(2, F_dF{Ca.trial_table.Trial_ind == tr});
        end
        F_dF = F_dF_cat;
        clearvars F_dF_cat
    else
        % marmoset
        F_dF = {cat(2, F_dF{:})};

        n_trial = 1;
    end
end

% account for nans in first last frames when using denoised data
if strcmpi(params.signal_type, 'denoised')
    F_dF{1} = F_dF{1}(:,2:end);
    F_dF{end} = F_dF{end}(:,1:end-1);
end

%{
% Identify bad trials (containing NaNs)
tr_bad = find(cellfun(@sum, cellfun(@isnan, F_dF, 'UniformOutput', false), repmat({'all'},n_trial,1)));
tr_good = setdiff(1:n_trial, tr_bad);
Ca.bad_trials_deconv = tr_bad;
%}

% Notch filter fluor signals to suppress laser crosstalk artifact - multi-area2 only
Ca.notch = [params.notch_freq, params.notch_Q]; % [freq, Q factor]
if ~any(isnan(Ca.notch))
    % Design a notch filter
    fprintf('\nApplying notch filter: %1.3f Hz, Q = %2.1f', params.notch_freq, params.notch_Q)
    Wo = params.notch_freq/(framerate/2); % normalized frequency
    [b,a] = iirnotch(Wo, Wo/params.notch_Q);
    
    % Apply the filter to each trace
    F_filt = cell(size(F_dF)); %
    for tr = tr_good
        F_filt{tr} = filtfilt(b, a, F_dF{tr}')'; 
    end
    
    % Compare original and filtered signals
    %{
    % Individual traces
    figure;
    for roi = 127 %1:n_ROI
        for tr = tr_good
            plot([F_dF{tr}(roi,:); F_filt{tr}(roi,:);]'); % ;
            pause;
        end
    end
    %}
else
    F_filt = F_dF;
end

% find and exclude too-short trials
params.min_frame = round(framerate*params.min_dur);
trial_lengths = cellfun(@size, Ca.F_df_REF, repmat({2}, size(Ca.F_df_REF)), 'UniformOutput',true); % # of frames in the deconvolved movies
tr_bad = find(trial_lengths < params.min_frame);
if tr_bad, fprintf('Excluding %i trials', numel(tr_bad)); end

% process traces and deconvolve
params.base_frames = round(framerate*params.base_window); % how many frames to use for mov mean in subtract_baseline?
% number of trials pooled (current +/- base_half neighbours) to estimate the
% per-trial baseline & noise, avoiding the trial-specific "iceberg" artifact.
% base_ntrials=1 -> base_half=0 -> legacy per-trial behaviour.
if isfield(params,'base_ntrials') && ~isempty(params.base_ntrials)
    base_half = floor(params.base_ntrials/2);
else
    base_half = 1; % default: current + previous + next
end
deconv = cell(1,n_trial);   trial_noise = nan(n_ROI, n_trial);  % sp_norm_trial = cell(1,n_trial);
fprintf('\nPerforming deconvolutions...\n')

if n_trial > 1, w = waitbar(0, 'Deconvolving trials'); end
tic
for tr = setdiff(1:n_trial, tr_bad) %find(trial_lengths > params.min_frame)' %1:n_trial %tr_good% go through each trial
    %nan_ind = find(isnan(F_filt{tr}));
    nan_frame = find(any(isnan(F_filt{tr}),1));
    %fprintf('\ntrial %i of %i', tr, n_trial ) %disp(['trial ', num2str(tr)])
    trial_traces = num2cell(F_filt{tr}, 2); % split trial's ROI traces into cells
    % pool the current trial with its neighbours (skipping bad trials) to give
    % subtract_baseline a context for estimating baseline & noise per ROI
    nb = tr-base_half : tr+base_half;
    nb = nb(nb>=1 & nb<=n_trial);
    nb = nb(~ismember(nb, tr_bad));
    if ~ismember(tr, nb), nb = sort([nb, tr]); end
    context_traces = num2cell(cat(2, F_filt{nb}), 2); % per-ROI concatenated context traces
    [trial_proc_traces, noise_std] = cellfun(@subtract_baseline, trial_traces, repmat({params}, size(trial_traces)), context_traces, 'UniformOutput',false);
    %subtract_baseline(trial_traces{29}, params, true); % visualize the subtraction here
    trial_noise(:,tr) = cat(1,noise_std{:}); % std dev of baseline-subtracted FLUOR signal?
    
    % Perform deconvolutions in parallel over ROIs
    sp_thresh = cell(size(trial_traces)); %sp_norm = cell(size(trial_traces)); % c_oasis = cell(size(trial_traces));
    trial_length = trial_lengths(tr); % for parallelization
    parfor roi = 1:n_ROI    % go through each neuron  par
        try
            [c_oasis, sp_oasis] = deconvolveCaE(trial_proc_traces{roi}, 'exp2', [params.tau_r, params.tau_d], ...
                'thresholded', 'smin',params.thresh_min, 'sampling_rate',framerate, 'optimize_b', 'window', params.min_frame); 
            sp_oasis([1:2,end-1:end]) = 0; % first and last bins contain bad estimations
            % normalize result by variance and threshold
            sp_norm = (sp_oasis./noise_std{roi}); % {roi}
            sp_thresh{roi} = sp_norm; %(sp_oasis./noise_std{roi}); %sp_norm{roi};
            sp_thresh{roi}(sp_thresh{roi} < params.spike_thresh) = 0;
            sp_thresh{roi} = sp_thresh{roi}/params.spike_thresh;
            if strcmpi(params.microscope, 'multi2')
                sp_thresh{roi} = check_convolution(sp_thresh{roi}, c_oasis);
            end
            %{
            % Illustrate the deconvolution and post-processing of s_oasis
            t_trace = [0:length(trial_proc_traces{roi})-1]/framerate;
            figure('WindowState','maximized', 'color','w');
            sp(1) = subplot(4,1,1); plot(t_trace, trial_proc_traces{roi}); title('Baseline-subtraced fluorescence')% hold on;
            set(gca,'XtickLabel',[])
            sp(2) = subplot(4,1,2); plot(t_trace, sp_oasis); title('Deconvolved'); %title('sp oasis')
            set(gca,'XtickLabel',[])
            sp(3) = subplot(4,1,3); plot(t_trace, sp_norm); hold on; % {roi}
            line( t_trace([1,end]), params.spike_thresh*[1,1], 'color','r', 'linestyle','--')
            set(gca,'XtickLabel',[])
            title('Normalized by fluor std dev'); % sp norm
            sp(4) = subplot(4,1,4); plot(t_trace, sp_thresh{roi}); 
            title('Thresholded and normalized by threshold');
            xlabel('Time (s)')
            linkaxes(sp,'x')
            xlim([-Inf,Inf]) %  [0,180]
            %}
        catch
            %fprintf('\nROI %i failed', roi)
            sp_thresh{roi} = nan(trial_length, 1); % 
        end
    end
    deconv{tr} = cat(2, sp_thresh{:})';
    %sp_norm_trial{tr} = cat(2, sp_norm{:})'; % probably don't need this
    %toc
    if exist('w', 'var'), waitbar(tr/n_trial, w, 'Deconvolving trials'); end
end
toc
if exist('w', 'var'), close(w); end

% Show the results of the deconvolution
%{
[~,sort_roi] = sort(median(trial_noise, 2), 'ascend');
figure('WindowState','maximized')
for tr = 1
    trial_traces = num2cell( F_filt{tr}, 2);
    trial_proc_traces = cellfun(@subtract_baseline, trial_traces, repmat({params}, size(trial_traces)), 'UniformOutput',false);
    for roi = sort_roi' %1:n_ROI
        clf
        sp(1) = subplot(3,1,1);
        plot(F_dF{tr}(roi,:)); hold on;
        if ~any(isnan(Ca.notch))
            plot(trial_traces{roi}); %hold on;
            plot(trial_proc_traces{roi})
            legend('Raw','Notch','Subtracted')
        else
            plot(trial_proc_traces{roi})
            legend('Raw','Subtracted')
        end
        ylabel('Fluor')
        title(sprintf('Trial %i, ROI %i', tr, roi))
        
        sp(2)= subplot(3,1,2);
        plot(sp_norm_trial{tr}(roi,:)); 
        hold on;
        line([1,size(F_dF{tr},2)], params.spike_thresh*[1,1], 'linestyle','--', 'color','r')
        ylabel('Deconvolved')
        title('Normalized')

        sp(3)= subplot(3,1,3);
        plot(deconv{tr}(roi,:)); hold on;
        title('Thresholded')
        ylabel('Deconvolved')
        xlabel('Frames')
        
        %legend('Thresholded','Normalized')
        linkaxes(sp,'x')
        axis tight;
        pause
    end
end
%}

if strcmpi(params.signal_type, 'denoised')
    deconv{1} = [nan(n_ROI,1), deconv{1}];
    deconv{end} = [deconv{1}, nan(n_ROI,1)];
end

% de-concatenate the results back to movie-level
if params.concatenate
    if isfield(Ca, 'trial_table')
        n_movie = height(Ca.trial_table); % length(Ca.trial_info); %
        n_frame_cum = [0,cumsum(Ca.trial_table.n_frame)'];
    else
        n_movie = length(Ca.trial_info); %
        n_frame_cum = [0,cumsum(cellfun(@width, Ca.F_dF))'];
    end

    deconv_cat = cat(2, deconv{:}); % first, concatenate all movies
    deconv = cell(1, n_movie);
    for ii = 1:n_movie
        deconv{ii} = deconv_cat(:,n_frame_cum(ii)+1:n_frame_cum(ii+1));
    end
end

% Save the results back to the main structure
Ca.deconv_params = params;
Ca.trial_noise = trial_noise;
%Ca.s_oasis = sp_norm_trial; % probably don't need this
if strcmpi(params.ROI_type, 'REF')
    if strcmpi(params.signal_type, 'denoised')
        Ca.deconv_REF = deconv;
    else
        Ca.deconv_raw = deconv;
    end
else
    Ca.deconv = deconv;
end
end