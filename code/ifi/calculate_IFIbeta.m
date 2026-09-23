function [IFIbeta, high, low, IFI_params, corr_map] = calculate_IFIbeta(act_proj, comp, IFI_params, show)
if nargin < 4, show = false; end
% act_proj = trial activity projected into CCA dimensions.
%   act proj should be a # of area comparisons x 2 cell array.
%   each element should be # frames x # CCA dimensions x # trials
% comp = structure containing info about the specific areas being compared in each comparsion
% IFI_params = CCA_params structure specifying binning, windowing and and delay sizes (see set_CCA_params)
% show = set to true to make a plot visualizing each correlation map and the corresponding IFIbeta. will PAUSE for each comparison and dimension. use enter to advance, or ctrl+C to stop 
% IFIbeta = information flow index beta, the slope of correlation maps with respect to delays, at each time step

data_proj = cellfun(@permute, act_proj, repmat({[2,1,3]}, size(act_proj)), 'UniformOutput',false);

% setup the windowing
IFI_params = setup_windows( size(data_proj{1},2), IFI_params );

% Generate a correlation map for each comparison
fprintf('\nCalculating correlation map...\n'); tic;
corr_map = nan(IFI_params.n_step, IFI_params.n_delay, IFI_params.dim_max, comp.n);
for cmp = 1:comp.n
    [Xwin, Ywin, ~, ~, ~] = window_activity(data_proj(cmp,:), IFI_params, false);  % break data into windows, with window size and delay specified by IFI_params
    for dm = 1:IFI_params.dim_max
        for st = 1:IFI_params.n_step
            for dl = 1:IFI_params.n_delay
                corr_map(st,dl,dm,cmp) = corr(Xwin{st}(:,dm), Ywin{st,dl}(:,dm), 'rows','complete');
            end
        end
    end
end
toc

% Calculate IFI
[IFIbeta, high, low] = get_corr_beta(corr_map, IFI_params.t_delay);
IFIbeta = permute(IFIbeta(2,:,:,:), [2,3,4,1]);  % only care about the slope, not the intercept
high = permute(high(2,:,:,:), [2,3,4,1]); % only care about the slope, not the intercept
low = permute(low(2,:,:,:), [2,3,4,1]); % only care about the slope, not the intercept

if show
    % plot individual corr maps and associated IFI_beta
    t_step = (0:(size(corr_map, 1)-1))*(IFI_params.frame_dur*IFI_params.TimeStep);
    figure('WindowState','maximized', 'color','w'); % IFI_beta_individiual_fig = 
    for cmp = 1:comp.n
        for dm = 1 %:3
            clf; sp = [];
            tiledlayout(2,1)
            sp(1) = nexttile; 
            imagesc(t_step, IFI_params.t_delay, corr_map(:,:,dm,cmp)'); hold on;
            line(t_step([1,end]), [0,0], 'color','k','linestyle','--');
            CB = colorbar; CB.Label.String = 'Corr';
            ylabel('Delay (s)'); % xlabel('Trial time (s)');
            title( sprintf('Correlation map: comparison %s, dim %i', comp.name{cmp}, dm) );
            colormap('jet')
            impixelinfo;

            sp(2) = nexttile;
            line(t_step([1,end]), [0,0], 'color','k','linestyle','--'); hold on;
            %yyaxis left
            plot(t_step, IFIbeta(:,dm,cmp))
            xlabel('Trial time (s)'); ylabel('IFI_{\beta} (\Delta corr / \Delta lag)');
            %yyaxis right
            %plot(t_step, IFIbeta(1,:,dm,c))
            %ylabel('Intercept');

            linkaxes(sp,'x')
            xlim([-Inf,Inf])
            pause; 
        end
    end
end
end