function panelTracking(ROI_mask, scaleFactor, fullpath, framerate)

% clear all;
close all hidden;

structure = struct([]);

videoFN = fullpath;
%%%%%%% Use bottom line if video is located in a subfolder

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

%     figure(1);
%     imshow(background);
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
videoPlayer = vision.VideoPlayer('Position', [755 100 width+15 height+30]);
%      videoPlayer3 = vision.VideoPlayer('Position', [755 100 width+15 height+30]);
%      videoPlayer4 = vision.VideoPlayer('Position', [755 100 width+15 height+30]);
% Reload FileReader afterwards so 1st frame is not lost


drawLine = vision.ShapeInserter('Shape', 'Lines',...
    'BorderColor', 'Custom', 'CustomBorderColor', [0 1 0]);
drawEndPointYellow = vision.ShapeInserter('Shape', 'Circles',...
    'BorderColor', 'Custom', 'CustomBorderColor', [1 1 0]);
drawEndPointRed = vision.ShapeInserter('Shape', 'Circles',...
    'BorderColor', 'Custom', 'CustomBorderColor', [1 0 0]);
% initialise video player with desired dimensions.



currFrame = 0;
counter = 0;
while ~isDone(videoFReader)
    currFrame = currFrame + 1;
    % play video frame by frame
    videoFrame = step(videoFReader);
    if currFrame > 900*(framerate/500)
        videoFrameGr = rgb2gray(videoFrame);
        level = scaleFactor*graythresh(videoFrameGr);
        videoFrameBW = im2bw(videoFrameGr,level);
        % convert the current frame from RGB to BW
        
        foregroundGr = backgroundGr-videoFrameGr;
        foregroundBW = backgroundBW-videoFrameBW;
        %substract background
    end
    
    if ~trackObject
        if currFrame > 900*(framerate/500)
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
                %                     edges(edgesXMax-100:edgesXMax,1:75) = 0;
                %                     edges(225:edgesXMax,1:60) = 0;
                %                     % the above 2 create a rectangular boxes near the bottom left
                %                     % corner in attempt to remove detection of whiskers.
                %
                %                     [cutoffXLow, ~, ~] = find(edges(edgesXMax-100:edgesXMax,:)==1);
                %                     if isempty(cutoffXLow)
                %                         cutoffXLow = edgesXMax;
                %                     else
                %                         %                     cutoffXLow = edgesXMax - min(cutoffXLow) - 5;
                %                         cutoffXLow = edgesXMax;
                %                     end
                %                     edges(cutoffXLow:edgesXMax,:) = 0;
                % cutoffXLow removes the detection of the shadow in the bottom
                % part of the image
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                [pointsX, pointsY] = find(edges==1);
                pointsX = pointsX + ROIxmin;
                pointsY = pointsY + ROIymin;
                % extract coordinates of the texture panel edges
                videoFrame = step(drawEndPointYellow, videoFrame, ...
                    [pointsY pointsX 0.5*ones(length(pointsX),1)]);
                % draw the edges on the current frame
                structure(end+1).fid = currFrame;
                structure(end).pointsX = pointsX;
                structure(end).pointsY = pointsY;
                % add coordinates and the current frame to the structure
            end
        end
    else
        counter = counter + 1;
        I = find(videoFrameBW<0.5);
        numDarkPixelsCurrFrame = size(I,1);
        I = foregroundBW(ROIxmin:ROIxmax,ROIymin:ROIymax);
        I = medfilt2(I,[5 5]);
        %{
        if currFrame == 1550*(framerate/500)
            I ;
        end
        %}
        edges = edge(I,'canny');%,[0.4 0.99]);
        edges = edges.*ROI_mask;
        
        %             edges(edgesXMax-100:edgesXMax,1:75) = 0;
        %             edges(300:edgesXMax,1:60) = 0;
        %             % the above 2 remove detection of whiskers
        %             edges(cutoffXLow:edgesXMax,:) = 0;
        % cutoffXLow removes the detection of the shadow in the bottom
        % part of the image
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        [pointsX, pointsY] = find(edges==1);
        pointsX = pointsX + ROIxmin;
        pointsY = pointsY + ROIymin;
        % extract coordinates of the texture panel edges
        videoFrame = step(drawEndPointYellow, videoFrame, ...
            [pointsY pointsX 0.5*ones(length(pointsX),1)]);
        % draw the edges on the current frame
        structure(end+1).fid = currFrame;
        structure(end).pointsX = pointsX;
        structure(end).pointsY = pointsY;
        % add coordinates and the current frame to the structure
        
        %                  step(videoPlayer4, edges);
        % display the ROI with the detected edges
        %             end
    end
    
    step(videoPlayer, videoFrame);
    % display original video frame (detected edges are drawn on these
    % frames)
    %          step(videoPlayer3, foregroundGr);
    % display the grayscale foreground
end

object = structure;
mat_filename = [videoFN(1:end-4) '.mat'];
if exist(mat_filename)
    save(mat_filename,'object','-append');
else
    save(mat_filename,'object');
end


% store the structure for the current video

release(videoPlayer);
%     release(videoPlayer3);
release(videoFReader);
% close player and file reader
