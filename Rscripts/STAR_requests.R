library(r4ss)
library(here)
library(dplyr)

exe_loc <- here::here("model_runs/ss3.exe")

## STAR request 2: blocks on commercial selectivity
mod <- SS_read("model_runs/5.09_no_extra_SE", ss_new = TRUE)

# add block
mod$ctl$N_Block_Designs <- mod$ctl$N_Block_Designs + 1
mod$ctl$blocks_per_pattern[3] <- 2
mod$ctl$Block_Design[[3]] <- c(2002, 2016, 2017, 2024)

# apply new block 3 to commercial parameters
mod$ctl$size_selex_parms[
  c(
    grep("SizeSel_P_1_Commercial(1)", rownames(mod$ctl$size_selex_parms), fixed = TRUE),
    grep("SizeSel_P_3_Commercial(1)", rownames(mod$ctl$size_selex_parms), fixed = TRUE),
    grep("SizeSel_P_4_Commercial(1)", rownames(mod$ctl$size_selex_parms), fixed = TRUE)
  ),
  "Block"
] <- 3

# fix added after initial response: make width of top narrow
mod$ctl$size_selex_parms[
  grep("SizeSel_P_2_Commercial(1)", rownames(mod$ctl$size_selex_parms), fixed = TRUE), "INIT"
] <- -10

# use block function 2 (replace) for all the parameters
mod$ctl$size_selex_parms[
  c(
    grep("SizeSel_P_1_Commercial(1)", rownames(mod$ctl$size_selex_parms), fixed = TRUE),
    grep("SizeSel_P_3_Commercial(1)", rownames(mod$ctl$size_selex_parms), fixed = TRUE),
    grep("SizeSel_P_4_Commercial(1)", rownames(mod$ctl$size_selex_parms), fixed = TRUE)
  ),
  "Block_Fxn"
] <- 2

# table of new block parameters
new_pars <- rbind(
  mod$ctl$size_selex_parms[grep("SizeSel_P_1_Commercial(1)", rownames(mod$ctl$size_selex_parms), fixed = TRUE), 1:7],
  mod$ctl$size_selex_parms[grep("SizeSel_P_1_Commercial(1)", rownames(mod$ctl$size_selex_parms), fixed = TRUE), 1:7],
  mod$ctl$size_selex_parms[grep("SizeSel_P_3_Commercial(1)", rownames(mod$ctl$size_selex_parms), fixed = TRUE), 1:7],
  mod$ctl$size_selex_parms[grep("SizeSel_P_3_Commercial(1)", rownames(mod$ctl$size_selex_parms), fixed = TRUE), 1:7],
  mod$ctl$size_selex_parms[grep("SizeSel_P_4_Commercial(1)", rownames(mod$ctl$size_selex_parms), fixed = TRUE), 1:7],
  mod$ctl$size_selex_parms[grep("SizeSel_P_4_Commercial(1)", rownames(mod$ctl$size_selex_parms), fixed = TRUE), 1:7]
)
# turn on dome selectivity for middle block and change initial value to not be 70
new_pars[5, "PHASE"] <- 6
new_pars[5, "INIT"] <- 3

# add new parameters to the old ones (they go first because it is fleet 1)
mod$ctl$size_selex_parms_tv <- rbind(
  new_pars,
  mod$ctl$size_selex_parms_tv
)

# write new model input files
SS_write(mod, "model_runs/6.08_STAR_request2_blocks", overwrite = TRUE)
# run without estimation to see control.ss_new comments to confirm blocks are in the right place
run(
  dir = "model_runs/6.08_STAR_request2_blocks",
  extras = "-nohess -stopph 0",
  skipfinished = FALSE
)

m6.08 <- SS_output("model_runs/6.08_STAR_request2_blocks", SpawnOutputLabel = mod_out$SpawnOutputLabel)

