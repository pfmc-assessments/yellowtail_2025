library(r4ss)
library(here)
library(dplyr)

exe_loc <- here::here('model_runs/ss3.exe')
source('Rscripts/bins.R')
source('Rscripts/model_rename_fleets.R')
source('Rscripts/model_remove_retention.R')

# compare old vs. new SS3 versions applied to 2017 inputs
m1.01 <- SS_output("model_runs/1.01_base_2017", printstats = FALSE, verbose = FALSE)
m1.02 <- SS_output("model_runs/1.02_base_2017_3.30.23", printstats = FALSE, verbose = FALSE)
SStableComparisons(
  SSsummarize(list(m1.01, m1.02)),
  names = c("NatM", "SSB_Virgin", "SSB_2017", "Bratio_2017"),
  likenames = NULL,
  modelnames = c("3.30.03.07", "3.30.23.1"),
) |>
  dplyr::mutate(across(-1, ~ round(.x, 3)))
#                   Label 3.30.03.07 3.30.23.1
# 1     NatM_p_1_Fem_GP_1      0.174        NA
# 2     NatM_p_1_Mal_GP_1     -0.149        NA
# 3 NatM_uniform_Fem_GP_1         NA     0.174
# 4 NatM_uniform_Mal_GP_1         NA    -0.149
# 5            SSB_Virgin     14.996    15.051
# 6              SSB_2017     11.278    11.465
# 7           Bratio_2017      0.752     0.762

# update catches ----------------------------------------------------------

mod_catches <- SS_read('model_runs/1.02_base_2017_3.30.23')

mod_catches <- rename_fleets(mod_catches)

mod_catches$dat$catch <- readRDS('data/processed/ss3_landings_2023.rds')

SS_write(mod_catches, dir = 'model_runs/3.01_reanalyze_catch', overwrite = TRUE)


run('model_runs/3.01_reanalyze_catch', 
    exe = exe_loc, extras = '-nohess', verbose = TRUE, 
    skipfinished = FALSE)

# update indices -----------------------------------------------------------

mod_survey <- SS_read('model_runs/3.01_reanalyze_catch')

load("data/confidential/wcgbts_updated/interaction/delta_lognormal/index/sdmTMB_save.RData")

wcgbts <- results_by_area$`North of Cape Mendocino`$index |>
  mutate(month = 7, index = 6) |> 
  rename(obs = est, se_log = se) |>
  select(names(mod_survey$dat$CPUE))

load("data/confidential/triennial/delta_lognormal/index/sdmTMB_save.RData")

triennial <- results_by_area$`North of Cape Mendocino`$index |>
  mutate(month = 7, index = 5) |>
  rename(obs = est, se_log = se) |>
  select(names(mod_survey$dat$CPUE))

mod_survey$dat$CPUE <- bind_rows(wcgbts, triennial)

mod_survey$ctl$Q_options <- mod_survey$ctl$Q_options[c('Triennial', 'WCGBTS'),]
mod_survey$ctl$Q_options$float <- 0

mod_survey$ctl$Q_parms <- mod_survey$ctl$Q_parms[grep('Tri|WCGBTS', rownames(mod_survey$ctl$Q_parms)),]

# Order: tri Q, tri extra SD, wcgbts Q, wcgbts SD 
mod_survey$ctl$Q_parms$PHASE <- c(2, 2, 2, -99) 
mod_survey$ctl$Q_parms$INIT <- c(-1, 0.01, -1, 0)

SS_write(mod_survey, dir = 'model_runs/3.02_surveys', overwrite = TRUE)
run('model_runs/3.02_surveys', 
    exe = exe_loc, extras = '-nohess', verbose = TRUE, 
    skipfinished = FALSE, show_in_console = TRUE)


# Update biology, etc. ----------------------------------------------------------

mod_biology <- SS_read('model_runs/3.02_surveys')

mod_biology$ctl$maturity_option <- 2 # age-based maturity
mod_biology$ctl$First_Mature_Age <- 1

mod_biology$ctl$MG_parms['Mat50%_Fem_GP_1', 'INIT'] <- 10
mod_biology$ctl$MG_parms['Mat_slope_Fem_GP_1', 'INIT'] <- -0.67

W_L_pars <- read.csv('Data/processed/W_L_pars.csv')
mod_biology$ctl$MG_parms['Wtlen_1_Fem_GP_1', 'INIT'] <- W_L_pars$A[W_L_pars$sex == 'female']
mod_biology$ctl$MG_parms['Wtlen_2_Fem_GP_1', 'INIT'] <- W_L_pars$B[W_L_pars$sex == 'female']
mod_biology$ctl$MG_parms['Wtlen_1_Mal_GP_1', 'INIT'] <- W_L_pars$A[W_L_pars$sex == 'male']
mod_biology$ctl$MG_parms['Wtlen_2_Mal_GP_1', 'INIT'] <- W_L_pars$B[W_L_pars$sex == 'male']

# Simplify control file. (No changes to model)
mod_biology$ctl$recr_dist_method <- 4
mod_biology$ctl$MG_parms <- mod_biology$ctl$MG_parms[-grep('RecrDist', rownames(mod_biology$ctl$MG_parms)),] 

SS_write(mod_biology, dir = 'model_runs/3.03_biology', overwrite = TRUE)
run('model_runs/3.03_biology', 
    exe = exe_loc, extras = '-nohess', verbose = TRUE, 
    skipfinished = FALSE, show_in_console = FALSE)

# out <- SSgetoutput(dirvec = c('model_runs/3.02_surveys', 'model_runs/3.03_biology', 'ignored/3.03_biology'))
# SS_plots(out[[3]])
# out |>
#   SSsummarize() |> # SStableComparisons()
#   SSplotComparisons(subplots = c(1,3), new = FALSE)

# update discards ---------------------------------------------------------

mod_discards <- SS_read('model_runs/3.03_biology')

source('Rscripts/model_remove_retention.R')

mod_discards <- remove_retention(mod_discards) |> 
  add_discards()

SS_write(mod_discards, dir = 'model_runs/3.04_discards', overwrite = TRUE)
run('model_runs/3.04_discards', 
    exe = exe_loc, extras = '-nohess', verbose = TRUE, 
    skipfinished = FALSE, show_in_console = TRUE)


# update ages -------------------------------------------------------------

mod_ages <- SS_read('model_runs/3.04_discards')

mod_ages$dat$agebin_vector <- age_bin
mod_ages$dat$N_agebins <- length(age_bin)

pacfin_ages <- read.csv('data/processed/pacfin_acomps_raw.csv') 
names(pacfin_ages)[1:9] <- names(mod_ages$dat$agecomp)[1:9]

ashop_ages <- readRDS('data/processed/ss3_ashop_ages.rds')
names(ashop_ages)[1:9] <- names(mod_ages$dat$agecomp)[1:9]

rec_ages <- readRDS('data/processed/ss3_rec_age_comps.rds') |> 
  mutate(fleet = 3, ageerr = as.numeric(1)) |>
  filter(year != 2009) # two samples
names(rec_ages)[1:9] <- names(mod_ages$dat$agecomp)[1:9]

wcgbts_ages <- readRDS('data/processed/ss3_wcgbts_caal_comps.rds') |>
  mutate(fleet = 6) 
names(wcgbts_ages)[1:9] <- names(mod_ages$dat$agecomp)[1:9]

wcgbts_mar_ages <- readRDS('data/processed/ss3_wcgbts_age_comps.rds') |>
  mutate(fleet = -6) 
names(wcgbts_mar_ages)[1:9] <- names(mod_ages$dat$agecomp)[1:9]

