model_directory <- 'model_runs'
base_model_name <- '4.12_age_and_M'
here('model_runs/ss3.exe')
base_model <- SS_read(file.path(model_directory, base_model_name))
base_out <- SS_output(file.path(model_directory, base_model_name))

# M-I weighting -----------------------------------------------------------

copy_SS_inputs(dir.old = file.path(model_directory, base_model_name), 
               dir.new = file.path(model_directory, 'sensitivities', 'M_I_weighting'))
file.copy(from = file.path(model_directory, base_model_name,
                           c('Report.sso', 'CompReport.sso', 'warning.sso')), 
          to = file.path(model_directory, 'sensitivities', 'M_I_weighting', 
                         c('Report.sso', 'CompReport.sso', 'warning.sso')), 
          overwrite = TRUE)
tune_comps(option = 'MI', niters_tuning = 3, 
           dir = file.path(model_directory, 'sensitivities', 'M_I_weighting'),
           exe = exe_loc, extras = '-nohess')


# D-M weighting -----------------------------------------------------------

copy_SS_inputs(dir.old = file.path(model_directory, base_model_name), 
               dir.new = file.path(model_directory, 'sensitivities', 'dirichlet_multinomial'))
file.copy(from = file.path(model_directory, base_model_name,
                           c('Report.sso', 'CompReport.sso', 'warning.sso')), 
          to = file.path(model_directory, 'sensitivities', 'dirichlet_multinomial', 
                         c('Report.sso', 'CompReport.sso', 'warning.sso')), 
          overwrite = TRUE)
tune_comps(option = 'DM', 
           dir = file.path(model_directory, 'sensitivities', 'dirichlet_multinomial'),
           exe = exe_loc, extras = '-nohess', niters_tuning = 1)

# SMURFS ------------------------------------------------------------------

sensi_mod <- base_model
smurf <- read.csv('Data/raw_not_confidential/SMURF index/index_forSS.csv') |>
  mutate(index = 4) |>
  rename(se_log = logse) |>
  select(-fleet)

sensi_mod$dat$fleetnames[4] <- 'SMURF'
sensi_mod$dat$fleetinfo[sensi_mod$dat$fleetinfo$fleetname == 'PLACEHOLDER',] <- c(3, 1, 1, 2, 0, 'SMURF')
rownames(sensi_mod$dat$CPUEinfo) <- sensi_mod$dat$fleetnames
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

# out <- SSgetoutput(dirvec = c(file.path(model_directory, base_model_name),
#                               file.path(model_directory, 'sensitivities', 'SMURF')))
# SSsummarize(out) |>
#   SSplotComparisons(subplots = c(1,3), endyrvec = 2037, new = FALSE)


# ORBS --------------------------------------------------------------------

sensi_mod <- base_model

orbs <- read.csv('Data/raw_not_confidential/ORBS index/index_forSS.csv') |>
  mutate(index = 3) |>
  rename(se_log = logse) |>
  select(-fleet)

sensi_mod$dat$CPUEinfo['Recreational','units'] <- 0 # numbers

sensi_mod$dat$CPUE <- bind_rows(sensi_mod$dat$CPUE,
                                orbs)

sensi_mod$ctl$Q_options <- rbind(sensi_mod$ctl$Q_options,
                                 Recreational = c(3,1,0,1,0,0)) |>
  slice(3,1,2) # reorder
sensi_mod$ctl$Q_parms <- bind_rows(sensi_mod$ctl$Q_parms[1:2,], # copy triennial Q setup for SMURF
                                   sensi_mod$ctl$Q_parms)
rownames(sensi_mod$ctl$Q_parms) <- rownames(sensi_mod$ctl$Q_parms) |>
  stringr::str_replace('Triennial\\(5\\)\\.\\.\\.[1|2]', 'Recreational(3)') |> # fix row names
  stringr::str_remove('\\.\\.\\.[:digit:]')

# try no extra SE

