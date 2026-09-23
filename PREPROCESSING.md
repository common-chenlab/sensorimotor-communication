# Preprocessing: raw two-photon images → session files

The deposited data start at the per-session files
(`Animals/<animal>/<animal>-<session>.mat`). This document describes how those were
produced from the raw microscope images, which are **not** deposited.

The code for these steps is in `code/preprocessing/`. It is included for transparency and
**cannot be run from the deposited data**: it needs the raw TIFF series and the lab's
acquisition storage layout (`W:`/`V:`/`X:` project drives, session folders with
`Behavior`/`PreProcess` subfolders), and the ROI curation step is interactive. The
analysis code that *can* be run from the deposited data is described in `README.md` and
`FIGURE_MAP.md`.

## Steps

Run in this order, per animal and session, for each of the four imaging areas (`A0` = S1,
`A1` = S2, `A2` = M1_A, `A3` = M1_B; channel 1 is the jYCaMP1s channel, channel 0
mCherry). `TestPipeline.m` in the lab pipeline folder is the scratch driver that calls
them.

| Step | Script | What it does |
|---|---|---|
| 01 | `CHEN_2P_Pipeline_Step_01.m` | Resonance-scanner flip/dewarp correction (`flip/`), then frame-wise motion correction with NoRMCorre, non-rigid (piece-wise rigid) enabled. Creates the session `.mat`. |
| 02a | `CHEN_2P_Pipeline_Step_02a.m` | Trial-by-trial alignment of every trial to a reference trial within the session. |
| 02b | `CHEN_2P_Pipeline_Step_02b.m` | Temporal downsampling and initial segmentation with CNMF (`run_CNMF_patches`), producing candidate ROIs. |
| (none) | ROI curation (interactive, `CurateROIs.m`) | CNMF ROIs are curated by hand against the structural projections, giving the `_REF` ROI set used downstream. Described below; code not deposited. |
| (none) | DeepInterpolation (`deepinterpolation/`) | Removes independent (photon shot) noise per trial movie, writing the `_dp` files that step 03 reads. Run on the compute cluster: `create_json.py` lists the session `.mat` files, `deep_interpolation_scc_gpu_andrew.sh` submits the job, `inference_GPU_SCC.py` runs inference with a trained model. |
| 03 | `CHEN_2P_Pipeline_Step_03_Area_SCC.m` | Extracts fluorescence for the curated (`REF`) ROIs and re-estimates background/neuropil, per area on the compute cluster. Reads DeepInterpolation-denoised movies (`_dp`) by default. Per-area outputs are merged with `RecombineAreas`. |
| 04 | `CHEN_2P_Pipeline_Step_04_old.m` | mCherry labelling of the M1 areas: identifies M1→S1/S2 projection neurons from the static (mCherry) and activity (jYCaMP1s) channels. Run for `A2`/`A3` only. |
| 07 | `CHEN_2P_Pipeline_Step_07.m` | Notch-filters the traces, subtracts baseline, and deconvolves to calcium event estimates (`deconvolve_traces.m` → `deconvolveCaE`, OASIS). Writes `F_df_REF`, `s_oasis`, `deconv_REF`. |

Step 04 runs independently of 02a–07 (it needs only the registered images and the curated
ROIs); the order above is the order it appears in the lab driver.

## Parameters

Recorded in the deposited session files (`FOV`, `sampling_rate`, `CNMFOptions`, `notch`,
`deconv_params`, `trial_noise` per area), so the exact values used for a session travel
with the data. Values below are from `sm045-4` and match the script defaults.

**Acquisition.** FOV 330 × 480 pixels per area; frame rate 32.258 Hz for A0/A1 and 31.056
Hz for A2/A3.

**Step 01, motion correction** (`modified_gpl/normcorre_chen_batch.m`): p × q spatial
binning, shift ceilings 30 px (x) and 50 px (y). Rigid pass `bin_width` 30, `us_fac` 2.
Non-rigid pass `grid_size` [100,100], `mot_uf` 4, `bin_width` 60, `max_shift` 25,
`max_dev` 25, `us_fac` 4, `min_patch_size` [16,16,16], `overlap_post` [25,25,16].

**Step 02b, CNMF**: temporal downsample factor 10; `K` = 4 components per patch;
`tau`/`gSig` = [5,10]; AR order `p` = 2; `merge_thr` 0.8; `min_SNR` 2; `init_method`
greedy; `search_method` dilate; `temporal_iter` 4.

