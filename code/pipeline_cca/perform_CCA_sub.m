sm_assert_writable(); % [release] this script writes into the data tree; refuses to run against the lab's working copy
% Setup/housekeeping - must run the first block of gather_SM_data first!
% Z:\Dropbox\Chen Lab Dropbox\Chen Lab Team Folder\Projects\Sensorimotor\Scripts\gather_SM_data.m
[animal, n_animal, fov_name, n_fov, comp, decis_name, animal_table, n_session_max, sessions, animal_fig_dir] = setup_SM_workspace();
fig_dir = smout('figures'); % [release] the figure cells below use fig_dir, which the lab got from add_sm_paths
[preproc_dir, preproc_dir_exists] = ChenLabFilepath([smroot() 'Analysis/preprocessing/']);

CCA_params = set_CCA_params('align_event',"direction_2_time", 'align_keep_lim',Inf, 'exclude','none',...  
    'WindowLength',Inf, 'TimeStep',0, 'DelayStep',0, 'min_ratio',100, ...
    'decis_type',"none", 'proj_data',true, 'resid_type','stim', 'resid_std',false, ...
    'name','full-resid_stim' ); % -drop_noncherry % -suppress_noncherry      %'suppress','non',...

% CCA_params = set_CCA_params('align_event',"direction_2_time", 'align_keep_lim',Inf, 'exclude','none',...  %
%     'WindowLength',Inf, 'TimeStep',0, 'DelayStep',0, 'min_ratio',100, ...
%     'decis_type',"none", 'proj_data',true, 'resid_type','direction_decision', 'name','full-resid_dir_decis' ); % -drop_noncherry

% CCA_params = set_CCA_params('align_event',["direction_1_time"  "direction_2_time"], 'align_keep_lim',[90,90],...
%     'WindowLength',15, 'TimeStep',3, 'DelayStep',3, 'MaxDelay',12, 'min_ratio',100, ...
%     'decis_type',"correct", 'proj_data',true, 'resid_type','stim','name','peri90-win15-step3-correct' ); % , 'name','periInf-winInf-step0-none' , 'name','peri90-ratio10-step3-decis_sub'
%CCA_params = set_CCA_params('name','peri90-win15-step3-correct');

n_align = CCA_params.n_align;
n_decis = numel(CCA_params.decis_name);
sub_name = CCA_params.sub_name; %["All", CCA_params.decis_name];
n_sub = numel(sub_name);
%event_name = {'Stim 1', 'Stim 2'};
CCA = cell(n_animal, n_session_max);

