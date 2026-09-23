function FIG5_STATS(varargin)
% FIG5_STATS  Exact statistics and annotated panels for Figure 5b,c.
%
%   Author Checklist item 10 (NCOMMS-26-057740-T): report exact P, t and df
%   for Fig 5b,c and draw the significance markers on the plot.
%
%   Reimplements the binned alignment analysis of SVM_CCA_alignment_UI.m
%   ("FIGURE BINNED" + "STATS" cells) so that the t statistic and degrees of
%   freedom are captured alongside the P value, then regenerates the panels
%   with brackets and asterisks and writes a stats table.
%
%   Panels
%     Fig 5b  choice            <- pcabinnedweights   (decoder 4 probe / 6 goal)
%     Fig 5c  stimulus n choice <- pcabinnedweightsui (decoder 1 probe / 3 goal)
%   Supplementary Fig 4 companions (stimulus, union) are computed as well.
%
%   Usage
%     FIG5_STATS               % use cached alignment if present, else compute
%     FIG5_STATS('recompute')  % force recomputation of the alignment stage
%
%   Outputs (written next to this file)
%     FIG5_alignment.mat        cached alignment + shuffle arrays
%     FIG5_stats_table.csv      every comparison, exact t / df / P
%     FIG5_stats_report.txt     legend-ready text
%     Fig5b_choice.eps/.png
%     Fig5c_intersection.eps/.png
%     SuppFig4_stimulus.eps/.png
%     SuppFig4_union.eps/.png

%% ------------------------------------------------------------------ CONFIG
ROOT    = [smroot() 'Analysis'];
PROJDIR = fullfile(ROOT,'proj','full-resid_stim');
OUTDIR  = smout('fig5_stats'); % [release] was the script's own folder
CACHE   = fullfile(OUTDIR,'FIG5_alignment.mat');

NPERM    = 100;   % shuffles per weight-vector pair (as in the original script)
CCACOMP  = 1;     % CCA component used in the figure (n = 1 in the original)
RNGSEED  = 20260916;

% Significance thresholds. These reproduce the marker scheme already stated in
% the Fig 5 legend. Exact P values are reported in the table regardless, so
% these can be switched to a conventional 0.05/0.01/0.001 scheme if the editor
% prefers (Author Checklist item 13).
STAR_THRESH = [0.05 0.02 0.0005];
STAR_LABEL  = {'*','**','***'};

% How to show the phase-shuffled chance level.
%   'line'   : dotted horizontal tick over each bar, error bars are symmetric SEM
%   'errlow' : lower whisker = shuffle mean (reproduces the original script)
% The submitted legend states "Error bars: SEM", which only matches 'line'.
SHUFFLE_STYLE = 'line';

recompute = any(strcmpi(varargin,'recompute'));

%% --------------------------------------------------- AREA-PAIR INDEX TABLE
% columns: [CCA pair, CCA side, area index into the SVM weight array]
idx = [1,1,1;   % S1 of S1:S2
       1,2,2;   % S2 of S1:S2
       2,1,1;   % S1 of S1:M1A
       2,2,3;   % M1A of S1:M1A
       3,1,1;   % S1 of S1:M1B
       3,2,4;   % M1B of S1:M1B
       6,1,3;   % M1A of M1A:M1B
       6,2,4;   % M1B of M1A:M1B
       4,1,2;   % S2 of S2:M1A
       4,2,3;   % M1A of S2:M1A
       5,1,2;   % S2 of S2:M1B
       5,2,4];  % M1B of S2:M1B

pairName  = {'S1','S2'; 'S1','M1A'; 'S1','M1B'; 'M1A','M1B'; 'S2','M1A'; 'S2','M1B'};
pairTitle = {'S1:S2','S1:M1A','S1:M1B','M1A:M1B','S2:M1A','S2:M1B'};

