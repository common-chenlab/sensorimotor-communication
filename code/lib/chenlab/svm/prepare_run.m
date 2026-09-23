function [predict_labels, Accuracy, Ws, biases]  = prepare_run(dataTRAIN, Y, tempdata, tempY, performzscore, shuffle)

if performzscore == 1
    dataTRAIN = zscore(dataTRAIN);
    tempdata = zscore(tempdata);
end
%% format test data
if isempty(tempY) == 0
    dataTEST = [tempdata(tempY==1,:); tempdata(tempY==0,:)];
    YTEST = [ones(1, sum(tempY==1)), zeros(1, sum(tempY==0))]';
end
%% format training data
data = [dataTRAIN, Y];
a =sum(Y==1);      % the size of Normal class based on the imbalanced ratio (r)
b =sum(Y==0);      % the size of abnormal class
data(:,end+1) = [1/a*ones(1,a) 1/b*ones(1,b)];
w = size(data,2)-2;

if isempty(tempY) == 0
    [predict_labels, Accuracy, Ws, biases] = wsvmmodel_cross_shuffles(data,dataTEST,YTEST,w,shuffle);
else
    [predict_labels, Accuracy, Ws, biases] = wsvmmodel_cross_shuffles(data,[],[],w,shuffle);
end
