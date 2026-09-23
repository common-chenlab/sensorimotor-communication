%%  //////////////////////////////////// CHEN_2P_Pipeline_Step_04 /////////////////////////////////////
% Purpose: annotation of ROIs (cell types and repeatedly imaged neurons)
function CHEN_2P_Pipeline_Step_04_old(pathdirectory, animal, session_num,area_channel, static_channel, activity_channel, skipflip)

% [pathdirectory, animal, session_num, area_num, areaName, static_channel, activity_channel, skipflip, overwrite] = parse_inputs(main_dir, anm, session_num, area_num, varargin{:});

% {
% input parameters
if nargin == 0
    pathdirectory =  'D:\Chen Lab Dropbox\Chen Lab Team Folder\Projects\Sensorimotor\Animals\';
    animal           = 'sm045';                         % name of the animal
    session_num     = '8';                             % session no., e.g., '2'
    area_channel = 'A3';
    static_channel = 'Ch0';
    activity_channel = 'Ch1';
    skipflip = 1;
end
% }

% add_pipeline_paths()
% add necessary paths
% {
analysis_path = './cell_type_annotation';
addpath(genpath(analysis_path));
analysis_path = './Flip';
addpath(genpath(analysis_path));
analysis_path = './NoRMCorre-master';
addpath(genpath(analysis_path));
% }

    
 
% load file and find reference trial
sessionName   = [animal , '-', session_num];          % e.g.'jn018-1'; full session name
sessionfile   = [sessionName '.mat'];            % file destination for save
savefoldername = fullfile(pathdirectory, animal);
% session_mat_file = matfile(fullfile(savefoldername, sessionfile), 'Writable', true);

 
    load([savefoldername '\' sessionfile]);
  
if isempty(findstr(area_channel, 'A0')) == 0
    Ca = CaA0;
elseif isempty(findstr(area_channel, 'A1')) == 0
    Ca = CaA1;
elseif isempty(findstr(area_channel, 'A2')) == 0
    Ca = CaA2;
elseif isempty(findstr(area_channel, 'A3')) == 0
    Ca = CaA3;
end


% if ~isfield(Ca, 'celltype_REF') %|| overwrite
    FOV = Ca.FOV;
    [~, static] = get_static_reference(Ca, static_channel, sessionName, skipflip);
    [~, activity] = get_static_reference(Ca, activity_channel, sessionName, skipflip);


    channel1 = static; % imread('Avg_A2_Ch0_14-09-59.tif');  % e.g., RFP
channel2 = activity; %imread('Avg_A2_Ch1_14-09-59.tif');  % e.g., YFP

angle_deg = atand(double(channel2(:)) ./ double(channel1(:)));
rfpangle = prctile(angle_deg(channel1(:)>5000&channel2(:)>5000),2);
gfpangle = prctile(angle_deg(channel1(:)>5000&channel2(:)>5000),98);
threshold = gfpangle-(gfpangle-rfpangle)/3;

% figure; scatter(channel1(:),channel2(:),5,angle_deg,'filled');
Ca.celltype_angle_thres = threshold;


% angles = atand(cell2mat(Ca.celltype_REF(:,2)) ./ cell2mat(Ca.celltype_REF(:,1)));


selectivity = atand(double(channel2) ./ double(channel1));

%     selectivity = (activity-static)./(static+activity);
    x = round((size(selectivity,1)-FOV(1))/2);
    y = round((size(selectivity,2)-FOV(2))/2);
    selectivity = selectivity(x+1:end-x,y+1:end-y);
Ca = label_cell_type_ratio(Ca, selectivity);
Ca.celltype_REF_angle =  cell2mat(Ca.celltype_REF(:,3))<threshold;
%     static = static(x+1:end-x,y+1:end-y);
%     activity = activity(x+1:end-x,y+1:end-y);
% 
%     
%     % extract selectivity for ROIs
% %     Ca = label_cell_type_ratio(Ca, selectivity);
% Ca = label_cell_type_ratio2(Ca, static, activity);
% static = static(:);
% activity = activity(:);
% selectivity = round(100*static./activity);
% temp = prctile(selectivity,50);
% temp2 = prctile(activity,99);
% dlm = fitlm(static(selectivity<temp&activity>temp2),activity(selectivity<temp&activity>temp2),'Intercept',false);
% Ca.celltype_ration_REF = dlm.Coefficients.Estimate;


    if isempty(findstr(area_channel, 'A0')) == 0
        CaA0 = Ca;
        save([savefoldername '\' sessionfile], 'CaA0','-append', '-v6'); disp(['successfully save CaA0 to ' sessionfile])
    elseif isempty(findstr(area_channel, 'A1')) == 0
        CaA1 = Ca;
        save([savefoldername '\' sessionfile], 'CaA1','-append', '-v6');
    elseif isempty(findstr(area_channel, 'A2')) == 0
        CaA2 = Ca;
        save([savefoldername '\' sessionfile], 'CaA2','-append', '-v6'); disp(['successfully save CaA2 to ' sessionfile])
    elseif isempty(findstr(area_channel, 'A3')) == 0
        CaA3 = Ca;
        save([savefoldername '\'  sessionfile], 'CaA3','-append', '-v6'); disp(['successfully save CaA3 to ' sessionfile])
    end

end