%% ------------------------------------------------------- STAGE 1 alignment
if recompute || ~exist(CACHE,'file')
    fprintf('Computing alignment (this takes a few minutes)...\n');
    rng(RNGSEED);

    S = load(fullfile(ROOT,'summary.mat'),'control');
    B = load(fullfile(ROOT,'svm','PCA_BINNED.mat'), ...
             'pcabinnedweights','pcabinnedweightsui');
    control = S.control;

    [alignSC, shufSC, sessSC] = collect(control, B.pcabinnedweights,   idx, PROJDIR, NPERM);
    [alignUI, shufUI, sessUI] = collect(control, B.pcabinnedweightsui, idx, PROJDIR, NPERM);

    assert(isequal(sessSC,sessUI), 'Session sets differ between the two weight arrays.');
    sessions = sessSC;

    save(CACHE,'alignSC','shufSC','alignUI','shufUI','sessions', ...
               'idx','NPERM','CCACOMP','RNGSEED','-v7.3');
else
    fprintf('Loading cached alignment from %s\n', CACHE);
    load(CACHE,'alignSC','shufSC','alignUI','shufUI','sessions');
end

nSess = numel(sessions);
fprintf('n = %d sessions\n', nSess);

%% ------------------------------------------------------------ STAGE 2 stats
% {label, source array, probe decoder, goal decoder, output stem, panel name}
measures = {
    'choice',            'SC', 4, 6, 'Fig5b_choice',        'Figure 5b'
    'stimulus x choice', 'UI', 1, 3, 'Fig5c_intersection',  'Figure 5c'
    'stimulus',          'SC', 3, 5, 'SuppFig4_stimulus',   'Supplementary Figure 4 (stimulus)'
    'union',             'UI', 2, 4, 'SuppFig4_union',      'Supplementary Figure 4 (union)'
    };

compLabel = {'probe A vs probe B','goal A vs goal B','probe A vs goal A','probe B vs goal B'};
barLabel  = {'probe A','probe B','goal A','goal B'};

rows = {};
for mi = 1:size(measures,1)
    meas = measures{mi,1};
    switch measures{mi,2}
        case 'SC', A = alignSC; Z = shufSC;
        case 'UI', A = alignUI; Z = shufUI;
    end
    kProbe = measures{mi,3};
    kGoal  = measures{mi,4};

    for j = 1:6
        c1 = 2*j-1;  c2 = 2*j;      % the two areas of this pair
        v = cell(1,4); s = cell(1,4);
        v{1} = squeeze(A(1,CCACOMP,kProbe,c1,:));  s{1} = squeeze(Z(1,CCACOMP,kProbe,c1,:));
        v{2} = squeeze(A(1,CCACOMP,kProbe,c2,:));  s{2} = squeeze(Z(1,CCACOMP,kProbe,c2,:));
        v{3} = squeeze(A(2,CCACOMP,kGoal, c1,:));  s{3} = squeeze(Z(2,CCACOMP,kGoal, c1,:));
        v{4} = squeeze(A(2,CCACOMP,kGoal, c2,:));  s{4} = squeeze(Z(2,CCACOMP,kGoal, c2,:));

        % --- four within-pair paired comparisons, Holm corrected as one family
        cmp  = [1 2; 3 4; 1 3; 2 4];
        pRaw = nan(1,4); tStat = nan(1,4); dfv = nan(1,4);
        for c = 1:4
            [~,p,~,st] = ttest(v{cmp(c,1)}, v{cmp(c,2)});
            pRaw(c) = p; tStat(c) = st.tstat; dfv(c) = st.df;
        end
        pHolm = holm(pRaw);

        % --- families the original SVM_CCA_alignment_UI.m used, for reference
        pOrig = nan(1,4);
        a = holm(pRaw([1 2 3])); pOrig(1) = a(1);
        a = holm(pRaw([2 3 4])); pOrig(2) = a(1);
        a = holm(pRaw([3 1 2])); pOrig(3) = a(1);
        a = holm(pRaw([4 1 2])); pOrig(4) = a(1);

        for c = 1:4
            lab = strrep(strrep(compLabel{c},' A',[' ' pairName{j,1}]),' B',[' ' pairName{j,2}]);
            rows(end+1,:) = { measures{mi,6}, meas, pairTitle{j}, lab, ...
                mean(v{cmp(c,1)}), sem(v{cmp(c,1)}), mean(v{cmp(c,2)}), sem(v{cmp(c,2)}), ...
                tStat(c), dfv(c), pRaw(c), pHolm(c), pOrig(c) }; %#ok<AGROW>
        end

        % --- each bar against its own shuffle (not currently in the legend)
        for b = 1:4
            [~,p,~,st] = ttest(v{b}, s{b});
            lab = [strrep(strrep(barLabel{b},' A',[' ' pairName{j,1}]),' B',[' ' pairName{j,2}]) ' vs shuffle'];
            rows(end+1,:) = { measures{mi,6}, meas, pairTitle{j}, lab, ...
                mean(v{b}), sem(v{b}), mean(s{b}), sem(s{b}), ...
                st.tstat, st.df, p, NaN, NaN }; %#ok<AGROW>
        end

        STATS(mi,j).pRaw  = pRaw;  %#ok<AGROW>
        STATS(mi,j).pHolm = pHolm; %#ok<AGROW>
        STATS(mi,j).t     = tStat; %#ok<AGROW>
        STATS(mi,j).df    = dfv;   %#ok<AGROW>
        STATS(mi,j).mu    = cellfun(@mean,v);
        STATS(mi,j).se    = cellfun(@sem, v);
        STATS(mi,j).shuf  = cellfun(@mean,s);
    end