**DeepInterpolation.** Jobs were submitted on the BU Shared Computing Cluster with
`deep_interpolation_scc_gpu_andrew.sh` (one GPU, `gpu_c=7.0`), which runs
`inference_GPU_SCC.py` over the file list built by `create_json.py`. Inference used
`~/trained_model.h5` (md5 `8318ba5481747463c256d74753e404cf`, modified 2023-01-24), a
transfer-trained network distinct from the two 2024 transfer models in the same folder.
Generator settings: `SingleTifGenerator`, `pre_post_frame` 30, `pre_post_omission` 0,
`batch_size` 5 (1 on the chunked path), `randomize` 0; output written as `<name>_dp.mat`.

Those three scripts are vendored in `code/preprocessing/deepinterpolation/` with their
provenance and checksums; see the README there. They come from the lab fork
`github.com/mitchclough/deepinterpolation` (branch `sensorimotor`, commit `9f4b377` plus
uncommitted local changes, which are what ran). The Allen Institute package itself is not
redistributed: its license is a 2-clause BSD with an added clause restricting redistribution
and commercial use. The model weights are deposited at `data/models/trained_model.h5`.

**ROI curation.** Between steps 02b and 03, the automatically detected CNMF ROIs are curated
by hand, once per animal, session and area, with `CurateROIs.m` in the lab pipeline
(`Analysis Suite/PIPELINE/2P/ROI Curation/`). The tool is interactive and is not deposited;
its result is, since the curated ROIs are stored in the session files as `ROIs_REF` (outlines)
and `cellid_REF` (identities), and every later step uses those rather than the raw CNMF set.

The procedure:

1. Load the session's mean, activity and maximum-intensity projections (from the denoised
   movies where available) together with the CNMF ROIs (`ROIs`, `cellid`).
2. Inspect the morphology of the detected ROIs (area, eccentricity, solidity) against those
   projections and choose cutoffs.
3. Drop ROIs below the cutoffs, then delete or adjust the survivors by eye.
4. Draw outlines for cells visible in the structural images that CNMF missed.
5. Save the result back into the session file as `ROIs_REF` and `cellid_REF` for that area.

Curation starts from the previous curated set when one exists, so ROIs are adjusted per
session to follow tissue changes across the chronic imaging window, as the Methods state.

**Step 04, mCherry labelling.** Per-pixel selectivity is the angle `atand(activity_channel
/ static_channel)`; `label_cell_type_ratio` reduces it per ROI; the threshold is `gfpangle
- (gfpangle - rfpangle)/3` and is stored per area as `celltype_angle_thres`.
`celltype_REF_angle` (ROI angle below threshold) is the mCherry+ flag, and it is the one
the analysis uses: `LoadMultiFOV` reads it into `fov.roi_mch`, which drives Fig. 6 and
`exclude_mcherry_cells`. `skipflip` is false for sm056 and sm057, true otherwise.

`CHEN_2P_Pipeline_Step_04_edit.m` is also included: it writes an alternative flag
`celltype_REF_new` (`> 0.2` on a ratio-regression measure), which is present in the data
but **not** used by the analysis; the line reading it in `LoadMultiFOV` is commented out.
Both variants are shipped because both left fields in the deposited files. A search of the
whole Analysis Suite finds `celltype_REF_angle` written only by `Step_04_old.m` and read only
by `LoadMultiFOV.m`. File dates are consistent with `Step_04_old.m` having been run most
recently: it was modified 2026-02-14, the same date as the `sm041` and `sm045` session files,
while `Step_04_edit.m` dates to 2024-01-24, matching the older session files. **(confirm)**
which was run for which sessions.

**Step 07, deconvolution** (`deconv_params` as stored): `ROI_type` REF; notch 1.5 Hz, Q =
2 (suppresses laser crosstalk between the scan engines); decay `tau_d` 1800 ms; rise
`tau_r` 100 ms; `thresh_min` 0.1; `base_thresh` 10th percentile; `spike_thresh` 1;
`min_dur` 4 s; `min_frame` 129.

## Whisker tracking

High-speed whisker videos (500 fps) are processed separately from the two-photon data, in
`code/whisker_tracking/`. `Steps_236.m` is the driver and runs three steps per session; the
names come from the lab's longer numbering, of which only 2, 3 and 6 are used here.

