# process survey comps
# see also explorations of changes in growth over space and time in the
# "Survey data" section of /docs/data_summary_doc.qmd

require(dplyr)
require(ggplot2)
# get age_bin and len_bin
source("Rscripts/bins.R")

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
yt_n_tri_bio <- purrr::map(yt_tri_bio, \(dat) filter(dat, Latitude_dd > 40 + 1 / 6 & Year > 1977))
yt_n_survey_catch <- filter(yt_survey_catch, Latitude_dd > 40 + 1 / 6)
yt_n_tri_catch <- filter(yt_tri_catch, Latitude_dd > 40 + 1 / 6 & Year > 1977)

# summary statistics for presence/absence
mean(yt_survey_catch$cpue_kg_km2 > 0)
# [1] 0.07304087
mean(yt_n_survey_catch$cpue_kg_km2 > 0)
# [1] 0.125381
mean(filter(yt_survey_catch, Latitude_dd > 46)$cpue_kg_km2 > 0)
# [1] 0.2737276
mean(filter(yt_survey_catch, Latitude_dd > 46, Depth_m > 100, Depth_m < 200)$cpue_kg_km2 > 0)
# [1] 0.5509761

# shared strata across WCGBTS and Triennial because S. California is excluded
# and Yellowtail rarely go beyond 366m:
# note 99.9% of fish in WCGBTS are less than 253m
# note 99.9% of fish in Triennial are less than 274, and only 2 fish beyond 366m
strata <- nwfscSurvey::CreateStrataDF.fn(
  names = c("shallow", "deep"),
  depths.shallow = c(55, 183),
  depths.deep = c(183, 400),
  lats.south = c(40.166667, 40.166667),
  lats.north = c(49, 49)
)

# exploratory plots
nwfscSurvey::plot_cpue(
  catch = yt_n_survey_catch,
  dir = dir_wcgbts
)

nwfscSurvey::plot_bio_patterns(
  bio = yt_n_survey_bio,
  col_name = "Length_cm",
  dir = dir_wcgbts
)

nwfscSurvey::wh_plot_proportion(
  data_catch = yt_n_survey_catch,
  data_bio = yt_n_survey_bio,
  dir = dir_wcgbts
)

nwfscSurvey::PlotMap.fn(
  dat = yt_n_survey_catch,
  dir = dir_wcgbts
)

# length at age (modified from code in /docs/data_summary_doc.qmd)
yt_n_survey_bio |>
  dplyr::filter(Sex != "U") |>
  ggplot() +
  geom_point(aes(x = Age_years, y = Length_cm, col = Sex), alpha = 0.1, position = "jitter") +
  # scale_color_brewer(palette = "Set2", direction = -1) +
  scale_color_manual(values = c("F" = "red", "M" = "blue")) +
  guides(colour = guide_legend(override.aes = list(alpha = 1)))
ggsave(file.path(dir_wcgbts, "wcgbts_length_at_age.png"))
# Large fish female, old fish male prevails, but not as notable as with canary.

# weight-length
yt_n_survey_bio |>
  dplyr::filter(Sex != "U") |>
  ggplot() +
  geom_point(aes(x = Length_cm, y = Weight_kg, col = Sex), alpha = 0.1, position = "jitter") +
  # scale_color_brewer(palette = "Set2", direction = -1) +
  scale_color_manual(values = c("F" = "red", "M" = "blue")) +
  guides(colour = guide_legend(override.aes = list(alpha = 1)))
ggsave(file.path(dir_wcgbts, "wcgbts_weight_at_length.png"))


# now create comps

# length comps (expanded) WCGBTS
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
# length comps (expanded) Triennial
tri_length_comps <- nwfscSurvey::get_expanded_comps(
  bio_data = yt_n_tri_bio$length_data,
  catch_data = yt_n_tri_catch,
  comp_bins = len_bin,
  strata = strata,
  comp_column_name = "Length_cm",
  # output = "full_expansion_ss3_format",
  two_sex_comps = TRUE,
  input_n_method = "stewart_hamel",
  month = 7,
  fleet = 999,
  dir = dir_tri
)

