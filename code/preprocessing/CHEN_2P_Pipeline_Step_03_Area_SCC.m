function bad_ROI = CHEN_2P_Pipeline_Step_03_Area_SCC(source_dir, target_dir, animal, session_num, area_num, varargin) % , sub_site, use_denoise, slackID
% this function extracts the fluor signals from curated ROIs
%cam added sub_site variable to accomodate subsession folder formats. exclude it from inputs or set to '' and should function as normal
% David added use_denoise variable to allow use of deepInterpolation output
% Andrew changed input parsing, added toggle for whether to delete _dp files after extraction, and (possible) saving area results to separate files to avoid writing permission issues.
% 7/27. Andrew 
% If separate area-level mat files (eg sm052-3-A0.mat, sm052-3-A1.mat etc) are generated, use RecombineAreas function (on a machine with write permission) to merge them back to a single mat file

% Housekeeping - add dependencies, parse inputs and set up file paths
%add_pipeline_paths(); % Z:\Dropbox\Dropbox\Chen Lab Team Folder\Analysis Suite\PIPELINE\add_pipeline_paths.m
[source_folder, save_folder, animal, session_name, session_mat_path, trial_paths, area_num, area_chan, area_fieldname, downsample_f, slackID, use_denoise, overwrite, erase_dp] = ...
    parse_inputs(source_dir, target_dir, animal, session_num, area_num, varargin{:});  %parse inputs
% Open the session's mat file and load the area's Ca data
fprintf('\nOpening %s', session_mat_path)
session_mat_file = matfile(session_mat_path, 'Writable', true);
Ca = session_mat_file.(area_fieldname); 

% Check whether the extraction needs to be redone
if isfield(Ca, 'F_df_REF') && ~overwrite 
    fprintf('\nF_df_REF already exists and overwrite is disabled - returning\n')
    return;
end

% Check that the number of trial mat files matches the number of trials
n_trial_mat = numel(trial_paths);
n_trial = numel([Ca.trial_info{:}]);
if n_trial_mat < n_trial
    warning('Found only %i source files for %i trials', n_trial_mat, n_trial)
elseif n_trial_mat > n_trial
    error('Found more source files than trials - something is wrong')
end

% populate cellid, ROI, and create Anew
if ~isfield(Ca,'cellid_REF')
    warning('cellid_REF is missing - using CNMF results instead')
    Ca.cellid_REF = Ca.cellid;
    for r = 1:length(Ca.ROIs)
        Ca.ROIs_REF{r} = fliplr(Ca.ROIs{r}');
    end
end

ROI_mask_local = zeros(Ca.FOV(1), Ca.FOV(2), length(Ca.cellid_REF));
bad_ROI = [];
for j = 1:length(Ca.ROIs_REF)
    try
        ROI_mask_local(:,:,j) = ROI_boundary2mask(Ca.ROIs_REF{j}, Ca.FOV); % flip(,2)  imshow(ROI_mask_local(:,:,j), [])
    catch
        fprintf('\nROI %i out of bounds', j);
        bad_ROI = [bad_ROI, j];
    end
end
if ~isempty(bad_ROI), return, end % bad ROIs cause extract_f to throw an error 

Anew = reshape(ROI_mask_local, [], size(ROI_mask_local,3));

% extract fluor signals
[b, options] = estimate_background(Ca, source_folder, area_chan, downsample_f, trial_paths, use_denoise);

fprintf('\nExtracting the fluorescence signals');
tic
[~, F_us] = extract_f(Anew, b, trial_paths, options);
Ca.F_df_REF = F_us; % note this signal is F, NOT actually dF/F

% Update the main mat file, or save the results to a temporary file
try
    fprintf('\nUpdating %s of %s... ', area_fieldname, session_mat_path)
    session_mat_file.(area_fieldname) = Ca;
catch
    save_mat_path = sprintf('%s%s%s-%s.mat', save_folder, filesep, session_name, area_fieldname);
    fprintf('\nUpdate failed (permission denied?)\nSaving Ca to %s', save_mat_path)
    save(save_mat_path, 'Ca');
end
toc
%}

