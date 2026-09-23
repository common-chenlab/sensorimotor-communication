function [F_df, F_us, Fd_us, Ab_d] = extract_f(Anew, b, files, options, varargin)
% extract fluorescence and DF/F on native temporal resolution
% C is deconvolved activity, C + YrA is non-deconvolved fluorescence
% F_df is the DF/F computed on the non-deconvolved fluorescence

if length(varargin)<3
    prct = 30;
    window_l = 3000;
    shift = 1000;
else
    prct = varargin{1};
    window_l = varargin{2};
    shift = varargin{3};
end

numFiles = length(files);
if numFiles == 0, error('No files found to extract!'); end
P.p    = 0;                 % order of dynamics. Set P.p = 0 for no deconvolution at the moment
C_us   = cell(numFiles,1);  % cell array for thresholded fluorescence
f_us   = cell(numFiles,1);  % cell array for temporal background
YrA_us = cell(numFiles,1);  %
b_us   = cell(numFiles,1);  % cell array for spatial background
setup_parpool_SCC(); % setup parallel processing for SCC    fullfile('step3', sprintf('%s-A%i',session_name,area_num))
%ppm = ParforProgressbar(numFiles, 'parpool', 'local', 'Title','Extracting fluor signals'); % broken in matlab v2023+
parfor i = 1:numFiles
    [~,~,extn] = fileparts(files{i});
    if contains(extn, 'mat')
        if contains(files{i},'_dp')
            y_temp = load(files{i}, 'inference_data');
            y_temp = y_temp.inference_data;
            %Y = double(reshape(y_temp.inference_data,[],size(y_temp.inference_data,3)));
        else
            y_temp = load(files{i}, 'motion_corrected');
            y_temp = y_temp.motion_corrected;
            %Y = double(reshape(y_temp.motion_corrected,[],size(y_temp.motion_corrected,3)));
        end
    elseif contains(extn, 'tif')
        y_temp = loadtiff(files{i});
    end
    Y = double( reshape(y_temp,[],size(y_temp,3)) );

    [C_us{i},f_us{i},~,~,YrA_us{i}] = update_temporal_components_axg(Y, Anew, b, [], [], P, options);
    b_us{i} = max( mm_fun(f_us{i},Y) - double(Anew)*(C_us{i}*f_us{i}'), 0 )/norm(f_us{i})^2;
    %ppm.increment();
end
%delete(ppm); % Delete the progress handle when the parfor loop is done.

%
F_us = cellfun(@plus, C_us, YrA_us, 'un',0);        % cell array for projected fluorescence
prctfun = @(data) prctfilt(data, prct, window_l, shift, 0);       % first detrend fluorescence (remove 30th percentile on a rolling 1000 timestep window)
Fd_us = cellfun(prctfun, F_us, 'un',0);             % detrended fluorescence

Ab_d = cell(numFiles,1);                            % now extract projected background fluorescence
parfor i = 1:numFiles
    Ab_d{i} = prctfilt((bsxfun(@times, Anew, 1./sum(Anew.^2))'*b_us{i})*f_us{i}, prct, window_l, shift, 0);
end

F0 = cellfun(@plus, cellfun(@(x,y) x-y,F_us,Fd_us,'un',0), Ab_d,'un',0);   % add and get F0 fluorescence for each component
% DF/F value
F_df = cellfun(@(x,y) x./y, Fd_us, F0 ,'un',0);
end