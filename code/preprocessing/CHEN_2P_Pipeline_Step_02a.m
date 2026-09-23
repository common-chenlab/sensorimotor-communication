%% //////////////////////// CHEN_2P_Pipeline_Step_02 //////////////////////
% Purpose
%         - Trial by trial alignment (first half of full step 2 script)
%           motion corrects each trial from 1 session to a reference trial

function CHEN_2P_Pipeline_Step_02a(pathdirectory, anm, sessionNo, area_channel, ref_trial, redo_trial_alignment, multi_plane, subsession, slackID)

if nargin == 0
    pathdirectory =  'Z:\Projects\Sensorimotor\Animals\';
    anm           = 'sm002';                    % name of the animal
    sessionNo     = '14';                       % session no., e.g., '2'
    area_channel  = 'A0_Ch1';                   % selecting areas and channel
    ref_trial     = '';                         % reference template for cross-trial alignment
    redo_trial_alignment = 1;                   % redo trial by trial alignment
    multi_plane = 0;
    subsession = '';
end
if isnumeric(sessionNo), sessionNo = num2str(sessionNo); end
sessionName = [anm , '-', sessionNo];       % e.g.'jn018-1'; full session name
sessionfile = [sessionName '.mat'];         % final session file name for save

sessionfoldername = fullfile(pathdirectory, anm, '2P', sessionName, filesep);
savefoldername = fullfile(pathdirectory, anm, filesep);

%handling folder directory for subsessions
if ~isempty(subsession)
    subsessionName = [anm subsession '-' sessionNo];
    sessionfoldername = fullfile(pathdirectory, anm, '2P', sessionName, subsessionName, filesep);
    sessionfile = [subsessionName '.mat'];
    savefoldername = fullfile(pathdirectory, anm, '2P', sessionName, filesep);
end

%% load files
session_mat_file = matfile(fullfile(savefoldername, sessionfile), 'Writable', true);
areaName = ['Ca', extractBefore(area_channel, '_Ch')];
Ca = session_mat_file.(areaName);
files = dir(fullfile(sessionfoldername, 'PreProcess', area_channel, 'Avg', '*.tif'));   % list of Avg files

%add_pipeline_paths();
setup_parpool_SCC();

%% auto detect reference trial
if isfield(Ca, 'ref_trial'),  ref_trial = Ca.ref_trial;  end
if isempty(ref_trial) || ~isfile(fullfile(sessionfoldername, 'PreProcess', area_channel, 'Avg', ref_trial)) || redo_trial_alignment
    % /// read trial info from raw data
    % scan the middle 50% of trials
    ref_metrics = zeros(length(files),1);
    parfor i = round(length(files)/4):round(length(files)*3/4)
        %disp(['potential ref trial: ', num2str(i)])
        filename = erase(files(i).name, 'Avg_');
        filename = strrep(filename, '.tif', '.mat');
        filename = fullfile(sessionfoldername, 'PreProcess', area_channel, filename);
        s = matfile(filename);
        ref_metrics(i, 1) = median(s.motion_metric, 'omitnan');
    end

    [ref_metrics, indices] = sort(ref_metrics, 'descend');
    ref_trial = files(indices(1)).name; % select trial with least motion
    %disp(['chosen ref trial: ', ref_trial, ' median correlation of ref_trial: ', num2str(ref_metrics(1))])
    redo_trial_alignment = 1;
end

%%
if ~exist('ref_trial', 'var'), ref_trial = files(1).name;  end

ref_frames = 30;
info = imfinfo(fullfile(files(1).folder, files(1).name));
rows = info.Height;
cols = info.Width;
refs = zeros([rows, cols, ref_frames]);
for j = 1:min(ref_frames, numel(indices)) %ref_frames  ASB 3/25/24
    i = indices(j);
    filename = fullfile(files(i).folder, files(i).name);

    refs(:, :, j) = im2double(imread(filename));
    if j > 1
        offset = align_image_batch(refs(:, :, j - 1), refs(:, :, j));
        refs(:, :, j) = circshift(refs(:, :, j), [offset(2), offset(1)]);
    end
