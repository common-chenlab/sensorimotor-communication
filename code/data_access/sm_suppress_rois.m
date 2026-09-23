function rois = sm_suppress_rois(animal, session, variant)
% SM_SUPPRESS_ROIS  Neurons silenced in one session for one in-silico silencing variant.
%
%   rois = sm_suppress_rois(animal, session, variant)
%   returns a 1x4 cell, one entry per area (S1, S2, M1A, M1B), of neuron indices into that
%   area's ROI list. S1 and S2 are always empty. variant is 'mch', 'ctrl' or 'noncherry'.
%
%   The lists come from suppress_rois.mat, extracted by tools/build_suppress_table.m from the
%   CCA_params.roi_suppress field of the original lab silencing files. The 'ctrl' lists are the
%   random draws those files were actually built with, so results reproduce exactly.
%
%   The table is looked for under the active data root first, then in the repository's own
%   data/ folder (where it is staged while the rest of the data is still being assembled).

persistent T tpath
if isempty(T)
    rel = 'Analysis/preprocessing/mCherry/suppress_rois.mat';
    repo = fileparts(fileparts(fileparts(mfilename('fullpath'))));
    candidates = {[smroot() rel], fullfile(repo, 'data', rel)};
    hit = find(cellfun(@isfile, candidates), 1);
    if isempty(hit)
        error('sm:noRoiTable', 'suppress_rois.mat not found (looked in %s).', strjoin(candidates, ', '));
    end
    tpath = candidates{hit};
    T = load(tpath, 'suppress_rois');
    T = T.suppress_rois;
end

if isnumeric(session), session = num2str(session); end
key = sprintf('%s-%s', animal, session);
k = find(strcmp({T.session}, key) & strcmp({T.variant}, lower(char(variant))), 1);
if isempty(k)
    error('sm:noRois', 'No %s neuron list for %s in %s.', variant, key, tpath);
end
rois = T(k).roi;
end
