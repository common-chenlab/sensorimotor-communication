function DISPLAY_subspace_reference()
% DISPLAY_subspace_reference  Draw the reviewer-response supplementary panel:
% Fig. 4C communication-subspace angles anchored between the same-channel
% reliability floor (green band) and the trial-shuffle chance ceiling (grey band).
% Run CCA_SUBSPACE_REFERENCE first to generate the results .mat.

outdir = smout('cca_subspace_reference'); % [release] outputs -> results/cca_subspace_reference
if ~isfile([outdir 'CCA_subspace_reference_results.mat']), outdir = [smroot() 'Analysis/CCA_SUBSPACE_REVISION/']; end % [release] fall back to shipped results
S = load([outdir 'CCA_subspace_reference_results.mat']);  % obs,flo,cei,COMPS,N,K
obs = S.obs; flo = S.flo; cei = S.cei; N = double(S.N);

% source panels: {name, comparison-row indices, xlabels, shared-index (0=none)}
panels = { ...
 'S1',  [1 2 3],   {'S2 | M1A','S2 | M1B','M1A | M1B'}, 0; ...
 'S2',  [4 5 6],   {'S1 | M1A','S1 | M1B','M1A | M1B'}, 3; ...
 'M1A', [7 8 9],   {'S1 | S2','S1 | M1B','S2 | M1B'},   1; ...
 'M1B', [10 11 12],{'S1 | S2','S1 | M1A','S2 | M1A'},   1};

green = [0.18 0.55 0.34]; black = [0.10 0.10 0.10];
figure('Position',[100 100 1150 330],'Color','w');
for pp = 1:4
    idx = panels{pp,2}; shared = panels{pp,4};
    subplot(1,4,pp); hold on;
    o = mean(obs(idx,:),2); e = std(obs(idx,:),0,2)/sqrt(N);
    fl = mean(flo(idx,:),2); ce = mean(cei(idx,:),2);
    fill([0 4 4 0],[min(ce)-0.6 min(ce)-0.6 max(ce)+0.6 max(ce)+0.6],[0.69 0.69 0.69],'FaceAlpha',0.45,'EdgeColor','none');
    fill([0 4 4 0],[min(fl)-0.6 min(fl)-0.6 max(fl)+0.6 max(fl)+0.6],[0.56 0.75 0.56],'FaceAlpha',0.55,'EdgeColor','none');
    for i = 1:3
        if i==shared, col = green; else, col = black; end
        errorbar(i,o(i),e(i),'o','MarkerSize',7,'Color',col,'MarkerFaceColor',col,'CapSize',4,'LineWidth',1.3);
    end
    if shared > 0
        base = max(o)+6; k = 0;
        for i = 1:3
            if i==shared, continue; end
            k = k+1; [~,p] = ttest(obs(idx(i),:), obs(idx(shared),:));
            y = base + k*3.5; x1 = min(i,shared); x2 = max(i,shared);
            plot([x1 x1 x2 x2],[y-1 y y y-1],'k','LineWidth',1);
            text((x1+x2)/2, y+0.5, pstar(p),'HorizontalAlignment','center','FontSize',10);
        end
    end
    xlim([0.4 3.6]); ylim([0 92]);
    set(gca,'XTick',1:3,'XTickLabel',panels{pp,3},'FontSize',9);
    title(['source: ' panels{pp,1}],'FontSize',11); box off;
    if pp==1, ylabel('subspace angle (deg)','FontSize',10); end
end
sgtitle(sprintf('Communication-subspace angles vs reliability floor (green) and chance (grey), n = %d, first 2 CCCs', N),'FontSize',10.5);
set(gcf,'PaperOrientation','landscape');
print(gcf, [smout('cca_subspace_reference') 'FigS_subspace_reference_MATLAB'], '-dpng','-r200');
print(gcf, [smout('cca_subspace_reference') 'FigS_subspace_reference_MATLAB'], '-dpdf','-painters','-bestfit');
end

function s = pstar(p)
if     p < 1e-3, s = '***';
elseif p < 1e-2, s = '**';
elseif p < 0.05, s = '*';
else,            s = 'n.s.';
end
end