SS_write(sensi_mod, file.path(model_directory, 'sensitivities', 'ORBS'))
# 
# out <- SSgetoutput(dirvec = c(file.path(model_directory, base_model_name),
#                               file.path(model_directory, 'sensitivities', 'ORBS')))
# SSsummarize(out) |>
#   SSplotComparisons(subplots = c(1,3), endyrvec = 2037, new = FALSE)
# SSplotIndices(out[[2]])
# 

# Oceanographic index -----------------------------------------------------

sensi_mod <- base_model

ocean <- read.csv('Data/raw_not_confidential/OceanographicIndex/OceanographicIndexV1.csv') |>
  mutate(month = 7, index = 4
         # index = ifelse(year >= 2015, 4, -4) # include 10 years of index
  ) |>
  select(year, month, index, obs = fit, se_log = se.p)

sensi_mod$dat$fleetnames[4] <- 'ocean'
sensi_mod$dat$fleetinfo[sensi_mod$dat$fleetinfo$fleetname == 'PLACEHOLDER',] <- c(3, 1, 1, 2, 0, 'ocean')
rownames(sensi_mod$dat$CPUEinfo) <- sensi_mod$dat$fleetnames
sensi_mod$dat$CPUEinfo['ocean', c('units', 'errtype')] <- c(36, -1) # recdev, normal error distribution

sensi_mod$dat$CPUE <- bind_rows(sensi_mod$dat$CPUE,
                                ocean)

sensi_mod$ctl$Q_options <- rbind(sensi_mod$ctl$Q_options,
                                 ocean = c(4,1,0,1,0,0)) |>
  slice(3,1,2) # reorder
sensi_mod$ctl$Q_parms <- bind_rows(sensi_mod$ctl$Q_parms[1:2,], # copy triennial Q setup for oceanographic index
                                   sensi_mod$ctl$Q_parms)
rownames(sensi_mod$ctl$Q_parms) <- rownames(sensi_mod$ctl$Q_parms) |>
  stringr::str_replace('Triennial\\(5\\)\\.\\.\\.[1|2]', 'ocean(4)') |> # fix row names
  stringr::str_remove('\\.\\.\\.[:digit:]')

SS_write(sensi_mod, file.path(model_directory, 'sensitivities', 'oceanographic_index_long'), overwrite = TRUE)
# 
# out <- SSgetoutput(dirvec = c(file.path(model_directory, base_model_name),
#                               file.path(model_directory, 'sensitivities', 'oceanographic_index')))


# hook and line survey ----------------------------------------------------

sensi_mod <- base_model

# index and catchability
hl_ind <- read.csv('Data/raw_not_confidential/Combined HL Index/index_forSS.csv') |>
  mutate(fleet = 4) |>
  select(year, month, index = fleet, obs, se_log = logse)

sensi_mod$dat$fleetnames[4] <- 'H&L'
sensi_mod$dat$fleetinfo[sensi_mod$dat$fleetinfo$fleetname == 'PLACEHOLDER',] <- c(3, 1, 1, 2, 0, 'H&L')
rownames(sensi_mod$dat$CPUEinfo) <- sensi_mod$dat$fleetnames
sensi_mod$dat$CPUEinfo['H&L', 'units'] <- 0 # numbers of fish

sensi_mod$dat$CPUE <- bind_rows(sensi_mod$dat$CPUE,
                                hl_ind)

sensi_mod$ctl$Q_options <- rbind(sensi_mod$ctl$Q_options,
                                 `H&L` = c(4,1,0,1,0,0)) |>
  slice(3,1,2) # reorder
sensi_mod$ctl$Q_parms <- bind_rows(sensi_mod$ctl$Q_parms[1:2,], # copy triennial Q setup for oceanographic index
                                   sensi_mod$ctl$Q_parms)
rownames(sensi_mod$ctl$Q_parms) <- rownames(sensi_mod$ctl$Q_parms) |>
  stringr::str_replace('Triennial\\(5\\)\\.\\.\\.[1|2]', 'H&L(4)') |> # fix row names
  stringr::str_remove('\\.\\.\\.[:digit:]')

