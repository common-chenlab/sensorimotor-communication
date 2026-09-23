load([smroot() 'Analysis/fig1b_opto/choice.mat'], 'control') % [release] was loaded by hand from Figure1-Opto/choice.mat
x = 1:4;
data = nanmean(control,1);
errhigh = nanstd(control,1)/sqrt(size(control,1));
errlow  = nanstd(control,1)/sqrt(size(control,1));

figure
subplot(1,5,1)
bar(x,data)
hold on
er = errorbar(x,data,errlow,errhigh);
er.Color = [0 0 0];
er.LineStyle = 'none';
hold off
xticklabels({'A Probe','A Test','P Probe','P Test'});
% ylim([0 1])

hold on
for i = 1:size(control,1)
    plot([1:2],control(i,1:2),'-o');
    hold on
end

for i = 1:size(control,1)
    plot([3:4],control(i,3:4),'-o');
    hold on
end
hold off
%%


x = 1:3;
data = nanmean(opto,1);
errhigh = nanstd(opto,1)/sqrt(size(opto,1));
errlow  = nanstd(opto,1)/sqrt(size(opto,1));

% figure;
for j = 1:4
    idx = [1:3]+((j-1)*3);
subplot(1,5,j+1)
bar(x,data(idx))
hold on
er = errorbar(x,data(idx),errlow(idx),errhigh(idx));
er.Color = [0 0 0];
er.LineStyle = 'none';
xticklabels({'Ctl','S1','M1'});
ylim([0 1])

hold on
for i = 1:size(opto,1)
    plot([1:3],opto(i,idx),'-o');
    hold on
end
hold off
end

%%
% [release] path handled by startup_sm.m: addpath('C:\Dropbox\Chen Lab Dropbox\Chen Lab Team Folder\Projects\Sensorimotor\Scripts\Mitch')

[h pS1] = ttest(opto(:,1),opto(:,2));
[h pM1] = ttest(opto(:,1),opto(:,3));
bonf_holm([pS1 pM1])

[h pS1] = ttest(opto(:,4),opto(:,5));
[h pM1] = ttest(opto(:,4),opto(:,6));
bonf_holm([pS1 pM1])

[h pS1] = ttest(opto(:,7),opto(:,8));
[h pM1] = ttest(opto(:,7),opto(:,9));
bonf_holm([pS1 pM1])

[h pS1] = ttest(opto(:,10),opto(:,11));
[h pM1] = ttest(opto(:,10),opto(:,12));
bonf_holm([pS1 pM1])

