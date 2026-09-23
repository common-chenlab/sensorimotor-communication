function [act_resid, act_align, t_align, shift_frame, tr_exclude, params, act_mean] = align_activity(act, trials, params, show)
if nargin < 4, show = false; end
% Align activity from individual trials to a specific event within each trial
% act dimensions: frames x ROI x trials

% OUTPUTS
% act_resid = residualized, aligned activity (either deconvolved activity, or PCA scores thereof). residualization style is set in params
% act_align = activity for each trial, aligned to specific event(s) during the trial  

shift_max = 10;
n_fov = numel(act);
n_frame = cellfun(@height, act);
% Determine event names from trial struct
event_names = []; tr = 0;
while isempty(event_names)
    tr = tr+1;
    if ~isempty(trials.all(tr).events{1})
        event_names = {trials.all(tr).events{1}.type};
    end
end
if isempty(event_names), error('Unable to determine event names'); end
[~,ev_align] = intersect(event_names, params.align_event); %find(strcmpi({trials.all(1).events{1}.type}, CCA_params.align_event));
n_align = numel(ev_align);
% setup residualization
if size(params.resid_labels,2) == 1
    n_resid = numel(params.resid_label_names); %numel(resid_unq);
else
    n_label_names = cellfun(@numel, params.resid_label_names);
    n_label_max = max(n_label_names);
    n_resid = 1; %prod(n_label_names);
end

align_frame = nan(n_align,n_fov); % the modal event onset frame
act_align = cell(n_align,n_fov); act_resid = cell(n_align,n_fov); act_mean = cell(n_align, n_fov, n_resid);
t_align = cell(n_align,n_fov);  t_act = cell(1,n_fov); % timing, in frames, relative to align_frame
event_frame = nan(trials.n_all, n_fov, n_align); shift_frame = nan(trials.n_all, n_fov, n_align);
params.resid_tr = cell(n_align, n_resid);

