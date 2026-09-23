# Third-party code

Files in `code/lib/third_party/` (and one in `code/lib/chenlab/svm/`) were written outside
the Chen lab and are redistributed here unchanged apart from the automatic path rewrite
described in `README.md`. Original author headers are kept in each file.

| File | Author / source | License | Status |
|---|---|---|---|
| `canonical-correlation-maps/CanonCorr.m`, `CanonCorrFitAndPredict.m`, `BinTime.m`, `Squash.m` | J. D. Semedo, *canonical-correlation-maps* (Semedo et al., Nat Commun 2022), github.com/joao-semedo/canonical-correlation-maps | MIT (`canonical-correlation-maps/LICENSE`) | confirmed |
| `loadtiff.m` | YoonOh Tak, 2012; modified by E. Pnevmatikakis (CaImAn) | BSD 2-clause, full text in the file header | confirmed 2026-09-23 from the file header |
| `janelia_whisker/LoadWhiskers.m`, `LoadMeasurements.m` | Nathan Clack, Janelia (whisk, github.com/nclack/whisk) | Janelia Farm Research Campus Software Copyright 1.1, a 3-clause BSD variant; text in `licenses/janelia-whisker-LICENSE.txt` | confirmed 2026-09-23 from the upstream repository |
| `code/lib/chenlab/svm/wsvmmodel_cross_shuffles.m` | Talayeh Razzaghi & Petros Xanthopoulos, 2014 (weighted SVM), modified in the lab | unknown | **confirm** |
| `code/lib/chenlab/parseXML.m` | appears to follow the MathWorks `xmlread` documentation example | MathWorks example | **confirm** |

## MATLAB File Exchange functions, not included

These are used by the code but are not redistributed here, because File Exchange
submissions carry per-submission licenses that we cannot restate on the authors' behalf.
Download each from File Exchange and put it on the MATLAB path before running the scripts
listed. Everything else runs without them.

| Function | Author | Needed by |
|---|---|---|
| `anova_rm.m` | Arash Salarian | repeated-measures ANOVA in `cca/DISPLAY_sig_CCA.m` and `mcherry/ANALYZE_PROJ.m` |
| `bonf_holm.m` | David M. Groppe | Holm-Bonferroni correction, used by nine scripts including `svm_cca/FIG5_STATS.m` and `ifi/FIG7E_STATS.m` |
| `confplot.m` | Michele Giugliano | shaded error bars in the lick and whisker figures |
| `distinguishable_colors.m` | Timothy E. Holy | plot colours in `pipeline_cca/show_CCA_results.m` |
| `violin.m` | Holger Hoffmann | violin plots in the correlation figures |
| `bluewhitered.m` | Nathan Childress | diverging colormap in `ifi/IFI_figure.m` and the correlation figures |
| `natsort.m` | Stephen Cobeldick | file ordering in `whisker_tracking/import_measurements/` |
| `progressbar.m` (parfor_progressbar) | — | progress display in `lib/chenlab/ParforProgressbar.m` |

The first two affect reported statistics; the rest affect figures or convenience only.

"confirm" in the table above means the license was inferred from the file's origin rather
than read from a license file. Each remaining one must be checked, and its license text
added next to the file, before the repository is made public.

## Modified GPL files

`preprocessing/modified_gpl/` holds lab-modified copies of files from NoRMCorre and
CaImAn-MATLAB (both GPL-2.0) and OASIS-matlab (GPL-3.0). They stay under their upstream
licenses; see `code/preprocessing/modified_gpl/NOTICE.md` for what was changed, and
`LICENSE` for how that interacts with this repository's MIT license.