end

T = cell2table(rows, 'VariableNames', ...
    {'panel','measure','area_pair','comparison','mean1','sem1','mean2','sem2', ...
     't','df','P_raw','P_holm_family4','P_holm_original_script'});
writetable(T, fullfile(OUTDIR,'FIG5_stats_table.csv'));
fprintf('Wrote %s\n', fullfile(OUTDIR,'FIG5_stats_table.csv'));

%% ---------------------------------------------------------- STAGE 3 figures
for mi = 1:size(measures,1)
    f = figure('Color','w','Position',[80 80 1100 620]);
    for j = 1:6
        subplot(2,3,j); hold on
        st = STATS(mi,j);
        x = 1:4;
        bar(x, st.mu, 0.65, 'FaceColor',[0.75 0.75 0.75], 'EdgeColor','k');
        switch SHUFFLE_STYLE
            case 'line'
                errorbar(x, st.mu, st.se, 'k', 'LineStyle','none', 'LineWidth',1, 'CapSize',6);
                for b = 1:4
                    plot(x(b)+[-0.33 0.33], [st.shuf(b) st.shuf(b)], 'k:', 'LineWidth',1);
                end
            case 'errlow'
                errorbar(x, st.mu, st.shuf, st.se, 'k', 'LineStyle','none', 'LineWidth',1);
        end

        ytop = max(st.mu + st.se);
        step = 0.085*max(ytop, eps);
        lvl  = ytop + step;
        cmp  = [1 2; 3 4; 1 3; 2 4];
        for c = 1:4
            lab = starstr(st.pHolm(c), STAR_THRESH, STAR_LABEL);
            if isempty(lab), continue; end
            bracket(cmp(c,1), cmp(c,2), lvl, step*0.28, lab);
            lvl = lvl + step;
        end

        ylim([0 max(lvl+step, 0.3)]);
        xlim([0.4 4.6]);
        set(gca,'XTick',x,'XTickLabel', ...
            {['probe ' pairName{j,1}],['probe ' pairName{j,2}], ...
             ['goal ' pairName{j,1}], ['goal ' pairName{j,2}]}, ...
            'TickDir','out','Box','off','FontSize',8);
        xtickangle(30);
        ylabel('alignment (R^2)','FontSize',8);
        title(pairTitle{j},'FontSize',9,'FontWeight','normal');
    end
    sgtitle(sprintf('%s  -  %s  (n = %d sessions)', ...
        measures{mi,6}, measures{mi,1}, nSess), 'FontSize',11);

    stem = fullfile(OUTDIR, measures{mi,5});
    print(f, stem, '-depsc', '-painters');
    print(f, stem, '-dpng', '-r300');
    fprintf('Wrote %s.eps / .png\n', stem);
end

