function DIMENSIONALITY_ANALYSIS()
% DIMENSIONALITY_ANALYSIS  Effective dimensionality (participation ratio) of
% population activity in the probe vs goal period, per area and session.
% Addresses Reviewer #1, comment 3 (what drives goal-period subspace alignment).
% Runs the analysis, makes the figure, and saves a vectorized EPS (-painters).
%
% PR = (sum lambda)^2 / sum(lambda^2), lambda = eigenvalues of the trial
% covariance of single-trial, period-averaged population vectors (all PCs).

PRE = [smroot() 'Analysis/preprocessing/'];
OUT = smout('dimensionality'); % [release] outputs -> results/
load([smroot() 'Analysis/summary.mat'],'control');
PROBE = [-3.2 -2.0];   % probe stimulus window (s); goal onset = 0
GOAL  = [ 0.0  1.2];   % goal stimulus window (s)
AREAS = {'S1','S2','M1A','M1B'};

nSess = size(control,1);
PRp = nan(nSess,4); PRg = nan(nSess,4); used = false(nSess,1);
for n = 1:nSess
    f = [PRE control{n,1} '-' num2str(control{n,2}) '_preprocess_pca.mat'];
    if ~isfile(f), continue; end
    try
        S = load(f);
        if isfield(S,'t_proj'), t = S.t_proj(:); else, t = S.T_align{1}(:)/30; end  % older files lack t_proj
        pj = t>=PROBE(1) & t<=PROBE(2);
        gj = t>=GOAL(1)  & t<=GOAL(2);
        for a = 1:4
            X  = S.act_align{a};                              % (frame, PC, trial)
            Mp = squeeze(mean(X(pj,:,:),1,'omitnan'))';       % (trial, PC)
            Mg = squeeze(mean(X(gj,:,:),1,'omitnan'))';
            Mp = Mp(~any(isnan(Mp),2),:); Mg = Mg(~any(isnan(Mg),2),:);
            PRp(n,a) = part_ratio(Mp); PRg(n,a) = part_ratio(Mg);
        end
        used(n) = true; fprintf('done %s-%d\n', control{n,1}, control{n,2});
    catch ME
        fprintf('FAIL %s-%d: %s\n', control{n,1}, control{n,2}, ME.message);
    end
end
PRp = PRp(used,:); PRg = PRg(used,:); N = sum(used);

fprintf('\nN = %d sessions\n', N);
fprintf('%-5s %9s %8s %7s %6s %10s\n','area','PR_probe','PR_goal','diff','%chg','p');
p = zeros(1,4);
for a = 1:4
    [~,p(a)] = ttest(PRg(:,a), PRp(:,a));
    fprintf('%-5s %9.2f %8.2f %7.2f %6.1f %10.1e\n', AREAS{a}, mean(PRp(:,a)), mean(PRg(:,a)), ...
        mean(PRg(:,a)-PRp(:,a)), 100*mean(PRg(:,a)-PRp(:,a))/mean(PRp(:,a)), p(a));
end
save([OUT 'dimensionality_results.mat'], 'PRp','PRg','N','AREAS','p');

% ---- figure ----
figure('Position',[100 100 470 350],'Color','w'); hold on;
cP = [0.60 0.63 0.65]; cG = [0.13 0.40 0.67];
for a = 1:4
    xp = a-0.16; xg = a+0.16;
    ep = std(PRp(:,a))/sqrt(N); eg = std(PRg(:,a))/sqrt(N);
    plot([xp xg],[mean(PRp(:,a)) mean(PRg(:,a))],'-','Color',[.6 .6 .6],'LineWidth',1);
    errorbar(xp, mean(PRp(:,a)), ep, 'o','MarkerSize',7,'Color',cP,'MarkerFaceColor',cP,'CapSize',4,'LineWidth',1.3);
    errorbar(xg, mean(PRg(:,a)), eg, 'o','MarkerSize',7,'Color',cG,'MarkerFaceColor',cG,'CapSize',4,'LineWidth',1.3);
    text(a, max(mean(PRp(:,a)),mean(PRg(:,a)))+3, pstar(p(a)), 'HorizontalAlignment','center','FontSize',11);
end
set(gca,'XTick',1:4,'XTickLabel',AREAS,'FontSize',10); box off;
ylabel({'participation ratio','(effective dimensionality)'},'FontSize',10);
ylim([0 62]); xlim([0.4 4.6]);
title(sprintf('Population dimensionality decreases during goal period (n=%d)', N),'FontSize',10);
% legend proxies
hP = plot(nan,nan,'o','Color',cP,'MarkerFaceColor',cP,'MarkerSize',7);
hG = plot(nan,nan,'o','Color',cG,'MarkerFaceColor',cG,'MarkerSize',7);
legend([hP hG],{'probe','goal'},'Location','southeast','Box','off','FontSize',9);

set(gcf,'Renderer','painters');
print(gcf, [OUT 'FigS_dimensionality'], '-depsc','-painters');  % vectorized EPS
print(gcf, [OUT 'FigS_dimensionality'], '-dpng','-r200');
fprintf('\nSaved EPS + PNG + results to %s\n', OUT);
end

function pr = part_ratio(M)
M = M - mean(M,1);
w = eig(cov(M)); w = w(w>1e-12);
pr = (sum(w)^2)/sum(w.^2);
end

function s = pstar(p)
if     p<1e-3, s='***';
elseif p<1e-2, s='**';
elseif p<0.05, s='*';
else,          s='n.s.';
end
end
