function verify_suppress_helper(animal, session)
% VERIFY_SUPPRESS_HELPER  Check sm_load_preprocess against the lab's stored variant files.
%
%   verify_suppress_helper('sm045', 4)
%
%   For each variant (mch, ctrl, noncherry), loads the original lab file and the helper's
%   reconstruction from the baseline file, and compares every variable. Numeric arrays must
%   agree to TOL; everything else exactly. Also checks the three calling styles the analysis
%   code uses: full struct, a variable subset, and no-output assignment into the workspace.

if nargin < 1, animal = 'sm045'; end
if nargin < 2, session = 4; end
TOL = 1e-9;
repo = fileparts(fileparts(fileparts(mfilename('fullpath'))));
run(fullfile(repo, 'startup_sm.m'));

if isnumeric(session), session = num2str(session); end
src = sprintf('%sAnalysis/preprocessing/mCherry/%s-%s_preprocess_pca_suppress_', smroot(), animal, session);
all_ok = true;
for v = {'mch', 'ctrl', 'noncherry'}
    ref = load([src v{1} '.mat']);
    tic; new = sm_load_preprocess(animal, session, v{1}); t = toc;
    worst = 0; bad = {};
    for f = setdiff(fieldnames(ref), {'CCA_params'})'
        [ok, e] = same(ref.(f{1}), new.(f{1}), TOL);
        worst = max(worst, e);
        if ~ok, bad{end+1} = f{1}; end %#ok<AGROW>
    end
    roi_ok = isequal(ref.CCA_params.roi_suppress, new.CCA_params.roi_suppress);
    ok = isempty(bad) && roi_ok;
    all_ok = all_ok && ok;
    fprintf('%-10s %s  max diff %.2g  (%.1f s)%s%s\n', v{1}, pf(ok), worst, t, ...
        ternary(roi_ok, '', '  neuron lists differ'), ternary(isempty(bad), '', ['  differ: ' strjoin(bad, ', ')]));
end

% calling styles used by the analysis scripts
sub = sm_load_preprocess(animal, session, 'mch', {'act_align', 'tr_include'});
ok1 = isequal(sort(fieldnames(sub))', sort({'act_align', 'tr_include'}));
sm_load_preprocess(animal, session, 'ctrl');  % no output -> assigns into this workspace
ok2 = exist('act_resid', 'var') == 1 && exist('tr_include', 'var') == 1;
fprintf('subset call returns only the requested variables: %s\n', pf(ok1));
fprintf('no-output call assigns variables like LOAD:        %s\n', pf(ok2));
all_ok = all_ok && ok1 && ok2;
fprintf('\nsm_load_preprocess on %s-%s: %s\n', animal, session, pf(all_ok));
end


function [ok, e] = same(a, b, tol)
e = 0;
if isnumeric(a) && isnumeric(b)
    ok = isequal(size(a), size(b));
    if ok && ~isempty(a)
        d = abs(double(a(:)) - double(b(:)));
        d(isnan(a(:)) & isnan(b(:))) = 0;
        e = max(d);
        ok = e <= tol;
    end
elseif iscell(a) && iscell(b)
    ok = isequal(size(a), size(b));
    for k = 1:numel(a)
        if ~ok, break; end
        [ok, ek] = same(a{k}, b{k}, tol);
        e = max(e, ek);
    end
else
    ok = isequaln(a, b);
end
end

function s = pf(ok), s = ternary(ok, 'PASS', 'FAIL'); end
function out = ternary(c, a, b), if c, out = a; else, out = b; end, end
