%% /////////////////////////////// CHEN_2P_Pipeline_Step_01 //////////////
% Purpose
%        - image flip (resonance scanner)
%        - frame-wise rigid/non-rigid motion correction used NoRMCorre
%          ref : https://github.com/simonsfoundation/NoRMCorre
%
% Input
%        -  anm :           String;   name of the animal; e.g., 'jn018'
%        -  sessionNo :     Char;     session no. of the recording; e.g., '2'
%        -  area_channel :  String;   name of imaging area and channel; e.g., 'A0_Ch0'
%        -  sampling_rate : Hz;       the full frame acqusition rate of the resonance scanner
%                           by default, 32.5868 Hz
%        -  FOV :           [vertical; horizontal] in pixel; size of the imaging field of view
%                           by default, [200 488]
%        -  do_parallel :   1 == do parallel computing; 0 == non parallel
%        -  do_nonrigid :   1 == do non-rigid motion correction; 0 == rigid motion correction only
%        -  multi-plane :   1 == two planes imaged, split input image
%                           before flipping and motion correcting; 0 == do
%                           normally (i.e. nosplitting)
%
% Output
%        - saved .mat files and .tiff files
%
% History
% 11.29.17 : intergrated by Jianguang; please keep tracking any changes made
%            by any user
% 09.21.20 : changed avgimage calculation to use .99*max in scaling (was 1x) -DGL

function CHEN_2P_Pipeline_Step_01(localdirectory, runningdirectory ,anm, sessionNo, area_channel, sampling_rate, FOV, do_parallel, do_nonrigid, multi_plane, subsession, skip_flip, slackID)

if nargin == 0
    if ispc
        localdirectory = 'V:\Projects\Transsynaptic\Animals\';
        runningdirectory =  'V:\Projects\Transsynaptic\Animals\';
    elseif isunix
        localdirectory = 'Z:\Projects\Multi-area_2\gcamp\';
        runningdirectory =  '/net/claustrum2/mnt/data/Projects/Perirhinal/Animals/';
    end
    anm           = 'os008';                         % name of the animal
    sessionNo     = '9';                             % session no. of recording, e.g., '2'
    area_channel  = 'A0_Ch1';                        % selecting areas and channel
    sampling_rate = 30.2;                         % Hz, full frame acqusition rate of the resonance scanner
    FOV           = [284 430];                       % pixel, field of view
    do_parallel   = 1;                               % parallel computing option
    do_nonrigid   = 1;                               % option to do non-rigid registration (faster without it, better results with it)
    multi_plane   = 0;
    subsession = '';                                % accomodates nested subsessions with each session.  set as empty string to ignore
    skip_flip = 0;
end

if ~exist('skip_flip', 'var')
    skip_flip = 0;
end

sessionName   = [anm , '-', sessionNo];             % e.g.'jn018-1'; full session name
sessionfile   = [sessionName '.mat'];               % final session file name for save

% /// data & toolbox directory
sessionfoldername = fullfile(runningdirectory, anm, '2P', sessionName, filesep);
localfoldername = fullfile(localdirectory, anm, '2P', sessionName);
savefoldername = fullfile(runningdirectory, anm);

%handling folder directory for subsessions
if ~isempty(subsession)
    subsessionName = [anm subsession '-' sessionNo];
    sessionfoldername = fullfile(runningdirectory, anm, '2P', sessionName, subsessionName, filesep);
    sessionfile = [subsessionName '.mat'];
    savefoldername = fullfile(runningdirectory, anm, '2P', sessionName, filesep);
end

disp(sessionfoldername)

%% Provide the following information
analysis_path = './Flip/';
addpath(genpath(analysis_path));
analysis_path = './NoRMCorre-master/';
addpath(genpath(analysis_path));
analysis_path = '../SlackMatlab';
addpath(genpath(analysis_path));

if isunix
    delete(gcp('nocreate'));
    %limits the max number of threads to the number of cpus given on scc
    NUM_CPUS = str2double(getenv('NSLOTS'));
    maxNumCompThreads(NUM_CPUS);
    pc = parcluster('local');
    parpool_tmpdir = fullfile(pc.JobStorageLocation, 'step1', [sessionName '_' area_channel], filesep);
    mkdir(parpool_tmpdir);
    pc.JobStorageLocation = parpool_tmpdir;
    parpool(pc, NUM_CPUS);
