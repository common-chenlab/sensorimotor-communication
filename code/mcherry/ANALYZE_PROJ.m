load([smroot() 'Analysis/summary.mat']);
% [release] path handled by startup_sm.m: addpath('Z:\Dropbox\Dropbox\Chen Lab Team Folder\Projects\Sensorimotor\Analysis\whisker_analysis');

counter = 1;
% result = [];
for i = 1:size(control,1)
    try
        counter
        temp = project_correlation(control{i,1}, control{i,2}, 1);
        result(:,:,1,counter) = temp(:,1:310);
        temp = project_correlation(control{i,1}, control{i,2}, 0);
        result(:,:,2,counter) = temp(:,1:310);
%           temp = project_correlation(control{i,1}, control{i,2}, 2);
%         result(:,:,3,counter) = temp(:,1:310);
        counter = counter + 1;
    catch
    end
end
        
result2 = nanmean(result,4);
result2sem = nanstd(result,[],4)/sqrt(size(result,4));
t = (1:310)/30;
titles = {'S1:S2','S1:M1A','S1:M1B','S2:M1A','S2:M1B','M1A:M1B'};
for i = 2:6
    figure(i)
    confplot(t, result2(i,:,1), result2sem(i,:,1), result2sem(i,:,1));  % non-mCherry only / mCherry-
    hold on
    confplot(t, result2(i,:,2), result2sem(i,:,2), result2sem(i,:,2));  % Ctl mCherry-
    hold off
%     
%     plot(result2(i,:,1));  % non-mCherry only / mCherry-
%     hold on
%     plot(result2(i,:,2))   % Ctl - 
% %     plot(result2(i,:,3))   % mCherry only
%     hold off
    ylim([0 1])
    title(titles{i})
end

%% CCC2
result2 = nanmean(resultCCC2,4);
result2sem = nanstd(resultCCC2,[],4)/sqrt(size(resultCCC2,4));
t = (1:310)/30;
titles = {'S1:S2','S1:M1A','S1:M1B','S2:M1A','S2:M1B','M1A:M1B'};
for i = 2:6
    figure(i)
    confplot(t, result2(i,:,1), result2sem(i,:,1), result2sem(i,:,1));  % non-mCherry only / mCherry-
    hold on
    confplot(t, result2(i,:,2), result2sem(i,:,2), result2sem(i,:,2));  % Ctl mCherry-
    hold off
    ylim([0 0.5])
    title(titles{i})
end



%% stats
for i = 1:6
    [p, table] = anova_rm({permute(result(i,200:end,1,:),[4,2,1,3]) permute(result(i,200:end,2,:),[4,2,1,3])});
end

for i = 1:6
    [p, table] = anova_rm({permute(resultCCC2(i,200:end,1,:),[4,2,1,3]) permute(resultCCC2(i,200:end,2,:),[4,2,1,3])});
end


%%
IFImCh = {}; % non-mCherry only
IFIctl = {};
IFImChonly = {}; % mCherry only
parfor i = 1:size(control,1)
    try
        disp(i)
%         IFImCh{i} = BATCH_IFI_mCherry(control{i,1}, control{i,2}, 1);
%         IFIctl{i} = BATCH_IFI_mCherry(control{i,1}, control{i,2}, 0);
        IFImChonly{i} = BATCH_IFI_mCherry(control{i,1}, control{i,2}, 2);
    catch
    end
end

%%

load([smroot() 'Scripts/CCA/IFI.mat']);


%% CONFIDENCE BOUNDS
sssmCh = [];
sssctl = [];
counter = 1;
for i = 1:length(rrr)
    try
        temp = IFImCh{i};
        sssmCh(:,:,:,:,counter) = temp(1:272,:,:,:,3);
        temp = IFIctl{i};
        sssctl(:,:,:,:,counter) = temp(1:272,:,:,:,3);
        counter = counter + 1;
    catch
    end
end

valctl = [];
valmCh = [];
for j = 1:6    
    ttt = nanmean(sssctl(1:272,1,j,9,:),5);    
    valctl(j) = nanmean(ttt(1:20));
    ttt = nanmean(sssmCh(1:272,1,j,9,:),5);    
    valmCh(j) = nanmean(ttt(1:20));
end
lowctl = max(valctl);
lowmCh = max(valmCh);

sssmCh = [];
sssctl = [];
counter = 1;
for i = 1:length(rrr)
    try
        temp = IFImCh{i};
        sssmCh(:,:,:,:,counter) = temp(1:272,:,:,:,2);
        IFImChonly
        counter = counter + 1;
    catch
    end
end

valctl = [];
valmCh = [];
for j = 1:6    
    ttt = nanmean(sssctl(1:272,1,j,9,:),5);    
    valctl(j) = nanmean(ttt(1:20));
    ttt = nanmean(sssmCh(1:272,1,j,9,:),5);    
    valmCh(j) = nanmean(ttt(1:20));
end
highctl = min(valctl);
highmCh = min(valmCh);


%% OVERALL
sssmCh = [];
sssctl = [];
sssmChonly = [];
counter = 1;
for i = 1:length(IFImCh)
    try
        temp = IFImCh{i};
        sssmCh(:,:,:,:,counter) = temp(1:299,:,:,:,1);
        temp = IFIctl{i};
        sssctl(:,:,:,:,counter) = temp(1:299,:,:,:,1);
        temp = IFImChonly{i};
        sssmChonly(:,:,:,:,counter) = temp(1:299,:,:,:,1);
        counter = counter + 1;
    catch
    end
end


