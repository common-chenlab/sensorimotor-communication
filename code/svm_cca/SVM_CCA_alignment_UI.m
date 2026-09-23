load([smroot() 'Analysis/summary.mat']);
% load('Z:\Dropbox\Dropbox\Chen Lab Team Folder\Projects\Sensorimotor\Analysis\svm\CONTROLCROSSTEST_REWARD.mat', 'controlweights')
load([smroot() 'Analysis/svm/PCA_BINNED.mat']);
% [release] path handled by startup_sm.m: addpath('Z:\Dropbox\Chen Lab Dropbox\Chen Lab Team Folder\Analysis Suite\Data Visualization');

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
    1,2,2; % S2 S1    
    2,1,1; % S1 M1A
    2,2,3; % M1A S1
    3,1,1; % S1 M1B
    3,2,4; % M1B S1
    6,1,3; % M1A M1B
    6,2,4; % M1B M1A
    4,1,2; % S2 M1A
    4,2,3; % M1A S2
    5,1,2; % S2 M1B
    5,2,4; % M1B S2
    ];


%% GET UI BINNED
result = [];
shufresult = [];
counter = 1;

for p = 1:size(control,1)  %     for p = 1:size(c21,1)
    try
        counter
        temp = pcabinnedweightsui{p}; %  temp = c21weights{p}; 
        load([smroot() 'Analysis/proj/full-resid_stim/' control{p,1} '-' num2str(control{p,2}) '-CCA_proj_full-resid_stim.mat']) % [release]               
        if size(temp,2) == 2
            for m = 1:size(idx,1) % svm weight
                temp2 = CCA_coeff{idx(m,1),idx(m,2)};
                for j = 1:3
                    ccweight = temp2(:,j);
                    for i = 1:2 %size(temp,2)
                        for k = 1:size(temp,4)  %%
                            svweight = temp(:,i,idx(m,3),k);
                            r = corrcoef(ccweight, svweight);
                            result(i,j,k,m,counter) = r(1,2)^2;  %abs(r(1,2));    %r(1,2)^2;                                                                                  result(i,j,k,m,counter) =  rad2deg(subspace(ccweight, svweight));
                            shuf = [];
                            for n = 1:100
                                r = corrcoef(ccweight(randperm(length(ccweight))), svweight(randperm(length(svweight))));
                                shuf = [shuf; r(1,2)^2];
                            end
                            shufresult(i,j,k,m,counter) = mean(shuf);  % prctile(shuf,95);  
                        end
                    end
                end
            end
            counter = counter + 1;
        end
    catch
    end
end


%% GET SC BINNED
scresult = [];
scshufresult = [];
counter = 1;

for p = 1:size(control,1)  %     for p = 1:size(c21,1)
    try
        counter
        temp = pcabinnedweights{p}; %  temp = c21weights{p}; 
        load([smroot() 'Analysis/proj/full-resid_stim/' control{p,1} '-' num2str(control{p,2}) '-CCA_proj_full-resid_stim.mat']) % [release]               
        if size(temp,2) == 2
            for m = 1:size(idx,1) % svm weight
                temp2 = CCA_coeff{idx(m,1),idx(m,2)};
                for j = 1:3
                    ccweight = temp2(:,j);
                    for i = 1:2 %size(temp,2)
                        for k = 1:size(temp,4)  %%
                            svweight = temp(:,i,idx(m,3),k);
                            r = corrcoef(ccweight, svweight);
                            scresult(i,j,k,m,counter) = r(1,2)^2; %abs(r(1,2));  
                            shuf = [];
                            for n = 1:100
                                r = corrcoef(ccweight(randperm(length(ccweight))), svweight(randperm(length(svweight))));
                                shuf = [shuf; r(1,2)^2];
                            end
                            scshufresult(i,j,k,m,counter) =  mean(shuf);   % prctile(shuf,95);  
                        end
                    end
                end
            end
            counter = counter + 1;
        end
    catch
    end
end


