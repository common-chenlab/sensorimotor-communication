load([smroot() 'Analysis/summary.mat']);
load([smroot() 'Analysis/svm/PCA_SVM.mat']);
load([smroot() 'Analysis/svm/PCA_SVM_lick.mat']);
load([smroot() 'Analysis/svm/CONTROLCROSSTEST_REWARD.mat'], 'controlweights')
% load('Z:\Dropbox\Dropbox\Chen Lab Team Folder\Projects\Sensorimotor\Analysis\svm\PCA_SVM_reward.mat');
% [release] path handled by startup_sm.m: addpath('Z:\Dropbox\Chen Lab Dropbox\Chen Lab Team Folder\Analysis Suite\Data Visualization');

%%

load([smroot() 'Analysis/summary.mat']);
load([smroot() 'Analysis/svm/PCA_SVM.mat']);
load([smroot() 'Analysis/svm/PCA_SVM_lick.mat']);
load([smroot() 'Analysis/svm/CONTROLCROSSTEST_REWARD.mat'], 'controlweights')
% load('Z:\Dropbox\Dropbox\Chen Lab Team Folder\Projects\Sensorimotor\Analysis\svm\PCA_SVM_reward.mat');
% [release] path handled by startup_sm.m: addpath('C:\Dropbox\Chen Lab Dropbox\Chen Lab Dropbox\Chen Lab Team Folder\Analysis Suite\Data Visualization');



result = [];
% shufresult = [];
counter = 1;
% idx = [1,1,1; % S1 S2
%     2,1,1; % S1 M1A
%     3,1,1; % S1 M1B
%     1,2,2; % S2 S1
%     4,1,2; % S2 M1A
%     5,1,2; % S2 M1B
%     2,2,3; % M1A S1
%     4,2,3; % M1A S2
%     6,1,3; % M1A M1B
%     3,2,4; % M1B S1
%     5,2,4; % M1B S2
%     6,2,4; % M1B M1A
%     ];

idx = [1,1,1; % S1 S2   
    2,1,1; % S1 M1A
    3,1,1; % S1 M1B
     6,1,3; % M1A M1B
    4,1,2; % S2 M1A
    5,1,2; % S2 M1B
    1,2,2; % S2 S1    
    2,2,3; % M1A S1
    3,2,4; % M1B S1
    6,2,4; % M1B M1A
    4,2,3; % M1A S2
    5,2,4; % M1B S2
    ];

