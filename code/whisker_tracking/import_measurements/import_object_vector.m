function import_object_vector(anm, session, raw_data_path, dropbox_path)


%% THIS NEEDS TO BE UPDATED AT SOME POINT WHEN WE START TO IMPORT 
%% MULTIPLE PARAMETERS TO AVOID OVERWRITING DATA

if nargin == 0
    anm = 'cc029';
    session = 'cc029-1';
    dropbox_path = 'Z:\Dropbox\Dropbox\Chen Lab Team Folder\Projects\Delayed Non-Match\Animals\';
    raw_data_path = 'Z:\Projects\Delayed_Non_Match_1\Animals\';
end

dropbox_folder = [dropbox_path anm '\'];
raw_folder = [raw_data_path anm '\CCD\' session '\'];

%% process mean angle
whisker_dat = load([dropbox_folder session '_whisker.mat'],'whisker_dat');
whisker_dat = whisker_dat.whisker_dat;

temp_object = {};

parfor i = 1:length(whisker_dat)
    original_file = whisker_dat(i).filename(1:end-4);    
    original_file
    %% get touch    
    temp_object{i} = get_object(raw_folder, original_file);
end

for i = 1:length(temp_object)
    whisker_dat(i).object_vector  = temp_object{i};
end

if exist([dropbox_folder session '_whisker.mat']) == 0    
%     save([dropbox_folder session '_whisker.mat'],'no_whiskers','-v6');
    save([dropbox_folder session '_whisker.mat'],'whisker_dat','-append','-v6');
else
%     save([dropbox_folder session '_whisker.mat'],'no_whiskers','-append','-v6');
    save([dropbox_folder session '_whisker.mat'],'whisker_dat','-append','-v6');
end
