function panelTracking_parallel(ROI_mask, scaleFactor, fullpath, framerate)

%% FIND BETTER WAY TO SET ROIymin, ROIymax, ROIxmin, ROImax

% clear all;
close all hidden;

structure = struct([]);

videoFN = fullpath;
%%%%%%% Use bottom line if video is located in a subfolder

v = VideoReader(videoFN);
numFrames = ceil(v.FrameRate*v.Duration);

videoFReader = vision.VideoFileReader(videoFN);
frame1 = step(videoFReader);
% load first frame to obtain dimensions and obtain background.
width = size(frame1,2);
height = size(frame1,1);

%% FIND BETTER WAY TO SET ROIymin, ROIymax, ROIxmin, ROImax
ROIymin = 1;
ROIymax = width;
ROIxmin = 1;
ROIxmax = height;
% specify region of interest (notice that in images and videos dimensions
% are flipped)


%% get dimensions
frame2 = step(videoFReader);
frameDiff = frame1-frame2;
background = frame1 - frameDiff;
% get background

H = fspecial('average', [20 20]);
H2 = fspecial('average', [9 9]);
background = imfilter(background, H);
background = imfilter(background, H);
background = imfilter(background, H);
background = imfilter(background, H2);
% smooth the image using average filter to remove whiskers from 1st frame

backgroundGr = rgb2gray(background);
frame1Gr = rgb2gray(frame1);
level = scaleFactor*graythresh(frame1Gr);
frame1BW = im2bw(frame1Gr,level);
level = scaleFactor*graythresh(backgroundGr);
backgroundBW = im2bw(backgroundGr,level);
I = find(frame1BW<0.5);
numDarkPixelsFrame1 = size(I,1);
darkThreshold = max(numDarkPixelsFrame1*1.10,1000);
% get a rought number of dark pixels in first frame.

trackObject = 0;
% boolean indicating whether algorithm should track an existing object or
% wait for it to appear.

videoFReader = vision.VideoFileReader(videoFN);
% Reload FileReader afterwards so 1st frame is not lost

for i = 1:numFrames    
    % play video frame by frame
%     videoFrame = read(v,i);
    videoFrame = step(videoFReader);
    
    if i > 900*(framerate/500)
     
        videoFrameGr = videoFrame;
        level = scaleFactor*graythresh(videoFrameGr);
        videoFrameBW = im2bw(videoFrameGr,level);
        % convert the current frame from RGB to BW
                          
%         foregroundGr = backgroundGr-videoFrameGr;
        foregroundBW = backgroundBW-videoFrameBW;
        %substract background
    end

    if ~trackObject
        if i > 900*(framerate/500)
            % detect when texture panel appears by a sudden increase in the
            % number of dark pixels
            I = find(videoFrameBW<0.5);
            numDarkPixelsCurrFrame = size(I,1);
            if numDarkPixelsCurrFrame > darkThreshold
                % texture panel has appeared. Try to detect it.
                 trackObject = 1;
                
                % EDGE DETECTION
                I = foregroundBW(ROIxmin:ROIxmax,ROIymin:ROIymax);
                I = medfilt2(I,[5 5]);
                edges = edge(I,'canny');%,[0.4 0.99]);
                edgesXMax = size(edges,1);
                edgesYMax = size(edges,2);
                edges = edges.*ROI_mask;
                            
                [pointsX, pointsY] = find(edges==1);
                pointsX = pointsX + ROIxmin;
                pointsY = pointsY + ROIymin;
                % extract coordinates of the texture panel edges

                structure(i).fid = i;
                structure(i).pointsX = pointsX;
                structure(i).pointsY = pointsY;
                % add coordinates and the current frame to the structure
            end
        end
    else        
        I = find(videoFrameBW<0.5);
        numDarkPixelsCurrFrame = size(I,1);
        I = foregroundBW(ROIxmin:ROIxmax,ROIymin:ROIymax);
        I = medfilt2(I,[5 5]);
     
        edges = edge(I,'canny');%,[0.4 0.99]);
        edges = edges.*ROI_mask;
        
        
        [pointsX, pointsY] = find(edges==1);
        pointsX = pointsX + ROIxmin;
        pointsY = pointsY + ROIymin;
        % extract coordinates of the texture panel edges

        structure(i).fid = i;
        structure(i).pointsX = pointsX;
        structure(i).pointsY = pointsY;
        % add coordinates and the current frame to the structure
             
    end
    %{
    if mod(i,100) == 0
        i
    end
    %}
end

object = structure;
mat_filename = [videoFN(1:end-4) '.mat'];
if exist(mat_filename)
    save(mat_filename,'object','-append');
else
    save(mat_filename,'object');
end


% store the structure for the current video


release(videoFReader);
% close player and file reader
