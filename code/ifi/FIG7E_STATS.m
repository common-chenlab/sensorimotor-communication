function FIG7E_STATS
% FIG7E_STATS  Test specification and exact statistics for Figure 7e.
%
%   Author Checklist item 11 (NCOMMS-26-057740-T): state the bootstrap test
%   used for Fig 7e and report the exact P values.
%
%   Fig 7e is the bar cell of
%     Manuscript\NatComm\original_submission\Figures\Figure7-IFI\DISPLAY_IFI.m
%   (the cell beginning at the "idx = {'S1S2',[190:200]; ...}" line, which
%   writes barS1S2.eps ... barM1AM1B.eps).
%
%   What the submitted figure actually does
%     Session-level IFI (slope of trial-by-trial correlation vs lag, CCA dim 1)
%     is averaged over an 11 frame window preceding the goal period, separately
%     for each area pair and each trial outcome. The two horizontal lines are
%     NOT a bootstrap: they come from get_corr_beta.m, which refits the slope
%     after randomly permuting the lag labels 1000 times and keeps the 5th and
%     95th percentiles. Those per-session percentiles are averaged over the
%     first 20 frames of the trial on all-trial data, then collapsed across the
%     six area pairs by taking max(low) and min(high). A bar was called
%     significant when its group mean fell outside that interval. No P value
%     was ever computed, and the procedure is a permutation test, not a
%     bootstrap.
%
%   What this script adds
%     (1) Reproduces the submitted figure's shuffle interval and verdicts.
%     (2) Runs a genuine bootstrap over sessions (BOOTN resamples of the
%         session-level means) and reports the 95% CI and an exact two-sided
%         P against zero. This is the reading that makes the word "bootstrap"
%         in the legend correct.
%     (3) Reports a one-sample two-sided t-test against zero as a parametric
%         cross-check, with exact t and df.
%     Both (2) and (3) are Bonferroni-Holm corrected across the four trial
%     outcomes within each area pair.
%
%   Outputs (written next to this file)
%     FIG7E_stats_table.csv     every bar, all three tests
%     FIG7E_stats_report.txt    legend-ready text
%     Fig7e_IFI_bars.eps/.png   the six panels with markers drawn

%% ------------------------------------------------------------------ CONFIG
IFIMAT  = [smroot() 'Scripts/CCA/IFI.mat'];
OUTDIR  = smout('fig7e_stats'); % [release] was the script's own folder

NFRAME  = 272;    % frames retained per session, as in DISPLAY_IFI.m
DIMCCA  = 1;      % first CCA dimension, as in DISPLAY_IFI.m
CONDALL = 9;      % index of the all-trials condition (used for the shuffle bound)
BASEWIN = 1:20;   % baseline frames the shuffle bound is averaged over
BOOTN   = 10000;
RNGSEED = 20260916;

% Pre-goal analysis window for each area pair (frames), from DISPLAY_IFI.m
pairName = {'S1:S2','S1:M1A','S1:M1B','S2:M1A','S2:M1B','M1A:M1B'};
pairWin  = {190:200, 197:207, 186:196, 186:196, 182:192, 190:200};

% Trial outcomes: rrr condition indices 5:8 in plotted order
condIdx   = 5:8;
condLabel = {'Hit','Miss','CR','FA'};   % 'a lick','a no lick','p no lick','p lick'

rng(RNGSEED);

%% ------------------------------------------------------- LOAD AND ASSEMBLE
fprintf('Loading %s\n', IFIMAT);
D = load(IFIMAT,'rrr','rrr3');

% observed IFI: frames x dim x pair x condition x session
[obs, keep] = stack(D.rrr,  NFRAME, 4);
% shuffle percentiles: frames x dim x pair x condition x session x [beta high low]
[shf, keep3] = stack(D.rrr3, NFRAME, 5);
assert(isequal(keep,keep3), 'Session sets differ between rrr and rrr3.');

nSess = size(obs,5);
fprintf('n = %d sessions contributed (of %d entries in IFI.mat)\n', nSess, numel(D.rrr));

