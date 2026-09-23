function [output_path, output_path_exists] = ChenLabFilepath(input_path, as_str) %
if isstring(input_path), input_path = char(input_path); end
if nargin < 2, as_str = ''; end % set as_str to 'unix' to force unix-style output, 'pc' to force pc-style output
%input_path = '/net/claustrum/mnt/data/Animals\sm052/test\\'; %'/net/claustrum/mnt/data/Animal'

% Automatically reformat file paths to suit the enviroment (linux vs PC) for the Chen lab
drive_map = {'Z:\', '/net/claustrum/mnt/data/'; ...
    'Y:\','/net/claustrum/mnt/data1/';...
    'X:\', '/net/claustrum2/mnt/data/'; ...
    'W:\', '/net/claustrum3/mnt/data/'; ...
    'V:\', '/net/claustrum4/mnt/storage/data/';};
n_drive = size(drive_map,1);

% Determine which environment's formatting style to use (by default, use the native environment)
if isempty(as_str)
    if isunix
        as_str = 'unix';
    else
        as_str = 'pc';
    end
end
if ~strcmpi(as_str, 'pc') && ~strcmpi(as_str, 'unix'), error('as_str must be pc or unix'); end

% Format the path accordingly
if strcmpi(as_str,'unix')
    drive_row = find(cellfun(@contains, repmat({input_path},n_drive,1), drive_map(:,1)));
    if ~isempty(drive_row)
        output_path = replace(input_path, drive_map{drive_row,1}, drive_map{drive_row,2});
    else
        output_path = input_path;
    end
    output_path(strfind(output_path, '\')) = '/';
    output_path = replace(output_path, '//','/' );
elseif strcmpi(as_str,'pc')
    drive_row = find(cellfun(@contains, repmat({input_path},n_drive,1), drive_map(:,2)));
    if ~isempty(drive_row)
        output_path = replace(input_path, drive_map{drive_row,2}, drive_map{drive_row,1});
    else
        output_path = input_path;
    end
    output_path(strfind(output_path, '/')) = '\';
    output_path = replace(output_path, '\\','\' );
end
output_path_exists = exist(output_path);
end