names = {'S1:S2','S1:M1A','S1:M1B','S2:M1A','S2:M1B','M1A:M1B'};
t = [1:299]/30;
for j = 1:6
    figure(j)
    for i = 1
        tt = nanmean(movmean(sssmCh(:,i,j,9,:),5,1),5);
        sem = nanstd(movmean(sssmCh(:,i,j,9,:),5,1),[],5)/sqrt(size(sssmCh,5)); 
%         confplot(t,tt, sem,sem);
%         plot(t,tt, sem,sem);
        plot(t,tt);
        hold on
    end
    for i = 1
        tt = nanmean(movmean(sssctl(:,i,j,9,:),5,1),5);
        sem = nanstd(movmean(sssctl(:,i,j,9,:),5,1),[],5)/sqrt(size(sssctl,5));
        %         confplot(t,tt, sem,sem);
        %         plot(t,tt, sem,sem);
        plot(t,tt);
        hold on
    end
%     for i = 1
%         tt = nanmean(movmean(sssmChonly(:,i,j,9,:),5,1),5);
%         sem = nanstd(movmean(sssmChonly(:,i,j,9,:),5,1),[],5)/sqrt(size(sssmChonly,5));
%         %         confplot(t,tt, sem,sem);
%         %         plot(t,tt, sem,sem);
%         plot(t,tt);
%         hold on
%     end
    hold off
    legend('mCherry-','ctl')
%     legend('non-mCherry only','XX','mCherry only')
    title(names{j})
    xline(81/30)
    xline(113/30)
    xline(226/30)
    xline(259/30)
%     xlim([5 9])
    ylim([-0.3 0.3])
end


%%  TRIAL
sssmCh = [];
sssctl = [];
counter = 1;
for i = 1:length(IFImCh)
    try
        temp = IFImCh{i};
        sssmCh(:,:,:,:,counter) = temp(1:272,:,:,:,1);
        temp = IFIctl{i};
        sssctl(:,:,:,:,counter) = temp(1:272,:,:,:,1);
        counter = counter + 1;
    catch
    end
end



names = {'S1:S2','S1:M1A','S1:M1B','S2:M1A','S2:M1B','M1A:M1B'};
t = [1:272]/30;
for j = 1:6
    figure(j)
    for i = 5:8
        tt = nanmean(movmean(sssmCh(:,1,j,i,:),5,1),5);
        sem = nanstd(movmean(sssmCh(:,1,j,i,:),5,1),[],5)/sqrt(size(sssmCh,5)); 
%         confplot(t,tt, sem,sem);
%         plot(t,tt, sem,sem);
          plot(t, tt);
        hold on
    end
    hold off
    if j == 1
    legend('a lick','a no lick','p no lick','p lick')
    end
    title([names{j} ' - mCherry'])
    xline(226/30)
    xline(259/30)
%     xlim([5 9])
    ylim([-0.5 0.3])
end

t = [1:272]/30;
for j = 1:6
    figure(j+6)
    for i = 5:8
        tt = nanmean(movmean(sssctl(:,1,j,i,:),5,1),5);
        sem = nanstd(movmean(sssctl(:,1,j,i,:),5,1),[],5)/sqrt(size(sssctl,5)); 
%         confplot(t,tt, sem,sem);
%         plot(t,tt, sem,sem);
         plot(t, tt);
        hold on
    end
    hold off
%     legend('a lick','a no lick','p no lick','p lick')
    title([names{j} ' - ctl'])
    xline(226/30)
    xline(259/30)
%     xlim([5 9])
    ylim([-0.5 0.3])
end

%%
idx = {'S1S2',[190:200];
'S1M1A',[197:207];
'S1M1B',[186:196];
'S2M1A',[186:196];
'S2M1B',[182:192];
'M1AM1B',[190:200]}


for j = 1:6
    figure(j)
    ttt = nanmean(sss(idx{j,2},1,:,:,:),1);
    data2 = permute(ttt(1,1,j,5:8,:), [5 4 3 2 1]);
    ttt = permute(ttt, [3 4 5 1 2]);
    tt = permute(ttt(j,5:8,:),[3 2 1]);
    %     tt = [nanmean(tt(:,[1,3]),2),nanmean(tt(:,[2,4]),2)];
    val = nanmean(tt,1);
    sem = nanstd(tt,[],1)/sqrt(size(tt,1));
    bar([1:4],val)
    hold on
    er = errorbar([1:4],val,sem,sem);
    er.Color = [0 0 0];
    er.LineStyle = 'none';
    hold off
    title(names{j})
    ylim([-0.25 0.25])
    yline(high)
    yline(low)
    xticks([1:4])
    xticklabels({'a lick','a no lick','p no lick','p lick'})
%     subjects = [1:size(data2,1)]'; % Subject IDs
    % Creating the table for repeated measures ANOVA
%     T = table(subjects, data2(:, 1), data2(:, 2), data2(:, 3), data2(:, 4),'VariableNames', {'Subject', 'Hit', 'Miss', 'CR' 'FA'});
%     % Define the within-subjects factor
%     within = table({'Hit'; 'Miss'; 'CR'; 'FA'}, 'VariableNames', {'Condition'});
%     % Repeated measures ANOVA
%     rm = fitrm(T, 'Hit-FA ~ Subject', 'WithinDesign', within);
%     % Display the results of repeated measures ANOVA
%     ranovaResult = ranova(rm);
%     disp('Results of repeated measures ANOVA:');
%     disp(ranovaResult);
%     % Post-hoc multiple comparisons
%     mc = multcompare(rm, 'Condition', 'ComparisonType', 'tukey-kramer');
%     disp('Post-hoc multiple comparisons results:');
%     disp(mc);

end



