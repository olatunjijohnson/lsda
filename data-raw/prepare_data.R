# ---------------------------------------------------------------------------
# prepare_data.R -- turn the raw course files into documented package datasets.
#
# Run from the package root:  Rscript data-raw/prepare_data.R
#
# Raw inputs live in ../../data-raw (one deduplicated copy of each file).
# This script is the ONLY place raw files are read; everything else in the
# course uses data(<name>).
# ---------------------------------------------------------------------------

raw <- normalizePath(file.path("..", "..", "data-raw"), mustWork = TRUE)
out <- "data"
dir.create(out, showWarnings = FALSE)
message("reading raw files from ", raw)

save_it <- function(obj, name) {
  assign(name, obj)
  save(list = name, file = file.path(out, paste0(name, ".rda")),
       compress = "xz", version = 3)
  message(sprintf("  %-16s %s", name,
                  paste(class(obj)[1], nrow(obj), "x", ncol(obj))))
}

# ---- 1. cattle -------------------------------------------------------------
# 60 animals, 2 treatment groups, bodyweight at 11 equally spaced times.
# Raw file is headerless: col 1 = group, cols 2-12 = the 11 weights.
#
# group is deliberately left as numeric 0/1 rather than converted to a factor.
# A factor is better R practice, but it breaks the existing course code in a
# silent and dangerous way: `cattle[, 1] == 0` returns an all-FALSE vector
# against a factor, so `cattle[which(cattle[, 1] == 0), ]` selects zero rows
# and the tutorial produces empty plots with no error at all. Recode to a
# factor only when the tutorial code is rewritten to match.
cattle <- utils::read.table(file.path(raw, "cattle.txt"), header = FALSE)
names(cattle) <- c("group", paste0("t", 1:11))
save_it(cattle, "cattle")

# ---- 2. fev1 ---------------------------------------------------------------
# Six Cities Study: lung function in 299 Topeka girls, unbalanced.
# NB the 2025 tree also carried air_pollution.csv, which is byte-for-byte this
# same data with two columns dropped. It is deliberately not reproduced here.
fev1 <- utils::read.csv(file.path(raw, "fev1_data.csv"))
save_it(fev1, "fev1")

# ---- 3. cd4 ----------------------------------------------------------------
# CD4+ counts in HIV seroconverters; time is years around seroconversion.
cd4 <- utils::read.table(file.path(raw, "cd4.txt"), header = TRUE)
save_it(cd4, "cd4")

# ---- 4. ichs ---------------------------------------------------------------
# Indonesian Children's Health Study: respiratory infection and vitamin A.
# Headerless; column order documented in the week 5 tutorial.
# gender and vitA left as numeric 0/1 for the same reason as cattle$group.
ichs <- utils::read.table(file.path(raw, "ichs.txt"), header = FALSE)
names(ichs) <- c("id", "infection", "time", "gender", "vitA", "age")
save_it(ichs, "ichs")

# ---- 5. galicia ------------------------------------------------------------
# Lead concentration in moss samples at 132 stations in Galicia, NW Spain.
galicia <- utils::read.csv(file.path(raw, "GaliciaData.csv"))
save_it(galicia, "galicia")

# Prediction grid and covariate surface for the week 8 kriging exercise.
galicia_grid <- utils::read.csv(file.path(raw, "grid_pred_galicia.csv"))
save_it(galicia_grid, "galicia_grid")
galicia_pred <- utils::read.csv(file.path(raw, "predictors_galicia.csv"))
save_it(galicia_pred, "galicia_pred")

# ---- 6. loaloa -------------------------------------------------------------
# Loa loa prevalence, 197 villages in Cameroon and southern Nigeria.
loaloa <- utils::read.csv(file.path(raw, "loaloaCameroon.csv"))
names(loaloa) <- tolower(names(loaloa))
save_it(loaloa, "loaloa")

