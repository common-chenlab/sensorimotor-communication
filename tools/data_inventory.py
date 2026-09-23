#!/usr/bin/env python3
"""Inventory the data files the repository code reads, with sizes, from a data root.

    python tools/data_inventory.py [DATA_ROOT] > tools/DATA_INVENTORY.csv

DATA_ROOT defaults to the lab working copy. Groups mirror data/README.md.
Session lists come from Analysis/summary.mat is not parsed here; every file
matching the patterns below is listed.
"""
import csv, glob, os, sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else r"Z:\Dropbox\Chen Lab Dropbox\Chen Lab Team Folder\Projects\Sensorimotor"
ANIMALS = ['sm041', 'sm045', 'sm052', 'sm054', 'sm056', 'sm057']

GROUPS = [
    ('metadata', ['Analysis/summary.mat', 'Analysis/lick_analysis/choice.mat']),
    ('preprocessed PCA (per session)', ['Analysis/preprocessing/*_preprocess_pca.mat']),
    ('preprocessed PCA, in-silico silencing (Fig 6f,g)', ['Analysis/preprocessing/mCherry/*_preprocess_pca_suppress_*.mat']),
    ('CCA projections (per session)', ['Analysis/proj/full-resid_stim/*-CCA_proj_full-resid_stim.mat']),
    ('SVM results (Fig 3, 5)', ['Analysis/svm/PCA_BINNED.mat', 'Analysis/svm/PCA_SVM.mat',
                                'Analysis/svm/PCA_SVM_lick.mat', 'Analysis/svm/CONTROLCROSSTEST_REWARD.mat']),
    ('whisker summary (Fig 1)', ['Analysis/whisker_analysis/matlab.mat']),
    ('IFI results (Fig 7)', ['Scripts/CCA/IFI.mat']),
    ('reviewer analyses', ['Analysis/CCA_SUBSPACE_REVISION/CCA_subspace_reference_results.mat',
                           'Analysis/R1C1_svm_ablation/SVM_ablation_results.mat',
                           'Analysis/R1C3_dimensionality/dimensionality_results.mat']),
    ('session files (Fig 2, lick, whisker; upstream input)', [f'Animals/{a}/{a}-*.mat' for a in ANIMALS]),
]

w = csv.writer(sys.stdout, lineterminator='\n')
w.writerow(['group', 'path', 'bytes'])
totals = {}
for group, pats in GROUPS:
    for pat in pats:
        for p in sorted(glob.glob(os.path.join(ROOT, *pat.split('/')))):
            if os.path.isfile(p):
                size = os.path.getsize(p)
                totals[group] = totals.get(group, 0) + size
                w.writerow([group, os.path.relpath(p, ROOT).replace('\\', '/'), size])
for g, b in totals.items():
    print(f"# {g}: {b / 1e9:.2f} GB", file=sys.stderr)
print(f"# TOTAL: {sum(totals.values()) / 1e9:.2f} GB", file=sys.stderr)
