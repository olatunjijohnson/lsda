# lsda

Course materials for **MATH48132 / MATH68132 Longitudinal and Spatial Data
Analysis** at the University of Manchester: the datasets used across the eleven
teaching weeks, a few teaching helper functions, and four interactive Shiny
applications.

Installing this package gives you every dataset the course uses, documented,
in one step — so tutorial code runs without hunting for CSV files.

## Install

```r
install.packages("lsda", repos = c("https://olatunjijohnson.r-universe.dev",
                                   "https://cloud.r-project.org"))
```

The r-universe repository serves pre-built binaries, so no compiler is needed.
To build from source instead:

```r
# install.packages("remotes")
remotes::install_github("olatunjijohnson/lsda")
```

## Datasets

```r
library(lsda)
data(package = "lsda")   # list everything
?galicia                 # variables, units and source for any one
```

`RiskMap` ships datasets called `galicia`, `loaloa` and `liberia` too, with
different contents, and weeks 7 and 8 attach both packages. Name the package
when you load one — `data(galicia, package = "lsda")` — or whichever was
attached last will win.

| Dataset | Weeks | Description |
|---|---|---|
| `cattle` | 1–3 | Bodyweight of 60 cattle at 11 times. Balanced design. |
| `fev1` | 1–2 | Lung function in 299 Topeka girls. Unbalanced. |
| `cd4` | — | CD4+ counts around seroconversion. |
| `ichs` | 5 | Respiratory infection and vitamin A in 250 children. |
| `galicia` | 7–8 | Lead in moss at 132 Galician stations. |
| `galicia_grid`, `galicia_pred` | 8 | Prediction grid and covariate surface. |
| `loaloa` | 7 | Loa loa prevalence, 197 villages. |
| `liberia`, `liberia_grid` | — | Malaria incidence and child growth. Not the onchocerciasis data used in the week 8 challenge — that one is `RiskMap::liberia`. |
| `scotland_lip` | 9–10 | Male lip cancer, 56 Scottish counties (`sf`). |
| `gm_no2` | 7–8 | NO₂ at 25 Greater Manchester monitoring stations (`sf`). |
| `gm_grid` | 8 | 4996-point prediction grid for Greater Manchester (`sf`). |
| `nw_obesity` | 9–10 | Child obesity and IDACI, 33 NW England districts (`sf`). |
| `tef` | — | Teacher effectiveness survey summaries. |

## Helper functions

| Function | Purpose |
|---|---|
| `spaghetti_plot()` | One line per subject, wide or long format |
| `cov_structure()` | Build independent / exchangeable / AR(1) / ARMA(1,1) matrices |
| `emp_variogram_mc()` | Monte Carlo envelope test for spatial correlation |
| `sir()` | Standardised incidence ratio |
| `run_app()` | Launch a course application |

## Interactive applications

```r
run_app()                    # list what is available
run_app("gee_robustness")
```

| App | Week | What it shows |
|---|---|---|
| `cov_explorer` | 2 | What each within-subject covariance structure looks like |
| `lmm_simulator` | 2–3 | Set true parameters, fit, and watch the estimates vary |
| `gee_robustness` | 5 | Why a wrong working correlation still gives an unbiased slope |
| `variogram` | 7 | Nugget, sill, range, and the shape each family implies |

## Notes

- `scotland_lip` geometry is in metres, tagged `EPSG:27700`. The original
  shapefile carried no CRS and coordinates in kilometres, so any
  distance-valued argument has to be scaled — `spdep::dnearneigh(d2 = 50000)`
  for 50 km, not `50`.
- Orkney, Shetland and the Western Isles share no boundary with anything, so
  `poly2nb()` correctly gives them no neighbours. Do **not** reach for a large
  snapping tolerance to fix it: `snap = 200000` takes the mean number of
  neighbours from 4.2 to 46.6 out of a possible 55 — very nearly a complete
  graph — and Moran's I on the lip-cancer SIRs falls from 0.44 to 0.05. Either
  keep the empty sets with `zero.policy = TRUE`, or join each island to its
  nearest county.
- `cattle$group`, `ichs$gender` and `ichs$vitA` are kept as numeric 0/1 rather
  than factors, so that existing course code comparing them to `0` and `1`
  keeps working.
- `data-raw/prepare_data.R` records how each dataset was derived. It expects
  the raw files from the private course repository and will not run here.

## Licence

CC BY-NC-SA 4.0
