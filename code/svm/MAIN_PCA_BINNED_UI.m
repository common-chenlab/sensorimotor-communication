function [acc, weights, shuf] = MAIN_PCA_BINNED_UI(animal, session, all)

% animal = 'sm041'
% session = '1'
% all = control_choice(1);

% [release] path handled by startup_sm.m: addpath(genpath('Z:\Dropbox\Chen Lab Dropbox\Chen Lab Team Folder\Analysis Suite\Secondary Analysis\svm'));
% [release] path handled by startup_sm.m: addpath('Z:\Dropbox\Dropbox\Chen Lab Team Folder\Analysis Suite\Secondary Analysis\GENERAL_SVM');

load([[smroot() 'Analysis/preprocessing/'] animal '-' session '_preprocess_pca.mat']);
[c2 ia2 ib2] = intersect(tr_include{1}, all.trialno, 'stable');
all.all = all.all(ib2);
all.choice = all.choice(ib2);
all.stim = all.stim(ib2);
tr_include{1} = tr_include{1}(ia2);

acc=[];
weights=[];
shuf=[];
sampletime = [95:125];
testtime = [242:272];

for j = 1:length(act_align)
    data = act_align{j};
    data = permute(data, [3 2 1]);   %trials X cells X time
    data = data(tr_include{1},1:30,:);
    for k = 1:4
        result = [];
        result2 = [];
        result3 = [];

        if k == 1  % sample intersection
            ix1 = find(all.all>=(3/100)&all.stim<3);
            ix2 = find(all.all<=(3/100)|all.stim>2);
        elseif k == 2  % sample union
            ix1 = find(all.all>=(3/100)|all.stim<3);
            ix2 = find(all.all<=(3/100)&all.stim>2);
        elseif k == 3 % test intersection
            ix1 = find(all.choice==1);
            ix2 = find(all.choice~=1);
        elseif k == 4 % test union
            ix1 = find(all.choice~=3);
            ix2 = find(all.choice==3);      
        end
        [type1, type2] = balance_idx(ix1, ix2);

        for i = 1:2
            i
            if i == 1
                newdata = nanmean(data(:,1:30,sampletime),3);
            else
                newdata = nanmean(data(:,1:30,testtime),3);
            end
            newdata = [newdata(type1,:); newdata(type2,:)];
            Y = [ones(length(type1), 1); zeros(length(type2), 1)];
            [predict_labels1, Accuracy, Ws, biases] = prepare_run(newdata, Y, [], [],0,0);
            result = [result, Accuracy];

            
            result2 = [result2, Ws'];

            % shuffle
            for m = 1:100
                [predict_labels1, Accuracy, Ws, biases] = prepare_run(newdata, Y, [], [],0,1);
                result3(i,m) = Accuracy;
            end
        end
        acc(j,:,k) = result;
        weights(:,:,j,k) = result2;
        shuf(:,:,j,k) = result3;
    end
end
