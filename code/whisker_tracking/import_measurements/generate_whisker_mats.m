function generate_whisker_mats(anm, session, raw_data_path, dropbox_path)

if nargin == 0
    anm = 'jn039';
    session = 'jn039-1';
    dropbox_path = 'Z:\Dropbox\Dropbox\Chen Lab Team Folder\Projects\Delayed Non-Match\Animals\';
    raw_data_path = 'Z:\Projects\Delayed_Non_Match_1\Animals\';
end

dropbox_folder = [dropbox_path anm '\'];
raw_folder = [raw_data_path anm '\CCD\' session '\'];

%% create initial _whisker.mat file


if ~exist([dropbox_folder session '_whisker.mat'], 'file')

    %% make new entry
    files = dir([raw_folder '*.mat']);
    filelist = {files.name}';
    %{
    filelist = {};
    for i = 1:length(files)
        filelist = [filelist; files(i).name];
    end
    %}

    [~,ndx] = natsort(filelist); % Y
    files = files(ndx);

    trials = 1;
    for i = 1:length(files)
        %i
        if isempty(findstr(files(i).name, 'trained')) == 0
            load([raw_folder files(i).name], 'no_whiskers');
        else
            if isempty(findstr(files(i).name, 'sort')) == 1
                if isempty(findstr(files(i).name, '2nd')) == 1
                    if isempty(findstr(files(i).name, '_nofilter')) == 1
                        sorted_file = files(i).name;
                        original_file = sorted_file(1:end-4);
                        %% filename
                        whisker_dat(trials).filename = [original_file '.mat'];

                        %% timestamp
                        time_str = original_file(end-5:end);
                        whisker_dat(trials).timestamp = [time_str(1:2) ':' time_str(3:4) ':' time_str(5:6)];
                        whisker_dat(trials).timestamp = [time_str(1:2) ':' time_str(3:4) ':' time_str(5:6)];

                        trials = trials + 1;
                    end
                end
            end
        end
    end

    if exist([dropbox_folder session '_whisker.mat']) == 0
        %         save([dropbox_folder session '_whisker.mat'],'no_whiskers','-v6');
        %         save([dropbox_folder session '_whisker.mat'],'whisker_dat','-append','-v6');
        save([dropbox_folder session '_whisker.mat'],'whisker_dat','-v6');
    else
        %         save([dropbox_folder session '_whisker.mat'],'no_whiskers','-append','-v6');
        save([dropbox_folder session '_whisker.mat'],'whisker_dat','-append','-v6');
    end
end

%%
% [release] path handled by startup_sm.m: addpath('c:\Program Files\WhiskerTracking\matlab');
% [release] path handled by startup_sm.m: addpath('Z:\Dropbox\Dropbox\Chen Lab Team Folder\Analysis Suite\PIPELINE\BEHAVIOR\whisker_tracking\common scripts');

load([dropbox_folder session '_whisker.mat']);

parfor i = 1:length(whisker_dat)
    original_file = whisker_dat(i).filename(1:end-4);
    if isempty(findstr('file',original_file)) 
        if exist([raw_folder original_file '.mat'], 'file') %some files are corrupt and were removed
            %         if exist([raw_folder original_file '_nofilter.mat']) == 0
            if exist([raw_folder original_file '.whiskers'], 'file') ~= 0
                if exist([raw_folder original_file '.measurements'], 'file') ~= 0
                    whiskers2 = LoadWhiskers([raw_folder original_file '.whiskers']);
                    measurements2 = LoadMeasurements([raw_folder original_file '.measurements']);
                    [whiskers, measurements] = build_measurements(whiskers2, measurements2);
                    save_parfor2(whiskers, measurements, raw_folder, original_file)
                    %                     save([raw_folder original_file '.mat'],'whiskers','-append','-v6');
                    %                     save([raw_folder original_file '.mat'],'measurements','-append','-v6');
                end
            end
        end
        %         end
    end
end