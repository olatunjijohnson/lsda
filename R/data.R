# Dataset documentation. Objects themselves are built by data-raw/prepare_data.R.

#' Cattle bodyweight data
#'
#' Bodyweight of 60 cattle in two treatment groups, recorded at 11 equally
#' spaced time points. A balanced design: every animal is measured at every
#' time, which makes it the natural first example for exploring within-subject
#' correlation.
#'
#' @format A data frame with 60 rows and 12 columns:
#' \describe{
#'   \item{group}{treatment group, coded 0 and 1}
#'   \item{t1}{bodyweight in kilograms at time 1}
#'   \item{t2}{bodyweight in kilograms at time 2}
#'   \item{t3}{bodyweight in kilograms at time 3}
#'   \item{t4}{bodyweight in kilograms at time 4}
#'   \item{t5}{bodyweight in kilograms at time 5}
#'   \item{t6}{bodyweight in kilograms at time 6}
#'   \item{t7}{bodyweight in kilograms at time 7}
#'   \item{t8}{bodyweight in kilograms at time 8}
#'   \item{t9}{bodyweight in kilograms at time 9}
#'   \item{t10}{bodyweight in kilograms at time 10}
#'   \item{t11}{bodyweight in kilograms at time 11}
#' }
#' @source Used throughout weeks 1-3 of MATH48132/68132. Originally distributed
#'   as a headerless text file; column names added here.
#' @examples
#' data(cattle)
#' spaghetti_plot(cattle, group = "group")
#' round(cor(cattle[, -1]), 2)
"cattle"

#' Lung function growth in Topeka schoolgirls (FEV1)
#'
#' Repeated spirometry measurements on 299 girls from Topeka, Kansas, enrolled
#' in the Six Cities Study of Air Pollution and Health. Girls entered at around
#' age 6-10 and were followed roughly annually. The number of observations per
#' girl ranges from 1 to 12, so the design is markedly unbalanced -- the
#' counterpart to the balanced \code{\link{cattle}} data.
#'
#' @format A data frame with 1993 rows and 8 columns:
#' \describe{
#'   \item{id}{girl identifier}
#'   \item{ht}{height in metres at the visit}
#'   \item{age}{age in years at the visit}
#'   \item{baseht}{height in metres at the first visit}
#'   \item{baseage}{age in years at the first visit}
#'   \item{logfev1}{log of FEV1}
#'   \item{fev1}{forced expiratory volume in one second, in litres}
#'   \item{logfev1_ht}{log(FEV1 / height), the usual response}
#' }
#' @source Six Cities Study of Air Pollution and Health.
#' @note The 2025 course tree also contained \code{air_pollution.csv}, which is
#'   this same data with \code{fev1} and \code{logfev1_ht} dropped. It is not
#'   reproduced here; use \code{fev1}.
#' @examples
#' data(fev1)
#' table(table(fev1$id))   # observations per girl: the design is unbalanced
"fev1"

#' CD4+ cell counts in HIV seroconverters
#'
#' Longitudinal CD4+ counts with time measured in years relative to
#' seroconversion, so negative times precede it. Highly unbalanced in both the
#' number and the spacing of visits.
#'
#' @format A data frame with 2376 rows and 8 columns:
#' \describe{
#'   \item{time}{years since seroconversion (negative before)}
#'   \item{cd4}{CD4+ cell count}
#'   \item{age}{age in years, centred}
#'   \item{cig}{cigarette smoking}
#'   \item{drug}{recreational drug use, 0/1}
#'   \item{partner}{number of sexual partners}
#'   \item{cesd}{depression score (CES-D scale)}
#'   \item{subject}{subject identifier}
#' }
#' @source Multicenter AIDS Cohort Study.
"cd4"

#' Indonesian Children's Health Study (ICHS)
#'
#' 250 preschool children examined at entry and then every three months for a
#' year. The question of interest is whether vitamin A deficiency raises the
#' risk of respiratory infection. The binary response and repeated measures make
#' this the standard GEE and GLMM example.
#'
#' @format A data frame with 1500 rows and 6 columns:
#' \describe{
#'   \item{id}{child identifier}
#'   \item{infection}{respiratory infection present, 0 = absent, 1 = present}
#'   \item{time}{months since the first visit}
#'   \item{gender}{0 = male, 1 = female}
#'   \item{vitA}{vitamin A status, 0 = sufficient, 1 = deficient}
#'   \item{age}{age in years}
#' }
#' @source Indonesian Children's Health Study. Used in week 5.
"ichs"

