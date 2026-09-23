function CHEN_2P_Pipeline_Step_02b(source_dir, animal, sess, varargin) % , area_channel, downsample_f, subsession, save_alts, K, tau, p, options, slack_flag
%add_pipeline_paths();
[sess_dir, sessionfile, area_channel, area_name, downsample_f, subsession, save_alts, K, tau, p, options, Ca, session_mat_file, reference_image, do_parallel, slack_flag] = ...
    parse_inputs(source_dir, animal, sess, varargin{:}); 
if do_parallel, setup_parpool_SCC(''); end

%% CNMF calcium extraction : downsampling files
ds_path = fullfile(sess_dir, 'PreProcess', area_channel, 'ds_data.mat');
ds_data_flag = isfile(ds_path);
%{ 
% this seems to cause errors
if isunix
    ds_folder = getenv('TMPDIR');
    if isempty(ds_folder),  ds_folder = '/tmp';  end
    if ds_data_flag,  movefile(ds_filename, ds_folder);  end
    ds_filename = fullfile(ds_folder, 'ds_data.mat');
    ds_data_flag = isfile(ds_filename);
end
%}
% here I check for previous runs and if ds data is available we'll use that, to skip this simply delete ds_data.mat
if ds_data_flag
    data = matfile(ds_path, 'Writable', true);
    if ~isprop(data, 'F_dark') || ~isprop(data, 'tsub') || (data.tsub ~= downsample_f),  ds_data_flag = 0;  end
end
if ~exist('data', 'var')
    data = matfile(ds_path,'Writable',true); % create an object which doesn't load data into memory
end

files = dir(fullfile(sess_dir, 'PreProcess', area_channel, [area_channel, '*.mat']));   % list of Avg files
files(contains({files.name}, '_dp')) = []; % exclude deep interp versions if they exist
numFiles = length(files);

% Downsample the trials
if ~ds_data_flag
    data_type = 'uint16';
    trial_means = zeros([Ca.FOV, numFiles]);
    Ts = zeros(numFiles,1); % store length of each file
    F_dark = Inf;  % dark fluorescence (min of all data)
    tt1 = tic;
    if ~do_parallel 
        data.Y = zeros([Ca.FOV 0], data_type);
        data.Yr = zeros([prod(Ca.FOV), 0], data_type);
        data.sizY = [Ca.FOV, 0];
        data.tsub = downsample_f; % tsub
        cnt = 0;                                        % number of frames processed so far
        for i = 1:numFiles
            name = fullfile(files(i).folder, files(i).name);
            disp(['downsampling this trial: ', files(i).name])
            temp = load(name, 'motion_corrected');
            trial_means(:,:,i) = mean(temp.motion_corrected, 3);
            Ts(i) = size(temp.motion_corrected,3);
            F_dark = min(min(temp.motion_corrected(:), [], 'omitnan'), F_dark);
            Ysub = cast(downsample_data(temp.motion_corrected, 'time', downsample_f), data_type);
            ln = size(Ysub, 3);
            disp(['downsampled trial: ', num2str(i), ' out of: ', num2str(numFiles)])
            data.Y(:, :, cnt+1:cnt+ln) = Ysub;
            data.Yr(:, cnt+1:cnt+ln) = reshape(Ysub, [], ln);
            toc(tt1);
            cnt = cnt + ln;
            data.sizY(1,3) = cnt;
            clearvars motion_corrected  %just to make sure nothing funky happens
        end
        data.F_dark = F_dark;
        data.Ts = Ts;                                       % added by Jianguang
        sizY = data.sizY;                 % size of data matrix
    else 
        ppm = ParforProgressbar(numFiles, 'parpool', 'local', 'Title','downsampling'); 
        parfor i = 1:numFiles
            temp = load(fullfile(files(i).folder, files(i).name), 'motion_corrected');
            Ts(i) = size(temp.motion_corrected,3); 
            F_dark = min(min(temp.motion_corrected(:), [], 'omitnan'), F_dark);
            trial_means(:,:,i) = mean(temp.motion_corrected, 3);
            Ytemp(i).Y = cast(downsample_data(temp.motion_corrected, 'time', downsample_f), data_type);
            disp(['downsampled trial: ', num2str(i), ' out of: ', num2str(numFiles)]);
            %toc(tt1);
            ppm.increment();
        end
        delete(ppm); % Delete the progress handle when the parfor loop is done.
        % parfor took ~6 mins
        tic
        fprintf('\n%s: Exporting data to mat file (could take ~20 mins)...', TimeStamp)
        Y = cat(3, Ytemp(:).Y);  % 7 s
        data.Y = Y; % 416.758459 s
        data.Yr = reshape(Y, [], size(Y, 3)); % 666.695813 s
        toc

        sizY = size(Y);
        data.sizY = size(Y);
        data.F_dark = F_dark;
        data.Ts = Ts;
        data.tsub = downsample_f;
        disp(['finished reading mat files, elapsed time: ', num2str(toc(tt1)), 's']);
        clearvars Y Ytemp;
    end
