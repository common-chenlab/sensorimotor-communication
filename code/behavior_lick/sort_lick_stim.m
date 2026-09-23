function [timing, AP_Hit, PA_Hit, AA_FA, PP_FA] = sort_lick_stim(anm, session)


load([[smroot() 'Animals/'] anm '\' anm '-' num2str(session) '.mat'],'summary','trials','licks');

Hit_CW_CCW = [];
Hit_CCW_CW = [];
CR_CW_CW = [];
CR_CCW_CCW = [];
AP_Hit = []; 
PA_Hit = [];  
AA_FA = []; 
PP_FA = []; 
CR = [];
FA = [];
Hit = [];
Miss = [];
all = [];
test = [];
choice = [];
stim = [];
speed = [];
d1=[];
d2=[];
delay=[];
delay2=[];
report=[];
reward=[];

min_delay = [];
withdraw = 1;
for i = 1:length(trials)
    min_delay = [min_delay; trials(i).delay];    
    if isnan(trials(i).delay_withdraw_time) 
        withdraw = 0;
    end    
end
min_delay = min(min_delay);

%% calculate min offset
min_offset = [];
for i = 1:length(trials)
    min_offset = [min_offset; trials(i).present_time];
end
if nanmean(min_offset) < 2500
    min_offset = 1;
else
    min_offset = 51;
end


for j = 2:size(summary.table,1)
    
    trial_id = summary.table{j,1};
    d1 = [d1; trials(trial_id).direction_1_time];
    d2 = [d2; trials(trial_id).direction_2_time];
    delay = [delay; trials(trial_id).delay_time];
    report = [report; trials(trial_id).report_time];
    reward = [reward; trials(trial_id).reward_time];
    
    %%
    temp = licks(trial_id).lick_vector(1,:);
    
%     if withdraw == 1
%         d1_end = round((trials(trial_id).delay_withdraw_time+min_delay)/1000*50);
%         d2_time = round(trials(trial_id).delay_present_time/1000*50);
%     else
%         d1_end =  round((trials(trial_id).delay_time+min_delay)/1000*50);
%         d2_time = round(trials(trial_id).direction_2_time/1000*50);
%     end
%     
    d1_end =  round((trials(trial_id).delay_time)/1000*50);
        d2_time = round(trials(trial_id).direction_2_time/1000*50);
    
%     temp = [temp(min_offset:d1_end), temp(d2_time:end)];
    temp = temp(min_offset:end);
    min_frames = 730;
    if length(temp) >= min_frames
        temp = temp(1:min_frames);
        all = [all; temp];
        speed = [speed; trial_id];
        delay2 = [delay2; trials(trial_id).delay];
        if findstr('Hit', trials(trial_id).decision) > 0
            choice = [choice; 1];
            Hit = [Hit; temp];
            if findstr('CW', trials(trial_id).direction_1) == 1
                Hit_CW_CCW = [Hit_CW_CCW; temp];
%                 if isempty(findstr('40', trials(trial_id).direction_1)) == 0
                    stim = [stim; 1];
%                 else
%                     stim = [stim; 5];
%                 end
            end
            if findstr('CCW', trials(trial_id).direction_1) == 1
                Hit_CCW_CW = [Hit_CCW_CW; temp];
%                 if isempty(findstr('40', trials(trial_id).direction_1)) == 0
                    stim = [stim; 3];
%                 else
%                     stim = [stim; 7];
%                 end
            end
        elseif findstr('Miss', trials(trial_id).decision) > 0
            Miss = [Miss; temp];
            choice = [choice; 2];
            if findstr('CW', trials(trial_id).direction_1) == 1
                Hit_CW_CCW = [Hit_CW_CCW; temp];
%                 if isempty(findstr('40', trials(trial_id).direction_1)) == 0
                    stim = [stim; 1];
%                 else
%                     stim = [stim; 5];
%                 end
            end
            if findstr('CCW', trials(trial_id).direction_1) == 1
                Hit_CCW_CW = [Hit_CCW_CW; temp];
%                 if isempty(findstr('40', trials(trial_id).direction_1)) == 0
                    stim = [stim; 3];
%                 else
%                     stim = [stim; 7];
%                 end
            end            
        elseif findstr('CR', trials(trial_id).decision) > 0
            CR = [CR; temp];
            choice = [choice; 3];
            if findstr('CW', trials(trial_id).direction_1) == 1
                CR_CW_CW = [CR_CW_CW; temp];
%                 if isempty(findstr('40', trials(trial_id).direction_1)) == 0
                    stim = [stim; 4];
%                 else
%                     stim = [stim; 8];
%                 end
            end
            if findstr('CCW', trials(trial_id).direction_1) == 1
                CR_CCW_CCW = [CR_CCW_CCW; temp];
%                 if isempty(findstr('40', trials(trial_id).direction_1)) == 0
                    stim = [stim; 2];
%                 else
%                     stim = [stim; 6];
%                 end
            end
        elseif findstr('FA', trials(trial_id).decision) > 0
            FA = [FA; temp];
            choice = [choice; 4];
            if findstr('CW', trials(trial_id).direction_1) == 1
                CR_CW_CW = [CR_CW_CW; temp];
%                 if isempty(findstr('40', trials(trial_id).direction_1)) == 0
                    stim = [stim; 2];
%                 else
%                     stim = [stim; 6];
%                 end
            end
            if findstr('CCW', trials(trial_id).direction_1) == 1
                CR_CCW_CCW = [CR_CCW_CCW; temp];
%                 if isempty(findstr('40', trials(trial_id).direction_1)) == 0
                    stim = [stim; 4];
%                 else
%                     stim = [stim; 8];
%                 end
            end
        end
    else
        length(temp)
    end
end

% Hit = nanmean(Hit,1);
% Miss = nanmean(Miss,1);
% FA = nanmean(FA,1);
% CR = nanmean(CR,1);
% AP_Hit = nanmean(all(stim==1&choice==1,:),1);
% PA_Hit = nanmean(all(stim==3&choice==1,:),1);
% AA_FA = nanmean(all(stim==2&choice==4,:),1);
% PP_FA = nanmean(all(stim==4&choice==4,:),1);
AP_Hit = nanmean(all(stim==1,:),1);
PA_Hit = nanmean(all(stim==3,:),1);
AA_FA = nanmean(all(stim==2,:),1);
PP_FA = nanmean(all(stim==4,:),1);



d1 = (nanmean(d1)/1000);
d2 = (nanmean(d2)/1000);
report = (nanmean(report)/1000);
delay = (nanmean(delay)/1000);
reward = (nanmean(reward)/1000);
timing = [d1,d2,delay,report, reward];