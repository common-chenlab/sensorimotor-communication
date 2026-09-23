function output = CHEN_Flip_Signed(filename, save_tiff, xshift)
%UCLA STEM Analysis - Peeling/Fitting
%Multi dataset event analysis
%adrcheng@ucla.edu 2010

if nargin == 0
    filename = 'X:\Projects\Transplant\sz001\2026-02-17\14-58-43_Stack\test_A0_Ch1_ 0003.tif';
    save_tiff = 1;
end
if nargin < 3
    xshift = [];
end
if isstring(filename)
    filename = char(filename);
end

timing = tic;

[pathway, file, ext] = fileparts(filename);
file = [file, ext];

if save_tiff == 1
    if ~isfolder('PreProcess') && isempty(pathway)
        mkdir('PreProcess');
    elseif ~isfolder(fullfile(pathway, 'PreProcess', filesep))
        mkdir(fullfile(pathway, 'PreProcess', filesep));
    end

    %output file characteristics
    if isempty(pathway)
        output.filename = fullfile('PreProcess', ['PreProcess_',filename]);
    else
        output.filename = fullfile(pathway, 'PreProcess', ['PreProcess_',file]);
    end
end

raw_data = readTiff(filename);

[height, width, nframes] = size(raw_data);

output_height = height*2;
output_width = width/2;

%dividing image into its two halves to be able to use phase correlation
avg = mean(raw_data, 3);
imgl = avg(:,1:width/2);
imgr = avg(:,width/2+1:end);
imgr = flip(imgr,2);

if isempty(xshift)
    tf = imregcorr(imgr, imgl, "translation");
    tf.T(3, 2) = 0;
    xshift = tf.T(3, 1);
else
    tf = affine2d;
    tf.T(3, 1) = xshift;
end
clear avg imgl imgr;
%////////////////////////////////

disp(['xshift: ', num2str(xshift)])

%shifting the raw data so the two halves are aligned after splitting
raw_data = circshift(raw_data, round(-xshift/2), 2);
imgl_new = raw_data(:, 1:width/2, :);
imgr_new = flip(raw_data(:, width/2+1:end, :), 2);

clear raw_data;

output.data_flipped = zeros(output_height, output_width, nframes, 'uint16');
for i=1:output_height
    if mod(i,2)==1
        output.data_flipped(i,:,:)=imgl_new((i+1)/2,:,:);
    else
        output.data_flipped(i,:,:)=imgr_new(i/2,:,:);
    end
end
clear imgr_new imgl_new;
output.xshift = xshift;

%de-warping the aligned and combined image
[xmap, ymap] = makeMaps2(output_height, output_width);
output.data_sined = zeros(output_height, output_width, nframes);
for i = 1:nframes
    output.data_sined(:, :, i) = interp2(output.data_flipped(:, :, i), xmap, ymap, 'nearest');
end

if save_tiff
    out_max = max(output.data_sined(:));
    if out_max < (2^16)/125
        output.data_sined = output.data_sined * 100;
    end
    
    WriteTiff(output.filename, uint16(output.data_sined));

    if isunix
        fileattrib(tiff_info.filename,'+w','g');
    end
end

toc(timing);
