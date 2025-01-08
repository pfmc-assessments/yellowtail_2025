# PacFIN comps ------------------------------------------------------------
library(here)
library(dplyr)
devtools::load_all('C:/users/kiva.oken/documents/pacfin.utilities')

load(here('Data/Confidential/Commercial/pacfin_12-11-2024/PacFIN.YTRK.bds.11.Dec.2024.RData'))

comm_catch <- readRDS('Data/processed/catch_wide.rds') |>
  rename(year = YEAR) 

bds_clean <- PacFIN.Utilities::cleanPacFIN(bds.pacfin) |>
  mutate(fleet = 1)

w_l_pars <- read.csv('Data/processed/W_L_pars.csv')

# length expansions
pacfin_exp <- PacFIN.Utilities::getExpansion_1(Pdata = bds_clean, 
                                                fa = w_l_pars$A[w_l_pars$Sex == 'F'],
                                                fb = w_l_pars$B[w_l_pars$Sex == 'F'], 
                                                ma = w_l_pars$A[w_l_pars$Sex == 'M'],
                                                mb = w_l_pars$B[w_l_pars$Sex == 'M'],
                                                ua = w_l_pars$A[w_l_pars$Sex == 'B'],
                                                ub = w_l_pars$B[w_l_pars$Sex == 'B'], 
                                               maxExp = 0.9) |>
  filter(year < 2024) |>
  PacFIN.Utilities::getExpansion_2(Catch = comm_catch, 
                                   Units = 'MT', 
                                   stratification.cols = 'state') |>
  mutate(Final_Sample_Size = PacFIN.Utilities::capValues(Expansion_Factor_1_L * Expansion_Factor_2, 
                                                         maxVal = 0.9)  
         )

comps <- PacFIN.Utilities::getComps(pacfin_exp, 
                                    strat = NULL, 
                                    Comps = 'LEN')

writeComps(inComps = comps, fname = 'data/processed/lcomps.csv')

# age expansion

bds_clean |>
  filter(age_method != 'L', # n = 1
         age_method != 'T', # n = 2,
         age_method != '', # n = 33
         age_method != 'S' | state != 'WA' # n = 99, keep OR surface reads for now
  )