tri_ages <- readRDS('data/processed/ss3_tri_caal_comps.rds') |>
  mutate(fleet = -5) 
names(tri_ages)[1:9] <- names(mod_ages$dat$agecomp)[1:9]

tri_mar_ages <- readRDS('data/processed/ss3_tri_age_comps.rds') |>
  mutate(fleet = 5) 
names(tri_mar_ages)[1:9] <- names(mod_ages$dat$agecomp)[1:9]

mod_ages$dat$agecomp <- bind_rows(
  pacfin_ages, 
  ashop_ages,
  rec_ages, 
  wcgbts_ages, 
  wcgbts_mar_ages,
  tri_ages,
  tri_mar_ages
)

SS_write(mod_ages, dir = 'model_runs/3.05_ages_raw_pacfin', overwrite = TRUE)
run('model_runs/3.05_ages_raw_pacfin', 
    exe = exe_loc, extras = '-nohess', verbose = TRUE, 
    skipfinished = FALSE)
tune_comps(niters_tuning = 2, dir = 'model_runs/3.05_ages_raw_pacfin',
           exe = exe_loc, extras = '-nohess')
out <- SS_output('model_runs/3.05_ages_raw_pacfin')
SS_plots(out)

# now try expanded PacFIN ages
pacfin_ages_exp <- read.csv('data/processed/pacfin_acomps.csv') |>
`names<-`(names(mod_ages$dat$agecomp)) 

mod_ages$dat$agecomp <- mod_ages$dat$agecomp |> 
  filter(fleet != 1) |>
  bind_rows(pacfin_ages_exp)

SS_write(mod_ages, dir = 'model_runs/3.06_ages_exp_pacfin', overwrite = TRUE)
run('model_runs/3.06_ages_exp_pacfin', 
    exe = exe_loc, extras = '-nohess', verbose = TRUE, 
    skipfinished = FALSE)
tune_comps(niters_tuning = 2, dir = 'model_runs/3.06_ages_exp_pacfin',
           exe = exe_loc, extras = '-nohess')



# update lengths ----------------------------------------------------------

mod_lengths_raw <- SS_read('model_runs/3.05_ages_raw_pacfin')

pacfin_lengths <- read.csv('data/processed/pacfin_lcomps_raw.csv') |>
  `names<-`(names(mod_lengths_raw$dat$lencomp)) |>
  filter(sex != 0) # these are generally heterogeneous from the rest of the fleet, and are sparse.

rec_lengths <- readRDS('data/processed/ss3_rec_length_comps_with_mrfss.rds') |> 
  `names<-`(names(mod_lengths_raw$dat$lencomp)) |>
  mutate(fleet = 3)

ashop_lengths <- readRDS('data/processed/ss3_ashop_comps_2023.rds') |>
  `names<-`(names(mod_lengths_raw$dat$lencomp))

wcgbts_lengths <- readRDS('data/processed/ss3_wcgbts_length_comps.rds') |>
  mutate(fleet = 6) |>
  `names<-`(names(mod_lengths_raw$dat$lencomp))

tri_lengths <- readRDS('data/processed/ss3_tri_length_comps.rds') |>
  mutate(fleet = 5) |>
  `names<-`(names(mod_lengths_raw$dat$lencomp))

mod_lengths_raw$dat$lencomp <- bind_rows(pacfin_lengths, 
                                         ashop_lengths, 
                                         rec_lengths, 
                                         wcgbts_lengths, 
                                         tri_lengths)

SS_write(mod_lengths_raw, dir = 'model_runs/3.07_lengths_raw_pacfin', overwrite = TRUE)
run('model_runs/3.07_lengths_raw_pacfin', 
    exe = exe_loc, extras = '-nohess', verbose = TRUE, 
    skipfinished = FALSE)
tune_comps(dir = 'model_runs/3.07_lengths_raw_pacfin', 
           niters_tuning = 2, exe = exe_loc, extras = '-nohess')

# expanded pacfin comps
mod_lengths_exp <- SS_read('model_runs/3.06_ages_exp_pacfin')

pacfin_lengths_exp <- read.csv('data/processed/pacfin_lcomps.csv') |>
  `names<-`(names(mod_lengths_exp$dat$lencomp)) |>
  filter(sex != 0) # these are generally heterogeneous from the rest of the fleet, and are sparse.

mod_lengths_exp$dat$lencomp <- bind_rows(pacfin_lengths_exp, 
                                         ashop_lengths, 
                                         rec_lengths, 
                                         wcgbts_lengths, 
                                         tri_lengths)

SS_write(mod_lengths_exp, dir = 'model_runs/3.08_lengths_exp_pacfin', overwrite = TRUE)
run('model_runs/3.08_lengths_exp_pacfin', 
    exe = exe_loc, extras = '-nohess', verbose = TRUE, 
    skipfinished = FALSE)
tune_comps(dir = 'model_runs/3.08_lengths_exp_pacfin', 
           niters_tuning = 2, exe = exe_loc, extras = '-nohess')

# out <- SSgetoutput(dirvec = c('model_runs/1.02_base_2017_3.30.23',
#                               glue::glue('model_runs/3.0{mod}', 
#                                          mod = c('4_discards',
#                                                  '5_ages_raw_pacfin',
#                                                  '6_ages_exp_pacfin',
#                                                  '7_lengths_raw_pacfin',
#                                                  '8_lengths_exp_pacfin'))))
# SSsummarize(out) |>
#   SSplotComparisons(subplots = c(1,3), 
#                     legendlabels = c('2017', 'stuff', 'raw ages', 'exp ages', 'raw ages+len', 'exp ages+len'), 
#                     new = FALSE)

# SSsummarize(out) |> SStableComparisons()

# SS_plots(out[[5]])
# SS_plots(out[[6]])

# run some profiles

# extend to 2024 ----------------------------------------------------------

mod_raw <- SS_read('model_runs/3.07_lengths_raw_pacfin')
mod <- SS_read('model_runs/3.08_lengths_exp_pacfin')

mod$dat$endyr <- mod_raw$dat$endyr <- 2024
mod$ctl$Block_Design <- mod_raw$ctl$Block_Design <- purrr::map(mod$ctl$Block_Design,
                                                               \(x){x[length(x)] <- 2024; return(x)})
mod$ctl$MainRdevYrLast <- mod_raw$ctl$MainRdevYrLast <- 2018

mod$ctl$last_early_yr_nobias_adj <- mod_raw$ctl$last_early_yr_nobias_adj <- 1950.5
mod$ctl$first_yr_fullbias_adj <- mod_raw$ctl$first_yr_fullbias_adj <- 1976.9
mod$ctl$last_yr_fullbias_adj <- mod_raw$ctl$last_yr_fullbias_adj <- 2016.5
mod$ctl$first_recent_yr_nobias_adj <- mod_raw$ctl$first_recent_yr_nobias_adj <- 2021.6
mod$ctl$max_bias_adj <- mod_raw$ctl$max_bias_adj <- 0.7855

SS_write(mod_raw, 'model_runs/3.09_raw_comps_2024', overwrite = TRUE)
SS_write(mod, 'model_runs/3.10_exp_comps_2024', overwrite = TRUE)

# note to self: need to run these first thing in am

run('model_runs/3.09_raw_comps_2024', 
    exe = exe_loc, extras = '-nohess', verbose = TRUE, 
    skipfinished = FALSE)
tune_comps(dir = 'model_runs/3.09_raw_comps_2024', 
           niters_tuning = 2, exe = exe_loc, extras = '-nohess')

