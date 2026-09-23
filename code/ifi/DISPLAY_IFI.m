load([smroot() 'Scripts/CCA/IFI.mat']);


%% CONFIDENCE BOUNDS
sss = [];
counter = 1;
for i = 1:length(rrr)
    try
        sss(:,:,:,:,counter) = rrr3(i).rrr(1:272,:,:,:,3);
        counter = counter + 1;
    catch
    end
end

val = [];
for j = 1:6    
    ttt = nanmean(sss(1:272,1,j,9,:),5);    
%     plot(ttt)
%     hold on
%     ttt = permute(ttt, [3 4 5 1 2]);    
    val(j) = nanmean(ttt(1:20));    
end
low = max(val);

sss = [];
counter = 1;
for i = 1:length(rrr)
    try
        sss(:,:,:,:,counter) = rrr3(i).rrr(1:272,:,:,:,2);
        counter = counter + 1;
    catch
    end
end

val = [];
for j = 1:6    
    ttt = nanmean(sss(1:272,1,j,9,:),5);    
%     plot(ttt)
%     hold on
%     ttt = permute(ttt, [3 4 5 1 2]);    
    val(j) = nanmean(ttt(1:20));    
end
high = min(val);





%% OVERALL
sss = [];
counter = 1;
for i = 1:length(rrr)  
    try
%         sss(:,:,:,:,counter) = rrr2(i).rrr(1:272,:,:,:);
        sss(:,:,:,:,counter) = rrr2(i).rrr(1:299,:,:,:);        
        counter = counter + 1;
    catch
    end
end

%% CANONICAL COMPONENTS
names = {'S1:S2','S1:M1A','S1:M1B','S2:M1A','S2:M1B','M1A:M1B'};
t = [1:299]/30;
for j = 1:6
    figure(j)
    for i = 1:3
        tt = nanmean(movmean(sss(:,i,j,9,:),5,1),5);
        sem = nanstd(movmean(sss(:,i,j,9,:),5,1),[],5)/sqrt(size(sss,5)); 
%         confplot(t,tt, sem,sem);
%         plot(t,tt, sem,sem);
        plot(t,tt);
        hold on
    end
    hold off
%     legend('a lick','a no lick','p no lick','p lick')
    title(names{j})
    xline(81/30)
    xline(113/30)
    xline(226/30)
    xline(259/30)
%     xlim([5 9])
    ylim([-0.3 0.3])
end


%%  TRIAL
sss = [];
counter = 1;
for i = 1:length(rrr)
    try
        sss(:,:,:,:,counter) = rrr(i).rrr(1:272,:,:,:);
%         sss(:,:,:,:,counter) = rrr3(i).rrr(1:272,:,:,:,3);
        counter = counter + 1;
    catch
    end
end

names = {'S1:S2','S1:M1A','S1:M1B','S2:M1A','S2:M1B','M1A:M1B'};
t = [1:272]/30;
for j = 1:6
    figure(j)
    for i = 5:8
        tt = nanmean(movmean(sss(:,1,j,i,:),5,1),5);
        sem = nanstd(movmean(sss(:,1,j,i,:),5,1),[],5)/sqrt(size(sss,5)); 
%         confplot(t,tt, sem,sem);
%         plot(t,tt, sem,sem);
          plot(t, tt);
        hold on
    end
    hold off
    legend('a lick','a no lick','p no lick','p lick')
    title(names{j})
    xline(226/30)
    xline(259/30)
%     xlim([5 9])
    ylim([-0.5 0.3])
end

t = [1:272]/30;
for j = 1:6
    figure(j)
    for i = 1:4
        tt = nanmean(movmean(sss(:,1,j,i,:),10,1),5);
        sem = nanstd(movmean(sss(:,1,j,i,:),10,1),[],5)/sqrt(size(sss,5)); 
%         confplot(t,tt, sem,sem);
%         plot(t,tt, sem,sem);
         plot(t, tt);
        hold on
    end
    hold off
    legend('a lick','a no lick','p no lick','p lick')
    title(names{j})
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


