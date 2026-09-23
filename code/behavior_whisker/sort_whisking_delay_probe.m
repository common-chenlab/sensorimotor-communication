function [X, Y, W, Z] = sort_whisking_delay_probe(all, summary, whisker_dat, trials, min_frames, sort_type, task, angle, samplingrate)

% min_frames: applies a threshold to returns trials with a minimal number of frames

% sort_type
%       1 - 1st rotation
%       2 - 2nd rotation
%       3 - decision

% sort_type
%       1 - 1st rotation
%       2 - 2nd rotation
%       3 - decision
min_offset = [];
for i = 1:length(trials)
    min_offset = [min_offset; trials(i).present_time];
end
if nanmean(min_offset) < 2500
    min_offset = 1;
else
    min_offset = 1+samplingrate;
end

%% calculate min frames
calc_min = [];
for i = 1:length(trials)    
    if trials(i).delay == 2000
        calc_min = [calc_min; trials(i).recording_time];
    end
end
min_frames = round(min(calc_min)/1000*samplingrate)-min_offset;
%%

CW_CCW = [];
CCW_CW = [];
CW_CW = [];
CCW_CCW = [];

Hit = [];
Miss = [];
CR = [];
FA = [];

d1=[];
d2=[];
delay=[];
report=[];
reward=[];
allwhisking = [];

 


for j = 2:size(summary.table,1)
    trial_id = summary.table{j,1};
    idx = find(ismember(all.trialno,trial_id));
    %get touch vector
    CCD = summary.table{j,14};
    if isempty(CCD) == 0
        
        if trials(trial_id).delay == 2000
            d1 = [d1; trials(trial_id).direction_1_time];
            d2 = [d2; trials(trial_id).direction_2_time];
            delay = [delay; trials(trial_id).delay_time];
            report = [report; trials(trial_id).report_time];
            reward = [reward; trials(trial_id).reward_time];
        end
        
        if angle == 1
            whisking = whisker_dat(CCD).mean_angle;
        elseif angle == 0
            whisking = whisker_dat(CCD).mean_curve;
        elseif angle == 2
            whisking = whisker_dat(CCD).mean_angle;
            
            if length(whisking) > min_frames
                whisking = movmean(whisking,3,'omitnan');
                try
                    [phase, whisking, setpt] = get_hilbert_components_100(whisking);
                catch
                    whisking = [];
                end
            end
        end
        if isempty(whisking) == 0
            record_time = round(trials(trial_id).end_time/1000*samplingrate);
            d2_time = round(trials(trial_id).delay_present_time/1000*samplingrate);
            delay_time = round((trials(trial_id).delay_withdraw_time+2000)/1000*samplingrate);
            d1_end = delay_time-1;
            report_time = round(trials(trial_id).report_time/1000*samplingrate);
            start = min_offset;
           
            if length(whisking) >= min_frames
                whisking = whisking(1:min_frames);
                allwhisking = [allwhisking ; whisking];
                whisking = whisking - nanmean(whisking(1:samplingrate));
                if all.all(idx)>(3/100)&all.stim(idx)<3  % A lick 
                    Hit = [Hit; whisking];
                elseif all.all(idx)<=(3/100)&all.stim(idx)<3 % A no lick
                   Miss = [Miss; whisking];
                elseif all.all(idx)<=(3/100)&all.stim(idx)>2  % P no lick
                    CR = [CR; whisking];
                elseif all.all(idx)>(3/100)&all.stim(idx)>2 % P lick
                    FA = [FA; whisking];
                end                    
            end
        end
    end
end

d1 = (nanmean(d1)/1000);
d2 = (nanmean(d2)/1000);
report = (nanmean(report)/1000);
delay = (nanmean(delay)/1000);
Z = reward;
reward = (nanmean(reward)/1000);
timing = [d1,d2,delay,report, reward];



if sort_type  == 1
    X = [Hit_CW_CCW; CR_CW_CW];
    Y = [Hit_CCW_CW; CR_CCW_CCW];
    W = [];
    Z = [];
    
    X = nanmean(X,1);
    Y = nanmean(Y,1);
    W = nanmean(W,1);
    Z = nanmean(Z,1);
    
elseif sort_type  == 2
    X = [Hit_CW_CCW; CR_CCW_CCW];
    Y = [Hit_CCW_CW; CR_CW_CW];
    W = [];
    Z = [];
elseif sort_type  == 3
    X = [Hit_CW_CCW; Hit_CCW_CW];
    Y = [CR_CCW_CCW; CR_CW_CW];
    W = [];
    Z = [];
elseif sort_type == 4   
    X = Hit;
    Y = Miss;
    W = CR;
    Z = FA;
    
    if angle ~= 2
        for i = 1:size(X,1)
            X(i,:) = movmean(X(i,:),round(samplingrate/10));
        end
        
        for i = 1:size(Y,1)
            Y(i,:) = movmean(Y(i,:),round(samplingrate/10));
        end
        
        for i = 1:size(W,1)
            W(i,:) = movmean(W(i,:),round(samplingrate/10));
        end
        
        for i = 1:size(Z,1)
            Z(i,:) = movmean(Z(i,:),round(samplingrate/10));
        end
    end
    
    X = nanmean(X,1);
    Y = nanmean(Y,1);
    W = nanmean(W,1);
    Z = nanmean(Z,1);
    
elseif sort_type == 5
    X = [Hit_CW_CCW];
    Y = [CR_CCW_CCW; CR_CW_CW; Hit_CCW_CW];
    W = [];
    Z = [];
elseif sort_type == 6
    X = [Hit_CCW_CW];
    Y = [CR_CW_CW; Hit_CW_CCW; CR_CCW_CCW];
    W = [];
    Z = [];
elseif sort_type == 7
    X = [CR_CCW_CCW];
    Y = [CR_CW_CW; Hit_CCW_CW; Hit_CW_CCW];
    W = [];
    Z = [];
elseif sort_type == 8
    X = [CR_CW_CW];
    Y = [Hit_CCW_CW; Hit_CW_CCW; CR_CCW_CCW];
    W = [];
    Z = [];
elseif sort_type == 9
    X = allwhisking;
    Y = [];
    W = [];
    Z = [];
end