# copy directory including output files to do tuning
# did that manually because I don't know how to do it in R
tune_comps(
  niters_tuning = 2, dir = "model_runs/6.09_STAR_request2_blocks_tuned",
  exe = exe_loc, extras = "-nohess"
)

m6.09 <- SS_output("model_runs/6.09_STAR_request2_blocks_tuned", SpawnOutputLabel = mod_out$SpawnOutputLabel)

dir.create("figures/STAR_request2_blocks")
SSplotComparisons(
  SSsummarize(list(mod_out, m6.09)),
  plotdir = "figures/STAR_request2_blocks",
  legendlabels = c("base model", "Request 2 selectivity blocks"),
  print = TRUE,
  filenameprefix = "STAR_request2_blocks"
)

SS_plots(m6.09)

# make custom selectivity plot
source("Rscripts/plot_selex.R")
plot_yellowtail_tv_selex(m6.09, file = "figures/STAR_request2_blocks_selectivity.png")


### STAR request 6: revised blocks
# modified version of the above code to change block year
mod <- SS_read("model_runs/6.09_STAR_request2_blocks_tuned", ss_new = TRUE)
mod$ctl$Block_Design[[3]] <- c(2001, 2010, 2011, 2024)
SS_write(mod, "model_runs/6.10_STAR_request6_blocks_v2", overwrite = TRUE)

m6.10 <- SS_output("model_runs/6.10_STAR_request6_blocks_v2", SpawnOutputLabel = mod_out$SpawnOutputLabel)
SS_plots(m6.10)
source("Rscripts/plot_selex.R")
plot_yellowtail_tv_selex(m6.10, file = "figures/STAR_request6_blocks_selectivity_v2.png")

# copy directory including output files to do tuning
from_dir <- "model_runs/6.10_STAR_request6_blocks_v2"
to_dir <- "model_runs/6.11_STAR_request6_blocks_v2_tuned"
dir.create(to_dir, showWarnings = FALSE)
file.copy(
  from = list.files(from_dir, full.names = TRUE),
  to = to_dir,
  overwrite = TRUE,
  recursive = TRUE
)
tune_comps(
  niters_tuning = 2, dir = to_dir,
  exe = exe_loc, extras = "-nohess"
)
m6.11 <- SS_output("model_runs/6.11_STAR_request6_blocks_v2_tuned", SpawnOutputLabel = mod_out$SpawnOutputLabel)
SS_plots(m6.11)

dir.create("figures/STAR_request6_blocks")
SSplotComparisons(
  SSsummarize(list(mod_out, m6.02, m6.11)),
  plotdir = "figures/STAR_request6_blocks",
  legendlabels = c("base model", "Request 2 selectivity blocks", "Request 6 selectivity blocks"),
  print = TRUE,
  filenameprefix = "STAR_request6_blocks"
)

png(
  "figures/STAR_request2_blocks_selectivity.png",
  width = 6.5, height = 5, units = "in", res = 300
)
par(oma = c(2, 2, 1, 1), las = 1)
plot_sel_ret(m6.11, Factor = "Lsel", fleet = 1, sex = 1)
mtext("Selectivity", side = 2, outer = TRUE, line = 0.5, las = 0)
mtext("Length (cm)", side = 1, outer = TRUE)
dev.off()


### STAR request 7: downweight comps
mod_inputs <- SS_read("model_runs/5.09_no_extra_SE", ss_new = TRUE)
request7_inputs <- mod_inputs
# downweight comps
request7_inputs$ctl$Variance_adjustment_list <- request7_inputs$ctl$Variance_adjustment_list |>
  dplyr::mutate(
    # downweight all comps by 0.5
    value = value * 0.1
  )
SS_write(request7_inputs, "model_runs/6.07_STAR_request7_downweight_comps", overwrite = TRUE)
m6.07 <- SS_output("model_runs/6.07_STAR_request7_downweight_comps", SpawnOutputLabel = mod_out$SpawnOutputLabel)

upweight <- SS_output("Model_Runs/sensitivities/upweight_wcgbts/", SpawnOutputLabel = mod_out$SpawnOutputLabel)