run('model_runs/3.10_exp_comps_2024', 
    exe = exe_loc, extras = '-nohess',
    verbose = TRUE, 
    skipfinished = FALSE)
tune_comps(dir = 'model_runs/3.10_exp_comps_2024', 
           niters_tuning = 2, exe = exe_loc, extras = '-nohess')



# Selectivity changes -----------------------------------------------------

mod <- SS_read('model_runs/3.10_exp_comps_2024')

# get rid of discard and random unused block
mod$ctl$N_Block_Designs <- 2
mod$ctl$blocks_per_pattern <- c(2, 1)
# 2017 used 2003, added at STAR panel. 
# Ali recommended 2004 (when yelloweye depth restrictions went into place) and it matches data better.
# Second time period is for longleader
mod$ctl$Block_Design <- list(c(2004, 2016, 2017, 2024), # rec
                             c(2015, 2024)) # hake
rownames(mod$ctl$size_selex_parms_tv) <- gsub('2003', '2004', rownames(mod$ctl$size_selex_parms_tv))

# some cleanup
mod$ctl$MG_parms['Mat50%_Fem_GP_1', c('LO', 'HI')] <- c(1,30)
mod$ctl$MG_parms[c('Mat50%_Fem_GP_1', 'Mat_slope_Fem_GP_1', 'Eggs_beta_Fem_GP_1', 'FracFemale_GP_1', 'CohortGrowDev'), 
                 'PRIOR'] <- 99
mod$ctl$SR_parms['SR_sigmaR', 'LO'] <- 0.4

# selectivity clean up
mod$ctl$size_selex_types['PLACEHOLDER', 'Pattern'] <- 0
mod$ctl$size_selex_parms <- mod$ctl$size_selex_parms[-grep('PLACEHOLDER', rownames(mod$ctl$size_selex_parms)),]
mod$ctl$size_selex_parms_tv <- mod$ctl$size_selex_parms_tv[-grep('PLACEHOLDER', rownames(mod$ctl$size_selex_parms_tv)),]

# estimate descending limb for early rec period
mod$ctl$size_selex_parms['SizeSel_P_4_Recreational(3)', c('INIT', 'PHASE')] <- c(7, 4)
# only block descending limb (other parameters did not change)
mod$ctl$size_selex_parms['SizeSel_P_3_Recreational(3)', c('Block', 'Block_Fxn')] <- 0
# blocks were redefined
mod$ctl$size_selex_parms[paste0('SizeSel_P_', c(1,4), '_Recreational(3)'), 'Block'] <- 1

# make hake fleet tv
mod$ctl$size_selex_parms[paste0('SizeSel_P_', c(1,3), '_At-Sea-Hake(2)'), 'Block'] <- 2
mod$ctl$size_selex_parms[paste0('SizeSel_P_', c(1,3), '_At-Sea-Hake(2)'), 'Block_Fxn'] <- 2

# remove 2 rec tv parameters, add extra rec block, add hake tv parameters
mod$ctl$size_selex_parms_tv <- mod$ctl$size_selex_parms_tv[-grep('P_3', rownames(mod$ctl$size_selex_parms_tv)),]
mod$ctl$size_selex_parms_tv <- slice(mod$ctl$size_selex_parms_tv, c(1,2,1,1,2,2))
rownames(mod$ctl$size_selex_parms_tv) <- c(paste0('SizeSel_P_', c(1,3), '_At-Sea-Hake(2)_BLK2repl_2015'),
                                           paste0('SizeSel_P_1_Recreational(3)_BLK1repl_', c(2003, 2017)),
                                           paste0('SizeSel_P_4_Recreational(3)_BLK1repl_', c(2003, 2017)))
mod$ctl$size_selex_parms_tv['SizeSel_P_1_At-Sea-Hake(2)_BLK2repl_2015', 'INIT'] <- 48.64850

SS_write(mod, 'model_runs/4.10_hake_blocks', overwrite = TRUE)
run('model_runs/4.10_hake_blocks', exe = exe_loc, extras = '-nohess', skipfinished = FALSE)

# Now add sex specific selectivity
mod <- SS_read('model_runs/4.10_hake_blocks')

# sex specific for all fleets except PLACEHOLDER
mod$ctl$size_selex_types$Male <- c(3,3,3,0,3,3) 

sex_rows <- mod$ctl$size_selex_parms[1:5,]
rownames(sex_rows) <- paste0('SizeSel_PMalOff_', 1:5)
sex_rows$LO <- c(rep(-10, 4), 0)
sex_rows$HI <- c(rep(10, 4), 2)
sex_rows$INIT <- c(rep(0, 4), 1)
sex_rows$PHASE <- rep(-99, 5)

sex_rows_temp <- sex_rows
size_selex_temp <- mod$ctl$size_selex_parms

rownames(sex_rows_temp) <- paste0(rownames(sex_rows), '_Commercial(1)')
size_selex_temp <- bind_rows(size_selex_temp[1:6,], sex_rows_temp, size_selex_temp[7:nrow(size_selex_temp),])

sex_rows_temp <- sex_rows
rownames(sex_rows_temp) <- paste0(rownames(sex_rows), '_At-Sea-Hake(2)')
size_selex_temp <- bind_rows(size_selex_temp[1:17,], sex_rows_temp, size_selex_temp[18:nrow(size_selex_temp),])

sex_rows_temp <- sex_rows
rownames(sex_rows_temp) <- paste0(rownames(sex_rows), '_Recreational(3)')
sex_rows_temp[3,'PHASE'] <- 6 # estimate separate descending limbs by sex
sex_rows_temp[5,'PHASE'] <- 6 # estimate scale for male selectivity
size_selex_temp <- bind_rows(size_selex_temp[1:28,], sex_rows_temp, size_selex_temp[29:nrow(size_selex_temp),])

sex_rows_temp <- sex_rows
rownames(sex_rows_temp) <- paste0(rownames(sex_rows), '_Triennial(5)')
size_selex_temp <- bind_rows(size_selex_temp[1:39,], sex_rows_temp, size_selex_temp[40:nrow(size_selex_temp),])

sex_rows_temp <- sex_rows
rownames(sex_rows_temp) <- paste0(rownames(sex_rows), '_WCGBTS(6)')
size_selex_temp <- bind_rows(size_selex_temp, sex_rows_temp)

mod$ctl$size_selex_parms <- size_selex_temp

SS_write(mod, 'model_runs/4.11_sex_selex_setup', overwrite = TRUE)
run('model_runs/4.11_sex_selex_setup', exe = exe_loc, skipfinished = FALSE, extras = '-nohess')
tune_comps(dir = 'model_runs/4.11_sex_selex_setup', niters_tuning = 1, extras = '-nohess', exe = exe_loc)
tune_comps(dir = 'model_runs/4.11_sex_selex_setup', niters_tuning = 1, exe = exe_loc)


out <- SSgetoutput(dirvec = paste0('model_runs/', c('1.02_base_2017_3.30.23', '3.07_lengths_raw_pacfin', '3.08_lengths_exp_pacfin', 
                                                    '3.10_exp_comps_2024', '4.11_sex_selex_setup')))

SS_plots(out[[5]])
SSsummarize(out) |>
  SSplotComparisons(subplots = c(1,3), new = FALSE, legendlabels = c('2017', 'update data', 'expand pacfin comps', 'extend to 2024', 'update selectivity'))

profile_info <- nwfscDiag::get_settings_profile(parameters = 'NatM_uniform_Fem_GP_1',
                                                low = 0.1, high = 0.2, step_size = 0.01,
                                                param_space = 'real')
