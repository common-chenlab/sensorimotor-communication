function CHEN_2P_Pipeline_Step_07(session_mat_path, indicator, microscope, varargin) % , animal1, tau_d, tau_r , ref_ROI, subsession, slackID , area_num  animal, session_num
% Performs deconvolution on CNMF or REF data, including (optional) suppression of crosstalk artifact
% REQUIRED INPUTS
% session_mat_path = path to session mat file that contains dF/F data
% indicator = which calcium indicator was used? this will set the time constants and spike_thresh used for deconvolution. options are  'ycamp', 'rcamp', 'rcamp_connectomics' or 'gcamp8m'
% microscope = which microscope was used? 'multi1' or 'multi2'. if multi2, notch filtering will be applied to fluor signals prior to deconvolution
% OPTIONAL NAME-VALUE PARAMETERS
% area = which area to use? multi-area1 (0 or 1) or multi-area 2 (0-3). default = 0
% overwrite = if deconvolved signals are already saved in the mat file, should they be overwritten? true or false (default)
% slack = send a slack message when done? true (default) or false 
% deconv parameters
% ROI_type = set to 'ref' (default) to use curated ROIs? otherwise, CNMF ROIs will be used
% thresh_min = threshold value for normalized deconvolved signal
% base_thresh = percentile used for thresholding  deconvolved signal. see deconvolveCaE.m
% base_window = width of window used for baseline subtraction - concatenated case only seconds
% base_ntrials = # of trials pooled (current +/- neighbours) to estimate the per-trial baseline & noise for DISCRETE trials. default 3. set to 1 for legacy per-trial behaviour. see subtract_baseline
% min_dur = minimum duration (seconds) for a trial to be included. default = 4 seconds
% concatenate = should trials be concatenated prior to decovolution? outputs will then be de-concatenated after deconvolution. this is intended for SLM experiments. default = false

% Housekeeping - add dependencies, parse inputs, and set the parameters for deconvolution
%add_pipeline_paths();
if isempty(session_mat_path),  error('session_mat_path is empty!');  end
[session_name, area_name, overwrite, slack_toggle, deconv_params] = parse_inputs(session_mat_path, indicator, microscope, varargin{:}); 

% load data
fprintf('\nReading data (%s) from %s', area_name, session_mat_path);
tic
session_mat_file = matfile(session_mat_path, 'Writable', true);
Ca = session_mat_file.(area_name);
toc

% check if the deconvolution needs to be redone
ref_ROI = strcmpi(deconv_params.ROI_type, 'ref');
if (ref_ROI && isfield(Ca, 'deconv_REF') && ~overwrite) || (~ref_ROI && isfield(Ca, 'deconv') && ~overwrite)
    fprintf('\nDeconvolution already done and overwrite is disabled - aborting\n')
    return;
end

% perform the deconvolution
setup_parpool_SCC(); % setup parallel processing
tic
Ca = deconvolve_traces(Ca, deconv_params); % /Analysis Suite/PIPELINE/2P/deconvolve_traces.m
toc

% save the results
fprintf('\nUpdating %s of %s... ', area_name, session_mat_path)
session_mat_file.(area_name) = Ca;
toc
fprintf('\n');

% send slack notification
if slack_toggle
    SendSlackNotification('REDACTED_SLACK_WEBHOOK', ...
        sprintf('2P PIPELINE STEP 07 is finished: %s %s', session_name, area_name), '#e_pipeline_log');
end

end

% SUBFUNCTIONS
%INPUT PARSER-----------------------------------------------------
function [session_name, area_name, overwrite, slack_toggle, deconv_params] = parse_inputs(session_mat_path, indicator, microscope, varargin) 
check_input = @(x)(ischar(x) || isnumeric(x));
IP = inputParser;
addRequired( IP, 'session_mat_path', @ischar) % path to session mat file that contains dF/F data
addRequired( IP, 'indicator', @ischar ) % ycamp, gcamp8m, 
addRequired( IP, 'microscope', @ischar )  % multi1, multi2 or voltage
addParameter( IP, 'area', 0, check_input ) % which area to use? multi-area1 or 2
addParameter( IP, 'denoised', true, @islogical ) % use the denoised (Deep interp) version of data?
addParameter( IP, 'overwrite', false, @islogical ) % if deconvolved signals are already saved in the mat file, should they be overwritten?
addParameter( IP, 'slack', true, @islogical ) % send a slack message when done?
% deconv parameters
addParameter( IP, 'ROI_type', 'REF', @ischar ) % use curated ("ref") ROIs? otherwise, CNMF ROIs will be used
addParameter( IP, 'thresh_min', 0.1, @isnumeric )
addParameter( IP, 'base_thresh', 10, @isnumeric ) % percentile used for baseline subtraction. see subtract_baseline
addParameter( IP, 'base_window', 10, @isnumeric ) % width of window used for baseline subtraction, in seconds - concatenated case only.  see subtract_baseline
addParameter( IP, 'base_ntrials', 3, @isnumeric ) % # trials pooled (current +/- neighbours) to estimate per-trial baseline & noise (discrete trials). 1 = legacy per-trial. see subtract_baseline
addParameter( IP, 'min_dur', 4, @isnumeric ) % seconds, trace must last at least this long
addParameter( IP, 'concatenate', false, @islogical ) 
parse( IP, session_mat_path, indicator, microscope, varargin{:} );

area_name = ['CaA', num2str(IP.Results.area)];
[~,session_name] = fileparts(session_mat_path);
use_denoise = IP.Results.denoised;
overwrite = IP.Results.overwrite;
slack_toggle = IP.Results.slack;

% SET DECONVOLUTION PARAMETERS
signal_type = 'raw';
if use_denoise
    signal_type = 'denoised';
end

% set indicator-specific parameters
if strcmpi(indicator, 'ycamp') || strcmpi(indicator, 'rcamp')
    tau_d = 1800; 
    tau_r = 100; 
    spike_thresh = 1;
elseif strcmpi(indicator, 'gcamp8m')
    tau_d = 1000;
    tau_r = 50;
    spike_thresh = 1.5;
elseif strcmpi(indicator, 'rcamp_connectomics') || strcmpi(indicator, 'rcamp')
    tau_d = 1000; 
    tau_r = 100; 
    spike_thresh = 1.5;
elseif strcmpi(indicator, 'marmoset')
    tau_d = 600; 
    tau_r = 50; 
    spike_thresh = 5;
else
    error('indicator not recognized!')
end

% set microscope-specific parameters
if strcmpi(microscope, 'multi2')
    notch_freq = 1.5; % Hz, to suppress laser crosstalk artifact in SM data - 1.5 Hz. set to NaN to disable
    notch_Q = 2; % Q factor for notch, see iirnotch documentation
else
    notch_freq = NaN;
    notch_Q = NaN;
end

deconv_params = struct(...
    'ROI_type', IP.Results.ROI_type, ...  % 'REF' or 'CNMF'
    'signal_type', signal_type, ...
    'concatenate', IP.Results.concatenate, ...
    'microscope', microscope, ...
    'indicator', indicator, ...
    'tau_r', tau_r, ...
    'tau_d', tau_d, ...
    'spike_thresh', spike_thresh, ...
    'thresh_min', IP.Results.thresh_min, ...
    'base_thresh', IP.Results.base_thresh, ...
    'base_window', IP.Results.base_window, ...
    'base_ntrials', IP.Results.base_ntrials, ...
    'base_frames', NaN, ...
    'min_dur', IP.Results.min_dur, ...
    'notch_freq', notch_freq, ...
    'notch_Q', notch_Q);
end