dir.create("figures/STAR_request7_downweight_comps")
SSplotComparisons(SSsummarize(list(mod_out, m6.07, upweight)),
  legendlabels = c("Base", "Downweight comps", "Upweight WCGBTS"),
  plotdir = "figures/STAR_request7_downweight_comps",
  print = TRUE
)

z <- r4ss:::table_compweight(m6.07)
source("Rscripts/table_sens.R")

SStableComparisons(SSsummarize(list(mod_out, m6.09, m6.11, m6.07)),
  modelnames = c("Base", "Request 2 blocks", "Request 6 blocks", "Downweight comps"),
  names = c(
    "Recr_Virgin", "R0", "NatM", "L_at_Amax", "VonBert_K", "SmryBio_unfished", "SSB_Virg",
    "SSB_2025", "Bratio_2025", "SPRratio_2024", "LnQ_base_WCGBTS"
  ),
  likenames = c(
    "TOTAL", "Survey", "Length_comp", "Age_comp",
    "Discard", "Mean_body_wt", "Recruitment", "priors"
  )
) |>
  table_sens(format = "html")


### STAR request 12:  Rerun the model using the fishery-independent index combinations below

mod_inputs <- SS_read("model_runs/5.09_no_extra_SE", ss_new = TRUE)
mod <- mod_inputs

# Add 4 new rows to the lambdas table
new_lambdas <- data.frame(
  like_comp = 1,
  fleet = 4:7,
  phase = 1,
  value = 0,
  sizefreq_method = 0
)
rownames(new_lambdas) <- c(
  "HnL", "Triennial", "WCGBTS", "SMURF"
)
mod$ctl$lambdas <- rbind(mod$ctl$lambdas, new_lambdas)
mod$ctl$N_lambdas <- 5
mod$ctl$lambdas
#                            like_comp fleet phase value sizefreq_method
# F-ballpark_Commercial_Phz5        17     1     5     0               0
# HnL                                1     4     1     0               0
# Triennial                          1     5     1     0               0
# WCGBTS                             1     6     1     0               0
# SMURF                              1     7     1     0               0

newmod <- mod
newmod$ctl$lambdas[c("WCGBTS", "HnL", "SMURF"), "value"] <- 1
SS_write(newmod, "model_runs/6.12_request12_WCGBTS_HnL_SMURF", overwrite = TRUE)

newmod <- mod
newmod$ctl$lambdas[c("Triennial", "HnL", "SMURF"), "value"] <- 1
SS_write(newmod, "model_runs/6.13_request12_Triennial_HnL_SMURF", overwrite = TRUE)

newmod <- mod
newmod$ctl$lambdas[c("Triennial", "WCGBTS", "SMURF"), "value"] <- 1
SS_write(newmod, "model_runs/6.14_request12_Triennial_WCGBTS_SMURF", overwrite = TRUE)

newmod <- mod
newmod$ctl$lambdas[c("Triennial", "HnL", "WCGBTS"), "value"] <- 1
SS_write(newmod, "model_runs/6.15_request12_Triennial_HnL_WCGBTS", overwrite = TRUE)

newmod <- mod
newmod$ctl$lambdas["Triennial", "value"] <- 1
SS_write(newmod, "model_runs/6.16_request12_Triennial", overwrite = TRUE)

newmod <- mod
newmod$ctl$lambdas["WCGBTS", "value"] <- 1
SS_write(newmod, "model_runs/6.17_request12_WCGBTS", overwrite = TRUE)

newmod <- mod
newmod$ctl$lambdas["HnL", "value"] <- 1
SS_write(newmod, "model_runs/6.18_request12_HnL", overwrite = TRUE)

