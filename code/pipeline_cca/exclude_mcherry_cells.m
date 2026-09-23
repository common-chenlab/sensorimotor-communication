function [act_out, CCA_params] = exclude_mcherry_cells(act_in, fov, CCA_params)
% if CCA_params.exlude is set to mcherry_pos, excludes activity from ALL mCherry+ cells. 
% if CCA_params.exlude is set to mcherry_neg, excludes activity from AS MANY (randomly selected) mCherry- cells as there are positive in the same area. 
% Otherwise, does not exclude anything.
% CCA_params.ROI_exclude keeps track of which ROIs were excluded from each area
act_out = act_in;
if ~strcmpi(CCA_params.exclude, 'none')
    n_mch = cellfun(@numel, {fov.roi_mch});
    for a = 3:4 % only 3,4 have mCherry positive cells
        if strcmpi(CCA_params.exclude, 'mcherry_pos')
            fprintf('\nExcluding all mCherry+ cells.')
            CCA_params.ROI_exclude{a} = fov(a).roi_mch;  % exclude mcherry positive cells
        elseif strcmpi(CCA_params.exclude, 'mcherry_neg')
            fprintf('\nExcluding some mCherry- cells.')
            roi_mch_neg = setdiff(1:fov(a).n_ROI, fov(a).roi_mch);
            CCA_params.ROI_exclude{a} = randsample(roi_mch_neg, min(numel(roi_mch_neg), n_mch(a))); % or, exclude  nonmcherry positive cells
        end
        act_out{a}(:,CCA_params.ROI_exclude{a},:) = [];
    end
end
end