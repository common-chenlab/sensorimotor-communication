
load([smroot() 'Analysis/summary.mat'])
load([smroot() 'Analysis/lick_analysis/choice.mat'])


rrr=[];
counter = 1;
for n = 1:size(control,1)
    n
    try
        rrr(:,:,:,:,counter) = compile_correlation(control{n,1}, num2str(control{n,2}), control_choice(n));
        counter = counter + 1;
        size(rrr);
    catch
    end
end


t = (1:size(rrr,2))/30;
for m = 1:6
    figure(m);
    for i = 1:4
        plot(nanmean(rrr(3,:,m,i,:),5))
        hold on
    end
    hold off
    legend({'sample a lick','sample a no lick','sample p no lick','sample p lick'});    
    ylim([0 0.7])
end
for m = 1:6
    figure(m+6);
    for i = 5:8
        plot(nanmean(rrr(3,:,m,i,:),5))
        hold on
    end
    hold off
    legend({'test a lick','test a no lick','test p no lick','test p lick'});   
    ylim([0 0.7])
end

m = 1
subplot(2,2,1)
for i = 1:4
    plot(movmean(eett(:,i,2,m,1),10))
    hold on
end
hold off
subplot(2,2,3)
for i = 1:4
    plot(nanmean(rrr(2,:,m,i,:),5))
    hold on
end
hold off
subplot(2,2,2)
for i = 5:8
    plot(movmean(eett(:,i,2,m,1),10))
    hold on
end
hold off
subplot(2,2,4)
for i = 5:8
    plot(nanmean(rrr(2,:,m,i,:),5))
    hold on
end
hold off

%% FIGURE

rrr=[];
counter = 1;
for n = 1:size(control,1)
    n
    try
        rrr(:,:,:,:,counter) = compile_correlation_binned(control{n,1}, num2str(control{n,2}), control_choice(n));
        counter = counter + 1;
        size(rrr);
    catch
    end
end
sss=nanmean(rrr,5);
sss = permute(sss, [3 4 1 2]);
ttt=nanstd(rrr,[],5)/sqrt(size(rrr,5));
ttt = permute(ttt, [3 4 1 2]);
figure; 
subplot(3,2,1)
bar(sss(:,1:4,1,1)); ylim([0 0.7])
subplot(3,2,3)
bar(sss(:,1:4,2,1)); ylim([0 0.7])
subplot(3,2,5)
bar(sss(:,1:4,3,1)); ylim([0 0.7])
subplot(3,2,2)
bar(sss(:,5:8,1,2)); ylim([0 0.7])
subplot(3,2,4)
bar(sss(:,5:8,2,2)); ylim([0 0.7])
subplot(3,2,6)
bar(sss(:,5:8,3,2)); ylim([0 0.7])

x = {'A lick','A no lick','P lick','P no lick'};
y = {'S1:S2','M1A:M1B','S1:M1A','S1:M1B','S2:M1A','S2:M1B'};
figure(1); imagesc(sss([1 6 2 3 4 5],[1 2 4 3],1,1)); caxis([0.15 0.7]); xticklabels(x); yticklabels(y); title('Probe CC1'); colorbar; colormap('jet'); daspect([1 1 1]);
figure(2); imagesc(sss([1 6 2 3 4 5],[5 6 8 7],1,2)); caxis([0.15 0.7]); xticklabels(x); yticklabels(y); title('Test CC1'); colorbar; colormap('jet'); daspect([1 1 1]);
figure(3); imagesc(sss([1 6 2 3 4 5],[1 2 4 3],2,1)); caxis([0.15 0.5]); xticklabels(x); yticklabels(y); title('Probe CC2'); colorbar; colormap('jet'); daspect([1 1 1]);
figure(4); imagesc(sss([1 6 2 3 4 5],[5 6 8 7],2,2)); caxis([0.15 0.5]); xticklabels(x); yticklabels(y); title('Test CC2'); colorbar; colormap('jet'); daspect([1 1 1]);
figure(5); imagesc(sss([1 6 2 3 4 5],[1 2 4 3],3,1)); caxis([0.15 0.4]); xticklabels(x); yticklabels(y); title('Probe CC3'); colorbar; colormap('jet'); daspect([1 1 1]);
figure(6); imagesc(sss([1 6 2 3 4 5],[5 6 8 7],3,2)); caxis([0.15 0.4]); xticklabels(x); yticklabels(y); title('Test CC3'); colorbar; colormap('jet'); daspect([1 1 1]);


x = {'Probe','Goal'};
names = {'A lick','A no lick','P lick','P no lick'};
y = {'S1:S2','M1A:M1B','S1:M1A','S1:M1B','S2:M1A','S2:M1B'};
vvv = permute(sss,[1 4 2 3]);
idx = [1,5;2,6;4,8;3,7];

for j = 1:3
    figure(j)
    for i = 1:4
        temp = [sss([1 6 2 3 4 5],idx(i,1),j,1), sss([1 6 2 3 4 5],idx(i,2),j,2)];
        subplot(1,4,i)
        imagesc(temp);
        xticks([1:2]);
        xticklabels(x); yticklabels(y); title('Probe CC1'); colorbar; colormap('jet'); daspect([1 1 1]);
        caxis([0.15 0.7]);
%         if j == 1
%             caxis([0.15 0.7]);
%         elseif j == 2
%             caxis([0.15 0.5]);
%         elseif j == 3
%             caxis([0.15 0.4]);
%         end
        title([names{i} ' CC' num2str(j)]);
    end
end


trials = {'A lick','A no lick','P no lick','P lick'};
y = {'S1:S2','M1A:M1B','S1:M1A','S1:M1B','S2:M1A','S2:M1B'};

for i = 1:4
    figure(i);
    temp = [sss([1 6 2 3 4 5],i,1,1), sss([1 6 2 3 4 5],i+4,1,2)];
    errors = [ttt([1 6 2 3 4 5],i,1,1), ttt([1 6 2 3 4 5],i+4,1,2)];
    b = bar(temp);
    title(trials{i});
    xticklabels(y);
    ylim([0 0.7]);

    % Add error bars
    hold on;
    numGroups = size(temp, 1);
    numBars = size(temp, 2);
    groupWidth = min(0.8, numBars/(numBars + 1.5)); % Calculate group width

    for j = 1:numBars
        % Calculate center of each bar
        x = (1:numGroups) - groupWidth/2 + (2*j-1) * groupWidth / (2*numBars);
        errorbar(x, temp(:, j), errors(:, j), '.k', 'LineWidth', 1); % Add error bars
    end
    hold off;
end

%% stats
uuu = permute(rrr, [5 3 4 1 2]);

areas = [1 6 2 3 4 5];
ppp = [];
for i = 1:4
    for j = 1:length(areas)
        [h p] = ttest2(uuu(:,areas(j),i,1,1), uuu(:,areas(j),i+4,1,2));
        ppp(i,j) = p;
    end
end
