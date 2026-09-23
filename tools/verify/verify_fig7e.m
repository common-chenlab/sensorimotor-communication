% VERIFY_FIG7E  Re-run the repository copy of FIG7E_STATS and compare its stats
% table with the table produced by the lab's original script.
repo = fileparts(fileparts(fileparts(mfilename('fullpath'))));
run(fullfile(repo, 'startup_sm.m'));
addpath(fullfile(repo, 'tools', 'verify'));

if ~isfile(fullfile(smout('fig7e_stats'), 'FIG7E_stats_table.csv'))
    close all
    FIG7E_STATS;
    close all
end

new = readtable(fullfile(smout('fig7e_stats'), 'FIG7E_stats_table.csv'));
ref = readtable([smroot() 'Analysis/CHECKLIST11_Fig7e_stats/FIG7E_stats_table.csv']);
verify_compare_tables('FIG7E_STATS', new, ref);