| Step | Function | What it does |
|---|---|---|
| 2 | `panel_tracking/OBJECT_TRACKING_NOTRAINING.m` | Tracks the texture panel. An ROI is drawn around the rotator by hand, then tracking runs over the session (`texture` = frame with the panel presented, `scaleFactor` 0.2 threshold). |
| 3 | `TRACE_WHISKER_NO_TRAIN.m` | Traces whiskers by calling the Janelia Whisker Tracker binaries `trace` and `measure`, the latter with the face coordinates read off the video. Produces `.whiskers` and `.measurements` files. |
| 6 | `import_measurements/IMPORT_MEASUREMENTS.m` | Reads those files back, derives angle, curvature and touch, and writes the per-session `<animal>-<session>_whisker.mat` used by the analysis. |

Per-session settings that must be set in `Steps_236.m`: `anm`, `session`, `face_x`/`face_y`
(the face position, taken from the Janelia GUI), `framerate` 500, and the raw/output roots.

The Janelia Whisker Tracker itself is **not** redistributed: steps 3 depends on its command
line binaries being installed and on the `.detectorbank` files that ship with it. The MATLAB
readers for its output (`LoadWhiskers.m`, `LoadMeasurements.m`, by Nathan Clack, HHMI) are
included under `code/lib/third_party/janelia_whisker/`. Cite the tracker in the Methods
(reference 39 of the manuscript).

Several of these functions carry `if nargin == 0` example blocks with paths from other lab
projects (Voltage, Delayed Non-Match). Those are defaults for interactive use and are
overridden when the functions are called from `Steps_236.m`.

Progress notifications to Slack were removed: the lab versions post to an incoming webhook,
which is a credential. The build redacts any webhook URL it finds, and
`code/config/SendSlackNotification.m` is a no-op stub so the calls remain harmless.

## Third-party packages (not redistributed here)

Cite these in the Methods; the repository does not include them.

| Package | Role | License | Version |
|---|---|---|---|
| [NoRMCorre](https://github.com/flatironinstitute/NoRMCorre) | motion correction (step 01) | GPL-2.0 | master-branch snapshot, no commit recorded; the lab copy carries local edits (e.g. `normcorre_chen_batch.m`) |
| [CaImAn-MATLAB](https://github.com/flatironinstitute/CaImAn-MATLAB) | CNMF segmentation (step 02b) | GPL-2.0 | master-branch snapshot, no commit recorded; the lab copy carries local edits |
| [OASIS-matlab](https://github.com/zhoupc/OASIS_matlab) | deconvolution (step 07) | GPL-3.0 | master-branch snapshot, no commit recorded |
| [Janelia Whisker Tracker](https://github.com/nclack/whisk) (Clack et al. 2012) | whisker tracing (whisker step 3) | Janelia Farm Research Campus Software Copyright 1.1 (see `licenses/`) | master-branch snapshot, no commit recorded |
| [DeepInterpolation](https://github.com/AllenInstitute/deepinterpolation) (Allen Institute) | denoising before step 03 | 2-clause BSD + non-commercial/redistribution clause | fork `mitchclough/deepinterpolation`, branch `sensorimotor`, commit `9f4b377` + local changes |

`code/preprocessing/modified_gpl/` holds six files that the lab modified inside those
packages (`normcorre_chen.m`, `normcorre_chen_batch.m`, `filter_border_ROIs_jc.m`,
`update_spatial_components_axg.m`, `update_temporal_components_axg.m`, `deconvolveCaE.m`).
They are derivative works of GPL-licensed code and are distributed under the upstream
licenses, not the repository's MIT license; see
`code/preprocessing/modified_gpl/NOTICE.md`. They are included because they set the
parameters and behaviour that shaped the deposited signals.

## Open points

- **DeepInterpolation model provenance.** The scripts, the model identity and the run
  settings are pinned (confirmed by A. Blaeser, 2026-09-17), and the weights are deposited
  at `data/models/trained_model.h5`. What is not known is how that network was trained: the
  file predates A.B. joining the lab and was not made by the current authors, so its base
  model and training data are unrecorded. Worth asking M. Clough before submission.
- **ROI curation** is described below but its code is not deposited, by author decision: it
  is an interactive tool whose output (the `_REF` ROI sets) is already in the deposited
  session files.
- **Step 04 variant.** `Step_04_old.m` is the only variant that writes
  `celltype_REF_angle` and `celltype_angle_thres`, and `Step_04_edit.m` the only one that
  writes `celltype_REF_new`. Between them they account for every `celltype_*` field in
  `CaA2`/`CaA3`, so both are included. The other variants in the lab folder (`Step_04.m`,
  `_ratio.m`, `_ratio_test.m`, `-swich_filters.m`) write `celltype_REF` only or nothing,
  and are not included. **(confirm)** by the author.
- **Package versions** for the citations above.