# ---- 7. liberia ------------------------------------------------------------
liberia <- utils::read.csv(file.path(raw, "Liberia_malaria_height_data.csv"))
save_it(liberia, "liberia")
liberia_grid <- utils::read.csv(file.path(raw, "grid_pred_liberia.csv"))
save_it(liberia_grid, "liberia_grid")

# ---- 8. scotland_lip (sf) --------------------------------------------------
# Male lip cancer, 56 Scottish counties, 1975-1980.
#
# The raw shapefile carries no CRS and its coordinates are British National
# Grid divided by 1000 (i.e. kilometres): bbox is x 62-468, y 530-1219.
# We rescale to metres and declare EPSG:27700 so that the geometry works with
# basemaps, area calculations and tmap/mapview. Adjacency -- the only thing
# weeks 9 and 10 actually use the geometry for -- is unaffected by a uniform
# rescaling.
if (requireNamespace("sf", quietly = TRUE)) {
  s <- sf::st_read(file.path(raw, "scotland_lip.shp"), quiet = TRUE)
  sf::st_geometry(s) <- sf::st_geometry(s) * 1000          # km -> m
  sf::st_crs(s) <- 27700                                    # British National Grid
  names(s)[names(s) == "cnty_nm"]  <- "county"
  names(s)[names(s) == "expectd"]  <- "expected"
  names(s)[names(s) == "AFF"]      <- "aff"
  s$sir <- s$cases / s$expected
  scotland_lip <- s
  save_it(scotland_lip, "scotland_lip")
} else {
  message("  sf not available -- skipping scotland_lip")
}

# ---- 9. tef ----------------------------------------------------------------
tef <- utils::read.table(file.path(raw, "tef.txt"), header = TRUE)
save_it(tef, "tef")

# ---- 10. gm_no2, gm_grid ---------------------------------------------------
# Nitrogen dioxide at 25 monitoring stations across Greater Manchester, the
# running geostatistical example in weeks 7 and 8, with the covariates the
# lecture model uses: distance to the nearest major road, elevation and
# population. gm_grid is the matching 4996-point prediction grid.
# Coordinates are British National Grid (EPSG:27700), as in the raw files.
if (requireNamespace("sf", quietly = TRUE)) {
  p <- utils::read.csv(file.path(raw, "pollution_manchester_new.csv"))
  p <- p[, c("Station", "NO2", "PM10", "PM25", "elevation", "road", "pop",
             "UTMX", "UTMY")]
  names(p)[names(p) == "Station"] <- "station"
  gm_no2 <- sf::st_as_sf(p, coords = c("UTMX", "UTMY"), crs = 27700)
  save_it(gm_no2, "gm_no2")

  g <- utils::read.csv(file.path(raw, "GM_pred_grid_predictor.csv"))
  gm_grid <- sf::st_as_sf(g, coords = c("UTMX", "UTMY"), crs = 27700)
  save_it(gm_grid, "gm_grid")
} else {
  message("  sf not available -- skipping gm_no2 and gm_grid")
}

# ---- 11. nw_obesity --------------------------------------------------------
# Childhood obesity and income deprivation in the 33 local authority districts
# of North West England, the areal example in weeks 9 and 10. The shapefile's
# column names are truncated to 7 characters, so they are spelled out here.
if (requireNamespace("sf", quietly = TRUE)) {
  o <- sf::st_read(file.path(raw, "North_West_England_Obesity_Deprivation.shp"),
                   quiet = TRUE)
  keep <- c(LAD23CD = "lad_code", LAD23NM = "lad_name", num_obs = "num_obese",
            totl_sm = "total_sampled", prop_bs = "prop_obese",
            IDACI_s = "idaci_score", IDACI_R = "idaci_rank")
  o <- o[, c(names(keep), attr(o, "sf_column"))]
  names(o)[match(names(keep), names(o))] <- unname(keep)
  nw_obesity <- o
  save_it(nw_obesity, "nw_obesity")
} else {
  message("  sf not available -- skipping nw_obesity")
}

message("done.")
