function out = smout(name)
% SMOUT  Output folder under <repository>/results/, created on demand.
%
%   out = smout()        -> <repo>/results/
%   out = smout('ifi')   -> <repo>/results/ifi/
%
%   All figures, tables and result .mat files written by the repository code go
%   here, never into the data tree.

repo = fileparts(fileparts(fileparts(mfilename('fullpath'))));
if nargin < 1 || isempty(name)
    out = fullfile(repo, 'results');
else
    out = fullfile(repo, 'results', char(name));
end
if ~isfolder(out)
    mkdir(out);
end
out = [out filesep];
end
