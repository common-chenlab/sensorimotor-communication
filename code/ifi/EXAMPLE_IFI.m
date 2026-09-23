BATCH_IFI(control, control_choice, 17);


% plot individual corr maps and associated IFI_beta
t_step = (0:(size(corr_map, 1)-1))*(IFI_params.frame_dur*IFI_params.TimeStep);
figure('WindowState','maximized', 'color','w'); % IFI_beta_individiual_fig =
for cmp = 1:comp.n
    for dm = 1 %:3
        figure(cmp);
        sp = [];
        tiledlayout(2,1)
        sp(1) = nexttile;
        imagesc(t_step, IFI_params.t_delay, corr_map(:,:,dm,cmp)'); hold on;
        line(t_step([1,end]), [0,0], 'color','k','linestyle','--');
        CB = colorbar; CB.Label.String = 'Corr';
        ylabel('Delay (s)'); % xlabel('Trial time (s)');
        title( sprintf('Correlation map: comparison %s, dim %i', comp.name{cmp}, dm) );
        colormap('jet')
        caxis([0 1])
        impixelinfo;

        sp(2) = nexttile;
        line(t_step([1,end]), [0,0], 'color','k','linestyle','--'); hold on;
        %yyaxis left
        plot(t_step, IFIbeta(:,dm,cmp))
        xlabel('Trial time (s)'); ylabel('IFI_{\beta} (\Delta corr / \Delta lag)');
        %yyaxis right
        %plot(t_step, IFIbeta(1,:,dm,c))
        %ylabel('Intercept');
        ylim([-1 0.4])
        linkaxes(sp,'x')
        xlim([-Inf,Inf])
        
    end
end