m6.12 <- SS_output("model_runs/6.12_request12_WCGBTS_HnL_SMURF", printstats = FALSE, verbose = FALSE, SpawnOutputLabel = mod_out$SpawnOutputLabel)
m6.13 <- SS_output("model_runs/6.13_request12_Triennial_HnL_SMURF", printstats = FALSE, verbose = FALSE, SpawnOutputLabel = mod_out$SpawnOutputLabel)
m6.14 <- SS_output("model_runs/6.14_request12_Triennial_WCGBTS_SMURF", printstats = FALSE, verbose = FALSE, SpawnOutputLabel = mod_out$SpawnOutputLabel)
m6.15 <- SS_output("model_runs/6.15_request12_Triennial_HnL_WCGBTS", printstats = FALSE, verbose = FALSE, SpawnOutputLabel = mod_out$SpawnOutputLabel)
m6.16 <- SS_output("model_runs/6.16_request12_Triennial", printstats = FALSE, verbose = FALSE, SpawnOutputLabel = mod_out$SpawnOutputLabel)
m6.17 <- SS_output("model_runs/6.17_request12_WCGBTS", printstats = FALSE, verbose = FALSE, SpawnOutputLabel = mod_out$SpawnOutputLabel)
m6.18 <- SS_output("model_runs/6.18_request12_HnL", printstats = FALSE, verbose = FALSE, SpawnOutputLabel = mod_out$SpawnOutputLabel)
no_indices <- SS_output("model_runs/sensitivities/no_indices_hess", printstats = FALSE, verbose = FALSE, SpawnOutputLabel = mod_out$SpawnOutputLabel)

biglist12 <- list(mod_out, m6.12, m6.13, m6.14, m6.15, m6.16, m6.17, m6.18, no_indices)
modelnames12 <- c(
  "Base (Triennial + WCGBTS + HnL + SMURF)",
  "1. WCGBTS + HnL + SMURF",
  "2. Triennial + HnL + SMURF",
  "3. Triennial + WCGBTS + SMURF",
  "4. Triennial + HnL + WCGBTS",
  "5. Triennial",
  "6. WCGBTS",
  "7. HnL",
  "No indices"
)
dir.create("figures/STAR_request12")
SSplotComparisons(
  SSsummarize(biglist12),
  plotdir = "figures/STAR_request12",
  legendlabels = modelnames12,
  print = TRUE,
  plot = FALSE,
  legendloc = "bottomleft",
  filenameprefix = "STAR_request12"
)

source("Rscripts/table_sens.R")
SStableComparisons(SSsummarize(biglist12),
  modelnames = modelnames12,
  names = c(
    "Recr_Virgin", "R0", "NatM", "L_at_Amax", "VonBert_K", "SmryBio_unfished", "SSB_Virg",
    "SSB_2025", "Bratio_2025", "SPRratio_2024", "LnQ_base_WCGBTS"
  ),
  likenames = c(
    "TOTAL", "Survey", "Length_comp", "Age_comp",
    "Discard", "Mean_body_wt", "Recruitment", "priors"
  )
) |>
  table_sens(format = "html")

# additional plot for discussion of request 12 (time series of spawning output starting in 2003 when the WCGBTS begins)
# this helps show that the changes over time are not as dramatic as when the full model time series is shown
SSplotTimeseries(mod_out, subplot = 1, minyr = 2003)

### STAR request 13:  Explore states of nature

# distribution from M prior
M_est <- mod_out$parameters[1, "Value"]
M_PR_SD <- mod_out$parameters[1, "Pr_SD"]
M_est
# [1] 0.156713
M_PR_SD
# [1] 0.31
qlnorm(p = c(0.125, 0.875), meanlog = log(M_est), sdlog = M_PR_SD)
# [1] 0.1097064 0.2238608

# distribution of OFL values
qlnorm(p = c(0.125, 0.875), meanlog = log(mod_out$derived_quants["OFLCatch_2025", "Value"]), sdlog = mod_out$OFL_sigma)
# [1] 4391.647 6738.685
qlnorm(p = c(0.125, 0.875), meanlog = log(mod_out$derived_quants["OFLCatch_2025", "Value"]), sdlog = mod_out$OFL_sigma) |> round()
# [1] 4392 6739

