function import_angles_curves(anm, session, raw_data_path, dropbox_path)

%% THIS NEEDS TO BE UPDATED AT SOME POINT WHEN WE START TO IMPORT 
%% MULTIPLE PARAMETERS TO AVOID OVERWRITING DATA

if nargin == 0
anm = 'jn039';
session = 'jn039-1';
dropbox_path = 'Z:\Dropbox\Dropbox\Chen Lab Team Folder\Projects\Delayed Non-Match\Animals\';
raw_data_path = 'Z:\Projects\Delayed_Non_Match_1\Animals\';
end

dropbox_folder = [dropbox_path anm '\'];
raw_folder = [raw_data_path anm '\CCD\' session '\'];
whisker_dat = load([dropbox_folder session '_whisker.mat'],'whisker_dat');
whisker_dat =  whisker_dat.whisker_dat;

%% threshold whisker parameters
whisker_length = 60;
whisker_score = 70;
follicle_y_max = 440;
follicle_y_min = 50;
tip_y_max = 440;

%% process median angle and curve
% [release] path handled by startup_sm.m: addpath('Z:\Dropbox\Dropbox\Chen Lab Team Folder\Analysis Suite\PIPELINE\BEHAVIOR\whisker_tracking\common scripts');

tempangles = {};
tempcurves = {};
parfor i = 1:length(whisker_dat)
    original_file = whisker_dat(i).filename(1:end-4)    
%     origsinal_file
    %% get mean angle
    [angles, curves] = median_angle_curve(raw_folder, original_file, whisker_length, whisker_score, follicle_y_max, follicle_y_min, tip_y_max);
    tempangles{i} =  angles;            
    tempcurves{i} =  curves;            
end

for i = 1:length(whisker_dat)
    whisker_dat(i).mean_angle  =  tempangles{i};
    whisker_dat(i).mean_curve  =  tempcurves{i};
end

%% save output
if exist([dropbox_folder session '_whisker.mat']) == 0    
    save([dropbox_folder session '_whisker.mat'],'whisker_dat','-v6');
else
    save([dropbox_folder session '_whisker.mat'],'whisker_dat','-append','-v6');
end