model_settings <- nwfscDiag::get_settings(
  settings = list(base_name = '4.11_sex_selex_setup',
                  run = 'profile',
                  profile_details = profile_info,
                  exe = exe_loc)
)

# future::plan(future::multisession, workers = parallelly::availableCores(omit = 1))
# nwfscDiag::run_diagnostics(mydir = 'model_runs',
#                            model_settings = model_settings)
# future::plan(future::sequential)


# M and aging error -------------------------------------------------------

mod <- SS_read('model_runs/4.11_sex_selex_setup')

# 99.9th percentile is 43 years
mod$ctl$MG_parms['NatM_p_1_Fem_GP_1', c('INIT', 'PRIOR', 'PR_SD')] <- c(0.126, round(log(0.126), 3), 0.31)

# update ageing error
mod$dat$N_ageerror_definitions <- 1
mod$dat$ageerror <- read.csv('data/processed/ageing_error/final_ageing_error.csv')

SS_write(mod, 'model_runs/4.12_age_and_M', overwrite = TRUE)
run('model_runs/4.12_age_and_M', exe = exe_loc, skipfinished = FALSE)

out <- SSgetoutput(dirvec = paste0('model_runs/4.1', c('1_sex_selex_setup', '2_age_and_M')))
SSsummarize(out) |> SSplotComparisons(subplots = c(1,3), new = FALSE)

# add H&L -----------------------------------------------------------------

mod <- SS_read('model_runs/4.12_age_and_M')

mod <- rename_fleets(mod, flt4_name = 'H&L_survey')

hl_ind <- read.csv('Data/raw_not_confidential/Combined HL Index/index_forSS.csv') |>
  mutate(fleet = 4) |>
  select(year, month, index = fleet, obs, se_log = logse)

mod$dat$fleetinfo[mod$dat$fleetnames == 'H&L_survey', 1:2] <- c(3, 1)
mod$dat$CPUEinfo['H&L_survey', 'units'] <- 0 # numbers of fish

mod$dat$CPUE <- bind_rows(mod$dat$CPUE,
                          hl_ind)

mod$ctl$Q_options <- rbind(mod$ctl$Q_options,
                           `H&L_survey` = c(4,1,0,1,0,0)) |>
  slice(3,1,2) # reorder
mod$ctl$Q_parms <- bind_rows(mod$ctl$Q_parms[1:2,], # copy triennial Q setup
                             mod$ctl$Q_parms)
rownames(mod$ctl$Q_parms) <- rownames(mod$ctl$Q_parms) |>
  stringr::str_replace('Triennial\\(5\\)\\.\\.\\.[1|2]', 'H&L_survey(4)') |> # fix row names
  stringr::str_remove('\\.\\.\\.[:digit:]')

# length comps
hl_len <- read.csv('Data/raw_not_confidential/Combined HL Index/length_cm_unsexed_raw_20_56_yellowtail rockfish_combinedhl.csv') |>
  mutate(month = 7, fleet = 4) |>
  rename(Nsamp = input_n, part = partition) |>
  rename_with(~stringr::str_replace(., pattern = 'u', replacement = 'f'), .cols = u20:u56) |>
  mutate(across(.cols = f20:f56, .fns = ~0, .names = 'm{.col}')) |>
  rename_with(~stringr::str_remove(., pattern = 'f'), mf20:mf56)
mod$dat$lencomp <- bind_rows(mod$dat$lencomp, hl_len)

# selectivity
mod$ctl$size_selex_types['H&L_survey', c('Pattern', 'Male')] <- c(24, 3)

new_selex <- mod$ctl$size_selex_parms[grepl('Recreational', rownames(mod$ctl$size_selex_parms)),]
rownames(new_selex) <- stringr::str_replace(rownames(new_selex), 'Recreational\\(3\\)', 
                                            'H&L_survey\\(4\\)')
new_selex$Block <- new_selex$Block_Fxn <- 0

last_rec_ind <- max(grep('Recreational', rownames(mod$ctl$size_selex_parms)))
mod$ctl$size_selex_parms <- bind_rows(mod$ctl$size_selex_parms[1:last_rec_ind,],
                                      new_selex,
                                      mod$ctl$size_selex_parms[(last_rec_ind + 1):nrow(mod$ctl$size_selex_parms),])

SS_write(mod, 'model_runs/5.01_hook_and_line', overwrite = TRUE)
run('model_runs/5.01_hook_and_line', exe = exe_loc, skipfinished = FALSE, extras = '-nohess')
# checked and it is close, one round should do it.
tune_comps(dir = 'model_runs/5.01_hook_and_line', niters_tuning = 1, exe = exe_loc, 
           extras = '-nohess')


# forecast ---------------------------------------------------------------

mod <- SS_read('model_runs/5.01_hook_and_line')
mod$fore$Flimitfraction <- -1
mod$fore$Flimitfraction_m <- PEPtools::get_buffer(2025:2036, sigma = 0.5, pstar = 0.45)
mod$fore$FirstYear_for_caps_and_allocations <- 2027
mod$fore$Ydecl <- 0
mod$fore$Yinit <- 0
mod$fore$ForeCatch <- data.frame(
  year = rep(2025:2026, each = 3),
  seas = 1,
  fleet = rep(1:3, 2),
  catch_or_F = c(3497, 360, 203.1, 3503, 360, 203.1) # Sent by K. Lockhart 4/11/25
)

# also some other cleanup:
mod$ctl$N_lambdas <- 1
mod$ctl$lambdas <- filter(mod$ctl$lambdas, phase != 1)

SS_write(mod, 'model_runs/5.02_forecast', overwrite = TRUE)

future::plan(future::multisession(workers = 6))
r4ss::retro(dir = 'model_runs', oldsubdir = '5.02_forecast', newsubdir = '5.02_forecast/retro',
            years = c(-(1:5), -10), exe = exe_loc, extras = '-nohess')
future::plan(future::sequential)

smurf_retro <- SSgetoutput(
  dirvec = c('model_runs/5.02_forecast', 
             paste0('model_runs/5.02_forecast/retro/retro-', c(1:5, 10)))
) |>
  SSsummarize()

SSplotRetroRecruits(endyrvec = c(2024:2019, 2014), cohorts = 2008:2018, retroSummary = smurf_retro)


# SMURF -------------------------------------------------------------------

mod <- SS_read('model_runs/5.02_forecast')

flt <- 7
smurf <- read.csv('Data/raw_not_confidential/SMURF index/index_forSS.csv') |>
  mutate(index = 7) |>
  rename(se_log = logse) |>
  select(-fleet)

# data file updates
mod$dat$Nfleets <- flt
mod$dat$fleetnames[flt] <- 'SMURF'
mod$dat$fleetinfo[flt,] <- c(3,1,1,2,0,'SMURF')
mod$dat$CPUEinfo[flt,] <- c(flt,33,0,0)
mod$dat$len_info[flt,] <- mod$dat$len_info[flt-1,]
mod$dat$age_info[flt,] <- mod$dat$age_info[flt-1,]
mod$dat$fleetinfo1$SMURF <- mod$dat$fleetinfo1$WCGBTS
mod$dat$fleetinfo2$SMURF <- mod$dat$fleetinfo2$WCGBTS
mod$dat$CPUE <- bind_rows(mod$dat$CPUE,
                          smurf)

# control file updates
mod$ctl$size_selex_types[flt,] <- rep(0, 4)
mod$ctl$age_selex_types[flt,] <- mod$ctl$age_selex_types[flt-1,]
mod$ctl$Q_options <- rbind(mod$ctl$Q_options,
                           SMURF = c(flt,1,0,1,0,0))
