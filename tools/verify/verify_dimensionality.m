% VERIFY_DIMENSIONALITY  Re-run DIMENSIONALITY_ANALYSIS (Supplementary Fig. 2) from the
% repository and compare the participation ratios with the lab's saved results.
repo = fileparts(fileparts(fileparts(mfilename('fullpath'))));
run(fullfile(repo, 'startup_sm.m'));
addpath(fullfile(repo, 'tools', 'verify'));

if ~isfile([smout('dimensionality') 'dimensionality_results.mat'])
    close all
    DIMENSIONALITY_ANALYSIS;
    close all
end

new = load([smout('dimensionality') 'dimensionality_results.mat']);
ref = load([smroot() 'Analysis/R1C3_dimensionality/dimensionality_results.mat']);
ok = true;
for f = {'PRp', 'PRg', 'N', 'p'}
    a = double(new.(f{1})); b = double(ref.(f{1}));
    same = isequal(size(a), size(b)) && all(abs(a(:) - b(:)) <= 1e-9 | (isnan(a(:)) & isnan(b(:))));
    fprintf('  %-4s %s  size %s  max diff %g\n', f{1}, string(same), mat2str(size(a)), max(abs(a(:) - b(:))));
    ok = ok && same;
end
fprintf('DIMENSIONALITY_ANALYSIS: %s\n', string(ok).replace(["true" "false"], ["PASS" "FAIL"]));
