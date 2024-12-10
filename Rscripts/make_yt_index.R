
## Example: yellowtail rockfish

# Packages
remotes::install_github("pfmc-assessments/nwfscSurvey")
library(nwfscSurvey)
library(dplyr)
library(sdmTMB)

# Read in indexwc configuration for latitude / depth truncation
url <- "https://raw.githubusercontent.com/pfmc-assessments/indexwc/refs/heads/main/data-raw/configuration.csv"
config <- read.csv(url)
config <- dplyr::filter(config, species == "yellowtail rockfish")
print(config)

# Pull the data in from warehouse with nwfscSurvey
# Note: this creates identical datafiles to the indexwc package BUT
# we can't use that package because of the region*year models we use below
catch <- pull_catch(survey = "NWFSC.Combo", common_name = "yellowtail rockfish")
filtered_catch <- dplyr::filter(catch,
                                Depth_m >= -config$min_depth,
                                Depth_m <= -config$max_depth,
                                Latitude_dd >= config$min_latitude,
                                Latitude_dd <= config$max_latitude) |>
  dplyr::rename(latitude = Latitude_dd,
                longitude = Longitude_dd,
                catch_weight = total_catch_wt_kg,
                effort = Area_swept_ha,
                year = Year)
saveRDS(filtered_catch,"yt_data_filtered.rds")
saveRDS(catch,"yt_data_raw.rds")


# Load the data
data_truncated <- readRDS("yt_data_filtered.rds")
data_truncated$region <- ifelse(data_truncated$latitude > 40.1666667, "N", "S")
data_truncated$region <- as.factor(data_truncated$region)
data_truncated$fyear <- as.factor(data_truncated$year)
data_truncated$pass_scaled <- c(-0.5,0.5)[data_truncated$Pass]

models <- expand.grid(knots = c(400),
                      anisotropy = c(TRUE),
                      spatiotemporal1 = c("iid"), spatiotemporal2 = c("off"),
                      family = c("sdmTMB::delta_gamma()"))
models$converged <- NA

# create presence-absence variable
data_truncated$present <- ifelse(data_truncated$catch_weight > 0, 1, 0)
# switch to one hot encoding
model_mat <- model.matrix(catch_weight ~ -1 + fyear*region + pass_scaled, data = data_truncated)
# delete the 2007:S interaction, as there's no values > 0
# also drop 2003:S because this is absorbed in the intercept
model_mat <- dplyr::select(as.data.frame(model_mat), -"fyear2007:regionS")
covariate_formula <- as.formula(paste("present ~", paste(colnames(model_mat), collapse = " + ")))
# join in model_mat
data_truncated <- cbind(data_truncated, model_mat)
data_truncated <- data_truncated[,-which(names(data_truncated)=="pass_scaled")[1]]
# Create list of variables models
vars <- c(paste0("fyear", c(2004:2006, 2008:2019, 2021:2023), ":regionS"), "pass_scaled", "region", "fyear", "-1")
covariate_formula <- as.formula(paste("present ~", paste(vars, collapse = " + ")))

# Make the mesh -- using 400 knots (above)
data_truncated <- add_utm_columns(data_truncated, ll_names = c("longitude","latitude")) |>
  dplyr::rename(x = X, y = Y) # for consistency with indexwc
mesh <- make_mesh(data_truncated, xy_cols = c("x","y"),
                  n_knots = models$knots)

# Run model
fit <- sdmTMB(
  formula = covariate_formula,
  time = "year",
  data = data_truncated,
  spatial = "on",
  offset = log(data_truncated$effort),
  spatiotemporal = list(models$spatiotemporal1, models$spatiotemporal2),
  mesh = mesh,
  anisotropy = models$anisotropy,
  share_range = FALSE, # indexwc setting
  family = delta_gamma(),
  control = sdmTMB::sdmTMBcontrol(newton_loops = 2, nlminb_loops = 2)
)

# Passes checks all ok
sanity(fit)

# Index construction -- first extract the grid from 'indexwc' so we're using
# exactly the same as other assessments / indexwc
grid <- readRDS("prediction_grid_from_indexwc.rds")

grid <- replicate_df(grid,
                     time_name = "year",
                     time_values = sort(unique(data_truncated$year)))
grid$region <- "N"
# replicate the S grid in case we'd want an index for that too
grid_S <- grid
grid_S$region <- "S"
grid <- rbind(grid, grid_S)
grid$fyear <- as.factor(grid$year)

# Now make predictions with sdmTMB
# need to add one hot encoding to this grid too
model_mat <- model.matrix(y ~ -1 + fyear*region, data = grid)
model_mat <- dplyr::select(as.data.frame(model_mat), -"fyear2007:regionS")
grid <- cbind(grid, model_mat) |>
  dplyr::filter(region == "N")

pred <- predict(fit, newdata = grid, return_tmb_object = TRUE)
yt_index <- get_index(pred, bias_correct = TRUE)
saveRDS(yt_index, "yt_index.rds")




