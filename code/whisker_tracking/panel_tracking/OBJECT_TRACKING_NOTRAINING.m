function OBJECT_TRACKING_NOTRAINING(foldername, do_parallel, texture, framerate, scaleFactor, slackID)
% ASB added parfor progressbar code 6/1/23
if nargin == 0
    foldername = 'W:\Projects\Perirhinal\Animals\pr048\CCD\pr048-9\';
    do_parallel = 1;
    texture = 500;   % frame number where texture panel is in presented position
    framerate = 100;
    scaleFactor = 0.1;  %Threshold. (0-1) Use lower values to exclude whiskers
    slackID = ''; %slack member ID, leave empty to not use it
end

%%
fSep = filesep;
filelist = dir([foldername, fSep, '*.avi']);
addpath(foldername)
% [release] path handled by startup_sm.m: addpath('Z:\Dropbox\Dropbox\Chen Lab Team Folder\Analysis Suite\PIPELINE\SlackMATLAB\');

%% load training file
trained_file = filelist(1).name;
v = VideoReader([foldername trained_file]);
first_frame = read(v,1);
texture_frame = read(v,texture);
video = first_frame - texture_frame;
ROI_mask = roipoly(video);
close all;

if do_parallel
    filename = filelist(1).name; % specify filename, don't forget the .avi extension in the name
    fprintf(filename);
    fullpath = strcat(foldername,fSep,filename); % if video is located in a subdirectory, use fullpath rather than filename
    panelTracking(ROI_mask, scaleFactor, fullpath, framerate);
    % [release] path handled by startup_sm.m: addpath('Z:\Dropbox\Chen Lab Dropbox\Chen Lab Team Folder\Analysis Suite\PIPELINE\Misc\parfor_progressbar\')
    ppm = ParforProgressbar(length(filelist)-1, 'parpool', 'local', 'Title','object tracking'); %  , 'progressBarUpdatePeriod', 10 , 'parpool', {'local', 4}
    tic
    parfor i = 2:length(filelist)
        filename = filelist(i).name; % specify filename, don't forget the .avi extension in the name
        fullpath = strcat(foldername,fSep,filename); % if video is located in a subdirectory, use fullpath rather than filename
        matPath = [extractBefore(fullpath,'.'),'.mat'];
        try
            if ~exist(matPath,'file')
                panelTracking_parallel(ROI_mask, scaleFactor, fullpath, framerate);
            else
                fprintf('\n%s already exists', matPath)
            end
        catch
            fprintf('\nObject tracking failed for %s (i = %i)', filename, i)
        end
        ppm.increment();
    end
    toc
    delete(ppm); % Delete the progress handle when the parfor loop is done.
else
    for i = 1:length(filelist)
        filename = filelist(i).name; % specify filename, don't forget the .avi extension in the name
        fprintf(filename);
        fullpath = strcat(foldername,fSep,filename);
        matPath = [extractBefore(fullpath,'.'),'.mat'];
        try
            if ~exist(matPath,'file')
                % if video is located in a subdirectory, use fullpath rather than filename
                panelTracking(ROI_mask, scaleFactor, foldername, framerate);
            else
                fprintf('\n%s already exists', matPath)
            end
        catch
            fprintf('\nObject tracking failed for %s (i = %i)', filename, i)
        end
    end
end
if isempty(slackID)
    SendSlackNotification('REDACTED_SLACK_WEBHOOK', ...
        'OBJECT TRACKING job is finished', '#e_pipeline_log');
else
    SendSlackNotification('REDACTED_SLACK_WEBHOOK', ...
        ['<@', slackID,'> OBJECT TRACKING job is finished'], '#e_pipeline_log');
end
%     catch
%         SendSlackNotification('REDACTED_SLACK_WEBHOOK', ...
%             'OBJECT TRACKING stopped with errors', '#e_pipeline_log');
%     end