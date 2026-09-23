function CCA_params = set_CCA_params(varargin)
check_text = @(x) ( ischar(x) || isstring(x) );
IP = inputParser;
addParameter( IP, 'name', '', check_text )
addParameter( IP, 'n_trial_min', 100, @isnumeric )
addParameter( IP, 'frame_dur', 1/30, @isnumeric ) %  seconds
addParameter( IP, 'filt_sigma', 0.05, @isnumeric ) % std dev of gaussian blurring applied to the data, seconds. set to NaN to skip filtering
addParameter( IP, 'gauss_filt', [], @isnumeric )
addParameter( IP, 'standardize', true, @islogical ) 
addParameter( IP, 'exclude','none', check_text)
addParameter( IP, 'ROI_exclude', cell(1,4), @iscell) % []  % isnumeric
addParameter( IP, 'n_PC', 30, @isnumeric)
addParameter( IP, 'PCA_params', struct('dim_max',NaN, 'standardize',true), @isstruct) % CCA_params.n_PC
addParameter( IP, 'suppress', 'none', check_text)  % 'none', 'mch', or 'ctrl'
%addParameter( IP, 'resid', true, @islogical ) 
addParameter( IP, 'resid_type', 'stim', @ischar ) % 'split','stim','lick','stim_lick','all','none'
addParameter( IP, 'resid_std', false, @islogical )  % should the residuals be standardized (z-scored after pooling trials)?
addParameter( IP, 'align_event', {'direction_1_time','direction_2_time'}, check_text )
addParameter( IP, 'align_keep_lim', [90,90], @isnumeric )
addParameter( IP, 'trim_NaN', false, @islogical ) 
addParameter( IP, 'BinWidth', 1, @isnumeric )
addParameter( IP, 'WindowLength', 15, @isnumeric )
addParameter( IP, 'TimeStep', 3, @isnumeric )
addParameter( IP, 'DelayStep', 3, @isnumeric )
addParameter( IP, 'MaxDelay', 12, @isnumeric )
addParameter( IP, 'min_ratio', 0, @isnumeric )
addParameter( IP, 'n_cv', 10, @isnumeric )
addParameter( IP, 'cv_style', 'semedo',  check_text ) %'han'; % Han method does resampling, not cross-validation. less conservative
addParameter( IP, 'n_shuff', 96, @isnumeric )
addParameter( IP, 'show', false, @islogical )
addParameter( IP, 'show_corr', '', check_text )
addParameter( IP, 'comp', make_comparison_struct(), @isstruct )
addParameter( IP, 'decis_type', 'decis', check_text ) % 'decis', 'correct', or 'none'/empty
addParameter( IP, 'balance', 'off', check_text )
addParameter( IP, 'n_balance', NaN, @isnumeric )
addParameter( IP, 'decis_include', NaN, @isnumeric )
addParameter( IP, 'decis_min', 10, @isnumeric )
addParameter( IP, 'proj_data', false, @islogical )
addParameter( IP, 'dim_max', 6, @isnumeric ) % use this many CCA dimensions, at most, when projecting data into CCA space
parse( IP, varargin{:} );

CCA_params = struct('name',''); % intialize name here to keep at the top of the struct
CCA_params.comp = IP.Results.comp;
% Preprocessing parameters
CCA_params.frame_dur = IP.Results.frame_dur;
CCA_params.filt_sigma = IP.Results.filt_sigma;
CCA_params.gauss_filt = IP.Results.gauss_filt;
if ~isnan(CCA_params.filt_sigma), CCA_params.gauss_filt = MakeGaussFilt( (1/CCA_params.frame_dur), 0.5, 0, CCA_params.filt_sigma, 'show',false); end
CCA_params.exclude = IP.Results.exclude; %'none';
CCA_params.ROI_exclude = IP.Results.ROI_exclude;
% alignment params
CCA_params.align_event = string(IP.Results.align_event); % align to these trial events
CCA_params.n_align = numel(CCA_params.align_event); 
CCA_params.align_keep_lim = IP.Results.align_keep_lim; % how many frames before/after the alignment event to retain
CCA_params.trim_NaN = IP.Results.trim_NaN;
CCA_params.t_align = [];
CCA_params.tr_exclude = [];
CCA_params.n_trial_min = IP.Results.n_trial_min; 
% PCA params
CCA_params.n_PC = IP.Results.n_PC;
CCA_params.PCA_params = IP.Results.PCA_params;
CCA_params.PCA_params.dim_max = IP.Results.n_PC;
CCA_params.PCA_params.standardize = IP.Results.standardize;
CCA_params.suppress_mch = IP.Results.suppress; %false;
CCA_params.roi_suppress = cell(1,4);

