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
