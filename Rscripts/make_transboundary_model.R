# Canadian yellowtail rockfish assessment from 2024
# SS3 input files stored at 
# https://github.com/pbs-software/pbs-synth/tree/master/PBSsynth/inst/input/2024/YTR/BC/Base/B1.R02v2/02.01
# but need to be run locally to get output


# load base model from elsewhere 
can2024inputs <- SS_read('C:/Users/ian.taylor/Documents/reviews/2024_DFO_yellowtail/models/02.01')
base_inputs <- SS_read('Model_Runs/5.09_no_extra_SE')




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