# length comps
rownames(sensi_mod$dat$len_info) <- sensi_mod$dat$fleetnames
hl_len <- read.csv('Data/raw_not_confidential/Combined HL Index/length_cm_unsexed_raw_20_56_yellowtail rockfish_combinedhl.csv') |>
  mutate(month = 7, fleet = 4) |>
  rename(Nsamp = input_n, part = partition) |>
  rename_with(~stringr::str_replace(., pattern = 'u', replacement = 'f'), .cols = u20:u56) |>
  mutate(across(.cols = f20:f56, .fns = ~0, .names = 'm{.col}')) |>
  rename_with(~stringr::str_remove(., pattern = 'f'), mf20:mf56)
sensi_mod$dat$lencomp <- bind_rows(sensi_mod$dat$lencomp, hl_len)

# selectivity
rownames(sensi_mod$ctl$size_selex_types) <- sensi_mod$dat$fleetnames
sensi_mod$ctl$size_selex_types['H&L', c('Pattern', 'Male')] <- c(24, 3)

new_selex <- sensi_mod$ctl$size_selex_parms[grepl('Recreational', rownames(sensi_mod$ctl$size_selex_parms)),]
rownames(new_selex) <- stringr::str_replace(rownames(new_selex), 'Recreational\\(3\\)', 'H&L\\(4\\)')
new_selex$Block <- new_selex$Block_Fxn <- 0

last_rec_ind <- max(grep('Recreational', rownames(sensi_mod$ctl$size_selex_parms)))
sensi_mod$ctl$size_selex_parms <- bind_rows(sensi_mod$ctl$size_selex_parms[1:last_rec_ind,],
                                            new_selex,
                                            sensi_mod$ctl$size_selex_parms[(last_rec_ind + 1):nrow(sensi_mod$ctl$size_selex_parms),])

SS_write(sensi_mod, file.path(model_directory, 'sensitivities', 'hook_and_line'), overwrite = TRUE)

tune_comps(dir = file.path(model_directory, 'sensitivities', 'hook_and_line'), niters_tuning = 0)
# miraculously, it is not bad.
# 
# out <- SS_output(file.path(model_directory, 'sensitivities', 'hook_and_line'))
# SS_plots(out)

# surveys_only <- SS_read(file.path(model_directory, 'sensitivities', 'hook_and_line'), 
#                         ss_new = TRUE)
# 
# surveys_only$ctl$MG_parms$PHASE <- -99
# surveys_only$ctl$SR_parms$PHASE <- -99
# surveys_only$ctl$Q_parms$PHASE <- -99
# surveys_only$ctl$size_selex_parms$PHASE <- -99
# surveys_only$ctl$size_selex_parms_tv$PHASE <- -99
# surveys_only$ctl$lambdas <- surveys_only$ctl$lambdas |>
#   slice(-(1:2)) |>
#   bind_rows(
#     data.frame(
#       like_comp = rep(4, 6),
#       fleet = 1:6, phase = 1, value = 0, sizefreq_method = 0
#     ),
#     data.frame(
#       like_comp = rep(5, 5),
#       fleet = c(1,2,3,5,6), phase = 1, value = 0, sizefreq_method = 0
#     )
#     
#   )
# surveys_only$ctl$N_lambdas <- nrow(surveys_only$ctl$lambdas)
# surveys_only$ctl$recdev_phase <- 1
# 
# SS_write(surveys_only, file.path(model_directory, 'sensitivities', 'surveys_only'),
#          overwrite = TRUE)
# out_surveys <- SS_output(file.path(model_directory, 'sensitivities', 'surveys_only'))
# SS_plots(out_surveys)

# RREAS -------------------------------------------------------------------

sensi_mod <- base_model

rreas <- read.csv('Data/raw_not_confidential/RREAS/ytail_coastwide_indices.csv') |>
  mutate(index = 4, month = 7) |>
  rename(se_log = logse, year = YEAR, obs = est)

