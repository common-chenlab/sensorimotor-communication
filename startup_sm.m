function startup_sm()
% STARTUP_SM  Put the repository code on the MATLAB path and report the data location.
%
%   Run once per MATLAB session from the repository root:
%       >> startup_sm
%   Then run any script listed in FIGURE_MAP.md.

repo = fileparts(mfilename('fullpath'));
addpath(genpath(fullfile(repo, 'code')));

fprintf('Sensorimotor communication code: %s\n', repo);
try
    fprintf('Data root:    %s\n', smroot());
catch err
    warning(err.identifier, '%s', err.message);
end
fprintf('Outputs go to: %s\n', smout());

% Several plotting cells export to the current folder; keep those out of the code tree.
cd(smout());
end
