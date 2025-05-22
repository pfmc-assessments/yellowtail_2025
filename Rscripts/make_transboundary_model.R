# Canadian yellowtail rockfish assessment from 2024
# SS3 input files stored at
# https://github.com/pbs-software/pbs-synth/tree/master/PBSsynth/inst/input/2024/YTR/BC/Base/B1.R02v2/02.01
# but need to be run locally to get output


# load base model from elsewhere
can2024 <- SS_output("C:/Users/ian.taylor/Documents/reviews/2024_DFO_yellowtail/models/02.01")
can2024inputs <- SS_read("C:/Users/ian.taylor/Documents/reviews/2024_DFO_yellowtail/models/02.01")
base_inputs <- SS_read("Model_Runs/5.09_no_extra_SE")




# three list of inputs
old <- base_inputs
new <- base_inputs
can_new <- can2024inputs

# increase fleets and vectors
new$dat$Nfleets <- old$dat$Nfleets + can_new$dat$Nfleets
new$dat$fleetnames <- c(old$dat$fleetnames, can_new$dat$fleetnames)
new$dat$fleetinfo <- rbind(old$dat$fleetinfo, can_new$dat$fleetinfo)
new$dat$surveytiming <- c(old$dat$surveytiming, can_new$dat$surveytiming)
new$dat$units_of_catch <- c(old$dat$units_of_catch, can_new$dat$units_of_catch)
new$dat$areas <- c(old$dat$areas, can_new$dat$areas)

# combine catch data
new$dat$catch <- rbind(old$dat$catch, can_new$dat$catch |> dplyr::mutate(fleet = fleet + 7))

# combine indices
new$dat$CPUEinfo <- rbind(old$dat$CPUEinfo, can_new$dat$CPUEinfo)
new$dat$CPUE <- rbind(old$dat$CPUE, can_new$dat$CPUE |> dplyr::mutate(index = index + 7))

# combine length comp info (no length comps in Canadian model, but both models have 7 fleets)
new_len_info <- old$dat$len_info
rownames(new_len_info) <- can_new$dat$fleetnames
new$dat$len_info <- rbind(old$dat$len_info, new_len_info)

# combine age comps
new$dat$age_info <- rbind(old$dat$age_info, can_new$dat$age_info)
# align assumptions for additive constant (0.001 vs 0.0001) and minimum sample size (0.01 vs 0.001)
new$dat$age_info$addtocomp <- old$dat$age_info$addtocomp[1]
new$dat$age_info$minsamplesize <- old$dat$age_info$minsamplesize[1]

# aggregate canadian age comps to use 30+ age bin instead of 45+
# make f30 column equal the sum of the columns f30, f31, ..., f45
cols_f <- paste0("f", 31:45)
can_new$dat$agecomp[, "f30"] <- can_new$dat$agecomp[, "f30"] + rowSums(can2024inputs$dat$agecomp[, cols_f])
cols_m <- paste0("m", 31:45)
can_new$dat$agecomp[, "m30"] <- can_new$dat$agecomp[, "m30"] + rowSums(can2024inputs$dat$agecomp[, cols_m])
# remove columns for ages 31-45
can_new$dat$agecomp <- can_new$dat$agecomp |> dplyr::select(!all_of(c(cols_f, cols_m)))
# combine tables
new$dat$agecomp <- rbind(old$dat$agecomp, can_new$dat$agecomp |> dplyr::mutate(ageerr = 1, fleet = fleet + 7))

# control file changes
# combine selectivity setups
new$ctl$age_selex_types <- rbind(old$ctl$age_selex_types, can_new$ctl$age_selex_types)
new$ctl$size_selex_types <- rbind(old$ctl$size_selex_types, can_new$ctl$size_selex_types)
# move Canadian age selectivity into new control files
new$ctl$age_selex_parms <- can_new$ctl$age_selex_parms

new$ctl$Q_options <- rbind(old$ctl$Q_options, can_new$ctl$Q_options |> dplyr::mutate(fleet = fleet + 7))
new$ctl$Q_parms <- rbind(old$ctl$Q_parms, can_new$ctl$Q_parms)


# write new input files
SS_write(new, dir = "Model_Runs/6.20_transboundary", overwrite = TRUE)
run("Model_Runs/6.20_transboundary")

m6.20 <- SS_output("Model_Runs/6.20_transboundary", SpawnOutputLabel = "Spawning output (trillions of eggs)")

# create a new model with area 1 = US, area 2 = Canada

# change to data file
new_spatial <- new
new_spatial$dat$N_areas <- 2
new_spatial$dat$fleetinfo$area <- c(rep(1, 7), rep(2, 7))

