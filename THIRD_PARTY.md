# Third-party code

Files in `code/lib/third_party/` (and one in `code/lib/chenlab/svm/`) were written outside
the Chen lab and are redistributed here unchanged apart from the automatic path rewrite
described in `README.md`. Original author headers are kept in each file.

| File | Author / source | License | Status |
|---|---|---|---|
| `canonical-correlation-maps/CanonCorr.m`, `CanonCorrFitAndPredict.m`, `BinTime.m`, `Squash.m` | J. D. Semedo, *canonical-correlation-maps* (Semedo et al., Nat Commun 2022), github.com/joao-semedo/canonical-correlation-maps | MIT (`canonical-correlation-maps/LICENSE`) | confirmed |
| `anova_rm.m` | Arash Salarian, 2008 (MATLAB File Exchange) | File Exchange BSD | **confirm** |
| `bonf_holm.m` | David M. Groppe (MATLAB File Exchange) | File Exchange BSD | **confirm** |
| `confplot.m` | Michele Giugliano, 2002 (MATLAB File Exchange) | File Exchange BSD | **confirm** |
| `distinguishable_colors.m` | Timothy E. Holy, 2010–2011 (MATLAB File Exchange) | File Exchange BSD | **confirm** |
| `loadtiff.m` | YoonOh Tak, 2012; modified by E. Pnevmatikakis (CaImAn) | BSD 2-clause, full text in the file header | confirmed 2026-09-23 from the file header |
| `violin.m` | Holger Hoffmann, 2015 (MATLAB File Exchange) | File Exchange BSD | **confirm** |
| `bluewhitered.m` | no author header; appears to be Nathan Childress (MATLAB File Exchange) | File Exchange BSD | **confirm** |
| `code/lib/chenlab/svm/wsvmmodel_cross_shuffles.m` | Talayeh Razzaghi & Petros Xanthopoulos, 2014 (weighted SVM), modified in the lab | unknown | **confirm** |
| `janelia_whisker/LoadWhiskers.m`, `LoadMeasurements.m` | Nathan Clack, Janelia (whisk, github.com/nclack/whisk) | Janelia Farm Research Campus Software Copyright 1.1, a 3-clause BSD variant; text in `licenses/janelia-whisker-LICENSE.txt` | confirmed 2026-09-23 from the upstream repository |
| `natsort.m` | Stephen Cobeldick (MATLAB File Exchange) | File Exchange BSD | **confirm** |
| `code/lib/chenlab/progressbar.m` | parfor_progressbar (MATLAB File Exchange) | File Exchange BSD | **confirm** |
| `code/lib/chenlab/parseXML.m` | appears to follow the MathWorks `xmlread` documentation example | MathWorks example | **confirm** |

"confirm" = the license was inferred from the file's origin, not read from a license file.
Each must be checked (and the license text added next to the file) before the repository
is made public.
