function [all, stim, choice, trialno] = sample_choice(anm, session)


% anm = 'sm041'
% session = 1

load([[smroot() 'Animals/'] anm '\' anm '-' num2str(session) '.mat'],'summary','trials','licks');


all = [];
stim = [];
choice = [];
trialno = [];


for j = 2:size(summary.table,1)
    trial_id = summary.table{j,1};
    try
        smp = round(50*trials(trial_id).delay_time/1000);
        lick = licks(trial_id).lick_vector(1,:);
        all = [all; nanmean(lick(smp:smp+100))];
        if findstr('CW', trials(trial_id).direction_1) == 1
            if findstr('CW', trials(trial_id).direction_2) == 1
                stim = [stim; 1];
            else
                stim = [stim; 2];
            end
        else
            if findstr('CW', trials(trial_id).direction_2) == 1
                stim = [stim; 3];
            else
                stim = [stim; 4];
            end
        end
        if findstr('Hit', trials(trial_id).decision) > 0
            choice = [choice; 1];
        elseif findstr('Miss', trials(trial_id).decision) > 0
            choice = [choice; 2];
        elseif findstr('CR', trials(trial_id).decision) > 0
            choice = [choice; 3];
        elseif findstr('FA', trials(trial_id).decision) > 0
            choice = [choice; 4];
        end
        trialno = [trialno; trial_id];
    catch
    end
end




