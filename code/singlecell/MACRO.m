
%% BINNED
load([smroot() 'Analysis/lick_analysis/choice.mat'])
load([smroot() 'Analysis/summary.mat'])

S1 = {};
S2 = {};
M1A = {};
M1B = {};
parfor i = 1:size(control,1)
    try
        disp(i)
        [pS1, pS2, pM1A, pM1B] = MAIN_SC_BINNED(control{i,1}, num2str(control{i,2}), control_choice(i));         
        S1{i} = pS1;
        S2{i} = pS2;
        M1A{i} = pM1A;
        M1B{i} = pM1B;       
    catch
    end
end

%%
anm = [1 10 ;
11 18 ;
19 25 ;
26 32 ;
33 38 ;
39 44];

sumS1=[];
sumS2=[];
sumM1A=[];
sumM1B=[];
for i = 1:size(anm,1)
    [a, b] = summarize_area(S1([anm(i,1):anm(i,2)]),ref);
    sumS1(i,:,1) = a;
    sumS1(i,:,2) = b;
    [a, b] = summarize_area(S2([anm(i,1):anm(i,2)]),ref);
    sumS2(i,:,1) = a;
    sumS2(i,:,2) = b;
    [a, b] = summarize_area(M1A([anm(i,1):anm(i,2)]),ref);
    sumM1A(i,:,1) = a;
    sumM1A(i,:,2) = b;
    [a, b] = summarize_area(M1B([anm(i,1):anm(i,2)]),ref);
    sumM1B(i,:,1) = a;
    sumM1B(i,:,2) = b;
end

multibar(firstlevel(1:4,1:4)',firstlevel(5:8,1:4)','probe - all ')
multibar(firstlevel(1:4,5:8)',firstlevel(5:8,5:8)','goal - all')
multibar(secondlevel(1:4,1:2)',secondlevel(5:8,1:2)','probe - choice')
multibar(secondlevel(1:4,13:14)',secondlevel(5:8,13:14)','goal - choice')
multibar(secondlevel(1:4,3:4)',secondlevel(5:8,3:4)','probe - stim')
multibar(secondlevel(1:4,15:16)',secondlevel(5:8,15:16)','goal - stim')
multibar(secondlevel(1:4,5:8)',secondlevel(5:8,5:8)','probe - intersection')
multibar(secondlevel(1:4,17:20)',secondlevel(5:8,17:20)','goal - intersection')
multibar(secondlevel(1:4,9:12)',secondlevel(5:8,9:12)','probe - union')
multibar(secondlevel(1:4,21:24)',secondlevel(5:8,21:24)','goal - union')

%% 2 way anova
statsum =[];
for i = 1:12
    clear data
    data = [];
    data = cat(3, data, permute(sumS1(:,i,:), [1 3 2]));
    data = cat(3, data, permute(sumS2(:,i,:), [1 3 2]));
    data = cat(3, data, permute(sumM1A(:,i,:), [1 3 2]));
    data = cat(3, data, permute(sumM1B(:,i,:), [1 3 2]));
    
    [nSamples, nA, nB] = size(data);
    
    % Reshape data into a column vector
    y = data(:);
    
    % Create grouping variables    
    groupA = [1 1 1 1 1 1 2 2 2 2 2 2];
    groupA = [groupA, groupA]; groupA = [groupA, groupA]';
    groupB = [1 1 1 1 1 1 1 1 1 1 1 1];
    groupB = [groupB, 2 2 2 2 2 2 2 2 2 2 2 2];
    groupB = [groupB, 3 3 3 3 3 3 3 3 3 3 3 3];
    groupB = [groupB, 4 4 4 4 4 4 4 4 4 4 4 4]';
     
    % Perform 2-way ANOVA
    [p, tbl, stats] = anovan(y, {groupA, groupB}, ...
        'model', 'interaction', ...
        'varnames', {'CategoryA', 'CategoryB'});
    
    % Extract p-value for Category A (first row after header)
    p_CategoryA = tbl{2, 7};  % p-value for Category A
    
    fprintf('Category A p-value: %.4f\n', p_CategoryA);
    fprintf('Category A F-statistic: %.4f\n', tbl{2, 6});
    statsum(i,1) =  p_CategoryA;
    statsum(i,2) =  tbl{2, 6};
    % Perform post-hoc multiple comparisons for Category A if significant
