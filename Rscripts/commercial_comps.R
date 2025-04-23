library(here)
library(dplyr)

# PacFIN comps ------------------------------------------------------------

# 2017 PacFIN data looks very different, cannot expand.
# FREQ is only ever 1. Phew.
# load('q:/assessments/currentassessments/yellowtail_rockfish_north/data/commercial/pacfin_6-3-2017/PacFIN.YTRK.bds.25.Apr.2017.dmp')
# bds.pacfin <- PacFIN.YTRK.bds.25.Apr.2017
# raw_comps_2017 <- bds.pacfin |> filter(!is.na(age1)) |>
#   rename(year = SAMPLE_YEAR) |>
#   nwfscSurvey::get_raw_comps(comp_column_name = 'age1', comp_bins = age_bin, input_n_method = 'tows')

# read CONFIDENTIAL file with PacFIN BDS data
load(here('Data/Confidential/Commercial/pacfin-2025-03-10/PacFIN.YTRK.bds.10.Mar.2025.RData'))
# load processed catch by year/fleet
comm_catch <- readRDS('Data/processed/catch_wide.rds') |>
  rename(year = YEAR) |>
  select(-Foreign)

# TODO: sort out foreign catch (maybe already completed by Kiva)
# for now just removing from the catch file
# KO: was not planning on allocating that to states, just ignoring it for the purposes of comp expansions
# It is only available by INFPC area anyway, which doesn't map exactly onto states.

# clean pacfin within inputs specific to Yellowtail Rockfish
bds_clean <- bds.pacfin |>
  pacfintools::cleanPacFIN(keep_sample_type = c('M', 'S'),
                           keep_age_method = c('B', 'S')) |>
  mutate(fleet = 1) |> # assign everything to fleet 1
  filter(SAMPLE_TYPE == 'M' | (state == 'OR' & SAMPLE_YEAR <= 1986),  # keep old OR special request
         state == 'WA' | state == 'OR' | PACFIN_GROUP_PORT_CODE == 'CCA' | PACFIN_GROUP_PORT_CODE == 'ERA') |> # only y-t north
  group_by(year, SEX) |>
  mutate(n = n()) |>
  filter(n > 100) # filter to sex-year combinations >100, avoid sparse lengths.
  
# get weight-length parameters processed elsewhere
w_l_pars <- read.csv('Data/processed/W_L_pars.csv') 
# get age_bin and len_bin
source("Rscripts/bins.R")

# run expansions
pacfin_exp <- bds_clean |>
  filter(# GRID != 'HKL' | SEX != 'U', # for now instead just use the 100 sample cutoff. more defensible.
         year != 2025) |>
  # exclude WA surface reads. OR surface reads are actually 'B', per email with ODFW.
  mutate(Age = ifelse(age_method == 'S' & state == 'WA', NA, Age)) |> 
  as.data.frame() |> 
  pacfintools::get_pacfin_expansions(Catch = comm_catch, 
                                          weight_length_estimates = w_l_pars, 
                                          stratification.cols = 'state', 
                                          Units = 'MT', maxExp = 0.8, 
                                          savedir = 'Data/Processed/pacfin_expansions')
# explore expansion factors
pacfin_exp |> 
  ggplot(aes(Expansion_Factor_1_L)) +
  geom_histogram()
ggsave('Data/Processed/pacfin_expansions/expansion_factor_1_L_hist.png')




# create length comps for SS3
length_comps_ss3 <- filter(pacfin_exp, !is.na(lengthcm)) |>
  pacfintools::getComps(
    Comps = "LEN",
    weightid = "Final_Sample_Size_L"
  ) |>
  pacfintools::writeComps(
    fname = 'Data/Processed/pacfin_lcomps.csv', 
    column_with_input_n = 'n_stewart', partition = 0,
    comp_bins = len_bin # sourced above
  )

age_comps_ss3 <- filter(pacfin_exp, !is.na(Age), 
                        SEX != 'U') |> # very few unsexed ages (215, 0.1%)
  pacfintools::getComps(
    Comps = "AGE",
    weightid = "Final_Sample_Size_A"
  ) |> 
  pacfintools::writeComps(
    fname = 'Data/Processed/pacfin_acomps.csv', 
    month = 7, ageErr = 1, partition = 0,
    column_with_input_n = 'n_stewart',
    comp_bins = age_bin # sourced above
  )

# tables for document

pacfin_exp |>
  filter(SEX != 'U') |>
  group_by(state, year) |>
  summarise(n_fish = sum(!is.na(lengthcm)),
            n_trip = length(unique(SAMPLE_NO))) |>
  tidyr::pivot_longer(cols = n_fish:n_trip, values_to = 'val', names_to = 'quant') |>
  mutate(quant = paste(state, quant, sep = ' ')) |>
  ungroup() |>
  select(-state) |>
  tidyr::pivot_wider(names_from = quant, values_from = val) |>
  left_join(select(length_comps_ss3, year, input_n)) |>
  arrange(year) |>
  mutate(across(everything(), ~tidyr::replace_na(., replace = 0))) |>
  write.csv('report/tables/pacfin_lengths.csv', row.names = FALSE)

pacfin_exp |>
  filter(!is.na(Age), SEX != 'U') |>
  group_by(state, year) |>
  summarise(n_fish = n(),
            n_trip = length(unique(SAMPLE_NO))) |>
  tidyr::pivot_longer(cols = n_fish:n_trip, values_to = 'val', names_to = 'quant') |>
  mutate(quant = paste(state, quant, sep = ' ')) |>
  ungroup() |>
  select(-state) |>
  tidyr::pivot_wider(names_from = quant, values_from = val) |>
  left_join(select(age_comps_ss3, year, input_n)) |> 
  arrange(year) |>
  mutate(across(everything(), ~tidyr::replace_na(., replace = 0))) |>
  write.csv('report/tables/pacfin_ages', row.names = FALSE)

# unexpanded (consistency w/2017) -----------------------------------------

pacfin_exp |>
  mutate(Final_Sample_Size_L = 1) |> # unweighted comps
  pacfintools::getComps(
    Comps = "LEN",
    weightid = "Final_Sample_Size_L"
  ) |> 
  pacfintools::writeComps(
    fname = 'Data/Processed/pacfin_lcomps_raw.csv', 
    month = 7, partition = 0,
    column_with_input_n = 'n_stewart',
    comp_bins = len_bin # sourced above
  )

pacfin_exp |>
  filter(!is.na(Age), SEX != 'U') |> 
  mutate(Final_Sample_Size_A = 1) |> # unweighted comps
  pacfintools::getComps(
    Comps = "AGE", 
    weightid = "Final_Sample_Size_A"
  ) |> 
  pacfintools::writeComps(
    fname = 'Data/Processed/pacfin_acomps_raw.csv', 
    month = 7, ageErr = 1, partition = 0,
    column_with_input_n = 'n_stewart',
    comp_bins = age_bin # sourced above
  )


