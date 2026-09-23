function b = recalculate_b(sessionfoldername, area_channel, sampling_rate, downsample_f, FOV, files, options, parallel_toggle)
if nargin < 8, parallel_toggle = true; end
% David updated to use inference_data instead of motion_corrected for Y if
% filename contains _dp
if ispc
    ds_filename = fullfile(sessionfoldername, 'PreProcess', area_channel, 'ds_data.mat');
elseif isunix
    ds_folder = getenv('TMPDIR');
    ds_filename = fullfile(ds_folder, 'ds_data.mat');
end

% here I check for previous runs and if ds data is available we'll use that
% -- to skip this simply delete ds_data.mat
ds_data_flag = isfile(ds_filename);
if ds_data_flag
    disp('loading ds_data.mat')
    data = matfile(ds_filename, 'Writable', true);
    if ~isprop(data, 'F_dark') || ~isprop(data, 'downsample_f') || (data.downsample_f ~= downsample_f)
        ds_data_flag = 0;
    end
end

if ~exist('data', 'var')
    data = matfile(ds_filename,'Writable',true); % create an object which don't load data into memory
end

n_files = length(files);

if ~ds_data_flag
    data_type = 'uint16';
    if ~parallel_toggle % ispc
        data.Y = zeros([FOV 0], data_type);
        data.Yr = zeros([prod(FOV), 0], data_type);
        data.sizY = [FOV, 0];
        data.downsample_f = downsample_f;
        F_dark = nan(n_files,1); %Inf;                                   % dark fluorescence (min of all data)
        Ts = zeros(n_files,1);                         % store length of each file
        cnt = 0;                                        
        tt1 = tic;
        for i = 1:n_files
            if contains(files{i}, 'denoised') % deepvid result
                temp = loadtiff(files{i});
            elseif contains(files{i}, '_dp')
                temp = load(files{i}, 'inference_data');
                temp = temp.inference_data;
            else
                temp = load(files{i}, 'motion_corrected');
                temp = temp.motion_corrected;
            end
            Ysub = cast(downsample_data(temp, 'time', downsample_f), data_type);
            fprintf('downsampled trial %i of %i', i, n_files)
            
            Ts(i) = size(temp,3);
            F_dark(i) = min(temp(:), [], 'omitnan');
            n_frame_sub = size(Ysub, 3);
            data.Y(:,:,cnt+1:cnt+n_frame_sub) = Ysub;
            data.Yr(:,cnt+1:cnt+n_frame_sub) = reshape(Ysub, [], n_frame_sub);

            toc(tt1);
            cnt = cnt + n_frame_sub; % count number of downsampled frames processed so far
        end
        data.sizY(1,3) = cnt;
        data.F_dark = min(F_dark, [], 'omitnan'); %;  F_dark;
        data.Ts = Ts;                                       % added by Jianguang
        sizY = data.sizY;                 % size of data matrix
    else %if isunix
        tic
        parfor i = 1:n_files
            if contains(files{i}, 'denoised') % deepvid result
                temp = loadtiff(files{i});
            elseif contains(files{i}, '_dp')
                temp = load(files{i}, 'inference_data'); % deepinterpolation result
                temp = temp.inference_data;
            else
                temp = load(files{i}, 'motion_corrected'); % non-inferenced data
                temp = temp.motion_corrected;
            end
            Ytemp(i).Y = cast(downsample_data(temp, 'time', downsample_f), data_type);
            fprintf('downsampled trial %i of %i', i, n_files)
        end
        toc;
        
        Y = cat(3, Ytemp(:).Y);
        data.Y = Y;
        data.Yr = reshape(Y, [], size(Y, 3));
        sizY = size(Y);
        data.sizY = sizY;
        data.F_dark = min(Y(:));
        data.downsample_f = downsample_f;
        
        %disp(['finished reading/downsampling mat files, elapsed time: ', num2str(toc(tt1)), 's']);
        clear Y;
    end
else
    sizY = data.sizY;
end

%% calculate from  data.Yr....
% bk_pix = (sum(A,2)==0);     % pixels with no active neurons
% [b,fin] = fast_nmf(double(data.Yr(bk_pix,:)),[],options.nb,50);

%% now run new CNMF on patches on the downsampled file, set parameters first
patch_size = [40,40];%/// [32, 32]       % size of each patch along each dimension (optional, default: [32,32])
overlap = [8,8];  % ////  [6,6]             % amount of overlap in each dimension (optional, default: [4,4])

patches = construct_patches(sizY(1:end-1),patch_size,overlap);
if ~exist('options', 'var')
    K = 4;                  % number of components to be found /// 10
    tau = 2;                 % std of gaussian kernel (size of neuron)//// 7
    p = 0;                   % order of autoregressive system //// 2 (p = 0 no dynamics, p=1 just decay, p = 2, both rise and decay)
    merge_thr = 0.8;         % merging threshold

    options = CNMFSetParms(...
        'd1',sizY(1),'d2',sizY(2),...
        'nb',1,...                                  % number of background components per patch
        'gnb',3,...                                 % number of global background components
        'fr',sampling_rate/downsample_f,...
        'ssub',2,...
        'downsample_f',4,...
        'p',p,...                                   % order of AR dynamics
        'merge_thr',merge_thr,...                   % merging threshold
        'gSig',tau,...
        'spatial_method','regularized',...
        'cnn_thr',0.2,...
        'patch_space_thresh',0.25,...
        'create_memmap', true,...
        'max_size_thr', 500,...
        'min_size_thr', 100,...
        'space_thresh', .5,...
        'min_SNR',2);
    options.foldername = fullfile(sessionfoldername, 'PreProcess', area_channel, filesep);
else
    K = 4;
    tau = options.gSig;
    p = options.p;
    options.fr = sampling_rate / downsample_f;
end
%%
% Run on patches (around 15 minutes)
% keyboard
[~, b] = run_CNMF_patches(data, K, patches, tau, p, options);

%delete(ds_filename);