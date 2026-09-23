
%% BINNED
load([smroot() 'Analysis/lick_analysis/choice.mat'])
load([smroot() 'Analysis/summary.mat'])

pcabinnedacc = {};
pcabinnedweights = {};
pcabinnedshuf = {};
parfor i = 1:size(control,1)
    try
        [acc, weights, shuf] = MAIN_PCA_BINNED(control{i,1}, num2str(control{i,2}), control_choice(i));
        pcabinnedacc{i} = acc;
        pcabinnedweights{i} = weights;
        pcabinnedshuf{i} = shuf;
    catch
    end
end


pcabinnedcrossacc = {};
parfor i = 1:size(control,1)
    try
        acc = MAIN_PCA_BINNED_CROSS(control{i,1}, num2str(control{i,2}), control_choice(i));
        pcabinnedcrossacc{i} = acc
    catch
    end
end

pcabinnedaccui = {};
pcabinnedweightsui = {};
pcabinnedshufui = {};
parfor i = 1:size(control,1)
    try
        [acc, weights, shuf] = MAIN_PCA_BINNED_UI(control{i,1}, num2str(control{i,2}), control_choice(i));
        pcabinnedaccui{i} = acc;
        pcabinnedweightsui{i} = weights;
        pcabinnedshufui{i} = shuf;
    catch
    end
end

pcabinnedcrossaccui = {};
parfor i = 1:size(control,1)
    try
        acc = MAIN_PCA_BINNED_CROSS_UI(control{i,1}, num2str(control{i,2}), control_choice(i));
        pcabinnedcrossaccui{i} = acc
    catch
    end
end



%%  STIMULUS AND CHOICE

rrr = [];
counter = 1;
for i = 1:length(pcabinnedacc)
    try
    rrr(:,:,:,counter) = pcabinnedacc{i};
    counter = counter + 1;
    catch
    end
end

sss = [];
counter = 1;
for i = 1:length(pcabinnedshuf)
    try
    sss(:,:,:,:,counter) = pcabinnedshuf{i};
    counter = counter + 1;
    catch
    end
end

% plot_bar_svm_binned(rrr,1, 1, [], 'sample stim (no lick)');
% plot_bar_svm_binned(rrr,1, 2, [], 'sample choice  (A only)');
plot_bar_svm_binned(rrr,1, 3, [], 'sample stim', sss);
plot_bar_svm_binned(rrr,1, 4, [], 'sample choice', sss);
plot_bar_svm_binned(rrr,2, 5, [], 'test stim', sss);
plot_bar_svm_binned(rrr,2, 6, [], 'test choice', sss);
% plot_bar_svm_binned(rrr,2, 7, [], 'test stim (no lick)');
% plot_bar_svm_binned(rrr,2, 8, [], 'test choice (A only)');
% plot_bar_svm_binned(rrr,2, 9, [], 'reward');

%compare probe and test
idx = [1,3,2,5; 1,4,2,6];
tt = [];
for i = 1:4
    for j = 1:2
        [h p] = ttest(permute(rrr(i,idx(j,1),idx(j,2),:),[4 1 2 3]), permute(rrr(i,idx(j,3),idx(j,4),:),[4 1 2 3]));
        tt(j,i) = p;
    end
end


%% CROSS STIMULUS AND CHOICE
rrr = [];
counter = 1;
for i = 1:length(pcabinnedcrossacc)
    try
    rrr(:,:,:,:,counter) = pcabinnedcrossacc{i};
    counter = counter + 1;
    catch
    end
end

% area, time, tested, trained
% trained
% 1) sample stim  
% 2) sample choice  
% 3) test stim 
% 4) test choice  
% 5) sample stim iso  
% 6) sample choice iso 
% 7) test stim iso 
% 8) test choice iso 

% cross condition stim to choice
plot_bar_svm_binned(rrr,1, 2, 1, 'Stim Sample -> Choice Sample',[]);
plot_bar_svm_binned(rrr,2, 4, 3, 'Stim Test-> Choice Test',[]);
% plot_bar_svm_binned(rrr,1, 2, 5, 'Stim Sample Iso -> Choice Sample');
% plot_bar_svm_binned(rrr,2, 4, 7, 'Stim Test Iso -> Choice Test');

% cross condition choice to stim
plot_bar_svm_binned(rrr,1, 1, 2, 'Choice Sample -> Stim Sample',[]);
plot_bar_svm_binned(rrr,2, 3, 4, 'Choice Test-> Stim Test',[]);
% plot_bar_svm_binned(rrr,1, 1, 6, 'Choice Sample Iso -> Stim Sample');
% plot_bar_svm_binned(rrr,2, 3, 8, 'Choice Test Iso -> Stim Test');

