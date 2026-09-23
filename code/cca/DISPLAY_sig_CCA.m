load([smroot() 'Analysis/summary.mat']);
result = [];
counter = 1;
for m = 1:size(control,1)
    try
    load([smroot() 'Analysis/proj/full-resid_stim/' control{m,1} '-' num2str(control{m,2}) '-CCA_proj_full-resid_stim.mat']); % [release]
    rrr = [];
    for i = 1:size(act_proj,1)
        for j = 1:6
            temp=act_proj{i,1}(:,j,:);
            temp = temp(:);
            temp2=act_proj{i,2}(:,j,:);
            temp2 = temp2(:);
            temp(isnan(temp2)) = [];
            temp2(isnan(temp2)) = [];
            temp2(isnan(temp)) = [];
            temp(isnan(temp)) = [];
            r = corrcoef(temp,temp2);
            rrr(i,j) = r(1,2);
        end
    end
    rrr = [rrr, r_thresh'];
    result(:,:,counter) = rrr;
    counter = counter +1;
    catch
    end
end

for i = 1:6
    figure(i)
    bar([1:6],nanmean(result(i,1:6,:),3));
    hold on
    er = errorbar([1:6],nanmean(result(i,1:6,:),3),nanstd(result(i,1:6,:),[],3)/sqrt(size(result,3)),nanstd(result(i,1:6,:),[],3)/sqrt(size(result,3)));
    er.Color = [0 0 0];
    er.LineStyle = 'none';
    yline(nanmean(result(i,7,:),3))
    ylim([0 0.65]);
    hold off
    title(comp_name{i});
    xlabel('CC component')
    ylabel('correlation')
end
%%
load([smroot() 'Analysis/summary.mat']);
load([smroot() 'Analysis/lick_analysis/choice.mat']);

rrr=[];
counter = 1;
for n = 1:size(control,1)
    n
    try
        rrr(:,:,:,:,counter) = compile_correlation(control{n,1}, num2str(control{n,2}), control_choice(n));
        counter = counter + 1;
        size(rrr)
    catch
    end
end

t = (1:size(rrr,2))/30;
for m = 1:6
    figure(m);
    for i = 1:4
%         plot(t,nanmean(rrr(1,:,m,i,:),5));
        ebar = nanstd(rrr(1,:,m,i,:),[],5)/sqrt(size(rrr,5));
        confplot(t, nanmean(rrr(1,:,m,i,:),5),ebar,ebar);
        hold on
    end
    hold off
%     legend({'sample a','sample p','sample lick','sample no lick'});
%     xline((find(t_proj==0)-10)/30)
%     xline((find(t_proj==0)-145-10)/30)
%     xline(74/30);
% xline(220/30);
    ylim([0 0.8]);
    xlim([0.5 9.925]);
    title(comp_name{m})
end

for m = 1:6
    figure(m+6);
    for i = 5:8
        plot(t,nanmean(rrr(1,:,m,i,:),5));
%         ebar = nanstd(rrr(1,:,m,i,:),[],5)/sqrt(size(rrr,5));
%         confplot(t, nanmean(rrr(1,:,m,i,:),5),ebar,ebar);
        hold on
    end
    hold off
%     legend({'test a','test p','test lick','test no lick'});
%     xline((find(t_proj==0)-10)/30)
%     xline((find(t_proj==0)-145-10)/30)
    ylim([0 0.8]);
    xlim([0.5 9.925]);
    title(comp_name{m})
end


%% STATS 
sample = nanmean(rrr(:,85:110,:,9,:),2);
test = nanmean(rrr(:,225:250,:,9,:),2);

sample = nanmean(rrr(:,55:110,:,9,:),2);
test = nanmean(rrr(:,195:250,:,9,:),2);

sample = nanmean(rrr(:,55:85,:,9,:),2);
test = nanmean(rrr(:,195:225,:,9,:),2);


sample = nanmean(rrr(:,85:110,:,9,:),2);
test = nanmean(rrr(:,225:250,:,9,:),2);


result = [];
for i = 1:6
    for j = 1:3        
        [p, table] = anova_rm({permute(sample(j,1,i,1,:),[5 2 1 3 4]) permute(test(j,1,i,1,:),[5 2 1 3 4])});
        result(i,j) = p(2);
    end
end



%%

plot(nanmean(UMAP1,1),nanmean(UMAP2,1))
scatter(nanmean(UMAP1,1),nanmean(UMAP2,1),[], [1:70],'filled')
C = cellstr(decision);
for i = 1:6
    figure(i+6)
    if i == 1
        idx = find(ismember(C,'Hit 1'));
    elseif i == 2
        idx = find(ismember(C,'Hit 2'));
    elseif i == 3
        idx = find(ismember(C,'FA 1'));
    elseif i == 4
        idx = find(ismember(C,'FA 2'));
    elseif i == 5
        idx = find(ismember(C,'Miss 1'));
    elseif i == 6
        idx = find(ismember(C,'Miss 2'));
    end
    

imagesc(sort(watershed(idx,:),1,'descend'))
colormap('hsv')
colorbar
caxis([1 13]);
%     plot(mode(UMAP1(idx,:),1),mode(UMAP2(idx,:),1));
%     hold on
%     scatter(mode(UMAP1(idx,:),1),mode(UMAP2(idx,:),1),[], [1:70],'filled');
%     hold off
%     xlim([-30 30])
%     ylim([-30 30])
%     colorbar
     if i == 1
        title('Hit 1');
    elseif i == 2
        title('Hit 2');
    elseif i == 3
        title('FA 1');
    elseif i == 4
        title('FA 2');
    elseif i == 5
        title('Miss 1');
    elseif i == 6
        title('Miss 2');
     end
%     daspect([1 1 1]);
end

figure
   
    plot(mode(UMAP1,1),mode(UMAP2,1));
    hold on
    scatter(mode(UMAP1,1),mode(UMAP2,1),[], [1:70],'filled');
hold off

aaa = [];
aaa(:,:,1) = UMAP1;
aaa(:,:,2) = UMAP2;
aaa = permute(aaa, [1 3 2]);
aaa = round(aaa);
kkk = [];
for i = 1:69
    a = aaa(:,:,i);
    [u,~,c] = unique(a,'rows');
    [~,ix]=max(accumarray(c,1));
    mdrows=u(ix,:);
    kkk=[kkk; mdrows];
end
figure; scatter(kkk(:,1),kkk(:,2),[], [1:69],'filled');

figure
imagesc(sort(watershed(1:150,:),1,'descend'))
colorbar
colormap('hsv')
caxis([1 13]);
figure
imagesc(sort(watershed(400:end,:),1,'descend'))
colorbar
colormap('hsv')
caxis([1 13]);


for i = 1:size(animals,1)
    try
    load(['video_matrix_' animals{i,1} '_ws.mat'])
figure(i)
% imagesc(sort(watershed((end-400):end,:),1,'descend'))
imagesc(sort(watershed,1,'descend'))
%  imagesc(watershed((end-200):end,:))
% imagesc(watershed)


C = cellstr(decision);
 
idx = find(ismember(C,'Hit 1'));
%         find(ismember(C,'Hit 2'));...
%         find(ismember(C,'FA 1'));...
%         find(ismember(C,'FA 2'))];
% 
%         
%  imagesc(sort(watershed(idx,:),1,'descend'))
colorbar
colormap('hsv')
caxis([1 13]);
id = find(ismember(pca_pheno.SampleID,animals{i,1}));
title([animals{i,1} ' ' num2str(pca_pheno.rankedTrials(id))]);
xline(32)
xline(44)
xline(56)
xline(68)
% xlim([32 68])
    catch 
    end
end

for i = 1:size(animals,1)
    try
    load(['video_matrix_' animals{i,1} '_ws.mat'])
figure(i)


UMAP2(isnan(UMAP2)) = 0;
imagesc(corrcoef(UMAP2(400-end:end,:)));

% C = cellstr(decision);
% 
% idx = [find(ismember(C,'Hit 1'));...
%         find(ismember(C,'Hit 2'));...
%         find(ismember(C,'FA 1'));...
%         find(ismember(C,'FA 2'))];
% 
%         
% imagesc(UMAP2(idx,:));
colorbar
colormap('jet')
% caxis([1 13]);
id = find(ismember(pca_pheno.SampleID,animals{i,1}));
title([animals{i,1} ' ' num2str(pca_pheno.rankedTrials(id))]);
xline(32)
xline(44)
xline(56)
xline(68)
    catch 
    end
end






figure
imagesc(sort(watershed(400:end,:),1,'descend'))
colorbar
colormap('hsv')

data = [];
for i = 1:13
    data(:,:,i) = double(ww==i);
end