%%
gather_only = false; % set true to gather existing results only, and prevent running new CCA
overwrite = false; % BE VERY CAREFUL, SETTING THIS TO TRUE WILL OVERWRITE EXISTING CCA FILES
if overwrite, fprintf('\nOVERWRITE ON - UNPAUSE TO CONTINUE\n'); pause; end
for an = 1:n_animal
    for sess = intersect(sessions(an).use, sessions(an).ctrl) % 3%% flip(sessions(an).ctrl) % sessions(an).use %intersect(sessions(an).use, sessions(an).(cond_field{cnd})) %sessions(an).ctrl(1:3) % 1 % sessions(an).use %1:2 % [flip(sessions(an).ctrl), flip(sessions(an).dreadd)] % find(~cellfun(@isempty,act(an,:)))
        try
            % setup CCA_result & CCA_mat, either loaded from existing data, fresh, or as empty variables
            [CCA_result, CCA_mat, run_mat] = LoadCCA(animal{an}, sess, CCA_params, gather_only, overwrite);
            %run_mat = true(n_align,comp.n);

            % Run the CCA for each set of inter-FOV comparison (unless it's already been run and we don't want to overwrite it)
            if any(run_mat, 'all')
                [preproc_path, preproc_path_exists] = ChenLabFilepath(fullfile(preproc_dir, sprintf('%s-%i_preprocess_pca.mat', animal{an}, sess))); % _split  _suppress_noncherry
                preproc_vars = {'T_align', 'act_align', 'act_resid', 'tr_include', 'shift_frame', ...
                    'trial_frame', 'choice', 'direction', 'texture', 'dir_decis', 'PCA_coeff', 'PCA_explained', 'CCA_params'}; % , 'probe_choice'
                if ~preproc_path_exists % || overwrite
                    % Load the data
                    [trials, ~, ~, fov, ~, act_sess] = LoadMultiFOV(animal{an}, sess, 'drop_field',{'trial'}); % [trials, ~, ~, fov{an,sess}, ~, act{an,sess}]
                    act_raw = cellfun(@permute, {act_sess.trial_resamp}, repmat({[2,1,3]},1,n_fov), 'UniformOutput',false);

                    % preprocess the data
                    [act_proc, CCA_params] = exclude_mcherry_cells(act_raw, fov, CCA_params); % before PCA, exclude mcherry+ cells, OR, randomly exclude an equivalent # of mcherry- cells?
                    
                    %[act_proc, PCA, ~, trial_frame] = prepare_CCA_data(act_proc, CCA_params); % LP filter each trace and perform PCA         , act_filt
                    act_proc = filter_activity(act_proc, CCA_params); % LP filter each trace
                    [act_proc, PCA, trial_frame, CCA_params] = activity_PCA(act_proc, fov, CCA_params);

                    [CCA_params, decis_labels] = get_trial_labels(trials, CCA_params);
                    [act_resid, act_align, T_align, shift_frame, tr_exclude, CCA_params, ~] = align_activity(act_proc, trials, CCA_params, false); % excluded trials are removed here

                    % pull out relevant PCA info
                    PCA_result = [PCA.result];
                    PCA_coeff = {PCA_result.coeff};
                    PCA_explained = {PCA_result.explained};
                    
                    % parse trials
                    tr_include = cell(size(tr_exclude));
                    for ev = 1:numel(tr_exclude), tr_include{ev} = setdiff(1:trials.n_all, tr_exclude{ev}); end % cellfun(@numel, tr_include)
                    
                    % Get trial labels (and remove excluded trials)
                    [~, ~, choice] = GetTrialSubsets(trials.all, "decision", ["Hit","Miss","CR","FA"]);
                    [~, ~, direction] = GetTrialSubsets(trials.all, ["direction_1_dir","direction_2_dir"], ["CW_CW", "CW_CCW", "CCW_CW", "CCW_CCW"]);
                    [~, ~, texture] = GetTrialSubsets(trials.all, "texture", ["200","800","1400"] );
                    [~, ~, dir_decis] = GetTrialSubsets(trials.all, ["direction_1_dir","direction_2_dir","decision"]);

                    % save the results of preprocessing
                    fprintf('\nSaving %s...', preproc_path)
                    save(preproc_path, preproc_vars{:}); %
                else
                    fprintf('\nLoading %s ', preproc_path)
                    load(preproc_path, preproc_vars{:}) 
                end
                
                % Standarize the residuals? NOTE: performed AFTER preprocessing, so the version of act_resid in the _preprocess_pca.mat file is NOT standardized
                if CCA_params.resid_std
                    act_resid = cellfun(@standardize_multitrial, act_resid, 'UniformOutput',false); % try z-scoring the residual
                end

                % Go through each comparison/event and perform the CCA
                n_trial_ev = cellfun(@(x)(size(x,3)), act_align(:,1));
                for ev = find(any(run_mat,2) & n_trial_ev > CCA_params.n_trial_min)'  %  & n_trial_ev/trials.n_all >= CCA_params.min_trial_frac
                    CCA_params.t_align = CCA_params.frame_dur*T_align{ev,1};
                    CCA_params.tr_exclude = setdiff(1:size(act_align{1},3), tr_include{ev}); %tr_exclude{ev}'; trials.n_all
                    if ~strcmpi(CCA_params.decis_type, 'none')
                        CCA_params.decis_labels = decis_labels;
                        CCA_params.decis_labels(tr_exclude{ev}) = []; % make sure decision labels respect excluded trials
                    end
                    for cmp = find(run_mat(ev,:)) % 1:comp.n
                        % Setup the version of activity to use for CCA
                        fprintf('\n[an, sess, ev, c] = [%i, %i, %i, %i]\n', an, sess, ev, cmp)
                        CCA_result(ev,cmp).data_name = sprintf('%s-%i-%s-peri_%s', animal{an}, sess, comp.name{cmp}, CCA_params.align_event{ev}); %#ok<*SAGROFW>   , phase.name{p}
                        if isempty(CCA_params.resid_labels)
                            act_cca = cellfun(@permute, [act_align(ev,comp.ind(cmp,1)), act_align(ev,comp.ind(cmp,2))], repmat({[2,1,3]},1,2),'UniformOutput',false); % CanonicalCrossCorrelation expects two cells containing ROI x time x trial arrays of spiking.
                        else % analyze residuals if desired
                            act_cca = cellfun(@permute, [act_resid(ev,comp.ind(cmp,1)), act_resid(ev,comp.ind(cmp,2))], repmat({[2,1,3]},1,2),'UniformOutput',false);
                        end
                        act_cca = cellfun(@(x)(x(:,:,tr_include{ev})), act_cca, 'UniformOutput',false); % [release] excluded trials must not be fitted or projected
                        if isfinite(CCA_params.n_PC)
                            act_cca{1} = act_cca{1}(1:CCA_params.n_PC,:,:);  act_cca{2} = act_cca{2}(1:CCA_params.n_PC,:,:); % limit analysis to top CCA_params.n_PC PCs
                        end
                        %act_cca{2} = circshift( act_cca{1}, 6, 2); fprintf('\nTEST MODE ON');  % for testing purposes, make act2 a delayed version of act1

                        % Run windowed CCA
                        CCA_result(ev,cmp) = CanonicalCrossCorrelationSubtype(act_cca, CCA_params, CCA_result(ev,cmp));

                        % Save the results to the file
                        fprintf('\nUpdating %s (%s)\n', CCA_mat.Properties.Source, CCA_result(ev,cmp).data_name);
                        CCA_mat.CCA(ev,cmp) = CCA_result(ev,cmp);
                        %show_CCA_results(CCA_result(ev,cmp).All, CCA_result(ev,cmp).params, '')
                    end
                end
                CCA_result = cca_coeff_2_roi(CCA_result, CCA_mat);
            end
        catch
            fprintf('\n%s-%i failed!\n', animal{an}, sess)
        end
        
        %CCA{an,sess} = CCA_result;  % Move the final version of CCA_result into the master cell array
        clearvars CCA_mat;
    end
