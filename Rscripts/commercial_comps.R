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
load(here('Data/Confidential/Commercial/pacfin_12-11-2024/PacFIN.YTRK.bds.11.Dec.2024.RData'))
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
         state == 'WA' | state == 'OR' | PACFIN_GROUP_PORT_CODE == 'CCA' | PACFIN_GROUP_PORT_CODE == 'ERA') # only y-t north
  
# get weight-length parameters processed elsewhere
w_l_pars <- read.csv('Data/processed/W_L_pars.csv') |>
  select(-n)
# get age_bin and len_bin
source("Rscripts/bins.R")

# run expansions
pacfin_exp <- bds_clean |>
  filter(SEX != 'U') |> # sample sizes are not calculated separately for sexed and unsexed rows. 
                        # need to do a whole separate expansion for unsexed (length only) data
  # exclude WA surface reads. OR surface reads are actually 'B', per email with ODFW.
  mutate(Age = ifelse(age_method == 'S' & state == 'WA', NA, Age)) |> 
  as.data.frame() |> 
  pacfintools::get_pacfin_expansions(Catch = comm_catch, 
                                          weight_length_estimates = w_l_pars, 
                                          stratification.cols = 'state', 
                                          Units = 'MT', maxExp = 0.8)

# create length comps for SS3
length_comps_ss3 <- filter(pacfin_exp, !is.na(lengthcm)) |>
  pacfintools::getComps(
    Comps = "LEN",
    weightid = "Final_Sample_Size_L"
  ) |>
  pacfintools::writeComps(
    fname = 'Data/Processed/pacfin_lcomps_2023.csv', 
    comp_bins = len_bin # sourced above
  )

age_comps_ss3 <- filter(pacfin_exp, !is.na(Age)) |>
  pacfintools::getComps(
    Comps = "AGE",
    weightid = "Final_Sample_Size_A"
  ) |>
  pacfintools::writeComps(
    fname = 'Data/Processed/pacfin_acomps_2023.csv', 
    month = 7, 
    comp_bins = age_bin # sourced above
  )

# unexpanded PacFIN comps (for consistency with 2017 assessment)

bds_clean |>
  rename(trawl_id = SAMPLE_NO) |>
  filter(!is.na(Age), SEX != 'U') |>
  nwfscSurvey::get_raw_comps(comp_column_name = 'Age', comp_bins = age_bin, 
                             input_n_method = 'tows', month = 7, fleet = 1, ageerr = 1) |>
  `names<-`(NULL) |>
  as.data.frame() |> 
  saveRDS(file = 'data/processed/pacfin_acomps_raw.rds')

bds_clean |>
  rename(trawl_id = SAMPLE_NO) |> 
  nwfscSurvey::get_raw_comps(comp_column_name = 'lengthcm', comp_bins = len_bin, input_n_method = 'tows',
                             month = 7, fleet = 1) |>
  bind_rows() |> 
  saveRDS(file = 'data/processed/pacfin_lcomps_raw.rds')

# ASHOP comps -------------------------------------------------------------

# Try unexpanded. Catches are low. This is what we did with Canary. If struggling with fits, expand.

ashop_lengths_old <- readxl::read_excel(
  here("Data/Confidential/ASHOP/Oken_YLT_Length data_1976-2023_102824_ASHOP.xlsx"), 
  sheet = "YLT_Length data 1976-1989")
ashop_lengths_new <- suppressWarnings(
  readxl::read_excel(here("Data/Confidential/ASHOP/Oken_YLT_Length data_1976-2023_102824_ASHOP.xlsx"), 
                     sheet = "YLT_Length data1990-2023")
)  # warning is about converting text to numeric for HAUL_JOIN, but values seems sensible, no NAs
ashop_lengths_2024 <- readxl::read_excel('Data/Confidential/ASHOP/Oken_YLT_Length data_2024_020425.xlsx') |>
  mutate(HAUL_JOIN = as.numeric(HAUL_JOIN))

ashop_lengths <- bind_rows(
  select(ashop_lengths_old, Sex = SEX, Length_cm = SIZE_GROUP, FREQUENCY, Year = YEAR, HAUL_JOIN),
  select(ashop_lengths_new, Sex = SEX, Length_cm = LENGTH, FREQUENCY, Year = YEAR, HAUL_JOIN),
  select(ashop_lengths_2024, Sex = SEX, Length_cm = LENGTH, FREQUENCY, Year = YEAR, HAUL_JOIN)
)

ntow <- ashop_lengths |>
  group_by(Year) |>
  summarise(ntow = length(unique(HAUL_JOIN)))

ss3_ashop_comps <- ashop_lengths |> 
  filter(Sex != 'U') |> # most (by orders of magnitude) samples are sexed
  tidyr::uncount(weights = FREQUENCY) |>
  mutate(Age = NA) |> # just to make function work
  as.data.frame() %>% # function does not play with tibbles
  nwfscSurvey::UnexpandedLFs.fn(dir = NULL,
                                datL = ., 
                                lgthBins = len_bin, # sourced above
                                partition = 2, 
                                fleet = 2, 
                                month = 7) |> 
  purrr::pluck('comps') |>
  left_join(ntow, by = c(year = 'Year')) |>
  mutate(Nsamp = ntow) |>
  select(-ntow) |>
  rename_with(~ stringr::str_to_lower(stringr::str_remove(.x, '-')), `F-20`:`M-56`) |>
  arrange(year) # consider filtering out low n

saveRDS(ss3_ashop_comps, file = 'Data/processed/ss3_ashop_comps_2023.rds')

ashop_ages <- readxl::read_excel('Data/Confidential/ASHOP/Oken_YLT_Bio data_ages added_2019-2024_022125.xlsx')

ashop_ages |>
  filter(YEAR != 2020, !is.na(AGE)) |> # only one sample
  rename(trawl_id = HAUL_JOIN) |>
  as.data.frame() |>
  nwfscSurvey::get_raw_comps(comp_bins = age_bin, comp_column_name = 'AGE', input_n_method = 'tows', two_sex_comps = TRUE,
                             month = 7, fleet = 2, partition = 2, ageerr = 1) |>
  purrr::pluck(1) |>
  saveRDS('Data/processed/ss3_ashop_ages.rds')
