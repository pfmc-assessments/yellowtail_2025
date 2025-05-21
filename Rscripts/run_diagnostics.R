library(nwfscDiag)
directory <- here::here("Model_Runs")
base_model_name <- "5.09_no_extra_SE"

exe_loc <- here::here(directory, 'ss3.exe')

profile_info <- nwfscDiag::get_settings_profile(
  parameters = c("NatM_uniform_Fem_GP_1", "SR_BH_steep", "SR_LN(R0)"),
  low = c(0.40, 0.25, -2),
  high = c(0.40, 1.0, 2),
  step_size = c(0.005, 0.05, 0.25),
  param_space = c("multiplier", "real", "relative")
)

model_settings <- nwfscDiag::get_settings(
  mydir = file.path(directory),
  settings = list(
    base_name = base_model_name,
    run = c("jitter", "profile", "retro"),
    profile_details = profile_info,
    exe = exe_loc)
)


# set up parallel stuff
future::plan(future::multisession(workers = parallelly::availableCores(omit = 1)))

# run diagnostics
nwfscDiag::run_diagnostics(mydir = directory, model_settings = model_settings)

# back to sequential processing
future::plan(future::sequential)

# find output from nwfscDiag in the folders parallel to the base model
jitter_dir <- dir(directory, pattern = paste0(base_model_name, "_jitter"), full.names = TRUE)
profile_dirs <- dir(directory, pattern = paste0(base_model_name, "_profile"), full.names = TRUE)
retro_dir <- dir(directory, pattern = paste0(base_model_name, "_retro"), full.names = TRUE)
# gather all the output files from the jitter, profile, and retro runs
jitter_outputs <- dir(jitter_dir, pattern = "^jitter*", full.names = TRUE)
retro_outputs <- dir(retro_dir, full.names = TRUE, include.dirs = FALSE)
profile_outputs <- profile_dirs |>
  purrr::map(~ list.files(.x, pattern = "(*.png|*.csv)", full.names = TRUE)) |>
  unlist()
# copy all the output files to a directory called "diagnostics" in the report folder
file.copy(jitter_outputs, "report/diagnostics", overwrite = TRUE)
file.copy(retro_outputs, "report/diagnostics", overwrite = TRUE) 
file.copy(profile_outputs, "report/diagnostics", overwrite = TRUE)


# MCMC diagnostics (requires exe in model directory)
if(!file.exists(file.path(directory, base_model_name, "ss3.exe"))) {
  file.copy(exe_loc, file.path(directory, base_model_name, "ss3.exe"))
}
nwfscDiag::run_mcmc_diagnostics(dir_wd = file.path(directory, base_model_name))

## 15-year retros
model_settings <- get_settings(
  settings = list(
    base_name = base_model_name,
    run = "retro",
    retro_yrs = -1:-15
  )
)
# note this won't overwrite the previous run because the folder name will be "15_yr_peel"
run_diagnostics(mydir = "Model_Runs", model_settings = model_settings)

# r10 <- SS_output('Model_Runs/5.02_forecast_retro_15_yr_peel/retro/retro-10', printstats = FALSE, verbose = FALSE)
# r15 <- SS_output('Model_Runs/5.02_forecast_retro_15_yr_peel/retro/retro-15', printstats = FALSE, verbose = FALSE)

retros <- SSgetoutput(
  dirvec = file.path(
    'Model_Runs/5.09_no_extra_SE_retro_16_yr_peel/retro/',
    paste0('retro-', 1:15)
  )
)
retros <- c(list(base = mod_out), retros)
retro_sum <- SSsummarize(retros)

png(
  file.path("report/diagnostics", "recruitment_retrospective_squid_long1.png"),
  width = 6.5, height = 5, units = "in", res = 300
)
SSplotRetroRecruits(
  endyrvec = c(2024 + 0:-16),
  cohorts = 2006:2024,
  retroSummary = retro_sum,
  main = NULL
)
dev.off()

# make new time series figures for profiles but with fewer lines
# files exist only after running nwfscDiag commands above

# R0 profile
mods <- SSgetoutput("Model_Runs/5.09_no_extra_SE_profile_SR_LN(R0)", keyvec = 1:16)
mod_sum <- SSsummarize(mods)
# figure out parameter values for each model
parvec <- mod_sum$pars |> 
  dplyr::filter(Label == "SR_LN(R0)") |> 
  dplyr::select(dplyr::starts_with("replist")) |> 
  as.numeric()
