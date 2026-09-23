function result = project_correlation(animal, session, mCherry)


mCherry_dir = [smroot() 'Analysis/preprocessing/mCherry/'];
CCA_dir = [smroot() 'Analysis/proj/full-resid_stim/'];

load([CCA_dir animal '-' num2str(session) '-CCA_proj_full-resid_stim.mat'])

if mCherry == 1
    load([mCherry_dir animal '-' num2str(session) '_preprocess_pca_suppress_mch.mat']);
elseif mCherry == 0    
    load([mCherry_dir animal '-' num2str(session) '_preprocess_pca_suppress_ctrl.mat']);
elseif mCherry == 2
    load([mCherry_dir animal '-' num2str(session) '_preprocess_pca_suppress_noncherry.mat']);    
end

result=[];

idx = [1 1 2;
    2 1 3;
    3 1 4;
    4 2 3;
    5 2 4;
    6 3 4];
    
for j = 1:size(idx,1)
    coef1 = CCA_coeff{idx(j,1),1};
    temp1 = act_resid{idx(j,2)};
    coef2 = CCA_coeff{idx(j,1),2};
    temp2 = act_resid{idx(j,3)};
    for i=1:size(temp2,1)
        x = permute(temp1(i,1:30,:),[3 2 1])*coef1(:,2);
        y = permute(temp2(i,1:30,:),[3 2 1])*coef2(:,2);
        y(isnan(x)) = [];
        x(isnan(x)) = [];
        x(isnan(y)) = [];
        y(isnan(y)) = [];
        r = corrcoef(x,y);
        result(j,i) = r(1,2);
    end
end