# change to control file
new_spatial$ctl$N_areas <- 2
new_spatial$ctl$recr_dist_method <- 2
new_spatial$ctl$recr_dist_read <- 2
# add new recruitment distribution
new_spatial$ctl$recr_dist_pattern <- data.frame(
  GPattern = 1,
  month = 1,
  area = 1:2,
  age = 0
)
new_spatial$ctl$N_moveDef <- 0

# create a dataframe with two rows and the same columns as new_spatial$ctl$MG_parms
newrows <- data.frame(
  MGparm = c("RecrDist_1", "RecrDist_2"),
  init_value = c(0.5, 0.5),
  min = c(0, 0),
  max = c(1, 1),
  phase = c(1, 1),
  block = c(0, 0)
)
# copy first two rows of new_spatial$ctl$MG_parms to get column names and dimensions
newrows <- new_spatial$ctl$MG_parms[1:4, ]
newrows$LO <- -3
newrows$HI <- 3
newrows$INIT <- 0
newrows$PRIOR <- 0
newrows$PR_SD <- 0
newrows$PR_type <- 0
newrows$PHASE <- c(-1, -1, 1, -1) # only estimate allocation to area 2
rownames(newrows) <- c("RecrDist_GP_1", "RecrDist_1", "RecrDist_2", "RecrDist_month_1")
new_spatial$ctl$MG_parms <- rbind(new$ctl$MG_parms[1:20, ], newrows, new$ctl$MG_parms[21:22, ])

SS_write(new_spatial, dir = "Model_Runs/6.21_transboundary_spatial", overwrite = TRUE)

# add deviations in recruitment allocation
new_spatial2 <- new_spatial
new_spatial2$ctl$MG_parms["RecrDist_2", "dev_minyr"] <- 1962
new_spatial2$ctl$MG_parms["RecrDist_2", "dev_maxyr"] <- 2024
new_spatial2$ctl$MG_parms["RecrDist_2", "dev_PH"] <- 6
new_spatial2$ctl$MG_parms["RecrDist_2", "dev_link"] <- 2

# dev_se and autocorr parameters from 2015 Canary assessment
new_spatial2$ctl$MG_parms_tv <- data.frame(
  LO = c(0.0001, -0.9900),
  HI = c(2.00, 0.99),
  INIT = c(0.5, 0.0),
  PRIOR = c(0.5, 0.0),
  PR_SD = c(0.5, 0.5),
  PR_type = c(6, 6),
  PHASE = c(-5, -6),
  row.names = c("RecrDist_Area_2_dev_se", "RecrDist_Area_2_dev_autocorr")
)

SS_write(new_spatial2, dir = "Model_Runs/6.22_transboundary_spatial_recrdist", overwrite = TRUE)

m6.21 <- SS_output("Model_Runs/6.21_transboundary_spatial", SpawnOutputLabel = "Spawning output (trillions of eggs)")
m6.22 <- SS_output("Model_Runs/6.22_transboundary_spatial_recrdist", SpawnOutputLabel = "Spawning output (trillions of eggs)")

dir.create("figures/US_plus_Canada")
SSplotComparisons(SSsummarize(list(mod_out, m6.21, m6.22)),
  plotdir = "figures/US_plus_Canada",
  legendlabels = c("Base", "U.S. + Canada", "U.S. + Canada + deviations in recruitment allocation"),
  plot = FALSE,
  print = TRUE,
  legendloc = "bottomleft"
)

ts_area1 <- m6.22$timeseries |> filter(Area == 1) |> select(Yr, Bio_all)
ts_area2 <- m6.22$timeseries |> filter(Area == 2) |> select(Yr, Bio_all)
ts_base <- mod_out$timeseries |> select(Yr, Bio_all)
ts_can <- can2024$timeseries |> select(Yr, Bio_all)

ts_all <- rbind(
  ts_base |> mutate(Area = "U.S. (Base model)"),
  ts_can |> mutate(Area = "Canada-only"),
  ts_area1 |> mutate(Area = "U.S. area within joint model"),
  ts_area2 |> mutate(Area = "Canada within joint model")
)

# plot timeseries of ts_all with ggplot2
library(ggplot2)
ggplot(ts_all, aes(x = Yr, y = Bio_all, color = Area)) +
    geom_line(size = 1) +
    labs(
        x = "Year",
        y = "Total Biomass",
        color = "Area"
    ) +
    theme_classic() +
    expand_limits(y = 0)
ggsave("figures/US_plus_Canada/biomass_timeseries.png", width = 6.5, height = 3.5)


dir.create("figures/US_plus_Canada_one_area")
SSplotComparisons(SSsummarize(list(mod_out, m6.20)),
  plotdir = "figures/US_plus_Canada_one_area",
  legendlabels = c("Base", "U.S. + Canada (one area)"),
  plot = FALSE,
  print = TRUE,
  legendloc = "bottomleft"
)
