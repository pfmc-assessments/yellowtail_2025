library(r4ss)
library(here)
library(dplyr)

exe_loc <- here('model_runs/ss3.exe')
source('Rscripts/bins.R')

# update catches ----------------------------------------------------------

mod_catches <- SS_read('model_runs/1.02_base_2017_3.30.23')

mod_catches$dat$catch <- readRDS('data/processed/ss3_landings_2023.rds')

SS_write(mod_catches, dir = 'model_runs/1.05_reanalyze_catch', overwrite = TRUE)
run('model_runs/1.05_reanalyze_catch', 
    exe = exe_loc, extras = '-nohess', verbose = TRUE, 
    skipfinished = FALSE)

# update ages -------------------------------------------------------------

mod_ages <- SS_read('model_runs/1.02_base_2017_3.30.23')

mod_ages$dat$agebin_vector <- age_bin
mod_ages$dat$N_agebins <- length(age_bin)

pacfin_ages <- readRDS('data/processed/pacfin_acomps_raw.rds') 
names(pacfin_ages)[1:9] <- names(mod_ages$dat$agecomp)[1:9]

# don't use expanded ages for more consistency with 2017 
  # read.csv('data/processed/pacfin_acomps_2023.csv') |>
  # `names<-`(names(mod_ages$dat$agecomp)) |>
  # mutate(ageerr = 1)

rec_ages <- readRDS('data/processed/ss3_rec_age_comps.rds') |> 
  mutate(fleet = 4, ageerr = as.numeric(1)) 
names(rec_ages)[1:9] <- names(mod_ages$dat$agecomp)[1:9]

# this is actually not straightforward. if updating catches, rec ages should be assigned to 3
# if not updating rec catches, rec ages should be assigned to fleet 4.

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
  rec_ages, 
  wcgbts_ages, 
  wcgbts_mar_ages,
  tri_ages,
  tri_mar_ages
)

SS_write(mod_ages, dir = 'model_runs/1.06_ages_retune', overwrite = TRUE)
run('model_runs/1.06_ages_retune', 
    exe = exe_loc, extras = '-nohess', verbose = TRUE, 
    skipfinished = FALSE)
tune_comps(niters_tuning = 2, dir = 'model_runs/1.06_ages_retune',
           exe = exe_loc, extras = '-nohess')

# update lengths ----------------------------------------------------------

mod_lengths <- SS_read('model_runs/1.02_base_2017_3.30.23')

pacfin_lengths <- readRDS('data/processed/pacfin_lcomps_raw.rds') |>
  `names<-`(names(mod_lengths$dat$lencomp))

# don't use expanded lengths for more consistency with 2017 
  # read.csv('data/processed/pacfin_lcomps_2023.csv') |>
  # `names<-`(names(mod_lengths$dat$lencomp))

rec_lengths <- readRDS('data/processed/ss3_rec_length_comps.rds') |> 
  `names<-`(names(mod_lengths$dat$lencomp)) |>
  mutate(fleet = 3)

ashop_lengths <- readRDS('data/processed/ss3_ashop_comps_2023.rds') |>
  `names<-`(names(mod_lengths$dat$lencomp))

wcgbts_lengths <- readRDS('data/processed/ss3_wcgbts_length_comps.rds') |>
  mutate(fleet = 6) |>
  `names<-`(names(mod_lengths$dat$lencomp))

tri_lengths <- readRDS('data/processed/ss3_tri_length_comps.rds') |>
  mutate(fleet = 5) |>
  `names<-`(names(mod_lengths$dat$lencomp))

  
mod_lengths$dat$lencomp <- mod_lengths$dat$lencomp |>
  filter(part == 1) |> # commercial discards only fleet without reanalyzed comps
  bind_rows(pacfin_lengths, ashop_lengths, rec_lengths, wcgbts_lengths, tri_lengths)

SS_write(mod_lengths, dir = 'model_runs/1.07_lengths_retune', overwrite = TRUE)
run('model_runs/1.07_lengths_retune', 
    exe = exe_loc, extras = '-nohess', verbose = TRUE, 
    skipfinished = FALSE)
