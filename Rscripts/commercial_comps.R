library(here)
library(dplyr)

# PacFIN comps ------------------------------------------------------------

# read CONFIDENTIAL file with PacFIN BDS data
load(here('Data/Confidential/Commercial/pacfin_12-11-2024/PacFIN.YTRK.bds.11.Dec.2024.RData'))
# load processed catch by year/fleet
comm_catch <- readRDS('Data/processed/catch_wide.rds') |>
  rename(year = YEAR) 
# clean pacfin within inputs specific to Yellowtail Rockfish
bds_clean <- pacfintools::cleanPacFIN(bds.pacfin,
                                      keep_age_method = c('B', 'S')) |>
  mutate(fleet = 1)  # assign everything to fleet 1

# get weight-length parameters processed elsewhere
w_l_pars <- read.csv('Data/processed/W_L_pars.csv') |>
  select(-n)
# get age_bin and len_bin
source("Rscripts/bins.R")

# TODO: sort out foreign catch (maybe already completed by Kiva)
# for now just removing from the catch file
comm_catch <- comm_catch |> dplyr::select(-Foreign)

# run expansions
pacfin_exp <- bds_clean |>
  filter(SEX != 'U', # most fish (even length-only) are sexed
         year < 2024) |>
  # exclude WA surface reads. OR surface reads are actually 'B', per email with ODFW.
  mutate(Age = ifelse(age_method == 'S' & state == 'WA', NA, Age)) |>
  pacfintools::get_pacfin_expansions(Catch = comm_catch, 
                                          weight_length_estimates = w_l_pars, 
                                          stratification.cols = 'state', 
                                          Units = 'MT', maxExp = 0.9)

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
    comp_bins = age_bin # sourced above
  )

# TODO: save the results using a command like the following:
# saveRDS(age_comps_ss3, file = 'Data/processed/ss3_pacfin_comps_2023.rds')

# ASHOP comps -------------------------------------------------------------

# Try unexpanded. Catches are low. This is what we did with Canary. If struggling with fits, expand.

ashop_lengths_old <- readxl::read_excel(
  here("Data/Confidential/ASHOP/Oken_YLT_Length data_1976-2023_102824_ASHOP.xlsx"), 
  sheet = "YLT_Length data 1976-1989")
ashop_lengths_new <- suppressWarnings(
  readxl::read_excel(here("Data/Confidential/ASHOP/Oken_YLT_Length data_1976-2023_102824_ASHOP.xlsx"), 
                     sheet = "YLT_Length data1990-2023")
)  # warning is about converting text to numeric for HAUL_JOIN, but values seems sensible, no NAs


ashop_lengths <- bind_rows(
  select(ashop_lengths_old, Sex = SEX, Length_cm = SIZE_GROUP, FREQUENCY, Year = YEAR, HAUL_JOIN),
  select(ashop_lengths_new, Sex = SEX, Length_cm = LENGTH, FREQUENCY, Year = YEAR, HAUL_JOIN)
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