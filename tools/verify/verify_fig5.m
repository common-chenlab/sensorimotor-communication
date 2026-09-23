% VERIFY_FIG5  Re-run the repository copy of FIG5_STATS from scratch (no cached
% alignment file) and compare its stats table with the lab's original output.
repo = fileparts(fileparts(fileparts(mfilename('fullpath'))));
run(fullfile(repo, 'startup_sm.m'));
addpath(fullfile(repo, 'tools', 'verify'));

if ~isfile(fullfile(smout('fig5_stats'), 'FIG5_stats_table.csv'))
    close all
    FIG5_STATS;
    close all
end

new = readtable(fullfile(smout('fig5_stats'), 'FIG5_stats_table.csv'));
ref = readtable([smroot() 'Analysis/CHECKLIST10_Fig5_stats/FIG5_stats_table.csv']);
verify_compare_tables('FIG5_STATS', new, ref, 1e-9);
