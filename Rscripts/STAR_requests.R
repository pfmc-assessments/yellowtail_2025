library(r4ss)
library(here)
library(dplyr)

exe_loc <- here::here("model_runs/ss3.exe")
source("Rscripts/bins.R")
source("Rscripts/model_rename_fleets.R")
source("Rscripts/model_remove_retention.R")


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
SS_write(mod, "model_runs/6.01_STAR_request2_blocks", overwrite = TRUE)
# run without estimation to see control.ss_new comments to confirm blocks are in the right place
run(
  dir = "model_runs/6.01_STAR_request2_blocks",
  extras = "-nohess -stopph 0",
  skipfinished = FALSE
)

# # modified version of the above code to change block year
# mod <- SS_read("model_runs/6.01_STAR_request2_blocks")

# # change middle block to start in 2001 instead of 2002 
# mod$ctl$Block_Design[[3]] <- c(2001, 2016, 2017, 2024)
# SS_write(mod, "model_runs/6.02_STAR_request2_blocks_v2", overwrite = TRUE)

m6.01 <- SS_output("model_runs/6.01_STAR_request2_blocks", SpawnOutputLabel = mod_out$SpawnOutputLabel)

SSplotComparisons(
  SSsummarize(list(mod_out, m6.01)),
  plotdir = "figures",
  legendlabels = c("base model", "Request 2 selectivity blocks"),
  plot = TRUE,
  filenameprefix = "STAR_request2_blocks"
)
SS_plots(m6.01)

# copy directory including output files to do tuning
# did that manually because I don't know how to do it in R
tune_comps(niters_tuning = 2, dir = 'model_runs/6.02_STAR_request2_blocks_tuned',
           exe = exe_loc, extras = '-nohess')


m6.02 <- SS_output("model_runs/6.02_STAR_request2_blocks_tuned", SpawnOutputLabel = mod_out$SpawnOutputLabel)

dir.create("figures/STAR_request2_blocks")
SSplotComparisons(
  SSsummarize(list(mod_out, m6.02)),
  plotdir = "figures/STAR_request2_blocks",
  legendlabels = c("base model", "Request 2 selectivity blocks"),
  print = TRUE,
  filenameprefix = "STAR_request2_blocks"
)

SS_plots(m6.02)

# make custom selectivity plot
source("Rscripts/plot_selex.R")
plot_yellowtail_tv_selex(m6.02, file = "figures/STAR_request2_blocks_selectivity.png")


source("Rscripts/table_sens.R")
table_sens()