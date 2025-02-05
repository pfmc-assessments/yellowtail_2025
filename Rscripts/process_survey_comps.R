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
  load(file.path(dir_wcgbts, "bio_yellowtail rockfish_NWFSC.Combo_2025-01-28.rdata"))
  yt_survey_bio <- x
  load(file.path(dir_tri, "bio_yellowtail rockfish_Triennial_2025-01-28.rdata"))
  yt_tri_bio <- x
  load(file.path(dir_wcgbts, "catch_yellowtail rockfish_NWFSC.Combo_2025-01-28.rdata"))
  yt_survey_catch <- x
  load(file.path(dir_tri, "catch_yellowtail rockfish_Triennial_2025-01-28.rdata"))
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

# exploratory plots
plot_cpue(
  catch = yt_n_survey_catch,
  dir = dir_wcgbts)

plot_bio_patterns(
  bio = yt_n_survey_bio, 
  col_name = "Length_cm",
  dir = dir_wcgbts)

wh_plot_proportion(
  data_catch = yt_n_survey_catch,
  data_bio = yt_n_survey_bio,
  dir = dir_wcgbts
)

PlotMap.fn(
  dat = yt_n_survey_catch,
  dir = dir_wcgbts
)

# length at age (modiifed from code in /docs/data_summary_doc.qmd)
yt_n_survey_bio |> dplyr::filter(Sex != "U") |> 
  ggplot() +
  geom_point(aes(x = Age_years, y = Length_cm, col = Sex), alpha = 0.1, position = "jitter") + 
  #scale_color_brewer(palette = "Set2", direction = -1) +
  scale_color_manual(values = c('F' = 'red', 'M' = 'blue')) +
  guides(colour = guide_legend(override.aes = list(alpha = 1)))
ggsave(file.path(dir_wcgbts, "wcgbts_length_at_age.png"))
# Large fish female, old fish male prevails, but not as notable as with canary.

# weight-length
yt_n_survey_bio |> dplyr::filter(Sex != "U") |> 
  ggplot() +
  geom_point(aes(x = Length_cm, y = Weight_kg, col = Sex), alpha = 0.1, position = "jitter") + 
  #scale_color_brewer(palette = "Set2", direction = -1) +
  scale_color_manual(values = c('F' = 'red', 'M' = 'blue')) +
  guides(colour = guide_legend(override.aes = list(alpha = 1)))
ggsave(file.path(dir_wcgbts, "wcgbts_weight_at_length.png"))

# get age_bin and len_bin
source("Rscripts/bins.R")

# now create comps

# length comps (expanded)
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

# length comps (raw)
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
  ageerr = 1
)

wcgbts_raw_age_comps <- nwfscSurvey::get_raw_comps(
  data = yt_n_survey_bio,
  comp_bins = age_bin,
  comp_column_name = "age",
  two_sex_comps = TRUE,
  dir = dir_wcgbts,
  age_error = 1,
  month = 7,
  fleet = 999,
  ageerr = 1
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

# raw vs expanded differ a lot in terms of 2013 proportion at age 5
# looking deeper here (one tow had lots of age-5 fish)
yt_n_survey_bio |> dplyr::filter(Year == 2013) |> dplyr::select(Age_years) |> table()
yt_n_survey_bio |> dplyr::filter(Year == 2013 & Age == 5) |> dplyr::select(Trawl_id) |> table()
# Trawl_id
# 201303008064 201303017092 201303017103
#            3           16            2
yt_n_survey_catch |> dplyr::filter(Trawl_id == 201303017092) |> dplyr::select(tidyselect::ends_with("wt_kg"))
#   Subsample_wt_kg total_catch_wt_kg
# 1           60.25            1348.9

# age comps (conditional) 
wcgbts_caal <- nwfscSurvey::SurveyAgeAtLen.fn(
  datAL = yt_n_survey_bio, 
  datTows = yt_n_survey_catch,
  strat.df = strata,
  lgthBins = len_bin, 
  ageBins = age_bin,
  dir = dir_wcgbts,
  month = 7,
  fleet = 999,
  ageerr = 1)

# check sample size by sex (confirm that we can ignore unsexed)
purrr::map(wcgbts_caal, ~ sum(.$input_n)) 
# $female
# [1] 3014

# $male
# [1] 3158

# $unsexed
# [1] 14
wcgbts_caal$unsexed$year
# [1] 2007 2007 2007 2007 2007 2007 2012 2014

wcgbts_caal_for_ss3 <- rbind(wcgbts_caal$female, wcgbts_caal$male)
saveRDS(wcgbts_caal_for_ss3, file = here::here("Data/Processed/ss3_wcgbts_caal_comps.rds"))

# testing new function Chantel is adding to nwfscSurvey (as of 29 Jan 2025)
if (FALSE) {
wcgbts_caal2 <- nwfscSurvey::get_raw_caal(
  data = yt_n_survey_bio, 
  len_bins = len_bin, 
  age_bins = age_bin,
  length_column_name = "length_cm",
  age_column_name = "age", 
  dir = dir_wcgbts,
  month = 7,
  fleet = 999,
  ageerr = 1)

wcgbts_caal_U <- yt_n_survey_bio |> 
  dplyr::mutate(Sex = "U") |> 
  nwfscSurvey::get_raw_caal(
    len_bins = len_bin, 
    age_bins = age_bin,
    length_column_name = "length_cm",
    age_column_name = "age", 
    month = 7,
    fleet = 999,
    ageerr = 1
  )

}