% cross temporal stim
plot_bar_svm_binned(rrr,2, 3, 1, 'Stim Sample -> Stim Test',[]);
plot_bar_svm_binned(rrr,1, 1, 3, 'Stim Test -> Stim Sample',[]);
% plot_bar_svm_binned(rrr,2, 3, 5, 'Stim Sample Iso -> Stim Test');
% plot_bar_svm_binned(rrr,1, 1, 7, 'Stim Test Iso -> Stim Sample');
% plot_bar_svm_binned(rrr,2, 7, 1, 'Stim Sample -> Stim Test Iso');
% plot_bar_svm_binned(rrr,1, 5, 3, 'Stim Test -> Stim Sample Iso');
% plot_bar_svm_binned(rrr,2, 7, 5, 'Stim Sample Iso -> Stim Test Iso');
% plot_bar_svm_binned(rrr,1, 5, 7, 'Stim Test Iso -> Stim Sample Iso');

% cross temporal choice
plot_bar_svm_binned(rrr,2, 4, 2, 'Choice Sample -> Choice Test',[]);
plot_bar_svm_binned(rrr,1, 2, 4, 'Choice Test -> Choice Sample',[]);
% plot_bar_svm_binned(rrr,2, 4, 6, 'Choice Sample Iso -> Choice Test');
% plot_bar_svm_binned(rrr,1, 2, 7, 'Choice Test Iso -> Choice Sample');
% plot_bar_svm_binned(rrr,2, 8, 2, 'Choice Sample -> Choice Test Iso');
% plot_bar_svm_binned(rrr,1, 6, 4, 'Choice Test -> Choice Sample Iso');
% plot_bar_svm_binned(rrr,2, 8, 6, 'Choice Sample Iso -> Choice Test Iso');
% plot_bar_svm_binned(rrr,1, 6, 7, 'Choice Test Iso -> Choice Sample Iso');


%% UNION AND INTERSECTION

rrr = [];
counter = 1;
for i = 1:length(pcabinnedaccui)
    try
    rrr(:,:,:,counter) = pcabinnedaccui{i};
    counter = counter + 1;
    catch
    end
end

sss = [];
counter = 1;
for i = 1:length(pcabinnedshufui)
    try
    sss(:,:,:,:,counter) = pcabinnedshufui{i};
    counter = counter + 1;
    catch
    end
end

plot_bar_svm_binned(rrr,1, 1, [], 'sample intersection', sss);
plot_bar_svm_binned(rrr,1, 2, [], 'sample union', sss);
plot_bar_svm_binned(rrr,2, 3, [], 'test intersection', sss);
plot_bar_svm_binned(rrr,2, 4, [], 'test union', sss);

%compare probe and test
idx = [1,1,2,3; 1,2,2,4];
tt = [];
for i = 1:4
    for j = 1:2
        [h p] = ttest(permute(rrr(i,idx(j,1),idx(j,2),:),[4 1 2 3]), permute(rrr(i,idx(j,3),idx(j,4),:),[4 1 2 3]));
        tt(j,i) = p;
    end
end

        
       


% CROSS UNION AND INTERSECTION
rrr = [];
counter = 1;
for i = 1:length(pcabinnedcrossaccui2)
    try
        rrr(:,:,:,:,counter) = pcabinnedcrossaccui2{i};
        counter = counter + 1;
    catch
    end
end

% cross condition intersection to union
plot_bar_svm_binned(rrr,1, 6, 5, 'Sample Intersection -> Sample Union',[]);
plot_bar_svm_binned(rrr,1, 5, 6, 'Sample Union -> Sample Intersection',[]);
plot_bar_svm_binned(rrr,2, 8, 7, 'Test Intersection -> Test Union',[]);
plot_bar_svm_binned(rrr,2, 7, 8, 'Test Union -> Test Intersection',[]);

% cross temporal intersection to union
plot_bar_svm_binned(rrr,2, 7, 5, 'Sample Intersection -> Test Intersection',[]);
plot_bar_svm_binned(rrr,2, 8, 6, 'Sample Union -> Test Union',[]);
plot_bar_svm_binned(rrr,1, 5, 7, 'Test Intersection -> Sample Intersection',[]);
plot_bar_svm_binned(rrr,1, 6, 8, 'Test Union -> Sample Union',[]);

% area, time, tested, trained
% trained
% 1) sample stim  
% 2) sample choice  
% 3) test stim 
% 4) test choice  
% 5) sample stim iso  
% 6) sample choice iso 
% 7) test stim iso 
% 8) test choice iso 