% residualization params
%CCA_params.resid = IP.Results.resid; % set to true to subtract ROI-and-trial-subtype-specific average traces from each trial
CCA_params.resid_type = IP.Results.resid_type;
CCA_params.resid_std = IP.Results.resid_std; 
CCA_params.resid_labels = []; 
CCA_params.resid_label_names = [];
CCA_params.resid_tr = []; % indices of the trials that were averaged to calculate the residual
CCA_params.n_trial_resid = [];
CCA_params.split_frame = [];

% CanonicalCrossCorrelation parameters. delays and timesteps are in units of frames, not seconds
CCA_params.BinWidth = IP.Results.BinWidth;
CCA_params.WindowLength = IP.Results.WindowLength;
CCA_params.TimeStep = IP.Results.TimeStep;
CCA_params.DelayStep = IP.Results.DelayStep;
CCA_params.MaxDelay = IP.Results.MaxDelay; % 3; %
CCA_params.win_lim = [];
CCA_params.n_step = NaN;
CCA_params.t_step = [];
CCA_params.delay_shift = [];
CCA_params.t_delay = []; 
CCA_params.n_delay = NaN;
CCA_params.dl_zero = NaN;
CCA_params.n_pair = NaN;

CCA_params.min_ratio = IP.Results.min_ratio; % minimum ratio of rows to total features (combining X and Y)
%CCA_params.CrossValidate = IP.Results.CrossValidate;
CCA_params.n_cv = IP.Results.n_cv;
CCA_params.cv_style = IP.Results.cv_style; 
CCA_params.n_shuff = IP.Results.n_shuff;
CCA_params.show = IP.Results.show;
CCA_params.show_corr = IP.Results.show_corr; % 

% Parameters for decision-based subsetting
CCA_params.decis_type = IP.Results.decis_type; %"correct"; %"decis"; % set to "decis" to use decisions, "correct" to use outcomes ("Correct","Incorrect")
CCA_params.decis_labels = []; 
if isempty(CCA_params.decis_type) || strcmpi(CCA_params.decis_type, "none")
    CCA_params.decis_name = '';
    CCA_params.sub_name = "All";
elseif strcmpi(CCA_params.decis_type, "decis")
    CCA_params.decis_name = ["Hit","CR","Miss","FA"]; 
    CCA_params.sub_name = ["All", CCA_params.decis_name];
elseif strcmpi(CCA_params.decis_type, "correct")
    CCA_params.decis_name = ["Correct","Incorrect"];
    CCA_params.sub_name = ["All", CCA_params.decis_name];
else
    error('decis_type must be set to "none"/empty, "decis" or "correct"')
end
CCA_params.n_decis = numel(CCA_params.decis_name);
CCA_params.field_names = [CCA_params.sub_name, "proj", "params"]; % CCA_result struct will have these fields 

% parameters for decision balancing (rebalancing doesn't seem to help - probably obsolete)
CCA_params.decis_balance = IP.Results.balance; %'max'; % 'min'; % set to 'max', 'min', 'off', or a # of trials to balance to
CCA_params.n_balance = IP.Results.n_balance;
CCA_params.decis_include = IP.Results.decis_include; % include only this many trials, randomly selected without replacement
CCA_params.decis_min = IP.Results.decis_min; % must have at least this many of each decision type to rebalance

% 
CCA_params.proj_data = IP.Results.proj_data;
CCA_params.dim_max = IP.Results.dim_max;

% Assign a name to the model
if isempty(IP.Results.name)
    CCA_params.name = sprintf('peri%i-win%i-step%i-%s', CCA_params.align_keep_lim(1), CCA_params.WindowLength, CCA_params.TimeStep, CCA_params.decis_type); 
else
    CCA_params.name = IP.Results.name;
end

end