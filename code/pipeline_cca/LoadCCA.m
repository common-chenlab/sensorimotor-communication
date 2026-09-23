function [CCA, CCA_mat, run_mat] = LoadCCA(animal, sess, CCA_params, gather_only, overwrite)
% CCA_params can be entered as a model name only, in which case LoadCCA will only load an existing model file (gather_only)
if ischar(CCA_params) || isstring(CCA_params)
    CCA_params = struct('name',string(CCA_params), 'n_align',1); 
    gather_only = true;
elseif ~isstruct(CCA_params)
    error('CCA_params must be either a structure with the appropriate CCA_params fields (see set_CCA_params) OR the name of an existing CCA model available for this animal-session to be loaded')
end
if gather_only, overwrite = false; end
save_dir{1,1} = ChenLabFilepath([smroot() 'Animals' filesep animal filesep 'CCA' filesep]); % [release] was sprintf, which read a Windows data root's backslashes as escapes
save_dir{2,1} = save_dir{1,1}; % [release] was the lab cluster's own copy of the data tree, which readers do not have % the main folder for storing CCA individual results
% cellfun(@mkdir, save_dir)
env_ind = isunix + 1; % 1 if pc, 2 if unix (SCC)

CCA = []; CCA_mat = [];
try
    % Check if the data already exists
    check_paths = strcat(save_dir, sprintf('%s-%i-CCA_results-%s.mat', animal, sess, CCA_params.name));
    check_exists = cellfun(@exist,check_paths)';

    % Check the file size for any existing files and ignore blank files (bytes for empty file currently 68896)
    file_size = zeros(1,2);
    for env = find(check_exists)
        temp_info = dir(check_paths{env});
        file_size(env) = temp_info.bytes;
        if file_size(env) < 10^5, check_exists(env) = false; end 
    end

    % Determine which file to use
    if check_exists(env_ind)
        % If a good file exists for this environment, use it
        check_path_ind = env_ind; % find(check_exists, 1, "first");
    elseif ~check_exists(env_ind) && any(check_exists) && ~overwrite
        % If a file exists, but only based in the other environment, copy it to the appropriate space 
        if ~exist(save_dir{1,1}, 'dir'), mkdir(save_dir{1,1}); end
        fprintf('\nCopying %s to %s',check_paths{find(check_exists)}, check_paths{env_ind});
        copyfile(check_paths{find(check_exists)}, check_paths{env_ind});
        check_path_ind = env_ind; % find(check_exists, 1, "first");
    else
        check_path_ind = find(check_exists, 1, "first");
    end

    if ~overwrite && ~isempty(check_path_ind)
        % If the file exists and we're not going to overwrite it, load it and fill in any fields that may be missing
        mat_path = check_paths{check_path_ind};
        fprintf('\nLoading and opening %s ...', mat_path); 
        tic
        CCA_mat = matfile(mat_path,  'Writable', true); % CCA_result =
        CCA = CCA_mat.CCA;
        CCA_params = CCA(1).params; % use params embedded in the results file
        toc
    elseif ~gather_only % If the file doesn't exist, but we plan to make it, set that up here
        % Set up the CCA structure template
        CCA_template = struct("data_name","", "timestamp",''); % , "trials",[], "pca",[]
        if ~isempty(CCA_params.field_names)
            for f = CCA_params.field_names, CCA_template.(f) = [];  end
        end
        if isunix,  mat_path = check_paths{2};  else,  mat_path = check_paths{1}; end
        CCA = repmat(CCA_template, CCA_params.n_align, CCA_params.comp.n); % CCA_params.phase.n
        
        mat_dir = fileparts(mat_path);
        fprintf('\nCreating and opening %s...', mat_path);
        if ~exist(mat_dir, 'dir'), mkdir(mat_dir); end
        
        sm_assert_writable(); % [release]
        save(mat_path, 'CCA', '-v7.3')
        CCA_mat = matfile(mat_path,  'Writable', true);
    else
        sprintf('%s not found and gather_only is true - returning empty', mat_file)
    end
catch
    fprintf('\n%s-%i failed - returning empty', animal, sess);
end

% determine if any cases (comparisons or events) still need to be analyzed
if gather_only
    if isfield(CCA_params, 'comp') % [release] a name-only call has no comp field
        run_mat = false(CCA_params.n_align, CCA_params.comp.n); % % when gather only is set, don't run any further analyses
    else % [release]
        run_mat = false; % [release] gather_only never runs anything anyway
    end % [release]
elseif overwrite || isempty(CCA) || ~isequal(size(CCA), [CCA_params.n_align, CCA_params.comp.n]) %#ok<*UNRCH>
    run_mat = true(CCA_params.n_align, CCA_params.comp.n); % when gather_only is disabled and overwrite is on, run all analyses
else
    run_mat = cellfun(@isempty, reshape({CCA.timestamp}, CCA_params.n_align, CCA_params.comp.n)); % otherwise, only run unanalyzed phases/inter-FOV comparisons
end