for p = 1:size(control,1)  %     for p = 1:size(c21,1)
    try
        counter
        temp = controlweights{p}; %  temp = c21weights{p}; 
        load([smroot() 'Analysis/proj/full-resid_stim/' control{p,1} '-' num2str(control{p,2}) '-CCA_proj_full-resid_stim.mat']) % [release]               
        %       load([control{p,1} '-' num2str(control{p,2}) '-CCA_proj_full-resid_dir_decis.mat'])
        %        load([control{p,1} '-' num2str(control{p,2}) '-CCA_proj_full-resid_decis.mat'])        
        %         load([c21{p,1} '-' num2str(c21{p,2}) '-CCA_proj_full-resid_stim.mat'])
        if size(temp,2) >= 298
            for m = 1:size(idx,1) % svm weight
                temp2 = CCA_coeff{idx(m,1),idx(m,2)};
                for j = 1:2
                    ccweight = temp2(:,j);
                    for i = 1:298 %size(temp,2)
                        for k = 1:size(temp,4)  %%
                            svweight = temp(:,i,idx(m,3),k);
                            %                             result(i,j,k, counter) = pdist([ccweight, svweight]','cosine');
                            r = corrcoef(ccweight, svweight);
                            result(i,j,k,m,counter) = abs(r(1,2));    %r(1,2)^2;
                            %                           result(i,j,k,m,counter) =  rad2deg(subspace(ccweight, svweight));
%                             shuf = [];
%                             for n = 1:100
%                                 r = corrcoef(ccweight(randperm(length(ccweight))), svweight(randperm(length(svweight))));
%                                 shuf = [shuf; abs(r(1,2))];
%                             end
%                             shufresult(i,j,k,m,counter) = mean(shuf);  % prctile(shuf,95);  
                        end
                    end
                end
            end
            counter = counter + 1;
        end
    catch
    end
end



ttt={'sample stim (no lick)','sample stim (A only)','sample stim','sample lick','test stim','test lick','reward'};

result2 = nanmean(result,5);
% shufresult2 = nanmean(shufresult,5);
t=[1:298]/30;
for i= 3:size(result2,3)
    figure(i)
    for j = 1:size(result2,4)
        subplot(4,3,j)
        plot(t, movmean(result2(:,1,i,j),5,1));
        hold on
%         plot(t, movmean(shufresult2(:,1,i,j),5,1));
        hold off
%         xline((find(t_proj==0)-20)/30)
%         xline((find(t_proj==0)-145-20)/30)
        ylim([0.05 0.5])
        title(ttt{i})
    end
end

%%

result2 = nanmean(movmean(result,5,1),5);
resulterr2 = nanstd(movmean(result,5,1),[],5)/sqrt(size(result,5));
shufresult2 = nanmean(movmean(shufresult,5,1),5);
t=[1:298]/30;
figure(1)
cc = 1;
for j = 1:6
    subplot(2,3,j)
    confplot(t(1:170), result2(1:170,cc,3,j), resulterr2(1:170,cc,3,j), resulterr2(1:170,cc,3,j));
    hold on
    confplot(t(171:end), result2(171:end,cc,5,j), resulterr2(171:end,cc,5,j), resulterr2(171:end,cc,5,j));
    hold on
    confplot(t(1:170), result2(1:170,cc,3,j+6), resulterr2(1:170,cc,3,j+6), resulterr2(1:170,cc,3,j+6));
    hold on
    confplot(t(171:end), result2(171:end,cc,5,j+6), resulterr2(171:end,cc,5,j+6), resulterr2(171:end,cc,5,j+6));
    hold on
    plot(t, shufresult2(:,cc,1,j));
    hold off
    xline((find(t_proj==0)-20)/30)
    xline((find(t_proj==0)-145-20)/30)
    ylim([0.05 0.4])
    title('stim')
end

figure(2)
cc = 1;
for j = 1:6
    subplot(2,3,j)
     confplot(t(1:170), result2(1:170,cc,3+1,j), resulterr2(1:170,cc,3+1,j), resulterr2(1:170,cc,3+1,j));
    hold on
    confplot(t(171:end), result2(171:end,cc,5+1,j), resulterr2(171:end,cc,5+1,j), resulterr2(171:end,cc,5+1,j));
    hold on
    confplot(t(1:170), result2(1:170,cc,3+1,j+6), resulterr2(1:170,cc,3+1,j+6), resulterr2(1:170,cc,3+1,j+6));
    hold on
    confplot(t(171:end), result2(171:end,cc,5+1,j+6), resulterr2(171:end,cc,5+1,j+6), resulterr2(171:end,cc,5+1,j+6));
    hold on
    plot(t, shufresult2(:,cc,1,j));
    hold off
    xline((find(t_proj==0)-20)/30)
    xline((find(t_proj==0)-145-20)/30)
    ylim([0.05 0.5])
    title('lick')
end


figure(3)

result2 = nanmean(result,5);
cc = 1;
for j = 1:12
    subplot(4,3,j)
     
    plot(t, result2(:,cc,7,j));
    hold on 
    plot(t, result2(:,cc,6,j));
    plot(t, result2(:,cc,5,j));
    hold off
    %     xline((find(t_proj==0)-20)/30)
%     xline((find(t_proj==0)-145-20)/30)
    ylim([0.05 0.5])
    title('reward')
end


%%

result3 = nanmean(result2,4);
t=[1:298]/30;
for i= 3:size(result2,3)
    figure(i)
    plot(t, movmean(result3(:,1:3,i),5,1))
    xline((find(t_proj==0)-20)/30)
    xline((find(t_proj==0)-145-20)/30)
    ylim([0 0.5])
    title(ttt{i})
end

maxidx = [];
result4=[];
for i = 3:size(result2,3)
    for j = 1:2
        temp = movmean(result3(:,j,i),5,1);
        if i < 5
            [h idx] = max(temp(1:(find(t_proj==0)+ ...
                30-145)));
        else
            [h idx] = max(temp);
        end
        maxidx(i,j) = idx;
        result4(1,j,i,:,:) = result(idx,j,i,:,:);
    end
end
% result4 = permute(result4, [3 4 2 5 1]);


for i= 3:size(result2,3)
    figure(i)
    for j = 1:size(result2,4)
        subplot(4,3,j)
        bar(nanmean(result4(:,1:2,i,j,:),5));
        ylim([0 0.5])
    end
end

for i= 3:size(result2,3)
    figure(i)
    for j = 1:2
        subplot(1,2,j)
        imagesc(nanmean(result4(i,:,j,:),4))

    end
end

%% UI
result = [];
counter = 1;
for p = 1:size(control,1)  %     for p = 1:size(c21,1)
    try
        counter
        temp = controlweightsui{p}; %  temp = c21weights{p}; 
        load([smroot() 'Analysis/proj/full-resid_stim/' control{p,1} '-' num2str(control{p,2}) '-CCA_proj_full-resid_stim.mat']) % [release]               
        if size(temp,2) >= 298
            for m = 1:size(idx,1) % svm weight
                temp2 = CCA_coeff{idx(m,1),idx(m,2)};
                for j = 1:2
                    ccweight = temp2(:,j);
                    for i = 1:298 %size(temp,2)
                        for k = 1:size(temp,4)  %%
                            svweight = temp(:,i,idx(m,3),k);                            
                            r = corrcoef(ccweight, svweight);
                            result(i,j,k,m,counter) = abs(r(1,2));    %r(1,2)^2;                            
                        end
                    end
                end
            end
            counter = counter + 1;
        end
    catch
    end
end

ttt={'sample I','sample U','test I','test U'};

result2 = nanmean(resultUI,5);
% t=[1:298]/30;
t=1:298;
for i= 1:size(result2,3)
    figure(i)
    for j = 1:size(result2,4)
        subplot(4,3,j)
        plot(t, movmean(result2(:,1,i,j),5,1));
        hold on
        hold off
        ylim([0.05 0.5])
        title(ttt{i})
    end
end

%% BINNED U I
sampleresult2 = nanmean(mean(resultUI(100:110,:,:,:,:),1),5);
testresult2 = nanmean(mean(resultUI(250:260,:,:,:,:),1),5);
samplesstd2 = nanstd(mean(resultUI(100:110,:,:,:,:),1),[],5)./sqrt(size(resultUI,5));
teststd2 = nanstd(mean(resultUI(250:260,:,:,:,:),1),[],5)./sqrt(size(resultUI,5));

figure
for j = 1:6
    subplot(2,3,j)
    a = [sampleresult2(1,1,1,j), testresult2(1,1,3,j);
        sampleresult2(1,1,1,j+6), testresult2(1,1,3,j+6)];
   hb = bar(a);  hold on
   for k = 1:length(hb)
        x = hb(k).XEndPoints; y = hb(k).YEndPoints;       
        if k == 1
            err = [samplesstd2(1,1,1,j) samplesstd2(1,1,1,j+6)];
        else
            err = [teststd2(1,1,3,j) teststd2(1,1,3,j+6)];
        end     
        errorbar(x, y, err, 'k', 'linestyle', 'none', 'LineWidth', 1);
    end
    ylim([0 0.5]); title('intersection')
end


figure
for j = 1:6
    subplot(2,3,j)
    a = [sampleresult2(1,1,2,j), testresult2(1,1,4,j);
        sampleresult2(1,1,2,j+6), testresult2(1,1,4,j+6)];
   hb = bar(a);  hold on
   for k = 1:length(hb)
        x = hb(k).XEndPoints; y = hb(k).YEndPoints;       
        if k == 1
            err = [samplesstd2(1,1,2,j) samplesstd2(1,1,2,j+6)];
        else
            err = [teststd2(1,1,4,j) teststd2(1,1,4,j+6)];
        end     
        errorbar(x, y, err, 'k', 'linestyle', 'none', 'LineWidth', 1);
    end
    ylim([0 0.5]); title('union')
end
%% BINNED STIM LICK
sampleresult2 = nanmean(mean(result(100:110,:,:,:,:),1),5);
testresult2 = nanmean(mean(result(250:260,:,:,:,:),1),5);
samplesstd2 = nanstd(mean(result(100:110,:,:,:,:),1),[],5)./sqrt(size(result,5));
teststd2 = nanstd(mean(result(250:260,:,:,:,:),1),[],5)./sqrt(size(result,5));

figure
for j = 1:6
    subplot(2,3,j)
    a = [sampleresult2(1,1,3,j), testresult2(1,1,5,j);
        sampleresult2(1,1,3,j+6), testresult2(1,1,5,j+6)];
   hb = bar(a);  hold on
   for k = 1:length(hb)
        x = hb(k).XEndPoints; y = hb(k).YEndPoints;       
        if k == 1
            err = [samplesstd2(1,1,3,j) samplesstd2(1,1,3,j+6)];
        else
            err = [teststd2(1,1,5,j) teststd2(1,1,5,j+6)];
        end     
        errorbar(x, y, err, 'k', 'linestyle', 'none', 'LineWidth', 1);
    end
    ylim([0 0.5]); title('stimulus')
end


figure
for j = 1:6
    subplot(2,3,j)
    a = [sampleresult2(1,1,4,j), testresult2(1,1,6,j);
        sampleresult2(1,1,4,j+6), testresult2(1,1,6,j+6)];
   hb = bar(a);  hold on
   for k = 1:length(hb)
        x = hb(k).XEndPoints; y = hb(k).YEndPoints;       
        if k == 1
            err = [samplesstd2(1,1,4,j) samplesstd2(1,1,4,j+6)];
        else
            err = [teststd2(1,1,6,j) teststd2(1,1,6,j+6)];
        end     
        errorbar(x, y, err, 'k', 'linestyle', 'none', 'LineWidth', 1);
    end
    ylim([0 0.5]); title('choice')
end


 %% STATS
 for j = 1:12
     [h p(j,1)] = ttest2(mean(resultUI(100:110, 1,1,j,:)), mean(resultUI(250:260, 1,3,j,:))); % intersection
     [h p(j,2)] = ttest2(mean(resultUI(100:110, 1,2,j,:)), mean(resultUI(250:260, 1,4,j,:))); % union
     [h p(j,3)] = ttest2(mean(result(100:110, 1,3,j,:)), mean(result(250:260, 1,5,j,:))); % stimulus
     [h p(j,4)] = ttest2(mean(result(100:110, 1,4,j,:)), mean(result(250:260, 1,6,j,:))); % lick
 end
 
 
 for i = 1:4
    p(:,i) = bonf_holm( p(:,i));
 end
 
107
256



idx = [1,1,1; % S1 S2   
    2,1,1; % S1 M1A
    3,1,1; % S1 M1B
     6,1,3; % M1A M1B
    4,1,2; % S2 M1A
    5,1,2; % S2 M1B
    1,2,2; % S2 S1    
    2,2,3; % M1A S1
    3,2,4; % M1B S1
    6,2,4; % M1B M1A
    4,2,3; % M1A S2
    5,2,4; % M1B S2
    ];