tune_comps(dir = 'model_runs/1.07_lengths_retune', 
           niters_tuning = 2, exe = exe_loc, extras = '-nohess')

# update indices -----------------------------------------------------------

mod_survey <- SS_read('model_runs/1.02_base_2017_3.30.23')

load("data/confidential/wcgbts_updated/interaction/delta_lognormal/index/sdmTMB_save.RData")

wcgbts <- results_by_area$`North of Cape Mendocino`$index |>
  mutate(month = 7, index = 6) |> # is this right?
  rename(obs = est, se_log = se) |>
  select(names(mod_survey$dat$CPUE))
  
load("data/confidential/triennial/delta_lognormal/index/sdmTMB_save.RData")

triennial <- results_by_area$`North of Cape Mendocino`$index |>
  mutate(month = 7, index = 5) |> # is this right?
  rename(obs = est, se_log = se) |>
  select(names(mod_survey$dat$CPUE))

mod_survey$dat$CPUE <- bind_rows(wcgbts, triennial)

mod_survey$ctl$Q_options <- mod_survey$ctl$Q_options[c('Triennial', 'NWFSCcombo'),]
mod_survey$ctl$Q_parms <- mod_survey$ctl$Q_parms[grep('Tri|NWFSC', rownames(mod_survey$ctl$Q_parms)),]


SS_write(mod_survey, dir = 'model_runs/1.08_surveys', overwrite = TRUE)
run('model_runs/1.08_surveys', 
    exe = exe_loc, extras = '-nohess', verbose = TRUE, 
    skipfinished = FALSE, show_in_console = TRUE)

# all together ------------------------------------------------------------

mod <- SS_read('model_runs/1.02_base_2017_3.30.23')

mod$dat$catch <- mod_catches$dat$catch
mod$dat$lencomp <- mod_lengths$dat$lencomp
mod$dat$CPUE <- mod_survey$dat$CPUE

mod$ctl$size_selex_parms$PHASE[grep('RecWA', rownames(mod$ctl$size_selex_parms))] <- -99
mod$ctl$size_selex_parms_tv$PHASE[grep('RecWA', rownames(mod$ctl$size_selex_parms_tv))] <- -99
mod$ctl$Q_options <- mod$ctl$Q_options[c('Triennial', 'NWFSCcombo'),]
mod$ctl$Q_parms <- mod$ctl$Q_parms[grep('Tri|NWFSC', rownames(mod$ctl$Q_parms)),]

# first everything but the age comps
# SS_write(mod, dir = 'model_runs/1.11_all_data_but_ages', overwrite = TRUE)
# run('model_runs/1.11_all_data_but_ages',
#     exe = exe_loc, extras = '-nohess', verbose = TRUE,
#     skipfinished = FALSE)
# 
# tune_comps(dir = 'model_runs/1.11_all_data_but_ages',
#            niters_tuning = 2, exe = exe_loc, extras = '-nohess')

# now add the age comps
mod$dat$agecomp <- mod_ages$dat$agecomp |>
  mutate(fleet = ifelse(fleet == 4, 3, fleet))

mod$dat$agebin_vector <- age_bin
mod$dat$N_agebins <- length(age_bin)

SS_write(mod, dir = 'model_runs/1.12_reanalyze_data_new_abins_reweight', overwrite = TRUE)
run('model_runs/1.12_reanalyze_data_new_abins_reweight', 
    exe = exe_loc, 
    extras = '-nohess',
    verbose = TRUE, 
    skipfinished = FALSE)

# copy_SS_inputs(dir.old = 'model_runs/1.03_reanalyze_data', 
#                dir.new = 'model_runs/1.04_reanalyze_reweight', 
#                overwrite = TRUE)
# 
# file.copy(from = glue::glue('model_runs/1.03_reanalyze_data/{file}', file = c('Report.sso', 'compreport.sso')),
#           to = glue::glue('model_runs/1.04_reanalyze_reweight/{file}', file = c('Report.sso', 'compreport.sso')),
#           overwrite = TRUE)
#           
tune_comps(dir = 'model_runs/1.12_reanalyze_data_new_abins_reweight', 
           niters_tuning = 2, exe = exe_loc, extras = '-nohess') 