mod$ctl$Q_parms <- bind_rows(mod$ctl$Q_parms,
                             mod$ctl$Q_parms[1:2,])

# bias adjustment (from an earlier model run with hessian)
mod$ctl$last_early_yr_nobias_adj <- 1950.6250
mod$ctl$first_yr_fullbias_adj <- 1975.0898
mod$ctl$last_yr_fullbias_adj <- 2015.1215
mod$ctl$first_recent_yr_nobias_adj <- 2024.9174
mod$ctl$max_bias_adj <- 0.8053

SS_write(mod, "Model_Runs/temp", overwrite = TRUE)
# stopph -1 causes model to write ss_new files without running anything
r4ss::run("Model_Runs/temp",
          extras = "-nohess -stopph -1",
          exe = exe_loc,
          skipfinished = FALSE
)
mod <- r4ss::SS_read("Model_Runs/temp", ss_new = TRUE)

SS_write(mod, "Model_Runs/5.03_smurf", overwrite = TRUE)

future::plan(future::multisession(workers = 6))
r4ss::retro(dir = 'model_runs', oldsubdir = '5.03_smurf', newsubdir = '5.03_smurf/retro',
            years = c(-(1:5), -10), exe = exe_loc, extras = '-nohess')
future::plan(future::sequential)

smurf_retro <- SSgetoutput(
  dirvec = c('model_runs/5.03_smurf', 
             paste0('model_runs/5.03_smurf/retro/retro-', c(1:5, 10)))
) |>
  SSsummarize()

SSplotRetroRecruits(endyrvec = c(2024:2019, 2014), cohorts = 2008:2018, retroSummary = smurf_retro)

# oceanographic index -----------------------------------------------------

mod <- SS_read('model_runs/5.03_smurf')

# rename index
mod$dat$fleetinfo$fleetname[7] <- 'ocean'
SS_write(mod, "Model_Runs/temp", overwrite = TRUE)
# stopph -1 causes model to write ss_new files without running anything
r4ss::run("Model_Runs/temp",
          extras = "-nohess -stopph -1",
          exe = exe_loc,
          skipfinished = FALSE
)
mod <- r4ss::SS_read("Model_Runs/temp", ss_new = TRUE)

ocean <- read.csv('Data/raw_not_confidential/OceanographicIndex/OceanographicIndexV1.csv') |>
  mutate(month = 7, index = 7,
         index = ifelse(year >= 2015, 7, -7) # include 10 years of index
  ) |>
  select(year, month, index, obs = fit, se_log = se.p)

# data file updates
mod$dat$CPUEinfo['ocean',] <- c(7,36,-1,0)
mod$dat$CPUE <- filter(mod$dat$CPUE, index != 7) |> # get rid of smurf
  bind_rows(ocean)

# bias adjustment (from an earlier model run with hessian)
mod$ctl$last_early_yr_nobias_adj <- 1949.7   
mod$ctl$first_yr_fullbias_adj <- 1974.8   
mod$ctl$last_yr_fullbias_adj <- 2024.6   
mod$ctl$first_recent_yr_nobias_adj <- 2024.8   
mod$ctl$max_bias_adj <- 0.8383  

SS_write(mod, "Model_Runs/5.04_ocean", overwrite = TRUE)

future::plan(future::multisession(workers = 6))
r4ss::retro(dir = 'model_runs', oldsubdir = '5.04_ocean', newsubdir = '5.04_ocean/retro',
            years = c(-(1:5), -10), exe = exe_loc, extras = '-nohess')
future::plan(future::sequential)


ocean_retro <- SSgetoutput(
  dirvec = c('model_runs/5.04_ocean', 
             paste0('model_runs/5.04_ocean/retro/retro-', c(1:5, 10)))
) |>
  SSsummarize()

SSplotRetroRecruits(endyrvec = c(2024:2019, 2014), cohorts = 2008:2018, retroSummary = ocean_retro)


# RREAS -------------------------------------------------------------------


mod <- SS_read('model_runs/5.03_smurf')

# rename index
mod$dat$fleetinfo$fleetname[7] <- 'RREAS'
SS_write(mod, "Model_Runs/temp", overwrite = TRUE)
# stopph -1 causes model to write ss_new files without running anything
r4ss::run("Model_Runs/temp",
          extras = "-nohess -stopph -1",
          exe = exe_loc,
          skipfinished = FALSE
)
mod <- r4ss::SS_read("Model_Runs/temp", ss_new = TRUE)

rreas <- read.csv('Data/raw_not_confidential/RREAS/ytail_coastwide_indices.csv') |>
  mutate(index = 7, month = 7) |>
  rename(se_log = logse, year = YEAR, obs = est)

# data file updates
mod$dat$CPUE <- filter(mod$dat$CPUE, index != 7) |> # get rid of smurf
  bind_rows(rreas)

SS_write(mod, "Model_Runs/5.5_rreas", overwrite = TRUE)

future::plan(future::multisession(workers = 6))
r4ss::retro(dir = 'model_runs', oldsubdir = '5.5_rreas', newsubdir = '5.5_rreas/retro',
            years = c(-(1:5), -10), exe = exe_loc, extras = '-nohess')
future::plan(future::sequential)


# smurf ocean -------------------------------------------------------------


mod <- r4ss::SS_read('model_runs/5.04_ocean')

flt <- 8
smurf <- read.csv('Data/raw_not_confidential/SMURF index/index_forSS.csv') |>
  mutate(index = 8) |>
  rename(se_log = logse) |>
  select(-fleet)

# data file updates
mod$dat$Nfleets <- flt
mod$dat$fleetnames[flt] <- 'SMURF'
mod$dat$fleetinfo[flt,] <- c(3,1,1,2,0,'SMURF')
mod$dat$CPUEinfo[flt,] <- c(flt,33,0,0)
mod$dat$len_info[flt,] <- mod$dat$len_info[flt-1,]
mod$dat$age_info[flt,] <- mod$dat$age_info[flt-1,]
mod$dat$fleetinfo1$SMURF <- mod$dat$fleetinfo1$WCGBTS
mod$dat$fleetinfo2$SMURF <- mod$dat$fleetinfo2$WCGBTS
mod$dat$CPUE <- bind_rows(mod$dat$CPUE,
                          smurf)

# control file updates
mod$ctl$size_selex_types[flt,] <- rep(0, 4)
mod$ctl$age_selex_types[flt,] <- mod$ctl$age_selex_types[flt-1,]
mod$ctl$Q_options <- rbind(mod$ctl$Q_options,
                           SMURF = c(flt,1,0,1,0,0))
mod$ctl$Q_parms <- bind_rows(mod$ctl$Q_parms,
                             mod$ctl$Q_parms[1:2,])

SS_write(mod, "Model_Runs/temp", overwrite = TRUE)
# stopph -1 causes model to write ss_new files without running anything
r4ss::run("Model_Runs/temp",
          extras = "-nohess -stopph -1",
          exe = exe_loc,
          skipfinished = FALSE
)
mod <- r4ss::SS_read("Model_Runs/temp", ss_new = TRUE)

SS_write(mod, "Model_Runs/5.06_smurf_ocean", overwrite = TRUE)

future::plan(future::multisession(workers = 6))
r4ss::retro(dir = 'model_runs', oldsubdir = '5.06_smurf_ocean', newsubdir = '5.06_smurf_ocean/retro',
            years = c(-(1:5), -10), exe = exe_loc, extras = '-nohess')
future::plan(future::sequential)

# Fix hake selectivity ----------------------------------------------------

