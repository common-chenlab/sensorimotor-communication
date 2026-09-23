function CCA = cca_coeff_2_roi(CCA, CCA_mat)
if nargin < 2, CCA_mat = []; end
params = CCA(1).params;
if isfield(CCA, 'pca')
    PCA_result = CCA(1).pca;
    for cmp = 1:params.comp.n
        PCA_coeff_src = PCA_result.coeff{params.comp.ind(cmp,1)}(:,1:params.n_PC);
        PCA_coeff_tgt = PCA_result.coeff{params.comp.ind(cmp,2)}(:,1:params.n_PC);
        for ev = 1:size(CCA,1)
            for fld = 1:(find(strcmpi(params.field_names, 'proj'))-1)
                CCA(ev,cmp).(params.field_names(fld)).A_roi = nan(size(PCA_coeff_src,1), params.n_PC, params.n_step, params.n_delay);
                CCA(ev,cmp).(params.field_names(fld)).B_roi = nan(size(PCA_coeff_tgt,1), params.n_PC, params.n_step, params.n_delay);
                for tp = 1:size(CCA(ev,cmp).(params.field_names(fld)).A,3) % params.n_step
                    for dl = 1:params.n_delay
                        CCA(ev,cmp).(params.field_names(fld)).A_roi(:,:,tp,dl) = PCA_coeff_src*CCA(ev,cmp).(params.field_names(fld)).A(:,:,tp,dl);
                        CCA(ev,cmp).(params.field_names(fld)).B_roi(:,:,tp,dl) = PCA_coeff_tgt*CCA(ev,cmp).(params.field_names(fld)).B(:,:,tp,dl);
                    end
                end
            end
            if ~isempty(CCA_mat)
                fprintf('\nUpdating %s (%s)\n', CCA_mat.Properties.Source, CCA(ev,cmp).data_name);
                CCA_mat.CCA(ev,cmp) = CCA(ev,cmp);
            end
        end
    end
else
    fprintf('pca field not found!')
end
%{
PC_test = [1, 0, 0; 1, 1, 0; 0,0 1; 0, 1, 1]
A_test = [1,0,0; 0.1,1,0; 0,0,1]
PC_test*A_test % this is the way
A_test*PC_test'  % wrong
%}