# search M and R0 profiles for models that had similar OFL values to low and high
# search was done in Rscripts/run_diagnostics.R

M_mods <- SSgetoutput("Model_Runs/5.09_no_extra_SE_profile_NatM_uniform_Fem_GP_1/", keyvec = c(4, 17), SpawnOutputLabel = "Spawning output (trillions of eggs)")
R0_mods <- SSgetoutput("Model_Runs/5.09_no_extra_SE_profile_SR_LN(R0)/", keyvec = c(2, 9), SpawnOutputLabel = "Spawning output (trillions of eggs)")
downweight_comps <- SS_output("model_runs/6.07_STAR_request7_downweight_comps", SpawnOutputLabel = "Spawning output (trillions of eggs)")
upweight_comps <- SS_output("model_runs/sensitivities/M_I_weighting", SpawnOutputLabel = "Spawning output (trillions of eggs)")

biglist <- list(
  base = mod_out,
  M_low = M_mods[[1]],
  M_high = M_mods[[2]],
  R0_low = R0_mods[[1]],
  R0_high = R0_mods[[2]],
  downweight_comps = downweight_comps,
  upweight_comps = upweight_comps
)
modelnames <- c(
  "Base",
  "M low",
  "M high",
  "R0 low",
  "R0 high",
  "Downweight comps",
  "Upweight comps"
)
dir.create("figures/STAR_request13")
SSplotComparisons(
  SSsummarize(biglist),
  plotdir = "figures/STAR_request13",
  legendlabels = modelnames,
  print = TRUE,
  plot = FALSE,
  filenameprefix = "STAR_request13"
)

source("Rscripts/table_sens.R")
SStableComparisons(SSsummarize(biglist),
  modelnames = modelnames,
  names = c(
    "Recr_Virgin", "R0", "NatM", "L_at_Amax", "VonBert_K", "SmryBio_unfished", "SSB_Virg",
    "SSB_2025", "Bratio_2025", "SPRratio_2024", "LnQ_base_WCGBTS", "OFLCatch_2025"
  ),
  likenames = c(
    "TOTAL", "Survey", "Length_comp", "Age_comp",
    "Discard", "Mean_body_wt", "Recruitment", "priors"
  )
) |>
  table_sens(format = "html")

# harvest control rule catch
hcr_catch <- SS_ForeCatch(
  replist = mod_out,
  yrs = 2025:2036
) |>
  dplyr::rename(
    year = "#Year",
    seas = "Seas",
    fleet = "Fleet",
    catch_or_F = "dead(B)",
  )

avg_attain_catch <- hcr_catch |>
  mutate(catch_or_F = ifelse(year %in% 2025:2026, catch_or_F, 0.55*catch_or_F))

# # recent 5-year average catch
# avg_catch <-
#   SS_ForeCatch(
#     replist = mod_out,
#     yrs = 2027:2036,
#     average = TRUE,
#     avg.yrs = 2020:2024
#   ) |>
#   dplyr::rename(
#     year = "#Year",
#     seas = "Seas",
#     fleet = "Fleet",
#     catch_or_F = "dead(B)",
#   )

# apply forecast catch to downweight comps
inputs_low <- SS_read("model_runs/6.07_STAR_request7_downweight_comps")
inputs_low$fore$ForeCatch <- hcr_catch
SS_write(inputs_low, dir = "model_runs/6.24_STAR_request7_downweight_comps_forecast", overwrite = TRUE)
m6.24 <- SS_output("model_runs/6.24_STAR_request7_downweight_comps_forecast", SpawnOutputLabel = "Spawning output (trillions of eggs)")