% cross condition intersection to union
plot_bar_svm_binned(rrr,1, 1, 5, 'Sample Intersection -> Sample Stim',[]);
plot_bar_svm_binned(rrr,1, 2, 5, 'Sample Intersection -> Sample Choice',[]);
plot_bar_svm_binned(rrr,1, 1, 6, 'Sample Union -> Sample Stim',[]);
plot_bar_svm_binned(rrr,1, 2, 6, 'Sample Union -> Sample Choice',[]);
plot_bar_svm_binned(rrr,2, 3, 7, 'Test Intersection -> Test Stim',[]);
plot_bar_svm_binned(rrr,2, 4, 7, 'Test Intersection -> Test Choice',[]);
plot_bar_svm_binned(rrr,2, 3, 8, 'Test Union -> Test Stim',[]);
plot_bar_svm_binned(rrr,2, 4, 8, 'Test Union -> Test Choice',[]);

plot_bar_svm_binned(rrr,1, 5, 1, 'Sample Stim -> Sample Intersection',[]);
plot_bar_svm_binned(rrr,1, 6, 1, 'Sample Stim -> Sample Union',[]);
plot_bar_svm_binned(rrr,1, 5, 2, 'Sample Choice -> Sample Intersection',[]);
plot_bar_svm_binned(rrr,1, 6, 2, 'Sample Choice-> Sample Union',[]);
plot_bar_svm_binned(rrr,2, 7, 3, 'Test Stim -> Test Intersection',[]);
plot_bar_svm_binned(rrr,2, 8, 3, 'Test Stim -> Test Union',[]);
plot_bar_svm_binned(rrr,2, 7, 4, 'Test Choice -> Test Intersection',[]);
plot_bar_svm_binned(rrr,2, 8, 5, 'Test Choice -> Test Union',[]);



% cross temporal condition intersection to union
plot_bar_svm_binned(rrr,2, 3, 5, 'Sample Intersection -> Test Stim',[]);
plot_bar_svm_binned(rrr,2, 4, 5, 'Sample Intersection -> Test Choice',[]);
plot_bar_svm_binned(rrr,2, 3, 6, 'Sample Union -> Test Stim',[]);
plot_bar_svm_binned(rrr,2, 4, 6, 'Sample Union -> Test Choice',[]);
plot_bar_svm_binned(rrr,1, 1, 7, 'Test Intersection -> Sample Stim',[]);
plot_bar_svm_binned(rrr,1, 2, 7, 'Test Intersection -> Sample Choice',[]);
plot_bar_svm_binned(rrr,1, 1, 8, 'Test Union -> Sample Stim',[]);
plot_bar_svm_binned(rrr,1, 2, 8, 'Test Union -> Sample Choice',[]);

plot_bar_svm_binned(rrr,2, 7, 1, 'Sample Stim -> Test Intersection',[]);
plot_bar_svm_binned(rrr,2, 8, 1, 'Sample Stim -> Test Union',[]);
plot_bar_svm_binned(rrr,2, 7, 2, 'Sample Choice -> Test Intersection',[]);
plot_bar_svm_binned(rrr,2, 8, 2, 'Sample Choice-> Test Union',[]);
plot_bar_svm_binned(rrr,1, 5, 3, 'Test Stim -> Sample Intersection',[]);
plot_bar_svm_binned(rrr,1, 6, 3, 'Test Stim -> Sample Union',[]);
plot_bar_svm_binned(rrr,1, 5, 4, 'Test Choice -> Sample Intersection',[]);
plot_bar_svm_binned(rrr,1, 6, 5, 'Test Choice -> Sample Union',[]);


% cross temporal condition intersection to union
plot_bar_svm_binned(rrr,2, 7, 5, 'Sample Intersection -> Test Intersection',[]);
plot_bar_svm_binned(rrr,2, 8, 6, 'Sample Union -> Test Union',[]);
plot_bar_svm_binned(rrr,1, 5, 7, 'Test Intersection -> Sample Intersection',[]);
plot_bar_svm_binned(rrr,1, 6, 8, 'Test Union -> Sample Union',[]);




