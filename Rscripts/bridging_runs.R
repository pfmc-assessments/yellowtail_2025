library(r4ss)
library(here)
library(dplyr)

exe_loc <- here('model_runs/ss3.exe')
source('Rscripts/bins.R')
source('Rscripts/model_rename_fleets.R')
source('Rscripts/model_remove_retention.R')

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

out <- SSgetoutput(dirvec = c('model_runs/1.02_base_2017_3.30.23',
                       glue::glue('model_runs/3.0{mod}', 
                                  mod = c('1_reanalyze_catch', 
                                          '2_surveys', 
                                          '3_biology', 
                                          '4_discards')))) |>
  SSsummarize()

SSplotComparisons(out, subplots = c(1,3), legendlabels = c('2017', 'catch', '+survey', '+biology', '+discard'), new = FALSE)

# update ages -------------------------------------------------------------

mod_ages <- SS_read('model_runs/3.04_discards')

mod_ages$dat$agebin_vector <- age_bin
mod_ages$dat$N_agebins <- length(age_bin)

pacfin_ages <- read.csv('data/processed/pacfin_acomps_raw.csv') 
names(pacfin_ages)[1:9] <- names(mod_ages$dat$agecomp)[1:9]

ashop_ages <- readRDS('data/processed/ss3_ashop_ages.rds')
names(ashop_ages)[1:9] <- names(mod_ages$dat$agecomp)[1:9]

rec_ages <- readRDS('data/processed/ss3_rec_age_comps.rds') |> 
  mutate(fleet = 3, ageerr = as.numeric(1)) 
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
  `names<-`(names(mod_lengths_raw$dat$lencomp))

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
  `names<-`(names(mod_lengths_exp$dat$lencomp))

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

out <- SSgetoutput(dirvec = c('model_runs/1.02_base_2017_3.30.23',
                              glue::glue('model_runs/3.0{mod}', 
                                         mod = c('4_discards',
                                                 '5_ages_raw_pacfin',
                                                 '6_ages_exp_pacfin',
                                                 '7_lengths_raw_pacfin',
                                                 '8_lengths_exp_pacfin'))))
SSsummarize(out) |>
  SSplotComparisons(subplots = c(1,3), 
                    legendlabels = c('2017', 'stuff', 'raw ages', 'exp ages', 'raw ages+len', 'exp ages+len'), 
                    new = FALSE)

SSsummarize(out) |> SStableComparisons()

SS_plots(out[[5]])
SS_plots(out[[6]])

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

out <- SSgetoutput(dirvec = c('model_runs/1.02_base_2017_3.30.23',
                              glue::glue('model_runs/3.{mod}', 
                                         mod = c('04_discards',
                                                 '07_lengths_raw_pacfin',
                                                 '08_lengths_exp_pacfin',
                                                 '09_raw_comps_2024',
                                                 '10_exp_comps_2024'))))

SS_plots(out[[5]])
SS_plots(out[[6]])

out |>
  SSsummarize() |>
  SSplotComparisons(subplots = c(1,3), new = FALSE, 
                    legendlabels = c('2017', 
                                     'most updates',
                                     'raw pacfin',
                                     'expanded pacfin',
                                     'raw pacfin to 20204',
                                     'expanded pacfin to 2024'))

new_ages_long <- pacfin_ages |>
  select(year, f1:f25) |>
  tidyr::pivot_longer(cols = -year, names_to = 'age', values_to = 'freq') |>
  group_by(year) |>
  mutate(freq = freq/sum(freq),
         age = as.numeric(stringr::str_remove(age, 'f'))) |>
  filter(year < 2017)

profile_info <- nwfscDiag::get_settings_profile(parameters = 'NatM_uniform_Fem_GP_1',
                                                low = 0.1, high = 0.2, step_size = 0.01,
                                                param_space = 'real')
model_settings <- nwfscDiag::get_settings(
  settings = list(base_name = '3.10_exp_comps_2024',
                  run = 'profile',
                  profile_details = profile_info,
                  exe = exe_loc)
)

future::plan(future::multisession, workers = parallelly::availableCores(omit = 1))
nwfscDiag::run_diagnostics(mydir = 'model_runs',
                           model_settings = model_settings)

