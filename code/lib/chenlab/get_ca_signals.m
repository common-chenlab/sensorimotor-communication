function [fluor, act, trials, fov] = get_ca_signals(data_struct, trials, fov, pct_base) % , denoise_frameloss
fluor = struct('F',[], 'filt',[], 'F0',[], 'dFF',[], 'z',[], 'SNR',[]);
act = struct('trial',[], 'z',[], 'trial_peak',[], 'trial_peak_frame',[], 'trial_sum',[], 'trial_phase_sum',[], 'trial_frac',[], 'trial_participation',[], 'trial_mean',[]); % , 'corr',[]
if isfield(data_struct, 'F_df_REF') && isfield(data_struct, 'deconv_REF')  
    a = str2double(extractAfter(fov.fov_name,'A'))+1; % area index
    % MAKE SURE TRIALS ARE CONSISTENT WITH WHISKING AND LICKING
    dFF_temp = cell(1,trials.n_all); 
    dFF_temp(setdiff(1:trials.n_all, [fov.tr_missing, fov.tr_exclude])) = data_struct.F_df_REF;
    act_temp = cell(1,trials.n_all);
    act_temp(setdiff(1:trials.n_all, [fov.tr_missing, fov.tr_exclude])) = data_struct.deconv_REF;
    % Parameters for event frame stamping
    denoise_frameloss = 30; % frame lost before and after, from deepinterp denoising
    denoise_timeloss = 1000*denoise_frameloss/fov.framerate; % in ms
    trial_event_type = {'begin', 'present_time', 'direction_1_time', 'delay_time', 'delay_withdraw_time', 'delay_present_time', 'direction_2_time','report_time',...
        'reward_time','decision_time','withdraw_time','end_time'};
    trial_event_code = num2cell(1:length(trial_event_type)); % Automatically number each of these events
    trial_event_desc = {'Trial Start', 'Present', 'Direction 1 Start', 'Delay', 'Delay Withdraw','Delay Present', 'Direction 2 Start', 'Report', 'Reward', 'Decision', 'Withdraw', 'Trial End'}; % Readable description of each event
    trial_event_key = cell2struct([trial_event_type; trial_event_desc; trial_event_code], {'type','desc','code'}, 1);
    n_event = numel(trial_event_key);
    % Recreate notch filtering used in pipeline step7
    Wo = data_struct.notch(1)/(fov.framerate/2); % normalized frequency
    if isMATLABReleaseOlderThan("R2022b")
        [b_notch,a_notch] = iirnotch(Wo, Wo/data_struct.notch(2));
    else
        [b_notch,a_notch] = designNotchPeakIIR(CenterFrequency=Wo,QualityFactor=data_struct.notch(2),Response="notch");
    end
    % For alignment of trial events to fov frames
    get_length = @(x)(size(x,2));
    trials.length(:,a) = cellfun(get_length, dFF_temp); % data_struct.F_df_REF
    trials.length(trials.length == 0) = NaN;
    trials.length_min(a) = min(trials.length(:,a), [], 1, 'omitnan');
    fov.T_trial = (0:trials.length_min(a)-1)/fov.framerate;
    % Get trial-by-trial activity, fluor and events (pared to length of the shortest imaged trial)
    fluor.F.trial = nan(fov.n_ROI, trials.length_min(a), trials.n_all); %
    fluor.filt.trial = nan(fov.n_ROI, trials.length_min(a), trials.n_all);
    fluor.F0.trial = nan(fov.n_ROI, trials.n_all);
    fluor.dFF.trial = nan(fov.n_ROI, trials.length_min(a), trials.n_all);
    fluor.z.trial = nan(fov.n_ROI, trials.length_min(a), trials.n_all);
    act.trial = nan(fov.n_ROI, trials.length_min(a), trials.n_all);
    act.trial_phase_sum = nan(fov.n_ROI, trials.n_all);
    act.z.trial = nan(fov.n_ROI, trials.length_min(a), trials.n_all);
    act.trial_peak = nan(fov.n_ROI, trials.n_all);
    act.trial_peak_frame = nan(fov.n_ROI, trials.n_all);
    act.trial_phase_sum = nan(fov.n_ROI, trials.n_all, n_event-1);
    for tr = setdiff(1:trials.n_all, [fov.tr_missing, fov.tr_exclude]) 
        %fprintf('\ntr = %i: mov_ts = %s, movie_ts = %s', tr, trials.im(tr).time_stamp, data_struct.trial_info{tr}.time_stamp)
        fluor.F.trial(:,:,tr) = dFF_temp{tr}(:,1:trials.length_min(a));
        temp_filt = filtfilt(b_notch, a_notch, dFF_temp{tr}')'; % apply notch filtering.  filtfilt operates along the first dimension
        fluor.filt.trial(:,:,tr) = temp_filt(:,1:trials.length_min(a)); %data_struct.F_df_REF{tr}(:,1:trials.length_min(a));
        fluor.F0.trial(:,tr) = prctile(fluor.filt.trial(:,:,tr), pct_base, 2);
        fluor.dFF.trial(:,:,tr) = (fluor.filt.trial(:,:,tr) - fluor.F0.trial(:,tr))./fluor.F0.trial(:,tr);
        %{
        for roi = 1:fov.n_ROI
            clf;
            plot(fluor.filt.trial(roi,:,tr));
            yyaxis right
            %fo =  min(fluor.filt.trial(roi,:,tr));
            plot( fluor.dFF.trial(roi,:,tr) );  %  (fluor.filt.trial(roi,:,tr) - fo)./fo
            pause;
        end
        %}
        act.trial(:,:,tr) = act_temp{tr}(:,1:trials.length_min(a)); % data_struct.deconv_REF data_struct.deconv_REF{tr}(:,1:trials.length_min(a));
        [trial_max, trial_max_frame] = max(act.trial(:,:,tr),[],2);
        act.trial_peak(:,tr) = trial_max;
        act.trial_peak_frame(:,tr) = trial_max_frame;
        % Get trial event timing in FOV frames
        trials.all(tr).imaging_offset(a) = trials.all(tr).recording_time - (1000*fov.T_trial(end) + 2*denoise_timeloss); % difference between start of imaging and start of trial
        trials.all(tr).timevec{a} = 1000*fov.T_trial + denoise_timeloss; % NOTE: DOES NOT ACCOUNT FOR OFFSET + trials.glm(tr).imaging_offset;
        trials.all(tr).events{a} = get_trial_event_frames(trials.all(tr).timevec{a}, trials.all(tr), trial_event_key, trials.all(tr).imaging_offset(a), denoise_timeloss, false); %
        % Sum activity within each phase (time between each 2 trial events)
        for ev = 1:n_event-1
            try
                act.trial_phase_sum(:,tr,ev) = sum(act.trial(:,trials.all(tr).events{a}(ev).first_frame:trials.all(tr).events{a}(ev+1).first_frame,tr), 2, 'omitnan');
            catch
            end
        end
        
        % Calculate SNR (Fmax - F0)/std(Fpre)
        fluor.SNR(:,tr) = (max(fluor.filt.trial(:,:,tr),[],2,'omitnan')-fluor.F0.trial(:,tr))./std(fluor.filt.trial(:,1:trials.all(tr).events{a}(2).first_frame,tr), 0, 2, 'omitnan');
    end
    act.trial_frac = squeeze(sum(act.trial, 2, 'omitnan'))/trials.length_min(a); % a
    act.trial_sum = squeeze(sum(act.trial,2, 'omitnan')); %any
    act.trial_participation = sum(act.trial_sum > 0, 1)/fov.n_ROI; % fraction of cells active whatsoever during each trial
    
    % Calculate z-score on ROI-pooled dFF and activity, after excluding missing data
    dFF_cat = reshape(fluor.dFF.trial, fov.n_ROI, []);
    fluor.z.trial = normalize(dFF_cat, 2, 'zscore'); %zscore(dFF_cat, 0, 2); % zscore function can't handle NaNs
    fluor.z.trial = reshape(fluor.z.trial, fov.n_ROI, trials.length_min(a), trials.n_all);
    act_cat = reshape(act.trial, fov.n_ROI, []);
    act.z.trial = normalize(act_cat, 2, 'zscore'); % zscore(act_cat, 0, 2);
    act.z.trial = reshape(act.z.trial, fov.n_ROI, trials.length_min(a), trials.n_all);

    % Average signals over trials
    fluor.F.trial_mean = mean(fluor.F.trial, 3, 'omitnan');
    fluor.filt.trial_mean = mean(fluor.filt.trial, 3, 'omitnan');
    fluor.dFF.trial_mean = mean(fluor.dFF.trial, 3, 'omitnan');
    fluor.z.trial_mean = mean(fluor.z.trial, 3, 'omitnan');
    act.trial_mean = mean(act.trial, 3, 'omitnan');
    act.z.trial_mean = mean(act.z.trial, 3, 'omitnan');
    
    % average trial-averages and ROIs
    fluor.F.fov_mean = mean(fluor.F.trial_mean',2);
    fluor.filt.fov_mean = mean(fluor.filt.trial_mean',2);
    fluor.dFF.fov_mean = mean(fluor.dFF.trial_mean',2);
    act.fov_mean = mean(act.trial_mean',2); %#ok<*UDIM>
    act.z.fov_mean = mean(act.z.trial_mean', 2);

    % Calculate correlations
    %act.corr = corrcoef(act_cat');
else
    warning('Missing F_df_REF or deconv_REF field')
end