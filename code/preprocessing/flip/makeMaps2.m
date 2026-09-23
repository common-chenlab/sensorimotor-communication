% Purpose
%       make x and y maps used for interpolating 2P data collected
%       with a resonance scanner (x map is inverse sin, y is the same
%       as original coordinates)
% Input
%       rows : number of rows in data
%       cols : number of cols in data
% Output
%       xmap : inverse sin map of original x coordinates
%       ymap : original y coordinates

function [xmap, ymap] = makeMaps2(rows, cols)

ytemp = (1:rows)';
ymap = repmat(ytemp, 1, cols);

xtemp = 0:(1 / (cols - 1)):1;
xtemp2 = -(cols - 1) * ((1 / pi) * asin(-2 * xtemp + 1) - 0.5) + 1;
xmap = repmat(xtemp2, rows, 1);