model_settings$base_name <- '3.09_raw_comps_2024'
nwfscDiag::run_diagnostics(mydir = 'model_runs',
                           model_settings = model_settings)
future::plan(future::sequential)


# Selectivity changes -----------------------------------------------------

mod <- SS_read('model_runs/3.10_exp_comps_2024')

# get rid of discard and random unused block
mod$ctl$N_Block_Designs <- 1
mod$ctl$blocks_per_pattern <- 1
# 2017 used 2003, added at STAR panel. 
# Ali recommended 2004 (when yelloweye depth restrictions went into place) and it matches data better.
mod$ctl$Block_Design <- list(c(2004, 2024))
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
# only block descending limb (ascending limb parameter did not change)
mod$ctl$size_selex_parms[paste0('SizeSel_P_', c(1,3), '_Recreational(3)'), c('Block', 'Block_Fxn')] <- 0
# blocks were redefined
mod$ctl$size_selex_parms['SizeSel_P_4_Recreational(3)', 'Block'] <- 1
# only one tv parameter is left
mod$ctl$size_selex_parms_tv <- mod$ctl$size_selex_parms_tv['SizeSel_P_4_Recreational(3)_BLK3repl_2004',]

SS_write(mod, 'model_runs/4.01_simplify_selex', overwrite = TRUE)
run('model_runs/4.01_simplify_selex', exe = exe_loc, extras = '-nohess', skipfinished = FALSE)


mod <- SS_read('model_runs/4.01_simplify_selex')

# add new block for longleader fishery
mod$ctl$blocks_per_pattern <- 2
# need to decide whether new block starts 2017 or 2018
mod$ctl$Block_Design <- list(c(2004, 2017, 2018, 2024))

# add new row to tv selectivity pars
mod$ctl$size_selex_parms_tv <- slice(mod$ctl$size_selex_parms_tv, c(1,1))
rownames(mod$ctl$size_selex_parms_tv) <- paste0('SizeSel_P_4_Recreational(3)_BLK1repl_', c(2003, 2018))

SS_write(mod, 'model_runs/4.02_add_rec_block', overwrite = TRUE)
run('model_runs/4.02_add_rec_block', exe = exe_loc, extras = '-nohess', skipfinished = FALSE)

mod <- SS_read('model_runs/4.02_add_rec_block')

# block for peak parameter
mod$ctl$size_selex_parms['SizeSel_P_1_Recreational(3)', c('Block', 'Block_Fxn')] <- c(1, 2)

mod$ctl$size_selex_parms_tv <- bind_rows(
  mod$ctl$size_selex_parms['SizeSel_P_1_Recreational(3)', 1:7],
  mod$ctl$size_selex_parms['SizeSel_P_1_Recreational(3)', 1:7],
  mod$ctl$size_selex_parms_tv
)
rownames(mod$ctl$size_selex_parms_tv)[1:2] <- paste0('SizeSel_P_1_Recreational(3)_BLK1repl_', c(2003, 2018)) 

SS_write(mod, 'model_runs/4.03_block_peak_param', overwrite = TRUE)
run('model_runs/4.03_block_peak_param', exe = exe_loc, extras = '-nohess', skipfinished = FALSE)

out <- SSgetoutput(dirvec = paste0('model_runs/', c('3.10_exp_comps_2024',
                                                    '4.01_simplify_selex',
                                                    '4.02_add_rec_block',
                                                    '4.03_block_peak_param')))

out_sum <- SSsummarize(out)
SStableComparisons(out_sum)
SSplotComparisons(out_sum, subplots = c(1,3), new = FALSE, legendlabels = c('working base', 'simplify selex',
                                                                            'add longleader block', 'block peak param'))
SS_plots(out[[4]], new = FALSE)

# consider fixing descending limb of last rec block so that it is logistic.
# need to deal with peak of hake (hitting bound), triennial (will hit bound if allowed to be estimated)
# I think if the hake bound increases to the max popn lbin it is estimable.
# Triennial hits bound no matter what. (Bizarre)

# Update bias adjustment --------------------------------------------------

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