# apply forecast catch to upweight comps
inputs_high <- SS_read("model_runs/sensitivities/M_I_weighting")
inputs_high$fore$ForeCatch <- hcr_catch
SS_write(inputs_high, dir = "model_runs/6.25_M_I_weighting_forecast", overwrite = TRUE)
m6.25 <- SS_output("model_runs/6.25_M_I_weighting_forecast", SpawnOutputLabel = "Spawning output (trillions of eggs)")

# apply forecast catch to low and high R0
inputs_low_R0 <- mod_inputs
inputs_high_R0 <- mod_inputs
inputs_low_R0$ctl$SR_parms["SR_LN(R0)", "INIT"] <- 10.25
inputs_high_R0$ctl$SR_parms["SR_LN(R0)", "INIT"] <- 10.75
inputs_low_R0$ctl$SR_parms["SR_LN(R0)", "PHASE"] <- -1
inputs_high_R0$ctl$SR_parms["SR_LN(R0)", "PHASE"] <- -1
inputs_low_R0$fore$ForeCatch <- hcr_catch
inputs_high_R0$fore$ForeCatch <- hcr_catch
SS_write(inputs_low_R0, dir = "model_runs/6.26_lowR0_forecast", overwrite = TRUE)
SS_write(inputs_high_R0, dir = "model_runs/6.27_highR0_forecast", overwrite = TRUE)
run("model_runs/6.26_lowR0_forecast", extras = "-nohess", skipfinished = FALSE)
run("model_runs/6.27_highR0_forecast", extras = "-nohess", skipfinished = FALSE)
m6.26 <- SS_output("model_runs/6.26_lowR0_forecast", SpawnOutputLabel = "Spawning output (trillions of eggs)")
m6.27 <- SS_output("model_runs/6.27_highR0_forecast", SpawnOutputLabel = "Spawning output (trillions of eggs)")

dir.create("figures/STAR_request13_forecast")
SSplotComparisons(
  SSsummarize(list(mod_out, m6.24, m6.25, m6.26, m6.27)),
  plotdir = "figures/STAR_request13_forecast",
  legendlabels = c("Base", "Downweight comps", "Upweight comps", "Low R0", "High R0"),
  print = TRUE,
  plot = FALSE,
  endyrvec = 2036,
  filenameprefix = "STAR_request13_forecast"
)

# apply average recent attainment of forecast HCR catch to low R0, high R0, and base model
inputs_low_R0 <- mod_inputs
inputs_high_R0 <- mod_inputs
mod <- mod_inputs
inputs_low_R0$ctl$SR_parms["SR_LN(R0)", "INIT"] <- 10.25
inputs_high_R0$ctl$SR_parms["SR_LN(R0)", "INIT"] <- 10.75
inputs_low_R0$ctl$SR_parms["SR_LN(R0)", "PHASE"] <- -1
inputs_high_R0$ctl$SR_parms["SR_LN(R0)", "PHASE"] <- -1
inputs_low_R0$fore$ForeCatch <- avg_attain_catch
inputs_high_R0$fore$ForeCatch <- avg_attain_catch
mod$fore$ForeCatch <- avg_attain_catch

SS_write(inputs_low_R0, dir = "model_runs/6.28_lowR0_forecast_avg_attain", overwrite = TRUE)
SS_write(inputs_high_R0, dir = "model_runs/6.29_highR0_forecast_avg_attain", overwrite = TRUE)
SS_write(mod, dir = "model_runs/6.30_base_forecast_avg_attain", overwrite = TRUE)
run("model_runs/6.28_lowR0_forecast_avg_attain", extras = "-nohess", skipfinished = FALSE)
run("model_runs/6.29_highR0_forecast_avg_attain", extras = "-nohess", skipfinished = FALSE)
run("model_runs/6.30_base_forecast_avg_attain", extras = "-nohess", skipfinished = FALSE)
m6.28 <- SS_output("model_runs/6.28_lowR0_forecast_avg_attain", SpawnOutputLabel = "Spawning output (trillions of eggs)")
m6.29 <- SS_output("model_runs/6.29_highR0_forecast_avg_attain", SpawnOutputLabel = "Spawning output (trillions of eggs)")
m6.30 <- SS_output("model_runs/6.30_base_forecast_avg_attain", SpawnOutputLabel = "Spawning output (trillions of eggs)")

