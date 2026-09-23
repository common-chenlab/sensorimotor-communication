function import_touch_vector(anm, session, raw_data_path, dropbox_path)


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
temp_touch = {};
whisker_dat = load([dropbox_folder session '_whisker.mat'],'whisker_dat');
whisker_dat = whisker_dat.whisker_dat;

randwhisk = randperm(length(whisker_dat));
radius = zeros(100,4);
%radius = zeros(length(whisker_dat),4);
parfor i = 1:100
    i
    original_file = whisker_dat(randwhisk(i)).filename(1:end-4);      
    %% get touch
    radius(i,:) = get_touch_radius(raw_folder, original_file);    
end

radius(radius<50) = 0;
radius(radius>0) = 1;
radius = sum(radius,1);
radius = find(radius>65);

if isempty(radius)
    radius = 12;
else
    radius = radius(1)*3;
end


temp_touch = {};

parfor i = 1:length(whisker_dat)
    original_file = whisker_dat(i).filename(1:end-4);    
    original_file
    %% get touch    
    temp_touch{i} = get_touch(raw_folder, original_file, radius);
end

for i = 1:length(temp_touch)
    whisker_dat(i).touch_vector  = temp_touch{i};
end

if exist([dropbox_folder session '_whisker.mat']) == 0    
%     save([dropbox_folder session '_whisker.mat'],'no_whiskers','-v6');
    save([dropbox_folder session '_whisker.mat'],'whisker_dat','-append','-v6');
else
%     save([dropbox_folder session '_whisker.mat'],'no_whiskers','-append','-v6');
    save([dropbox_folder session '_whisker.mat'],'whisker_dat','-append','-v6');
end
