sm_assert_writable(); % [release] this script writes into the data tree; refuses to run against the lab's working copy
load([smroot() 'Analysis/summary.mat'], 'control') % [release] was load('summary.mat') from Analysis/

for i = 1:size(control,1)
    try
        i
        CCA_dir = [smroot() 'Analysis/proj/full-resid_stim/'];
        load([CCA_dir control{i,1} '-' num2str(control{i,2}) '-CCA_proj_full-resid_stim.mat'], 'CCA_coeff');

        PCA_dir = [smroot() 'Analysis/preprocessing/'];
        load([PCA_dir control{i,1} '-' num2str(control{i,2}) '_preprocess_pca.mat'], 'PCA_coeff');

        % 'S1-S2'	'S1-M1_A'	'S1-M1_B'	'S2-M1_A'	'S2-M1_B'	'M1_A-M1_B'
        dim1_coef = {};
        dim1_coef{1,1} = PCA_coeff{1}(:,1:30)*CCA_coeff{1,1}(:,1);
        dim1_coef{1,2} = PCA_coeff{2}(:,1:30)*CCA_coeff{1,2}(:,1);
        dim1_coef{2,1} = PCA_coeff{1}(:,1:30)*CCA_coeff{2,1}(:,1);
        dim1_coef{2,2} = PCA_coeff{3}(:,1:30)*CCA_coeff{2,2}(:,1);
        dim1_coef{3,1} = PCA_coeff{1}(:,1:30)*CCA_coeff{3,1}(:,1);
        dim1_coef{3,2} = PCA_coeff{4}(:,1:30)*CCA_coeff{3,2}(:,1);
        dim1_coef{4,1} = PCA_coeff{2}(:,1:30)*CCA_coeff{4,1}(:,1);
        dim1_coef{4,2} = PCA_coeff{3}(:,1:30)*CCA_coeff{4,2}(:,1);
        dim1_coef{5,1} = PCA_coeff{2}(:,1:30)*CCA_coeff{5,1}(:,1);
        dim1_coef{5,2} = PCA_coeff{4}(:,1:30)*CCA_coeff{5,2}(:,1);
        dim1_coef{6,1} = PCA_coeff{3}(:,1:30)*CCA_coeff{6,1}(:,1);
        dim1_coef{6,2} = PCA_coeff{4}(:,1:30)*CCA_coeff{6,2}(:,1);

        save([CCA_dir control{i,1} '-' num2str(control{i,2}) '-CCA_proj_full-resid_stim.mat'], 'dim1_coef', '-append');
    catch
    end
end


%%

% 'S1-S2'	'S1-M1_A'	'S1-M1_B'	'S2-M1_A'	'S2-M1_B'	'M1_A-M1_B'

counter = 1;
retro = [];
for i = 1:size(control,1)
    try
        counter
        CCA_dir = [smroot() 'Analysis/proj/full-resid_stim/'];
        load([CCA_dir control{i,1} '-' num2str(control{i,2}) '-CCA_proj_full-resid_stim.mat'], 'dim1_coef');

        ses_dir = [[smroot() 'Animals/'] control{i,1} '\'];
        clear CaA2
        clear CaA3
        load([ses_dir control{i,1} '-' num2str(control{i,2}) '.mat']); %,'CaA2','CaA3');        
        r = corrcoef(dim1_coef{2,2},double(CaA2.celltype_REF_angle)); retro(2,2,counter) = r(1,2);
        r = corrcoef(dim1_coef{3,2},double(CaA3.celltype_REF_angle)); retro(3,2,counter) = r(1,2);
        r = corrcoef(dim1_coef{4,2},double(CaA2.celltype_REF_angle)); retro(4,2,counter) = r(1,2);
        r = corrcoef(dim1_coef{5,2},double(CaA3.celltype_REF_angle)); retro(5,2,counter) = r(1,2);
        r = corrcoef(dim1_coef{6,1},double(CaA2.celltype_REF_angle)); retro(6,1,counter) = r(1,2);
        r = corrcoef(dim1_coef{6,2},double(CaA3.celltype_REF_angle)); retro(6,2,counter) = r(1,2);
        counter = counter + 1;
    catch
% [control{i,1} '-' num2str(control{i,2})]
    end
end

figure; cdfplot(retro(2,2,:)); title('M1A (S1)')
figure; cdfplot(retro(3,2,:)); title('M1B (S1)')
figure; cdfplot(retro(4,2,:)); title('M1A (S2)')
figure; cdfplot(retro(5,2,:)); title('M1B (S2)')
figure; cdfplot(retro(6,1,:)); title('M1A (M1B)')
figure; cdfplot(retro(6,2,:)); title('M1B (M1A)')

kkk = nanmean(abs(retro),3);
%%

counter = 1;
retro = [];
for i = 1:size(control,1)
    try
        counter
        CCA_dir = [smroot() 'Analysis/proj/full-resid_stim/'];
        load([CCA_dir control{i,1} '-' num2str(control{i,2}) '-CCA_proj_full-resid_stim.mat'], 'dim1_coef');

        ses_dir = [[smroot() 'Animals/'] control{i,1} '\'];
        clear CaA2
        clear CaA3
        load([ses_dir control{i,1} '-' num2str(control{i,2}) '.mat']); %,'CaA2','CaA3');        
        r = dim1_coef{2,2}; retro(2,2,1,counter) = nanmean(abs(r(CaA2.celltype_REF_angle==1))); retro(2,2,2,counter) = nanmean(abs(r(CaA2.celltype_REF_angle==0)));
        r = dim1_coef{3,2}; retro(3,2,1,counter) = nanmean(abs(r(CaA3.celltype_REF_angle==1))); retro(3,2,2,counter) = nanmean(abs(r(CaA3.celltype_REF_angle==0)));
        r = dim1_coef{4,2}; retro(4,2,1,counter) = nanmean(abs(r(CaA2.celltype_REF_angle==1))); retro(4,2,2,counter) = nanmean(abs(r(CaA2.celltype_REF_angle==0)));
        r = dim1_coef{5,2}; retro(5,2,1,counter) = nanmean(abs(r(CaA3.celltype_REF_angle==1))); retro(5,2,2,counter) = nanmean(abs(r(CaA3.celltype_REF_angle==0)));
        r = dim1_coef{6,1}; retro(6,1,1,counter) = nanmean(abs(r(CaA2.celltype_REF_angle==1))); retro(6,1,2,counter) = nanmean(abs(r(CaA2.celltype_REF_angle==0)));
        r = dim1_coef{6,2}; retro(6,2,1,counter) = nanmean(abs(r(CaA3.celltype_REF_angle==1))); retro(6,2,2,counter) = nanmean(abs(r(CaA3.celltype_REF_angle==0)));
        counter = counter + 1;
    catch
% [control{i,1} '-' num2str(control{i,2})]
    end
end

figure; bar(permute(retro(2,2,:), [3 2 1])); title('M1A (S1)')
figure; bar(permute(retro(3,2,:), [3 2 1])); title('M1B (S1)')
figure; bar(permute(retro(4,2,:), [3 2 1])); title('M1A (S2)')
figure; bar(permute(retro(5,2,:), [3 2 1])); title('M1B (S2)')
figure; bar(permute(retro(6,1,:), [3 2 1])); title('M1A (M1B)')
figure; bar(permute(retro(6,2,:), [3 2 1])); title('M1B (M1A)')
