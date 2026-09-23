function results = SummarizeCCA(results, params)
%tic
%fprintf('\nCalculating summary stats...')
% Determine # of significant dimensions based on thresholding
results.r_thresh = mean(results.r_shf(:,:,1,:), 4, 'omitnan') + 3*std(results.r_shf(:,:,1,:), 0, 4, 'omitnan');
sig_r = mean(results.r_cv, 4, 'omitnan') > results.r_thresh;
results.dim_sig = zeros(params.n_step, params.n_delay);
for tp = 1:params.n_step
    for dl = 1:params.n_delay
        dim_temp = find(squeeze(sig_r(tp,dl,:)) == 1, 1, 'last');
        if ~isempty(dim_temp), results.dim_sig(tp,dl) = dim_temp; end
    end
end

% Calculate mean corr at zero delay
results.r_map = mean(results.r_cv, 4, 'omitnan');
results.r_map_shf = prctile(results.r_shf, 95, 4); %mean(results.r_shf, 4, 'omitnan');
results.r_zero = squeeze(results.r_map(:,params.dl_zero,:));
results.r_zero_shf = squeeze(results.r_map_shf(:,params.dl_zero,:));

% Calculate information flow indices (IFI) -note this method was found to have issues when denominator was close to zero. 
% see Z:\Dropbox\Chen Lab Dropbox\Chen Lab Team Folder\Projects\Sensorimotor\Scripts\full_trial_IFI.m  instead
% {
dl_pre = 1:params.dl_zero-1;
dl_post = params.dl_zero+1:params.n_delay;
if ~isempty(dl_pre) && ~isempty(dl_post)
    % Data (not accounting for trial subtypes)
    bup = permute(mean( results.r_cv(:,dl_pre,:,:), [2,4]), [1,3,2]); % , 'omitnan'
    tdown = permute(mean( results.r_cv(:,dl_post,:,:), [2,4]), [1,3,2]); % , 'omitnan'
    results.IFI = (bup-tdown)./(bup+tdown);
    % Shuffles (not accounting for trial subtypes)
    bup_shf = squeeze(mean( results.r_shf(:,dl_pre,:,:), [2,4])); % , 'omitnan'
    tdown_shf = squeeze(mean( results.r_shf(:,dl_post,:,:), [2,4])); % , 'omitnan'
    results.IFI_shf = (bup_shf-tdown_shf)./(bup_shf+tdown_shf);
    % accounting for trials and trial subtypes
    %{
    for tr = 1:n_trial
        bup_tr = permute(mean(results.r_trial(:,dl_pre,:,tr), 2), [1,3,2]); % , 'omitnan'
        tdown_tr = permute(mean(results.r_trial(:,dl_post,:,tr), 2), [1,3,2]); % , 'omitnan'
        results.IFI_trial(:,:,tr) = (bup_tr-tdown_tr)./(bup_tr+tdown_tr);
    end
    if ~isempty(params.decis_labels)
        tdown_sub = permute(mean(results.r_decis(:,dl_post,:,:), 2), [1,3,4,2]); % , 'omitnan'
        bup_sub = permute(mean(results.r_decis(:,dl_pre,:,:), 2), [1,3,4,2]); % , 'omitnan'
        results.IFI_sub = (bup_sub-tdown_sub)./(bup_sub+tdown_sub);
    end
    %}
end
%}

% Calculate subspace angles between each combination of steps/delays, for A and B (slow for large # of steps/delays)
%[~,step_max] = max( squeeze(results.r_full(:,params.dl_zero,1)) ); % identify the window of maximum correlation
%w = waitbar(0, sprintf('Calculating subspace angles'));
%{
for tpX = 1:params.n_step
    for tpY = 1:params.n_step
        for dlX = 1:params.n_delay
            for dlY = 1:params.n_delay
                %results.subspace_angle = subspacea(subspace_ref, results.A(:, params.dim_angle, tp, params.dl_zero) );
                try
                    results.A_angles(tpX, tpY, dlX, dlY,:) = subspacea( results.A(:, params.dim_angle, tpX, dlX), ...
                        results.A(:, params.dim_angle, tpY, dlY) ); % sum()
                    results.B_angles(tpX, tpY, dlX, dlY,:) = subspacea( results.B(:, params.dim_angle, tpX, dlX), ...
                        results.B(:, params.dim_angle, tpY, dlY) );
                catch
                end
            end
        end
    end
    %waitbar(tpX/params.n_step, w); % toc
end
%}
%if exist('w','var'), close(w); end
%toc

% Plot the results (optional)
fprintf('\n')
if params.show
    show_CCA_results(results, params); % 
end

end