# choose which to keep
keep <- which(parvec > 9.5 & parvec < 11.5 & parvec != round(mod_out$parameters["SR_LN(R0)", "Value"], 1))
# subset models and add base model
mods2 <- c(list(replist_base = mod_out), mods[keep[order(parvec[keep], decreasing = FALSE)]])
mod_sum2 <- SSsummarize(mods2)
mod_sum2$SpawnOutputLabels <- mod_out$SpawnOutputLabel
parvec2 <- mod_sum2$pars |> 
  dplyr::filter(Label == "SR_LN(R0)") |> 
  dplyr::select(dplyr::starts_with("replist")) |> 
  as.numeric()
legendlabels <- paste0("log(R0) = ", round(parvec2, 2))
legendlabels[1] <- paste0(legendlabels[1], " (base model)")
SSplotComparisons(
  mod_sum2,
  subplots = c(2, 4),
  uncertainty = c(TRUE, rep(FALSE, length(mods2) - 1)),
  legendlabels = legendlabels,
  plotdir = "report/diagnostics",
  legendloc = "left",
  plot = FALSE,
  print = TRUE,
  filenameprefix = "SR_LN(R0)_trajectories_thinned",
  ylimAdj = 1.2 # add white space to make room for legend
)

# M profile
mods <- SSgetoutput("Model_Runs/5.09_no_extra_SE_profile_NatM_uniform_Fem_GP_1", keyvec = 1:25)
mod_sum <- SSsummarize(mods)
# figure out parameter values for each model
parlabel <- "NatM_uniform_Fem_GP_1"
parvec <- mod_sum$pars |> 
  dplyr::filter(Label == parlabel) |> 
  dplyr::select(dplyr::starts_with("replist")) |> 
  as.numeric()
# choose which to keep
keep <- which(
  parvec > 0.12 & 
  parvec < 0.2 & 
  #parvec != round(mod_out$parameters[, "Value"], 2) &
  round(parvec, 3) == round(parvec, 2) # filter to every other sample
)
# subset models and add base model
mods2 <- c(list(replist_base = mod_out), mods[keep[order(parvec[keep], decreasing = FALSE)]])
mod_sum2 <- SSsummarize(mods2)
mod_sum2$SpawnOutputLabels <- mod_out$SpawnOutputLabel
parvec2 <- mod_sum2$pars |> 
  dplyr::filter(Label == parlabel) |> 
  dplyr::select(dplyr::starts_with("replist")) |> 
  as.numeric()
legendlabels <- paste0("M = ", round(parvec2, 3))
legendlabels[1] <- paste0(legendlabels[1], " (base model)")
SSplotComparisons(
  mod_sum2,
  subplots = c(2, 4),
  uncertainty = c(TRUE, rep(FALSE, length(mods2) - 1)),
  legendlabels = legendlabels,
  plotdir = "report/diagnostics",
  legendloc = "left",
  plot = FALSE,
  print = TRUE,
  filenameprefix = "NatM_trajectories_thinned",
  ylimAdj = 1.2 # add white space to make room for legend
)

# h profile
mods <- SSgetoutput("Model_Runs/5.09_no_extra_SE_profile_SR_BH_steep", keyvec = 1:16)
mod_sum <- SSsummarize(mods)
# figure out parameter values for each model
parlabel <- "SR_BH_steep"
parvec <- mod_sum$pars |> 
  dplyr::filter(Label == parlabel) |> 
  dplyr::select(dplyr::starts_with("replist")) |> 
  as.numeric()
# choose which to keep
keep <- which(
  #parvec >= 0.5 & 
  #parvec <= 0.95 &
  #parvec != round(mod_out$parameters[, "Value"], 2) &
  round(parvec, 2) == round(parvec, 1) # filter to every other sample
)
# subset models and add base model
mods2 <- c(list(replist_base = mod_out), mods[keep[order(parvec[keep], decreasing = FALSE)]])
mod_sum2 <- SSsummarize(mods2)
mod_sum2$SpawnOutputLabels <- mod_out$SpawnOutputLabel
parvec2 <- mod_sum2$pars |> 
  dplyr::filter(Label == parlabel) |> 
  dplyr::select(dplyr::starts_with("replist")) |> 
  as.numeric()
legendlabels <- paste0("h = ", round(parvec2, 3))
legendlabels[1] <- paste0(legendlabels[1], " (base model)")
SSplotComparisons(
  mod_sum2,
  subplots = c(2, 4),
  uncertainty = c(TRUE, rep(FALSE, length(mods2) - 1)),
  legendlabels = legendlabels,
  plotdir = "report/diagnostics",
  legendloc = "left",
  plot = FALSE,
  print = TRUE,
  filenameprefix = "SR_BH_steep_trajectories_thinned",
  ylimAdj = 1.2 # add white space to make room for legend
)
