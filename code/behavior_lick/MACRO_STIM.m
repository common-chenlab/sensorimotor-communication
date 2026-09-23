% [release] path handled by startup_sm.m: addpath('Z:\Dropbox\Dropbox\Chen Lab Team Folder\Projects\Perirhinal\Analysis\sort');

load([smroot() 'Analysis/summary.mat'])

results = [];
parfor i = 1:size(control,1)
    try        
        [timing, AP_Hit, PA_Hit, AA_FA, PP_FA] = sort_lick_stim(control{i,1}, control{i,2});
        results(i).AP = AP_Hit;        
        results(i).PA = PA_Hit;
        results(i).AA = AA_FA;
        results(i).PP = PP_FA;       
        results(i).animal = control{i,1};
        results(i).session = control{i,2};
    catch
    end
end
control_lick = results;

results = [];
parfor i = 1:size(c21,1)
    try        
        [timing, AP_Hit, PA_Hit, AA_FA, PP_FA] = sort_lick_stim(c21{i,1}, c21{i,2});
        results(i).AP = AP_Hit;        
        results(i).PA = PA_Hit;
        results(i).AA = AA_FA;
        results(i).PP = PP_FA;       
        results(i).animal = c21{i,1};
        results(i).session = c21{i,2};
    catch
    end
end
c21_lick = results;

%%


results = [];
parfor i = 1:size(control,1)
    try        
        [all, stim, choice, trialno] = sample_choice(control{i,1}, control{i,2});
        results(i).all = all;        
        results(i).stim = stim;
        results(i).choice = choice;        
        results(i).trialno = trialno;        
    catch
    end
end
control_choice = results;

results = [];
parfor i = 1:size(c21,1)
    try        
        [all, stim, choice, trialno] = sample_choice(c21{i,1}, c21{i,2});
        results(i).all = all;        
        results(i).stim = stim;
        results(i).choice = choice;     
         results(i).trialno = trialno;
    catch
    end
end
c21_choice = results;

%%

idx = [39, 91, 131, 164, 197, 240, 280];


allAP_Hit = []; 
allPA_Hit = []; 
allFA = [];
% allPP_FA = [];



temp_AP = [];
temp_PA = [];
temp_AA = [];
temp_PP = [];
for j = 1:length(control_lick)
    temp_AP = [temp_AP; control_lick(j).AP];
    temp_PA = [temp_PA; control_lick(j).PA];
    temp_AA = [temp_AA; control_lick(j).AA];
    temp_PP = [temp_PP; control_lick(j).PP];
end
figure;
plot(nanmean(temp_AP,1))
hold on
plot(nanmean(temp_PA,1))
plot(nanmean(temp_AA,1))
plot(nanmean(temp_PP,1))
hold off


temp_AP = [];
temp_PA = [];
temp_AA = [];
temp_PP = [];
for j = 1:length(c21_lick)
    temp_AP = [temp_AP; c21_lick(j).AP];
    temp_PA = [temp_PA; c21_lick(j).PA];
    temp_AA = [temp_AA; c21_lick(j).AA];
    temp_PP = [temp_PP; c21_lick(j).PP];
end
figure;
plot(nanmean(temp_AP,1))
hold on
plot(nanmean(temp_PA,1))
plot(nanmean(temp_AA,1))
plot(nanmean(temp_PP,1))
hold off



t = (1:480)/50;
for i = 1:5
    figure(i); confplot(t, nanmean(allAP_Hit(:,:,i),1), nanstd(allAP_Hit(:,:,i),1)/sqrt(7));
    hold on
    confplot(t, nanmean(allPA_Hit(:,:,i),1), nanstd(allPA_Hit(:,:,i),1)/sqrt(7));
    hold on
    confplot(t, nanmean(allFA(:,:,i),1), nanstd(allFA(:,:,i),1)/sqrt(7));    
    xline(timing);
    ylim([0 0.5]);  title(['T3 ' num2str(i-1)])
    hold off
end


%%
load('FA_report.mat')

idx = [39, 91, 131, 164, 197, 240, 280];
allFA = [];

for j = 1:length(idx)
    try
        allFA = [allFA; result(idx(j)).asFAall(1:187)];        
    catch
    end
end






t = (1:480)/50;
for i = 1:5
    figure(i);
    confplot(t, allHit(i,:), SallHit(i,:), SallHit(i,:)); hold on;
    confplot(t, allMiss(i,:), SallMiss(i,:), SallMiss(i,:));   hold on;
    confplot(t, allFA(i,:), SallFA(i,:), SallFA(i,:));   hold on;
    confplot(t, allCR(i,:), SallCR(i,:), SallCR(i,:));
    ylim([-0.1 0.5]);
    xline(timing);
    
    
    %     temp = [allHit(i,:); allMiss(i,:); allFA(i,:); allCR(i,:)];
    %     figure(i); plot(t, temp'); ylim([0 0.5]); xline(timing);
    %     legend('Hit','Miss','FA','CR');
end

t = (1:480)/50;
for i = 1:5
    figure(i+5);
    confplot(t, allFast(i,:), SallFast(i,:), SallFast(i,:));   hold on;
    confplot(t, allSlow(i,:), SallSlow(i,:), SallSlow(i,:));
    ylim([0 0.5]);
    xline(timing);
    
    %     temp = [allFast(i,:); allSlow(i,:)];
    %         plot(t, temp'); ylim([0 0.4]); xline(timing);
    %     legend('Fast','Slow');
end




