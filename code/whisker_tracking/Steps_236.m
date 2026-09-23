%% INPUT PARAMETERS HERE - MAKE SURE THIS CORRECT BEFORE RUNNING!!!!!
%% MAKE SURE ALL FILES ARE IN THE RIGHT LOCATION AND PROPERLY NAMED!!!!

% steps to be processed - DEFAULT = [2,3,6]
process_steps = [2,3,6]; % list steps that need to be processed 4-crop subvolume, 5 - fine registration, 6- segmentation,7 - normalize
anm = 'sm057'; %animal
session = 'sm057-1'; %session
face_x = 35;  % get these coordinates from Janelia Whisker Tracking
face_y = 219; % get these coordinates from Janelia Whisker Tracking
dropbox_path = [smroot() 'Animals/']; %root folder where output files are to be stored ON DROPBOX
raw_data_path = 'W:\Projects\Sensorimotor\Animals\';   %root folder where whisker files are found
framerate = 500; % fps
slackID = ''; %slack member ID, leave empty to not use it
  
% DON'T EDIT BELOW
foldername = [raw_data_path anm '\CCD\' session '\'];

% Object Tracking - draw an ROI around the rotator, then double click the ROI to proceed
% takes 2-4 hours, generates .mat files (eg sm057a_593_20230227154713.mat), should be ~2 MB each at this stage
if ismember(2,process_steps)
    fprintf('\nRunning Step 2...')
    tic
    % [release] path handled by startup_sm.m: addpath('Z:\Dropbox\Dropbox\Chen Lab Team Folder\Analysis Suite\PIPELINE\BEHAVIOR\whisker_tracking\02_texture panel tracking');
    do_parallel = 1;
    texture = 2500;   % frame number where texture panel is in presented position   
    scaleFactor = 0.2;  %Threshold. (0-1) Use lower values to exclude whiskers  
    OBJECT_TRACKING_NOTRAINING(foldername, do_parallel, texture, framerate, scaleFactor, slackID);
    % [release] path handled by startup_sm.m: rmpath('Z:\Dropbox\Dropbox\Chen Lab Team Folder\Analysis Suite\PIPELINE\BEHAVIOR\whisker_tracking\02_texture panel tracking');
    fprintf('\nStep 2 complete!')
    toc
end
%
% Trace Whiskers - takes 2-4 hours for non-reencoded avis. generates .whisker and .measurement files
if ismember(3,process_steps)    
    tic
    % [release] path handled by startup_sm.m: addpath('Z:\Dropbox\Dropbox\Chen Lab Team Folder\Analysis Suite\PIPELINE\BEHAVIOR\whisker_tracking\03_import_data');
    TRACE_WHISKER_NO_TRAIN(foldername, face_x, face_y, slackID);
    % [release] path handled by startup_sm.m: rmpath('Z:\Dropbox\Dropbox\Chen Lab Team Folder\Analysis Suite\PIPELINE\BEHAVIOR\whisker_tracking\03_import_data');
    fprintf('\nStep 3 complete!')
    toc
end

% Import Measurements - takes ~30 mins (Fills in the 
if ismember(6,process_steps)
    tic
    % [release] path handled by startup_sm.m: addpath('Z:\Dropbox\Dropbox\Chen Lab Team Folder\Analysis Suite\PIPELINE\BEHAVIOR\whisker_tracking\06_import_measurements');  
    fix(clock)
    IMPORT_MEASUREMENTS(anm, session, dropbox_path, raw_data_path, slackID);
    % [release] path handled by startup_sm.m: rmpath('Z:\Dropbox\Dropbox\Chen Lab Team Folder\Analysis Suite\PIPELINE\BEHAVIOR\whisker_tracking\06_import_measurements');
    toc
    fprintf('\nStep 6 complete!')
end