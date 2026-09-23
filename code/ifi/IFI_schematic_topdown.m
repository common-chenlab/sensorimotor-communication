%% setup
% setup dependencies
% [release] path handled by startup_sm.m: addpath('Z:\Dropbox\Chen Lab Dropbox\Chen Lab Team Folder\Analysis Suite\PIPELINE\') 
add_sm_paths(); % [main_dir, fig_dir] = 
add_cca_paths;

% Load comparisons structure
load([smroot() 'Analysis/proj/full-resid_stim/sm045-4-CCA_proj_full-resid_stim.mat'], 'comp'); % 'act_proj',

%% Generate pseudodata to illustrate IFI calculation
close all; clear;
% Parameters
numTrials = 275;
tr_null = randperm(numTrials, round(0.25*numTrials)); %  a subset of trials show no transient
numTimePoints = 323; % frames, at 30 Hz
transientCenter = round(numTimePoints / 2);
transientWidth = 5;       % Width (std dev) of the transient
baselineRate = 0.2;          % Baseline firing rate (spikes/time bin)
transientAmplitude = 1.5;   % Peak additional firing rate due to transient
response_offset = -12; % how many frames after the event do we see the response? negative if tgt precedes src

% Create time vector
timeVec = 1:numTimePoints;

% Baseline firing rate matrix (same baseline for all cells, can be modified)
baselineRates = baselineRate * ones(numTrials, numTimePoints);
%figure; imagesc(baselineRates); impixelinfo

% Transient firing rate profile (Gaussian bump)
transientProfile = transientAmplitude * exp(-((timeVec - transientCenter).^2) / (2 * transientWidth^2));
%figure; plot(transientProfile);

% Add transient to baseline rates for each cell, optionally add cell-to-cell rate variability
cellBaselineVariability = 0.3 * randn(numTrials,1);  % small variability per cell (additive in rate)
cellBaselineVariability = max(cellBaselineVariability, -baselineRate + 0.1); % avoid negative rates
for i = 1:numTrials
    baselineRates(i, :) = baselineRates(i, :) + cellBaselineVariability(i);
end
%figure; imagesc(baselineRates); impixelinfo

% Add transient profile to a subset of trials
transientTrials = transientProfile.*ones(numTrials, numTimePoints);
transientTrials(tr_null, :) = 0;
%figure; imagesc(transientTrials); impixelinfo

firingRates = baselineRates + transientTrials;  % size: 275 x 258
firingRates(firingRates < 0) = 0;                % clip to zero
%figure; imagesc(firingRates); impixelinfo

% Generate Poisson-distributed spike counts
activity = cell(1,2);
activity{1,1} = poissrnd(firingRates);

% generate response activity from a second area
% Parameters

response_center = round(numTimePoints / 2) + response_offset;

% Baseline firing rate matrix (same baseline for all cells, can be modified)
baselineRates = baselineRate * ones(numTrials, numTimePoints);
%figure; imagesc(baselineRates); impixelinfo

% Transient firing rate profile (Gaussian bump)
responseProfile = transientAmplitude * exp(-((timeVec - response_center).^2) / (2 * transientWidth^2));
%figure; plot(transientProfile);

% Add transient to baseline rates for each cell, optionally add cell-to-cell rate variability
cellBaselineVariability = 0.3 * randn(numTrials,1);  % small variability per cell (additive in rate)
cellBaselineVariability = max(cellBaselineVariability, -baselineRate + 0.1); % avoid negative rates
for i = 1:numTrials
    baselineRates(i, :) = baselineRates(i, :) + cellBaselineVariability(i);
end
%figure; imagesc(baselineRates); impixelinfo

% Add transient profile to a subset of trials
responseTrials = responseProfile.*ones(numTrials, numTimePoints);
responseTrials(tr_null, :) = 0;
%figure; imagesc(transientTrials); impixelinfo

responseRates = baselineRates + responseTrials;  % size: 275 x 258
responseRates(responseRates < 0) = 0;                % clip to zero
%figure; imagesc(firingRates); impixelinfo

% Generate Poisson-distributed spike counts
activity{1,2} = poissrnd(responseRates);

% show the simultaneous activity in the 2 areas
figure;
tiledlayout(2,1)
sp(1) = nexttile();
imagesc(activity{1,1}); 
colormap(flipud(gray)) %colormap gray
impixelinfo
%plot(timeVec, activity(1:10, :));
ylabel('Trial');

sp(2) = nexttile();
imagesc(activity{1,2}); 
colormap(flipud(gray)) %colormap gray
impixelinfo
%plot(timeVec, activity(1:10, :));
xlabel('Time');
ylabel('Trial');
linkaxes(sp,'xy')

%% plug the pseudodata into the IFI calcuator

% convert simulated activity to expected format
act_sim = cellfun(@permute, activity, repmat({[2,3,1]},1,2), 'UniformOutput', false); % calculator expects 6x2 cell array of n_timepoint x n_CC x n_trial arrays
act_sim = repmat(act_sim,6,1);

% Calculate IFIbeta (# steps x # dimensions x # comparisons)
IFI_params = set_CCA_params('name','', 'BinWidth',1, 'WindowLength',15, 'TimeStep',3, 'DelayStep',3, 'MaxDelay',12, 'dim_max',1); % set parameters for calculating IFI. units of FRAMES. SM data is 30 Hz
[~, ~, ~, IFI_params, corr_map] = calculate_IFIbeta(act_sim, comp, IFI_params, true); % IFIbeta, high, low, IFI_params, 
t_step = (0:(size(corr_map, 1)-1))*(IFI_params.frame_dur*IFI_params.TimeStep);
IFIbeta = get_corr_beta(corr_map, IFI_params.t_delay);
%IFIbeta = permute(IFIbeta(2,:,:,:), [2,3,4,1]);  % only care about the slope, not the intercept
n_step = size(corr_map,1);

%% example IFI calculation. slope method

dm = 1; 
cmp = 1;
step_ex = median(1:103); % 55;
lag_ex = flip(1:size(corr_map,2));
corr_ex = corr_map(step_ex,:,dm,cmp); % correlation for each delay iteration, at the example timepoint
corr_poly = polyfit(lag_ex, corr_ex, 1);
corr_fit = polyval(corr_poly, lag_ex);

% set figure parameters
paperWidth = 1; paperHeight = 0.7; % % Set figure paper size (in inches)
LW = 1.5;
MS = 3; % marker size

%close all;
IFI_slope_fig = figure('color','w');
set(IFI_slope_fig, 'PaperUnits', 'inches', 'PaperSize', [paperWidth, paperHeight], 'PaperPosition', [0, 0, paperWidth, paperHeight]);
plot(lag_ex, corr_ex, 'ko', 'MarkerSize',MS); hold on;
plot(lag_ex, corr_fit, 'k', 'LineWidth',LW)
xlim([0.5,9.5])
ylim([-Inf,Inf]) % [-0.1, 0.2]
axis square;
box off;
set(gca,'TickDir','out', 'LineWidth',1, 'Xtick',[1,5,9], 'XtickLabel',[], 'Ytick',[0,0.1], 'YtickLabel',[], 'TickLength',[0.03,0]) % , 'Position',[0, 0, 0.9, 0.9] , 'Ytick',-0.1:0.1:0.2

% Export to eps
fig_path = (string(smout('figures/Figure6-IFI')) + "IFI_schem_slope_TD.eps");
fprintf("\nSaving %s\n", fig_path)
print(IFI_slope_fig, '-depsc', fig_path); 


fprintf("IFI(t) = %1.3f", IFIbeta(2,step_ex,dm,cmp))
%% Export each raster as a separate eps file

full_width = 2; % seconds
step_size = 0.1; % seconds per step
t_lims = 3*(step_ex + full_width/(2*step_size)*[-1,1]);

% make the source raster figure
IFI_src_fig = figure('color','w'); % IFI_beta_individiual_fig = 'WindowState','maximized'
set(IFI_src_fig, 'PaperUnits', 'inches', 'PaperSize', [paperWidth, paperHeight], 'PaperPosition', [0, 0, paperWidth, paperHeight]);
h = imagesc(activity{1,1}); hold on;
xlim(t_lims)
colormap(flipud(gray))
set(gca, 'Xtick',[], 'Ytick',[], 'LineWidth',LW, 'Position',[0 0 1 1])
%colorbar
%impixelinfo;

% Export to eps
fig_path = (string(smout('figures/Figure6-IFI')) + "IFI_schem_src_TD.eps");
fprintf("\nSaving %s\n", fig_path)
print(IFI_src_fig, '-depsc', fig_path); 


% make the target raster figure
IFI_tgt_fig = figure('color','w'); % IFI_beta_individiual_fig = 'WindowState','maximized'
set(IFI_tgt_fig, 'PaperUnits', 'inches', 'PaperSize', [paperWidth, paperHeight], 'PaperPosition', [0, 0, paperWidth, paperHeight]);
h = imagesc(activity{1,2}); hold on;
xlim(t_lims)
colormap(flipud(gray)) 
set(gca, 'Xtick',[], 'Ytick',[], 'LineWidth',LW, 'Position',[0 0 1 1])
%colorbar
%impixelinfo;

% Export to eps
fig_path = (string(smout('figures/Figure6-IFI')) + "IFI_schem_tgt_TD.eps");
fprintf("\nSaving %s\n", fig_path)
print(IFI_tgt_fig, '-depsc', fig_path); 


%%
%{
% Parameters
numCells = 275;
numTimePoints = 258;
transientCenter = round(numTimePoints / 2);
transientWidth = 20;       % Width (std dev) of the transient
baselineRate = 5;          % Baseline firing rate (spikes/time bin)
transientAmplitude = 10;   % Peak additional firing rate due to transient

% Create time vector
timeVec = 1:numTimePoints;

% Baseline firing rate matrix (same baseline for all cells, can be modified)
baselineRates = baselineRate * ones(numCells, numTimePoints);

% Transient firing rate profile (Gaussian bump)
transientProfile = transientAmplitude * exp(-((timeVec - transientCenter).^2) / (2 * transientWidth^2));

% Add transient to baseline rates for each cell, optionally add cell-to-cell rate variability
cellBaselineVariability = 0.3 * randn(numCells,1);  % small variability per cell (additive in rate)
cellBaselineVariability = max(cellBaselineVariability, -baselineRate + 0.1); % avoid negative rates
for i = 1:numCells
    baselineRates(i, :) = baselineRates(i, :) + cellBaselineVariability(i);
end

% Add transient profile
firingRates = baselineRates + transientProfile;  % size: 275 x 258
firingRates(firingRates < 0) = 0;                % clip to zero

% Generate Poisson-distributed spike counts
activity = poissrnd(firingRates);

% Example plot for 10 cells
figure;
plot(timeVec, activity(1:10, :));
xlabel('Time');
ylabel('Spike count (activity)');
title('Cell activity with Poisson noise and transient increase');
legend(arrayfun(@(x) sprintf('Cell %d', x), 1:10, 'UniformOutput', false));
%}