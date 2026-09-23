function rrr = BATCH_IFI(control, control_choice, ses)
% 
animal = control{ses,1}; % 'sm045'
session = num2str(control{ses,2}); %'4'
all = control_choice(ses);
% 

% Load exported data
load([[smroot() 'Analysis/proj/full-resid_stim/'] animal '-' session '-CCA_proj_full-resid_stim.mat'], 'act_proj','comp');
path1 = [smroot() 'Analysis/preprocessing/'];
name1 = [animal '-' session '_preprocess_pca.mat'];
load([path1 name1])
% load('choice.mat')

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