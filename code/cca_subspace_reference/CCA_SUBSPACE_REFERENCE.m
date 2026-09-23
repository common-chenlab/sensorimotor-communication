function CCA_SUBSPACE_REFERENCE(max_sessions)
% CCA_SUBSPACE_REFERENCE  Anchor the Fig. 4C communication-subspace angles to
% two functional baselines requested by Reviewer #1 (comment 5):
%   (1) reliability FLOOR  - angle between two independent bootstrap estimates
%                            of the SAME channel's subspace (within-area baseline)
%   (2) chance   CEILING   - angle after trial-shuffling one area before CCA
%                            (unrelated-populations baseline)
% A conservative split-half floor is also computed for robustness.
%
% The observed angles recomputed here reproduce the pipeline's saved CCA_coeff
% exactly (canoncorr on the top-30 residualized PCs over the whole trial),
% i.e. they match Fig. 4C. Uses the first K = 2 canonical components, as in the paper.
%
% Requires: Statistics and Machine Learning Toolbox (canoncorr); subspace (core).
% Input:  max_sessions (optional) - cap #sessions for a quick test (default Inf).
% Output: saves CCA_subspace_reference_results.mat and prints a summary table.
%
% Author: revision analysis, 2026.

if nargin < 1 || isempty(max_sessions), max_sessions = Inf; end

proj_dir = [smroot() 'Analysis/proj/full-resid_stim/'];
summ     = [smroot() 'Analysis/summary.mat'];
load(summ, 'control');

nPC = 30; K = 2; nBoot = 20; nShuff = 10; nSplit = 10;
rng(0);

% pair index -> area ids (1=S1, 2=S2, 3=M1A, 4=M1B); matches comp.ind
IND = [1 2; 1 3; 1 4; 2 3; 2 4; 3 4];
% within-source comparisons: {label, source_area, pairP, pairQ}
COMPS = { ...
 'S1-S2:M1A',1,1,2; 'S1-S2:M1B',1,1,3; 'S1-M1A:M1B',1,2,3; ...
 'S2-S1:M1A',2,1,4; 'S2-S1:M1B',2,1,5; 'S2-M1A:M1B',2,4,5; ...
 'M1A-S1:S2',3,2,4; 'M1A-S1:M1B',3,2,6; 'M1A-S2:M1B',3,4,6; ...
 'M1B-S1:S2',4,3,5; 'M1B-S1:M1A',4,3,6; 'M1B-S2:M1A',4,5,6};
nComp = size(COMPS,1);
nSess = size(control,1);

obs = nan(nComp,nSess); flo = nan(nComp,nSess); cei = nan(nComp,nSess);
shf = nan(nComp,nSess); shc = nan(nComp,nSess); used = false(nSess,1);

count = 0;
for n = 1:nSess
    if count >= max_sessions, break; end
    fname = [proj_dir control{n,1} '-' num2str(control{n,2}) '-CCA_proj_full-resid_stim.mat'];
    if ~isfile(fname), continue; end
    try
        Sd = load(fname, 'act_resid');
        areas = cell(1,4);
        for a = 1:4
            x = permute(Sd.act_resid{a}, [2 1 3]);   % (frame,PC,trial) -> (PC,frame,trial)
            areas{a} = x(1:nPC,:,:);                 % keep top nPC
        end
        nTr = size(areas{1},3);

        % --- observed (full data) ---
        Lf = pair_loadings(areas, IND, 1:nTr, false);
        for c = 1:nComp
            [src,pP,pQ] = deal(COMPS{c,2},COMPS{c,3},COMPS{c,4});
            obs(c,n) = rad2deg(subspace(Lf{src,pP}(:,1:K), Lf{src,pQ}(:,1:K)));
        end

        % --- bootstrap reliability floor ---
        acc = zeros(nComp,1);
        for b = 1:nBoot
            L1 = pair_loadings(areas, IND, randi(nTr,[1 nTr]), false);
            L2 = pair_loadings(areas, IND, randi(nTr,[1 nTr]), false);
            for c = 1:nComp
                [src,pP,pQ] = deal(COMPS{c,2},COMPS{c,3},COMPS{c,4});
                a1 = rad2deg(subspace(L1{src,pP}(:,1:K), L2{src,pP}(:,1:K)));
                a2 = rad2deg(subspace(L1{src,pQ}(:,1:K), L2{src,pQ}(:,1:K)));
                acc(c) = acc(c) + 0.5*(a1+a2);
            end
        end
        flo(:,n) = acc/nBoot;

        % --- trial-shuffle chance ceiling ---
        acc = zeros(nComp,1);
        for b = 1:nShuff
            Ls1 = pair_loadings(areas, IND, 1:nTr, true);
            Ls2 = pair_loadings(areas, IND, 1:nTr, true);
            for c = 1:nComp
                [src,pP,pQ] = deal(COMPS{c,2},COMPS{c,3},COMPS{c,4});
                acc(c) = acc(c) + rad2deg(subspace(Ls1{src,pP}(:,1:K), Ls2{src,pQ}(:,1:K)));
            end
        end
        cei(:,n) = acc/nShuff;

        % --- split-half (conservative floor + matched-noise cross) ---
        af = zeros(nComp,1); ax = zeros(nComp,1);
        for b = 1:nSplit
            p = randperm(nTr); h1 = p(1:floor(nTr/2)); h2 = p(floor(nTr/2)+1:end);
            L1 = pair_loadings(areas, IND, h1, false);
            L2 = pair_loadings(areas, IND, h2, false);
            for c = 1:nComp
                [src,pP,pQ] = deal(COMPS{c,2},COMPS{c,3},COMPS{c,4});
                a1 = rad2deg(subspace(L1{src,pP}(:,1:K), L2{src,pP}(:,1:K)));
                a2 = rad2deg(subspace(L1{src,pQ}(:,1:K), L2{src,pQ}(:,1:K)));
                af(c) = af(c) + 0.5*(a1+a2);
                ax(c) = ax(c) + rad2deg(subspace(L1{src,pP}(:,1:K), L2{src,pQ}(:,1:K)));
            end
        end
        shf(:,n) = af/nSplit; shc(:,n) = ax/nSplit;

        used(n) = true; count = count + 1;
        fprintf('done %s-%d (%d)\n', control{n,1}, control{n,2}, count);
    catch ME
        fprintf('FAIL %s-%d: %s\n', control{n,1}, control{n,2}, ME.message);
    end