end

%% Gather data into plottable arrays
%{
max_dim = 3; 
check_dim = 1:max_dim;
sess_name = cell(0,1); sess_ind = nan(0,2);
t_step = cell(0,n_align);  t_delay = cell(0,n_align);  decis_labels = cell(0,n_align);
r_zero = cell(0, n_align, comp.n);  r_zero_shf = cell(0, n_align, comp.n); r_map = cell(0, n_align, comp.n);  r_map_shf = cell(0, n_align, comp.n);
r_zero_an = cell(n_animal, n_align, comp.n);
r_sub = cell(0, n_align, comp.n, n_decis); r_sub_half = cell(0, n_align, comp.n, n_decis); 
r_proj_half = cell(0, n_align, comp.n); 
angle_half_A = cell(n_align, comp.n); % 0, 
%r_trial = cell(0, n_align, comp.n); r_decis_mean = cell(0, n_align, comp.n, n_decis);
r_map_peaks = cell(0, n_align, comp.n); r_sub_peaks = cell(0, n_align, comp.n, n_decis);
r_sub_cat = cell(0, n_align, comp.n); r_decis_mean_cat = cell(0, n_align, comp.n);
k = 0; 
for an = 1:n_animal
    q = 0;
    for sess = sessions(an).ctrl
        % Check that the data exists and is complete
        if ~isempty(CCA{an,sess})  && ~any(cellfun(@isempty, reshape({CCA{an,sess}.data_name}, n_align, comp.n)),'all') % && isequal(size(CCA{an,sess}), [n_align, comp.n])
            try
            k = k+1; q = q+1;
            sess_ind(k,1) = an; sess_ind(k,2) = sess;
            sess_name{k} = sprintf('%s-%i', animal{an}, sess);
            % Gather results from windowed analysis of the peri-event raster
            for ev = 1:n_align
                t_step{k,ev} = CCA{an,sess}(ev,1).params.t_step; % relative to beginning of aligned data
                [~,step_half] = min(abs(t_step{k,ev} - 0.5));
                t_delay{k,ev} = CCA{an,sess}(ev,1).params.t_delay;
                decis_labels{k,ev} = CCA{an,sess}(ev,1).params.decis_labels;
                for c = 1:comp.n
                    r_zero{k,ev,c} = CCA{an,sess}(ev,c).All.r_zero;
                    r_zero_shf{k,ev,c} = CCA{an,sess}(ev,c).All.r_zero_shf;

                    %t_delay_an{an,ev} = CCA{an,sess}(ev,1).params.t_delay;
                    %r_zero_an{an,ev,c}(:,:,q) = r_zero{k,ev,c};

                    r_map{k,ev,c} = CCA{an,sess}(ev,c).All.r_map;
                    %r_map_peaks{k,ev,c} = get_map_statistics(r_map{k,ev,c}, t_step{k,ev}, t_delay{k,ev}, false); % true false
                    r_map_shf{k,ev,c} = CCA{an,sess}(ev,c).All.r_map_shf;
                    %r_trial{k,ev,c} = CCA{an,sess}(ev,c).All.r_trial;
                    for s = 1:n_sub
                        r_sub{k,ev,c,s} = CCA{an,sess}(ev,c).(sub_name{s}).r_full;
                        r_sub_half{k,ev,c,s} = r_sub{k,ev,c,s}(step_half,CCA{an,sess}(ev,c).params.dl_zero,:);
                        %r_sub_peaks{k,ev,c,s} = get_map_statistics(r_sub{k,ev,c,s}, t_step{k,ev}, t_delay{k,ev}, true); % true
                    end
                    r_sub_cat{k,ev,c} = cat(2, r_sub{k,ev,c,:}); % concatenate full and decision-specific corrleation maps for plotting
                    % Pull out correlation projections
                    r_proj_half{k,ev,c} = nan(3,n_sub,max_dim); 
                    for S = 1:3 % which subspace to project into
                        for s = 1:n_sub % which subset of data was to projected
                            r_proj_half{k,ev,c}(S,s,:) = squeeze( CCA{an,sess}(ev,c).proj.r(step_half, CCA{an,sess}(ev,c).params.dl_zero, S, s, 1:max_dim) );
                        end
                    end
                    % Calculate angle between subset-defined subspaces
                    temp_angle_A = nan(3,3); temp_angle_B = nan(3,3);
                    for S = 1:3 % which subspace to project into
                        for s = 1:3 % which subset of data was to projected
                            temp_angle_A(S,s) = sum( subspacea( CCA{an,sess}(ev,c).(sub_name{S}).A(:,check_dim,step_half,CCA{an,sess}(ev,c).params.dl_zero), ...
                                CCA{an,sess}(ev,c).(sub_name{s}).A(:,check_dim,step_half,CCA{an,sess}(ev,c).params.dl_zero) ) );
                            temp_angle_B(S,s) = sum( subspacea( CCA{an,sess}(ev,c).(sub_name{S}).B(:,check_dim,step_half,CCA{an,sess}(ev,c).params.dl_zero), ...
                                CCA{an,sess}(ev,c).(sub_name{s}).B(:,check_dim,step_half,CCA{an,sess}(ev,c).params.dl_zero) ) );
                        end
                    end
                    angle_half{ev,c}(k,:,1) = temp_angle_A( triu(true(size(temp_angle_A)),1))';
                    angle_half{ev,c}(k,:,2) = temp_angle_B( triu(true(size(temp_angle_B)),1))';
                end
            end
            fprintf('\n%s-%i added\n', animal{an}, sess)
            catch
                k = k-1;
            end
        else
            fprintf('\n%s-%i was empty or incomplete - skipped\n', animal{an}, sess)
        end
        
    end
end
n_data = k;



%}