end
reference_image = median(refs, 3);

mkdir(fullfile(sessionfoldername, 'PreProcess', area_channel, 'Avg2a', filesep));
FOV = Ca.FOV;

% /////////////////////// Trial-by-Trial alignment
parObj = gcp('nocreate');                                 % check current Parellel Pool
% Note: when using Chen-lab cluster, make sure to check if Parellel Pool was enabled; otherwise it may wait forever in Matlab2016a ...
trial_info = cell(1, length(files));
if ~isempty(parObj)      % do parallel version
    parfor i = 1:length(files)
        [fileloc, mat_file, time_stamp, motion_metric] = trial_align_batch(files(i).name, sessionfoldername, area_channel, reference_image, redo_trial_alignment, multi_plane, FOV);
        trial_info{i}.fileloc = fileloc;
        trial_info{i}.mat_file = mat_file;
        trial_info{i}.time_stamp = time_stamp;
        trial_info{i}.motion_metric = motion_metric;
    end
else   % non-parallel version
    for i = 1:length(files)
        [fileloc, mat_file, time_stamp, motion_metric] = trial_align_batch(files(i).name, sessionfoldername, area_channel, reference_image, redo_trial_alignment, multi_plane, FOV);
        trial_info{i}.fileloc = fileloc;
        trial_info{i}.mat_file = mat_file;
        trial_info{i}.time_stamp = time_stamp;
        trial_info{i}.motion_metric = motion_metric;
    end
end

% /// save other information
Ca.trial_info = trial_info;
Ca.ref_trial  = ref_trial;

session_mat_file.(areaName) = Ca;
fprintf('\nStep 2a complete: successfully saved %s to %s\n', areaName, sessionfile)  %disp(['successfully save ', areaName, ' to ', sessionfile])

%poolobj = gcp('nocreate');
%delete(poolobj);
%if isunix, rmdir(parpool_tmpdir, 's'); end

slack_hook = 'REDACTED_SLACK_WEBHOOK ';
slack_msg = sprintf('2P PIPELINE STEP 02a %s-%s %s %s is finished', anm, sessionNo, subsession, area_channel);
SendSlackNotification(slack_hook, slack_msg, '#e_pipeline_log');


end

function [fileloc, mat_file, time_stamp, motion_metric] = trial_align_batch(fullname, sessionfoldername, area_channel, reference_image, redo_trial_alignment, multi_plane, FOV)

reg_image = im2double(imread(fullfile(sessionfoldername, 'PreProcess', area_channel, 'Avg', fullname)));
mat_file = strrep(fullname, 'Avg_', '');
mat_file = strrep(mat_file, '.tif', '.mat');

trial_mat_file = load(fullfile(sessionfoldername, 'PreProcess', area_channel, mat_file));
if ~isfield(trial_mat_file, 'aligned')
    aligned = 0;
else
    aligned = trial_mat_file.aligned;
end

if aligned && redo_trial_alignment
    if multi_plane
        nrows = size(trial_mat_file.motion_corrected, 1);
        half_rows = nrows / 2;
        motion_corrected1 = circshift(trial_mat_file.motion_corrected(1:half_rows, :, :), [-trial_mat_file.offset1(1, 2), -trial_mat_file.offset1(1, 1), 0]);
        motion_corrected2 = circshift(trial_mat_file.motion_corrected((half_rows+ 1):nrows, :, :), [-trial_mat_file.offset2(1, 2), -trial_mat_file.offset2(1, 1), 0]);
        motion_corrected = cat(1,motion_corrected1,motion_corrected2);
    else
        motion_corrected = circshift(trial_mat_file.motion_corrected, [-trial_mat_file.offset(1, 2), -trial_mat_file.offset(1, 1), 0]);
    end
else
    motion_corrected = trial_mat_file.motion_corrected;
end