% Erase the deep interp files (optional), and send a slack notification
%dp_check(Ca, source_dir, animal, session_name, area_chan, erase_dp, slackID) %dp_check(source_dir, target_dir, animal, session_num, area_chan, erase_dp, slackID);
toc
end

% SUBFUNCTIONS
%INPUT PARSER--------------------------------------------------------------
function [source_folder, save_folder, animal, session_name, session_mat_path, trial_mat_paths, area_num, area_chan, area_fieldname, downsample_f, slackID, use_denoise, overwrite, erase_dp] = ...
    parse_inputs(source_dir, target_dir, animal, session_num, area_num, varargin)
IP = inputParser;
addRequired( IP, 'source_dir', @ischar ) 
addRequired( IP, 'target_dir', @ischar ) 
addRequired( IP, 'animal', @ischar ) 
addRequired( IP, 'session_num', @(x)(ischar(x) || isnumeric(x)) )  % which imaging session for this animal?
addRequired( IP, 'area_num', @isnumeric )  % which area to work on?
addOptional( IP, 'sub_site', '', @ischar )
addParameter( IP, 'chan', 1, @isnumeric ) % chan 1 = gcamp, 0 = mcherry
addParameter( IP, 'slack', '', @ischar )  % send a slack notification when done?
addParameter( IP, 'downsample', 10, @isnumeric ) % for background recalculation
addParameter( IP, 'denoised', true, @islogical ) % use the denoised (Deep interp) version of data?
addParameter( IP, 'overwrite', false, @islogical ) % overwrite existing dF_F_REF?
addParameter( IP, 'erase', false, @islogical ) % erase deepinterp results after extraction?
parse( IP, source_dir, target_dir, animal, session_num, area_num, varargin{:} );
sub_site = IP.Results.sub_site;
chan = IP.Results.chan;
downsample_f = IP.Results.downsample; %10;
slackID = IP.Results.slack;
use_denoise = IP.Results.denoised;
overwrite = IP.Results.overwrite;
erase_dp = IP.Results.erase;
area_chan = sprintf('A%i_Ch%i', area_num, chan);
area_fieldname = sprintf('CaA%i', area_num); %['Ca', extractBefore(area_chan, '_Ch')];
session_num = num2str(session_num);
session_name = [animal , '-', session_num];
if ~isempty(sub_site)
    subsessionName = [animal sub_site '-' session_num];
    source_folder = fullfile(source_dir, animal, '2P', session_name, subsessionName, filesep);
    save_folder = fullfile(target_dir, animal, [animal sub_site]);
    sessionfile = [subsessionName, '.mat'];
else
    source_folder = fullfile(source_dir, animal, '2P', session_name, filesep);
    save_folder = fullfile(target_dir, animal);
    sessionfile   = [session_name '.mat'];
end
session_mat_path = fullfile(save_folder, sessionfile);
% Locate trial fluor .mat failes
trial_mat_dir = sprintf('%sPreProcess/A%i_Ch%i/', source_folder, area_num, chan);
[~,trial_mat_paths] = FileFinder(trial_mat_dir, 'type','mat', 'contains',area_chan, 'exclude','_dp');
if use_denoise
    [~,trial_mat_paths] = FileFinder(trial_mat_dir, 'type','mat', 'contains',{area_chan,'_dp'});
end
if isempty(trial_mat_paths), error('Could not find any trial mat files'); end
trial_mat_paths = cellfun(@ChenLabFilepath, trial_mat_paths, 'UniformOutput', false);

end

% ESTIMATE BACKGROUND------------------------------------------------------
function [b, options] = estimate_background(Ca, source_folder, area_chan, downsample_f, trial_mat_paths, use_denoise)
if ~isfield(Ca, 'CNMFOptions')
    tau = 2;                 % std of gaussian kernel (size of neuron)//// 7
    p = 0;                   % order of autoregressive system //// 2 (p = 0 no dynamics, p=1 just decay, p = 2, both rise and decay)
    merge_thr = 0.8;         % merging threshold
    options = CNMFSetParms(...
        'nb',1,...                                  % number of background components per patch
        'gnb',3,...                                 % number of global background components
        'ssub',2,...
        'tsub',4,...
        'p',p,...                                   % order of AR dynamics
        'merge_thr',merge_thr,...                   % merging threshold
        'gSig',tau,...
        'spatial_method','regularized',...
        'cnn_thr',0.2,...
        'patch_space_thresh',0.25,...
        'create_memmap', true,...
        'max_size_thr', 500,...
        'min_size_thr', 100,...
        'space_thresh', .5,...
        'min_SNR',2);
    options.foldername = [source_folder 'PreProcess' filesep area_chan filesep];