# length comps (raw) WCGBTS
wcgbts_raw_length_comps <- nwfscSurvey::get_raw_comps(
  data = yt_n_survey_bio,
  comp_bins = len_bin,
  comp_column_name = "length_cm",
  two_sex_comps = TRUE,
  dir = dir_wcgbts,
  month = 7,
  fleet = 999
)

# length comps (raw) Triennial
tri_raw_length_comps <- nwfscSurvey::get_raw_comps(
  data = yt_n_tri_bio$length_data,
  comp_bins = len_bin,
  comp_column_name = "length_cm",
  two_sex_comps = TRUE,
  dir = dir_tri,
  month = 7,
  fleet = 999
)

# length comp plots WCGBTS
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

# length comp plots Triennial
nwfscSurvey::plot_comps(
  data = tri_raw_length_comps,
  dir = dir_tri
)
file.copy(
  file.path(dir_tri, "plots/length_frequency_sex_3.png"),
  file.path(dir_tri, "plots/length_frequency_raw_sex_3.png")
)
file.copy(
  file.path(dir_tri, "plots/length_r4ss_frequency_sex_3.png"),
  file.path(dir_tri, "plots/length_r4ss_frequency_raw_sex_3.png")
)
nwfscSurvey::plot_comps(
  data = tri_length_comps,
  dir = dir_tri
)

# save processed data as RDS file
saveRDS(wcgbts_length_comps$sexed, file = here::here("Data/Processed/ss3_wcgbts_length_comps.rds"))
saveRDS(tri_length_comps$sexed, file = here::here("Data/Processed/ss3_tri_length_comps.rds"))

# age comps (marginal, expanded) WCGBTS
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

