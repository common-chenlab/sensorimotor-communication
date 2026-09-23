function PCA = run_PCA_SM(act_in, varargin)
IP = inputParser;
addRequired( IP, 'act_in', @isnumeric ) % iscell
addOptional( IP, 'param', [], @isstruct ) 
addParameter( IP, 'name', '', @ischar ) 
addParameter( IP, 'save', '', @ischar ) % ChenLabFilepath([smout('figures') 'PCA_SM_std.pdf'])
addParameter( IP, 'show', false, @islogical ) % whether or not to make the plot
parse( IP, act_in, varargin{:} );
param = IP.Results.param;
show = IP.Results.show;
save_path = IP.Results.save;
fov_name = IP.Results.name;

[n_obs, n_var] = size(act_in); % 

% Set default parameters
PCA.param.standardize = true;
PCA.param.explained_cutoff = 75;
PCA.param.dim_max = NaN;
%PCA.param.prom_cutoff = 5; % # of PCs to check for prominent cells
%PCA.param.prom_retain = 5; % # of prominent cells cells to retain from each PC
% Set parameters by hand, if provided
if ~isempty(param)
    if isfield(param, 'dim_max') && param.dim_max > 0
        if param.dim_max <= size(act_in,2)
            PCA.param.dim_max = param.dim_max;
        else
            PCA.param.dim_max = size(act_in,2);
        end
    elseif isfield(param, 'explained_cutoff') && param.dim_max > 0
        PCA.param.explained_cutoff = param.explained_cutoff;
        PCA.param.dim_max = Inf;
    end
    if isfield(param, 'standardize'),  PCA.param.standardize = param.standardize; end
end

% Perform the PCA, and save key results to the struct
if PCA.param.standardize
    stand_str = 'Standardized';
    act_in = normalize(act_in); 
else
    stand_str = 'Unstandardized';
end
[coeff, score, latent, tsquared, explained, mu] = pca(act_in); % , 'VariableWeights','variance'
PCA.result.coeff = coeff;  % check orthogonality PCA.result.coeff'*PCA.result.coeff
%if PCA.param.standardize, PCA.result.coeff = diag(std(act_in))\PCA.result.coeff; end
PCA.result.score = score;
PCA.result.latent = latent;
PCA.result.tsquared = tsquared;
PCA.result.explained = explained;
PCA.result.dim_cutoff = find(cumsum(PCA.result.explained) >= PCA.param.explained_cutoff, 1, 'first');
PCA.result.explained_max_dim = sum(PCA.result.explained(1:PCA.param.dim_max));

