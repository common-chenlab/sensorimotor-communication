function rrr = BATCH_IFI_mCherry(control, ses, mCherry)

% [release] path handled by startup_sm.m: addpath('Z:\Dropbox\Dropbox\Chen Lab Team Folder\Projects\Sensorimotor\Scripts\CCA')
% [release] path handled by startup_sm.m: addpath('Z:\Dropbox\Dropbox\Chen Lab Team Folder\Projects\Sensorimotor\Scripts\correlation')
% [release] path handled by startup_sm.m: addpath('Z:\Dropbox\Dropbox\Chen Lab Team Folder\Analysis Suite\PIPELINE\misc')
load([smroot() 'Analysis/lick_analysis/choice.mat']);
load([smroot() 'Analysis/summary.mat'])
% 
animal = control{ses,1}; % 'sm045'
session = num2str(control{ses,2}); %'4'
all = control_choice(ses);
% 
% 
% % Load exported data
% % load(['Z:\Dropbox\Dropbox\Chen Lab Team Folder\Projects\Sensorimotor\Analysis\proj\full-no_cherry-resid_stim\' animal '-' session '-CCA_proj_full-no_cherry-resid_stim.mat'], 'act_proj','comp');
% load(['Z:\Dropbox\Dropbox\Chen Lab Team Folder\Projects\Sensorimotor\Analysis\proj\full-drop_noncherry-resid_stim\' animal '-' session '-CCA_proj_full-drop_noncherry-resid_stim.mat'], 'act_proj','comp');
% 
% load 
% path1 = 'Z:\Dropbox\Chen Lab Dropbox\Chen Lab Team Folder\Projects\Sensorimotor\Analysis\preprocessing\';
% name1 = [animal '-' session '_preprocess_pca.mat'];
% load([path1 name1])
% % load('choice.mat')

CCA_dir = [smroot() 'Analysis/proj/full-resid_stim/'];
load([CCA_dir animal '-' num2str(session) '-CCA_proj_full-resid_stim.mat'],'comp','CCA_coeff');

mCherry_dir = [smroot() 'Analysis/preprocessing/mCherry/'];
if mCherry == 1
    load([mCherry_dir animal '-' num2str(session) '_preprocess_pca_suppress_mch.mat']);
elseif mCherry == 0
    load([mCherry_dir animal '-' num2str(session) '_preprocess_pca_suppress_ctrl.mat']);
elseif mCherry == 2
    load([mCherry_dir animal '-' num2str(session) '_preprocess_pca_suppress_noncherry.mat']);
end

idx = [1 1 2;
    2 1 3;
    3 1 4;
    4 2 3;
    5 2 4;
    6 3 4];

act_proj={};
for j = 1:size(idx,1)
    coef1 = CCA_coeff{idx(j,1),1};
    temp1 = act_resid{idx(j,2)};
    coef2 = CCA_coeff{idx(j,1),2};
    temp2 = act_resid{idx(j,3)};
    result1 = [];
    result2 = [];
    for i=1:size(temp2,1) %time
        for k=1:6
            result1(i,k,:)=permute(temp1(i,1:30,:),[3 2 1])*coef1(:,k);
            result2(i,k,:)=permute(temp2(i,1:30,:),[3 2 1])*coef2(:,k);
        end
    end
    act_proj{j,1} = result1;
    act_proj{j,2} = result2;
end

%%
[c2 ia2 ib2] = intersect(tr_include{1}, all.trialno, 'stable');
all.all = all.all(ib2);
all.choice = all.choice(ib2);
all.stim = all.stim(ib2);
tr_include{1} = tr_include{1}(ia2);

ix{1} = find(all.stim<3&all.all>(3/100));
ix{2} = find(all.stim<3&all.all<=(3/100));
ix{3} = find(all.stim>2&all.all<=(3/100));
ix{4} = find(all.stim>2&all.all>(3/100));
ix{5} = find(all.choice==1);
ix{6} = find(all.choice==2);
ix{7} = find(all.choice==3);
ix{8} = find(all.choice==4);
ix{9} = [1:length(all.all)];

% set parameters for calculating IFI
% IFI_params = set_CCA_params('name','', 'BinWidth',1, 'WindowLength',15, 'TimeStep',3, 'DelayStep',3, 'MaxDelay',12); % units of FRAMES. SM data is 30 Hz

IFI_params = set_CCA_params('name','', 'BinWidth',1, 'WindowLength',15, 'TimeStep',1, 'DelayStep',3, 'MaxDelay',12); % units of FRAMES. SM data is 30 Hz

rrr = [];
for ppp = 1:length(ix)
    temp = act_proj;
    for i = 1:size(temp,1)
        for j = 1:size(temp,2)
            temp{i,j} = temp{i,j}(:,:,ix{ppp});
        end
    end
    % Calculate IFIbeta (# steps x # dimensions x # comparisons)
    [IFIbeta, high, low, ~] = calculate_IFIbeta(temp, comp, IFI_params, false);
    rrr(:,:,:,ppp, 1) = IFIbeta;
    rrr(:,:,:,ppp, 2) = high;
    rrr(:,:,:,ppp, 3) = low;
end

%rrr(timepoint,   ,  , 

