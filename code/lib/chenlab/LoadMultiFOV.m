function [trials, licks, whisk, fov, fluor, act, corr_fov, fov_data] = LoadMultiFOV(animal, sess, varargin) % , fov_data{a} , glm_summ, glm_result, glm_X
% OUTPUTS:
% trials - structure containing trial level data, distinguishing imaged (im) trials from non-imaged
% licks - licking data structure array
% whisk - whisking data strucuture array
% fov - metadata about each FOV and its ROIs
% fluor - fluor data structures for each FOV
% act - deconvolved activity data structures for each FOV
[source_dir, n_fov, pct_base, f_resamp, fov_num, gamma_value, crop_size, drop_field_names, n_drop, W_dir] = parse_inputs(animal, sess, varargin{:}); 
% Initialize outputs
trials = struct('all',[], 'n_all',NaN, 'im',[], 'n_im',NaN, 'missing',[], 'n_missing',NaN, 'length',[], 'length_min',NaN, 'summary',[]);
fov = repmat(struct('name','', 'fov_name','', 'fig_dir','', 'mean',[], 'diff_max',[], 'chan_avg',[], 'framerate',NaN, 'T_trial',[], 'n_im',[], 'n_pix',[], 'um_per_pixel',[], ...
    'ROI',[], 'n_ROI',NaN, 'ROI_label',[], 'cell_ID',[], 'n_CNMF',NaN, 'roi_auto',[], 'roi_drawn',[], 'roi_mch',[], 'tr_whisk_missing',[], 'tr_exclude',[], 'tr_missing',[]), 1,n_fov); % , 'diff_mov',[]
