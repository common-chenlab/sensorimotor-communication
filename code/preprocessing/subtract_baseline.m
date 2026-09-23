function [trace_out, noise_var] = subtract_baseline(trace_in, params, context, show)
% context (optional): a trace, or cell array of trace segments, used to
%   ESTIMATE the baseline and noise for the DISCRETE-trial case. It is meant
%   to be the current trial pooled with its neighbouring trials (built in
%   deconvolve_traces). Estimating baseline/noise from several adjacent,
%   randomly-interleaved trials -- instead of from the current trial alone --
%   stops a single high-activity trial from setting its own condition-specific
%   baseline & noise. Previously each trial's baseline was prctile(trace,X)
%   and noise was std(diff(trace)) of that one trial, so a trial with a large
%   response (e.g. a cell driven at both sample and test) raised its own floor
%   and noise and thereby subtracted/normalised its WHOLE trace downward -- an
%   "iceberg" artifact that suppressed other epochs (e.g. the sample window).
%   NB: the old `movmean(baseline,50)` here was a no-op (baseline is a scalar
%   in the per-trial call), so no cross-trial smoothing ever actually happened.
%   If context is omitted, behaviour reverts to the legacy per-trial estimate.
if nargin < 4, show = false; end
if nargin < 3 || isempty(context), context = trace_in; end

% Process the fluor trace
if params.concatenate
    % continuous data (unchanged) - moving baseline across a sliding window
    baseline = movmean(trace_in, params.base_frames); % moving baseline across sliding window
    trace_out = trace_in - baseline;  % subtracts baseline
    trace_out = trace_out - prctile(trace_out, params.base_thresh);
    % estimate noise variance from the baseline-subtracted trace
    noise_var = median(std(diff(trace_out), 'omitnan'));
else
    % discrete trials - estimate baseline & noise from the POOLED context
    % (current trial + neighbours), then subtract from the current trial only.
    if iscell(context), ctx = cat(2, context{:}); else, ctx = context; end
    baseline = prctile(ctx, params.base_thresh); % pooled Xth-percentile baseline
    trace_out = trace_in - baseline; % subtract pooled baseline from current trial
    % noise estimated from the pooled context (not just this trial)
    noise_var = median(std(diff(ctx), 'omitnan'), 'omitnan');
end

% Make a plot illustrating the subtraction (optional)
if show
    framerate = params.min_frame/params.min_dur;
    t_trace = [0:length(trace_out)-1]/framerate;
    trace_out_mean = mean(trace_out);

    figure;
    sp(1) = subplot(2,1,1);
    plot(t_trace, trace_in); hold on;
    plot(t_trace, baseline, 'linewidth',1.5)
    if params.concatenate
        title( {'Original trace and baseline', sprintf('window = %2.1f seconds, thresh pct = %2.2f', params.base_window, params.base_thresh)} )
    else
        title( {'Original trace and baseline', sprintf('thresh pct = %2.1f, moving mean of 50 trials', params.base_thresh)} )
    end

    sp(2) = subplot(2,1,2);
    plot(t_trace, trace_out); hold on;
    line(t_trace([1,end]), (trace_out_mean + noise_var)*[1,1], 'color','k', 'linestyle','--', 'linewidth',1.5)
    line(t_trace([1,end]), (trace_out_mean - noise_var)*[1,1], 'color','k', 'linestyle','--', 'linewidth',1.5)
    title( sprintf('Subtracted trace (std dev = %2.2f)', noise_var), 'Interpreter','none' )
    xlabel('Time (s)')
    linkaxes(sp,'x')
    xlim([0,180]) %xlim([-Inf,Inf])
end

end