list(m6.28, m6.29, m6.30) |>
  SSsummarize() |>
  SSplotComparisons(subplots = c(1,3,5,18), new = FALSE, endyrvec = 2036,
                    legendlabels = c('low R0', 'high R0', 'base'), 
                    plotdir = 'figures/STAR_request15', png = TRUE)


dir.create("figures/states_of_nature")
SSplotComparisons(
  SSsummarize(list(mod_out, m6.26, m6.27)),
  plotdir = "figures/states_of_nature",
  legendlabels = c("Base (logR0 = 10.51)", "Low (logR0 = 10.25)", "High (logR0 = 10.75)"),
  print = TRUE,
  plot = FALSE,
  endyrvec = 2036,
  filenameprefix = "states_of_nature_"
)

SSplotTimeseries(mod_out, subplot = 1, minyr = 2003)

# sample sizes for STAR report
commages <-read.csv("report/Tables/pacfin_ages.csv") 
commlengths <- read.csv("report/Tables/pacfin_lengths.csv")
tri_bio_table <- read.csv("Data/Processed/input_n_tri.csv", check.names = FALSE)
wcgbts_bio_table <- read.csv("Data/Processed/input_n_wcgbts.csv", check.names = FALSE)
ashop_comp <- read.csv("report/Tables/ashop_comps.csv") 
rec_bio_table <- read.csv("Data/Processed/rec_bio_sample_size_table.csv", check.names = FALSE)

n_lengths <- c(
  commlengths[, grepl("n_fish$", names(commlengths))] |> sum(),
  tri_bio_table$n_lengths |> sum(),
  wcgbts_bio_table$n_lengths |> sum(),
  ashop_comp$nfish.length |> sum(),
  rec_bio_table |> dplyr::select(-Year, -`Washington ages`) |> sum()
)

n_ages <- c(
  commages[, grepl("n_fish$", names(commages))] |> sum(),
  tri_bio_table$n_ages |> sum(),
  wcgbts_bio_table$n_ages |> sum(),
  ashop_comp$nfish.age |> sum(),
  rec_bio_table |> dplyr::select(`Washington ages`) |> sum()
)

n_lengths |> sum()
n_ages |> sum()


### exploring female M distributions vs prior for states of nature
### inspired by email from Adam Langley

# re-ran states of nature in "_hess" directories to get uncertainty
ybase <- SS_output('Model_Runs/5.09_no_extra_SE')
ylo <- SS_output('Model_Runs/6.26_lowR0_forecast_hess')
yhi <- SS_output('Model_Runs/6.27_highR0_forecast_hess')
# colors from r4ss::SSplotPars()
colvec <- c("blue", "red", "black", "gray60", rgb(0, 0, 0, 0.5))
# make plot
png("figures/M_distributions_states_of_nature.png", width = 6.5, height = 5, units = "in", res = 300)
colvec[1] <- "red"
SSplotPars(ylo, strings = "NatM_uniform_Fem", nrows = 1, ncols = 1, colvec = colvec, 
  showlegend = FALSE, showinit = FALSE)
colvec[1] <- "blue"
SSplotPars(ybase, strings = "NatM_uniform_Fem", nrows = 1, ncols = 1, colvec = colvec, add = TRUE, 
  showlegend = FALSE, showinit = FALSE)
colvec[1] <- "green3"
SSplotPars(yhi, strings = "NatM_uniform_Fem", nrows = 1, ncols = 1, colvec = colvec, add = TRUE, 
  showlegend = FALSE, showinit = FALSE)
legend('topleft', 
  legend = c("Prior", "Base", "Low R0", "High R0"), 
  col = c("black", "blue", "red", "green3"), lty = 1, lwd = c(2, 1, 1, 1), bty = "n")
dev.off()
