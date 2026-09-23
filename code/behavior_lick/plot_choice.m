control = [];
for i = 1:length(control_choice)
    control = [control; ...
        sum(control_choice(i).all>(3/100)&control_choice(i).stim<3)/sum(control_choice(i).stim<3),...
        sum(control_choice(i).all>(3/100)&control_choice(i).stim>2)/sum(control_choice(i).stim>2),...
        sum(control_choice(i).choice==1)/sum(control_choice(i).choice<3),...
        sum(control_choice(i).choice==4)/sum(control_choice(i).choice>2)];
end 


c21 = [];
for i = 1:length(c21_choice)
    c21 = [c21; ...
        sum(c21_choice(i).all>(3/100)&c21_choice(i).stim<3)/sum(c21_choice(i).stim<3),...
        sum(c21_choice(i).all>(3/100)&c21_choice(i).stim>2)/sum(c21_choice(i).stim>2),...
        sum(c21_choice(i).choice==1)/sum(c21_choice(i).choice<3),...
        sum(c21_choice(i).choice==4)/sum(c21_choice(i).choice>2)];
end 

x = 1:4;
data = nanmean(control,1);
errhigh = nanstd(control,1)/sqrt(size(control,1));
errlow  = nanstd(control,1)/sqrt(size(control,1));
bar(x,data)                
hold on
er = errorbar(x,data,errlow,errhigh);    
er.Color = [0 0 0];                            
er.LineStyle = 'none';  
hold off
xticklabels({'A - sample','P - sample','A - test','P -test'});
title('control')

figure;
x = 1:4;
data = nanmean(c21,1);
errhigh = nanstd(c21,1)/sqrt(size(c21,1));
errlow  = nanstd(c21,1)/sqrt(size(c21,1));
bar(x,data)                
hold on
er = errorbar(x,data,errlow,errhigh);    
er.Color = [0 0 0];                            
er.LineStyle = 'none';  
hold off
xticklabels({'A - sample','P - sample','A - test','P -test'});
title('c21')




%%

for j = 1:4
    control = [];
    for i = 1:length(control_choice)
        if j == 1
            idx = find(control_choice(i).all>(3/100)&control_choice(i).stim<3);
        elseif j == 2
            idx = find(control_choice(i).all<=(3/100)&control_choice(i).stim<3);
        elseif j == 3
            idx = find(control_choice(i).all>(3/100)&control_choice(i).stim>2);
        elseif j == 4
            idx = find(control_choice(i).all<=(3/100)&control_choice(i).stim>2);
        end
        st = control_choice(i).stim(idx);
        ch = control_choice(i).choice(idx);
        control = [control; ...
%             sum(ch==1)/length(idx),...
%             sum(ch==2)/length(idx),...
%             sum(ch==3)/length(idx),...
%             sum(ch==4)/length(idx)];
         sum(ch==1)/sum(ch==1|ch==2),...
            sum(ch==2)/sum(ch==1|ch==2),...
            sum(ch==3)/sum(ch==3|ch==4),...
            sum(ch==4)/sum(ch==3|ch==4)];
    end
    
    
    x = 1:4;
    data = nanmean(control,1);
    errhigh = nanstd(control,1)/sqrt(size(control,1));
    errlow  = nanstd(control,1)/sqrt(size(control,1));
    subplot(2,2,j)
    bar(x,data)
    hold on
    er = errorbar(x,data,errlow,errhigh);
    er.Color = [0 0 0];
    er.LineStyle = 'none';
    hold off
    xticklabels({'Hit','Miss','CR','FA'});
    ylim([0 1])
    if j == 1
        title('A lick sample')
    elseif j == 2
        title('A no lick sample')
    elseif j == 3
        title('P lick sample')
    elseif j == 4
        title('P no lick sample')
    end
end

