function [whisk, n_whisk, tr_whisk_missing] = get_whisk(whisker_path, trials)
whisk = [];
n_whisk = NaN;
tr_whisk_missing = [];
if exist(whisker_path, 'file')
    fprintf('\nLoading %s\n', whisker_path);
    load(whisker_path, 'whisker_dat');
    n_whisk = numel(whisker_dat);
    if numel(whisker_dat) ~= trials.n_all
        if iscell(trials.summary.table.CCD_idx)
            tr_whisk_missing = [trials.summary.table.Trial(find(cellfun(@isempty, trials.summary.table.CCD_idx)))', setdiff(1:trials.n_all, trials.summary.table.Trial)]; % setdiff(1:trials.n_all, trials.summary.table.CCD_idx)
        elseif isnumeric(trials.summary.table.CCD_idx)
            tr_whisk_missing = [trials.summary.table.Trial(find(isempty(trials.summary.table.CCD_idx))), setdiff(1:trials.n_all, trials.summary.table.Trial)];
        end
        if ~isempty(tr_whisk_missing), fprintf('Missing whisking data for %i trials', numel(tr_whisk_missing)); end
        whisk = repmat(struct('filename','', 'timestamp','', 'mean_angle',[], 'mean_curve',[], 'touch_vector',[], 'object_vector',[]), 1, trials.n_all );
        tr_whisk_include = setdiff(1:trials.n_all, tr_whisk_missing);
        if numel(whisker_dat) > numel(tr_whisk_include)
            i = 1;
            while i <= numel(whisker_dat)
                if ~any(matches(trials.summary.table.CCD_Name, whisker_dat(i).filename))
                    whisker_dat(i) = [];
                else
                    i = i + 1;
                end
            end
        end
        whisk(tr_whisk_include) = whisker_dat;
    else
        whisk = whisker_dat;
    end
end