%% Trial-averaged
timestamp = convertStringsToChars(string(datetime('now','TimeZone','local','Format','MMM_d_y_HH_mm'))); %
fig_path = fullfile(fig_dir,sprintf('CCA_corr_decis_%s.pdf',timestamp));
CCA_corr_decis_fig = figure('WindowState','maximized', 'Units','normalized');
LW_cent = 1.5; LW_edge = 3;
for k = 1:n_data
    for d = 1
        %clf;
        %tiledlayout(comp.n, n_align);
        for cmp = 1:comp.n
            clf;
            tiledlayout(1, n_align);
            for ev = 1:n_align
                % figure out y axes
                n_delay = numel(t_delay{k,ev});
                y_cent_ticks = round(n_delay/2):n_delay:size(r_decis_mean_cat{k,ev,cmp},2); % comp.n
                y_cent_labels = ["All",CCA_params.decis_name];
                y_edge_ticks =  [0,n_delay:n_delay:size(r_decis_mean_cat{k,ev,cmp},2)]+0.5;
                y_delay_ticks = [y_edge_ticks(1)+0.5, y_cent_ticks, y_edge_ticks(end)-0.5];
                y_delay_labels = [num2str(t_delay{k,ev}(1)), sprintfc('%d', zeros(1,numel(y_cent_ticks))) ,num2str(-t_delay{k,ev}(1))];
                % figure out x axes
                %[T_align_step, align_step] = min(abs(t_step{k,ev} - CCA_params.frame_dur*CCA_params.align_keep_lim(1)));
                %[T_align_step, align_step] = min(abs(t_step{k,ev} - CCA_params.frame_dur*CCA_params.align_keep_lim(1))); % - CCA_params.frame_dur*CCA_params.align_keep_lim(1)
                %T_peri = t_step{k,ev} - t_step{k,ev}(align_step);
                T_peri = reshape(t_step{k,ev}, 1, []);
                x_lims = T_peri([1,end]) + [-1,1]*diff(t_step{k,ev}([1,2]))/2; %T_peri([1,end]) + [-1,1]*(t_step{k,ev}(2)-t_step{k,ev}(1))/2;

                nexttile
                yyaxis left;
                imagesc(T_peri, [], r_decis_mean_cat{k,ev,cmp}(:,:,d)'); impixelinfo
                CB = colorbar;
                hold on;
                line([0,0], y_edge_ticks([1,end]), 'color','k','linewidth',LW_cent, 'linestyle','--')
                for s = 1:n_decis
                    line(x_lims, y_cent_ticks(s)*[1,1], 'color','k','linestyle','--', 'linewidth',LW_cent)
                    line(x_lims, y_edge_ticks(s+1)*[1,1], 'color','k', 'linestyle','-', 'linewidth',LW_edge);
                end
                set(gca,'Ytick',y_cent_ticks, 'YtickLabel',y_cent_labels, 'box','off')
                title(sprintf('%s %s %s', sess_name{k}, CCA_params.align_event{ev}, comp.name{cmp}), 'interpreter','none')
                y_lim_left = get(gca,'Ylim');

                xlim(T_peri([find(~all(isnan(r_decis_mean_cat{k,ev,cmp}(:,:,d)),2), 1, 'first'), find(~all(isnan(r_decis_mean_cat{k,ev,cmp}(:,:,d)),2), 1, 'last')]) + [-1,1]*(T_peri(2)-T_peri(1))/2 );
                yyaxis right;
                ylim(y_lim_left);
                set(gca,'Ytick',y_delay_ticks, 'YtickLabel',y_delay_labels); %
                ylabel({'Delay (s)','+: Source leads target'});
            end
            pause;
        end
    end
end

%% Trial-subtype
timestamp = convertStringsToChars(string(datetime('now','TimeZone','local','Format','MMM_d_y_HH_mm'))); %
fig_path = fullfile(fig_dir,sprintf('CCA_corr_decis_%s.pdf',timestamp));
CCA_corr_decis_subtype_fig = figure('WindowState','maximized', 'Units','normalized');
LW_cent = 1.5; LW_edge = 3;
for k = 1:n_data
    for d = 1
        for cmp = 1:comp.n
            clf;
            tiledlayout(1, n_align);
            for ev = 1:n_align
                n_delay = numel(t_delay{k,ev});
                y_cent_ticks = round(n_delay/2):n_delay:size(r_sub_cat{k,ev,cmp},2); % comp.n
                y_cent_labels = ["All",CCA_params.decis_name];
                y_edge_ticks =  [0,n_delay:n_delay:size(r_sub_cat{k,ev,cmp},2)]+0.5;
                y_delay_ticks = [y_edge_ticks(1)+0.5, y_cent_ticks, y_edge_ticks(end)-0.5];
                y_delay_labels = [num2str(t_delay{k,ev}(1)), sprintfc('%d', zeros(1,numel(y_cent_ticks))) ,num2str(-t_delay{k,ev}(1))];
                T_peri = reshape(t_step{k,ev}, 1, []); % - t_step{k,ev}(align_step);
                x_lims = T_peri([1,end]) + [-1,1]*(t_step{k,ev}(2)-t_step{k,ev}(1))/2;

                nexttile
                yyaxis left;
                imagesc(T_peri, [], r_sub_cat{k,ev,cmp}(:,:,d)'); impixelinfo
                CB = colorbar;
                hold on;
                line([0,0], y_edge_ticks([1,end]), 'color','k','linewidth',LW_cent, 'linestyle','--')
                for s = 1:n_decis
                    line(x_lims, y_cent_ticks(s)*[1,1], 'color','k','linestyle','--', 'linewidth',LW_cent)
                    line(x_lims, y_edge_ticks(s+1)*[1,1], 'color','k', 'linestyle','-', 'linewidth',LW_edge);
                end
                line(x_lims, y_cent_ticks(s+1)*[1,1], 'color','k','linestyle','--', 'linewidth',LW_cent)
                set(gca,'Ytick',y_cent_ticks, 'YtickLabel',y_cent_labels, 'box','off')
                title(sprintf('%s', CCA_params.align_event{ev}), 'interpreter','none')
                xlabel('Peri-event time (s)');
                y_lim_left = get(gca,'Ylim');
                xlim(T_peri([find(~all(isnan(r_sub_cat{k,ev,cmp}(:,:,d)),2), 1, 'first'), find(~all(isnan(r_sub_cat{k,ev,cmp}(:,:,d)),2), 1, 'last')]) + [-1,1]*(T_peri(2)-T_peri(1))/2 );
                yyaxis right;
                ylim(y_lim_left);
                set(gca,'Ytick',y_delay_ticks, 'YtickLabel',y_delay_labels, 'Ydir','reverse'); %
                ylabel({'Delay (s)','+: Source leads target'});
            end
            sgtitle(sprintf('%s, %s, %s, dim %i', CCA_params.name, sess_name{k}, comp.name{cmp}, d), 'Interpreter','none', 'FontSize',16)
            pause;
        end
    end
end

%%
timestamp = convertStringsToChars(string(datetime('now','TimeZone','local','Format','MMM_d_y_HH_mm'))); %
fig_path = fullfile(fig_dir,sprintf('CCA_corr_decis_sess_avg_%s.pdf',timestamp));
CCA_corr_decis_sess_avg_fig = figure('WindowState','maximized', 'Units','normalized');
LW_cent = 1.5; LW_edge = 3;
for d = 1:max_dim
    for cmp = 1:comp.n
        clf;
        tiledlayout(1, n_align);
        for ev = 1:n_align
            n_delay =  numel(t_delay{1,ev}); 
            y_cent_ticks = round(n_delay/2):n_delay:size(r_sub_cat{1,ev,cmp},2); % comp.n
            y_cent_labels = ["All",CCA_params.decis_name];
            y_edge_ticks =  [0,n_delay:n_delay:size(r_sub_cat{1,ev,cmp},2)]+0.5;
            y_delay_ticks = [y_edge_ticks(1)+0.5, y_cent_ticks, y_edge_ticks(end)-0.5];
            y_delay_labels = [num2str(t_delay{1,ev}(1)), sprintfc('%d', zeros(1,numel(y_cent_ticks))) ,num2str(-t_delay{1,ev}(1))];
            T_peri = reshape(t_step{1,ev}, 1, []); 
            x_lims = T_peri([1,end]) + [-1,1]*(t_step{1,ev}(2)-t_step{1,ev}(1))/2;
            % Average correlation maps over all sessions, for this dim and comparison
            r_sub_cat2 = cat(4, r_sub_cat{:,ev,cmp}); % size(r_sub_cat)
            r_sub_cat2_mean = mean(r_sub_cat2(:,:,d,:),4)';

            nexttile
            yyaxis left;
            
            imagesc(T_peri, [], r_sub_cat2_mean); impixelinfo;

            CB = colorbar;
            hold on;
            line([0,0], y_edge_ticks([1,end]), 'color','k','linewidth',LW_cent, 'linestyle','--')
            for s = 1:n_decis
                line(x_lims, y_cent_ticks(s)*[1,1], 'color','k','linestyle','--', 'linewidth',LW_cent)
                line(x_lims, y_edge_ticks(s+1)*[1,1], 'color','k', 'linestyle','-', 'linewidth',LW_edge);
            end
            line(x_lims, y_cent_ticks(s+1)*[1,1], 'color','k','linestyle','--', 'linewidth',LW_cent)
            set(gca,'Ytick',y_cent_ticks, 'YtickLabel',y_cent_labels, 'box','off')
            title(sprintf('%s', CCA_params.align_event{ev}), 'interpreter','none')
            xlabel('Peri-event time (s)');
            y_lim_left = get(gca,'Ylim');
            xlim(T_peri([find(~all(isnan(r_sub_cat{1,ev,cmp}(:,:,d)),2), 1, 'first'), find(~all(isnan(r_sub_cat{1,ev,cmp}(:,:,d)),2), 1, 'last')]) + [-1,1]*(T_peri(2)-T_peri(1))/2 );
            
            yyaxis right;
            ylim(y_lim_left);
            set(gca,'Ytick',y_delay_ticks, 'YtickLabel',y_delay_labels, 'Ydir','reverse'); %
            ylabel({'Delay (s)','+: Source leads target'});
        end
        sgtitle(sprintf('%s, dim %i, %i sessions averaged', comp.name{cmp}, d, n_data), 'FontSize',16) % Dropbox {sprintf('%s, dim %i', comp.name{c}, d, n_data), sprintf('%i sessions averaged', n_data)}

        %pause%(0.2)
        fprintf('\nExporting %s', fig_path)
        exportgraphics(CCA_corr_decis_sess_avg_fig, fig_path, 'append',true);
    end
end


