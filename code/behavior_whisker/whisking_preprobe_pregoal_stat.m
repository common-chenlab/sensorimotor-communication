function whisking_preprobe_pregoal_stat()
% Pre-probe vs pre-goal whisking amplitude comparison (Reviewer 2, major concern 2).
% Tests whether whisking amplitude differs between the 1-s windows immediately
% preceding the probe and goal stimuli. Reported in the response to reviewers
% (does not produce a manuscript figure).
%
% Input: matlab.mat (result struct with ampAP/ampPA/ampPP/ampAA = the four choice
% conditions Hit/Miss/CR/FA, whisking amplitude at 500 Hz, aligned to trial start),
% produced by the processing section of whisker_analysis_delay.m.

load([smroot() 'Analysis/whisker_analysis/matlab.mat'],'result'); % [release]
load([smroot() 'Analysis/summary.mat'],'control'); %#ok<NASGU>

% Windows (samples at 500 Hz). From the grand-mean whisking profile, probe onset
% is ~sample 2200 and goal onset ~sample 4400; pre-stimulus = the 1 s before each.
PRE_PROBE = 1700:2200;
PRE_GOAL  = 3900:4400;

PP = []; PG = [];
for i = 1:numel(result)
    try
        amp = [result(i).ampAP(1:5600); result(i).ampPA(1:5600); ...
               result(i).ampPP(1:5600); result(i).ampAA(1:5600)];   % 4 x 5600
        m = nanmean(amp,1);                     % mean across the 4 choice conditions
        PP(end+1,1) = nanmean(m(PRE_PROBE));     %#ok<AGROW>
        PG(end+1,1) = nanmean(m(PRE_GOAL));      %#ok<AGROW>
    catch
    end
end
ok = ~(isnan(PP) | isnan(PG)); PP = PP(ok); PG = PG(ok); n = numel(PP);

[~, p, ~, stats] = ttest(PG, PP);
fprintf('\nPre-probe vs pre-goal whisking amplitude (n = %d sessions)\n', n);
fprintf('  pre-probe = %.3f +/- %.3f (mean +/- SEM)\n', mean(PP), std(PP)/sqrt(n));
fprintf('  pre-goal  = %.3f +/- %.3f\n', mean(PG), std(PG)/sqrt(n));
fprintf('  difference (goal - probe) = %.3f\n', mean(PG - PP));
fprintf('  paired t-test: t(%d) = %.2f, p = %.4f\n', stats.df, stats.tstat, p);
fprintf('  Wilcoxon signed-rank: p = %.4f\n', signrank(PG, PP));
end
