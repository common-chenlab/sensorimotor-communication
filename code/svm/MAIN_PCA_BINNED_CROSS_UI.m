function acc = MAIN_PCA_BINNED_CROSS_UI(animal, session, all)

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

sampletime = [95:125];
testtime = [242:272];

for j = 1:length(act_align)
    data = act_align{j};
    data = permute(data, [3 2 1]);   %trials X cells X time
    data = data(tr_include{1},1:30,:);
    for k = 1:8
        if k == 1 % sample stim
            newdata = nanmean(data(:,:,sampletime),3);  % sample
            ix1 = find(all.stim<3);
            ix2 = find(all.stim>2);
        elseif k == 2 % sample choice
            newdata = nanmean(data(:,:,sampletime),3);  % sample
            ix1 = find(all.all>(3/100));
            ix2 = find(all.all<=(3/100));
        elseif k == 3  % test stim
            newdata = nanmean(data(:,:,testtime),3); % test
            ix1 = find(all.stim==1|all.stim==3);
            ix2 = find(all.stim==2|all.stim==4);
        elseif k == 4  % test choice
            newdata = nanmean(data(:,:,testtime),3); % test
            ix1 = find(all.choice==1|all.choice==4);
            ix2 = find(all.choice==2|all.choice==3);
        elseif k == 5  % sample intersection
            newdata = nanmean(data(:,:,sampletime),3);  % sample
            ix1 = find(all.all>=(3/100)&all.stim<3);
            ix2 = find(all.all<=(3/100)|all.stim>2);
        elseif k == 6  % sample union
            newdata = nanmean(data(:,:,sampletime),3);  % sample
            ix1 = find(all.all>=(3/100)|all.stim<3);
            ix2 = find(all.all<=(3/100)&all.stim>2);
        elseif k == 7 % test intersection
            newdata = nanmean(data(:,:,testtime),3); % test
            ix1 = find(all.choice==1);
            ix2 = find(all.choice~=1);
        elseif k == 8 % test union
            newdata = nanmean(data(:,:,testtime),3); % test
            ix1 = find(all.choice~=3);
            ix2 = find(all.choice==3);
        end

        [type1, type2] = balance_idx(ix1, ix2);
        newdata = [newdata(type1,:); newdata(type2,:)];
        Y = [ones(length(type1), 1); zeros(length(type1), 1)];

        for m = 1:8
            if m == 1 % sample stim
                ix1 = find(all.stim<3);
                ix2 = find(all.stim>2);
            elseif m == 2 % sample choice
                ix1 = find(all.all>(3/100));
                ix2 = find(all.all<=(3/100));
            elseif m == 3  % test stim
                ix1 = find(all.stim==1|all.stim==3);
                ix2 = find(all.stim==2|all.stim==4);
            elseif m == 4  % test choice
                ix1 = find(all.choice==1|all.choice==4);
                ix2 = find(all.choice==2|all.choice==3);
            elseif m == 5  % sample intersection
                ix1 = find(all.all>=(3/100)&all.stim<3);
                ix2 = find(all.all<=(3/100)|all.stim>2);
            elseif m == 6 % sample union
                ix1 = find(all.all>=(3/100)|all.stim<3);
                ix2 = find(all.all<=(3/100)&all.stim>2);
            elseif m == 7 % test intersection
                ix1 = find(all.choice==1);
                ix2 = find(all.choice~=1);
            elseif m == 8 % test union
                ix1 = find(all.choice~=3);
                ix2 = find(all.choice==3);
            end
            for i = 1:2
                if i == 1
                    newdata2 = nanmean(data([ix1;ix2],1:30,sampletime),3);
                else
                    newdata2 = nanmean(data([ix1;ix2],1:30,testtime),3);
                end
                ix3 = [ones(length(ix1),1); zeros(length(ix2),1)];
                [predict_labels1, Accuracy, Ws, biases]= prepare_run(newdata, Y, newdata2, ix3,0,0);
                acc(j,i,m,k) = Accuracy; % area, time, tested, trained
            end
        end
    end
end