plot_bar_svm_binned(rrr,1, 1, 5, 'Sample Intersection -> Sample Stim',[]);
plot_bar_svm_binned(rrr,1, 2, 5, 'Sample Intersection -> Sample Choice',[]);
plot_bar_svm_binned(rrr,2, 3, 5, 'Sample Intersection -> Test Stim',[]);
plot_bar_svm_binned(rrr,2, 4, 5, 'Sample Intersection -> Test Choice',[]);
plot_bar_svm_binned(rrr,1, 5, 5, 'Sample Intersection -> Sample Intersection',[]);
plot_bar_svm_binned(rrr,1, 6, 5, 'Sample Intersection -> Sample Union',[]);
plot_bar_svm_binned(rrr,2, 7, 5, 'Sample Intersection -> Test Intersection',[]);
plot_bar_svm_binned(rrr,2, 8, 5, 'Sample Intersection -> Test Union',[]);



plot_bar_svm_binned(rrr,1, 1, 2, 'Sample Choice -> Sample Stim',[]);
plot_bar_svm_binned(rrr,1, 2, 2, 'Sample Choice -> Sample Choice',[]);
plot_bar_svm_binned(rrr,2, 3, 2, 'Sample Choice -> Test Stim',[]);
plot_bar_svm_binned(rrr,2, 4, 2, 'Sample Choice -> Test Choice',[]);
plot_bar_svm_binned(rrr,1, 5, 2, 'Sample Choice -> Sample Intersection',[]);
plot_bar_svm_binned(rrr,1, 6, 2, 'Sample Choice -> Sample Union',[]);
plot_bar_svm_binned(rrr,2, 7, 2, 'Sample Choice -> Test Intersection',[]);
plot_bar_svm_binned(rrr,2, 8, 2, 'Sample Choice -> Test Union',[]);


%%
plot_bar_svm_binned(rrr,1, 1, 7, 'Test Intersection -> Sample Stim',[]);
plot_bar_svm_binned(rrr,1, 2, 7, 'Test Intersection -> Sample Choice',[]);
plot_bar_svm_binned(rrr,2, 3, 7, 'Test Intersection -> Test Stim',[]);
plot_bar_svm_binned(rrr,2, 4, 7, 'Test Intersection -> Test Choice',[]);
plot_bar_svm_binned(rrr,1, 5, 7, 'Test Intersection -> Sample Intersection',[]);
plot_bar_svm_binned(rrr,1, 6, 7, 'Test Intersection -> Sample Union',[]);
plot_bar_svm_binned(rrr,2, 7, 7, 'Test Intersection -> Test Intersection',[]);
plot_bar_svm_binned(rrr,2, 8, 7, 'Test Intersection -> Test Union',[]);


%%
plot_bar_svm_binned(rrr,1, 1, 4, 'Test Choice -> Sample Stim',[]);
plot_bar_svm_binned(rrr,1, 2, 4, 'Test Choice -> Sample Choice',[]);
plot_bar_svm_binned(rrr,2, 3, 4, 'Test Choice -> Test Stim',[]);
plot_bar_svm_binned(rrr,2, 4, 4, 'Test Choice -> Test Choice',[]);
plot_bar_svm_binned(rrr,1, 5, 4, 'Test Choice -> Sample Intersection',[]);
plot_bar_svm_binned(rrr,1, 6, 4, 'Test Choice -> Sample Union',[]);
plot_bar_svm_binned(rrr,2, 7, 4, 'Test Choice -> Test Intersection',[]);
plot_bar_svm_binned(rrr,2, 8, 4, 'Test Choice -> Test Union',[]);

sss = nanmean(rrr,5);
sss = permute(sss, [3 4 2 1]);

for i = 1:4
    ggg = [];
    ggg = [ggg; sss(1,:,1,i)];
    ggg = [ggg; sss(2,:,1,i)];
    ggg = [ggg; sss(3,:,2,i)];
    ggg = [ggg; sss(4,:,2,i)];
    ggg = [ggg; sss(5,:,1,i)];
    ggg = [ggg; sss(6,:,1,i)];
    ggg = [ggg; sss(7,:,2,i)];
    ggg = [ggg; sss(8,:,2,i)];
    idx = [1,6,2,5,3,8,4,7];
    figure; imagesc(ggg(idx,idx))
    conditions = {'Sample Stim','Sample Choice','Test Stim','Test Choice','Sample Intersection','Sample Union','Test Intersection','Test Union'};
    xticklabels(conditions(idx))
    yticklabels(conditions(idx))
    caxis([0.6 0.85]);
    daspect([1 1 1])
    colormap('jet')
end