ttt={'sample intersection','sample union','test intersection','test union'};
result2 = nanmean(result,5);
semresult2 = nanstd(result,[],5)/sqrt(size(result,5));
shufresult2 = nanmean(shufresult,5);

scresult2 = nanmean(scresult,5);
scsemresult2 = nanstd(scresult,[],5)/sqrt(size(scresult,5));
scshufresult2 = nanmean(scshufresult,5);


for i= 1:size(result2,3)
    figure(i)
    for j = 1:size(result2,4)
        subplot(4,3,j)
        if i < 3
        bar(result2(1,:,i,j))
        else
            bar(result2(2,:,i,j))
        end        
        ylim([0.05 0.5])
        title(ttt{i})
    end
end


ttt={'','','sample stim','sample lick','test stim','test lick'};
scresult2 = nanmean(scresult,5);
for i= 3:6
    figure(i+2)
    for j = 1:size(scresult2,4)
        subplot(4,3,j)
        if i < 5
        bar(scresult2(1,:,i,j))
        else
            bar(scresult2(2,:,i,j))
        end
        
        ylim([0.05 0.5])
        title(ttt{i})
    end
end

%% FIGURE BINNED
n = 1
ll = {'S1','S2';          
    'S1','M1A';
    'S1','M1B';
    'M1A','M1B';
    'S2','M1A';
    'S2','M1B'};
    
x = [1:4];
% intersection
figure(1)
k = 1
for j = 1:6
    subplot(2,3,j); 
    temp = [result2(1,n,k,j*2-1), result2(1,n,k,j*2), result2(2,n,k+2,j*2-1), result2(2,n,k+2,j*2)];
    errlow = [shufresult2(1,n,k,j*2-1), shufresult2(1,n,k,j*2), shufresult2(2,n,k+2,j*2-1), shufresult2(2,n,k+2,j*2)];
    errhigh = [semresult2(1,n,k,j*2-1), semresult2(1,n,k,j*2), semresult2(2,n,k+2,j*2-1), semresult2(2,n,k+2,j*2)];
    bar(x, temp); ylim([0 0.3]);
    hold on
    er = errorbar(x,temp,errlow,errhigh);
    er.Color = [0 0 0];
    er.LineStyle = 'none';
    hold off
    title('intersection')
    xticklabels({['probe ' ll{j,1}],['probe ' ll{j,2}], ['test ' ll{j,1}],['test ' ll{j,2}]})
%     legend(ll(j,:))
end

% union
figure(2)
k = 2
for j = 1:6
    subplot(2,3,j); 
    temp = [result2(1,n,k,j*2-1), result2(1,n,k,j*2), result2(2,n,k+2,j*2-1), result2(2,n,k+2,j*2)];
    errlow = [shufresult2(1,n,k,j*2-1), shufresult2(1,n,k,j*2), shufresult2(2,n,k+2,j*2-1), shufresult2(2,n,k+2,j*2)];
    errhigh = [semresult2(1,n,k,j*2-1), semresult2(1,n,k,j*2), semresult2(2,n,k+2,j*2-1), semresult2(2,n,k+2,j*2)];
    bar(x, temp); ylim([0 0.3]);
    hold on
    er = errorbar(x,temp,errlow,errhigh);
    er.Color = [0 0 0];
    er.LineStyle = 'none';
    hold off
    title('union')
    xticklabels({['probe ' ll{j,1}],['probe ' ll{j,2}], ['test ' ll{j,1}],['test ' ll{j,2}]})
%     legend(ll(j,:))
end

figure(3)
k = 3
for j = 1:6
    subplot(2,3,j); 
    temp = [scresult2(1,n,k,j*2-1), scresult2(1,n,k,j*2), scresult2(2,n,k+2,j*2-1), scresult2(2,n,k+2,j*2)];
    errlow = [scshufresult2(1,n,k,j*2-1), scshufresult2(1,n,k,j*2), scshufresult2(2,n,k+2,j*2-1), scshufresult2(2,n,k+2,j*2)];
    errhigh = [scsemresult2(1,n,k,j*2-1), scsemresult2(1,n,k,j*2), scsemresult2(2,n,k+2,j*2-1), scsemresult2(2,n,k+2,j*2)];
    bar(x, temp); ylim([0 0.3]);
    hold on
    er = errorbar(x,temp,errlow,errhigh);
    er.Color = [0 0 0];
    er.LineStyle = 'none';
    hold off
    title('stim')
    xticklabels({['probe ' ll{j,1}],['probe ' ll{j,2}], ['test ' ll{j,1}],['test ' ll{j,2}]})
