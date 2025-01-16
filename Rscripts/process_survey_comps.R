# process survey comps
# see also explorations of changes in growth over space and time in the
# "Survey data" section of /docs/data_summary_doc.qmd

require(dplyr)
require(ggplot2)

dir_wcgbts <- here::here("Data/Raw_not_confidential/wcgbts")
dir_tri <- here::here("Data/Raw_not_confidential/triennial")

# pull survey data from data warehouse (skip unless it's been updated)
new_pull <- FALSE
if (new_pull) {
  yt_survey_bio <- nwfscSurvey::pull_bio(
    common_name = "yellowtail rockfish",
    survey = "NWFSC.Combo",
    dir = dir_wcgbts
  )
  yt_tri_bio <- nwfscSurvey::pull_bio(
    common_name = "yellowtail rockfish",
    survey = "Triennial",
    dir = dir_tri
  )
  yt_survey_catch <- nwfscSurvey::pull_catch(
    common_name = "yellowtail rockfish",
    survey = "NWFSC.Combo",
    dir = dir_wcgbts
  )
  yt_tri_catch <- nwfscSurvey::pull_catch(
    common_name = "yellowtail rockfish",
    survey = "Triennial",
    dir = dir_tri
  )
} else {
  # read saved data files TODO: update after 2024 survey data is available
  load(file.path(dir_wcgbts, "bio_yellowtail rockfish_NWFSC.Combo_2025-01-14.rdata"))
  yt_survey_bio <- x
  load(file.path(dir_tri, "bio_yellowtail rockfish_Triennial_2025-01-14.rdata"))
  yt_tri_bio <- x
  load(file.path(dir_wcgbts, "catch_yellowtail rockfish_NWFSC.Combo_2025-01-15.rdata"))
  yt_survey_catch <- x
  load(file.path(dir_tri, "catch_yellowtail rockfish_Triennial_2025-01-15.rdata"))
  yt_tri_catch <- x
}

# filter by latitude
yt_n_survey_bio <- filter(yt_survey_bio, Latitude_dd > 40 + 1 / 6)
yt_n_tri_bio <- purrr::map(yt_tri_bio, \(dat) filter(dat, Latitude_dd > 40 + 1 / 6))
yt_n_survey_catch <- filter(yt_survey_catch, Latitude_dd > 40 + 1 / 6)
yt_n_tri_catch <- filter(yt_tri_catch, Latitude_dd > 40 + 1 / 6)

strata <- nwfscSurvey::CreateStrataDF.fn(
  names = c("shallow", "deep"),
  depths.shallow = c(55, 183),
  depths.deep = c(183, 400), # note 99.9% of fish are less than 253m
  lats.south = c(40.166667, 40.166667),
  lats.north = c(49, 49)
)

# get age and length bins
source(here::here("Rscripts/bins.R"))

wcgbts_length_comps <- nwfscSurvey::get_expanded_comps(
  bio_data = yt_n_survey_bio,
  catch_data = yt_n_survey_catch,
  comp_bins = len_bin,
  strata = strata,
  comp_column_name = "length_cm",
  output = "full_expansion_ss3_format",
  two_sex_comps = TRUE,
  input_n_method = "stewart_hamel",
  month = 7,
  fleet = 999,
  dir = dir_wcgbts
)

wcgbts_raw_length_comps <- nwfscSurvey::get_raw_comps(
  data = yt_n_survey_bio,
  comp_bins = len_bin,
  comp_column_name = "length_cm",
  two_sex_comps = TRUE,
  dir = dir_wcgbts,
  month = 7,
  fleet = 999
)

nwfscSurvey::plot_comps(
  data = wcgbts_raw_length_comps,
  dir = dir_wcgbts
)
file.copy(
  file.path(dir_wcgbts, "plots/length_frequency_sex_3.png"),
  file.path(dir_wcgbts, "plots/length_frequency_raw_sex_3.png")
)
file.copy(
  file.path(dir_wcgbts, "plots/length_r4ss_frequency_sex_3.png"),
  file.path(dir_wcgbts, "plots/length_r4ss_frequency_raw_sex_3.png")
)
nwfscSurvey::plot_comps(
  data = wcgbts_length_comps,
  dir = dir_wcgbts
)

# save processed data as RDS file
saveRDS(wcgbts_length_comps$sexed, file = here::here("Data/Processed/ss3_wcgbts_length_comps.rds"))

# age comps (marginal)
wcgbts_age_comps <- nwfscSurvey::get_expanded_comps(
  bio_data = yt_n_survey_bio,
  catch_data = yt_n_survey_catch,
  comp_bins = age_bin,
  strata = strata,
  comp_column_name = "age",
  output = "full_expansion_ss3_format",
  two_sex_comps = TRUE,
  input_n_method = "stewart_hamel",
  month = 7,
  fleet = 999,
  dir = dir_wcgbts
)

wcgbts_raw_age_comps <- nwfscSurvey::get_raw_comps(
  data = yt_n_survey_bio,
  comp_bins = age_bin,
  comp_column_name = "age",
  two_sex_comps = TRUE,
  dir = dir_wcgbts,
  age_error = 1,
  month = 7,
  fleet = 999
)

nwfscSurvey::plot_comps(
  data = wcgbts_raw_age_comps,
  dir = dir_wcgbts
)
file.copy(
  file.path(dir_wcgbts, "plots/age_frequency_sex_3.png"),
  file.path(dir_wcgbts, "plots/age_frequency_raw_sex_3.png")
)
file.copy(
  file.path(dir_wcgbts, "plots/age_r4ss_frequency_sex_3.png"),
  file.path(dir_wcgbts, "plots/age_r4ss_frequency_raw_sex_3.png")
)
nwfscSurvey::plot_comps(
  data = wcgbts_age_comps,
  dir = dir_wcgbts
)

# save processed data as RDS file
saveRDS(wcgbts_age_comps$sexed, file = here::here("Data/Processed/ss3_wcgbts_age_comps.rds"))

# age comps (conditional)
# TODO