%% Project back to single neurons
% neurons, time, area, condition
pcabinnedweightsuiproj={}
for i = 1:size(control,1)
    try
        i
        load([[smroot() 'Analysis/preprocessing/'] control{i,1} '-' num2str(control{i,2}) '_preprocess_pca.mat']);
        temp = pcabinnedweightsui{i};

        r={};
        for k = 1:4
            r{k} = [];
            for j = 1:2
                for m = 1:4
                    r{k}(:,j,m) = temp(:,j,k,m)'*PCA_coeff{k}(:,1:30)';
                end
            end
        end
        pcabinnedweightsuiproj{i} = r;
    catch
        
    end
end

pcabinnedweightsproj={}
for i = 1:size(control,1)
    try
        i
        load([[smroot() 'Analysis/preprocessing/'] control{i,1} '-' num2str(control{i,2}) '_preprocess_pca.mat']);
        temp = pcabinnedweights{i};
        r={};
        for k = 1:4
            r{k} = [];
            for j = 1:2
                for m = 1:9
                    r{k}(:,j,m) = temp(:,j,k,m)'*PCA_coeff{k}(:,1:30)';
                end
            end
        end
        pcabinnedweightsproj{i} = r;
    catch       
    end
end

% pcabinnedweightsproj
difz =[]; 
for i = 1:size(control,1)
    try
        load([[smroot() 'Animals/'] control{i,1} '\' control{i,1} '-' num2str(control{i,2}) '.mat'],'CaA3');

%         temp = pcabinnedweightsuiproj{i};        
%         temp = temp{3}(:,2,3);

         temp = pcabinnedweightsproj{i};
        temp = temp{4}(:,2,5);
        temp = zscore(temp);
%         figure;
%         cdfplot(temp(CaA3.celltype_REF_new==1))
%         hold on
%         cdfplot(temp(CaA3.celltype_REF_new==0))

        difz = [difz, mean(temp(CaA3.celltype_REF_new==1))-mean(temp(CaA3.celltype_REF_new==0))];
    catch
        
    end
end

for i = 1:44
    try
        load([[smroot() 'Animals/'] control{i,1} '\' control{i,1} '-' num2str(control{i,2}) '.mat'],'CaA2','CaA3');

        temp = pcabinnedweightsproj{i}{3};
        figure;
        subplot(2,2,1);
        scatter(temp(CaA2.celltype_REF_angle==1,1,3),temp(CaA2.celltype_REF_angle==1,2,5)); hold on; scatter(temp(CaA2.celltype_REF_angle==0,1,3),temp(CaA2.celltype_REF_angle==0,2,5));
        subplot(2,2,2);
        scatter(temp(CaA2.celltype_REF_angle==1,1,4),temp(CaA2.celltype_REF_angle==1,2,6)); hold on; scatter(temp(CaA2.celltype_REF_angle==0,1,4),temp(CaA2.celltype_REF_angle==0,2,6));
        subplot(2,2,3);
        scatter(temp(CaA2.celltype_REF_angle==1,1,3),temp(CaA2.celltype_REF_angle==1,1,4)); hold on; scatter(temp(CaA2.celltype_REF_angle==0,1,3),temp(CaA2.celltype_REF_angle==0,1,4));
        subplot(2,2,4);
        scatter(temp(CaA2.celltype_REF_angle==1,2,5),temp(CaA2.celltype_REF_angle==1,2,6)); hold on; scatter(temp(CaA2.celltype_REF_angle==0,2,5),temp(CaA2.celltype_REF_angle==0,2,6));

        temp = pcabinnedweightsproj{i}{4};
        figure;
        subplot(2,2,1);
        scatter(temp(CaA3.celltype_REF_angle==1,1,3),temp(CaA3.celltype_REF_angle==1,2,5)); hold on; scatter(temp(CaA3.celltype_REF_angle==0,1,3),temp(CaA3.celltype_REF_angle==0,2,5));
        subplot(2,2,2);
        scatter(temp(CaA3.celltype_REF_angle==1,1,4),temp(CaA3.celltype_REF_angle==1,2,6)); hold on; scatter(temp(CaA3.celltype_REF_angle==0,1,4),temp(CaA3.celltype_REF_angle==0,2,6));
        subplot(2,2,3);
        scatter(temp(CaA3.celltype_REF_angle==1,1,3),temp(CaA3.celltype_REF_angle==1,1,4)); hold on; scatter(temp(CaA3.celltype_REF_angle==0,1,3),temp(CaA3.celltype_REF_angle==0,1,4));
        subplot(2,2,4);
        scatter(temp(CaA3.celltype_REF_angle==1,2,5),temp(CaA3.celltype_REF_angle==1,2,6)); hold on; scatter(temp(CaA3.celltype_REF_angle==0,2,5),temp(CaA3.celltype_REF_angle==0,2,6));

    catch
    end
end