%     if p_CategoryA < 0.05
%         figure;
%         [c, m, h, gnames] = multcompare(stats, 'Dimension', 1);
%         title('Multiple Comparisons for Category A');
%     end
end
%%
sumS1x(:,1,:) = sum(sumS1(:,1:2,:),2); sumS1x(:,2,:) = sum(sumS1(:,3:4,:),2); sumS1x(:,3,:) = sum(sumS1(:,5:8,:),2); sumS1x(:,4,:) = sum(sumS1(:,9:12,:),2);
sumS2x(:,1,:) = sum(sumS2(:,1:2,:),2); sumS2x(:,2,:) = sum(sumS2(:,3:4,:),2); sumS2x(:,3,:) = sum(sumS2(:,5:8,:),2); sumS2x(:,4,:) = sum(sumS2(:,9:12,:),2);
sumM1Ax(:,1,:) = sum(sumM1A(:,1:2,:),2); sumM1Ax(:,2,:) = sum(sumM1A(:,3:4,:),2); sumM1Ax(:,3,:) = sum(sumM1A(:,5:8,:),2); sumM1Ax(:,4,:) = sum(sumM1A(:,9:12,:),2);
sumM1Bx(:,1,:) = sum(sumM1B(:,1:2,:),2); sumM1Bx(:,2,:) = sum(sumM1B(:,3:4,:),2); sumM1Bx(:,3,:) = sum(sumM1B(:,5:8,:),2); sumM1Bx(:,4,:) = sum(sumM1B(:,9:12,:),2);

statsum =[];
for i = 1:4
    clear data
    data = [];
    data = cat(3, data, permute(sumS1x(:,i,:), [1 3 2]));
    data = cat(3, data, permute(sumS2x(:,i,:), [1 3 2]));
    data = cat(3, data, permute(sumM1Ax(:,i,:), [1 3 2]));
    data = cat(3, data, permute(sumM1Bx(:,i,:), [1 3 2]));
    
    [nSamples, nA, nB] = size(data);
    
    % Reshape data into a column vector
    y = data(:);
    
    % Create grouping variables    
    groupA = [1 1 1 1 1 1 2 2 2 2 2 2];
    groupA = [groupA, groupA]; groupA = [groupA, groupA]';
    groupB = [1 1 1 1 1 1 1 1 1 1 1 1];
    groupB = [groupB, 2 2 2 2 2 2 2 2 2 2 2 2];
    groupB = [groupB, 3 3 3 3 3 3 3 3 3 3 3 3];
    groupB = [groupB, 4 4 4 4 4 4 4 4 4 4 4 4]';
     
    % Perform 2-way ANOVA
    [p, tbl, stats] = anovan(y, {groupA, groupB}, ...
        'model', 'interaction', ...
        'varnames', {'CategoryA', 'CategoryB'});
    
    % Extract p-value for Category A (first row after header)
    p_CategoryA = tbl{2, 7};  % p-value for Category A
    
    fprintf('Category A p-value: %.4f\n', p_CategoryA);
    fprintf('Category A F-statistic: %.4f\n', tbl{2, 6});
    statsum(i,1) =  p_CategoryA;
    statsum(i,2) =  tbl{2, 6};
    % Perform post-hoc multiple comparisons for Category A if significant
%     if p_CategoryA < 0.05
%         figure;
%         [c, m, h, gnames] = multcompare(stats, 'Dimension', 1);
%         title('Multiple Comparisons for Category A');
%     end
end



