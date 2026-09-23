function trial_events = get_trial_event_frames(image_time, trialInfo, trial_events, offset, denoise_loss, show)
% Finds the first imaging frame, relative to trial_time where the events specified in trial_events first occurred, 
%   and appends it to the relevant structure element in trial_events (replacement for generateEventVector)
% trial_time: Timing (ms) of each sample from imaging start (imaged sampling rate)
% trialInfo: Struct for trial of interest with time stamps for events
% trial_events: structure containing names, descriptions, and numerical coding of relevant trial events. 
% offset: Timing difference between imaging start and trial start
if nargin < 5, show = false; end
if trialInfo.auto_reward == 1 && strcmp(trialInfo.decision,'Miss')
    trialInfo.reward_time = trialInfo.decision_time;
end
trial_time = image_time + offset;
begin_ind = trial_events(strcmpi({trial_events.type}, 'begin')).code;
trial_events(begin_ind).timestamp = denoise_loss+offset;
trial_events(begin_ind).first_frame = 1; % begin = first frame

for ev = setdiff(1:length(trial_events), begin_ind)
    trial_events(ev).first_frame = NaN;
    if isfield(trialInfo, trial_events(ev).type) && ~isnan(trialInfo.(trial_events(ev).type))
        trial_events(ev).timestamp = trialInfo.(trial_events(ev).type); 
        trial_events(ev).first_frame = find(trial_time < trial_events(ev).timestamp, 1, 'last');
    %else
    %    fprintf('\nDid not find %s in trial info', trial_events(ev).type)
    end
end
%[trial_events.first_frame]

if show
    y_lim = [-0.2,0.2];
    y_offset = 0.1;
    close all;
    figure;
    subplot(2,1,1)
    line([0, trialInfo.end_time], [0,0], 'color','k'); hold on;
    ylim(y_lim);

    line(offset*[1,1], y_lim, 'color','k','linestyle','--')
    text(offset, y_offset, 'Offset','HorizontalAlignment','right')
    line((denoise_loss+offset)*[1,1], y_lim, 'color','k','linestyle','-.')
    line((trialInfo.end_time-denoise_loss)*[1,1], y_lim, 'color','k','linestyle','-.')
    %line(trialInfo.end_time*[1,1], y_lim, 'color','k','linestyle','--')

    plot(trialInfo.present_time, 0, '.', 'MarkerSize',10) % rotator starts to enter
    line(trialInfo.present_time*[1,1], [0,y_offset])
    text(trialInfo.present_time, y_offset, 'present_time', 'Interpreter','none' ,'HorizontalAlignment','center')
    
    plot(trialInfo.direction_1_time, 0, '.', 'MarkerSize',10) % starts to turn
    line(trialInfo.direction_1_time*[1,1], [0,-y_offset])
    text(trialInfo.direction_1_time, -y_offset, 'direction_1_time', 'Interpreter','none' ,'HorizontalAlignment','center')
    
    plot(trialInfo.delay_withdraw_time, 0, '.', 'MarkerSize',10) % starts to leave
    line(trialInfo.delay_withdraw_time*[1,1], [0,y_offset])
    text(trialInfo.delay_withdraw_time, y_offset, 'delay_withdraw_time', 'Interpreter','none' ,'HorizontalAlignment','center')
    
    plot(trialInfo.delay_present_time, 0, '.', 'MarkerSize',10) % rotator starts to return
    line(trialInfo.delay_present_time*[1,1], [0,-y_offset])
    text(trialInfo.delay_present_time, -y_offset, 'delay_present_time', 'Interpreter','none' ,'HorizontalAlignment','center')

    plot(trialInfo.direction_2_time, 0, '.', 'MarkerSize',10) % % starts to turn again
    line(trialInfo.direction_2_time*[1,1], [0,y_offset])
    text(trialInfo.direction_2_time, y_offset, 'direction_2_time', 'Interpreter','none' ,'HorizontalAlignment','center')

    plot(trialInfo.report_time, 0, '.', 'MarkerSize',10) % 
    line(trialInfo.report_time*[1,1], [0,-y_offset])
    text(trialInfo.report_time, -y_offset, 'report_time', 'Interpreter','none' ,'HorizontalAlignment','center')

    plot(trialInfo.withdraw_time, 0, '.', 'MarkerSize',10)
    line(trialInfo.withdraw_time*[1,1], [0,y_offset])
    text(trialInfo.withdraw_time, y_offset, 'withdraw_time', 'Interpreter','none' ,'HorizontalAlignment','center')

    plot(trialInfo.end_time, 0, '.', 'MarkerSize',10)
    line(trialInfo.end_time*[1,1], [0,-y_offset])
    text(trialInfo.end_time, -y_offset, 'end_time', 'Interpreter','none' ,'HorizontalAlignment','center')

    title(sprintf('Trial timeline (Decision type: %s)', trialInfo.decision))
    xlabel('Trial time (ms)')

    subplot(2,1,2);
    line([0, trialInfo.end_time], [0,0], 'color','k'); % trial_time(end)
    hold on; %
    xlabel('Trial time (ms)')
    title('Imaging timeline')
    ylim([-0.2,0.2]);
    for ev = 1:numel(trial_events)
        y_temp = -y_offset*(-1)^(mod(ev,2)+1); % alternate above/below line
        if ~isnan(trial_events(ev).first_frame)
            plot(trial_time(trial_events(ev).first_frame), 0, '.', 'MarkerSize',10); % +offset
            line((trial_time(trial_events(ev).first_frame))*[1,1], [0,y_temp]) % +offset
            text(trial_time(trial_events(ev).first_frame), y_temp, trial_events(ev).type, 'Interpreter','none' ,'HorizontalAlignment','center') %+offset
        else
            warning('%s is missing', trial_events(ev).type)
        end
    end
end
end