% look for cells that are prominent in the cutoff coefficient matrix
% PCA.result.influence = sum(abs(PCA.result.coeff(:,1:PCA.result.dim_cutoff)).*PCA.result.explained(1:PCA.result.dim_cutoff)', 2); % influence of ROI in top few coefficients
% [~, ROI_inf_sort] = sort(PCA.result.influence, 'descend');
% PCA.result.ROI_prom = ROI_inf_sort(1:min([PCA.param.prom_retain,PCA.result.dim_cutoff]))';

% Fit the spectrum to a power-law and read off the exponent
x_temp = (1:length(PCA.result.explained))';
f = fit(x_temp, PCA.result.explained,'power1');
beta_temp = coeffvalues(f);
PCA.result.exponent = beta_temp(2);

% Reconstruct the act_in using fewer PCs (either dim_max, or dim_cutoff if max is not provided)
if isfinite(PCA.param.dim_max)
    PCA.param.dim_recon = PCA.param.dim_max;
else
    PCA.param.dim_recon = PCA.result.dim_cutoff;
end


if show
    result_recon = PCA.result.score(:,1:PCA.param.dim_recon)*PCA.result.coeff(:,1:PCA.param.dim_recon)' + mean(act_in, 1, 'omitnan'); % reconstruction of data from specified PCs

    FS =14;
    lim_pct = [1,99];
    %close all
    figure('WindowState','maximized', 'color','w')
    t = tiledlayout(6,3);
    sp(1) = nexttile(t, [2,2]);
    imagesc(act_in');
    set(gca,'FontSize',FS, 'box', 'off');
    clim([-3,3])%clim(prctile(act_in(:), lim_pct)) %
    colormap(gca, 'bluewhitered') % %colormap(sp(1), flipud(colormap('gray')))
    std_str = " (z-score)"; % std_str(PCA.param.standardize)
    CB(1) = colorbar(); CB(1).Label.String = strcat("Deconvolved activity", std_str{PCA.param.standardize});  CB(1).Label.FontSize = FS;
    ylabel('ROI')
    title(sprintf('%s Observed (%s)', fov_name, stand_str))

    sp(2) = nexttile(t, [2,2]);
    imagesc(result_recon');
    set(gca,'FontSize',FS, 'box', 'off')
    clim([-3,3])% clim(prctile(result_recon(:), lim_pct))
    colormap(sp(2), 'bluewhitered') %colormap(sp(2), flipud(colormap('gray')));
    CB(2) = colorbar(); CB(2).Label.String = "Reconstructed"; CB(2).Label.FontSize = FS;
    ylabel('ROI')
    title(sprintf('Reconstructed using first %i PCs (%2.2f pct of variance explained)', PCA.param.dim_recon, sum(PCA.result.explained(1:PCA.param.dim_recon))))

    sp(3) = nexttile(t, [2,2]);
    imagesc(PCA.result.score'); hold on;
    line([1,size(PCA.result.score,1)], PCA.param.dim_recon*[1,1]+0.5, 'color',[0,0,0,0.5])
    line([1,size(PCA.result.score,1)], PCA.result.dim_cutoff*[1,1]+0.5, 'color',[1,0,0,0.5])
    set(gca,'FontSize',FS, 'box', 'off')
    clim(prctile(PCA.result.score(:), lim_pct))
    colormap(gca, 'bluewhitered');
    CB(3) = colorbar(); CB(3).Label.String = "PCA score"; CB(3).Label.FontSize = FS;
    title('Principal Component Scores')
    ylabel('PC')
    xlabel('Concatenated frame')
    linkaxes(sp,'xy')

    nexttile(t, [3,1])
    imagesc(PCA.result.coeff);  % (:,1:PCA.result.dim_cutoff)
    hold on;
    plot(PCA.result.dim_cutoff*[1,1]+0.5, [0,n_var], 'color','k', 'linestyle','--')
    plot(PCA.param.dim_max*[1,1]+0.5, [0,n_var], 'color','k')
    impixelinfo;
    colormap(gca,'bluewhitered')
    CB(4) = colorbar(); CB(4).Label.String = "Coefficient value"; CB(4).Label.FontSize = FS;
    axis image;
    ylabel('ROI'); xlabel('PCs'); % (1st -> cutoff)
    title('Coefficient Matrix')
    %yyaxis right;
    set(gca, 'TickDir','out','FontSize',FS) % ,'Ytick',sort(PCA.result.ROI_prom)

    nexttile(t, [3,1])
    plot(f, x_temp, PCA.result.explained); hold on;
    plot(PCA.result.dim_cutoff, PCA.result.explained(PCA.result.dim_cutoff), 'o')
    axis square;
    xlabel('Component #'); ylabel('% Variance Explained')
    title(sprintf('Exponent = %2.2f', PCA.result.exponent))
    set(gca,'FontSize',FS)
    legend('Data','Fit','Cutoff PC', 'AutoUpdate','off', 'Location','east');
    axis tight;

    yyaxis right
    plot(cumsum(PCA.result.explained)); hold on;
    line(PCA.param.dim_max*[1,1], [0,100], 'color','k')
    line(PCA.result.dim_cutoff*[1,1], [0,100], 'color','k', 'linestyle','--')
    ylabel('Total Variance Explained')
    axis square;
    axis tight;

    %sgtitle(stand_str);

    if ~isempty(save_path)
        fprintf('\nSaving figure: %s', save_path)
        try
            exportgraphics(gcf, save_path, 'Append',true)
        catch
            warning('Failed to update %s - is the file open?', save_path)
        end
    end
end
end
%{
Make the scores Shuting's way
sc = nan(n_obs, PCA.param.dim_recon);
for ob = 1:n_obs
    sc(ob,:) = (act_in(ob,:) - mu)*PCA.result.coeff(:,1:PCA.param.dim_recon); % *ones(1,data.num_trial)
end

% Compare matlab and shuting's scores
figure('WindowState','maximized', 'color','w')
sp(1) = subplot(2,1,1);
imagesc(PCA.result.score(:,1:PCA.param.dim_recon)'); hold on;
%line([1,size(PCA.result.score,1)], PCA.param.dim_recon*[1,1]+0.5, 'color',[0,0,0,0.5])
%line([1,size(PCA.result.score,1)], PCA.result.dim_cutoff*[1,1]+0.5, 'color',[1,0,0,0.5])
set(gca,'FontSize',FS)
clim(prctile(PCA.result.score(:), lim_pct))
colormap(gca, 'bluewhitered');
CB(3) = colorbar(); CB(3).Label.String = "PCA score"; CB(3).Label.FontSize = FS;
title('Principal Component Scores')
ylabel('PC')
xlabel('Concatenated frame')

sp(2) = subplot(2,1,2);
imagesc(sc'); hold on;
set(gca,'FontSize',FS)
clim(prctile(sc(:), lim_pct))
colormap(gca, 'bluewhitered');
ylabel('ROI')
xlabel('Concatenated frame')
linkaxes(sp,'xy')
%imagesc(abs(PCA.result.score(:,1:PCA.param.dim_recon) - sc)')

%}



%{
%https://www.mathworks.com/help/stats/quality-of-life-in-u-s-cities.html
close all;
figure
plot(PCA.result.score(:,1),PCA.result.score(:,2),'+')
xlabel('1st Principal Component')
ylabel('2nd Principal Component')
pause;
%gname
%}
%{
figure
pareto(explained)
xlabel('Principal Component')
ylabel('Variance Explained (%)')
%}