%     legend(ll(j,:))
end

figure(4)
k = 4
for j = 1:6
    subplot(2,3,j); 
    temp = [scresult2(1,n,k,j*2-1), scresult2(1,n,k,j*2), scresult2(2,n,k+2,j*2-1), scresult2(2,n,k+2,j*2)];
    errlow = [scshufresult2(1,n,k,j*2-1), scshufresult2(1,n,k,j*2), scshufresult2(2,n,k+2,j*2-1), scshufresult2(2,n,k+2,j*2)];
    errhigh = [scsemresult2(1,n,k,j*2-1), scsemresult2(1,n,k,j*2), scsemresult2(2,n,k+2,j*2-1), scsemresult2(2,n,k+2,j*2)];
    bar(x, temp); ylim([0 0.3]);
    hold on
    er = errorbar(x,temp,errlow,errhigh);
    er.Color = [0 0 0];
    er.LineStyle = 'none';
    hold off
    title('choice')
    xticklabels({['probe ' ll{j,1}],['probe ' ll{j,2}], ['test ' ll{j,1}],['test ' ll{j,2}]})
%     legend(ll(j,:))
end

%% STATS
allstat = [];
k = 1
for j = 1:6
    probe1 = result(1,n,k,j*2-1,:); probe1 = permute(probe1, [5 1 2 3 4]);
    probe2 = result(1,n,k,j*2,:); probe2 = permute(probe2, [5 1 2 3 4]);
    test1 = result(2,n,k+2,j*2-1,:); test1 = permute(test1, [5 1 2 3 4]);
    test2 = result(2,n,k+2,j*2,:); test2 = permute(test2, [5 1 2 3 4]);
    [h p1] = ttest(probe1, probe2);
    [h p2] = ttest(test1, test2);
    [h p3] = ttest(probe1, test1);
    [h p4] = ttest(probe2, test2);
    a = bonf_holm([p1 p2 p3]);
    allstat(1,k,j) = a(1);
    a = bonf_holm([p2 p3 p4]);
    allstat(2,k,j) = a(1);
    a = bonf_holm([p3 p1 p2]);
    allstat(3,k,j) = a(1);
    a = bonf_holm([p4 p1 p2]);
    allstat(4,k,j) = a(1);    
    title('intersection')
end

k = 2
for j = 1:6    
    probe1 = result(1,n,k,j*2-1,:); probe1 = permute(probe1, [5 1 2 3 4]);
    probe2 = result(1,n,k,j*2,:); probe2 = permute(probe2, [5 1 2 3 4]);
    test1 = result(2,n,k+2,j*2-1,:); test1 = permute(test1, [5 1 2 3 4]);
    test2 = result(2,n,k+2,j*2,:); test2 = permute(test2, [5 1 2 3 4]);
    [h p1] = ttest(probe1, probe2);
    [h p2] = ttest(test1, test2);
    [h p3] = ttest(probe1, test1);
    [h p4] = ttest(probe2, test2);
    a = bonf_holm([p1 p2 p3]);
    allstat(1,k,j) = a(1);
    a = bonf_holm([p2 p3 p4]);
    allstat(2,k,j) = a(1);
    a = bonf_holm([p3 p1 p2]);
    allstat(3,k,j) = a(1);
    a = bonf_holm([p4 p1 p2]);
    allstat(4,k,j) = a(1); 
    title('union')
end

