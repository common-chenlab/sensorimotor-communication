# Modified third-party files: GPL, not MIT

The files in this folder are **modifications of GPL-licensed packages** made in the Chen
lab. They are derivative works, so they are distributed under their upstream licenses,
**not** under the MIT license that covers the rest of this repository (see
`../../../LICENSE`).

| File | Derived from | Upstream license |
|---|---|---|
| `normcorre_chen.m`, `normcorre_chen_batch.m` | [NoRMCorre](https://github.com/flatironinstitute/NoRMCorre) | GPL-2.0 |
| `filter_border_ROIs_jc.m`, `update_spatial_components_axg.m`, `update_temporal_components_axg.m` | [CaImAn-MATLAB](https://github.com/flatironinstitute/CaImAn-MATLAB) | GPL-2.0 |
| `deconvolveCaE.m` | [OASIS-matlab](https://github.com/zhoupc/OASIS_matlab) | GPL-3.0 |

They are included because they contain the motion-correction, segmentation and
deconvolution settings actually used to produce the deposited session files; see
`../../../PREPROCESSING.md`. They require the rest of their upstream packages, which are
not redistributed here.

Each file keeps its original header. Full license texts: the upstream repositories, or the
`license.txt` / `LICENSE` in the lab's package copies.
