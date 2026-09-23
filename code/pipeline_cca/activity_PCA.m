function [act_PCA, PCA, trial_frames, CCA_params] = activity_PCA(act, fov, CCA_params)
% performs PCA of the input data
% INPUTS
% act = raw activity data for each ROI. dimensions should be frames x ROI x trials
% CCA_params = structure setting all parameters for analysis. here only gauss_filt, n_PC and PCA_params are relevant
% OUTPUTS
% act_PCA = activity projected into PCA space, possibly after suppressing some cells' coefficients
% PCA = strucutre array containing PCA results for each area. NOTE: PCA variable is unaffected by suppression
% trial_frames = frames associated with each trial, to deconcatenate PCA results
% CCA_params, now containing indicies of suppressed ROIs

n_fov = size(fov,2);
n_trial = size(act{1},3); 

act_PCA = cell(1,n_fov);  trial_frames = cell(1, n_trial);  %PCA = [];
if CCA_params.n_PC > 0
    % for deconcatenation, figure out which frames belong to which trials. trial frames are the same for all areas due to resampling
    n_frame_trial = cellfun(@height, act);
    for tr = 1:n_trial
        trial_frames{1,tr} = n_frame_trial(1)*(tr-1)+1:n_frame_trial(1)*tr;
    end

    for a = flip(1:n_fov)
        act_cat = reshape(permute(act{a}, [1,3,2]), prod(size(act{a},[1,3])), size(act{a},2) ); % concatenate all trials for each ROI
        %{
        % make sure concatenation was done correctly
        figure;
        subplot(2,1,1)
        plot(act{a}(:,1,2)); % roi 1, trial 2
        subplot(2,1,2)
        plot(act_cat(321:640, 1) ); % roi 1, trial 2
        %}

        % Perform PCA on the concatenated data
        PCA(a) = run_PCA_SM(act_cat, CCA_params.PCA_params, 'show',false); %#ok<AGROW> %  'name',fov_name{a}
        %, 'save',ChenLabFilepath('Z:\Dropbox\Chen Lab Dropbox\Chen Lab Team Folder\Projects\Sensorimotor\Figures\PCA_SM_std.pdf')

        % recalculate PCA scores after suppressing mCh coefficients (or an equal number of randomly selected cells)
        if a > 2 && ~strcmpi(CCA_params.suppress_mch, 'none')
            % determine which coefficients to zero
            if strcmpi(CCA_params.suppress_mch, 'mch')
                fprintf('\nSuppressing all %i mCh coefficients', numel(fov(a).roi_mch))
                CCA_params.roi_suppress{a} = fov(a).roi_mch;
            elseif strcmpi(CCA_params.suppress_mch, 'ctrl') || strcmpi(CCA_params.suppress_mch, 'control')
                roi_non_mch = setdiff(1:fov(a).n_ROI, fov(a).roi_mch);
                n_suppress = min(numel(fov(a).roi_mch), numel(roi_non_mch));
                fprintf('\nSuppressing %i random non-mCh coefficients', n_suppress)
                CCA_params.roi_suppress{a} = sort( randsample(roi_non_mch, n_suppress) );
            elseif strcmpi(CCA_params.suppress_mch, 'non') || strcmpi(CCA_params.suppress_mch, 'noncherry')
                roi_non_mch = setdiff(1:fov(a).n_ROI, fov(a).roi_mch);
                n_suppress = numel(roi_non_mch);
                fprintf('\nSuppressing all %i non-mCh coefficients', n_suppress)
                CCA_params.roi_suppress{a} = roi_non_mch;
            else
                error('CCA_params.suppress_mch has invalid setting')
            end
            PCA_coeff = PCA(a).result.coeff; % imshow(PCA_coeff, [])
            PCA_coeff(CCA_params.roi_suppress{a},:) = 0;
            
            % calculate score using the modified loadings
            if CCA_params.PCA_params.standardize
                act_cat = normalize(act_cat);
            end
            score = act_cat*PCA_coeff;

            %{
            figure;
            plot(PCA(a).result.score(:,1)); hold on;
            plot(score(:,1));
            %}
        else
            score = PCA(a).result.score;
        end

        % De-concatenate the PCA data to preserve trial-specificity
        act_PCA{a} = nan(size(act{a}));
        for tr = 1:n_trial
            act_PCA{a}(:,:,tr) = score(trial_frames{1,tr},:); % 1:PCA(a).param.dim_max PCA(a).param.dim_recon
        end
    end
else
    fprintf('CCA_params.n_PC is not greater than 0. Skipping activity_PCA!')
end
end