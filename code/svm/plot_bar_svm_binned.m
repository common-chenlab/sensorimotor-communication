function plot_bar_svm_binned(rrr,testtime, testcondition, trainedcondition, titletext,sss)



if isempty(trainedcondition)
    data = nanmean(rrr(:,testtime, testcondition, :),4);
    err = nanstd(rrr(:,testtime, testcondition, :),[],4)/sqrt(size(rrr,4));

    temp = sss(testtime, :, :, testcondition, :);

    data2 = permute(rrr(:,testtime, testcondition, :), [4 1 2 3]);
    subjects = [1:size(data2,1)]'; % Subject IDs

    % Creating the table for repeated measures ANOVA
    T = table(subjects, data2(:, 1), data2(:, 2), data2(:, 3), data2(:, 4),'VariableNames', {'Subject', 'S1', 'S2', 'M1A' 'M1B'});

    % Define the within-subjects factor
    within = table({'S1'; 'S2'; 'M1A'; 'M1B'}, 'VariableNames', {'Condition'});

    % Repeated measures ANOVA
    rm = fitrm(T, 'S1-M1B ~ Subject', 'WithinDesign', within);

    % Display the results of repeated measures ANOVA
    ranovaResult = ranova(rm);
    disp('Results of repeated measures ANOVA:');
    disp(ranovaResult);

    % Post-hoc multiple comparisons
    mc = multcompare(rm, 'Condition', 'ComparisonType', 'tukey-kramer');
    disp('Post-hoc multiple comparisons results:');
    disp(mc);


    lll = [];
    for i= 1:size(temp,3)

        for j= 1:size(temp,5)
            lll(i,j) = prctile(temp(1,:,i,1,j), 95);
        end
    end
    lll = nanmean(lll,2);

else
    data = nanmean(rrr(:,testtime, testcondition, trainedcondition,:),5);
    err = nanstd(rrr(:,testtime, testcondition, trainedcondition,:),[],5)/sqrt(size(rrr,5));
    lll = err;
end


figure;
x = [1:4];
bar(x,data)

hold on

er = errorbar(x,data,data-lll,err);
er.Color = [0 0 0];
er.LineStyle = 'none';

hold off

ylim([0.5 0.9])
title(titletext)
xticklabels({'S1','S2','M1A','M1B'})