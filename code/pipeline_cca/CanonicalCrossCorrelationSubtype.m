function results = CanonicalCrossCorrelationSubtype(act, params, results)
% Parameters should be set using set_CCA_params prior to calling this function
if nargin < 3, results = struct(); end
WB = findall(0,'type','figure','tag','TMWWaitbar'); delete(WB); % close all previous waitbars
% Make sure the data is analyzable
if (var(act{1}(:)) == 0 || var(act{2}(:)) == 0), fprintf('Acivity must be non-constant - returning'); return; end

% Figure out size/indexing/timing of windows and delays
[~,n_frame,n_trial] = size(act{1}); %
params = setup_windows(n_frame, params);
% Determine maximum possible # of correlated dimension pairs
n_ROI = cellfun(@height, act);
n_ROI_min = min(n_ROI);
if ~isfield(params, 'n_pair') || isempty(params.n_pair) || isnan(params.n_pair)
    params.n_pair = n_ROI_min;
else
    params.n_pair = min(n_ROI_min, params.n_pair);
end
if params.dim_max > params.n_pair, params.dim_max = params.n_pair; end

% Break out activity by trial decision labels
sub_name = params.sub_name; %["All",params.decis_name]; %
n_sub = numel(sub_name); %n_decis+1;
n_decis = n_sub-1; %numel(params.decis_name);
act_sub = cell(n_sub,2);
act_sub(1,:) = act; % first row should always be for analysis conducted on the entire data set
if n_decis > 0 && ~isempty(params.decis_labels) % remove excluded trials prior to calling this function!
    % Figure out whether to balance and which trials to include
    tr_decis = cell(1,n_decis);
    for s = 1:n_decis
        tr_decis{s} = find(params.decis_labels == s)'; %setdiff(find(decis_labels == s)', tr_exclude{ev}); % get the indices of the (good) trials associated with each subtype
        % limit the selection to a subset if params.decis_include is set (for testing purposes only)
        if params.decis_include > 0
            fprintf('\nLimiting to %i trials each', params.decis_include)
            tr_decis{s} = sort(tr_decis{s}(randsample(numel(tr_decis{s}), params.decis_include)));
        end
    end
    n_trial_decis = cellfun(@numel,tr_decis); % how many trials of each decision type?
    n_trial_sub = [n_trial, n_trial_decis];
    params.tr_bal = cell(size(tr_decis));
    if ~strcmpi(params.decis_balance,'off') || (isnumeric(params.decis_balance) && params.decis_balance > 0) %~isequal(params.decis_balance,0) % && ~any(n_decis_trial < params.decis_min)
        if strcmpi(params.decis_balance,'max')
            params.n_balance = max(n_trial_decis);
        elseif strcmpi(params.decis_balance,'min')
            params.n_balance = min(n_trial_decis);
        elseif isnumeric(params.decis_balance) && params.decis_balance > 0
            params.n_balance = params.decis_balance;
        end
        fprintf('\nBalancing by decision -> %i trials each', params.n_balance)
        decis_diff = params.n_balance - n_trial_decis;
        for s = find(decis_diff <= 0) % # trials >= balance target
            % randomly select (without replacement) trials to use
            params.tr_bal{s} = tr_decis{s}(sort(randsample(n_trial_decis(s), params.n_balance)))'; % randi(n_decis_trial(s), 1, params.n_balance)
            act_sub{s+1,1} = act{1}(:,:,params.tr_bal{s});
            act_sub{s+1,2} = act{2}(:,:,params.tr_bal{s});
        end
        for s = find(decis_diff > 0) % # trials < balance target
            % randomly select (with replacement) trials to reuse, and append them to the end of act
            params.tr_bal{s} = [tr_decis{s}, tr_decis{s}(randi(n_trial_decis(s), 1, decis_diff(s)))];
            act_sub{s+1,1} = act{1}(:,:,params.tr_bal{s});
            act_sub{s+1,2} = act{2}(:,:,params.tr_bal{s});
        end
    else
        params.n_balance = 0; 
        for s = 1:n_decis
            params.tr_bal{s} = tr_decis{s};
            act_sub{s+1,1} = act{1}(:,:,tr_decis{s});
            act_sub{s+1,2} = act{2}(:,:,tr_decis{s});
        end
    end
