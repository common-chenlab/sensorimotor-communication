function [predict_labels, acc, Ws, biases] = wsvmmodel_cross_shuffles(data,data1,Y1, w, shuffledata)
% 3/14/2014 - Talayeh Razzaghi and Petros Xanthopoulos - Industral Engineering and Management Systems, University of central Florida - talayeh.razzaghi@gmail.com            
%                                                                                                
% INPUT:                                                                                                                                      
% data: time series data with label and weights, If we run SVM, the weights for all data samples are one                          
% a: the size of Normal class
% b: the size of abnormal class                           
% w: window length                                   
% t: parameter of abnormal pattern                             
% mod: if mod==1 SVM is running elseif mod==2 WSVM is running                                      
                                     
% OUTPUT:                                                                                          
% meanSensitivity: the average of sensitivity over 10-fold cross-validation
% meanSpecificity: the average of specificity over 10-fold cross-validation
% meanAccuracy: the average of Accuracy over 10-fold cross-validation
% meanGmean: the average of Gmean over 10-fold cross-validation

% Data Normalization
datanorm = data(:,1:w);       
data(:,1:w) = datanorm;                
classes = data(:,w+1);                 
Attributes = data(:,1:w);            
weight = data(:,w+2);                                    
ACC = [];
Sensitivity=[];
Specificity=[];
Gmean =[];
Ws = [];
biases = [];
% 10-fold Cross-validation
predict_labels =[];
if shuffledata == 1
    rep = 2;
    classes = classes(randperm(length(classes)));
else
    rep = 10;
end
for i = 1:rep    
    r=randperm(numel(classes));
    tot=floor(numel(classes)*0.9);   % It selects 90% of data for training and 10% for testing      
    train=(r(1:tot));           %train=data(r(1:tot),:);
    test=(r(tot+1:end)); 
    model = svmtrain(classes(train),Attributes(train,:),'-s 0 -t 0 -c 10 -g 0.015618');      %SVM   

    weight = model.sv_coef'*model.SVs;    
    bias = mean(model.sv_coef-(model.SVs*weight'));
    Ws = [Ws; weight];
    biases = [biases; bias];
    
%     if shuffledata == 1        
%         tempdata1 = data1(:,randperm(size(data1,2)));
%     else
        tempdata1 = data1;
%     end
    if isempty(Y1)==0
        [pl, acc] = svcpredict_test(Y1, tempdata1, [1:length(Y1)], model, Y1);
    else
        [pl, acc] = svcpredict_test(classes(test), Attributes(test,:), [1:length(test)], model, classes(test));
    end
    ACC = [ACC; acc];
    predict_labels = [predict_labels, pl];
end
%  figure; bar(nanmean(Ws,1))
predict_labels = nanmean(predict_labels,2);
acc = nanmean(ACC,1);
Ws = nanmean(Ws,1);
biases = nanmean(biases,1);
    
    % shuffles = nanmean(shuffles);

