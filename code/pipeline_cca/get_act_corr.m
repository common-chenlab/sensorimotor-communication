function [corr_mat, corr_vec, corr_full_mat, corr_full_vec] = get_act_corr(act_fov, show, fov_name)
% act_fov should be a 1xn_fov cell array of activity data with equal heights
if nargin < 2, show = false; end
if nargin < 3, fov_name = ''; end
n_fov = numel(act_fov);
n_ROI = cellfun(@width, act_fov);
act_fov = [act_fov{:}]; % concatenate horizontally

% initialize outputs, and skip if act_fov is missing everything
corr_mat = cell(n_fov, n_fov); corr_vec = cell(n_fov, n_fov); %corr_fov.name = cell(n_fov,n_fov);
corr_full_mat = nan(sum(n_ROI)); corr_full_vec = [];
if all(isnan(act_fov)), return, end

% calculate correlation between all ROIs, within and across areas
corr_full_mat = corrcoef(act_fov, 'Rows','complete'); % correlation matrix pooling all FOV
corr_full_vec = corr_full_mat(triu(true(size(corr_full_mat)), 1)); % all non trivial correlation coefficients
ROI_lims = [0,cumsum(n_ROI)];

% get distributions of correlations broken out by area
for a1 = 1:n_fov
    roi_a1 = ROI_lims(a1)+1:ROI_lims(a1+1);
    for a2 = a1:n_fov
        roi_a2 = ROI_lims(a2)+1:ROI_lims(a2+1);
        corr_mat{a1,a2} = corr_full_mat(roi_a2,roi_a1);
        if a1 == a2
            corr_vec{a1,a2} = corr_mat{a1,a2}(triu(true(size(corr_mat{a1,a2})), 1));
        else
            corr_vec{a1,a2} = corr_mat{a1,a2}(:);
        end

    end
end


% Show the process (optional)
if show
    % Set up axis ticks and labels
    area_lines = ROI_lims(2:end-1)+0.5;
    area_lims_mid = movmean(ROI_lims, 2); area_lims_mid = area_lims_mid(2:end);
    area_ticks = sort([area_lims_mid, area_lines]);
    if isempty(fov_name), fov_name = sprintfc('%i', 1:n_fov); end
    fov_pair_name = cell(n_fov);
    for a1 = 1:n_fov
        for a2 = 1:n_fov
          fov_pair_name{a1,a2} = sprintf('%s vs %s', fov_name{a1}, fov_name{a2});
        end
    end
    fov_pair_ind = [find(logical(eye(n_fov)))', find(triu(true(n_fov), 1))'];
    area_tick_labels = cell(1,2*n_fov);
    for fov = 1:n_fov
        area_tick_labels{2*fov-1} = fov_name{fov};
        area_tick_labels{2*fov} = '';
    end
    area_tick_labels(end) = [];

    % Show the process of getting area vs area correlations
    thresh_pct = 99.5;
    FS = 18;
    close all; figure('WindowState','maximized')
    subplot(2,3,1:3);
    imagesc(zscore(act_fov)'); hold on;
    for a = 1:numel(area_lines)
        line([0,size(corr_full_mat,1)], area_lines(a)*[1,1], 'color',[0,0,0,0.7])
    end
    clim([-3,3])
    colormap bluewhitered
    set(gca,'Ytick',area_ticks, 'YtickLabel',area_tick_labels, 'TickDir','out', 'ticklength',[0.002,0], 'FontSize',FS); % ,'Ytick',area_ticks, 'YtickLabel',area_tick_labels

    subplot(2,3,4)
    imagesc(corr_full_mat); hold on;
    axis square;
    corr_lims = prctile(corr_full_vec, [0.1,thresh_pct]); % prctile(corr_full_vec, thresh_pct)*[-1,1]; %  [min(corr_full_vec),  max(corr_full_vec)]
    %clim(corr_lims);
    colormap(gca,'bluewhitered')
    for a = 1:numel(area_lines)
        line([0,size(corr_full_mat,1)], area_lines(a)*[1,1], 'color',[0,0,0,0.7])
        line(area_lines(a)*[1,1], [0,size(corr_full_mat,1)], 'color',[0,0,0,0.7])
    end
    set(gca,'Xtick',area_ticks, 'XtickLabel',area_tick_labels,'Ytick',area_ticks, 'YtickLabel',area_tick_labels, 'TickDir','out', 'ticklength',[0.002,0], 'FontSize',FS);
    CB = colorbar; %CB.Label.String = 'Correlation (0.1-thresh_pct%ile)';
    %impixelinfo;
    
    % Show a closeup of each specific correlation submatrix, and their distributions
    subplot(2,3,6)
    violin(cell2padmat(corr_vec(fov_pair_ind)))
    %boxplot(cell2padmat(corr_pool(fov_pair_ind)))
    set(gca, 'FontSize',FS, 'Xtick',1:numel(fov_pair_ind), 'XtickLabel',fov_pair_name(fov_pair_ind), 'box','off')
    ylabel('Correlation')

    for a1 = 1:n_fov
        for a2 = a1:n_fov
            % Continue showing the process of getting area vs area correlations
            subplot(2,3,5)
            cla;
            imagesc(corr_mat{a1,a2}); hold on;
            title(sprintf('%s vs %s', fov_name{a1}, fov_name{a2}))
            axis image;
            clim(corr_lims);
            colormap(gca,'bluewhitered')
            set(gca,'TickDir','out', 'ticklength',[0.002,0], 'FontSize',FS);
            impixelinfo;
            pause;
        end
    end
end