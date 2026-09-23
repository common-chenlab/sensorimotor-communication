function [fov, act, corr_fov] = get_interfov_corr(fov, act, varargin)
IP = inputParser;
addRequired( IP, 'fov', @isstruct ) % iscell
addRequired( IP, 'act', @isstruct )
addParameter( IP, 'rate', 30, @isnumeric )
addParameter( IP, 'fov_name', {'S1','S2','M1_1','M1_2'}, @iscell)
addParameter( IP, 'save', '', @ischar )
addParameter( IP, 'show', true, @islogical ) % whether or not to make the plot
parse( IP, fov, act, varargin{:} );
f_common = IP.Results.rate; %f_common = 2*10;
fov_name = IP.Results.fov_name;
show = IP.Results.show;
save_dir = IP.Results.save;

% Concatenate trials
n_fov = numel(fov);
n_trial = size(act(1).trial,3);
n_frame = size(act(1).trial_resamp, 2);
act_cat = cell(1,n_fov); act_trial = cell(n_trial,n_fov);
for a = 1:n_fov
    act_cat{a} = reshape(act(a).trial_resamp, fov(a).n_ROI, [])'; % get_act_corr expects frames x ROI shape
    for tr = 1:n_trial
        act_trial{tr,a} = act(a).trial_resamp(:,:,tr)'; % get_act_corr expects frames x ROI shape
    end
end
n_ROI = cellfun(@width, act_cat);

% calculate correlation between all ROIs, within and across fovs
corr_fov = struct('mat',[], 'vec',[], 'trial_mat',[], 'trial_vec',[]); % , 'name',[]
corr_fov.trial_mat = cell(n_fov,n_fov,n_trial); corr_fov.trial_vec = cell(n_fov,n_fov,n_trial); % cell(1,n_trial)
[corr_fov.mat, corr_fov.vec, corr_full_mat, corr_full_vec] = get_act_corr(act_cat, false);
for tr = 1:n_trial
    [corr_fov.trial_mat(:,:,tr), corr_fov.trial_vec(:,:,tr)] = get_act_corr(act_trial(tr,:), false);
end
corr_fov.name = cell(n_fov, n_fov);
for a1 = 1:n_fov
    for a2 = a1:n_fov
        corr_fov.name{a1,a2} = sprintf('%s vs %s', fov_name{a1}, fov_name{a2});
    end
end