else
    sizY = data.sizY;
end

if save_alts
    average_image_file = fullfile(sess_dir, 'PreProcess', ['average_', area_channel, '.tif']);
    activity_map_file = fullfile(sess_dir, 'PreProcess', ['alternative_activity_', area_channel, '.tif']);
    if ~ds_data_flag
        %save an image which is an average of all trials
        average_image = mean(trial_means, 3, 'omitnan');
        average_image = 65535*(average_image-min(average_image(:)))/(max(average_image(:))-min(average_image(:)));
        imwrite(uint16(average_image), average_image_file);

        %saving an activity image generated from the mean of the differences between trials
        result = zeros([Ca.FOV, size(trial_means,3)-1]);
        for i = 1:size(trial_means,3)-1
            result(:,:,i) = abs(trial_means(:,:,i)-trial_means(:,:,i+1))./(trial_means(:,:,i)+trial_means(:,:,i+1));
        end
        activity_map = mean(result, 3, 'omitnan');
        low_thres = prctile(activity_map(:),0.1);
        high_thres = prctile(activity_map(:),99.5);
        activity_map(activity_map<low_thres) = low_thres;
        activity_map(activity_map>high_thres) = high_thres;
        activity_map = 65535*(activity_map-min(activity_map(:)))/(max(activity_map(:))-min(activity_map(:)));
        imwrite(uint16(activity_map), activity_map_file);
    else
        average_image = im2double(imread(average_image_file));
        activity_map = im2double(imread(activity_map_file));
    end
