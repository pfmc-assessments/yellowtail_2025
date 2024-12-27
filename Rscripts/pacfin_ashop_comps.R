# PacFIN comps ------------------------------------------------------------

load(here('Data/Confidential/Commercial/pacfin_12-11-2024/PacFIN.YTRK.bds.11.Dec.2024.RData'))

comm_catch <- readRDS('Data/processed/ss3_landings_2023.rds') |>
  filter(fleet == 1, year >= 1981) |>
  select(year, catch)

bds_clean <- PacFIN.Utilities::cleanPacFIN(bds.pacfin, keep_age_method = c('B', 'S')) |>
  filter(age_method != 'L', # n = 1
         age_method != 'T', # n = 2,
         age_method != '', # n = 33
         age_method != 'S' | state != 'WA' # n = 99, keep OR surface reads for now
  )

w_l_pars <- read.csv('Data/processed/W_L_pars.csv')

# length expansions
pacfin_exp1 <- PacFIN.Utilities::getExpansion_1(Pdata = bds_clean, 
                                                fa = w_l_pars$A[w_l_pars$Sex == 'F'],
                                                fb = w_l_pars$B[w_l_pars$Sex == 'F'], 
                                                ma = w_l_pars$A[w_l_pars$Sex == 'M'],
                                                mb = w_l_pars$B[w_l_pars$Sex == 'M'],
                                                ua = w_l_pars$A[w_l_pars$Sex == 'B'],
                                                ub = w_l_pars$B[w_l_pars$Sex == 'B'])

pacfin_exp2 <- pacfin_exp1 |>
  mutate(fleet = 'catch') |>
  PacFIN.Utilities::getExpansion_2(Catch = comm_catch, 
                                   Units = 'MT', 
                                   stratification.cols = 'fleet') |>
  mutate(Final_Sample_Size = PacFIN.Utilities::capValues(Expansion_Factor_1_L * Expansion_Factor_2, 
                                                         maxVal = 0.80)) # where does the 0.8 come from?

comps <- PacFIN.Utilities::getComps(pacfin_exp2, 
                                    strat = 'fleet', 
                                    Comps = 'LEN')
