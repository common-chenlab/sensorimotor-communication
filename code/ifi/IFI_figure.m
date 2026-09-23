clear; clc; close all;

% setup dependencies
% [release] path handled by startup_sm.m: addpath('Z:\Dropbox\Chen Lab Dropbox\Chen Lab Team Folder\Analysis Suite\PIPELINE\') 
add_sm_paths(); % [main_dir, fig_dir] = 
add_cca_paths;

% Load exported data
load([smroot() 'Analysis/proj/full-resid_stim/sm045-4-CCA_proj_full-resid_stim.mat'], 'act_proj','comp');
animal = 'sm045';
session = '4';
path1 = [smroot() 'Analysis/preprocessing/'];
name1 = [animal '-' session '_preprocess_pca.mat'];
load([path1 name1]);

% set parameters for calculating IFI
IFI_params = set_CCA_params('name','', 'BinWidth',1, 'WindowLength',15, 'TimeStep',3, 'DelayStep',3, 'MaxDelay',12, 'dim_max',2); % units of FRAMES. SM data is 30 Hz

% Calculate IFIbeta (# steps x # dimensions x # comparisons)
[IFIbeta, high, low, IFI_params, corr_map] = calculate_IFIbeta(act_proj, comp, IFI_params, true);
t_step = (0:(size(corr_map, 1)-1))*(IFI_params.frame_dur*IFI_params.TimeStep);
[IFIbeta, high, low] = get_corr_beta(corr_map, IFI_params.t_delay);
%IFIbeta = permute(IFIbeta(2,:,:,:), [2,3,4,1]);  % only care about the slope, not the intercept

%% make separate trial rasters of CCA-projections: S1 and M1
% specify the data
dm = 1; % only analyzed first CCA dim for IFI
cmp = 2; %cmp2 = S1-M1A
raster1 = permute(act_proj{cmp,1}(:,dm,:), [3,1,2]); % S1
raster2 = permute(act_proj{cmp,2}(:,dm,:), [3,1,2]); % M1A

step_ex = 76; % specific step to show for right panel ie correlation/delay slope
step_lims = [66,86];
t_lims = 3*step_lims;
%t_step(step_ex)

% set figure parameters
paperWidth = 1; paperHeight = 0.7; % % Set figure paper size (in inches)
cpct = 99.5;
LW = 1.5;

% make the source raster figure
IFI_src_fig = figure('color','w'); % IFI_beta_individiual_fig = 'WindowState','maximized'
set(IFI_src_fig, 'PaperUnits', 'inches', 'PaperSize', [paperWidth, paperHeight], 'PaperPosition', [0, 0, paperWidth, paperHeight]);
h = imagesc(raster1); hold on;
xlim(t_lims)
cmax1 = prctile(abs(raster1(:)), cpct); %max(abs(raster1), [], 'all'); %
clim(cmax1*[-1,1])
colormap('bluewhitered') % colormap('gray') %
set(h, 'AlphaData', ~isnan(raster1)); % make missing data transparent
set(gca, 'Xtick',[], 'Ytick',[], 'LineWidth',LW, 'Position',[0 0 1 1])
%colorbar
%impixelinfo;

% Export to eps
fig_path = (string(smout('figures/Figure6-IFI')) + "IFI_src.eps");
fprintf("\nSaving %s\n", fig_path)
print(IFI_src_fig, '-depsc', fig_path); 


% make the target raster figure
IFI_tgt_fig = figure('color','w'); % IFI_beta_individiual_fig = 'WindowState','maximized'
set(IFI_tgt_fig, 'PaperUnits', 'inches', 'PaperSize', [paperWidth, paperHeight], 'PaperPosition', [0, 0, paperWidth, paperHeight]);
h = imagesc(raster2); hold on;
xlim(t_lims)
cmax2 = prctile(abs(raster2(:)), cpct); %max(abs(raster1), [], 'all'); %
clim(cmax2*[-1,1])
colormap('bluewhitered') % colormap('gray') %
set(h, 'AlphaData', ~isnan(raster2)); % make missing data transparent
set(gca, 'Xtick',[], 'Ytick',[], 'LineWidth',LW, 'Position',[0 0 1 1])
%colorbar
%impixelinfo;

% Export to eps
fig_path = (string(smout('figures/Figure6-IFI')) + "IFI_tgt.eps");
fprintf("\nSaving %s\n", fig_path)
print(IFI_tgt_fig, '-depsc', fig_path); 

%% example IFI calculation. slope method
lag_ex = 1:size(corr_map,2);
corr_ex = corr_map(step_ex,:,dm,cmp); % correlation for each delay iteration, at the example timepoint
corr_fit = polyval(polyfit(lag_ex, corr_ex, 1), lag_ex);

paperWidth = 0.7; paperHeight = 0.7; % Set figure paper size (in inches)
MS = 3; % marker size
close all;
IFI_slope_fig = figure('color','w');
set(IFI_slope_fig, 'PaperUnits', 'inches', 'PaperSize', [paperWidth, paperHeight], 'PaperPosition', [0, 0, paperWidth, paperHeight]);
plot(lag_ex, corr_ex, 'ko', 'MarkerSize',MS); hold on;
plot(lag_ex, corr_fit, 'k', 'LineWidth',LW)
xlim([0.5,9.5])
axis square;
box off;
set(gca,'TickDir','out', 'LineWidth',1, 'Xtick',[1,5,9], 'XtickLabel',[], 'YtickLabel',[], 'TickLength',[0.03,0]) % , 'Position',[0, 0, 0.9, 0.9]

% Export to eps
fig_path = (string(smout('figures/Figure6-IFI')) + "IFI_slope.eps");
fprintf("\nSaving %s\n", fig_path)
print(IFI_slope_fig, '-depsc', fig_path); 


%% combined trial rasters of CCA-projections: S1 and M1
%{ 
paperWidth = 2; paperHeight = 1; % % Set figure paper size (in inches)
IFI_src_fig = figure('color','w'); % IFI_beta_individiual_fig = 'WindowState','maximized'
set(IFI_src_fig, 'PaperUnits', 'inches', 'PaperSize', [paperWidth, paperHeight], 'PaperPosition', [0, 0, paperWidth, paperHeight]);
cpct = 99;
LW = 3;
dm = 1; % only analyzed first CCA dim for IFI
for cmp = 1%:comp.n
    raster1 = permute(act_proj{cmp,1}(:,dm,:), [3,1,2]); % S1
    raster2 = permute(act_proj{cmp,2}(:,dm,:), [3,1,2]); % M1A

    clf; sp = []; h = [];
    tiledlayout(1,2, 'TileSpacing','compact', 'Padding','tight');
    sp(1) = nexttile;
    h(1) = imagesc(raster1); hold on;
    %line([30,45], [])

    cmax1 = prctile(abs(raster1(:)), cpct); %max(abs(raster1), [], 'all'); %
    clim(cmax1*[-1,1])
    colormap('bluewhitered') % colormap('gray') %
    set(h(1), 'AlphaData', ~isnan(raster1)); % make missing data transparent
    set(sp(1), 'Xtick',[], 'Ytick',[], 'LineWidth',LW)
    %colorbar

    %impixelinfo;

    sp(2) = nexttile;
    h(2) = imagesc(raster2); hold on;
    set(h(2), 'AlphaData', ~isnan(raster2)); % make missing data transparent
    set(sp(2), 'Xtick',[], 'Ytick',[])
    cmax2 = prctile(abs(raster2(:)), cpct); %max(abs(raster1), [], 'all'); %
    clim(cmax2*[-1,1])
    set(sp(2), 'Xtick',[], 'Ytick',[], 'LineWidth',LW)
    %colorbar
    linkaxes(sp,'x')
    xlim([-Inf,Inf])
    %pause;
end


% Export to PDF
fig_path = (string(smout('figures/Figure6-IFI')) + "Fig6Aleft.eps");
fprintf("\nSaving %s\n", fig_path)
print(IFI_src_fig, '-depsc', fig_path); %  '-dpdf'

%}