end
% {
%% now run new CNMF on patches on the downsampled file, set parameters first
patch_size = [40,40];%/// [32, 32]       % size of each patch along each dimension (optional, default: [32,32])
overlap = [8,8];  % ////  [6,6]             % amount of overlap in each dimension (optional, default: [4,4])
patches = construct_patches(sizY(1:end-1),patch_size,overlap); % sizY
options.d1 = sizY(1);
options.d2 = sizY(2);
options.fr = Ca.sampling_rate / downsample_f;

%%
disp('running patches')
% Run on patches
fprintf('\nrun_CNMF_patches...')
tic
[A, b, C, f, ~, P, ~, YrA] = run_CNMF_patches(data, K, patches, tau, p, options); % 1.2 hours
toc

% compute correlation image on a small sample of the data (optional - for visualization purposes)
fprintf('\nCorrelation_image_max...')
tic
Cn = correlation_image_max(data, 8); % 4 mins
toc

% classify components
fprintf('\nClassifying components...')
tic
[~, ~, ~, ~, keep] = classify_components(data, A, C, b, f, YrA, options); % 25 mins
toc

%% run GUI for modifying component selection (optional, close twice to save values)
Coor = plot_contours(A,Cn,options,1); close;
keep = filter_border_ROIs_jc(keep, Ca.FOV, Coor);

%% view contour plots of selected and rejected components (optional)
throw = ~keep;
figure;
ax1 = subplot(121); plot_contours_old(A(:,keep),Cn,options,1,[],Coor,1,find(keep)); title('Selected components','fontweight','bold','fontsize',14);
ax2 = subplot(122); plot_contours_old(A(:,throw),Cn,options,1,[],Coor,1,find(throw));title('Rejected components','fontweight','bold','fontsize',14);
linkaxes([ax1,ax2],'xy')

%% plot all rois including manually drawn ones
figure,
plot_contours_old(A,Cn,options,1,[],Coor,1,1:size(A,2)); title('Selected components','fontweight','bold','fontsize',14);

%% keep only the active components
A_keep = A(:,keep);

%% extract fluorescence and DF/F on native temporal resolution
% C is deconvolved activity, C + YrA is non-deconvolved fluorescence
% F_df is the DF/F computed on the non-deconvolved fluorescence
P.p = 0;                    % order of dynamics. Set P.p = 0 for no deconvolution at the moment
options.fr = Ca.sampling_rate; % restore native temporal resolution

C_us = cell(numFiles,1);    % cell array for thresholded fluorescence
f_us = cell(numFiles,1);    % cell array for temporal background
YrA_us = cell(numFiles,1);
b_us = cell(numFiles,1);    % cell array for spatial background
tic
wb = waitbar(0, 'updating temporal components');
for i = 1:numFiles % 69 mins
    filename = fullfile(files(i).folder, files(i).name);
    mat_data = matfile(filename);
    frames = size(mat_data, 'motion_corrected', 3);
    mc_data = single(reshape(mat_data.motion_corrected, [], frames));

    %disp(['updating temporal components for: ', filename]);
    [C_us{i},f_us{i},~,~,YrA_us{i}] = update_temporal_components_axg(mc_data, A_keep, b, [], [], P, options);
    b_us{i} = max(mm_fun(f_us{i}, mc_data) - A_keep*(C_us{i} * f_us{i}'), 0)/norm(f_us{i})^2;
    waitbar(i/numFiles, wb)
end
close(wb)
toc
F_us = cellfun(@plus,C_us,YrA_us,'un',0);           % cell array for projected fluorescence
%prctfun = @(data) prctfilt(data,30,1000,300);       % first detrend fluorescence (remove 30th percentile on a rolling 1000 timestep window)
%Fd_us = cellfun(prctfun,F_us,'un',0);               % detrended fluorescence

Ab_d = cell(numFiles,1);                            % now extract projected background fluorescence
for i = 1:numFiles
    Ab_d{i} = prctfilt((bsxfun(@times, A_keep, 1./sum(A_keep.^2))'*b_us{i})*f_us{i},30,1000,300,0);
end

%% export all necessary files for step 3
% Use F_dF and Coor
close all;

ROIs = Coor(keep);
% ROIs    = Coor;
[CC, ~] = plot_contours2(Cn,1,ROIs,reference_image, sess_dir, Ca.ref_trial);

if save_alts
    %plot cnmf results on different images for validation purposes
    plot_rois(sess_dir, activity_map, CC, 'alternative', area_channel)
    plot_rois(sess_dir, average_image, CC, 'average', area_channel)
    Cn = uint16((2^16-1)*(Cn-min(Cn(:)))/(max(Cn(:))-min(Cn(:))));
    plot_rois(sess_dir, Cn, CC, 'corr', area_channel)
end

% /// generate cell labels
cellid = cell(length(ROIs), 1);
celltype = cell(length(ROIs), 1);
cellalgo = cell(length(ROIs), 1);
for i = 1:length(ROIs)
    cellid{i,1} = [sessionfile(1:end-4) '-' area_channel(1:2) '-' sprintf('%04d', i) '-temp'];
    celltype{i,1} = 'U';
    cellalgo{i,1} = 'CNMF';       % added by Jianguang
end

% save information to the main mat file
Ca.b = b;
Ca.F_dF = F_us;
Ca.ROIs = ROIs;
Ca.cellid = cellid;
Ca.celltype = celltype;
Ca.cellalgo = cellalgo;
Ca.CNMFOptions = options;
session_mat_file.(area_name) = Ca;
disp(['successfully save ', area_name, ' to ', sessionfile])

delete(ds_path);

if slack_flag
    SendSlackNotification('REDACTED_SLACK_WEBHOOK', ...
        ['2P PIPELINE STEP 02b ' animal '-' sess subsession ' ' area_channel ' is finished'], '#e_pipeline_log');
end

%{
if exist('slackID','var')
    if ~isempty(slackID)
        SendSlackNotification('REDACTED_SLACK_WEBHOOK', ...
            ['<@', slackID, '> 2P PIPELINE STEP 02b ' animal '-' sess subsession ' ' area_channel ' is finished'], '#e_pipeline_log');
    else

    end
end
%}
end


% SUBFUNCTIONS
%INPUT PARSER-----------------------------------------------------
function [session_dir, sessionfile, area_channel, area_name, downsample_f, subsession, save_alts, K, tau, p, options, Ca, session_mat_file, reference_image, do_parallel, slack_flag] = parse_inputs(source_dir, animal, sess, varargin) 
check_input = @(x)(ischar(x) || isnumeric(x));
IP = inputParser;
addRequired( IP, 'source_dir', @ischar )
addRequired( IP, 'animal', @ischar )
addRequired( IP, 'sess', check_input )  % @ischar
addParameter( IP, 'subsession', '', check_input )
addParameter( IP, 'area_num', 0, check_input )
addParameter(IP, 'chan', 1, @isnumeric )
addParameter(IP, 'downsample', 10, @isnumeric )
addParameter(IP, 'save_alts', true, @islogical )
addParameter(IP, 'options', [], @isstruct)
addParameter(IP, 'p', 2, @isnumeric) 
addParameter(IP, 'K', 4, @isnumeric) 
addParameter(IP, 'tau', [5,10], @isnumeric) 
addParameter(IP, 'parallel', true, @islogical)
addParameter( IP, 'slack', true, @islogical ) % '', @ischar
parse( IP, source_dir, animal, sess, varargin{:} ); % area_num,
if isnumeric(sess), sess = num2str(sess); end
area_num = IP.Results.area_num;
chan = IP.Results.chan;
area_channel = sprintf('A%i_Ch%i', area_num, chan);
downsample_f = IP.Results.downsample;
subsession = IP.Results.subsession;
save_alts = IP.Results.save_alts;
K = IP.Results.K;
tau = IP.Results.tau;
p = IP.Results.p;
do_parallel = IP.Results.parallel;
slack_flag = IP.Results.slack;

% Set up file paths and names
sess_name = sprintf('%s-%s', animal, sess); %[anm , '-', sessionNo];       % e.g.'jn018-1'; full session name
sessionfile = [sess_name '.mat'];         % final session file name for save
session_dir = fullfile(source_dir, animal, '2P', sess_name, filesep);
savefoldername = fullfile(source_dir, animal, filesep);
if ~isempty(subsession)
    subsessionName = [animal subsession '-' sess];
    session_dir = fullfile(source_dir, animal, '2P', sess_name, subsessionName, filesep);
    sessionfile = [subsessionName '.mat'];
    savefoldername = fullfile(source_dir, animal, '2P', sess_name, filesep);
end

% Open the main .mat file for this session
session_mat_path = fullfile(savefoldername, sessionfile);
fprintf('\nOpening %s', session_mat_path);
session_mat_file = matfile(session_mat_path, 'Writable', true);
area_name = ['Ca', extractBefore(area_channel, '_Ch')];
Ca = session_mat_file.(area_name);

% Load the reference image
ref_im_path = fullfile(session_dir, 'PreProcess', area_channel, 'Avg2a', Ca.ref_trial);
fprintf('\nLoading %s', ref_im_path)
reference_image = im2double(imread(ref_im_path)); % imshow(reference_image,[])

% Get the options for CNMF
options = IP.Results.options;
if ~exist('options', 'var') || isempty(options)
    options = CNMFSetParms(...
        'nb', 1,...
        'gnb', 3,...
        'ssub', 1,...
        'tsub', 1,...
        'merge_thr', 0.8,...
        'spatial_method', 'regularized',...
        'spatial_parallel', 1,...
        'cnn_thr', 0.2,...
        'patch_space_thresh', 0.25,...
        'max_size_thr', 500,...
        'min_size_thr', 100,...
        'space_thresh', 0.5,...
        'min_SNR',2);
end
options.d1 = NaN; %sizY(1);
options.d2 = NaN; %sizY(2);
options.p = p;
options.fr = Ca.sampling_rate/downsample_f; %NaN; %fr / tsub;
options.gSig = tau;
options.foldername = fullfile(session_dir, 'PreProcess', area_channel, filesep);

end

% PLOT ROIS ----------------------------------------------------------
function plot_rois(sessionfoldername, image, CC, label, area_channel)

[d1, d2] = size(image);
max_number = size(CC,1);
cmap = hot(3*size(CC,1));
imagesc(image);
colormap(gray);
axis tight; axis equal;
posA = get(gca,'position');
set(gca,'position',posA);
hold on;
for i = 1:size(CC,1)
    if size(CC{i},2) > 1
        cont = medfilt1(CC{i}')';
        plot(cont(1,2:end),cont(2,2:end),'Color',cmap(i+size(CC,2),:), 'linewidth', 1); hold on;
    end
end

for i = 1:size(CC,1)
    BW = poly2mask(CC{i}(1,:), CC{i}(2,:), d1, d2);
    Aor(:,i) = reshape(BW,[1 d1*d2]);
end
cm = com(Aor(:,1:end),d1,d2);

lbl = strtrim(cellstr(num2str((1:size(CC,1))')));
text(round(cm(1:max_number,2)),round(cm(1:max_number,1)),lbl(1:max_number),'color',[1,1,1],'fontsize',8,'fontname','helvetica','fontweight','bold');
axis off;

set(gca,'position',[0 0 1 1],'units','normalized')

saveas(gcf, fullfile(sessionfoldername, 'PreProcess', ['CNMF_', label, '_', area_channel, '.tif']));
test = imread(fullfile(sessionfoldername, 'PreProcess', ['CNMF_', label, '_', area_channel, '.tif']));
blue = test(:,:,3);
x = mean(blue,1);
x = x<255;
first_x = find(x,1, 'first');
last_x = find(x,1, 'last');

y = mean(blue,2);
y = y<255;
first_y = find(y,1, 'first');
last_y = find(y,1, 'last');

test = test(first_y:last_y, first_x:last_x,:);
test = imresize(test, [d1 d2]);
imwrite(test, fullfile(sessionfoldername, 'PreProcess', ['CNMF_', label, '_', area_channel, '.tif']));

end