end

obs=obs(:,used); flo=flo(:,used); cei=cei(:,used); shf=shf(:,used); shc=shc(:,used);
N = size(obs,2);

fprintf('\nN = %d sessions   (K = %d CCCs)\n', N, K);
fprintf('%-13s %8s %9s %8s %11s %11s\n','comparison','floor','observed','ceiling','p(o>floor)','p(o<ceil)');
for c = 1:nComp
    [~,pF] = ttest(obs(c,:), flo(c,:));
    [~,pC] = ttest(obs(c,:), cei(c,:));
    fprintf('%-13s %8.1f %9.1f %8.1f %11.1e %11.1e\n', COMPS{c,1}, ...
        mean(flo(c,:)), mean(obs(c,:)), mean(cei(c,:)), pF, pC);
end

% within-source distinct-vs-shared contrasts
CON = {'S2  S1-ch vs motor-ch',4,6; 'S2  S1-ch vs motor-ch',5,6; ...
       'M1A sens-ch vs motor',8,7; 'M1A sens-ch vs motor',9,7; ...
       'M1B sens-ch vs motor',11,10; 'M1B sens-ch vs motor',12,10};
fprintf('\nWithin-source contrasts (distinct minus shared):\n');
for i = 1:size(CON,1)
    a = CON{i,2}; b = CON{i,3}; [~,p] = ttest(obs(a,:),obs(b,:));
    fprintf('  %-22s %-12s d=%+5.1f  p=%.1e\n', CON{i,1}, COMPS{a,1}, ...
        mean(obs(a,:))-mean(obs(b,:)), p);
end

outdir = smout('cca_subspace_reference'); % [release] outputs -> results/
save([outdir 'CCA_subspace_reference_results.mat'], 'obs','flo','cei','shf','shc','COMPS','N','K');
fprintf('\nSaved %sCCA_subspace_reference_results.mat\n', outdir);
end

% ------------------------------------------------------------------------
function L = pair_loadings(areas, IND, trials, doShuffle)
% L{source_area, pair} = canoncorr loadings (nPC x nCC) for the source area
L = cell(4,6);
for pr = 1:6
    a1 = IND(pr,1); a2 = IND(pr,2);
    X = squash(areas{a1}(:,:,trials));
    if doShuffle
        Y = squash(areas{a2}(:,:,trials(randperm(numel(trials)))));
    else
        Y = squash(areas{a2}(:,:,trials));
    end
    good = ~any(isnan(X),2) & ~any(isnan(Y),2);
    [A,B] = canoncorr(X(good,:), Y(good,:));
    L{a1,pr} = A; L{a2,pr} = B;
end
end

function M = squash(a3)
% (PC, frame, trial) -> (frame*trial, PC)   [column-major, matches Squash.m + transpose]
[P,F,T] = size(a3);
M = reshape(a3, [P, F*T])';
end
