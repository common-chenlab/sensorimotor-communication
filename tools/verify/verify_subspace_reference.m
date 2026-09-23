% VERIFY_SUBSPACE_REFERENCE  Run the repository copy of CCA_SUBSPACE_REFERENCE on the first
% sessions and compare the observed Fig. 4C subspace angles (deterministic) with the
% results shipped in Analysis/CCA_SUBSPACE_REVISION. The bootstrap floor and shuffle
% ceiling are random resamples (the shipped values came from a Python run with a
% different RNG), so they are only checked for plausibility, not equality.
NSESS = 3;
repo = fileparts(fileparts(fileparts(mfilename('fullpath'))));
run(fullfile(repo, 'startup_sm.m'));

CCA_SUBSPACE_REFERENCE(NSESS);
new = load([smout('cca_subspace_reference') 'CCA_subspace_reference_results.mat']);
ref = load([smroot() 'Analysis/CCA_SUBSPACE_REVISION/CCA_subspace_reference_results.mat']);

d = abs(new.obs - ref.obs(:, 1:NSESS));
fprintf('observed angles, first %d sessions: max abs diff %.3g deg\n', NSESS, max(d(:)));
fprintf('floor mean  new %.1f / shipped %.1f deg (same sessions)\n', mean(new.flo(:)), mean(mean(ref.flo(:, 1:NSESS))));
fprintf('ceiling mean new %.1f / shipped %.1f deg (same sessions)\n', mean(new.cei(:)), mean(mean(ref.cei(:, 1:NSESS))));
if max(d(:)) < 1e-6
    fprintf('CCA_SUBSPACE_REFERENCE: PASS (observed angles)\n');
else
    fprintf('CCA_SUBSPACE_REFERENCE: FAIL (observed angles)\n');
end
% keep results/ free of the partial 3-session file
delete([smout('cca_subspace_reference') 'CCA_subspace_reference_results.mat']);