mods <- SSgetoutput(dirvec = glue::glue('model_runs/1.{model}', 
                                        model = c('02_base_2017_3.30.23',
                                                  '05_reanalyze_catch',
                                                  '06_ages_retune',
                                                  '07_lengths_retune',
                                                  '08_surveys',
                                                  # '11_all_data_but_ages',
                                                  '12_reanalyze_data_new_abins_reweight'))) |>
  SSsummarize()

SSplotComparisons(mods, subplots = c(1,3), new = FALSE, 
                  legendlabels = c('2017', 
                                   'update catches',
                                   'update ages, retune',
                                   'update lengths, retune',
                                   'update surveys',
                                   # 'update all but ages, retune',
                                   'update everything, retune'))

mods <- SSgetoutput(dirvec = c('model_runs/1.02_base_2017_3.30.23',
                               'model_runs/1.06_ages_retune',
                               'model_runs/1.09_new_comp_old_n',
                               'model_runs/1.10_update_pacfin_ages_sp_proj')) |>
  SSsummarize()
SSplotComparisons(mods, subplots = c(1), 
                  legendlabels = c('2017', 
                                   'update ages, retune',
                                   'update comps, not N',
                                   'include 70s OR ages, retune'))


# conclusion: reanalysis of age data led to departure in scale
# maybe look into this a small amount.
out <- SS_output('model_runs/1.04_reanalyze_reweight')
SS_plots(out)

# extend to 2024 ----------------------------------------------------------

mod <- SS_read('model_runs/1.12_reanalyze_data_new_abins_reweight')
mod$dat$endyr <- 2024
mod$ctl$Block_Design <- purrr::map(mod$ctl$Block_Design,
                                   \(x){x[length(x)] <- 2024; return(x)})
mod$ctl$MainRdevYrLast <- 2018

SS_write(mod, 'model_runs/2.01_extend_2024', overwrite = TRUE)
run('model_runs/2.01_extend_2024', 
    exe = exe_loc, 
    # extras = '-nohess',
    verbose = TRUE, 
    skipfinished = FALSE)

out <- SS_output('model_runs/2.01_extend_2024')
SS_plots(out)

mods <- SSgetoutput(dirvec = glue::glue('model_runs/{model}', 
                                        model = c('1.02_base_2017_3.30.23',
                                                  '1.04_reanalyze_reweight',
                                                  '2.01_extend_2024'))) |>
  SSsummarize()

SSplotComparisons(mods, subplots = c(1,3), new = FALSE, 
                  legendlabels = c('2017', 
                                   'update everything, retune',
                                   'extend to 2023'))

new_ages_long <- pacfin_ages |>
  select(year, f1:f25) |>
  tidyr::pivot_longer(cols = -year, names_to = 'age', values_to = 'freq') |>
  group_by(year) |>
  mutate(freq = freq/sum(freq),
         age = as.numeric(stringr::str_remove(age, 'f'))) |>
  filter(year < 2017)


# Update bias adjustment --------------------------------------------------

mod <- SS_read('model_runs/2.01_extend_2024')

mod$ctl$last_early_yr_nobias_adj <- 1950.5
mod$ctl$first_yr_fullbias_adj <- 1976.9
mod$ctl$last_yr_fullbias_adj <- 2016.5
mod$ctl$first_recent_yr_nobias_adj <- 2021.6
mod$ctl$max_bias_adj <- 0.7855

SS_write(mod, 'model_runs/2.02_bias_adjust')
run('model_runs/2.02_bias_adjust', exe = exe_loc, skipfinished = FALSE, extras = '-nohess')

mods <- SSgetoutput(dirvec = glue::glue('model_runs/{model}', 
                                       model = c('1.02_base_2017_3.30.23',
                                                 '1.04_reanalyze_reweight',
                                                 '2.01_extend_2024',
                                                 '2.02_bias_adjust'))) |>
  SSsummarize()
  
SSplotComparisons(mods, subplots = c(1,3, 11), new = FALSE, 
                  legendlabels = c('2017', 
                                   'update everything, retune',
                                   'extend to 2023',
                                   'bias adjustment'))

out <- SS_output('model_runs/2.02_bias_adjust')
SS_plots(out)


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
