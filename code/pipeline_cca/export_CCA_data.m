sm_assert_writable(); % [release] this script writes into the data tree; refuses to run against the lab's working copy
if ~exist('animal', 'var') % [release] the lab had these from perform_CCA_sub
    [animal, n_animal, fov_name, n_fov, comp, decis_name, animal_table, n_session_max, sessions, animal_fig_dir] = setup_SM_workspace(); % [release]
end % [release]
if ~exist('trials', 'var') || ~iscell(trials) % [release] filled in per session below
    trials = cell(n_animal, n_session_max); fov = cell(n_animal, n_session_max); % [release]
end % [release]
% Select the model to export
model_name = 'full-resid_stim'; % [release] was 'full-resid_stim_std', a variant no figure uses; the published model is full-resid_stim

[preproc_dir, preproc_dir_exists] = ChenLabFilepath([smroot() 'Analysis/preprocessing/']);
if ~preproc_dir_exists, mkdir(preproc_dir); end
[proj_dir, proj_dir_exists] = ChenLabFilepath([[smroot() 'Analysis/proj/'],model_name,'\']); % CCA_params.name
if ~proj_dir_exists, mkdir(proj_dir); end
comp_name = comp.name;
for an = 1:n_animal % [release] was an = 2, the session the author last re-exported
    for sess = intersect(sessions(an).use, sessions(an).ctrl) % [release] was sess = 4
        fprintf('\n[an,sess] = [%i, %i]', an, sess)
        % Load CCA results
        CCA_result = LoadCCA(animal{an}, sess, model_name, true, false);
        if isempty(CCA_result) % [release] the emptiness check below comes too late: the next line already indexes into CCA_result
            fprintf(' - no %s results, skipping', model_name); continue % [release]
        end % [release]
        CCA_params = reshape([CCA_result.params], size(CCA_result)); % get the parameters that were used when the model was originally run
        % Set parameters that might be missing from more recent CCA results files
        if ~isfield(CCA_params, 'exclude')
            for c = 1:numel(CCA_params), CCA_params(c).exclude = 'none'; end
        end
        if ~isfield(CCA_params, 'resid_label_names')
            for c = 1:numel(CCA_params)
                CCA_params(c).resid_labels = [];
                CCA_params(c).resid_label_names = [];
            end
        end

        if ~isempty(CCA_result)
            try
                % Export the preprocessing variables
                [preproc_path, preproc_path_exists] = ChenLabFilepath(fullfile(preproc_dir, sprintf('%s-%i_preprocess_pca.mat', animal{an}, sess)));
                if ~preproc_path_exists %
                    % Load the data
                    [trials{an,sess}, ~, ~, fov{an,sess}, ~, act_sess] = LoadMultiFOV(animal{an}, sess, 'drop_field',{'trial'});
                    % preprocess the data and repackage for export
                    act_raw = cellfun(@permute, {act_sess.trial_resamp}, repmat({[2,1,3]},1,n_fov), 'UniformOutput',false);
                    [act_proc, CCA_params(1)] = exclude_mcherry_cells(act_raw, fov, CCA_params(1)); % before PCA, exclude mcherry+ cells, OR, randomly exclude an equivalent # of mcherry- cells?
                    [act_proc, PCA, ~, trial_frame] = prepare_CCA_data(act_proc, CCA_params(1)); % LP filter each trace and perform PCA    act_filt
                    [CCA_params(1), ~] = get_trial_labels(trials{an,sess}, CCA_params(1)); % decis_labels
                    [act_resid, act_align, T_align, shift_frame, tr_exclude, ~, act_mean] = align_activity( act_proc, trials{an,sess}, CCA_params(1) ); % excluded trials are removed here  CCA_params
                    tr_include = cell(size(tr_exclude));
                    for ev = 1:numel(tr_exclude), tr_include{ev} = setdiff(1:trials{an,sess}.n_all, tr_exclude{ev}); end % cellfun(@numel, tr_include)
                    PCA_coeff = CCA_result(1).pca.coeff;
                    PCA_explained = {PCA_result.explained};
                    t_proj = CCA_result(1).params.t_align;

                    % Get trial labels (and remove excluded trials)
                    [~, ~, choice] = GetTrialSubsets(trials{an,sess}.all, "decision", ["Hit","Miss","CR","FA"]);
                    [~, ~, direction] = GetTrialSubsets(trials{an,sess}.all, ["direction_1_dir","direction_2_dir"], ["CW_CW", "CW_CCW", "CCW_CW", "CCW_CCW"]);
                    [~, ~, texture] = GetTrialSubsets(trials{an,sess}.all, "texture", ["200","800","1400"] );
                    [~, ~, dir_decis] = GetTrialSubsets(trials{an,sess}.all, ["direction_1_dir","direction_2_dir","decision"]);

                    fprintf('\nSaving %s...', preproc_path)
                    save(preproc_path, 'act_align', 'tr_include', 't_proj', 'T_align', 'shift_frame', 'trial_frame', 'PCA_coeff', 'choice', 'direction', 'texture', 'dir_decis'); % 'PCA',  , 'CCA_params', 'act_resid', 'CCA_params', 'act_mean'
                else
                    fprintf('\nLoading %s', preproc_path) % [release] the projection save below needs act_resid from it
                    load(preproc_path, 'act_resid') % [release]
                end
                %}

                % Save the projections and model-specific info
                [proj_path, proj_path_exists] = ChenLabFilepath(fullfile(proj_dir, sprintf('%s-%i-CCA_proj_%s.mat', animal{an}, sess, model_name) )); % CCA_params.name
                if true % ~proj_path_exists
                    % Get CCA projections and coefficients (NOTE THIS DOES NOT ACCOUNT FOR MULTIPLE ALIGNMENT EVENTS FOR NOW)
                    act_proj = cell(comp.n, 2); CCA_coeff = cell(comp.n, 2);
                    [~,step_half] = min(abs(CCA_result(1,1).params.t_step - 0.5));
                    for cmp = 1:comp.n
                        act_proj(cmp,:) = CCA_result(1,cmp).proj.data_intra;
                        CCA_coeff{cmp,1} = CCA_result(1,cmp).All.A(:, :, step_half, CCA_params(1,cmp).dl_zero);
                        CCA_coeff{cmp,2} = CCA_result(1,cmp).All.B(:, :, step_half, CCA_params(1,cmp).dl_zero);
                    end
                    CCA_all = [CCA_result.All];
                    r_thresh = [CCA_all.r_thresh];
                    fprintf('\nSaving %s\n', proj_path);
                    save(proj_path, 'act_resid', 'act_proj', 'CCA_params','CCA_coeff','comp','r_thresh','comp_name', '-v6'); % , '-v7.3'  , 'act_mean'
                else
                    warning('%s already exists! - skipping', proj_path)
                end
            catch err % [release] say why, instead of just "failed"
                fprintf('\n%s-%i failed: %s', animal{an}, sess, err.message) % [release]
            end
        end
    end
end

%% Load PCA results

model_name = 'full-resid_stim'; 
[proj_dir, proj_dir_exists] = ChenLabFilepath([[smroot() 'Analysis/proj/'],model_name,'\']); % CCA_params.name
[cca_name, cca_path] = FileFinder(proj_dir, 'type','mat'); % , 'sort','chron'
cca_sess = extractBefore(cca_name, '-CCA'); 
n_result = size(cca_name,1);
comp = make_comparison_struct();

% Find PCA results
[preproc_dir, preproc_dir_exists] = ChenLabFilepath([smroot() 'Analysis/preprocessing/']);
[pca_name, pca_path] = FileFinder(preproc_dir, 'type','mat'); % , 'sort','chron'
pca_sess = extractBefore(pca_name, '_');
n_PC = 30;

for r = 1:n_result % [release] was r = 63, where a previous run had been resumed
    % Loading CCA coefficients (each set is n_PC x n_CC)
    fprintf('\n\nLoading %s', cca_path{r})  
    temp_cca = load(cca_path{r});

    % Load PCA coefficients for this session (each set is n_ROI x n_PC)
    if ~isfield(temp_cca, 'roi_coeff')
        try
            r_pc = find(strcmpi(pca_sess, cca_sess{r}));
            if ~isempty(r_pc)
                fprintf('\nLoading %s', pca_path{r_pc})
                temp_pca = load(pca_path{r_pc});

                % Multiply coefficients to get ROI x canonical component matrix
                roi_coeff = cell(comp.n, 2);
                for cmp = 1:comp.n
                    roi_coeff{cmp,1} = temp_pca.PCA_coeff{comp.ind(cmp,1)}(:,1:min(size(temp_pca.PCA_coeff{comp.ind(cmp,1)},1), n_PC))*temp_cca.CCA_coeff{cmp,1};
                    roi_coeff{cmp,2} = temp_pca.PCA_coeff{comp.ind(cmp,2)}(:,1:min(size(temp_pca.PCA_coeff{comp.ind(cmp,2)},1), n_PC))*temp_cca.CCA_coeff{cmp,2};
                end

                % Save into the CCA results mat file
                fprintf('\nSaving roi_coeff into %s', cca_path{r})
                save(cca_path{r}, 'roi_coeff', '-append');
            else
                fprintf('\nNo PCA path found for %s', cca_sess{r})
            end
        catch
            fprintf('\n%s failed', cca_sess{r})
        end
    else
        fprintf('\nroi_coeff already exists')
    end
end


%%
%{
CCA_params = set_CCA_params('name','full-resid_stim-debug'); % decis_name, comp, 'decis' 'periInf-winInf-step0-none'
save_dir = ChenLabFilepath([[smroot() 'Analysis/proj/'],CCA_params.name,'\']);
mkdir(save_dir)
comp_name = comp.name;
for an = 2 %flip(1:n_animal)
    for sess = 4%intersect(sessions(an).use, sessions(an).ctrl) 
        fprintf('\n[an,sess] = [%i, %i]', an, sess)
        % Load CCA results
        [CCA_result, CCA_mat] = LoadCCA(animal{an}, sess, CCA_params, true, false);

        if ~isempty(CCA_result) 
            try
                % Load the data and perform preprocessing
                if isempty(trials{an,sess})
                    [trials{an,sess}, ~, ~, fov{an,sess}] = LoadMultiFOV(animal{an}, sess, 'drop_field',{'trial'});
                end
                % Get trial labels (and remove excluded trials)
                [~, ~, choice] = GetTrialSubsets(trials{an,sess}.all, "decision", ["Hit","Miss","CR","FA"]);
                choice(CCA_result(1).params.tr_exclude) = [];
                [~, ~, direction] = GetTrialSubsets(trials{an,sess}.all, ["direction_1_dir","direction_2_dir"], ["CW_CW", "CW_CCW", "CCW_CW", "CCW_CCW"]);
                direction(CCA_result(1).params.tr_exclude) = [];
                [~, ~, texture] = GetTrialSubsets(trials{an,sess}.all, "texture", ["200","800","1400"] );
                texture(CCA_result(1).params.tr_exclude) = [];

                % Project trial data into top 3 dimensions
                t_proj = CCA_result(1).params.t_align;
                act_proj = cell(comp.n, 2); %act_align;
                [~,step_half] = min(abs(CCA_result(1,1).params.t_step - 0.5));
                CCA_coeff = cell(comp.n, 2);
                for cmp = 1:comp.n
                    act_proj(cmp,:) = CCA_result(1,cmp).proj.data_intra;
                    CCA_coeff{cmp,1} = CCA_result(1,cmp).All.A(:,:, step_half, CCA_result(1,cmp).params.dl_zero);
                    CCA_coeff{cmp,2} = CCA_result(1,cmp).All.B(:,:, step_half, CCA_result(1,cmp).params.dl_zero);
                end

                PCA_coeff = CCA_result(1).pca.coeff;
                for a = 1:numel(PCA_coeff), PCA_coeff{a} = PCA_coeff{a}; end % (:,1:CCA_result(1).params.n_PC)

%{
                figure;
                tiledlayout('flow');
                for a = 1:comp.n
                    nexttile;
                    imagesc( mean(act_proj{a,1},3)' );
                    nexttile;
                    imagesc( mean(act_proj{a,2},3)' );
                    pause;
                end
                impixelinfo
%}

                act_align = cellfun(@permute, CCA_result(1).pca.score, repmat({[2,1,3]}, [1,numel(CCA_result(1).pca.score)]) , 'UniformOutput', false); % [CCA_result(1,1).proj.data(1,:), CCA_result(1,end).proj.data(1,:)];
%{
                figure;
                tiledlayout('flow');
                for a = 1:4
                    nexttile;
                    imagesc( mean(act_align{a},3) );
                end
                impixelinfo
%}

%{
                figure;
                tiledlayout('flow');
                for a = 1:comp.n
                    nexttile;
                    imagesc( mean(CCA_result(1,a).proj.data{1},3) );
                    nexttile;
                    imagesc( mean(CCA_result(1,a).proj.data{2},3) );
                    pause;
                end
                impixelinfo
%}

                % Save the projections and metadata
                tic
                save_path = fullfile(save_dir, sprintf('%s-%i-CCA_proj_%s.mat', animal{an}, sess, CCA_params.name) ); % CCA_params.name
                fprintf('\nSaving %s\n', save_path);
                save(save_path, 'act_align','act_proj','t_proj','comp','comp_name','choice','direction','texture','PCA_coeff','CCA_coeff', '-v6') % , '-v7.3'
                toc
            catch err % [release] say why, instead of just "failed"
                fprintf('\n%s-%i failed: %s', animal{an}, sess, err.message) % [release]
            end
        end
    end
end
%}
%%
%{
CCA_params = default_CCA_params(); % decis_name, comp, 'decis'
dim_max = 3;
proj_dir = ChenLabFilepath([smroot() 'Analysis/proj/']);
comp_name = comp.name;
for an = 1:6 %flip(1:n_animal-1)
    for sess = 1 %[6,11] %sessions(an).use %1:14 % [flip(sessions(an).ctrl), flip(sessions(an).dreadd)] % find(~cellfun(@isempty,act(an,:)))
        fprintf('\n[an,sess] = [%i, %i]', an, sess)
        % Load CCA results
        [CCA_result, CCA_mat] = LoadCCA(animal{an}, sess, CCA_params, true, false);

        % set parameters for alignment to return entire trial, aligned to second stim
        CCA_params.align_event = {'direction_2_time'}; % 'begin'; % {'direction_1_time','direction_2_time'}
        CCA_params.align_keep_lim = [];
        CCA_params.n_align = 1;

        if ~isempty(CCA_result)
            try
                % Load the data and perform preprocessing
                if isempty(act{an,sess})
                    [trials{an,sess}, ~, ~, fov{an,sess}, ~, act{an,sess}] = LoadMultiFOV(animal{an}, sess, 'drop_field',{'trial'});
                end
                [~, ~, CCA_params.trial_labels] = GetTrialSubsets(trials{an,sess}.all, ["direction_1_dir","direction_2_dir","texture"]); % for calculating residuals
                [act_proc, PCA] = prepare_CCA_data(cellfun(@permute,{act{an,sess}.trial_resamp},repmat({[2,1,3]},1,n_fov),'UniformOutput',false), CCA_params); % PCA
                [act_resid, act_align, T_align, ~, tr_exclude, CCA_params] = align_activity( act_proc, trials{an,sess}, CCA_params, false); % excluded trials are removed here
                if CCA_params.residual, act_align = act_resid;  act_resid = []; end
                act_align = cellfun(@permute, act_align, repmat({[2,1,3]},size(act_align)),'UniformOutput',false);

                % Project trial data into top 3 dimensions
                act_proj = cell(comp.n, 2); %act_align;
                t_proj = T_align{1}/30;
                for cmp = 1:comp.n
                    [~,step_half] = min(abs(CCA_result(2,cmp).params.t_step - 0.5));
                    CCA_result(2,cmp).All.A(:,1:dim_max, step_half, CCA_result(2,cmp).params.dl_zero)
                    CCA_result(2,cmp).All.B(:,1:dim_max, step_half, CCA_result(2,cmp).params.dl_zero)
                    for tr = 1:size(act_align{1,1},3)
                        act_proj{cmp,1}(:,:,tr) = act_align{1,comp.ind(cmp,1)}(:,:,tr)'*CCA_result(2,cmp).All.A(:,1:dim_max, step_half, CCA_result(2,cmp).params.dl_zero);
                        act_proj{cmp,2}(:,:,tr) = act_align{1,comp.ind(cmp,2)}(:,:,tr)'*CCA_result(2,cmp).All.B(:,1:dim_max, step_half, CCA_result(2,cmp).params.dl_zero);
                    end
                end

                % Get trial labels (and remove excluded trials)
                [~, ~, choice] = GetTrialSubsets(trials{an,sess}.all, "decision", ["Hit","Miss","CR","FA"]);
                choice(tr_exclude{1}) = [];
                [~, ~, texture] = GetTrialSubsets(trials{an,sess}.all, "texture", ["200","800","1400"] );
                texture(tr_exclude{1}) = [];
                [~, ~, direction] = GetTrialSubsets(trials{an,sess}.all, ["direction_1_dir","direction_2_dir"], ["CW_CW", "CW_CCW", "CCW_CW", "CCW_CCW"]);
                direction(tr_exclude{1}) = [];

                % Save the projections and metadata
                tic
                proj_path = fullfile(proj_dir, sprintf('%s-%i-CCA_proj.mat', animal{an}, sess) );
                fprintf('\nSaving %s\n', proj_path);
                save(proj_path, 'act_align','act_proj','t_proj','comp','comp_name','choice','direction','texture', '-v6') % , '-v7.3'
                toc
            catch err % [release] say why, instead of just "failed"
                fprintf('\n%s-%i failed: %s', animal{an}, sess, err.message) % [release]
            end
        end
    end
end
%}