%% ------------------------------------- SHUFFLE BOUND, AS IN THE SUBMISSION
valLow = nan(1,6); valHigh = nan(1,6);
for j = 1:6
    tLow  = nanmean(shf(1:NFRAME,DIMCCA,j,CONDALL,:,3),5);
    tHigh = nanmean(shf(1:NFRAME,DIMCCA,j,CONDALL,:,2),5);
    valLow(j)  = nanmean(tLow(BASEWIN));
    valHigh(j) = nanmean(tHigh(BASEWIN));
end
shufLow  = max(valLow);
shufHigh = min(valHigh);
fprintf('Shuffle interval used in the submitted figure: [%.5f, %.5f]\n', shufLow, shufHigh);

%% ------------------------------------------------------------------ STATS
rows = {};
for j = 1:6
    w = pairWin{j};
    v = nan(nSess,4);
    for c = 1:4
        v(:,c) = squeeze(nanmean(obs(w, DIMCCA, j, condIdx(c), :), 1));
    end

    pBootRaw = nan(1,4); ciLo = nan(1,4); ciHi = nan(1,4);
    pTRaw = nan(1,4); tStat = nan(1,4); dfv = nan(1,4);
    for c = 1:4
        x = v(~isnan(v(:,c)), c);
        n = numel(x);
        bs = mean(x(randi(n, n, BOOTN)), 1);
        pBootRaw(c) = max(2*min(mean(bs <= 0), mean(bs >= 0)), 1/BOOTN);
        ciLo(c) = prctile(bs, 2.5);
        ciHi(c) = prctile(bs, 97.5);
        [~,p,~,st] = ttest(x);
        pTRaw(c) = p; tStat(c) = st.tstat; dfv(c) = st.df;
    end
    pBoot = holm(pBootRaw);
    pT    = holm(pTRaw);

    mu = nanmean(v,1);
    se = nanstd(v,[],1) ./ sqrt(sum(~isnan(v),1));
    outside = mu < shufLow | mu > shufHigh;   % the submitted figure's criterion

    for c = 1:4
        rows(end+1,:) = { pairName{j}, condLabel{c}, sprintf('%d-%d', w(1), w(end)), ...
            sum(~isnan(v(:,c))), mu(c), se(c), ciLo(c), ciHi(c), ...
            pBootRaw(c), pBoot(c), tStat(c), dfv(c), pTRaw(c), pT(c), ...
            shufLow, shufHigh, outside(c) }; %#ok<AGROW>
    end

    R(j).mu = mu; R(j).se = se; R(j).pBoot = pBoot; R(j).pT = pT; %#ok<AGROW>
    R(j).outside = outside; R(j).t = tStat; R(j).df = dfv;        %#ok<AGROW>
end

T = cell2table(rows, 'VariableNames', ...
    {'area_pair','outcome','window_frames','n', ...
     'mean_IFI','sem','boot_CI95_low','boot_CI95_high', ...
     'P_boot_raw','P_boot_holm','t','df','P_ttest_raw','P_ttest_holm', ...
     'shuffle_low','shuffle_high','outside_shuffle_interval'});
writetable(T, fullfile(OUTDIR,'FIG7E_stats_table.csv'));
fprintf('Wrote %s\n', fullfile(OUTDIR,'FIG7E_stats_table.csv'));

%% ----------------------------------------------------------------- FIGURE
f = figure('Color','w','Position',[80 80 1150 620]);
for j = 1:6
    subplot(2,3,j); hold on
    x = 1:4;
    bar(x, R(j).mu, 0.65, 'FaceColor',[0.75 0.75 0.75], 'EdgeColor','k');
    errorbar(x, R(j).mu, R(j).se, 'k', 'LineStyle','none', 'LineWidth',1, 'CapSize',6);
    yline(shufHigh, 'k:', 'LineWidth',1);
    yline(shufLow,  'k:', 'LineWidth',1);
    yline(0, 'k-', 'LineWidth',0.5);

    for c = 1:4
        lab = starstr(R(j).pBoot(c));
        if isempty(lab), continue; end
        yoff = 1.35*R(j).se(c);
        if R(j).mu(c) >= 0
            ty = R(j).mu(c) + yoff; va = 'bottom';
        else
            ty = R(j).mu(c) - yoff; va = 'top';
        end
        text(x(c), ty, lab, 'HorizontalAlignment','center', ...
             'VerticalAlignment',va, 'FontSize',10);
    end

    ylim([-0.25 0.25]); xlim([0.4 4.6]);
    set(gca,'XTick',x,'XTickLabel',condLabel,'TickDir','out','Box','off','FontSize',8);
    ylabel('IFI (\Deltacorr / \Deltalag)','FontSize',8);
    title(pairName{j},'FontSize',9,'FontWeight','normal');
