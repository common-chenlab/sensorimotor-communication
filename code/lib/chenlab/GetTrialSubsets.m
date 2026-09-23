function [trial_subsets, n_subset, trials_subtype_ind] = GetTrialSubsets(trials, set_fields, set_field_order)
% Divide the set of trials on the basis of the criteria (fields) provided
n_trials = numel(trials); 
trials_subtype_ind = nan(n_trials,1);
if nargin < 2 || isempty(set_fields)
    % If no subsets are provided, make one big subset of all trials
    trial_subsets = struct('name','All_trials', 'ind',1:n_trials, 'n_trial',n_trials, ...
        'legend', sprintf('All (n=%i trials)', n_trials)); 
    n_subset = 1;
    trials_subtype_ind = ones(n_trials,1);
    return;
end

n_set = numel(set_fields);
if nargin < 3, set_field_order = ''; end
if ischar(set_fields), set_fields = {set_fields}; end % char -> cell
subset_template = struct('name','', 'ind',[], 'n_trial',NaN, 'legend','');

set_vals = cell(1,n_set); set_ind = cell(1,n_set);
for s = 1:n_set 
    if isnumeric(trials(1).(set_fields{s}))
        [set_vals{s}, ~, set_ind{s}] = unique([trials.(set_fields{s})], 'stable'); % 
        set_vals{s} = string(set_vals{s}); % convert to string   num2str(subset_vals{s});
    elseif ischar(trials(1).(set_fields{s}))
        [set_vals{s}, ~, set_ind{s}] = unique({trials.(set_fields{s})}, 'stable'); % 
    else
        error('Fields must contain character or numeric data!')
    end
end

[unique_rows, ~, trial_subset_code] = unique(cat(2, set_ind{:}), 'stable','rows'); % 
n_subset = size(unique_rows,1);
trial_subsets = repmat( subset_template, 1, n_subset );
for b = 1:n_subset
    temp_name = cell(1,n_set);
    for s = 1:n_set
        temp_name{s} = set_vals{s}{unique_rows(b,s)};
    end
    trial_subsets(b).name = strjoin(temp_name, '_');
    trial_subsets(b).ind = find(trial_subset_code == b)';
    trial_subsets(b).n_trial = numel(trial_subsets(b).ind);
    trial_subsets(b).legend = sprintf('%s (n=%i trials)', trial_subsets(b).name, trial_subsets(b).n_trial);
end

% Reorder subsets according to set_order_field, otherwise sort from most to least common
if ~isempty(set_field_order)
    [~,~,temp_order] = intersect(set_field_order, {trial_subsets.name}, 'stable'); 
    temp_order = [temp_order; setdiff(1:n_subset, temp_order)]'; % in case the field order given doesn't cover all subsets
else
    [~,temp_order] = sort([trial_subsets.n_trial], 'descend');
end
trial_subsets = trial_subsets(temp_order);
%{trial_subsets.name}

% Create a trial subtype index vector
for b = 1:n_subset
    trials_subtype_ind(trial_subsets(b).ind) = b;
end
%sum(trials_subtype_ind == 4)
end