else
    options = Ca.CNMFOptions;
    options.p = 0;
end
options.fr = Ca.sampling_rate;
if use_denoise
    if isfield(Ca, 'b_dp')
        b = Ca.b_dp;
    elseif isfield(Ca, 'b')
        b = Ca.b;
        Ca.b_dp = b;
    else
        b = recalculate_b(source_folder, area_chan, Ca.sampling_rate, downsample_f, Ca.FOV, trial_mat_paths, options);
        Ca.b_dp = b;
    end
else
    % Use existing background calculation if possible or recalculate
    if isfield(Ca, 'b')
        b = Ca.b;
    else
        b = recalculate_b(source_folder, area_chan, Ca.sampling_rate, downsample_f, Ca.FOV, trial_mat_paths, options);
        Ca.b = b;
    end
end
end

% CHECK AND ERASE DEEP INTERP FILES----------------------------------------
%{
function dp_check(Ca, source_dir, animal, session_name, area_chan, erase_dp, slackID) % source_dir, target_dir, 
%{
pd = fullfile(target_dir, animal, filesep);
sessionName = [animal '-' sessionNo];
areaName = ['CaA' area_chan(2)];
% Load the Ca struct from Dropbox
mat_file = matfile(fullfile(pd, [animal '-' sessionNo '.mat']));
Ca = mat_file.(areaName);
%}

% Each F_df_REF entry should be 60 frames shorter than the original video in F_dF
F_len = cellfun(@(x) size(x,2), Ca.F_dF);
FRef_len = cellfun(@(x) size(x,2), Ca.F_df_REF);
tr_bad = F_len-FRef_len ~= 60; % find( )
if any(tr_bad)
    % If any trials are the wrong length, send a notification
    if exist('slackID', 'var')
        if ~isempty(slackID)
            SendSlackNotification('REDACTED_SLACK_WEBHOOK', ...
                ['<@', slackID, '> 2P PIPELINE STEP 03 (SCC) ' session_name ' ' area_chan ' is finished. '...
                'Trial length mismatch.'], '#e_pipeline_log');
        else
            SendSlackNotification('REDACTED_SLACK_WEBHOOK', ...
                ['2P PIPELINE STEP 03 (SCC) ' session_name ' ' area_chan ' is finished. '...
                'Trial length mismatch.'], '#e_pipeline_log');
        end
    end
else
    % If all trials are the correct length, delete the _dp.mat files send a notification
    dp_pd = fullfile(source_dir, animal, filesep);
    numFiles = length(dir(fullfile(dp_pd, '2P', session_name, 'PreProcess', area_chan, '*_dp.mat')));
    if erase_dp && numFiles > 0
        delete(fullfile(dp_pd, '2P', session_name, 'PreProcess', area_chan, '*_dp.mat'))
    else
        numFiles = 0;
    end
    if exist('slackID', 'var')
        if ~isempty(slackID)
            SendSlackNotification('REDACTED_SLACK_WEBHOOK', ...
                ['<@', slackID, '> 2P PIPELINE STEP 03 (SCC) ' session_name ' ' area_chan...
                ' is finished. ' num2str(numFiles) ' _dp.mat files deleted.']...
                , '#e_pipeline_log');
        else
            SendSlackNotification('REDACTED_SLACK_WEBHOOK', ...
                ['2P PIPELINE STEP 03 (SCC) ' session_name ' ' area_chan...
                ' is finished. ' num2str(numFiles) ' _dp.mat files deleted.']...
                , '#e_pipeline_log');
        end
    end
end
end
%}