sensi_mod$dat$fleetnames[4] <- 'RREAS'
sensi_mod$dat$fleetinfo[sensi_mod$dat$fleetinfo$fleetname == 'PLACEHOLDER',] <- c(3, 1, 1, 2, 0, 'RREAS')
rownames(sensi_mod$dat$CPUEinfo) <- sensi_mod$dat$fleetnames
sensi_mod$dat$CPUEinfo['RREAS','units'] <- 33 # recruitment, age-0 recruits;

sensi_mod$dat$CPUE <- bind_rows(sensi_mod$dat$CPUE,
                                rreas)

sensi_mod$ctl$Q_options <- rbind(sensi_mod$ctl$Q_options,
                                 RREAS = c(4,1,0,0,0,1)) |>
  slice(3,1,2) # reorder
sensi_mod$ctl$Q_parms <- bind_rows(sensi_mod$ctl$Q_parms[1,], # copy triennial Q setup for RREAS
                                   sensi_mod$ctl$Q_parms)
rownames(sensi_mod$ctl$Q_parms) <- rownames(sensi_mod$ctl$Q_parms) |>
  stringr::str_replace('Triennial\\(5\\)\\.\\.\\.1', 'RREAS(4)') |> # fix row names
  stringr::str_remove('\\.\\.\\.[:digit:]')

SS_write(sensi_mod, file.path(model_directory, 'sensitivities', 'RREAS'),
         overwrite = TRUE)

out <- SS_output(file.path(model_directory, 'sensitivities', 'RREAS'))
SSplotIndices(out, fleets = 4)

# remove trawl surveys ----------------------------------------------------

sensi_mod <- base_model

sensi_mod$dat$CPUE$year <- -1*sensi_mod$dat$CPUE$year
sensi_mod$ctl$Q_options <- sensi_mod$ctl$Q_parms <- NULL

SS_write(sensi_mod, file.path(model_directory, 'sensitivities', 'no_surveys'),
         overwrite = TRUE)


# observer index ----------------------------------------------------------

sensi_mod <- base_model

sensi_mod$dat$CPUEinfo
sensi_mod$dat$CPUE <- bind_rows(sensi_mod$dat$CPUE,
                                read.csv('data/processed/observer_index.csv'))

sensi_mod$ctl$Q_options <- rbind(sensi_mod$ctl$Q_options,
                                 Commercial = c(1,1,0,0,0,1)) |>
  slice(3,1,2) # reorder
sensi_mod$ctl$Q_parms <- bind_rows(sensi_mod$ctl$Q_parms[1,], # copy triennial Q setup for observer index
                                   sensi_mod$ctl$Q_parms)
sensi_mod$ctl$Q_parms[1, 'PHASE'] <- -99
rownames(sensi_mod$ctl$Q_parms) <- rownames(sensi_mod$ctl$Q_parms) |>
  stringr::str_replace('Triennial\\(5\\)\\.\\.\\.1', 'Commercial(1)') |> # fix row names
  stringr::str_remove('\\.\\.\\.[:digit:]')

SS_write(sensi_mod, file.path(model_directory, 'sensitivities', 'observer_index'),
         overwrite = TRUE)
# out <- SS_output(file.path(model_directory, 'sensitivities', 'observer_index'))
# SSplotIndices(out, fleets = 1)

# no fishery lengths ------------------------------------------------------

sensi_mod <- base_model
sensi_mod$ctl$lambdas <- filter(sensi_mod$ctl$lambdas, like_comp == 17) |>
  bind_rows(data.frame(
    like_comp = 4, fleet = 1:3, phase = 1, value = 0, sizefreq_method = 0
  ))
sensi_mod$ctl$N_lambdas <- nrow(sensi_mod$ctl$lambdas)

SS_write(sensi_mod, file.path(model_directory, 'sensitivities', 'no_fishery_len'),
         overwrite = TRUE)

