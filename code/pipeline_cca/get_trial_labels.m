function [CCA_params, decis_labels] = get_trial_labels(trials, CCA_params)
% figure out trial subtype labels to use for residualization in act_align

% First, get decision labels and subsets
[decis_subsets, ~, decis_labels] = GetTrialSubsets(trials.all, "decision", ["Hit","CR","Miss","FA"]); % for performing decision-level CCA

% modify decis_labels to pool correct (hit, CR) and incorrect (miss, FA) trials
correct_labels = decis_labels; correct_labels(correct_labels == 2) = 1; 
correct_labels(correct_labels > 2) = 2; 

% Which trials had licking?
lick_labels = decis_labels; 
lick_labels(lick_labels==4) = 1; % lick: Hit/FA = 1
lick_labels(lick_labels>1) = -1; % no lick: CR/Miss = -1

% Get trial labels based on all stimulus parameters (texture, direction1 and direction2) 
stim_order = ["CW_CW_200", "CCW_CW_200", "CW_CCW_200", "CCW_CCW_200",...
    "CW_CW_800", "CCW_CW_800", "CW_CCW_800", "CCW_CCW_800",...
    "CW_CW_1400", "CCW_CW_1400", "CW_CCW_1400", "CCW_CCW_1400"]; % order by texture, then second dir, then first dir
[stim_subsets, ~, stim_labels] = GetTrialSubsets(trials.all, ["direction_1_dir"], stim_order);
[dir1_subsets, ~, dir1_labels] = GetTrialSubsets(trials.all, "direction_1_dir", ["CW","CCW"]);

% determine which labels to use for calculating residuals (label names should match the order of labels)
if strcmpi(CCA_params.resid_type, 'stim') 
    CCA_params.resid_labels = stim_labels; %
    CCA_params.resid_label_names = string({stim_subsets.name});
elseif strcmpi(CCA_params.resid_type, 'lick')
    CCA_params.resid_labels = lick_labels;
    CCA_params.resid_label_names = ["No lick","Lick"];
%elseif strcmpi(CCA_params.resid_type, 'stim_lick')
    %CCA_params.resid_labels = lick_labels.*stim_labels;
    %CCA_params.resid_label_names = ["Lick","No lick"];
elseif strcmpi(CCA_params.resid_type, 'decis')
    CCA_params.resid_labels = decis_labels;
    CCA_params.resid_label_names = string({decis_subsets.name});
elseif strcmpi(CCA_params.resid_type, 'correct')
    CCA_params.resid_labels = correct_labels;
    CCA_params.resid_label_names = ["Correct","Incorrect"];
elseif strcmpi(CCA_params.resid_type, 'all')
    CCA_params.resid_labels = ones(size(stim_labels));
    CCA_params.resid_label_names = "All trials";
elseif strcmpi(CCA_params.resid_type, 'direction_decision')
    [dd_subsets, ~, CCA_params.resid_labels] = GetTrialSubsets(trials.all, ["direction_1_dir","direction_2_dir","decision"]);
    CCA_params.resid_label_names = string({dd_subsets.name});
elseif strcmpi(CCA_params.resid_type, 'split')  % subtract direction1 trial avgs for all frames before split_frame, and decision averages after
    if ~isfield(CCA_params, 'split_frame'),  CCA_params.split_frame = 215;  end % frame at which to split residualization
    CCA_params.resid_label_names = {string({dir1_subsets.name}), string({decis_subsets.name})};
    CCA_params.resid_labels = [dir1_labels, decis_labels];
elseif strcmpi(CCA_params.resid_type, 'none')
    CCA_params.resid_labels = [];
    CCA_params.resid_label_names = [];
end

% figure out which trials correspond to which decisions, notwithstanding any trial exclusions from align_activity
if strcmpi(CCA_params.decis_type, "correct")
    decis_labels = correct_labels;
elseif strcmpi(CCA_params.decis_type, "none")
    decis_labels = [];
end

end