M1Atype = {};
M1Btype = {};
for i = 1:size(control,1)
    try        
        load([[smroot() 'Animals/'] control{i,1} '\' control{i,1} '-' num2str(control{i,2}) '.mat'],'CaA2','CaA3');
        M1Atype{i} = CaA2.celltype_REF_angle;
        M1Btype{i} = CaA3.celltype_REF_angle;
    catch        
    end
end



anm = [1 10 ;
11 18 ;
19 25 ;
26 32 ;
33 38 ;
39 44];


sumM1=[];
for i = 1:size(anm,1)
    [a, b] = summarize_area_mCherry(M1A([anm(i,1):anm(i,2)]),M1Atype([anm(i,1):anm(i,2)]),M1B([anm(i,1):anm(i,2)]),M1Btype([anm(i,1):anm(i,2)]),ref,1);
    sumM1(i,:,1) = a; %mCherry sample
    sumM1(i,:,2) = b; %mCherry test
    [a, b] = summarize_area_mCherry(M1A([anm(i,1):anm(i,2)]),M1Atype([anm(i,1):anm(i,2)]),M1B([anm(i,1):anm(i,2)]),M1Btype([anm(i,1):anm(i,2)]),ref,0);
    sumM1(i,:,3) = a; %no mCherry sample
    sumM1(i,:,4) = b; %no mCherry test  
end

% sumM1 = nanmean(sumM1,1);
% figure; bar(permute(sumM1(:,[1 2 3 4 5 6 7 8 12 11 10 9],[1 3 2 4]),[3 2 1])')
% xticklabels(ref_label([1 2 3 4 5 6 7 8 12 11 10 9]));
% legend('mCherry+ probe', 'ctl probe', 'mCherry+ goal', 'ctl goal')
% add standard error mean  error bars

% Calculate mean and SEM
sumM1_mean = nanmean(sumM1,1);
sumM1_sem = nanstd(sumM1,[],1) ./ sqrt(sum(~isnan(sumM1),1));

% Prepare data for plotting
plot_order = [1 2 3 4 5 6 7 8 12 11 10 9];
% plot_order = [1 2 3 4];
data_mean = permute(sumM1_mean(:,plot_order,[1 3 2 4]),[3 2 1]);
data_sem = permute(sumM1_sem(:,plot_order,[1 3 2 4]),[3 2 1]);

% Create bar plot
figure; 
h = bar(data_mean');
hold on;

% Add error bars
ngroups = size(data_mean, 2);
nbars = size(data_mean, 1);
groupwidth = min(0.8, nbars/(nbars + 1.5));

for i = 1:nbars
    x = (1:ngroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*nbars);
    errorbar(x, data_mean(i,:), data_sem(i,:), 'k', 'linestyle', 'none', 'LineWidth', 1);
end

% xticklabels({'Stim','Choice','Intersection','Union'});
xticklabels(ref_label(plot_order));
legend('mCherry+ probe', 'ctl probe', 'mCherry+ goal', 'ctl goal')
hold off;

testsumM1 = sumM1(:,plot_order,:);
stattest = [];
for i = 1:12
    stattest(i,1) = ttest(testsumM1(:,1,1),testsumM1(:,1,2));
    stattest(i,2) = ttest(testsumM1(:,1,3),testsumM1(:,1,4));
end
%% total N
anm = [1 10 ;
11 18 ;
19 25 ;
26 32 ;
33 38 ;
39 44];

result = [];
for i = 1:44
    result(i,1) = sum(M1Atype{i});    
    result(i,2) = length(M1Atype{i});
    result(i,3) = sum(M1Btype{i});
    result(i,4) = length(M1Btype{i});
end

summary = [];
for i = 1:6
    summary(i,1) = sum(result([anm(i,1):anm(i,2)],1))+sum(result([anm(i,1):anm(i,2)],3));
    summary(i,2) = sum(result([anm(i,1):anm(i,2)],2))+sum(result([anm(i,1):anm(i,2)],4));
end
summary(:,3) = summary(:,1)./summary(:,2);
nanmean(summary(:,3)) %  20.8 
nanstd(summary(:,3))/sqrt(6) % 6.2

%%
ptS1=[];
ptS2=[];
ptM1A=[];
ptM1B=[];
for i = 1:size(anm,1)
    ptS1(:,:,i) = summarize_area_probe_test(S1([anm(i,1):anm(i,2)]),ref);
    ptS2(:,:,i) = summarize_area_probe_test(S2([anm(i,1):anm(i,2)]),ref);
    ptM1A(:,:,i) = summarize_area_probe_test(M1A([anm(i,1):anm(i,2)]),ref);
    ptM1B(:,:,i) = summarize_area_probe_test(M1B([anm(i,1):anm(i,2)]),ref);
end
figure(1); imagesc(nanmean(ptS1,3)); title('S1'); daspect([1 1 1])
xticks([1:13]); xticklabels([{''}; ref_label]); xtickangle(90);
yticks([1:13]); yticklabels([{''}; ref_label]);
figure(2); imagesc(nanmean(ptS2,3)); title('S2'); daspect([1 1 1])
xticks([1:13]); xticklabels([{''}; ref_label]); xtickangle(90);
yticks([1:13]); yticklabels([{''}; ref_label]);
figure(3); imagesc(nanmean(ptM1A,3)); title('M1A'); daspect([1 1 1])
xticks([1:13]); xticklabels([{''}; ref_label]); xtickangle(90);
yticks([1:13]); yticklabels([{''}; ref_label]);
figure(4); imagesc(nanmean(ptM1B,3)); title('M1B'); daspect([1 1 1])
xticks([1:13]); xticklabels([{''}; ref_label]); xtickangle(90);
yticks([1:13]); yticklabels([{''}; ref_label]);


%%  CCA weights

S1id = {};
for i = 1:length(S1)
    S1id{i} = assign_area(S1{i},ref);
end

S2id = {};
for i = 1:length(S2)
    S2id{i} = assign_area(S2{i},ref);
end

M1Aid = {};
for i = 1:length(M1A)
    M1Aid{i} = assign_area(M1A{i},ref);
end
M1Bid = {};
for i = 1:length(M1A)
    M1Bid{i} = assign_area(M1B{i},ref);
end

idweights = {};
idx = [1,2;1,3;1,4;2,3;2,4;3,4];
for i = 1:length(S1)
   
    temp = {};
    try
    for j=1:6
        t = idx(j,1);
        if t == 1
            tt = S1id{i};
        elseif t == 2
            tt = S2id{i};
        elseif t == 3
            tt = M1Aid{i};
        elseif t == 4
            tt = M1Bid{i};
        end
        temp{j,1} = idCCA(tt,CCAweights{i}{j,1});
          t = idx(j,2);
        if t == 1
            tt = S1id{i};
        elseif t == 2
            tt = S2id{i};
        elseif t == 3
            tt = M1Aid{i};
        elseif t == 4
            tt = M1Bid{i};
        end
        temp{j,2} = idCCA(tt,CCAweights{i}{j,2});
    end
    catch
    end
    idweights{i} = temp;
end

anm = [1 10 ;
11 18 ;
19 25 ;
26 32 ;
33 38 ;
39 44];

result = cell(6, 2);
for r = 1:6
    for c = 1:2
        animalData = nan(6, 12, 2);
        for a = 1:size(anm, 1)
            allNeurons = [];
            for i = anm(a,1):anm(a,2)
                if isempty(idweights{i}) || size(idweights{i},1) < r || size(idweights{i},2) < c
                    continue
                end
                w = idweights{i}{r,c};
                if ~isempty(w)
                    allNeurons = cat(1, allNeurons, w);
                end
            end
            if ~isempty(allNeurons)
                animalData(a,:,:) = nanmean(allNeurons, 1);
            end
        end
        result{r,c} = animalData;  % (6 x 12 x 2)
    end
end



result = cell(6, 2);
for r = 1:6
    for c = 1:2
%         animalData = nan(6, 12, 2);
%         for a = 1:size(anm, 1)
            allNeurons = [];
            for i = 1:length(idweights)
                if isempty(idweights{i}) || size(idweights{i},1) < r || size(idweights{i},2) < c
                    continue
                end
                w = idweights{i}{r,c};
                if ~isempty(w)
                    allNeurons = cat(1, allNeurons, w);
                end
%             end
%             if ~isempty(allNeurons)
%                 animalData(a,:,:) = nanmean(allNeurons, 1);
%             end
            end
        result{r,c} = allNeurons;  % (6 x 12 x 2)
    end
end


counter = 1
for j = 1:6
    figure(j)
    for i = 1:2
        subplot(1,2,i) %  subplot(1,2,counter)
        bar(permute(nanmean(result{j,i},1),[2 3 1]))
        xticklabels(ref_label)
        xtickangle(90)
        counter = counter + 1;
        ylim([0 0.9])
    end
end