mod <- SS_read('model_runs/5.03_smurf')

mod$ctl$size_selex_parms['SizeSel_P_1_At-Sea-Hake(2)', c('INIT', 'PHASE')] <- c(55, -99)

SS_write(mod, dir = 'model_runs/5.07_smurf_fix_hake')

out <- SS_output('model_runs/5.07_smurf_fix_hake')


# Correct hake input N ----------------------------------------------------

mod <- SS_read('model_runs/5.07_smurf_fix_hake')

hake_len <- readRDS('data/processed/ss3_ashop_comps_2023.rds') |>
  rename(part = partition)

mod$dat$len_info$minsamplesize <- 0.01
mod$dat$age_info$minsamplesize <- 0.01

mod$dat$lencomp <- mod$dat$lencomp |>
  filter(fleet != 2) |> # remove bad comps
  bind_rows(hake_len)

SS_write(mod, 'model_runs/5.08_correct_input_n')
tune_comps(dir = 'model_runs/5.08_correct_input_n', niters_tuning = 0, 
           exe = exe_loc, extras = '-nohess')

out <- SSgetoutput(dirvec = c('model_runs/5.07_smurf_fix_hake', 'model_runs/5.08_correct_input_n'))

out |>
  SSsummarize() |>
  SSplotComparisons(subplots = c(1,3))


# No extra SE -------------------------------------------------------------

mod <- SS_read('model_runs/5.08_correct_input_n')

mod$ctl$Q_parms[grep('extra', rownames(mod$ctl$Q_parms)), 'INIT'] <- 0
mod$ctl$Q_parms[grep('extra', rownames(mod$ctl$Q_parms)), 'PHASE'] <- -99

mod$ctl$size_selex_parms[grepl('Mal', rownames(mod$ctl$size_selex_parms)) &
                           grepl('H&L', rownames(mod$ctl$size_selex_parms)), 'PHASE'] <- -99

mod$ctl$SR_parms['SR_sigmaR', 'INIT'] <- 0.5

SS_write(mod, 'model_runs/5.09_no_extra_SE', overwrite = TRUE)

out <- SSgetoutput(dirvec = c('model_runs/5.08_correct_input_n', 'model_runs/5.09_no_extra_SE'))

out |>
  SSsummarize() |> 
  SSplotComparisons(subplots = c(1,3), new = FALSE)

SS_plots(out[[2]])

# add 2024 discards
mod <- SS_read('model_runs/5.09_no_extra_SE')
# get GEMM discards (copied from Rscripts/model_remove_retention.R)
(avg_discards <- readRDS("Data/Processed/gemm_discards_by_fleet.rds") |>
  dplyr::filter(year %in% 2019:2023, fleet == "Commercial") |>
  dplyr::pull(catch) |>
  mean())
# [1] 5.31276
mod$dat$catch[mod$dat$catch$fleet == 1 & mod$dat$catch$year == 2024, "catch"]
# [1] 2663.91
# add GEMM discards to 2024 catch
mod$dat$catch[mod$dat$catch$fleet == 1 & mod$dat$catch$year == 2024, 'catch'] <- 
  avg_discards + mod$dat$catch[mod$dat$catch$fleet == 1 & mod$dat$catch$year == 2024, 'catch']

SS_write(mod, 'model_runs/5.10_add_2024_discards', overwrite = TRUE)
run('model_runs/5.10_add_2024_discards', extras = '-nohess', exe = exe_loc)

out <- SSgetoutput(
  dirvec = c('model_runs/5.09_no_extra_SE', 'model_runs/5.10_add_2024_discards'),
  verbose = FALSE
)
out |>
  SSsummarize(verbose = FALSE) |>
  SStableComparisons(
    names = c("SSB_2025", "Bratio_2025", "ForeCatch_2027"),
    likenames = NULL,
    verbose = FALSE
  )

# bridging figures --------------------------------------------------------

out1 <- SSgetoutput(dirvec = c('model_runs/1.02_base_2017_3.30.23',
                               glue::glue('model_runs/{mod}',
                                          mod = c('3.01_reanalyze_catch',
                                                  '3.02_surveys',
                                                  '3.03_biology',
                                                  '3.04_discards'))),
                    SpawnOutputLabel = 'Spawning Output (trillions of eggs)')

out2 <- SSgetoutput(dirvec = glue::glue('model_runs/{mod}',
                                        mod = c('3.04_discards',
                                                '3.05_ages_raw_pacfin',
                                                '3.07_lengths_raw_pacfin',
                                                '3.06_ages_exp_pacfin',
                                                '3.08_lengths_exp_pacfin',
                                                '3.10_exp_comps_2024')),
                    SpawnOutputLabel = 'Spawning Output (trillions of eggs)')

out3 <- SSgetoutput(dirvec = glue::glue('model_runs/{mod}',
                                        mod = c('3.10_exp_comps_2024',
                                                '4.15_rec_blocks_only',
                                                '4.11_sex_selex_setup',
                                                '5.09_no_extra_se')),
                    SpawnOutputLabel = 'Spawning Output (trillions of eggs)')

out_gfsc <- SSgetoutput(dirvec = glue::glue('model_runs/{mod}',
                                            mod = c('1.02_base_2017_3.30.23',
                                                    '3.08_lengths_exp_pacfin',
                                                    '3.10_exp_comps_2024',
                                                    '4.15_rec_blocks_only',
                                                    '5.09_no_extra_se')),
                    SpawnOutputLabel = 'Spawning Output (trillions of eggs)')


# bridging plots for group 1
out1 |>
  SSsummarize() |>
  SSplotComparisons(subplots = c(2,4,18), new = FALSE,
                    legendlabels = c('2017',
                                     'Reanalyze catch', 
                                     '+ index', 
                                     '+ bio', 
                                     '+ discard'), 
                    png = TRUE, plotdir = 'report/figures/bridging', 
                    filenameprefix = 'bridging1', 
                    legendloc = 'bottomleft')


out1 |>
  r4ss::plot_twopanel_comparison(
    dir = 'report/figures/bridging',
    filename = 'bridging1_comparison.png',
    legendlabels = c(
      '2017',
      'Reanalyze catch',
      '+ index',
      '+ bio',
      '+ discard'
    ),
    legendloc = 'bottomleft',
    endyrvec = 2017
  )

# bridging plots for group 2
c(list(base2017 = out1[[1]]), out2) |> 
  SSsummarize() |>
  SSplotComparisons(subplots = c(2,4,18), new = FALSE,
                    legendlabels = c('2017',
                                     'first steps',
                                     'reanalyze raw pacfin ages',
                                     'raw pacfin ages + lengths',
                                     'exp pacfin ages',
                                     'exp pacfin ages + lengths',
                                     'extend to 2024'), 
                    png = TRUE, plotdir = 'report/figures/bridging',
                    filenameprefix = 'bridging2', 
                    legendloc = 'bottomleft')

c(list(base2017 = out1[[1]]), out2) |>
  r4ss::plot_twopanel_comparison(
    dir = 'report/figures/bridging',
    filename = 'bridging2_comparison.png',
    legendlabels = c(
      '2017',
      'first steps',
      'reanalyze raw pacfin ages',
      'raw pacfin ages + lengths',
      'exp pacfin ages',
      'exp pacfin ages + lengths',
      'extend to 2024'
    ),
    legendloc = 'bottomleft',
    endyrvec = c(rep(2017, 6), 2025),
    shadeForecast = FALSE
  )

# bridging plots for group 3
out3_smry <- c(list(base2017 = out1[[1]]), out3) |> 
  SSsummarize() 