end

mkdir(fullfile(sessionfoldername, 'PreProcess', area_channel, 'Avg', filesep));

if do_parallel
    if isunix
        parObj = gcp('nocreate');
        if isempty(parObj)
            parObj = parpool(NUM_CPUS);
        end
    elseif ispc
        parObj = gcp;
    end
else
    parObj=[];
end

% load images from all subdirectories
files = dir(fullfile(sessionfoldername, '*_Live', ['*' area_channel '*.tif']));
if isempty(files)
    files = dir(fullfile(sessionfoldername, '*_Behavior', ['*' area_channel '*.tif']));
end

if isempty(files)
    error(['no tiff files found for area: ', area_channel, ' in folder: ', sessionfoldername]);
end

%% estimate xshift and yshift
xshift = [];
if ~skip_flip
    subset = randi(length(files), [1 100]);
    counter = 1;
    xshift = zeros(20, 1);
    for i = subset
        if counter < 20
            fullname = fullfile(files(i).folder, files(i).name);

            % /// Note: use 1000 KB as threshold to check empty .tiff files
            if files(i).bytes > 1024000
                xshift_temp = estimate_flip(fullname);
                xshift(counter) = xshift_temp;
                counter = counter + 1;
            else
                xshift(counter) = NaN;
            end
        end
    end
    xshift = mode(xshift);
end

if skip_flip == 2
    skip_flip = 0;
end

% ////////////////////////// Run on parallel version
% Note: in the Chen-lab cluster, make sure to check if Parellel Pool
% was enabled; otherwise it may wait forever  ...

files_done = dir(fullfile(sessionfoldername, 'PreProcess', area_channel, '*.mat'));
if ~isempty(parObj)
    parfor i = 1:length(files)
        % /// identify files not done yet ...
        flag_done = 0;
        if ~isempty(files_done)
            [~, temp] = fileparts(files(i).folder);
            if contains(temp, 'Live')
                temp = eraseBetween(temp, '_', 'e', 'Boundaries','inclusive');
            elseif contains(temp, 'Behavior')
                temp = eraseBetween(temp, '_', 'r', 'Boundaries', 'inclusive');
            end
            new_file_name = [area_channel '_' temp '.mat'];
            flag_done = any(strcmp({files_done.name}, new_file_name));
        end

        fullname = fullfile(files(i).folder, files(i).name);
        % /// Note: use 1000 KB as threshold to check empty .tiff files
        if files(i).bytes > 1024000 && ~flag_done
            save_flip_normcorre(sessionfoldername, fullname, files(i).folder, FOV, area_channel, files(i).date, do_nonrigid, multi_plane, xshift, skip_flip);
        end
    end

    % /////////////// Run on non-parallel version
else
    for i = 1:length(files)
        % /// identify files not done yet ...
        flag_done = 0;
        if ~isempty(files_done)
            [~, temp] = fileparts(files(i).folder);
            if contains(temp, 'Live')
                temp = eraseBetween(temp, '_', 'e', 'Boundaries','inclusive');
            elseif contains(temp, 'Behavior')
                temp = eraseBetween(temp, '_', 'r', 'Boundaries', 'inclusive');
            end
            new_file_name = [area_channel '_' temp '.mat'];
            flag_done = any(strcmp({files_done.name}, new_file_name));
        end

        fullname = fullfile(files(i).folder, files(i).name);
        % /// Note: use 1000 KB as threshold to check empty .tiff files
        if files(i).bytes > 1024000 && ~flag_done
            save_flip_normcorre(sessionfoldername, fullname, files(i).folder, FOV, area_channel, files(i).date, do_nonrigid, multi_plane, xshift, skip_flip);
        end
    end
end

%% save information so far

Ca.FOV = FOV;
Ca.sampling_rate = sampling_rate;
Ca.sessionfoldername = localfoldername;

