# first draft script to run diagnostics
# TODO: add paralelization
directory <- here::here("Model_Runs")
base_model_name <- "4.12_age_and_M"

profile_info <- nwfscDiag::get_settings_profile( 
  parameters =  c("NatM_uniform_Fem_GP_1", "SR_BH_steep", "SR_LN(R0)"),
  low =  c(0.40, 0.25, -2),
  high = c(0.40, 1.0,  2),
  step_size = c(0.005, 0.05, 0.25),
  param_space = c('multiplier', 'real', 'relative')
  )

model_settings <- nwfscDiag::get_settings(
  mydir = file.path(directory),
  settings = list(
    base_name = base_model_name,
      run = c("jitter", "profile", "retro"),
      profile_details = profile_info )
    )

nwfscDiag::run_diagnostics(mydir = directory, model_settings = model_settings)

directory <- here::here("Model_Runs")
base_model_name <- "4.13_age_and_M_recdev2"
nwfscDiag::run_mcmc_diagnostics(dir_wd = file.path(directory, base_model_name))
