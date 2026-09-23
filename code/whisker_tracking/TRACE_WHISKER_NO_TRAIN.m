function TRACE_WHISKER_NO_TRAIN(sessionfoldername, face_x, face_y, slackID)

%use if you cannot annotate a training set
%Cam Condylis 2/4/2020
if nargin == 0
    sessionfoldername = 'W:\Projects\Perirhinal\Animals\pr048\CCD\pr048-9\';
    face_x = 23;
    face_y = 198;
    slackID = ''; %slack member ID, leave empty to not use it
end

%%
cd(sessionfoldername)
filelist = dir([sessionfoldername '*.avi']);
% [release] path handled by startup_sm.m: addpath('Z:\Dropbox\Dropbox\Chen Lab Team Folder\Analysis Suite\PIPELINE\SlackMATLAB\');
% [release] path handled by startup_sm.m: addpath('Z:\Dropbox\Chen Lab Dropbox\Chen Lab Team Folder\Analysis Suite\PIPELINE\Misc\parfor_progressbar\')
ppm = ParforProgressbar(length(filelist), 'parpool', 'local', 'title','Whisker tracking'); 
parfor i = 1:length(filelist)
    filename = filelist(i).name(1:end-4);
    disp(filename)
    if exist([sessionfoldername filename '.whiskers'],'file') ~= 2
        % Trace Whiskers
        status = system(['trace ' filename '.avi ' filename '.whiskers']);
    end
    if exist([sessionfoldername filename '.measurements'],'file') ~= 2
        status = system(['measure --face ' num2str(face_x) ' ' num2str(face_y) ' y ' filename '.whiskers ' filename '.measurements']);
    end
    ppm.increment();
end
delete(ppm);
if isempty(slackID)
    SendSlackNotification('REDACTED_SLACK_WEBHOOK', ...
        'TRACE WHISKING job is finished', '#e_pipeline_log');
else
    SendSlackNotification('REDACTED_SLACK_WEBHOOK', ...
        ['<@',slackID,'> TRACE WHISKING job is finished'], '#e_pipeline_log');
end