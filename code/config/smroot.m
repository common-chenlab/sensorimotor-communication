function root = smroot()
% SMROOT  Root of the data tree used by every script in this repository.
%
%   root = smroot() returns a folder (with trailing separator) holding the session files in
%   Animals/<animal>/, as published on GIN. The upstream pipeline writes the intermediates it
%   builds (Analysis/..., Scripts/CCA/IFI.mat) into the same folder.
%
%   Resolution order:
%     1. environment variable SM_DATA_ROOT
%     2. <repository>/data/, but only once it holds a complete data set, marked by the
%        file data/DATA_COMPLETE. While the folder is still being populated the marker
%        should be absent, so scripts keep reading a complete tree instead of failing on
%        files that have not been copied yet.
%     3. the Chen lab working copy (Dropbox on Windows, claustrum on Linux)
%
%   A candidate must contain an Animals/ or an Analysis/ subfolder. The lab working copy is
%   treated as read-only; see sm_assert_writable.

persistent cached
if ~isempty(cached)
    root = cached;
    return
end

repo = fileparts(fileparts(fileparts(mfilename('fullpath'))));
repo_data = fullfile(repo, 'data');
candidates = {getenv('SM_DATA_ROOT')};
if isfile(fullfile(repo_data, 'DATA_COMPLETE'))
    candidates{end+1} = repo_data;
end
candidates = [candidates, { ...
    'Z:\Dropbox\Chen Lab Dropbox\Chen Lab Team Folder\Projects\Sensorimotor', ...
    '/net/claustrum/mnt/data/Dropbox/Chen Lab Dropbox/Chen Lab Team Folder/Projects/Sensorimotor'}];

for k = 1:numel(candidates)
    c = candidates{k};
    if ~isempty(c) && (isfolder(fullfile(c, 'Animals')) || isfolder(fullfile(c, 'Analysis')))
        cached = [char(c) filesep];
        if (isfolder(fullfile(repo_data, 'Animals')) || isfolder(fullfile(repo_data, 'Analysis'))) ...
                && ~strcmpi(cached, [repo_data filesep])
            fprintf(['[smroot] Using %s\n         (%s holds a partial copy; add a ' ...
                'DATA_COMPLETE file there once it is complete.)\n'], cached, repo_data);
        end
        root = cached;
        return
    end
end
error('smroot:notFound', ['No data tree found. Put the data in %s and mark it with a ' ...
    'DATA_COMPLETE file, or set the SM_DATA_ROOT environment variable (see ' ...
    'data/README.md).'], repo_data);
end