k = 3
for j = 1:6    
    probe1 = scresult(1,n,k,j*2-1,:); probe1 = permute(probe1, [5 1 2 3 4]);
    probe2 = scresult(1,n,k,j*2,:); probe2 = permute(probe2, [5 1 2 3 4]);
    test1 = scresult(2,n,k+2,j*2-1,:); test1 = permute(test1, [5 1 2 3 4]);
    test2 = scresult(2,n,k+2,j*2,:); test2 = permute(test2, [5 1 2 3 4]);
    [h p1] = ttest(probe1, probe2);
    [h p2] = ttest(test1, test2);
    [h p3] = ttest(probe1, test1);
    [h p4] = ttest(probe2, test2);
    a = bonf_holm([p1 p2 p3]);
    allstat(1,k,j) = a(1);
    a = bonf_holm([p2 p3 p4]);
    allstat(2,k,j) = a(1);
    a = bonf_holm([p3 p1 p2]);
    allstat(3,k,j) = a(1);
    a = bonf_holm([p4 p1 p2]);
    allstat(4,k,j) = a(1); 
    title('stim')
end

k = 4
for j = 1:6
    probe1 = scresult(1,n,k,j*2-1,:); probe1 = permute(probe1, [5 1 2 3 4]);
    probe2 = scresult(1,n,k,j*2,:); probe2 = permute(probe2, [5 1 2 3 4]);
    test1 = scresult(2,n,k+2,j*2-1,:); test1 = permute(test1, [5 1 2 3 4]);
    test2 = scresult(2,n,k+2,j*2,:); test2 = permute(test2, [5 1 2 3 4]);
    [h p1] = ttest(probe1, probe2);
    [h p2] = ttest(test1, test2);
    [h p3] = ttest(probe1, test1);
    [h p4] = ttest(probe2, test2);
    a = bonf_holm([p1 p2 p3]);
    allstat(1,k,j) = a(1);
    a = bonf_holm([p2 p3 p4]);
    allstat(2,k,j) = a(1);
    a = bonf_holm([p3 p1 p2]);
    allstat(3,k,j) = a(1);
    a = bonf_holm([p4 p1 p2]);
    allstat(4,k,j) = a(1); 
    title('choice')
end

%% GET UI
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
                for j = 1:3
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


%% GET STIM/CHOICE
scresult = [];
counter = 1;
for p = 1:size(control,1)  %     for p = 1:size(c21,1)
    try
        counter
        temp = controlweights{p}; %  temp = c21weights{p}; 
        load([smroot() 'Analysis/proj/full-resid_stim/' control{p,1} '-' num2str(control{p,2}) '-CCA_proj_full-resid_stim.mat']) % [release]               
        if size(temp,2) >= 298
            for m = 1:size(idx,1) % svm weight
                temp2 = CCA_coeff{idx(m,1),idx(m,2)};
                for j = 1:3
                    ccweight = temp2(:,j);
                    for i = 1:298 %size(temp,2)
                        for k = 1:size(temp,4)  %%
                            svweight = temp(:,i,idx(m,3),k);
                            r = corrcoef(ccweight, svweight);
                            scresult(i,j,k,m,counter) = abs(r(1,2));    %r(1,2)^2;
                        end
                    end
                end
            end
            counter = counter + 1;
        end
    catch
    end
end



%%


ttt={'sample intersection','sample union','test intersection','test union'};

scttt={'sample stim (no lick)','sample stim (A only)','sample stim','sample lick','test stim','test lick','reward'};

result2 = nanmean(result,5);
scresult2 = nanmean(scresult,5);
% shufresult2 = nanmean(shufresult,5);
t=[1:298]/30;
for i= 1:size(result2,3)
    figure(i)
    for j = 1:size(result2,4)
        subplot(4,3,j)
        plot(t, movmean(result2(:,2,i,j),5,1));
        hold on
         plot(t, movmean(scresult2(:,2,3,j),5,1));
         plot(t, movmean(scresult2(:,2,4,j),5,1));
         plot(t, movmean(scresult2(:,2,5,j),5,1));
         plot(t, movmean(scresult2(:,2,6,j),5,1));
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
    ylim([0 0.4])
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
