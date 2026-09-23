# Figure to code map

Each row names the script that produces a panel, the arrays and indices it plots, and the
number of sessions or animals behind it. Rows marked **Confirmed** were traced to the plotted
values when the Source Data file was built; rows marked **Inferred** are still awaiting the
authors' confirmation.

The plotted values for every panel are also published in the article's Source Data file.
Where the code as published cannot regenerate a panel, the row says so.

Most analysis scripts are MATLAB *cell scripts*: run them cell by cell (Ctrl+Enter). "cell
*X*" refers to the `%% X` heading.

## Main figures

| Panel | Script(s) and provenance | n | Status |
|---|---|---|---|
| 1a | schematic, drawn in Illustrator | | |
| 1b | `behavior_lick/plot_choice_FIGURE.m`, from `Manuscript/.../Figure1-Opto/choice.mat` (`control`, one row per animal). Note this is a **different** file from `Analysis/lick_analysis/choice.mat`. | 10 animals | Confirmed |
| 1c | `behavior_lick/MACRO_STIM.m` + `sort_lick_stim.m` writing `Analysis/lick_analysis/licks.mat` (`control_lick`), conditions AP, PA, AA, PP | 38 sessions | Confirmed |
| 1d | video still | | |
| 1e, 1f, 1g | `behavior_whisker/whisker_analysis_delay.m`; processing cells write `Analysis/whisker_analysis/matlab.mat` (`result`, `resultchoice`, 1x44 aligned to `summary.mat`), figure cells write `amp.eps` / `curv.eps` | 6 animals, 38 sessions | Confirmed |
| 2a | images | | |
| 2b | `singlecell/FIGURE_RASTER.m`, session sm052-3 | | Inferred |
| 2c | example traces | | Inferred |
| 2d | `singlecell/MACRO.m` via `summarize_area.m`, fraction of **all** neurons | 6 animals | Confirmed |
| 2e-h | same, but relative proportion **within category group**. The within-group branch of `summarize_area.m` is commented out, so the code as published does not regenerate these panels. Archived values: `Analysis/singlecell/Book1.xlsx` | 6 animals | Confirmed |
| 3b | `svm/MACRO_PCA_BINNED.m` lines 77-80 + `svm/plot_bar_svm_binned.m`, from `Analysis/svm/PCA_BINNED.mat`: probe stim `pcabinnedacc(:,1,3,:)`, probe choice `(:,1,4,:)`, goal stim `(:,2,5,:)`, goal choice `(:,2,6,:)`; intersection/union from `pcabinnedaccui`. Chance line = 95th percentile of the 100 shuffles in `pcabinnedshuf` | 40 sessions | Confirmed |
| 3c | 8x8 trained-by-tested matrix per area, from `pcabinnedcrossaccui2` (`svm/MAIN_PCA_BINNED_CROSS_UI.m`). Conditions 1-8: sample stim, sample choice, test stim, test choice, sample intersection, sample union, test intersection, test union | 40 sessions | Confirmed |
| 4b | `cca/DISPLAY_sig_CCA.m` first cell: per-session CCC1-6 correlation plus the `r_thresh` shuffle threshold. Session average with SEM, not one example session; "example" means the example area **pair** (S2:M1A) | 40 sessions | Confirmed |
| 4c | `cca/COMPARE_CCA_SUBSPACE.m`; reference bands from `cca_subspace_reference/` | 40 sessions | Confirmed |
| 4d | `cca/DISPLAY_sig_CCA.m` via `compile_correlation.m` time courses, CCC1-3, all trials | 37 sessions | Confirmed |
| 4e | `cca/SUMMARY2.m` FIGURE + stats cells via **`compile_correlation_binned.m`** (one correlation over the whole window; probe 95:125, goal 242:272). Conditions: probe i paired with goal i+4; Fig 4e uses i = 3 (P no lick) and 4 (P lick). CCC1 only | 40 sessions | Confirmed |
| 5b, 5c | `svm_cca/SVM_CCA_alignment_UI.m` (cells GET UI/SC BINNED, FIGURE BINNED, STATS); exact stats `svm_cca/FIG5_STATS.m` | 40 sessions | Confirmed |
| 6a | images | | |
| 6b-e | `singlecell/MACRO.m` via `summarize_area_mCherry(...)`; flag 1 = mCherry+ projection, flag 0 = unlabelled. `sumM1(animal, category, k)` with k = 1 proj probe, 2 proj goal, 3 ctl probe, 4 ctl goal. 6b stimulus (cat 3,4), 6c choice (1,2), 6d intersection (5:8), 6e union (9:12) | 6 animals; projection bars rest on 3-5 | Confirmed |
| 6f, 6g | `mcherry/ANALYZE_PROJ.m` + `project_correlation.m`; flag 1 loads `_suppress_mch` (projection removed), flag 0 loads `_suppress_ctrl` (matched unlabelled removed) | 39 sessions | Confirmed |
| 7a | `ifi/IFI_figure.m`, `ifi/IFI_schematic_bottomup.m`, `ifi/IFI_schematic_topdown.m` | | Inferred |
| 7b | `ifi/EXAMPLE_IFI.m` (runs `BATCH_IFI` on session 17) | | Inferred |
| 7c | `ifi/DISPLAY_IFI.m`, from `Scripts/CCA/IFI.mat`; loses sm041-5 (272 frames, fails the 1:299 cut) | 37 sessions | Confirmed |
| 7d | `ifi/DISPLAY_IFI.m` cell TRIAL | 38 sessions | Confirmed |
| 7e | `ifi/DISPLAY_IFI.m` bar cell; exact stats `ifi/FIG7E_STATS.m` | 38 sessions | Confirmed |
| 7f | model schematic | | |