%Find trials without data
tr_missing = cellfun(@(x)(find(all(isnan(x), [1,2]))), act, 'UniformOutput', false);
tr_missing = unique(vertcat(tr_missing{:}));
tr_exclude = cell(n_align,1);
if ~isempty(ev_align)
    for ev = 1:n_align %ev_align'
        %fprintf('%s', CCA_params.align_event{})
        for a = 1:n_fov
            % Get event timing for each trial for this FOV
            for tr = setdiff(1:trials.n_all, tr_missing)
                try
                    event_frame(tr,a,ev) = trials.all(tr).events{1}(ev_align(ev)).resamp_frame;
                catch
                    fprintf('\nMissing event info: tr = %i\n', tr)
                end
            end

            align_frame(ev,a) = mode(event_frame(:,a,ev));
            shift_frame(:,a,ev) = event_frame(:,a,ev) - align_frame(ev,a);
            % Keep track of trials that are missing or where shift was excessive, and trim NaN frames
            tr_bad_shift = find(any(isnan(shift_frame(:,a,ev)),2) | any(abs(shift_frame(:,a,ev)) > shift_max,2));
            tr_exclude{ev} = unique([tr_missing(:); tr_bad_shift(:)]);
            
            % Perform the alignment for each trial (even bad ones)
            act_align{ev,a} = act{a};
            for tr = find(shift_frame(:,a,ev) ~= 0 & ~isnan(shift_frame(:,a,ev)))' % & abs(shift_frame(:,a,ev)) <= shift_max %~isnan(shift_frame(:,a,ev)))'
                act_align{ev,a}(:,:,tr) = circshift(act{a}(:,:,tr), -shift_frame(tr,a,ev), 1);
                if shift_frame(tr,a,ev) < 0
                    act_align{ev,a}(1:abs(shift_frame(tr,a,ev)),:,tr) = NaN;
                elseif shift_frame(tr,a,ev) > 0
                    act_align{ev,a}(end-abs(shift_frame(tr,a,ev))+1:end,:,tr) = NaN;
                end
                %{
                if show
                    figure;
                    sp(1) = subplot(2,1,1);
                    imagesc(act{a}(:,:,tr)')
                    sp(2) = subplot(2,1,2);
                    imagesc(act_align{ev,a}(:,:,tr)')
                    linkaxes(sp, 'xy')
                    impixelinfo
                    pause;
                end
                %}
            end
        end

        for a = 1:n_fov
            t_align{ev,a} = (1:n_frame(a))' - align_frame(ev,a);
            t_act{a} = (1:n_frame(a))' - align_frame(ev,a);
            %act_align{ev,a}(:,:,tr_exclude{ev}) = [];  % exclude bad trials

            % Keep only a segment of the peri-event time (optional)
            if ~isempty(params.align_keep_lim) && all(isfinite(params.align_keep_lim))
                keep_ind = align_frame(ev,a) - params.align_keep_lim(1):align_frame(ev,a) + params.align_keep_lim(2);
                keep_ind = keep_ind(keep_ind > 0 & keep_ind < n_frame(a));
                act_align{ev,a} = act_align{ev,a}(keep_ind,:,:); % act_keep
                t_align{ev,a} = t_align{ev,a}(keep_ind); %keep_ind - align_frame(ev,a); %t_keep{a}
            end

            % Trim NaNs?
            if params.trim_NaN
                trim_frame = find( any( isnan(act_align{ev,a}(:,:,setdiff(1:trials(1).n_all, tr_exclude{ev}))), [2,3]) )'; % note: trim limits do not consider excluded trials
                act_align{ev,a}(trim_frame,:,:) = []; % act_align{ev,a} =
                t_align{ev,a}(trim_frame) = [];
            end

            % Calculate residuals for each individual trial subtype
            % {
            params.n_trial_resid = nan(n_align, n_resid);
            if ~strcmpi(params.resid_type,'none') %~isempty(params.resid_labels) % trial_labels
                act_resid{ev,a} = act_align{ev,a};
                if strcmpi(params.resid_type,'split')
                    % get trial averages for each side of split
                    n_split = size(params.resid_labels, 2);
                    split_lims = [1, params.split_frame, n_frame(a)];
                    % calculate means for each case
                    act_mean_split = cell(n_split, n_label_max);
                    for spl = 1:n_split
                        temp_frames = split_lims(spl):split_lims(spl+1);
                        temp_unq = unique(params.resid_labels(:,spl));
                        for sb = unique(params.resid_labels(:,spl))' % params.align_labels{ev}
                            resid_ind = find(sb==temp_unq);
                            tr_temp = setdiff(find(params.resid_labels(:,spl) == sb)', tr_exclude{ev}); % params.align_labels{ev}
                            n_tr_temp = numel(tr_temp);
                            act_mean_split{spl,sb} = mean(act_align{ev,a}(temp_frames,:,tr_temp), 3, 'omitnan');
                            act_resid{ev,a}(temp_frames,:,tr_temp) = act_align{ev,a}(temp_frames,:,tr_temp) - act_mean_split{spl,sb};
                            %{
                            % Make a plot to illustrate the process
                            TL = 0.005;
                            figure('WindowState','maximized');
                            sp(1) = subplot(3,1,1);
                            imagesc(t_align{ev,a}(temp_frames), [], act_align{ev,a}(temp_frames,:,tr_temp(1))') % , 'omitnan'
                            set(gca,'TickLength',[TL,0])
                            ylabel('PC');
                            title(sprintf('First trial of split phase 1, subtype %i, aligned but unsubtracted',sb))
                            sp(2) = subplot(3,1,2);
                            imagesc(t_align{ev,a}(temp_frames), [], act_mean_split{spl,sb}') % , 'omitnan'
                            set(gca,'TickLength',[TL,0])
                            ylabel('PC');
                            title(sprintf('Aligned trial-subtype mean, n = %i trials',numel(tr_temp)))
                            sp(3) = subplot(3,1,3);
                            imagesc(t_align{ev,a}(temp_frames), [], act_resid{ev,a}(temp_frames,:,tr_temp(1))') % , 'omitnan'
                            set(gca,'TickLength',[TL,0])
                            title('First trial, mean-subtracted residual')
                            ylabel('PC');
                            xlabel('Frames, relative to stimulus onset')
                            sgtitle('Averaged over trials', 'FontSize',20)
                            linkaxes(sp, 'xy')
                            impixelinfo
                            pause
                            close all
                            %}
                        end
                    end
                else
                    resid_unq = unique(params.resid_labels);
                    for sb = unique(params.resid_labels)' % params.align_labels{ev}
                        resid_ind = find(sb==resid_unq);
                        params.resid_tr{ev,sb} = setdiff(find(params.resid_labels == sb)', tr_exclude{ev}); % params.align_labels{ev}
                        params.n_trial_resid(ev,resid_ind) = numel(params.resid_tr{ev,sb});
                        act_mean{ev,a,resid_ind} = mean(act_align{ev,a}(:,:,params.resid_tr{ev,sb}), 3, 'omitnan');
                        act_resid{ev,a}(:,:,params.resid_tr{ev,sb}) = act_align{ev,a}(:,:,params.resid_tr{ev,sb}) - act_mean{ev,a,resid_ind};
                        %{
                        % Make a plot to illustrate the process
                        TL = 0.005;
                        figure('WindowState','maximized');
                        sp(1) = subplot(3,1,1);
                        imagesc(t_align{ev,a}, [], act_align{ev,a}(:,:,params.resid_tr{ev,sb}(1))') % , 'omitnan'
                        set(gca,'TickLength',[TL,0])
                        ylabel('PC');
                        title(sprintf('First trial of subtype %i, aligned but unsubtracted',sb))
                        sp(2) = subplot(3,1,2);
                        imagesc(t_align{ev,a}, [], act_mean{ev,a,resid_ind}') % , 'omitnan'
                        set(gca,'TickLength',[TL,0])
                        ylabel('PC');
                        title(sprintf('Aligned trial-subtype mean, n = %i trials',numel(params.resid_tr{ev,sb})))
                        sp(3) = subplot(3,1,3);
                        imagesc(t_align{ev,a}, [], act_resid{ev,a}(:,:,params.resid_tr{ev,sb}(1))') % , 'omitnan'
                        set(gca,'TickLength',[TL,0])
                        title('First trial, mean-subtracted residual')
                        ylabel('PC');
                        xlabel('Frames, relative to stimulus onset')
                        sgtitle('Averaged over trials', 'FontSize',20)
                        linkaxes(sp, 'xy')
                        impixelinfo
                        pause
                        close all
                        %}
                    end
                end

                %}
                if show
                    TL = 0.005;
                    figure('WindowState','maximized');
                    sp(1) = subplot(3,1,1);
                    imagesc(t_act{a}, [], mean(act{a}(:,:,setdiff(1:trials.n_all, tr_exclude{ev})), 3)') % , 'omitnan'
                    set(gca,'TickLength',[TL,0])
                    ylabel('PC');
                    title('Unaligned')

                    sp(2) = subplot(3,1,2);
                    imagesc(t_align{ev,a}, [], mean(act_align{ev,a}(:,:,setdiff(1:trials.n_all, tr_exclude{ev})),3)') % , 'omitnan'
                    set(gca,'TickLength',[TL,0])
                    ylabel('PC');
                    title('Stimulus-aligned, pre-residualization')

                    sp(3) = subplot(3,1,3);
                    imagesc(t_align{ev,a}, [], mean(act_resid{ev,a}(:,:,setdiff(1:trials.n_all, tr_exclude{ev})), 3)') % , 'omitnan'
                    set(gca,'TickLength',[TL,0])
                    title('Aligned and residualized')
                    ylabel('PC');
                    xlabel('Frames, relative to stimulus onset')
                    sgtitle('Averaged over non-excluded trials', 'FontSize',20)
                    linkaxes(sp, 'xy')
                    impixelinfo
                end
            end
        end
    end
else
    fprintf('\nalign_event not found in the events structure')
end
end