out3_smry$SpawnBioLower$replist3 <- out3_smry$SpawnBioUpper$replist3 <- out3_smry$SpawnBio$replist3
out3_smry$BratioLower$replist3 <- out3_smry$BratioUpper$replist3 <- out3_smry$Bratio$replist3

out3_smry |>
  SSplotComparisons(subplots = c(2,4,18), new = FALSE,
                    legendlabels = c('2017',
                                     'reanalyze and extend data',
                                     'selectivity: rec blocks',
                                     'selectivity: hake block, sex-specific rec',
                                     'add H&L, SMURF, various other updates'), 
                    png = TRUE, plotdir = 'report/figures/bridging',
                    filenameprefix = 'bridging3', 
                    legendloc = 'bottomleft')

c(list(base2017 = out1[[1]]), out3) |>
  r4ss::plot_twopanel_comparison(
    dir = 'report/figures/bridging',
    filename = 'bridging3_comparison.png',
    legendlabels = c(
      '2017',
      'reanalyze and extend data',
      'selectivity: rec blocks',
      'selectivity: hake block, sex-specific rec',
      'add H&L, SMURF, various other updates (2025 base model)'
    ),
    legendloc = 'bottomleft',
    uncertainty = c(TRUE, FALSE, FALSE, FALSE, TRUE),
    endyrvec = c(2017, rep(2025, 4)),
    shadeForecast = FALSE
  )

out_gfsc |>
  r4ss::plot_twopanel_comparison(
    dir = 'report/figures/bridging',
    filename = 'bridging_gfsc_comparison.png',
    legendlabels = c(
      '2017',
      'Reanalyze data',
      'Extend data',
      '+ Rec block',
      '+ All other model changes (2025 base model)'
    ),
    legendloc = 'bottomleft',
    endyrvec = c(2017, 2017, rep(2025, 3)),
  )

smry <- out_gfsc |>
  SSsummarize() 
smry$SmryBio <- smry$SmryBio |>
  mutate(across(1:2, ~ifelse(Yr > 2017, NA, .)))

smry |>
  r4ss::SSplotComparisons(
    plotdir = 'report/figures/bridging',
    filenameprefix = 'bridging_gfsc_comparison_smry_bio',
    legendlabels = c(
      '2017',
      'Reanalyze data',
      'Extend data',
      '+ Rec block',
      '+ All other model changes (2025 base model)'
    ),
    legendloc = 'bottomleft',
    subplots = 18, endyrvec = c(2017, 2017, 2025, 2025, 2025),
    new = FALSE, png = TRUE
  )
# Update # Update # Update bias adjustment --------------------------------------------------



mod <- SS_read('model_runs/2.01_extend_2024')


# also update sigmaR to avoid warnings. Tuning indicates 0.5 is about right.

SS_write(mod, 'model_runs/2.02_bias_adjust', overwrite = TRUE)
run('model_runs/2.02_bias_adjust', exe = exe_loc, skipfinished = FALSE, 
    extras = '-nohess')

mods <- SSgetoutput(dirvec = glue::glue('model_runs/{model}', 
                                       model = c('1.02_base_2017_3.30.23',
                                                 '1.12_reanalyze_data_new_abins_reweight',
                                                 # '2.01_extend_2024',
                                                 '2.02_bias_adjust'))) |>
  SSsummarize()
  
SSplotComparisons(mods, subplots = c(1,3, 11), new = FALSE, 
                  legendlabels = c('2017', 
                                   'update everything, retune',
                                   'extend to 2023',
                                   'bias adjustment'))

out <- SS_output('model_runs/2.02_bias_adjust')
SS_plots(out)


# odds and ends ----------------------------------------------------------------

source('Rscripts/model_remove_retention.R')
source('Rscripts/model_rename_fleets.R')

mod <- SS_read('model_runs/2.02_bias_adjust')
mod <- remove_retention(mod) |>
  add_discards()

mod$ctl$Q_options['NWFSCcombo', 'float'] <- 0
mod$ctl$Q_options['NWFSCcombo', 'link'] <- 3

mod$ctl$Q_parms['Q_extraSD_NWFSCcombo(6)', 'INIT'] <- 0
mod$ctl$Q_parms['Q_extraSD_NWFSCcombo(6)', 'PHASE'] <- -1
mod$ctl$Q_parms['LnQ_base_NWFSCcombo(6)', 'PHASE'] <- 2


# mod$ctl$F_Method <- 3
# mod$ctl$maxF <- 4
# need to figure out name of n tuning iterations

SS_write(mod, 'model_runs/2.09_remove_discards_2.02', overwrite = TRUE)
run('model_runs/2.09_remove_discards_2.02', exe = exe_loc, extras = '-nohess')



# No HKL or sparse lengths ----------------------------------------------------------

mod <- SS_read('model_runs/2.02_bias_adjust')

no_hkl_lengths <- readRDS('data/processed/pacfin_lcomps_raw.rds') |>
  `names<-`(names(mod$dat$lencomp))

mod$dat$lencomp <- filter(mod$dat$lencomp, fleet != 1) |>
  bind_rows(no_hkl_lengths)

SS_write(mod, 'model_runs/2.03_no_hkl_lengths', overwrite = TRUE)
run('model_runs/2.03_no_hkl_lengths', exe = exe_loc, skipfinished = FALSE, extras = '-nohess')

# can now actually fit the lengths
tune_comps(dir = 'model_runs/2.03_no_hkl_lengths', niters_tuning = 0, allow_up_tuning = TRUE, exe = exe_loc, extras = '-nohess')

mods <- SSgetoutput(dirvec = glue::glue('model_runs/{model}', 
                                        model = c('2.01_extend_2024',
                                                  '2.02_bias_adjust',
                                                  '2.03_no_hkl_lengths'))) |>
  SSsummarize()

SSplotComparisons(mods, subplots = c(1,3), new = FALSE, 
                  legendlabels = c('extend to 2023',
                                   'bias adjustment',
                                   'No sparse or HKL lengths'))

out <- SS_output('model_runs/2.03_no_hkl_lengths')
SS_plots(out)


# Try to fit index better -------------------------------------------------
mod <- SS_read('model_runs/2.03_no_hkl_lengths')

mod$ctl$Q_options['NWFSCcombo', 'extra_se'] <- 0
mod$ctl$Q_parms <- mod$ctl$Q_parms[-grep('extraSD_NWFSC', rownames(mod$ctl$Q_parms)),]

SS_write(mod, 'model_runs/2.04_no_extrasd_WCGBTS', overwrite = TRUE)
run('model_runs/2.04_no_extrasd_WCGBTS', exe = exe_loc, extras = '-nohess', skipfinished = FALSE)

out <- SS_output('model_runs/2.04_no_extrasd_WCGBTS')
SSplotIndices(out)

tune_comps(dir = 'model_runs/2.04_no_extrasd_WCGBTS', niters_tuning = 0, allow_up_tuning = TRUE, exe = exe_loc, extras = '-nohess')
# nope.


# update lengths and ages -------------------------------------------------
mod <- SS_read('model_runs/2.04_no_extrasd_WCGBTS')

mod$dat$agecomp <- mod_ages$dat$agecomp

mod$dat$lencomp <- mod_lengths$dat$lencomp

# bah this isn't working. we will remove these eventually. be patient.
# mod$dat$use_lencomp <- 2 # downweight discard length comps
# mod$dat$len_info <- bind_rows(mod$dat$len_info, mod$dat$len_info[1,]) |>
#   mutate(fleet = c(1, 1, (-2):(-6)),
#          part = c(1, 2, rep(0, 5))) |>
#   relocate(fleet:part, .before = mintailcomp) |>
#   `rownames<-`(NULL)