end
sgtitle(sprintf('Figure 7e  -  IFI preceding the goal period  (n = %d sessions)', nSess), ...
        'FontSize',11);
stem = fullfile(OUTDIR,'Fig7e_IFI_bars');
print(f, stem, '-depsc', '-painters');
print(f, stem, '-dpng', '-r300');
fprintf('Wrote %s.eps / .png\n', stem);

%% ----------------------------------------------------------------- REPORT
fid = fopen(fullfile(OUTDIR,'FIG7E_stats_report.txt'),'w');
fprintf(fid,'Figure 7e exact statistics (Author Checklist item 11)\n');
fprintf(fid,'NCOMMS-26-057740-T\n\n');
fprintf(fid,'Test specification\n');
fprintf(fid,'  Session-level IFI (CCA dimension 1) averaged over the 11 frame window\n');
fprintf(fid,'  preceding the goal period, one window per area pair. The group mean was\n');
fprintf(fid,'  tested against zero by bootstrap over sessions: %d resamples with\n', BOOTN);
fprintf(fid,'  replacement, two-sided P = 2 x min(fraction of resampled means <= 0,\n');
fprintf(fid,'  fraction >= 0), floored at 1/%d, Bonferroni-Holm corrected across the\n', BOOTN);
fprintf(fid,'  four trial outcomes within each area pair. n = %d sessions.\n\n', nSess);
fprintf(fid,'  Dotted lines mark the lag-permutation chance level (1000 permutations of\n');
fprintf(fid,'  the lag labels per session, 5th and 95th percentiles, averaged over the\n');
fprintf(fid,'  first 20 frames and collapsed across area pairs): [%.4f, %.4f].\n\n', shufLow, shufHigh);
for j = 1:6
    fprintf(fid,'--- %s (frames %d-%d) ---\n', pairName{j}, pairWin{j}(1), pairWin{j}(end));
    for c = 1:4
        star = starstr(R(j).pBoot(c));
        if ~isempty(star), star = [' ' star]; end %#ok<AGROW>
        fprintf(fid,'  %-5s IFI = %+7.4f +/- %.4f   bootstrap P = %s%s   [t(%d) = %+6.3f, P = %s]\n', ...
            condLabel{c}, R(j).mu(c), R(j).se(c), pstr(R(j).pBoot(c)), star, ...
            R(j).df(c), R(j).t(c), pstr(R(j).pT(c)));
    end
end
fclose(fid);
fprintf('Wrote %s\n', fullfile(OUTDIR,'FIG7E_stats_report.txt'));
type(fullfile(OUTDIR,'FIG7E_stats_report.txt'));

end % FIG7E_STATS

%% ================================================================ helpers

function [out, keep] = stack(S, nframe, ndim)
% Concatenate the per-session arrays along a new trailing session dimension,
% skipping empty entries, exactly as the try/catch in DISPLAY_IFI.m does.
out = []; keep = []; c = 0;
for i = 1:numel(S)
    a = S(i).rrr;
    if isempty(a) || size(a,1) < nframe, continue; end
    c = c + 1; keep(end+1) = i; %#ok<AGROW>
    if ndim == 4
        out(:,:,:,:,c) = a(1:nframe,:,:,:); %#ok<AGROW>
    else
        out(:,:,:,:,c,:) = a(1:nframe,:,:,:,:); %#ok<AGROW>
    end
end
if ndim == 5
    out = permute(out, [1 2 3 4 5 6]);
end
end

function p = holm(praw)
[s,o] = sort(praw(:));
m = numel(s);
adj = cummax(s .* (m:-1:1)');
p = nan(size(praw));
p(o) = min(adj,1);
end

function lab = starstr(p)
if     p < 0.001, lab = '***';
elseif p < 0.01,  lab = '**';
elseif p < 0.05,  lab = '*';
else,             lab = '';
end
end

function s = pstr(p)
if p < 1e-4, s = sprintf('%.1e', p); else, s = sprintf('%.4f', p); end
end
