function roiMask = ROI_boundary2mask(roiBound,FOV)
% Accepts ROI boundary pixels as stored in ROI_list and outputs the pixels
% contained in that boundary
x = roiBound(:,2);
y = roiBound(:,1);

% Create a dummy space where the ROI boundary exists (needed for mask2poly)
roiMask = false(FOV(1),FOV(2));

for rC = 1:length(x)
    roiMask(y(rC),x(rC)) = 1;
end

P = mask2poly(roiMask);
inPoints = polygrid(P(:,1),P(:,2),1);

for rC2 = 1:length(inPoints)
    roiMask(inPoints(rC2,2),inPoints(rC2,1)) = 1;
end
% figure; imshow(roiMask,[0 1]);

end

function [inPoints] = polygrid( xv, yv, ppa)

N = sqrt(ppa);
%Find the bounding rectangle
lower_x = min(xv);
higher_x = max(xv);

lower_y = min(yv);
higher_y = max(yv);
%Create a grid of points within the bounding rectangle
inc_x = 1/N;
inc_y = 1/N;

interval_x = lower_x:inc_x:higher_x;
interval_y = lower_y:inc_y:higher_y;
[bigGridX, bigGridY] = meshgrid(interval_x, interval_y);

%Filter grid to get only points in polygon
in = inpolygon(bigGridX(:), bigGridY(:), xv, yv);
%Return the co-ordinates of the points that are in the polygon
inPoints = [bigGridX(in), bigGridY(in)];

end