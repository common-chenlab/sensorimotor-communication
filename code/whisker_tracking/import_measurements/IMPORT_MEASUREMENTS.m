function IMPORT_MEASUREMENTS(anm, session, dropbox_path, raw_data_path, slackID)

if nargin == 0
    %% edit this information
    anm = 'vo002';
    session = 'vo002-14';
    dropbox_path = 'Z:\Dropbox\Dropbox\Chen Lab Team Folder\Projects\Voltage\Animals\'; %root folder where output files are to be stored ON DROPBOX
    raw_data_path = 'Z:\Projects\Voltage\Animals\';   %root folder where whisker files are found
    slackID = ''; %slack member ID, leave empty to not use it
end

%% 
% [release] path handled by startup_sm.m: addpath('Z:\Dropbox\Dropbox\Chen Lab Team Folder\Analysis Suite\PIPELINE\SlackMATLAB\');
caughterror = 0;

try
    generate_whisker_mats(anm, session, raw_data_path, dropbox_path);    
catch
    caughterror = 1;
    if isempty(slackID)
        SendSlackNotification('REDACTED_SLACK_WEBHOOK', ...
            'IMPORT MEASUREMENTS stopped with errors in generate mats', '#e_pipeline_log');
    else
        SendSlackNotification('REDACTED_SLACK_WEBHOOK', ...
            ['<@',slackID,'> IMPORT MEASUREMENTS stopped with errors in generate mats'], '#e_pipeline_log');
    end
end

try
    import_angles_curves(anm, session, raw_data_path, dropbox_path);
catch
    caughterror = 1;
    if isempty(slackID)
        SendSlackNotification('REDACTED_SLACK_WEBHOOK', ...
            'IMPORT MEASUREMENTS stopped with errors in import angle curves', '#e_pipeline_log');
    else
        SendSlackNotification('REDACTED_SLACK_WEBHOOK', ...
            ['<@',slackID,'> IMPORT MEASUREMENTS stopped with errors in import angle curves'], '#e_pipeline_log');
    end
end
    
try
    import_touch_vector(anm, session, raw_data_path, dropbox_path);
    import_object_vector(anm, session, raw_data_path, dropbox_path);
catch
    caughterror = 1;
    if isempty(slackID)
        SendSlackNotification('REDACTED_SLACK_WEBHOOK', ...
            'IMPORT MEASUREMENTS stopped with errors in import touch vector', '#e_pipeline_log');
    else
        SendSlackNotification('REDACTED_SLACK_WEBHOOK', ...
            ['<@',slackID,'> IMPORT MEASUREMENTS stopped with errors in import touch vector'], '#e_pipeline_log');
    end
end

if caughterror == 0
    if isempty(slackID)
        SendSlackNotification('REDACTED_SLACK_WEBHOOK', ...
            'IMPORT MEASUREMENTS job is finished', '#e_pipeline_log');
    else
        SendSlackNotification('REDACTED_SLACK_WEBHOOK', ...
            ['<@',slackID,'> IMPORT MEASUREMENTS job is finished'], '#e_pipeline_log');
    end
end

end

