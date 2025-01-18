library(r4ss)
library(here)
library(dplyr)

exe_loc <- here('model_runs/ss3.exe')

# update catches ----------------------------------------------------------

mod_catches <- SS_read('model_runs/1.02_base_2017_3.30.23')

mod_catches$dat$catch <- readRDS('data/processed/ss3_landings_2023.rds')

SS_write(mod_catches, dir = 'model_runs/1.05_reanalyze_catch', overwrite = TRUE)
run('model_runs/1.05_reanalyze_catch', 
    exe = exe_loc, extras = '-nohess', verbose = TRUE, 
    skipfinished = FALSE)

# update ages -------------------------------------------------------------

mod_ages <- SS_read('model_runs/1.02_base_2017_3.30.23')

pacfin_ages <- read.csv('data/processed/pacfin_acomps_2023.csv') |>
  `names<-`(names(mod_ages$dat$agecomp)) |>
  mutate(ageerr = 1)

rec_ages <- readRDS('data/processed/ss3_rec_age_comps.rds') |>
  mutate(fleet = 3, age_error = numeric(1)) |>
  `names<-`(names(mod_ages$dat$agecomp)) 

# this is actually not straightforward. if updating catches, rec ages should be assigned to 3
# if not updating rec catches, rec ages should be assigned to fleet 4.

mod_ages$dat$agecomp <- mod_ages$dat$agecomp |> 
  filter(fleet != 1, fleet != 4) |> # redo commercial, rec ages
  bind_rows(pacfin_ages, rec_ages)

SS_write(mod_ages, dir = 'model_runs/1.06_ages_retune', overwrite = TRUE)
run('model_runs/1.06_ages_retune', 
    exe = exe_loc, extras = '-nohess', verbose = TRUE, 
    skipfinished = FALSE)
tune_comps(niters_tuning = 2, dir = 'model_runs/1.06_ages_retune',
           exe = exe_loc, extras = '-nohess')

# update lengths ----------------------------------------------------------

mod_lengths <- SS_read('model_runs/1.02_base_2017_3.30.23')

pacfin_lengths <- read.csv('data/processed/pacfin_lcomps_2023.csv') |>
  `names<-`(names(mod_lengths$dat$lencomp))

rec_length <- readRDS('data/processed/ss3_rec_length_comps.rds') |> 
  `names<-`(names(mod_lengths$dat$lencomp)) |>
  mutate(fleet = 3)

ashop_lengths <- readRDS('data/processed/ss3_ashop_comps_2023.rds') |>
  `names<-`(names(mod_lengths$dat$lencomp))

mod_lengths$dat$lencomp <- mod_lengths$dat$lencomp |>
  filter(!(fleet %in% 1:4)) |>
  bind_rows(pacfin_lengths, ashop_lengths, rec_lengths)

SS_write(mod_lengths, dir = 'model_runs/1.07_lengths_retune', overwrite = TRUE)
run('model_runs/1.07_lengths_retune', 
    exe = exe_loc, extras = '-nohess', verbose = TRUE, 
    skipfinished = FALSE)
tune_comps(dir = 'model_runs/1.07_lengths_retune', 
           niters_tuning = 2, exe = exe_loc, extras = '-nohess')

# update wcgbts -----------------------------------------------------------

mod_wcgbts <- SS_read('model_runs/1.02_base_2017_3.30.23')

load("Q:/Assessments/CurrentAssessments/yellowtail_rockfish_north/data/indices/wcgbts/year-area_pass/delta_lognormal/index/sdmTMB_save.RData")

wcgbts <- results_by_area$`North of Cape Mendocino`$index |>
  mutate(month = 1, index = 6) |> # is this right?
  rename(obs = est, se_log = se) |>
  select(names(mod_wcgbts$dat$CPUE))
  
mod_wcgbts$dat$CPUE <- mod_wcgbts$dat$CPUE |>
  filter(index == 5) |> # throw out fishery-dependent, replace wcgbts
  bind_rows(wcgbts)

SS_write(mod_wcgbts, dir = 'model_runs/1.08_wcgbts', overwrite = TRUE)
run('model_runs/1.08_wcgbts', 
    exe = exe_loc, extras = '-nohess', verbose = TRUE, 
    skipfinished = FALSE)

# all together ------------------------------------------------------------

mod <- SS_read('model_runs/1.02_base_2017_3.30.23')

mod$dat$catch <- mod_catches$dat$catch
mod$dat$agecomp <- mod_ages$dat$agecomp
mod$dat$lencomp <- mod_lengths$dat$lencomp
mod$dat$CPUE <- mod_wcgbts$dat$CPUE

SS_write(mod, dir = 'model_runs/1.04_reanalyze_reweight', overwrite = TRUE)
run('model_runs/1.04_reanalyze_reweight', 
    exe = exe_loc, extras = '-nohess', verbose = TRUE, 
    skipfinished = FALSE)
tune_comps(dir = 'model_runs/1.04_reanalyze_reweight', 
           niters_tuning = 2, exe = exe_loc, extras = '-nohess')


mods <- SSgetoutput(dirvec = glue::glue('model_runs/1.{model}', 
                                        model = c('02_base_2017_3.30.23',
                                                  '05_reanalyze_catch',
                                                  '06_ages_retune',
                                                  '07_lengths_retune',
                                                  '08_wcgbts',
                                                  '04_reanalyze_reweight'))) |>
  SSsummarize()

SSplotComparisons(mods, subplots = c(1,3), 
                  legendlabels = c('2017', 
                                   'update catches', 
                                   'update ages, retune', 
                                   'update lengths, retune',
                                   'update wcgbts',
                                   'update everything, retune'))

# conclusion: reanalysis of age data led to departure in scale
# maybe look into this a small amount.


# extend to 2023 ----------------------------------------------------------

mod <- SS_read('model_runs/1.04_reanalyze_reweight')
mod$dat$endyr <- 2023
mod$ctl$Block_Design <- purrr::map(mod$ctl$Block_Design,
                                   \(x){x[length(x)] <- 2023; return(x)})

SS_write(mod, 'model_runs/2.01_extend_2023')
run('model_runs/2.01_extend_2023', 
    exe = exe_loc, extras = '-nohess', verbose = TRUE, 
    skipfinished = FALSE)

mods <- SSgetoutput(dirvec = glue::glue('model_runs/{model}', 
                                        model = c('1.02_base_2017_3.30.23',
                                                  '1.04_reanalyze_reweight',
                                                  '2.01_extend_2023'))) |>
  SSsummarize()

SSplotComparisons(mods, subplots = c(1,3), 
                  legendlabels = c('2017', 
                                   'update everything, retune',
                                   'extend to 2023'))

