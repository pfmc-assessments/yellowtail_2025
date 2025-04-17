# first draft script to run diagnostics
directory <- here::here("Model_Runs")
base_model_name <- "5.07_smurf_fix_hake"

exe_loc <- here(directory, 'ss3.exe')

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
    profile_details = profile_info,
    exe = exe_loc)
)


# run in parallel
future::plan(future::multisession(workers = parallelly::availableCores(omit = 1)))

nwfscDiag::run_diagnostics(mydir = directory, model_settings = model_settings)

# back to sequential processing
future::plan(future::sequential)

directory <- here::here("Model_Runs")
base_model_name <- "4.13_age_and_M_recdev2"
nwfscDiag::run_mcmc_diagnostics(dir_wd = file.path(directory, base_model_name))
