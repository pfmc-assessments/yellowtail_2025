model_directory <- 'model_runs'
base_model_name <- '4.11_sex_selex_setup'
exe_loc <- 'model_runs/ss3.exe'
future::plan(future::multisession(workers = parallelly::availableCores(omit = 1)))

# Diagnostics -------------------------------------------------------------


profile_info <- nwfscDiag::get_settings_profile(parameters = 'NatM_uniform_Fem_GP_1',
                                                low = 0.1, high = 0.2, step_size = 0.01,
                                                param_space = 'real')
model_settings <- nwfscDiag::get_settings(
  settings = list(base_name = base_model_name,
                  run = 'profile',
                  profile_details = profile_info,
                  exe = exe_loc)
)


# Sensitivities -----------------------------------------------------------

base_model <- SS_read(file.path(model_directory, base_model_name))



# SMURFS ------------------------------------------------------------------

sensi_mod <- base_model
smurf <- read.csv('Data/raw_not_confidential/SMURF index/index_forSS.csv') |>
  mutate(index = 4) |>
  rename(se_log = logse) |>
  select(-fleet)

sensi_mod$dat$fleetinfo[sensi_mod$dat$fleetinfo$fleetname == 'PLACEHOLDER',] <- c(3, 1, 1, 2, 0, 'SMURF')
rownames(sensi_mod$dat$CPUEinfo) <- sensi_mod$dat$fleetinfo$fleetname
sensi_mod$dat$CPUEinfo['SMURF','units'] <- 33 # recruitment, age-0 recruits;

sensi_mod$dat$CPUE <- bind_rows(sensi_mod$dat$CPUE,
                                smurf)

sensi_mod$ctl$Q_options <- rbind(sensi_mod$ctl$Q_options,
                                     SMURF = c(4,1,0,1,0,0)) |>
  slice(3,1,2) # reorder
sensi_mod$ctl$Q_parms <- bind_rows(sensi_mod$ctl$Q_parms[1:2,], # copy triennial Q setup for SMURF
                                   sensi_mod$ctl$Q_parms)
rownames(sensi_mod$ctl$Q_parms) <- rownames(sensi_mod$ctl$Q_parms) |>
  stringr::str_replace('Triennial\\(5\\)\\.\\.\\.[1|2]', 'SMURF(4)') |> # fix row names
  stringr::str_remove('\\.\\.\\.[:digit:]')

# bias adjustment (from an earlier model run with hessian)
sensi_mod$ctl$last_early_yr_nobias_adj <- 1950.6250
sensi_mod$ctl$first_yr_fullbias_adj <- 1975.0898
sensi_mod$ctl$last_yr_fullbias_adj <- 2015.1215
sensi_mod$ctl$first_recent_yr_nobias_adj <- 2024.9174
sensi_mod$ctl$max_bias_adj <- 0.8053

# no selectivity changes needed.

SS_write(sensi_mod, file.path(model_directory, 'sensitivities', 'SMURF'))

out <- SSgetoutput(dirvec = c(file.path(model_directory, base_model_name),
                              file.path(model_directory, 'sensitivities', 'SMURF')))
SSsummarize(out) |>
  SSplotComparisons(subplots = c(1,3), endyrvec = 2037, new = FALSE)


# ORBS

orbs <- read.csv('Data/raw_not_confidential/ORBS index/index_forSS.csv') |>
  mutate(index = 3) |>
  rename(se_log = logse) |>
  select(-fleet)

sensitivity_dirs <- file.path(model_directory, c())

furrr::future_map(sensitivity_dirs, run(., exe = exe_loc, extras = '-nohess', skipfinished = FALSE))
