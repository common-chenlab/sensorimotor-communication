function [predict_label, acc] = svcpredict_test(classes, data, test, model, test_l)

% Attributes = zscore(data);
Attributes = data;

[predict_label, accuracy, prob_estimates] = svmpredict(classes(test), Attributes(test,:), model);

%% weighted accuracy
idx0 = find(test_l==0);
idx1 = find(test_l==1);
acc = 0.5*(sum(predict_label(idx0)==0)/length(idx0)+sum(predict_label(idx1)==1)/length(idx1));