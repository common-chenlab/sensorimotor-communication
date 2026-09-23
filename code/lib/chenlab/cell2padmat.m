function [ y ] = cell2padmat( x )
% cell2padmat takes an cell array of 1 or 2-d matrices with (potentially) unequal heights and
% creates a matrix with the contents of each cell horizontally concatenated. Since the
% cells can have uneven number, the smaller columns are padded with NaN.
% This function was made to use with boxplot.
% Make sure input has proper dimensions
[Nrow,n_cell] = size(x);
if Nrow*n_cell ~= length(x)
    error('Input cell array must be 1 dimensional. ') 
elseif Nrow > n_cell
    x = x';
end

cell_height = cellfun(@height, x);
cell_width = cellfun(@width, x);
cum_width = [0,cumsum(cell_width)];

y = NaN( max(cell_height), sum(cell_width) ); 
for col = 1:n_cell
    y(1:cell_height(col), cum_width(col)+1:cum_width(col+1)) = x{col};
end
end