if ~aligned || redo_trial_alignment
    fileloc = trial_mat_file.fileloc;
    time_stamp = trial_mat_file.time_stamp;
    motion_metric = trial_mat_file.motion_metric;
    if multi_plane
        num_planes = 2;
        reference_image1 = reference_image(1:end/2,:);
        reference_image2 = reference_image(end/2+1:end,:);
        reg_image1 = reg_image(1:end/2,:);
        reg_image2 = reg_image(end/2+1:end,:);
        motion_corrected1 = motion_corrected(1:end/2,:,:);
        motion_corrected2 = motion_corrected(end/2+1:end,:,:);

        for i = 1:num_planes
            if i==1
                offset1 = align_image_batch(reference_image1, reg_image1);

                motion_corrected1 = circshift(motion_corrected1, [offset1(2), offset1(1), 0]);
            else
                offset2 = align_image_batch(reference_image2, reg_image2);

                motion_corrected2 = circshift(motion_corrected2, [offset2(2), offset2(1), 0]);

                trial_mat_file.aligned = 1;
                motion_corrected = cat(1, motion_corrected1, motion_corrected2);
                if size(motion_corrected, 1:2) ~= FOV
                    %Crop
                    start1 = floor(((size(motion_corrected, 1) - FOV(1)) / 2) + 1);
                    end1 = floor(size(motion_corrected, 1) - ((size(motion_corrected, 1) - FOV(1)) / 2));
                    start2 = floor(((size(motion_corrected, 2) - FOV(2)) / 2) + 1);
                    end2 = floor(size(motion_corrected, 2) - ((size(motion_corrected, 2) - FOV(2)) / 2));
                    motion_corrected = motion_corrected(start1:end1, start2:end2, :);
                end
                trial_mat_file.motion_corrected = motion_corrected;
                trial_mat_file.offset1 = offset1;
                trial_mat_file.offset2 = offset2;
                save(fullfile(sessionfoldername, 'PreProcess', area_channel, mat_file), '-struct', 'trial_mat_file', '-append');
            end
        end
    else
        offset = align_image_batch(reference_image, reg_image);

        motion_corrected = circshift(motion_corrected, [offset(2), offset(1), 0]);

        if size(motion_corrected, 1:2) ~= FOV
            %Crop
            start1 = floor(((size(motion_corrected, 1) - FOV(1)) / 2) + 1);
            end1 = floor(size(motion_corrected, 1) - ((size(motion_corrected, 1) - FOV(1)) / 2));
            start2 = floor(((size(motion_corrected, 2) - FOV(2)) / 2) + 1);
            end2 = floor(size(motion_corrected, 2) - ((size(motion_corrected, 2) - FOV(2)) / 2));
            motion_corrected = motion_corrected(start1:end1, start2:end2, :);
        end

        avgimg = mean(motion_corrected, 3);
        avgimg = 65535*(avgimg-min(avgimg(:)))/(.99*max(avgimg(:))-min(avgimg(:)));
        imgname = ['Avg_', strrep(mat_file, '.mat', '.tif')];
        imwrite(uint16(avgimg), fullfile(sessionfoldername, 'PreProcess', area_channel, 'Avg2a', imgname));

        %disp(['successfully save ' imgname]);

        trial_mat_file.aligned = 1;
        trial_mat_file.motion_corrected = motion_corrected;
        trial_mat_file.offset = offset;
        save(fullfile(sessionfoldername, 'PreProcess', area_channel, mat_file), '-struct', 'trial_mat_file', '-append');
    end
else
    fileloc = trial_mat_file.fileloc;
    motion_metric = trial_mat_file.motion_metric;
    time_stamp = trial_mat_file.time_stamp;
    %     motion_corrected = trial_mat_file.motion_corrected;
end

% tiff_info.directory = fullfile(sessionfoldername, 'PreProcess', area_channel, filesep);
% tiff_info.filename = fullfile(sessionfoldername, 'PreProcess', area_channel, strrep(mat_file, '.mat', '.tif'));
% tiff_info.bitspersample = 16;
% tiff_info.floatingpoint = false;
% tiff_info.nframes = size(motion_corrected, 3);
% motion_corrected = padarray(motion_corrected, [(512 - size(motion_corrected, 1)) / 2, (512 - size(motion_corrected, 2)) / 2, 0], 0);
%
% WriteTiff(tiff_info.filename, uint16(motion_corrected));
end
