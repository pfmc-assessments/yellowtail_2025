# code to set base model directory and update r4ss plots and tables as needed

# location of base model 
# path is relative to /report/
# base_mod should match what's set in /report/SAR_USWC_Yellowtail_rockfish_skeleton.qmd
# so is not set here to avoid accidental mismatch
if (!exists("base_mod")) {
  cli::cli_abort(
    "base_mod not set. Please set base_mod to match what's set in /report/SAR_USWC_Yellowtail_rockfish_skeleton.qmd."
  )
}

# read model output using r4ss
mod_out <- r4ss::SS_output(
  dir = file.path("Model_Runs", base_mod),
  SpawnOutputLabel = "Spawning output (trillions of eggs)",
  printstats = FALSE,
  verbose = FALSE
)

# make new r4ss plots
# TODO: add better fleetnames if desired
r4ss::SS_plots(mod_out, printfolder = "../../report/r4ss_plots", uncertainty = TRUE)

# make new tables
# TODO: add better fleetnames if desired
r4ss::table_all(replist = mod_out, dir = here::here("report"))

# custom calls to r4ss functions

# taller biology plot to be easier to see and 
r4ss::SSplotBiology(
  mod_out,
  subplots = 3,
  plotdir = "report/r4ss_plots",
  plot = FALSE,
  print = TRUE,
  pheight = 5.5,
  pwidth = 6.5)

# standard selectivity plots but with smurfs removed because 
# the use of index units 33 bypasses selectivity
r4ss::SSplotSelex(
  mod_out,
  subplots = c(1, 2),
  fleets = which(!grepl("SMURF", mod_out$FleetNames)),
  plotdir = "report/Figures",
  plot = FALSE,
  print = TRUE
)

# make custom selectivity plot
source("Rscripts/plot_selex.R")
plot_yellowtail_tv_selex(mod_out)

# make custom index plot
source("Rscripts/plot_indices.R")
plot_indices(
  mod_out,
  dir = "report/Figures",
  fit = TRUE,
  log = FALSE,
  fleets = c(6, 5, 4, 7)
)

# make custom parameter prior/est plot TODO: modify to exclude male M?
r4ss::SSplotPars(
  mod_out,
  strings = "NatM_uniform_Fem_GP_1",
  ncols = 1,
  nrows = 1,
  plot = FALSE,
  print = TRUE,
  plotdir = "report/Figures",
  pheight = 3.5,
  newheaders = "Female natural mortality (M)"
)

# NOTE: manually update comparisons with Canada via script:
# Rscripts\explore_Canadian_comparisons.R

# landscape plot of length comps for fishing fleets
r4ss::SSplotComps(
  mod_out,
  subplots = 21,
  fleets = 1:3,
  maxrows = 1,
  maxcols = 3,
  datonly = TRUE, 
  plot = FALSE,
  print = TRUE,
  plotdir = "report/Figures",
  pwidth = 6.5,
  pheight = 3.5,
  ybuffer = .3
)
file.rename(
  "report/Figures/comp_lendat__aggregated_across_time.png",
  "report/Figures/comp_lendat__aggregated_across_time_FISHERIES.png"
)

r4ss::SSplotComps(
  mod_out,
  subplots = 21,
  fleets = 4:6,
  maxrows = 1,
  maxcols = 4,
  datonly = TRUE, 
  plot = FALSE,
  print = TRUE,
  plotdir = "report/Figures",
  pwidth = 6.5,
  pheight = 3.5,
  ybuffer = .3
)
file.rename(
  "report/Figures/comp_lendat__aggregated_across_time.png",
  "report/Figures/comp_lendat__aggregated_across_time_SURVEYS.png"
)

r4ss::SSplotComps(
  mod_out,
  kind = "AGE",
  subplots = 21,
  fleets = 1:3,
  maxrows = 1,
  maxcols = 3,
  datonly = TRUE, 
  plot = FALSE,
  print = TRUE,
  plotdir = "report/Figures",
  pwidth = 6.5,
  pheight = 3.5,
  ybuffer = .3
)
file.rename(
  "report/Figures/comp_agedat__aggregated_across_time.png",
  "report/Figures/comp_agedat__aggregated_across_time_FISHERIES.png"
)

# historical assessment timeseries plot
source("Rscripts/historical_assessment_timeseries.R")

# N-at-age matrix for electronic supplement
write.csv(mod_out$natage, file = 'report/tables/n_at_age.csv', row.names = FALSE)