end

% RUN THE CCA ON EACH SUBTYPE
setup_parpool_SCC;
tic
Xwin = cell(1,n_sub); Ywin = cell(1,n_sub); Xwin_trial = cell(1,n_sub); Ywin_trial = cell(1,n_sub);
for s = 1:n_sub %flip(1:n_sub)
    % Initialize values for the output results structure
    results.(sub_name{s}).subtype = sub_name{s};
    results.(sub_name{s}).sample_ratio = nan(params.n_step, params.n_delay);
    results.(sub_name{s}).r_full = nan(params.n_step, params.n_delay, n_ROI_min); % correlation using all the data
    results.(sub_name{s}).r_cv = nan(params.n_step, params.n_delay, n_ROI_min, params.n_cv); % correlations obtained from cross-validation
    results.(sub_name{s}).r_shf = nan(params.n_step, params.n_delay, n_ROI_min, params.n_shuff); % correlations obtained from shuffling trials
    results.(sub_name{s}).r_thresh = nan(params.n_step, params.n_delay); % threshold correlations to consider a dimension significant
    results.(sub_name{s}).dim_sig = nan(params.n_step, params.n_delay);
    results.(sub_name{s}).A = nan(n_ROI(1), n_ROI_min, params.n_step, params.n_delay);
    results.(sub_name{s}).B = nan(n_ROI(2), n_ROI_min, params.n_step, params.n_delay);
    results.(sub_name{s}).r_trial = nan(params.n_step, params.n_delay, n_ROI_min, n_trial); % correlations obtained from projecting individual trials along CCA dimensions
    results.(sub_name{s}).IFI = nan(params.n_step, n_ROI_min);
    results.(sub_name{s}).IFI_shf = nan(params.n_step, n_ROI_min);
    results.(sub_name{s}).IFI_trial = nan(params.n_step, n_ROI_min, n_trial);
    results.(sub_name{s}).IFI_sub = nan(params.n_step, n_ROI_min, n_decis);

    % divide the data into windows, including relative delays, and generate shuffled versions too
    [Xwin{s}, Ywin{s}, Xshuff, Xwin_trial{s}, Ywin_trial{s}] = window_activity(act_sub(s,:), params, false); % {s}

    % Run CCA + cross-validation + shuffles on each window/delay,
    if params.n_step > 1, w = waitbar(0, sprintf('Performing windowed CCA on %s dataset',sub_name{s})); end
    for tp = 1:params.n_step % step_half %
        if params.n_step == 1 && params.n_delay > 1, w = waitbar(0, sprintf('Performing delayed CCA on %s dataset',sub_name{s})); end % 'Performing delayed CCA'
        for dl = 1:params.n_delay
            Xtemp = Xwin{s}{tp};
            Ytemp = Ywin{s}{tp,dl};
            % remove missing data and check the sample ratio
            nan_frames = find(isnan(sum([Xtemp, Ytemp], 2)));
            Xtemp(nan_frames,:) = [];  Ytemp(nan_frames,:) = [];
            results.(sub_name{s}).sample_ratio(tp,dl) = size(Xtemp,1)/(size(Xtemp,2) + size(Ytemp,2));
            if results.(sub_name{s}).sample_ratio(tp,dl) > params.min_ratio
                % CCA on full data
                [results.(sub_name{s}).A(:,:,tp,dl), results.(sub_name{s}).B(:,:,tp,dl), results.(sub_name{s}).r_full(tp,dl,:)] = canoncorr(Xtemp, Ytemp);
                % Cross-validation
                if params.n_cv > 0 %CrossValidate
                    if strcmpi(params.cv_style, 'han') % Shuting Han's method
                        for fld = 1:params.n_cv
                            idx_train = randperm(size(X,1), round(size(Xtemp,1)*0.8));
                            [~, ~, results.(sub_name{s}).r_cv(tp,dl,:,fld)] = canoncorr(Xtemp(idx_train,:),Ytemp(idx_train,:));
                        end
                    else % Semedo method
                        cv_part = cvpartition(size(Xtemp,1), 'kFold', params.n_cv);
                        for fld = 1:params.n_cv
                            [results.(sub_name{s}).r_cv(tp,dl,:,fld),~,~] = CanonCorrFitAndPredict( Xtemp(cv_part.training(fld),:), Ytemp(cv_part.training(fld),:), Xtemp(cv_part.test(fld),:), Ytemp(cv_part.test(fld),:) );
                        end
                    end
                else
                    [~, ~, aux, ~] = CanonCorr(Xtemp, Ytemp); % warnings(dl)
                    results.(sub_name{s}).r_cv(tp,dl,:) = aux(1:params.n_pair);
                end
                % Shuffle trials and recalculate CC
                result_shf = cell(1,params.n_shuff);  %A_shf = cell(1,params.n_shuff);
                parfor sh = 1:params.n_shuff
                    Xtemp_shuff = Xshuff{tp,sh}; %Squash(Xbin(:,:,randperm(size(Xbin,3))))';
                    Xtemp_shuff(nan_frames,:) = [];
                    Ytemp_shuff = Ytemp;
                    shuff_nan_frames = find(isnan(sum([Xtemp_shuff, Ytemp_shuff], 2))); % Shuffling may have spread nans around
                    Xtemp_shuff(shuff_nan_frames,:) = [];
                    Ytemp_shuff(shuff_nan_frames,:) = [];
                    [result_shf{sh}.A, result_shf{sh}.B, result_shf{sh}.r] = CanonCorr( Xtemp_shuff, Ytemp_shuff ); 
                end
                for sh = 1:params.n_shuff % unpack cell version of results used for parallelizing shuffled analysis
                    results.(sub_name{s}).r_shf(tp,dl,:,sh) = result_shf{sh}.r;
                end
                % Project trial-level data into CCA space and then get trial-level correlation
                if dl == params.dl_zero && s == 1
                    for tr = 1:n_trial % par is slower
                        results.(sub_name{s}).r_trial(tp,dl,:,tr) = diag( corr(Xwin_trial{s}{tp,tr}*results.(sub_name{s}).A(:,:,tp,dl), ...
                            Ywin_trial{s}{tp,dl,tr}*results.(sub_name{s}).B(:,:,tp,dl), 'rows','complete') );
                    end
                end
            end
            if params.n_step == 1 && params.n_delay > 1, waitbar(dl/params.n_delay, w); end
        end
        if params.n_step > 1, waitbar(tp/params.n_step, w); end
    end
    if exist('w','var'), close(w); end

    % CALCULATE STATISTICS OF INTEREST FROM CCA results.(sub_name{s})
    results.(sub_name{s}) = SummarizeCCA(results.(sub_name{s}), params); % 
    toc