#' Lead concentration in moss samples, Galicia
#'
#' Lead concentration measured in moss at 132 sampling stations across Galicia,
#' north-west Spain, with a co-located PM10 measurement. The running example for
#' the geostatistical weeks: variogram estimation in week 7, model fitting and
#' kriging in week 8.
#'
#' @format A data frame with 132 rows and 5 columns:
#' \describe{
#'   \item{lead}{lead concentration}
#'   \item{loglead}{log lead concentration, the modelled response}
#'   \item{long}{longitude in decimal degrees}
#'   \item{lat}{latitude in decimal degrees}
#'   \item{pm10}{particulate matter under 10 micrometres}
#' }
#' @seealso \code{\link{galicia_grid}} and \code{\link{galicia_pred}} for
#'   prediction.
#' @section Name clash: \pkg{RiskMap} also ships a \code{galicia}, with three
#'   columns (\code{x}, \code{y}, \code{lead}). Both packages are attached in the
#'   week 7 and 8 tutorials, so load this one with
#'   \code{data(galicia, package = "lsda")}.
"galicia"

#' Prediction grid for Galicia
#'
#' A regular grid covering the Galicia study region, for mapping kriging
#' predictions in week 8.
#'
#' @format A data frame with 1508 rows and 2 columns, \code{X} and \code{Y},
#'   in kilometres.
#' @seealso \code{\link{galicia}}
"galicia_grid"

#' Covariate surface for Galicia prediction
#'
#' PM10 and coordinates at each prediction location, so that models including
#' PM10 as a covariate can be used for prediction.
#'
#' @format A data frame with 1508 rows and 3 columns: \code{pm10},
#'   \code{long}, \code{lat}.
#' @seealso \code{\link{galicia}}
"galicia_pred"

#' Loa loa prevalence in Cameroon and Nigeria
#'
#' Village-level survey results for Loa loa (eyeworm) from 197 villages across
#' Cameroon and southern Nigeria, with elevation and NDVI vegetation covariates.
#' A binomial response, so it extends the Gaussian geostatistics of weeks 7-8
#' to the generalised case.
#'
#' @format A data frame with 197 rows and 11 columns:
#' \describe{
#'   \item{row}{row identifier}
#'   \item{villcode}{village identifier}
#'   \item{longitude, latitude}{decimal degrees}
#'   \item{no_exam}{number of individuals tested}
#'   \item{no_inf}{number testing positive}
#'   \item{elevation}{metres above sea level}
#'   \item{mean9901, max9901, min9901, stdev9901}{NDVI summaries, 1999-2001}
#' }
#' @references Diggle, P.J., Thomson, M.C., Christensen, O.F., Rowlingson, B.,
#'   Obsomer, V., Gardon, J., Wanji, S., Takougang, I., Enyong, P., Kamgno, J.,
#'   Remme, H., Boussinesq, M. and Molyneux, D.H. (2007). Spatial modelling and
#'   prediction of Loa loa risk: decision making under uncertainty.
#' @section Name clash: \pkg{RiskMap} also ships a \code{loaloa} --- the same
#'   survey, but with upper-case column names. Load this one with
#'   \code{data(loaloa, package = "lsda")}.
"loaloa"

#' Malaria incidence and child growth in Liberia
#'
#' Cluster-level malaria incidence with height-for-age z-scores, used as the
#' week 8 challenge dataset.
#'
#' @format A data frame with 267 rows and 5 columns:
#' \describe{
#'   \item{cluster}{cluster identifier}
#'   \item{height_for_age_zscores}{mean height-for-age z-score}
#'   \item{longitude, latitude}{decimal degrees}
#'   \item{malaria_incidence_rate}{incidence rate}
#' }
#' @seealso \code{\link{liberia_oncho}}, the river-blindness survey used in the
#'   week 8 challenge, which is a different dataset despite the similar name.
"liberia"

#' River blindness in Liberia
#'
#' Reported onchocerciasis (river blindness) nodule counts from 90 villages
#' sampled across Liberia, with village elevation. The week 8 challenge: a
#' binomial geostatistical model, where the response is a count out of a total
#' rather than a continuous measurement.
#'
#' @format A data frame with 90 rows and 6 columns:
#' \describe{
#'   \item{lat, long}{decimal degrees}
#'   \item{ntest}{number of people tested for the presence of nodules}
#'   \item{npos}{number testing positive}
#'   \item{elevation}{village elevation in metres}
#'   \item{log_elevation}{log of the elevation}
#' }
#' @source Redistributed from the \pkg{RiskMap} package by Emanuele Giorgi,
#'   under its MIT licence, so that the exercise runs in the browser without
#'   \pkg{RiskMap}, which cannot load under WebAssembly.
#' @seealso \code{\link{liberia}} for the unrelated malaria and child-growth
#'   dataset, and \code{\link{liberia_grid}} for a prediction grid.
"liberia_oncho"

