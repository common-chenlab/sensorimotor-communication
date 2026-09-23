function SVM_ABLATION()
% SVM_ABLATION  Reviewer 1, comment 1 (Nature Communications revision).
%
% Tests whether M1->S1/S2 projection neurons (mCherry+) contribute
% DISPROPORTIONATELY to LOCAL population task DECODING, as opposed to the
% inter-areal communication subspace tested in Fig. 6f,g. This is the SVM
% analog of the CCA in silico silencing: we decode stimulus and choice from
% the top-30 PCs of each motor area (M1A, M1B) during the probe and goal
% periods using three versions of the population PCA:
%   (1) baseline  : all neurons                          (_preprocess_pca.mat)
%   (2) mch       : projection (mCherry+) neurons silenced (_suppress_mch)
%   (3) ctrl      : a matched number of random unlabeled
%                   neurons silenced                       (_suppress_ctrl)
% The drop in decoding accuracy relative to baseline measures each
% population's contribution to the local task code. Same decoder as Fig. 3
% (top-30 PCs, probe frames 95:125, goal frames 242:272) and same silencing
% files as Fig. 6f,g, so the analysis is consistent with both.
%
% Output: SVM_ablation_results.mat with acc(session,area,variable,window,version)
%   area:     1=M1A, 2=M1B
%   variable: 1=stimulus (A vs P), 2=choice (lick vs no-lick)
%   window:   1=probe (sample), 2=goal (test)
%   version:  1=baseline, 2=projection-silenced, 3=matched-unlabeled-silenced

% [release] path handled by startup_sm.m: addpath(genpath('Z:\Dropbox\Chen Lab Dropbox\Chen Lab Team Folder\Analysis Suite\Secondary Analysis\svm'));
% [release] path handled by startup_sm.m: addpath('Z:\Dropbox\Dropbox\Chen Lab Team Folder\Analysis Suite\Secondary Analysis\GENERAL_SVM');

pre = [smroot() 'Analysis/preprocessing/'];
mch = [pre 'mCherry/']; % [release] portable separator
load([smroot() 'Analysis/summary.mat'],'control');
load([smroot() 'Analysis/lick_analysis/choice.mat'],'control_choice');

sampletime = 95:125;    % probe / sample window (Fig. 3 decoder)
testtime   = 242:272;   % goal / test window
areas      = [3 4];     % 3=M1A, 4=M1B  (1=S1,2=S2,3=M1A,4=M1B)
suf        = {'', '_suppress_mch', '_suppress_ctrl'};
nPC        = 30;
NR         = 1;         % repeats (10-fold CV inside prepare_run already stabilizes)

nS = size(control,1);
acc = nan(nS,2,2,2,3);

for n = 1:nS
    animal = control{n,1}; session = num2str(control{n,2});
    try
        allc = control_choice(n);
        % load the three PCA versions
        D = cell(1,3);
        for v = 1:3
            if v == 1
                f = [pre animal '-' session '_preprocess_pca.mat'];
            else
                f = [mch animal '-' session '_preprocess_pca' suf{v} '.mat'];
            end
            D{v} = load(f,'act_align','tr_include');
        end
        % align trial labels to included trials (shared across versions)
        tri = D{1}.tr_include{1};
        [~, ia2, ib2] = intersect(tri, allc.trialno, 'stable');
        a_all  = allc.all(ib2);
        a_stim = allc.stim(ib2);
        tri    = tri(ia2);

        for ai = 1:2
            j = areas(ai);
            for vr = 1:2            % variable: 1=stimulus, 2=choice(lick)
                if vr == 1
                    ix1 = find(a_stim < 3);          ix2 = find(a_stim > 2);
                else
                    ix1 = find(a_all > (3/100));      ix2 = find(a_all <= (3/100));
                end
                for wi = 1:2
                    win = sampletime; if wi == 2, win = testtime; end
                    % precompute the trial-window activity for each version
                    ND = cell(1,3); ok = true;
                    for v = 1:3
                        dat = permute(D{v}.act_align{j}, [3 2 1]);  % trials x cells x time
                        if size(dat,2) < nPC, ok = false; break; end
                        dat = dat(tri, 1:nPC, :);
                        ND{v} = nanmean(dat(:,:,win), 3);           % trials x nPC
                    end
                    if ~ok, continue; end
                    accR = zeros(NR,3);
                    for r = 1:NR
                        [t1, t2] = balance_idx(ix1, ix2);
                        Y = [ones(numel(t1),1); zeros(numel(t2),1)];
                        for v = 1:3
                            nd = [ND{v}(t1,:); ND{v}(t2,:)]; %#ok<AGROW>
                            evalc('[~, A] = prepare_run(nd, Y, [], [], 0, 0);'); % swallow libsvm output
                            accR(r,v) = A;
                        end
                    end
                    acc(n,ai,vr,wi,:) = mean(accR,1);
                end
            end
        end
        fprintf('done %s-%s\n', animal, session);
    catch ME
        fprintf('skip %s-%s: %s\n', animal, session, ME.message);
    end
end

outdir = smout('reviewer_svm_ablation'); % [release] outputs -> results/
save([outdir 'SVM_ablation_results.mat'], 'acc', 'control', 'sampletime', 'testtime');
fprintf('\nSaved results. Sessions with data: %d\n', sum(~isnan(acc(:,1,1,1,1))));
end
