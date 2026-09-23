function show_CCA_results(results, params, fig_dir) % , CCA_params 
if nargin < 3, fig_dir = ''; end
dim_max = max(results.dim_sig(:));
close all;
clearvars h sp;
timestamp = convertStringsToChars(string(datetime('now','TimeZone','local','Format','MMM_d_y_HH_mm')));
CCA_results_fig = figure('WindowState','maximized','Color','w');
TL = [0.005,0];
if params.n_delay == 1 && params.n_step == 1
    % no delays or timesteps, just show thresholding
    n_ROI_min = size(results.r_full,3);
    CV_str = 'Cross-validation';
    if strcmpi(params.cv_style, 'han'),  CV_str = strcat(CV_str,' (Han)');  end
    JitterPlot(squeeze(results.r_shf)', 'new',false, 'monochrome',[1,0,0], 'paired',true); hold on;
    h(3) = plot(1,NaN, 'color',[1,0,0]); h(2) = plot(1,NaN, 'color',[0,0,1]);
    JitterPlot(squeeze(results.r_cv)', 'Ylabel','Corr Coeff (x-val)','xlabel','CCC Dim', 'new',false, 'monochrome',[0,0,1], 'paired',true);
    line([0,n_ROI_min], results.r_thresh*[1,1], 'color','r' ,'linestyle','--')
    axis square; axis tight;
    line(results.dim_sig*[1,1]+0.5, get(gca,'Ylim'), 'color','r' ,'linestyle','--')
    h(1) = plot(squeeze(results.r_full), 'k+', 'MarkerSize',6); hold on;
    
    ylabel('Canonical Correlation Coefficient'); xlabel('Canonical Correlation Dimension');
    title( sprintf('Found %i significant dimension', results.dim_sig) )
    legend(h, 'Full',CV_str,'Shuffle', 'Location','best','AutoUpdate','off') % NorthEastOutside
    set(gca,'Xtick',0:5:n_ROI_min, 'TickLength',TL)
    %fig_dir = add_sm_paths;
    %exportgraphics(gcf, fullfile(fig_dir,'CCA_thresholding.pdf'), 'append',true)
elseif params.n_delay > 1 && params.n_step == 1
    % no timesteps, just plot correlation vs delay to illustrate calculating IFI
    dl_pre = 1:params.dl_zero-1;
    dl_post = params.dl_zero+1:numel(params.t_delay);
    MS = 10;
    for d = 1%:max([1,dim_max])
        %subplot(1,max([1,dim_max]), d)
        mean_trace = mean(results.r_cv(:,:,d,:),4)';
        plot(params.t_delay, mean_trace); hold all; % , 'b' h(d) =
        h(1) = plot(params.t_delay(dl_pre), mean_trace(dl_pre), 'ko', 'MarkerSize',MS);
        h(2) = plot(params.t_delay(dl_post), mean_trace(dl_post), 'kx', 'MarkerSize',MS);
        legend(h, 'Bottom-up', 'Top-down','AutoUpdate','off', 'location','best')
        axis square
        xlabel({'Delay (s)','Delay > 0: source leads target'}); 
        ylabel('Corr Coeff'); 
        title({sprintf('Dim %i',d),sprintf('IFI = %2.3f', results.IFI(d))}); % , shuff = %2.3f , CCA_results.IFI_shf(d)
        %title({sprintf('Dim %i',d), 'Positive delay means src leads tgt'})
        %legend(h, [sprintfc('dim %i', 1:max([1,dim_max])), {'Shuff'}], 'Location','best','AutoUpdate','off')
    end
    %plot(CCA_params.t_delay, mean(CCA_results.r_shf(:,:,1,:),4)', 'r');

elseif params.n_delay > 1 && params.n_step > 1 % timesteps but no delays, just plot correlation over time
    % timesteps and delays, show correlation heatmaps + plot information flow
    step_size = params.t_step(2)-params.t_step(1);
    step_lims = reshape(params.t_step([1,end]), 1,2) + [-1,1]*step_size/2; % + [-1,1]*CCA_params.t_step(1)/2; % % [-1,1]*CCA_params.WindowLength*CCA_params.frame_dur/2; %  [-1,1]
    if ~isempty(fig_dir), fig_path = fullfile(fig_dir, sprintf('CCA_results_corr_map_IFI_%s.pdf', timestamp)); else, fig_path = ''; end
    for d = 1:max([1,dim_max]) % CCA_params.n_pair
        clf;
        corr_map = mean(results.r_cv(:,:,d,:),4)';
        %corr_shf_map = mean(CCA_results.r_shf(:,:,d,:),4)';
        [corr_map_max, dl_max_corr] = max(corr_map, [], 1);
        cca_lim = [min(corr_map(:)), max(corr_map(:))];
        %tiledlayout(2,1)
        
        sp(2) = subplot(2,1,2); %nexttile([1,1]);
        line(step_lims, [0,0], 'color','k','linestyle','--'); hold on;
        h(1) = plot(params.t_step, results.IFI(:,d)); %hold on;
        h(2) = plot(params.t_step, results.IFI_shf(:,d));
        legend(h, [sprintfc('dim %i', d), {'Shuff'}], 'Location','best', 'AutoUpdate','off');
        %xlim(step_lims)
        ylabel('IFI')
        xlabel('Time (s)')
        title('IFI > 0 = bottom-up info flow')
        colormap(gca, distinguishable_colors(3))
        set(gca, 'TickLength',TL)
        
        sp(1) = subplot(2,1,1); % nexttile([1,1]);
        imagesc(params.t_step, params.t_delay, corr_map ); hold on; % t_delay,
        plot(params.t_step, params.t_delay(dl_max_corr), 'kx')
        line(step_lims, [0,0], 'color','k','linestyle','--')
        clim(cca_lim); 
        CB = colorbar;  CB.Label.String = 'Correlation';
        CB.Position = [0.92, 0.5836, 0.0111, 0.3416]; 
        set(gca,'YDir','Normal', 'TickLength',TL) %set(gca,'Xtick',CCA_params.t_step)
        ylabel({'Delay (s)'}); 
        title({sprintf('Dim %i',d), 'Positive delay means src leads tgt'}) % xlabel('Time'); ,'< tg leads src .  src leads tgt >'
        impixelinfo;
        linkaxes(sp,'x');
        xlim(step_lims);
        % Save the figure to a pdf?
        if ~isempty(fig_dir)
            fprintf('\nSaving %s', fig_path);
            exportgraphics(CCA_results_fig, fig_path, 'append',true);
        else
            pause;
        end
    end
else
    % timesteps but no delays, show correlation (mean +/- error) over time
    for d = 1:max([1,dim_max])
        % make mean +/- error arrays for plotshaded
        corr_zero_mean  = mean(results.r_cv(:,params.dl_zero,d,:), 4);
        corr_zero_sem  = SEM(results.r_cv(:,params.dl_zero,d,:), 4);
        corr_zero_low = corr_zero_mean - corr_zero_sem;
        corr_zero_high = corr_zero_mean + corr_zero_sem;
        corr_shade = [corr_zero_low'; corr_zero_mean'; corr_zero_high'];
        shf_zero_mean  = mean(results.r_shf(:,params.dl_zero,d,:), 4);
        shf_zero_sem  = SEM(results.r_shf(:,params.dl_zero,d,:), 4);
        shf_zero_low = shf_zero_mean - shf_zero_sem;
        shf_zero_high = shf_zero_mean + shf_zero_sem;
        shf_shade = [shf_zero_low'; shf_zero_mean'; shf_zero_high'];

        % Make a shaded error timecourse plot
        plotshaded(params.t_step, corr_shade, '-', 'b'); hold on;
        plotshaded(params.t_step, shf_shade, '-', 'r')
        h(2) = plot(1,NaN','r'); h(1) = plot(1,NaN','b');
        axis square;
        xlabel('Trial time (s)'); ylabel('Canonical Correlation Coeffcient');
        title({sprintf('1 frame = %2.3f s, Window = %i frames, Bin = %i frames, Step = %i frames, Nshuff = %i', params.frame_dur, params.WindowLength, params.BinWidth, params.TimeStep, params.NumShuffles),   sprintf('Dimension %i', d)})
        legend(h, 'Cross-validated mean +/- SEM','Trial-shuffled mean +/- SEM', 'AutoUpdate','off', 'Location','eastoutside')
        set(gca, 'TickLength',TL)
        %fig_dir = add_sm_paths;
        %exportgraphics(gcf, fullfile(fig_dir,'CCA_timecourse_example.pdf'), 'append',true)
    end
end
%{
JitterPlot( squeeze(results.r_sub(tp,params.dl_zero,1:3,:))', 'ErrorBar',0, 'paired',true ); hold on;
plot( 1:3, squeeze(results.r_full(tp,params.dl_zero,1:3)), 'ko')
xlabel('CCA Dim'); ylabel('CC Coeff'); title('Correlation by trial-subtype');
axis square;
%}


%{
% Shuffled heatmap, not that interesting
nexttile([1,1])
imagesc(CCA_params.t_step, CCA_params.t_delay, corr_shf_map );
clim(cca_lim);
set(gca,'YDir','Normal')
title('Shuffle mean'); ylabel('Delay'); % xlabel('Time');
sgtitle(sprintf('CCA Dim %i', d) )
impixelinfo;
%}
end