SS_write(mod, 'model_runs/2.05_data_deadline_comps', overwrite = TRUE)
run('model_runs/2.05_data_deadline_comps', exe = exe_loc, extras = '-nohess', skipfinished = FALSE, show_in_console = TRUE)

out2 <- SS_output('model_runs/2.05_data_deadline_comps')
SS_plots(out2)

tune_comps(dir = 'model_runs/2.05_data_deadline_comps', niters_tuning = 0, allow_up_tuning = TRUE, exe = exe_loc, extras = '-nohess')


# dome-shaped selectivity -------------------------------------------------

mod <- SS_read('model_runs/2.05_data_deadline_comps')

mod$ctl$size_selex_parms[grep('P_2', rownames(mod$ctl$size_selex_parms)), 'INIT'] <- -15 

mod$ctl$size_selex_parms[grep('P_4', rownames(mod$ctl$size_selex_parms)), 'INIT'] <- 4.5
mod$ctl$size_selex_parms[grep('P_4', rownames(mod$ctl$size_selex_parms)), 'PHASE'] <- 4

SS_write(mod, 'model_runs/2.06_domed_selectivity', overwrite = TRUE)

out <- SS_output('model_runs/2.06_domed_selectivity')
SS_plots(out)

SSsummarize(list(out2, out)) |>
  SStableComparisons()

# creates a bunch of cryptic biomass, increasing the scale (as expected)
# Survey likelihood goes up (I think it is actually the NLL?), but fits are bad regardless
# Decreases M and makes male and female M more similar (as expected)
# triennial and rec selectivity pars are on bounds
# fits to length comps do not changes
# improves fits to age comps
# still trying to actually fit the survey index!!!

# another idea: try expanded comps, tune sigma R

# why is the scale of the survey likelihood so low? It will never get fit well when it is 3 and age comp likelihood is 900.


# expanded PacFIN comps ---------------------------------------------------

mod <- SS_read('model_runs/2.06_domed_selectivity')

pacfin_expanded_ages <- read.csv('data/processed/pacfin_acomps_2023.csv') |>
  `names<-`(names(mod_ages$dat$agecomp)) |>
  mutate(ageerr = 1)

pacfin_expanded_lengths <- read.csv('data/processed/pacfin_lcomps_2023.csv') |>
`names<-`(names(mod_lengths$dat$lencomp))

mod$dat$agecomp <- mod$dat$agecomp |> 
  filter(fleet != 1) |> 
  rbind(pacfin_expanded_ages)

mod$dat$lencomp <- mod$dat$lencomp |> 
  filter(fleet != 1) |> 
  rbind(pacfin_expanded_lengths)

SS_write(mod, 'model_runs/2.07_expanded_pacfin')

tune_comps(niters_tuning = 2, dir = 'model_runs/2.07_expanded_pacfin',
           exe = exe_loc, extras = '-nohess')

out <- SS_output('model_runs/2.07_expanded_pacfin')
SS_plots(out)

# using these comps did weird things to the early rec devs, gave them a quite a trend.
# I wonder if the pacfin expansions are not working well for early years.


# removing discards
source("Rscripts/model_remove_retention.R")
mod <- SS_read('model_runs/2.05_data_deadline_comps') |> 
  remove_retention() |> 
  add_discards()
SS_write(mod, 'model_runs/2.08_remove_discards_from_2.05', overwrite = TRUE)
run('model_runs/2.08_remove_discards_from_2.05', exe = exe_loc, extras = '-nohess')

# troubleshooting ages ----------------------------------------------------

mod_ages <- SS_read('model_runs/1.02_base_2017_3.30.23')

# old data weighting, old sample sizes, new comps
pacfin_ages_adj <- pacfin_ages |>
  filter(year < 2017) 

pacfin_ages_adj[pacfin_ages_adj$fleet == 1, 1:9] <-
  mod_ages$dat$agecomp |> 
  filter(fleet == 1, year >= 1974) |>
  select(year:Nsamp)

mod_ages$dat$agecomp <- mod_ages$dat$agecomp |>
  filter(fleet != 1) |>
  rbind(pacfin_ages_adj) 

SS_write(mod_ages, 'model_runs/new_comp_old_n')
run('model_runs/new_comp_old_n', exe = exe_loc, extras = '-nohess')

# with special projects (pre-1981 only)
# requires rerunning pacfin code, not reproducible at the moment.
mod_ages$dat$agecomp <- mod_ages$dat$agecomp |>
  filter(fleet != 1) |>
  rbind(`names<-`(age_comps_ss3, names(mod$dat$agecomp))) |>
  mutate(ageerr = 1) # only one aging error matrix used

SS_write(mod_ages, dir = 'model_runs/update_pacfin_ages_sp_proj')
run('model_runs/update_pacfin_ages_sp_proj', exe = exe_loc, extras = '-nohess')
tune_comps(niters_tuning = 2, dir = 'model_runs/update_pacfin_ages_sp_proj',
           exe = exe_loc, extras = '-nohess')

# Don't run models, just look at data:
get_long_comps <- function(comps_wide, type = 'age', max_age = 30) {
  if(type == 'age') {
    selection <- comps_wide |>
      select(year, f1:(!!paste0('m', max_age))) 
  } else if(type == 'length') {
    selection <- comps_wide |>
      select(year, f20:m56) 
  } else stop()
  selection |>
    tidyr::pivot_longer(cols = -year, names_to = 'category', values_to = 'freq') |>
    tidyr::separate(category, into = c('sex', 'age'), sep = 1) |>
    group_by(year) |>
    mutate(freq = freq/sum(freq),
           age = as.numeric(age)) 
  
}


bind_rows(list(new_expanded = get_long_comps(pacfin_ages),
               old_ss3 = get_long_comps(mod_ages$dat$agecomp[mod_ages$dat$agecomp$fleet == 1,],
                                        max_age = 25)),
          .id = 'type') |> 
  tidyr::pivot_wider(names_from = type, values_from = freq) |>
  filter(age < 25) |>
  ggplot(aes(x = new_expanded, y = old_ss3, col = age)) +
  geom_point(alpha = 0.5)

expanded_ages <- read.csv('data/processed/pacfin_acomps_2023.csv') |>
  mutate(ageerr = 1)

names(expanded_ages)[1:9] <- names(mod_ages$dat$agecomp)[1:9]

bind_rows(list(new_expanded = get_long_comps(expanded_ages),
               old_ss3 = get_long_comps(mod_ages$dat$agecomp[mod_ages$dat$agecomp$fleet == 1,],
                                        max_age = 25)),
          .id = 'type') |> 
  tidyr::pivot_wider(names_from = type, values_from = freq) |>
  filter(age < 25) |>
  ggplot(aes(x = new_expanded, y = old_ss3, col = age)) +
  geom_point(alpha = 0.5)
# removing CA samples south of 40-10 makes no difference, comps were not expanded in 2017.

bind_rows(list(new_expanded = get_long_comps(pacfin_lengths[pacfin_lengths$sex == 3,], type = 'length'),
               old_ss3 = get_long_comps(mod_lengths$dat$lencomp[mod_lengths$dat$lencomp$fleet == 1 &
                                                                  mod_lengths$dat$lencomp$part == 2,], type = 'length')),
          .id = 'type') |> 
  tidyr::pivot_wider(names_from = type, values_from = freq) |>
  ggplot(aes(x = new_expanded, y = old_ss3, col = age)) +
  geom_point()
