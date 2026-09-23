function S = sm_load_preprocess(animal, session, variant, vars)
% SM_LOAD_PREPROCESS  Load a session's preprocessing file, optionally with M1 neurons silenced.
%
%   S = sm_load_preprocess(animal, session)                  baseline, all variables
%   S = sm_load_preprocess(animal, session, variant)         in-silico silencing variant
%   S = sm_load_preprocess(animal, session, variant, vars)   only the listed variables
%   sm_load_preprocess(...)                                  no output: assigns the variables
%                                                            into the caller, like LOAD
%
%   variant is 'none' (default), 'mch', 'ctrl' or 'noncherry', matching the lab files
%   <animal>-<session>_preprocess_pca_suppress_<variant>.mat that this replaces:
%     'mch'        silence the mCherry+ (projection-labelled) M1 neurons
%     'ctrl'       silence a matched, randomly drawn set of unlabelled M1 neurons
%     'noncherry'  silence every unlabelled M1 neuron
%
%   Why this works. The lab pipeline (activity_PCA.m) made each variant from the SAME PCA fit
%   as the baseline: it zeroed the loadings of the silenced neurons and recomputed the scores,
%   score = X * C_z. The PCA is full rank and C is square and orthonormal, so X = score * C'
%   and the variant scores are an exact linear transform of the baseline scores:
%
%       score_variant = score_baseline * C' * D * C,    D = diag(not silenced)
%
%   Residualisation and trial alignment are linear and act per sample, so the same matrix
%   applies to act_align and act_resid. Only the M1 areas (3 and 4) are touched. The neuron
%   lists, including the random 'ctrl' draw, come from sm_suppress_rois and are the lists the
%   original files were built with, so the result matches those files to about 1e-11
%   (tools/verify/verify_suppress_helper.m).
%
%   Differences from LOADing an original variant file: PCA_coeff is returned unchanged, as it
%   was in those files; CCA_params holds only suppress_mch and roi_suppress, not the full
%   parameter struct, which no analysis reads after this load.

if nargin < 3 || isempty(variant), variant = 'none'; end
if nargin < 4, vars = {}; end
if ischar(vars) || isstring(vars), vars = cellstr(vars); end
variant = lower(char(variant));
if ~ismember(variant, {'none', 'mch', 'ctrl', 'noncherry'})
    error('sm:badVariant', 'variant must be none, mch, ctrl or noncherry (got "%s").', variant);
end
if isnumeric(session), session = num2str(session); end

path = sprintf('%sAnalysis/preprocessing/%s-%s_preprocess_pca.mat', smroot(), animal, session);
act_fields = {'act_align', 'act_resid'};
if isempty(vars)
    S = load(path);
else
    need = vars;
    if ~strcmp(variant, 'none') && any(ismember(vars, act_fields))
        need = union(vars, {'PCA_coeff'}, 'stable');   % the transform needs the loadings
    end
    S = load(path, need{:});
end

if ~strcmp(variant, 'none')
    rois = sm_suppress_rois(animal, session, variant);
    for f = intersect(act_fields, fieldnames(S))'
        for a = find(~cellfun(@isempty, rois))
            S.(f{1}){a} = silence(S.(f{1}){a}, S.PCA_coeff{a}, rois{a});
        end
    end
    S.CCA_params = struct('suppress_mch', variant, 'roi_suppress', {rois});
    if ~isempty(vars)
        S = rmfield(S, setdiff(fieldnames(S), vars));   % drop PCA_coeff if it was only borrowed
    end
end

if nargout == 0
    for f = fieldnames(S)'
        assignin('caller', f{1}, S.(f{1}));
    end
    clear S
end
end


function Y = silence(X, C, roi)
% Apply score * C' * D * C along the component dimension of a [frames x components x trials] array.
d = ones(size(C, 1), 1);
d(roi) = 0;
M = C' * (d .* C);
[nf, nc, nt] = size(X);
Y = reshape(permute(X, [1 3 2]), nf * nt, nc) * M;
Y = permute(reshape(Y, nf, nt, nc), [1 3 2]);
end
