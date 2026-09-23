% [release] path handled by startup_sm.m: addpath('Z:\Dropbox\Dropbox\Chen Lab Team Folder\Analysis Suite\Secondary Analysis\common_query_functions')
% [release] path handled by startup_sm.m: addpath('Z:\Dropbox\Dropbox\Chen Lab Team Folder\Analysis Suite\Secondary Analysis\process_whisking')
% [release] path handled by startup_sm.m: addpath('Z:\Dropbox\Dropbox\Chen Lab Team Folder\Analysis Suite\Secondary Analysis\process_whisking\hilbert_code')
pathdir = [smroot() 'Animals/'];
load([smroot() 'Analysis/summary.mat'])
load([smroot() 'Analysis/lick_analysis/choice.mat'])

%% CODE IS TO PROCESS DATA

%% PROBE PERIOD
result = [];
for i = 1:size(control,1)
    try       
        i
        load([pathdir control{i,1} '\' control{i,1} '-' num2str(control{i,2}) '_whisker.mat']);
        load([pathdir control{i,1} '\' control{i,1} '-' num2str(control{i,2}) '.mat'],'trials','summary');
        %          [Xx, Yx, Wx, Zx] = sort_whisking_touch(summary, whisker_dat, trials, 1000, 4, 1, 0);
        [AP, PA, PP, AA] = sort_whisking_delay_probe(control_choice(i), summary, whisker_dat, trials, 1000, 4, 1, 1,500);        
        result(i).angleAP = AP;
        result(i).anglePA = PA;
        result(i).anglePP = PP;
        result(i).angleAA = AA;

        [AP, PA, PP, AA] = sort_whisking_delay_probe(control_choice(i), summary, whisker_dat, trials, 1000, 4, 1, 0,500);
        result(i).curvAP = AP;
        result(i).curvPA = PA;
        result(i).curvPP = PP;
        result(i).curvAA = AA;

        [AP, PA, PP, AA] = sort_whisking_delay_probe(control_choice(i), summary, whisker_dat, trials, 1000, 4, 1, 2,500);
        result(i).ampAP = AP;
        result(i).ampPA = PA;
        result(i).ampPP = PP;
        result(i).ampAA = AA;
    catch
    end
end

%%

result = [];
for i = 1:size(control,1)
    try       
        i
        load([pathdir control{i,1} '\' control{i,1} '-' num2str(control{i,2}) '_whisker.mat']);
        load([pathdir control{i,1} '\' control{i,1} '-' num2str(control{i,2}) '.mat'],'trials','summary');
        %          [Xx, Yx, Wx, Zx] = sort_whisking_touch(summary, whisker_dat, trials, 1000, 4, 1, 0);
        [AP, PA, PP, AA] = sort_whisking_delay(summary, whisker_dat, trials, 1000, 4, 1, 1,500);        
        result(i).angleAP = AP;
        result(i).anglePA = PA;
        result(i).anglePP = PP;
        result(i).angleAA = AA;

        [AP, PA, PP, AA] = sort_whisking_delay(summary, whisker_dat, trials, 1000, 4, 1, 0,500);
        result(i).curvAP = AP;
        result(i).curvPA = PA;
        result(i).curvPP = PP;
        result(i).curvAA = AA;

        [AP, PA, PP, AA] = sort_whisking_delay(summary, whisker_dat, trials, 1000, 4, 1, 2,500);
        result(i).ampAP = AP;
        result(i).ampPA = PA;
        result(i).ampPP = PP;
        result(i).ampAA = AA;
    catch
    end
end

%% CODE BELOW IS AFTER PROCESSING DATA AND FOR FIGURES AND STATISTIC ANALYSIS

load([smroot() 'Analysis/whisker_analysis/matlab.mat']) % [release] was load('matlab.mat') from whisker_analysis/
angle = [];
counter = 1;
for i = 1:size(control,1)
    try       
        angle(:,1,counter) = movmean(result(i).ampAP(1:5600),50);
        angle(:,2,counter) = movmean(result(i).ampPA(1:5600),50);
        angle(:,3,counter) = movmean(result(i).ampPP(1:5600),50);
        angle(:,4,counter) = movmean(result(i).ampAA(1:5600),50);
        counter = counter + 1;
    catch
    end
end

% % AP - Hit, PA - Miss,  PP - CR, AA - FA
% plot(nanmean(angle,3))
% legend('A lick','A no lick','P no lick','P lick')
t = [1:5600]/500;
figure; 
confplot(t, nanmean(angle(:,1,:),3), nanstd(angle(:,1,:),[],3)/sqrt(size(angle,3)), nanstd(angle(:,1,:),[],3)/sqrt(size(angle,3))); hold on
confplot(t, nanmean(angle(:,2,:),3), nanstd(angle(:,2,:),[],3)/sqrt(size(angle,3)), nanstd(angle(:,2,:),[],3)/sqrt(size(angle,3))); hold on
confplot(t, nanmean(angle(:,3,:),3), nanstd(angle(:,3,:),[],3)/sqrt(size(angle,3)), nanstd(angle(:,3,:),[],3)/sqrt(size(angle,3))); hold on
confplot(t, nanmean(angle(:,4,:),3), nanstd(angle(:,4,:),[],3)/sqrt(size(angle,3)), nanstd(angle(:,4,:),[],3)/sqrt(size(angle,3))); hold off
print(gcf, '-depsc', '-painters', 'amp.eps');




curv = [];
counter = 1;
for i = 1:size(control,1)
    try       
        curv(:,1,counter) = 1000/32*movmean(result(i).curvAP(1:5600),50);
        curv(:,2,counter) = 1000/32*movmean(result(i).curvPA(1:5600),50);
        curv(:,3,counter) = 1000/32*movmean(result(i).curvPP(1:5600),50);
        curv(:,4,counter) = 1000/32*movmean(result(i).curvAA(1:5600),50);
        counter = counter + 1;
    catch
    end
end
% plot(nanmean(curv,3))
figure; 
confplot(t, nanmean(curv(:,1,:),3), nanstd(curv(:,1,:),[],3)/sqrt(size(curv,3)), nanstd(curv(:,1,:),[],3)/sqrt(size(curv,3))); hold on
confplot(t, nanmean(curv(:,2,:),3), nanstd(curv(:,2,:),[],3)/sqrt(size(curv,3)), nanstd(curv(:,2,:),[],3)/sqrt(size(curv,3))); hold on
confplot(t, nanmean(curv(:,3,:),3), nanstd(curv(:,3,:),[],3)/sqrt(size(curv,3)), nanstd(curv(:,3,:),[],3)/sqrt(size(curv,3))); hold on
confplot(t, nanmean(curv(:,4,:),3), nanstd(curv(:,4,:),[],3)/sqrt(size(curv,3)), nanstd(curv(:,4,:),[],3)/sqrt(size(curv,3))); hold off
print(gcf, '-depsc', '-painters', 'curv.eps');


%% stats
result = resultsamplechoice;
angle = [];
counter = 1;
for i = 1:size(control,1)
    try       
        angle(:,1,counter) = movmean(result(i).ampAP(1:5600),50);
        angle(:,2,counter) = movmean(result(i).ampPA(1:5600),50);
        angle(:,3,counter) = movmean(result(i).ampPP(1:5600),50);
        angle(:,4,counter) = movmean(result(i).ampAA(1:5600),50);
        counter = counter + 1;
    catch
    end
end

%% Compute mean amplitude over window [2400:2700] for each signal & subject
% nanmean over dim 1 → [1 x 4 x n_subjects], squeeze+transpose → [n_subjects x 4]
data = squeeze(nanmean(angle(2400:2700,:,:), 1))'; % [n_subjects x 4]
group_names = {'AP', 'PA', 'PP', 'AA'};
figure; [p_anova, tbl, stats] = anova1(data, group_names); title('One-Way ANOVA: Signal Comparison');
fprintf('ANOVA p-value: %.4f\n', p_anova); disp('--- ANOVA Table ---'); disp(tbl);
figure; [c, m, h, gnames] = multcompare(stats, 'CType', 'tukey-kramer');
title('Multiple Comparisons (Tukey-Kramer)');
mc_table = array2table(c, ...
    'VariableNames', {'Group1','Group2','Lower_CI','Mean_Diff','Upper_CI','p_value'});
mc_table.Group1 = gnames(mc_table.Group1); mc_table.Group2 = gnames(mc_table.Group2);
disp('--- Multiple Comparisons Table ---'); disp(mc_table);


result = resultchoice;
angle = [];
counter = 1;
for i = 1:size(control,1)
    try       
        angle(:,1,counter) = movmean(result(i).ampAP(1:5600),50);
        angle(:,2,counter) = movmean(result(i).ampPA(1:5600),50);
        angle(:,3,counter) = movmean(result(i).ampPP(1:5600),50);
        angle(:,4,counter) = movmean(result(i).ampAA(1:5600),50);
        counter = counter + 1;
    catch
    end
end

%% Compute mean amplitude over window [2400:2700] for each signal & subject
% nanmean over dim 1 → [1 x 4 x n_subjects], squeeze+transpose → [n_subjects x 4]
data = nanmean(angle(4800:5100,:,:), 1); % [n_subjects x 4]
data = permute(data,[3 2 1]);
group_names = {'A lick', 'A no lick', 'P lick', 'P no lick'};
figure; [p_anova, tbl, stats] = anova1(data, group_names); title('One-Way ANOVA: Signal Comparison');
fprintf('ANOVA p-value: %.4f\n', p_anova); disp('--- ANOVA Table ---'); disp(tbl);
figure; [c, m, h, gnames] = multcompare(stats, 'CType', 'tukey-kramer');
title('Multiple Comparisons (Tukey-Kramer)');
mc_table = array2table(c, ...
    'VariableNames', {'Group1','Group2','Lower_CI','Mean_Diff','Upper_CI','p_value'});
mc_table.Group1 = gnames(mc_table.Group1); mc_table.Group2 = gnames(mc_table.Group2);
disp('--- Multiple Comparisons Table ---'); disp(mc_table);

t = [1:5600];
figure; 
plot(t, nanmean(angle(:,1,:),3)); hold on
plot(t, nanmean(angle(:,2,:),3)); hold on
plot(t, nanmean(angle(:,3,:),3)); hold on
plot(t, nanmean(angle(:,4,:),3)); hold off



