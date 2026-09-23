# Dynamic engagement of long-range communication across sensorimotor cortex during flexible behavior

Analysis code for Blaeser, Clough, Ahrens & Chen (Nature Communications, manuscript
NCOMMS-26-057740).

> **Pre-release.** This repository is being prepared for publication. The DOIs under
> *Data* and *Citing* will be filled in at release.

## Requirements

- MATLAB R2024a (other recent releases likely work; untested)
- Toolboxes, as reported by `matlab.codetools.requiredFilesAndProducts` over `code/`
  (`tools/verify/list_toolboxes.m`): Statistics and Machine Learning, Signal Processing,
  Image Processing, DSP System, Curve Fitting, Parallel Computing. Not every script needs
  every toolbox; the figure scripts mostly need Statistics and Machine Learning, plus
  Parallel Computing for `parfor` cells.
- The data, published separately on G-Node GIN (see *Data* below)

The same check finds no required files outside the repository.

## Quick start

```matlab
>> cd path/to/sensorimotor-communication
>> startup_sm            % path setup; reports data folder; cd's to results/
>> FIG7E_STATS           % e.g. Figure 7e statistics -> results/fig7e_stats/
```

`FIGURE_MAP.md` lists the script for every figure panel. Most analysis scripts are cell
scripts meant to be run cell by cell.

## Layout

```
startup_sm.m               path setup
code/
  config/                  smroot (data root), smout (results/), write guard, path shims
  data_access/             sm_load_preprocess: baseline or silenced-M1 preprocessing data
  pipeline_cca/            session PCA + CCA and export of intermediates (upstream)
  behavior_lick/           Fig. 1b,c
  behavior_whisker/        Fig. 1e-g, reviewer whisking test
  singlecell/              Fig. 2, 6b-e
  svm/                     Fig. 3, Supp. Fig. 1
  cca/                     Fig. 4, Supp. Fig. 3
  cca_subspace_reference/  Fig. 4c reference bands
  svm_cca/                 Fig. 5, Supp. Fig. 4
  mcherry/                 Fig. 6f,g
  ifi/                     Fig. 7
  dimensionality/          Supp. Fig. 2
  reviewer_svm_ablation/   reviewer response
  preprocessing/           raw images -> session files; needs raw data (PREPROCESSING.md)
  whisker_tracking/        whisker videos -> *_whisker.mat; needs raw video
  lib/chenlab/             shared Chen-lab functions used by the above
  lib/third_party/         external functions (THIRD_PARTY.md)
data/                      clone of the GIN data repository (not part of this repository)
results/                   everything the code writes (not in git)
tools/                     build and verification scripts
```

## Where the code comes from

The code was written in the lab's Dropbox project folders and is still being edited there.
`code/` is **generated** from those folders by `tools/build_repo.py`:

- `tools/manifest.csv` lists every file and its source: 165 files, found by tracing function
  calls from each figure's entry-point script and from the preprocessing and whisker-tracking
  entry points. Roughly a third come from the lab-wide *Analysis Suite*.
- Hard-coded lab paths are rewritten to `smroot()`; `addpath` calls to lab folders are
  commented out.
- `tools/patches.py` holds the remaining hand edits (inputs that depended on MATLAB's
  current folder, output folders). Each edited line is marked `[release]`.
- Credentials are redacted automatically. Several lab scripts embed a Slack webhook URL; the
  build replaces any it finds and reports how many, so none reaches the deposit.
- `tools/SOURCE_LOCK.csv` records the md5 of every source file at build time.

The analysis logic itself is not modified. To refresh after the lab code changes:

```bash
python tools/build_repo.py --check   # list sources changed since the last build
python tools/build_repo.py           # rebuild code/
```

Hand-written files (`code/config/`, `code/data_access/`,
`code/preprocessing/deepinterpolation/`, `startup_sm.m`, the `.md` files, `tools/`) are not
touched by the build.

## Verification

`tools/verify/` re-runs repository copies against the lab's data and compares their output
with results produced by the original scripts. Logs go to `results/verify_logs/`.

| Script | Checks | Result |
|---|---|---|
| `verify_fig7e.m` | `FIG7E_STATS` table (Fig. 7e) | PASS: 24×17 table identical |
| `verify_fig5.m` | `FIG5_STATS` recomputed from per-session CCA files, no cache (Fig. 5b,c, Supp. Fig. 4) | PASS: 192×13 table, max diff 1e-14 |
| `verify_dimensionality.m` | `DIMENSIONALITY_ANALYSIS` recomputed from 40 per-session PCA files (Supp. Fig. 2) | PASS: participation ratios and P values, max diff 1e-13 |
| `verify_subspace_reference.m` | `CCA_SUBSPACE_REFERENCE` observed angles, first 3 sessions (Fig. 4c) | PASS: max diff 1e-12°; bootstrap floor/ceiling are random draws and agree within 0.3° |

Run on 2026-09-16 against the lab working copy of the data. Not yet verified: Fig. 1–4
(except 4c), 6, 7a–d. Those scripts are interactive cell scripts with no saved numeric
output to compare against.

## Data

The data are published on G-Node GIN as one dataset,
[common-chenlab/Sensorimotor_NComm2026](https://gin.g-node.org/common-chenlab/Sensorimotor_NComm2026)
(DOI: TODO): one `.mat` file per imaging session, grouped by animal, plus whisker kinematics,
the session list, the Figure 1b optogenetic behaviour, the silenced-neuron lists and the
denoising network weights. Its README describes every variable.

Clone it into this repository's `data/` folder:

```bash
gin get common-chenlab/Sensorimotor_NComm2026 data
cd data && gin get-content .
```

Or keep it elsewhere and set the environment variable `SM_DATA_ROOT` to its root. The code
locates the data through `smroot()`; see `code/config/smroot.m`.

The figure scripts read intermediates (per-session PCA and CCA results, decoding and
information-flow results) that are not deposited. They are rebuilt from the session files by
the upstream pipeline in `code/pipeline_cca/` and the analysis drivers, which write them into
the data folder. See `FIGURE_MAP.md` for which script produces what. Every plotted value is
also available in the article's Source Data file.

## Scope

The deposited data begin at the per-session files. `PREPROCESSING.md` documents how those
were made from the raw two-photon images (motion correction, CNMF segmentation, ROI
curation, denoising, deconvolution) and lists the parameters used, and it also covers whisker
tracking. That code is in `code/preprocessing/` and `code/whisker_tracking/` for transparency
and cannot be run from the deposited data.

## Citing

Please cite the article, and this code by its Zenodo DOI (TODO). `CITATION.cff` holds the
citation metadata; GitHub shows it as *Cite this repository*. Cite the dataset by its GIN
DOI (see *Data*), not by repository URL.

## License

MIT (`LICENSE`), with two exceptions: `code/lib/third_party/` (own licenses,
`THIRD_PARTY.md`) and `code/preprocessing/modified_gpl/` (GPL-2.0 / GPL-3.0 derivative
works, `code/preprocessing/modified_gpl/NOTICE.md`).