session_mat_file = matfile(fullfile(savefoldername, sessionfile), 'Writable', true);
areaName = ['Ca', extractBefore(area_channel, '_Ch')];
session_mat_file.(areaName) = Ca;
disp(['successfully save ', areaName, ' to ', sessionfile])

poolobj = gcp('nocreate');
delete(poolobj);

if isunix
    rmdir(parpool_tmpdir, 's');
end

if exist('slackID','var') && ~isempty(slackID)
    SendSlackNotification('REDACTED_SLACK_WEBHOOK', ...
        ['<@', slackID, '> 2P PIPELINE STEP 01 is finished: ',anm, '-', sessionNo, subsession,' ', area_channel], '#e_pipeline_log');
else
    SendSlackNotification('REDACTED_SLACK_WEBHOOK', ...
        ['2P PIPELINE STEP 01 is finished: ',anm, '-', sessionNo, subsession,' ', area_channel], '#e_pipeline_log');
end

end

function save_flip_normcorre(sessionfoldername, fullname, folder_name, FOV, area_channel, file_timestamp, do_nonrigid, multi_plane, xshift, skip_flip)

if skip_flip
    output.data_sined = readTiff(fullname);
else
    output = CHEN_Flip_Signed(fullname, 0, xshift);
end

if size(output(1).data_sined,1) >= FOV(1)
    if size(output(1).data_sined,2) >= FOV(2)
        if multi_plane
            data1=output.data_sined(1:end/2,:,:);
            data2=output.data_sined(end/2+1:end,:,:);
            FOV(1)=FOV(1)/2;
            [motion_corrected1, motion_metric1] = normcorre_chen_batch(data1, do_nonrigid);
            [motion_corrected2, motion_metric2] = normcorre_chen_batch(data2, do_nonrigid);
            motion_corrected=cat(1,motion_corrected1,motion_corrected2);
            motion_metric=cat(3,motion_metric1,motion_metric2);
        else
            [motion_corrected, motion_metric] = normcorre_chen_batch(output.data_sined, do_nonrigid);
        end

        if ~isempty(motion_corrected)
            if skip_flip
                [motion_corrected, output.xshift] = fixOffsetAndDewarp(motion_corrected, 1);
            end

            [~, name] = fileparts(folder_name);
            if contains(name, 'Behavior')
                folder = eraseBetween(name, '_', 'r', 'Boundaries','inclusive');
            elseif contains(name, 'Live')
                folder = eraseBetween(name, '_', 'e', 'Boundaries','inclusive');
            end

            mat_file.motion_corrected = uint16(65535*(motion_corrected-min(motion_corrected(:)))/(max(motion_corrected(:))-min(motion_corrected(:))));
            mat_file.motion_metric = motion_metric;
            mat_file.fileloc = fullname;
            mat_file.time_stamp = file_timestamp;
            mat_file.aligned = 0;
            mat_file.x_shift = output.xshift;

            new_file_name = [area_channel '_' folder '.mat'];
            save(fullfile(sessionfoldername, 'PreProcess', area_channel, new_file_name), '-struct', 'mat_file');

            avgimg = mean(motion_corrected, 3);
            avgimg = 65535*(avgimg-min(avgimg(:)))/(.99*max(avgimg(:))-min(avgimg(:)));
            imwrite(uint16(avgimg), fullfile(sessionfoldername, 'PreProcess', area_channel, 'Avg', ['Avg_' strrep(new_file_name, '.mat', '.tif')]));

            disp(['successfully save Avg_' strrep(new_file_name, '.mat', '.tif')]);
        else
            warning('no motion corrected data in save_flip_normcorre');
            disp(['missing in: ', fullname]);
        end
    else
        warning(['xresolution (requested:', num2str(FOV(2)),' got:', num2str(size(output(1).data_sined,2)), ') not met in save_flip_normcorre']);
        disp(['missing in: ', fullname]);
    end
else
    warning(['yresolution (requested:', num2str(FOV(1)),' got:', num2str(size(output(1).data_sined,1)), ') not met in save_flip_normcorre']);
    disp(['missing in: ', fullname]);
end

end