#' Prediction grid for Liberia
#'
#' @format A data frame with 3837 rows and 2 columns, \code{X} and \code{Y}.
#' @seealso \code{\link{liberia}}
"liberia_grid"

#' Male lip cancer in Scottish counties, 1975-1980
#'
#' Observed and expected male lip cancer cases in each of the 56 Scottish
#' counties, with the proportion of the workforce in agriculture, fishing and
#' forestry (AFF) as a proxy for sunlight exposure. The running example for the
#' areal weeks: Moran's I in week 9, CAR and ICAR models in week 10.
#'
#' @format An \code{sf} data frame with 56 features and 6 columns:
#' \describe{
#'   \item{county}{county name}
#'   \item{cases}{observed cases}
#'   \item{expected}{expected cases given the age-sex structure}
#'   \item{aff}{proportion employed in agriculture, fishing or forestry}
#'   \item{sir}{standardised incidence ratio, \code{cases / expected}}
#'   \item{geometry}{county polygon}
#' }
#' @section Coordinate reference system:
#' The original shapefile declared no CRS and its coordinates were British
#' National Grid divided by 1000. Here the geometry is rescaled to metres and
#' tagged \code{EPSG:27700}, so basemaps and area calculations behave. Adjacency
#' -- the only property weeks 9 and 10 rely on -- is unchanged by rescaling.
#' @source Clayton and Kaldor (1987); Breslow and Clayton (1993).
#' @examples
#' data(scotland_lip)
#' head(scotland_lip$sir)
"scotland_lip"

#' Nitrogen dioxide in Greater Manchester
#'
#' Nitrogen dioxide (NO2) measured at 25 monitoring stations across Greater
#' Manchester, the running geostatistical example in weeks 7 and 8: the
#' variogram of the residuals in week 7, and model fitting and prediction in
#' week 8.
#'
#' @format An \code{sf} data frame with 25 features and 8 columns:
#' \describe{
#'   \item{station}{monitoring station name}
#'   \item{NO2}{nitrogen dioxide concentration}
#'   \item{PM10, PM25}{particulate matter concentrations}
#'   \item{elevation}{elevation in metres}
#'   \item{road}{distance to the nearest major road, in metres}
#'   \item{pop}{population count of the surrounding cell}
#'   \item{geometry}{station location, EPSG:27700}
#' }
#' @seealso \code{\link{gm_grid}} for the prediction grid.
#' @examples
#' data(gm_no2)
#' summary(gm_no2$NO2)
"gm_no2"

#' Prediction grid for Greater Manchester
#'
#' A regular grid covering Greater Manchester, carrying the same covariates as
#' \code{\link{gm_no2}}, for mapping predictions in week 8.
#'
#' @format An \code{sf} data frame with 4996 features and 4 columns:
#' \describe{
#'   \item{elevation}{elevation in metres}
#'   \item{pop}{population count of the cell}
#'   \item{road}{distance to the nearest major road, in metres}
#'   \item{geometry}{grid point, EPSG:27700}
#' }
#' @examples
#' data(gm_grid)
#' nrow(gm_grid)
"gm_grid"

#' Childhood obesity and deprivation in North West England
#'
#' Childhood obesity and income deprivation for the 33 local authority
#' districts of North West England, the areal example in weeks 9 and 10.
#'
#' @format An \code{sf} data frame with 33 features and 8 columns:
#' \describe{
#'   \item{lad_code, lad_name}{local authority district code and name}
#'   \item{num_obese}{number of children measured as obese}
#'   \item{total_sampled}{number of children measured}
#'   \item{prop_obese}{\code{num_obese / total_sampled}}
#'   \item{idaci_score}{Income Deprivation Affecting Children Index, average score}
#'   \item{idaci_rank}{rank of the IDACI score (lower is more deprived)}
#'   \item{geometry}{district polygon, EPSG:27700}
#' }
#' @source National Child Measurement Programme small-area data and the English
#'   Indices of Deprivation 2019, both published by gov.uk.
#' @examples
#' data(nw_obesity)
#' summary(nw_obesity$prop_obese)
"nw_obesity"

#' Teacher effectiveness survey summaries
#'
#' Summary statistics from a teacher effectiveness survey, used as a secondary
#' example.
#'
#' @format A data frame with 37 rows and 11 columns.
"tef"