## Supplementary figures

| Panel | Script(s) | n | Status |
|---|---|---|---|
| S1 | cross-period cells of the Fig 3c matrix (`svm/MACRO_PCA_BINNED.m`) | 40 sessions | Confirmed |
| S2 | `dimensionality/DIMENSIONALITY_ANALYSIS.m` | 40 sessions | Confirmed |
| S3a | `cca/DISPLAY_sig_CCA.m`, same analysis as 4b over all six pairs | 40 sessions | Confirmed |
| S3b | same as 4d over all six pairs | 37 sessions | Confirmed |
| S3c | same as 4e, conditions i = 1 (A lick) and 2 (A no lick) | 40 sessions | Confirmed |
| S4 | `svm_cca/SVM_CCA_alignment_UI.m`; `svm_cca/FIG5_STATS.m` writes the panels | 40 sessions | Confirmed |

## Session counts

`summary.mat` `control` lists 44 sessions. Analyses drop sessions silently through
`try ... catch end`, so n varies by panel:

- 4 sessions have no `_preprocess_pca.mat` (sm041-9, sm045-2, sm045-5, sm052-9), giving the
  40 used by most panels.
- `compile_correlation` additionally errors on sm041-12, sm052-2 and sm054-3, giving the 37
  behind Fig 4d and Supplementary Fig 3b.
- `IFI.mat` has 6 empty entries of 44, giving 38 for Fig 7d,e; Fig 7c additionally loses
  sm041-5, giving 37. Missing: sm041-9, sm045-2, sm045-5, sm052-9, sm056-1, sm056-9.
- Fig 6f,g use 39 sessions.

All six animals survive in every panel.

## Reviewer-response analyses (not manuscript figures)

| Item | Script(s) |
|---|---|
| R1 comment 1, SVM ablation | `reviewer_svm_ablation/SVM_ABLATION.m`, `DISPLAY_svm_ablation.m` |
| R1 comment 5, subspace floor and ceiling | `cca_subspace_reference/` |
| R2 major 2, pre-probe vs pre-goal whisking | `behavior_whisker/whisking_preprobe_pregoal_stat.m` |

## Upstream pipeline (produces the intermediate data)

Session `.mat` files (`Animals/<animal>/<animal>-<session>.mat`, plus `_whisker.mat`) are
the starting point. They come from the lab's 2P preprocessing and whisker tracking, both
documented in `PREPROCESSING.md`. `LoadMultiFOV` also reads FOV parameters from the lab's
raw-data server, so the pipeline currently runs only inside the lab.

1. `pipeline_cca/setup_SM_workspace.m`: animals, areas, usable sessions.
2. `pipeline_cca/perform_CCA_sub.m` to `CanonicalCrossCorrelationSubtype.m`: per-session PCA
   and CCA, results via `LoadCCA.m` into `Animals/<animal>/CCA/`.
3. `pipeline_cca/export_CCA_data.m` writes `Analysis/preprocessing/*_preprocess_pca.mat` and
   `Analysis/proj/full-resid_stim/*-CCA_proj_full-resid_stim.mat`.
4. `pipeline_cca/get_CCA_coef.m` appends `dim1_coef` to the projection files.

These scripts write into the data tree and stop with an error if `smroot()` is the lab's
working copy (`sm_assert_writable`).
