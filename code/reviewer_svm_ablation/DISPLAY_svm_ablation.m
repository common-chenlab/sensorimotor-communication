function DISPLAY_svm_ablation()
% DISPLAY_svm_ablation  Figure + stats for the SVM ablation (Reviewer 1, comment 1).
% Loads SVM_ablation_results.mat and tests whether silencing M1->S1/S2 projection
% (mCherry+) neurons reduces LOCAL task-decoding accuracy more than silencing a
% matched number of random unlabeled neurons, separately for the probe and goal
% periods. Compare against Fig. 6f,g (communication subspace).
% Exports vectorized EPS via -painters.

outdir = smout('reviewer_svm_ablation'); % [release] outputs -> results/reviewer_svm_ablation
if ~isfile([outdir 'SVM_ablation_results.mat']), outdir = [smroot() 'Analysis/R1C1_svm_ablation/']; end % [release] fall back to shipped results
load([outdir 'SVM_ablation_results.mat'], 'acc');

% acc(session, area[M1A,M1B], variable[stim,choice], window[probe,goal], version[base,mch,ctrl])
base = acc(:,:,:,:,1);
mch  = acc(:,:,:,:,2);   % projection silenced
ctrl = acc(:,:,:,:,3);   % matched unlabeled silenced

dropP = base - mch;      % contribution of projection neurons
dropC = base - ctrl;     % contribution of matched unlabeled neurons

% pool across the two motor areas and the two task variables -> per session, per window
dropP_w = squeeze(nanmean(nanmean(dropP,2),3)) * 100;   % (nS x 2 window), percentage points
dropC_w = squeeze(nanmean(nanmean(dropC,2),3)) * 100;
base_w  = squeeze(nanmean(nanmean(base ,2),3)) * 100;

valid = ~isnan(dropP_w(:,1)) & ~isnan(dropC_w(:,1));
dropP_w = dropP_w(valid,:); dropC_w = dropC_w(valid,:); base_w = base_w(valid,:);
nS = size(dropP_w,1);

wname = {'Probe','Goal'};
fprintf('\nSVM ablation of local task decoding (n = %d sessions, M1A+M1B, stimulus+choice pooled)\n', nS);
P = zeros(1,2); Pw = zeros(1,2);
for w = 1:2
    [~,p,~,st] = ttest(dropP_w(:,w), dropC_w(:,w));
    pw = signrank(dropP_w(:,w), dropC_w(:,w));
    P(w)=p; Pw(w)=pw;
    fprintf('  %-6s baseline acc=%.1f%%  | projection drop=%.2f%%  matched-unlabeled drop=%.2f%%  | dP-dC=%.2f%%  t(%d)=%.2f p=%.4f (signrank p=%.4f)\n', ...
        wname{w}, mean(base_w(:,w)), mean(dropP_w(:,w)), mean(dropC_w(:,w)), ...
        mean(dropP_w(:,w)-dropC_w(:,w)), st.df, st.tstat, p, pw);
end

% ---------- figure ----------
means = [mean(dropP_w(:,1)) mean(dropC_w(:,1)) mean(dropP_w(:,2)) mean(dropC_w(:,2))];
sems  = [std(dropP_w(:,1)) std(dropC_w(:,1)) std(dropP_w(:,2)) std(dropC_w(:,2))]/sqrt(nS);
xpos  = [1 2 3.6 4.6];
colP = [0.80 0.20 0.20];   % projection
colC = [0.55 0.55 0.55];   % matched unlabeled
cols = [colP; colC; colP; colC];

figure('Color','w','Position',[100 100 460 420]); hold on
for k = 1:4
    bar(xpos(k), means(k), 0.8, 'FaceColor', cols(k,:), 'EdgeColor','none', 'FaceAlpha',0.85);
end
% individual sessions with paired connecting lines
jit = 0.10;
dat = {dropP_w(:,1) dropC_w(:,1) dropP_w(:,2) dropC_w(:,2)};
for grp = [1 3]   % probe pair (1,2), goal pair (3,4)
    x1 = xpos(grp)   + (rand(nS,1)-0.5)*jit;
    x2 = xpos(grp+1) + (rand(nS,1)-0.5)*jit;
    for s = 1:nS
        plot([x1(s) x2(s)], [dat{grp}(s) dat{grp+1}(s)], '-', 'Color',[0.7 0.7 0.7 0.35]);
    end
    scatter(x1, dat{grp},   14, 'MarkerFaceColor',colP,'MarkerEdgeColor','none','MarkerFaceAlpha',0.55);
    scatter(x2, dat{grp+1}, 14, 'MarkerFaceColor',colC,'MarkerEdgeColor','none','MarkerFaceAlpha',0.55);
end
errorbar(xpos, means, sems, 'k','LineStyle','none','LineWidth',1.1,'CapSize',8);
yline(0,'k:');
% significance annotations
yl = ylim; ytop = yl(2);
for i = 1:2
    gx = xpos(2*i-1:2*i);
    lab = sprintf('n.s. (p=%.2f)', P(i)); if P(i)<0.05, lab=sprintf('p=%.3f',P(i)); end
    plot([gx(1) gx(2)], [ytop ytop]*0.96, 'k-');
    text(mean(gx), ytop*0.99, lab, 'HorizontalAlignment','center','FontSize',9);
end
set(gca,'XTick',[1.5 4.1],'XTickLabel',wname,'FontSize',11,'TickDir','out','Box','off');
ylabel('Decrease in decoding accuracy (%)');
title(sprintf('M1 local task decoding (n=%d sessions)', nS));
% legend proxies
hP = bar(nan,nan,'FaceColor',colP,'EdgeColor','none');
hC = bar(nan,nan,'FaceColor',colC,'EdgeColor','none');
legend([hP hC], {'Projection (M1_{S1/S2}) silenced','Matched unlabeled silenced'}, ...
    'Location','northoutside','Box','off');

print(gcf, [smout('reviewer_svm_ablation') 'FigR1C1_svm_ablation'], '-depsc', '-painters');
print(gcf, [smout('reviewer_svm_ablation') 'FigR1C1_svm_ablation'], '-dpng', '-r200');
fprintf('\nSaved FigR1C1_svm_ablation.eps / .png\n');
end