fov_data = cell(1,n_fov); % fluor = []; act = [];  fluor = cell(1,n_fov); act = cell(1,n_fov); 
% Load the data
[mat_path, mat_path_exists] = ChenLabFilepath(sprintf('%s%s\\%s-%i.mat', source_dir, animal, animal, sess));
[whisker_path, whisker_path_exists] = ChenLabFilepath(sprintf('%s%s\\%s-%i_whisker.mat', source_dir, animal, animal, sess));
if ~whisker_path_exists, error('%s does not exist!', whisker_path); end
check_dFF = @(x)(all(isnan(x),'all'));
if mat_path_exists
    fprintf('\nLoading %s\n', mat_path); tic
    data_struct = load(mat_path); toc % , 'CaA0'  'sm045-1.mat'
    % Trial metadata
    if isfield(data_struct, 'trials') && isfield(data_struct, 'summary')
        trials.all = data_struct.trials;
        trials.n_all = numel(trials.all);
        % add useful fields
        for tr = 1:trials.n_all
            trials.all(tr).direction_1_dir = extractBefore(trials.all(tr).direction_1, ' '); %trials.all(tr).direction_1(1:find(trials.all(tr).direction_1 == ' ', 1)-1);
            trials.all(tr).direction_2_dir = extractBefore(trials.all(tr).direction_2, ' '); %trials.all(tr).direction_2(1:find(trials.all(tr).direction_2 == ' ', 1)-1);
            trials.all(tr).texture = str2double(extractAfter(trials.all(tr).direction_1, 'R'));
        end
        trials.summary = data_struct.summary;
        try
            trials.summary.table{1,find(strcmpi(trials.summary.table(1,:), "CCD idx"))} = 'CCD_idx'; %#ok<FNDSB>
            trials.summary.table = cell2table(trials.summary.table(2:end,:), 'VariableNames',trials.summary.table(1,:));
            for i = 1:height(trials.summary.table)
                if isempty(trials.summary.table.CCD_Name{i})
                    trials.summary.table.CCD_Name{i} = '';
                end
            end
        catch
            fprintf('\nIssues with trials summary table')
        end
    else
        error('Need trials data to proceed')
    end

    % Get whisking and licking data
    [licks,~] = get_licks(data_struct);  % n_trial_licks
    [whisk, ~, tr_whisk_missing] = get_whisk(whisker_path, trials); % n_whisk

    % [release] cleaned session files carry these values as CaA<k>.xml_params; read
    % [release] parameters.xml from the acquisition server only for older files
    use_xml = ~isfield(data_struct.CaA0, 'xml_params'); % [release]
    if use_xml % [release]
        % Read parameters.xml file
        [~,behav_dir] = FileFinder(ChenLabFilepath(sprintf('%s%s\\2P\\%s-%i\\',W_dir, animal, animal, sess)), 'type',0, 'contains','Behavior');
        [~, params_path] = FileFinder(behav_dir{1}, 'type','xml', 'contains','parameters');
        %fprintf('\nReading %s', params_path{1})
        params = parseXML(params_path{1}); % xmlread
        stage_params = params.Children(strcmpi({params.Children.Name}, 'stage'));
    end % [release]

    % FOV-level metadata
    % [release] per-FOV figure folders go under results/, not into the data tree
    for a = fov_num
        %fprintf('\nGetting fov %i data', a-1);
        fov_data{a} = data_struct.(sprintf('CaA%i', a-1));
        fov(a).name = sprintf('%s-%i-A%i', animal, sess, a-1);
        fov(a).fov_name = sprintf('A%i',a-1);
        fov(a).fig_dir = smout(sprintf('figures/%s/%s', animal, fov(a).name)); % [release] was <data>/Animals/<animal>/Figures/
        fov(a).n_im = sum(~cellfun(check_dFF, fov_data{a}.F_df_REF)); % find(cellfun(check_dFF, fov_data{a}.F_df_REF)) %numel(fov_data{a}.F_dF); % F_df_REF
        % Get deep interp projections (mean and max diff)
        %{
        try
            [fov(a).mean, fov(a).diff_max] = UnpackDeepInterp(W_dir, animal, sess, a-1, 'show',false); %
        catch
            fprintf('\nUnpackDeepInterp failed')
        end
        %}
        fov(a).n_pix = [330 480]; % size of the deep-interp movie = [330 480], original size = [350, 534] pix   (fov(a).mean);
        fov(a).um_per_pixel = [550, 350]./[350, 534]; % conversions, per Mitch: ~350um in X and ~550um in Y, left is anterior, top is medial
        fov(a).framerate = fov_data{a}.sampling_rate; % (a)
        
        % Read area-specific parameters from the xml file (per Mitch, MicronPerPixel fields are wrong and the Framerate_Hz field is only a rough estimate)
        if ~use_xml % [release] same values, baked in by tools/build_session_file.m
            fov(a).params = rmfield(fov_data{a}.xml_params, 'source'); % [release]
        else % [release]
            area_params = params.Children(string({params.Children.Name}) == sprintf('area%i',a-1)); % 'area0'
            arm_params = area_params.Children(strcmpi({area_params.Children.Name}, 'framearm'));
            fov(a).params.Framerate_Hz = area_params.Children(string({area_params.Children.Name}) == 'Framerate_Hz').Children.Data;
            fpu_xy = area_params.Children(string({area_params.Children.Name}) == 'fpuxystage').Children;
            fov(a).params.Xpos = str2double( fpu_xy(strcmpi({fpu_xy.Name}, 'XPosition_um') ).Children.Data ); % fpuxystage -> XPosition_um
            fov(a).params.Ypos = str2double( fpu_xy(strcmpi({fpu_xy.Name}, 'YPosition_um') ).Children.Data ); % fpuxystage -> YPosition_um
            % 2 versions of offsets appear under the framearm node, USE THE SECOND PAIR
            fov(a).params.Xoffset = str2double( arm_params.Children(find(strcmpi({arm_params.Children.Name}, 'XOffset_Fraction'),1, 'last')).Children.Data );
            fov(a).params.Yoffset = str2double( arm_params.Children(find(strcmpi({arm_params.Children.Name}, 'YOffset_Fraction'),1, 'last')).Children.Data );
            fov(a).params.Xstage = str2double( stage_params.Children((strcmpi({stage_params.Children.Name}, 'XPosition_um'))).Children.Data );
            fov(a).params.Ystage = str2double( stage_params.Children((strcmpi({stage_params.Children.Name}, 'YPosition_um'))).Children.Data );
        end % [release]

        % Get red/green channel projections from step4
        preproc_dir = ChenLabFilepath(sprintf('%s%s\\2P\\%s-%i\\PreProcess\\',W_dir, animal, animal, sess));
        [~,chan_avg_path] = FileFinder(preproc_dir, 'contains',{'Avg',sprintf('A%i',a-1)}, 'exclude',{'Avg1','Avg2a'});
        if numel(chan_avg_path) == 2 %~isempty(chan_avg_path) &&
            fov(a).chan_avg = [];
            for ch = 2:-1:1
                %fprintf('\nLoading %s', chan_avg_path{ch})
                fov(a).chan_avg(:,:,ch) = loadtiff(chan_avg_path{ch});
            end
            % crop to match deepinterp results %if ~isempty(fov(a).mean)
            size_chan = size(fov(a).chan_avg, [1,2]);
            size_deep = fov(a).n_pix; %[330,480]; %size(fov(a).mean, [1,2]);
            size_margin = (size_chan-size_deep)/2;
            fov(a).chan_avg = fov(a).chan_avg(size_margin(1)+1:end-size_margin(1), size_margin(2)+1:end-size_margin(2), :);
            fov(a).chan_avg(end,end,3) = 0; % add blue cahnnel for imshow
        else
            warning('\nFailed to get step 4 images')
        end
        % Which ROIs are deemed mCherry+?
        if isfield(fov_data{a}, 'celltype_REF_angle') % celltype_REF_new
            fov(a).roi_mch = find(fov_data{a}.celltype_REF_angle)'; % fov_data{a}.celltype_REF_new
        end

        % Check for trials with missing/excluded IMAGING data
        fov(a).tr_whisk_missing = tr_whisk_missing; %fov(a).tr_exclude = []; fov(a).tr_missing = [];
        if fov(a).n_im ~= trials.n_all
            fprintf('\nArea %i 2P data missing %i trials', a-1, trials.n_all-fov(a).n_im)
            % Which trials were excluded?
            [fov_exclude_dir, fov_exclude_exists] = ChenLabFilepath(sprintf('%s\\PreProcess\\A%i_Ch1\\exclude\\',fov_data{a}.sessionfoldername, a-1));
            if fov_exclude_exists
                fov_exlude_name = FileFinder(fov_exclude_dir, 'type','mat');
                fov_exlude_stamp = extractAfter(fov_exlude_name, sprintf('A%i_Ch1_',a-1));
                %lick_time = [licks.time];
                for x = 1:numel(fov_exlude_stamp)
                    temp_time = datetime(fov_exlude_stamp{x}, "Format","HH-mm-ss");
                    time_diff = seconds([licks.time] - temp_time); %
                    time_diff(time_diff > 0) = Inf; % lick timestamp must precede movie timestamp
                    [min_diff, tr_min_diff] = min(abs(time_diff));
                    fov(a).tr_exclude = [fov(a).tr_exclude, tr_min_diff];
                    fprintf('\nExcluded timestamp %s matched to trial %i (licking = %s, %2.1f second difference)', fov_exlude_stamp{x}, tr_min_diff, licks(tr_min_diff).time_stamp, min_diff )
                end
            end
            % Find trials that were not excluded but where imaging data is missing
            a_idx_name = sprintf('A%i_idx', a-1);
            if iscell(trials.summary.table.(a_idx_name))
                temp_cell = trials.summary.table.(a_idx_name);
                fov(a).tr_missing = [find(cellfun(@isempty, temp_cell))', setdiff(1:trials.n_all, trials.summary.table.Trial)]; 
            elseif isnumeric(trials.summary.table.(a_idx_name)) || islogical(trials.summary.table.(a_idx_name))
                temp = trials.summary.table.(a_idx_name);
                fov(a).tr_missing = [find(isempty(temp)), setdiff(1:trials.n_all, trials.summary.table.Trial)];
            end
        end
    end
    %clearvars data_struct % remove once elements (fovs, trials, licks summary) have been copied

    % Take stock of missing/incomplete/excluded trials
    tr_missing = unique([[fov.tr_missing], [fov.tr_exclude], tr_whisk_missing]); % setdiff(1:trials.n_all, tr_mov); % indices of trials that were not matched to movies
    trials.im = trials.all; % (tr_mov)
    trials.im(tr_missing) = []; % subset of trials with complete imaging of all areas + whisker data, for GLM
    trials.n_im = numel(trials.im);
    trials.missing = trials.all(tr_missing);
    trials.n_missing = numel(tr_missing);
    % fields to be filled in by get_ca_signals below
    trials.length = nan(trials.n_all, n_fov); 
    for tr = 1:trials.n_all, trials.all(tr).events = cell(1,n_fov); end % placeholder for trial events info
   
    % Get ROI data, calcium signals, and trial events, if called
    for a = fov_num %flip(1:n_fov)
        fov(a) = get_ROIs(fov_data{a}, fov(a), gamma_value, crop_size); % Get ROIs and info about them
        if nargout > 5
            [fluor(a), act(a), trials, fov(a)] = get_ca_signals(fov_data{a}, trials, fov(a), pct_base);  % {a}
        end
    end
    % Resample the data -> f_resamp Hz, so that all areas are sampled equally
    if nargout > 5
        [fov, act, trials] = resample_activity(fov, act, trials, 'rate',f_resamp, 'show',false, 'save',smout('figures'));
    end

    % Assess correlation within and between areas
    if nargout > 6
        [fov, act, corr_fov] = get_interfov_corr(fov, act, 'show',false, 'save',smout('figures'));
    else
        corr_fov = [];
    end

    % Drop specific fields of activity to save memory
    if nargout > 5 && n_drop > 0
        %fprintf('\nDropping %s', drop_field_names{:}) %  strcat(drop_field_names{:}, ' ')
        act = drop_fields(act, drop_field_names); % rmfield(act, drop_field_names); % drop_fields instead of rmfields in case some fields aren't present
        for a = fov_num % 1:n_fov
            act(a).z = drop_fields(act(a).z, drop_field_names);
            fluor(a).F = drop_fields(fluor(a).F, drop_field_names);
            fluor(a).filt = drop_fields(fluor(a).filt, drop_field_names);
            fluor(a).dFF = drop_fields(fluor(a).dFF, drop_field_names);
            fluor(a).z = drop_fields(fluor(a).z, drop_field_names); 
        end
    end
    toc
else
    error('\nNo .mat file found!'); 
end
end

%INPUT PARSER--------------------------------------------------------------
function [source_dir, n_fov, pct_base, f_resamp, fov_num, gamma_value, crop_size, drop_field_names, n_drop, W_dir] = parse_inputs(anm, session_num, varargin)
IP = inputParser;
addRequired( IP, 'anm', @ischar )
addRequired( IP, 'session', @isnumeric )  % @ischar % @(x)(ischar(x) || isnumeric(x))
addParameter( IP, 'source', [smroot() 'Animals/'], @ischar )  %  'W:\\Projects\\Sensorimotor\\Animals\\'
addParameter( IP, 'n_fov', 4, @isnumeric )
addParameter( IP, 'pct_base', 10, @isnumeric )
addParameter( IP, 'f_resamp', 30, @isnumeric )
addParameter( IP, 'gamma', 0.2, @isnumeric )
addParameter( IP, 'crop', [50,50], @isnumeric )
addParameter( IP, 'fov_num', [], @isnumeric ) % which fovs to load? default to all of them
addParameter( IP, 'drop_field_names', {}, @iscell )
parse( IP, anm, session_num, varargin{:} );
% Set parameters
source_dir = ChenLabFilepath(IP.Results.source);
n_fov = IP.Results.n_fov;
pct_base = IP.Results.pct_base;
f_resamp = IP.Results.f_resamp;
fov_num = IP.Results.fov_num;
if isempty(fov_num), fov_num = flip(1:n_fov); end
gamma_value = IP.Results.gamma; %0.2;
crop_size = IP.Results.crop; %[50,50];
drop_field_names = IP.Results.drop_field_names;
n_drop = numel(drop_field_names);
[W_dir, ~] = ChenLabFilepath('W:\Projects\Sensorimotor\Animals\'); % sprintf('W:\\Projects\\Sensorimotor\\Animals\\%s\\', anm )
end