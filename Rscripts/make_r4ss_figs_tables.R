# code to set base model directory and update r4ss plots and tables as needed

# location of base model (TODO: change as needed)
# path is relative to /report/
mod_loc <- "Model_Runs/5.09_no_extra_SE"

# read model output using r4ss
model <- r4ss::SS_output(
  dir = mod_loc,
  SpawnOutputLabel = "Spawning output (trillions of eggs)",
  printstats = FALSE,
  verbose = FALSE
)

# make new r4ss plots
# TODO: add better fleetnames if desired
r4ss::SS_plots(model, printfolder = "../../report/r4ss_plots", uncertainty = TRUE)

# make new tables
# TODO: add better fleetnames if desired
table_all(replist = model, dir = here::here("report"))

# make custom selectivity plot
source("Rscripts/plot_selex.R")
plot_yellowtail_tv_selex(model)

# make custom parameter prior/est plot TODO: modify to exclude male M?
SSplotPars(
  model,
  strings = "NatM_uniform_Fem_GP_1",
  ncols = 1,
  nrows = 1,
  plot = FALSE,
  print = TRUE,
  plotdir = "report/Figures",
  pheight = 3.5,
  newheaders = "Female natural mortality (M)"
)