% Make a summary figure (optional)
if show
    ROI_lims = [0,cumsum(n_ROI)];
    fov_lines = ROI_lims(2:end-1)+0.5;
    fov_lims_mid = movmean(ROI_lims, 2);
    fov_lims_mid = fov_lims_mid(2:end);
    fov_ticks = sort([fov_lims_mid, fov_lines]);
    fov_tick_labels = ["S1","","S2","","M1_1","","M1_2"];
    n_trial_show = 5;
    %trial_ticks = n_frame*(1:n_trial);
    trial_show_ticks = [1, n_frame*(1:n_trial_show)+1];
    
    act_cat_plot = [act_cat{:}]'; %normalize([act_cat{:}]', 2, 'range');
    act_cat_plot = act_cat_plot(:,1:n_trial_show*n_frame);
    thresh_pct = 97; %99.5;
    act_cat_thresh = prctile(act_cat_plot, thresh_pct, 2); % set ROI-specific thresholds
    act_cat_plot = act_cat_plot./act_cat_thresh;

    FS = 15;
    interfov_corr_fig = figure('WindowState','maximized', 'color','w');
    tl = tiledlayout(2,2, 'TileSpacing','compact');
    nexttile(tl,[1,2]);
    %act_cat_fig = figure('WindowState','maximized', 'color','w');
    %opt = {[0,0], [0.15, 0.15], [0.1, 0.1]};
    %subtightplot(1,1,1,opt{:})%tiledlayout(1 , 1, 'Padding','loose');
    imagesc(act_cat_plot); hold on;
    clim([0,1])
    colormap(flipud(colormap('gray'))) % reverse grayscale: black = active, white = silent
    CB = colorbar; CB.Label.String = sprintf('Normalized activity (%2.1f pctile)',thresh_pct); CB.Label.FontSize = FS; % CB.Label.Rotation = 180;
    for a = 1:3
        line([0,size(act_cat{1},1)], fov_lines(a)*[1,1], 'color',[0,0,0,0.5])
    end
    for tr = 1:n_trial_show
        line(trial_show_ticks(tr+1)*[1,1]-0.5, [1,sum(n_ROI)], 'color',[0,0,0,0.5])
    end
    xlabel(sprintf('Trials (%2.1f s each)', n_frame/f_common)); ylabel('ROI'); 
    title(sprintf('%s: Concatenated activity, resampled to %2.1f Hz',extractBefore(fov(1).name, '-A'), f_common));
    set(gca, 'Xtick',trial_show_ticks, 'XtickLabel',1:n_trial_show, 'Ytick',fov_ticks, 'YtickLabel',fov_tick_labels, 'TickDir','out', 'ticklength',[0.004,0], ...
        'FontSize',FS, 'Units','normalized') % , 'XtickLabel',1:trials.n_all , 'Position',[0.01, 0.01, 0.99, 0.99] 
    %save_path = ChenLabFilepath(fullfile(save_dir, 'concatenated_trial_activity_example.png')); % sprintf()
    %fprintf('\nSaving figure to %s', save_dir)
    %exportgraphics(act_cat_fig, save_path) % , 'Append',true
    impixelinfo

    nexttile;
    %corr_fov_fig = figure('WindowState','maximized', 'color','w');
    %opt = {[0,0], [0.15, 0.15], [0.1, 0.1]};
    %subtightplot(1,1,1,opt{:})
    imagesc(corr_full_mat); hold on;
    xlabel('ROI'); ylabel('ROI'); title('Overall, zero-delay correlation');
    axis square;
    corr_lims = prctile(corr_full_vec, [100-thresh_pct,thresh_pct]); % prctile(corr_full_vec, thresh_pct)*[-1,1]; %  [min(corr_full_vec),  max(corr_full_vec)]
    clim(corr_lims);
    colormap(gca,'bluewhitered') %bluewhitered %colormap(flipud(gray)); %colormap gray
    CB = colorbar; CB.Label.String = sprintf('Correlation (0.1-%2.1f pctile)', thresh_pct); %CB.Label.Rotation = 0%
    for a = 1:3
        line([0,size(corr_full_mat,1)], fov_lines(a)*[1,1], 'color',[0,0,0,1], 'LineWidth',1.5)
        line(fov_lines(a)*[1,1], [0,size(corr_full_mat,1)], 'color',[0,0,0,1], 'LineWidth',1.5)
    end
    set(gca, 'Xtick',fov_ticks, 'XtickLabel',fov_tick_labels, 'Ytick',fov_ticks, 'YtickLabel',fov_tick_labels, 'TickDir','out', 'ticklength',[0.002,0], 'FontSize',FS)
    %save_path = ChenLabFilepath(fullfile(save_dir, 'corr_fov_example.png')); % sprintf()
    %fprintf('\nSaving figure to %s', save_dir)
    %exportgraphics(corr_fov_fig, save_path) % , 'Append',true

    nexttile;
    fov_pair_ind = [find(logical(eye(size(corr_fov.vec))))', find(triu(true(size(corr_fov.vec)), 1))']; % diagonals, then inter-area    triu(true(size(corr_fov.vec)))
    %violin([{corr_full_vec}, corr_fov.vec(fov_pair_ind)]) %[{corr_full_vec}, corr_fov.vec(fov_pair_ind)]
    boxplot(cell2padmat([{corr_full_vec}, corr_fov.vec(fov_pair_ind)]));  %boxplot(cell2padmat(corr_fov.vec(triu(true(size(corr_fov.vec))))'))
    ylabel('Pairwise correlation')
    set(gca,'XtickLabel',['All ROIs', corr_fov.name(fov_pair_ind)], 'TickLabelInterpreter','tex', 'FontSize',FS)
    %ecdfCol(cell2padmat(corr_fov.vec(triu(true(size(corr_fov.vec))))'), 'new',true, 'xlabel','Pairwise correlation', 'pool',true, 'names',corr_fov.name(triu(true(size(corr_fov.name))))')
    if ~isempty(save_dir)
        save_path = ChenLabFilepath(fullfile(save_dir, 'interfov_corr_30hz.pdf')); % sprintf()
        fprintf('\nSaving figure to %s', save_dir)
        try
            exportgraphics(interfov_corr_fig, save_path, 'Append',true)
        catch
            warning('Failed to update %s - is the file open?', save_path)
        end
    end
end
end