# age comps (marginal, expanded) Triennial
tri_age_comps <- nwfscSurvey::get_expanded_comps(
  bio_data = yt_n_tri_bio$age_data,
  catch_data = yt_n_tri_catch,
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

# age comps (marginal, raw) WCGBTS
wcgbts_raw_age_comps <- nwfscSurvey::get_raw_comps(
  data = yt_n_survey_bio,
  comp_bins = age_bin,
  comp_column_name = "age",
  two_sex_comps = TRUE,
  dir = dir_wcgbts,
  month = 7,
  fleet = 999,
  ageerr = 1
)
# age comps (marginal, raw) Triennial
tri_raw_age_comps <- nwfscSurvey::get_raw_comps(
  data = yt_n_tri_bio$age_data,
  comp_bins = age_bin,
  comp_column_name = "age",
  two_sex_comps = TRUE,
  dir = dir_tri,
  month = 7,
  fleet = 999,
  ageerr = 1
)
# comp plots WCGBTS
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

# comp plots Triennial
nwfscSurvey::plot_comps(
  data = tri_raw_age_comps,
  dir = dir_tri
)
file.copy(
  file.path(dir_tri, "plots/age_frequency_sex_3.png"),
  file.path(dir_tri, "plots/age_frequency_raw_sex_3.png")
)
file.copy(
  file.path(dir_tri, "plots/age_r4ss_frequency_sex_3.png"),
  file.path(dir_tri, "plots/age_r4ss_frequency_raw_sex_3.png")
)
nwfscSurvey::plot_comps(
  data = tri_age_comps,
  dir = dir_tri
)

# save processed data as RDS file
saveRDS(wcgbts_age_comps$sexed, file = here::here("Data/Processed/ss3_wcgbts_age_comps.rds"))
saveRDS(tri_age_comps$sexed, file = here::here("Data/Processed/ss3_tri_age_comps.rds"))

# raw vs expanded differ a lot in terms of 2013 proportion at age 5
# looking deeper here (one tow had lots of age-5 fish)
yt_n_survey_bio |>
  dplyr::filter(Year == 2013) |>
  dplyr::select(Age_years) |>
  table()
yt_n_survey_bio |>
  dplyr::filter(Year == 2013 & Age == 5) |>
  dplyr::select(Trawl_id) |>
  table()
# Trawl_id
# 201303008064 201303017092 201303017103
#            3           16            2
yt_n_survey_catch |>
  dplyr::filter(Trawl_id == 201303017092) |>
  dplyr::select(tidyselect::ends_with("wt_kg"))
#   Subsample_wt_kg total_catch_wt_kg
# 1           60.25            1348.9

# age comps (conditional)
wcgbts_caal <- nwfscSurvey::get_raw_caal(
  data = yt_n_survey_bio,
  len_bins = len_bin,
  age_bins = age_bin,
  length_column_name = "length_cm",
  age_column_name = "age",
  dir = dir_wcgbts,
  month = 7,
  fleet = 999,
  ageerr = 1
)
saveRDS(wcgbts_caal, file = here::here("Data/Processed/ss3_wcgbts_caal_comps.rds"))

# confirm that there are very few d fish:
table(yt_n_survey_bio$Sex)
#    F    M    U
# 7845 9462   22


tri_caal <- nwfscSurvey::get_raw_caal(
  data = yt_n_tri_bio$age_data,
  len_bins = len_bin,
  age_bins = age_bin,
  length_column_name = "length_cm",
  age_column_name = "age",
  dir = dir_tri,
  month = 7,
  fleet = 999,
  ageerr = 1
)
saveRDS(tri_caal, file = here::here("Data/Processed/ss3_tri_caal_comps.rds"))

# confirm that there are very few unsexed fish:
table(yt_n_tri_bio$age_data$Sex)
#    F    M
# 2841 3198
table(yt_n_tri_bio$length_data$Sex)
#    F    M
# 6632 7643


# tables for report
table(yt_n_survey_bio$Sex)
#    F    M    U
# 7845 9462   22
table(yt_n_tri_bio$Length_data$Sex)
#    F    M
# 6632 7643

input_n_wcgbts_len <- nwfscSurvey::get_input_n(
  data = yt_n_survey_bio,
  species_group = "shelfrock"
) |>
  dplyr::filter(sex_grouped == "sexed") |>
  dplyr::select(year, n_tows, n, input_n) |> 
  dplyr::rename(n_lengths = n)


input_n_wcgbts_age <- nwfscSurvey::get_input_n(
  data = yt_n_survey_bio |> dplyr::filter(!is.na(Age)),
  comp_column_name = "Age",
  species_group = "shelfrock"
) |>
  dplyr::filter(sex_grouped == "sexed") |>
  dplyr::select(year, n) |>
  dplyr::rename(n_ages = n)

input_n_wcgbts <- dplyr::full_join(
  input_n_wcgbts_age,
  input_n_wcgbts_len
) |> dplyr::arrange(year)


input_n_tri_len <- nwfscSurvey::get_input_n(
  data = yt_n_tri_bio$length_data,
  species_group = "shelfrock"
) |>
  dplyr::filter(sex_grouped == "sexed") |>
  dplyr::select(year, n_tows, n, input_n) |> 
  dplyr::rename(n_lengths = n, n_tows_lengths = n_tows, input_n_lengths = input_n)

input_n_tri_age <- nwfscSurvey::get_input_n(
  data = yt_n_tri_bio$age_data,
  comp_column_name = "Age",
  species_group = "shelfrock"
) |>
  dplyr::filter(sex_grouped == "sexed") |>
  dplyr::select(year, n_tows, n, input_n) |>
  dplyr::rename(n_ages = n, n_tows_ages = n_tows, input_n_ages = input_n)

input_n_tri <- cbind(
  input_n_tri_age,
  input_n_tri_len |> dplyr::select(-year)
)

write.csv(input_n_wcgbts, file = "Data/Processed/input_n_wcgbts.csv", row.names = FALSE)
write.csv(input_n_tri, file = "Data/Processed/input_n_tri.csv", row.names = FALSE)