# non-linear catchability -------------------------------------------------

sensi_mod <- base_model
sensi_mod$ctl$Q_options$link <- 3

power_row <- sensi_mod$ctl$Q_parms[1,] |>
  `rownames<-`('power_parameter')
power_row$INIT <- 0
power_row$PHASE <- 3

sensi_mod$ctl$Q_parms <- bind_rows(
  sensi_mod$ctl$Q_parms[1,],
  power_row,
  sensi_mod$ctl$Q_parms[2:3,],
  power_row,
  sensi_mod$ctl$Q_parms[4,]
)

SS_write(sensi_mod, file.path(model_directory, 'sensitivities', 'nonlinear_q'),
         overwrite = TRUE)


# Add unsexed commercial lengths ------------------------------------------

sensi_mod <- base_model

unsexed_lengths <- read.csv('data/processed/pacfin_lcomps_raw.csv') |>
  `names<-`(names(sensi_mod$dat$lencomp)) |>
  filter(sex == 0)
sensi_mod$dat$lencomp <- bind_rows(sensi_mod$dat$lencomp,
                                   unsexed_lengths)

SS_write(sensi_mod, file.path(model_directory, 'sensitivities', 'unsexed_lengths'),
         overwrite = TRUE)


# sex-specific selectivity ------------------------------------------------

sensi_mod <- base_model

sensi_mod$ctl$size_selex_parms[grepl('Off_(1|2|5)', rownames(sensi_mod$ctl$size_selex_parms)) &
                                 !grepl('Rec', rownames(sensi_mod$ctl$size_selex_parms)), 
                               'PHASE'] <- 6

SS_write(sensi_mod, file.path(model_directory, 'sensitivities', 'sex_selex'), 
         overwrite = TRUE)


# No sex specific selectivity ---------------------------------------------

sensi_mod <- base_model

sensi_mod$ctl$size_selex_parms[grepl('Off', rownames(sensi_mod$ctl$size_selex_parms)), 'PHASE'] <- -99

SS_write(sensi_mod, file.path(model_directory, 'sensitivities', 'no_sex_selex'), 
         overwrite = TRUE)

# no recdev constraint ----------------------------------------------------

sensi_mod <- base_model

sensi_mod$ctl$do_recdev <- 2

SS_write(sensi_mod, file.path(model_directory, 'sensitivities', 'recdev_option_2'), 
         overwrite = TRUE)



# Breakpoint M --------------------------------------------------------------

sensi_mod <- base_model

sensi_mod$ctl$natM_type <- 1
sensi_mod$ctl$N_natM <- sensi_mod$ctl$N_natMparms <- 2
sensi_mod$ctl$M_ageBreakPoints <- 9:10 # age at 50% maturity is 10

nat_m_ind <- grep('NatM', rownames(sensi_mod$ctl$MG_parms))

mg_table <- SS_read(file.path(model_directory, '4.07_breakpoint_m'))$ctl$MG_parms
mg_table['CV_old_Fem_GP_1', 'LO'] <- -0.99
sensi_mod$ctl$MG_parms <- mg_table

SS_write(sensi_mod, file.path(model_directory, 'sensitivities', 'breakpoint_m'),
         overwrite = TRUE)  


# Single M ----------------------------------------------------------------

sensi_mod <- base_model

sensi_mod$ctl$MG_parms['NatM_p_1_Mal_GP_1', c('INIT', 'PHASE')] <- c(0, -99)

SS_write(sensi_mod, file.path(model_directory, 'sensitivities', 'single_m'),
         overwrite = TRUE)  

# Time varying W-L --------------------------------------------------------



# Run stuff ---------------------------------------------------------------



future::plan(future::multisession(workers = parallelly::availableCores(omit = 1)))

sensitivity_dirs <- file.path(model_directory, c())
furrr::future_map(sensitivity_dirs, run(., exe = exe_loc, extras = '-nohess', skipfinished = FALSE))