%% ----------------------------------------------------------- STAGE 4 report
fid = fopen(fullfile(OUTDIR,'FIG5_stats_report.txt'),'w');
fprintf(fid,'Figure 5b,c exact statistics (Author Checklist item 10)\n');
fprintf(fid,'NCOMMS-26-057740-T\n');
fprintf(fid,'Two-sided paired Student t-test, Bonferroni-Holm corrected across\n');
fprintf(fid,'the four within-pair comparisons. n = %d sessions from 6 animals.\n\n', nSess);
for mi = 1:2
    fprintf(fid,'--- %s (%s) ---\n', measures{mi,6}, measures{mi,1});
    for j = 1:6
        st = STATS(mi,j);
        for c = 1:4
            lab  = strrep(strrep(compLabel{c},' A',[' ' pairName{j,1}]),' B',[' ' pairName{j,2}]);
            star = starstr(st.pHolm(c), STAR_THRESH, STAR_LABEL);
            if ~isempty(star), star = [' ' star]; end %#ok<AGROW>
            fprintf(fid,'  %-9s %-30s t(%d) = %7.3f, P = %s%s\n', ...
                pairTitle{j}, lab, st.df(c), st.t(c), pstr(st.pHolm(c)), star);
        end
    end
    fprintf(fid,'\n');
end
fclose(fid);
fprintf('Wrote %s\n', fullfile(OUTDIR,'FIG5_stats_report.txt'));
type(fullfile(OUTDIR,'FIG5_stats_report.txt'));

end % FIG5_STATS

%% ================================================================ helpers

function [align, shufm, sessions] = collect(control, W, idx, projdir, nperm)
% Correlate every CCA weight vector with every binned SVM weight vector.
% align(bin, cca_comp, decoder, pair_row, session) = r^2
nBin = 2; nComp = 3; nPair = size(idx,1);
align = []; shufm = []; sessions = {}; c = 0;
for p = 1:size(control,1)
    temp = W{p};
    if size(temp,2) ~= nBin, continue; end
    f = fullfile(projdir, sprintf('%s-%d-CCA_proj_full-resid_stim.mat', ...
                                  control{p,1}, control{p,2}));
    if ~exist(f,'file'), continue; end
    D = load(f,'CCA_coeff');
    c = c + 1;
    sessions{c} = sprintf('%s-%d', control{p,1}, control{p,2}); %#ok<AGROW>
    nDec = size(temp,4);
    if isempty(align)
        align = nan(nBin, nComp, nDec, nPair, 0);
        shufm = nan(nBin, nComp, nDec, nPair, 0);
    end
    for m = 1:nPair
        C = D.CCA_coeff{idx(m,1), idx(m,2)};
        for jj = 1:nComp
            cw = C(:,jj);
            for i = 1:nBin
                for k = 1:nDec
                    sw = temp(:,i,idx(m,3),k);
                    r = corrcoef(cw, sw);
                    align(i,jj,k,m,c) = r(1,2)^2;
                    shufm(i,jj,k,m,c) = mean(permR2(cw, sw, nperm));
                end
            end
        end
    end
    fprintf('  session %d (%s)\n', c, sessions{c});
end
end

function r2 = permR2(a, b, nperm)
% r^2 between independently permuted copies of a and b, vectorised.
n = numel(a);
[~,ia] = sort(rand(n,nperm),1);
[~,ib] = sort(rand(n,nperm),1);
A = a(ia); B = b(ib);
A = A - mean(A,1); B = B - mean(B,1);
r2 = (sum(A.*B,1).^2) ./ (sum(A.^2,1) .* sum(B.^2,1));
end

function p = holm(praw)
% Holm-Bonferroni step-down correction (matches bonf_holm).
[s,o] = sort(praw(:));
m = numel(s);
adj = s .* (m:-1:1)';
adj = cummax(adj);
p = nan(size(praw));
p(o) = min(adj,1);
end

function s = sem(x)
s = nanstd(x(:)) ./ sqrt(sum(~isnan(x(:))));
end

function lab = starstr(p, thr, labels)
lab = '';
for i = numel(thr):-1:1
    if p < thr(i), lab = labels{i}; return; end
end
end

function s = pstr(p)
if p < 1e-4, s = sprintf('%.1e', p); else, s = sprintf('%.4f', p); end
end

function bracket(x1, x2, y, tick, label)
plot([x1 x1 x2 x2], [y-tick y y y-tick], 'k-', 'LineWidth', 0.75);
text(mean([x1 x2]), y, label, 'HorizontalAlignment','center', ...
     'VerticalAlignment','bottom', 'FontSize', 9);
end