end

% Project data into each subset's subspace, and then calculate correlation (very slow for large # of comparisons)
% { 
if strcmpi(params.decis_type, 'decis')
    %fprintf('\nCalculating projections');
    results.proj.r = nan(params.n_step, params.n_delay, n_sub, n_sub, n_ROI_min);
    results.proj.beta = nan(params.n_step, params.n_delay, n_sub, n_sub, n_ROI_min);
    for tp = 1:params.n_step
        for dl = 1:params.n_delay
            for S = 1:3 %n_sub % which subspace to project into
                for s = 1:n_sub % source of data to project
                    Xproj_temp = Xwin{s}{tp}*results.(sub_name{S}).A(:,:,tp,dl);
                    Yproj_temp = Ywin{s}{tp,dl}*results.(sub_name{S}).B(:,:,tp,dl);
                    results.proj.r(tp,dl,S,s,:) = diag(corr(Xproj_temp, Yproj_temp, 'rows','complete')); % corr_sub_prob{s} =
                    for d = 1:n_ROI_min
                        results.proj.beta(tp,dl,S,s,d) = Xproj_temp(:,d)\Yproj_temp(:,d);
                    end
                end
            end
        end
    end
end

% Project the full trial data into the CCA subspaces (top dim_max dims only) defined for each window/delay
% CAREFUL - this could be very memory-expensive for multiple timepoints/windows
if params.proj_data
    %fprintf('\nCalculating intra-chunk projections');
    results.proj.data = act_sub; %cell(params.n_step, params.n_delay, n_sub, 2);
    results.proj.data_intra = cell(n_sub, 2, params.n_step, params.n_delay);
    results.proj.r_intra = nan(n_sub, params.dim_max, params.n_step, params.n_delay);
    %results.proj.beta_intra = nan(n_sub, params.dim_max, params.n_step, params.n_delay);
    for s = 1:n_sub
        for tp = 1:params.n_step
            for dl = 1:params.n_delay
                % project trial-by-trial data into the current subspaces
                results.proj.data_intra{s,1,tp,dl} = nan(n_frame, params.dim_max, n_trial);
                results.proj.data_intra{s,2,tp,dl} = nan(n_frame, params.dim_max, n_trial);
                for tr = flip(1:n_trial)
                    results.proj.data_intra{s,1,tp,dl}(:,:,tr) = act_sub{s,1}(:,:,tr)'*results.(sub_name{s}).A(:,1:params.dim_max,tp,dl);
                    results.proj.data_intra{s,2,tp,dl}(:,:,tr) = act_sub{s,2}(:,:,tr)'*results.(sub_name{s}).B(:,1:params.dim_max,tp,dl);
                end
                % Calculate correlation/beta coefficients (ignoring NaNs)
                Xcat_temp = Squash(permute(results.proj.data_intra{s,1,tp,dl},[2,1,3]))';
                Ycat_temp = Squash(permute(results.proj.data_intra{s,2,tp,dl},[2,1,3]))';
                nan_ind = find(any(isnan([Xcat_temp,Ycat_temp]),2));
                Xcat_temp(nan_ind,:) = []; Ycat_temp(nan_ind,:) = [];
                results.proj.r_intra(s,:,tp,dl) = diag( corr(Xcat_temp, Ycat_temp, 'rows','complete' ) );
                %for d = 1:params.dim_max,  results.proj.beta_intra(s,d,tp,dl) = Xcat_temp(:,d)\Ycat_temp(:,d); end
            end
        end
    end
end
results.params = params; 
%{
decis_color = distinguishable_colors(n_decis);
sub_color = distinguishable_colors(n_sub);
close all; clearvars sp h;
figure('WindowState','maximized')
for d = 1:2
    clf;
    tiledlayout(1,3)
    for S = 1:3 %n_sub % which subspace to project into
        nexttile
        for s = 2:n_sub % subset of data to project
            Xproj_temp = Xwin{s}{tp}*results.(sub_name{S}).A(:,:,tp,dl);
            Yproj_temp = Ywin{s}{tp,dl}*results.(sub_name{S}).B(:,:,tp,dl);
            plot(Xproj_temp(:,d), Yproj_temp(:,d), '.', 'Markersize',2, 'color',sub_color(s,:)); hold on;
            %scatter(Xproj_temp(:,d), Yproj_temp(:,d), 10, 'filled', 'color',sub_color(s,:), 'MarkerFaceAlpha',0.1); hold on;
            %pause;
        end
        set(gca,'XAxisLocation','origin', 'YAxisLocation','origin')
        title( {sprintf('%s subspace (%i trials)',sub_name{S}, n_trial_sub(S)), ...
            sprintf('r_{All} = %2.2f, r_{Hit} = %2.2f, r_{CR} = %2.2f, r_{Miss} = %2.2f, r_{FA} = %2.2f', ...
            results.proj.r(tp,dl,S,1,d), results.proj.r(tp,dl,S,2,d), results.proj.r(tp,dl,S,3,d), results.proj.r(tp,dl,S,4,d), results.proj.r(tp,dl,S,5,d) )}, 'FontSize',16 )
        lim_temp = get(gca,'Xlim');
        for s = 2:n_sub
            h(s-1) = line(lim_temp, results.proj.beta(tp,dl,S,s,d)*lim_temp, 'Color',decis_color(s-1,:), 'linewidth',2); % beta_temp(s)
        end
        if S == 1
            legend(h, sub_name(2:n_sub), 'Location','best')
        end
        axis square;
        %pause
    end
    %sgtitle(sprintf('Dim %i', d), 'FontSize',18)
    pause
end
%}

% Timestamp the final results
results.timestamp = TimeStamp; % convertStringsToChars(string(datetime('now','TimeZone','local','Format','MMM_d_y_HH_mm')));
end