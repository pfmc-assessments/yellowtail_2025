library(dplyr)
library(devtools)
#install_github("pfmc-assessments/indexwc")
library(indexwc)
library(purrr)
library(sdmTMB)
library(tibble)

#### Re-running a state-based index for yellowtail 
configuration_ytk <- configuration |>
  dplyr::filter(species == "yellowtail rockfish")

configuration_ytk_wcgbt <- configuration_ytk |>
  dplyr::filter(source == "NWFSC.Combo" & family == "sdmTMB::delta_gamma()")

configuration_ytk_wcgbt[1, "formula"]<- "catch_weight ~ 0 + fyear*split_state + pass_scaled"
configuration_ytk_wcgbt[, "formula"]
configuration_to_run <- configuration_ytk_wcgbt |>
  dplyr::filter(
    formula == "catch_weight ~ 0 + fyear*split_state + pass_scaled"
  )

data <- configuration_to_run |>
  # Row by row ... do stuff then ungroup
  dplyr::rowwise() |>
  # Pull the data based on the function found in fxn column
  dplyr::mutate(
    data_raw = list(format_data(eval(parse(text = fxn)))),
    data_filtered = list(data_raw |>
                           dplyr::filter(
                             depth <= min_depth, depth >= max_depth,
                             latitude >= min_latitude, latitude <= max_latitude,
                             year >= min_year, year <= max_year
                           ) |>
                           #dplyr::mutate(split_mendocino = ifelse(latitude > 40.1666667, "N", "S")))
                           dplyr::mutate(split_state = ifelse(latitude < 42, "C", 
                                                              ifelse(latitude <46.246922&latitude>42,"O", "W"))))
  ) |>
  dplyr::ungroup()

dplyr::filter(data$data_filtered[[1]]) |>
  dplyr::group_by(split_state, year) |>
  dplyr::summarise(sum_catch_weight = sum(catch_weight)) |>
  dplyr::filter(sum_catch_weight == 0)

lm <- lm(
  formula = as.formula(configuration_to_run$formula),
  data = data$data_filtered[[1]]
)

coef_names <- names(coef(lm))

print(coef_names)

pres_not_identifiable <- names(which(is.na(coef(lm))))
print(pres_not_identifiable)

lm_pos <- lm(
  formula = as.formula(configuration_to_run$formula),
  data = dplyr::filter(data$data_filtered[[1]], catch_weight > 0)
)

pos_not_identifiable <- names(which(is.na(coef(lm_pos))))
print(pos_not_identifiable)

map_pres <- coef_names
map_pres[coef_names %in% pres_not_identifiable] <- NA
map_pres <- factor(map_pres)

map_pos <- coef_names
map_pos[coef_names %in% pos_not_identifiable] <- NA
map_pos <- factor(map_pos)
start_pres <- rep(0, length(coef_names))
start_pres[coef_names %in% pres_not_identifiable] <- -20

start_pos <- rep(0, length(coef_names))
start_pos[coef_names %in% pos_not_identifiable] <- -20
best <- data |>
  dplyr::mutate(
    # Evaluate the call in family
    family = purrr::map(family, .f = ~ eval(parse(text = .x))),
    # Run the model on each row in data
    results = purrr::pmap(
      .l = list(
        data = data_filtered,
        formula = formula,
        family = family,
        anisotropy = anisotropy,
        n_knots = knots,
        share_range = share_range,
        spatiotemporal = purrr::map2(spatiotemporal1, spatiotemporal2, list),
        sdmtmb_control = list(
          sdmTMB::sdmTMBcontrol(
            map = list(b_j = map_pos, b_j2 = map_pos),
            start = list(b_j = start_pos, b_j2 = start_pos),
            newton_loops = 1 # increase for real models
          )
        )
      ),
      .f = indexwc::run_sdmtmb
    )
  )

#### Re-running canary for N/S Mendocino Request 14

configuration_cr <- configuration |>
  dplyr::filter(species == "yellowtail rockfish")

configuration_cr[, "species"]<- "canary rockfish"

configuration_to_run <- configuration_cr |>
  dplyr::filter(
    formula == "catch_weight ~ 0 + fyear*split_mendocino + pass_scaled"
    #formula == "catch_weight ~ 0 + fyear + pass_scaled"
    
  )

data <- configuration_to_run |>
  # Row by row ... do stuff then ungroup
  dplyr::rowwise() |>
  # Pull the data based on the function found in fxn column
  dplyr::mutate(
    data_raw = list(format_data(eval(parse(text = fxn)))),
    data_filtered = list(data_raw |>
                           dplyr::filter(
                             depth <= min_depth, depth >= max_depth,
                             latitude >= min_latitude, latitude <= max_latitude,
                             year >= min_year, year <= max_year
                           ) |>
                           dplyr::mutate(split_mendocino = ifelse(latitude > 40.1666667, "N", "S")))
  ) |>
  dplyr::ungroup()

lm <- lm(
  formula = as.formula(configuration_to_run$formula),
  data = data$data_filtered[[1]]
)

coef_names <- names(coef(lm))

print(coef_names)

pres_not_identifiable <- names(which(is.na(coef(lm))))
print(pres_not_identifiable)
lm_pos <- lm(
  formula = as.formula(configuration_to_run$formula),
  data = dplyr::filter(data$data_filtered[[1]], catch_weight > 0)
)

pos_not_identifiable <- names(which(is.na(coef(lm_pos))))
print(pos_not_identifiable)
map_pres <- coef_names
map_pres[coef_names %in% pres_not_identifiable] <- NA
map_pres <- factor(map_pres)

map_pos <- coef_names
map_pos[coef_names %in% pos_not_identifiable] <- NA
map_pos <- factor(map_pos)
start_pres <- rep(0, length(coef_names))
start_pres[coef_names %in% pres_not_identifiable] <- -20

start_pos <- rep(0, length(coef_names))
start_pos[coef_names %in% pos_not_identifiable] <- -20

best <- data |>
  dplyr::mutate(
    # Evaluate the call in family
    family = purrr::map(family, .f = ~ eval(parse(text = .x))),
    # Run the model on each row in data
    results = purrr::pmap(
      .l = list(
        data = data_filtered,
        formula = formula,
        family = family,
        anisotropy = anisotropy,
        n_knots = knots,
        share_range = share_range,
        spatiotemporal = purrr::map2(spatiotemporal1, spatiotemporal2, list),
        sdmtmb_control = list(
          sdmTMB::sdmTMBcontrol(
            map = list(b_j = map_pos, b_j2 = map_pos),
            start = list(b_j = start_pos, b_j2 = start_pos),
            newton_loops = 1 # increase for real models
          )
        )
      ),
      .f = indexwc::run_sdmtmb
    )
  )


#### Re-running widow for N/S Mendocino request 14
configuration_wr <- configuration |>
  dplyr::filter(species == "yellowtail rockfish")
configuration_wr[, "species"]<- "widow rockfish"
configuration_to_run <- configuration_wr |>
  dplyr::filter(
    formula == "catch_weight ~ 0 + fyear*split_mendocino + pass_scaled"
  )

data <- configuration_to_run |>
  # Row by row ... do stuff then ungroup
  dplyr::rowwise() |>
  # Pull the data based on the function found in fxn column
  dplyr::mutate(
    data_raw = list(format_data(eval(parse(text = fxn)))),
    data_filtered = list(data_raw |>
                           dplyr::filter(
                             depth <= min_depth, depth >= max_depth,
                             latitude >= min_latitude, latitude <= max_latitude,
                             year >= min_year, year <= max_year
                           ) |>
                           dplyr::mutate(split_mendocino = ifelse(latitude > 40.1666667, "N", "S")))
  ) |>
  dplyr::ungroup()

lm <- lm(
  formula = as.formula(configuration_to_run$formula),
  data = data$data_filtered[[1]]
)

coef_names <- names(coef(lm))

print(coef_names)

pres_not_identifiable <- names(which(is.na(coef(lm))))
print(pres_not_identifiable)
lm_pos <- lm(
  formula = as.formula(configuration_to_run$formula),
  data = dplyr::filter(data$data_filtered[[1]], catch_weight > 0)
)

pos_not_identifiable <- names(which(is.na(coef(lm_pos))))
print(pos_not_identifiable)
map_pres <- coef_names
map_pres[coef_names %in% pres_not_identifiable] <- NA
map_pres <- factor(map_pres)

map_pos <- coef_names
map_pos[coef_names %in% pos_not_identifiable] <- NA
map_pos <- factor(map_pos)
start_pres <- rep(0, length(coef_names))
start_pres[coef_names %in% pres_not_identifiable] <- -20

start_pos <- rep(0, length(coef_names))
start_pos[coef_names %in% pos_not_identifiable] <- -20

best <- data |>
  dplyr::mutate(
    # Evaluate the call in family
    family = purrr::map(family, .f = ~ eval(parse(text = .x))),
    # Run the model on each row in data
    results = purrr::pmap(
      .l = list(
        data = data_filtered,
        formula = formula,
        family = family,
        anisotropy = anisotropy,
        n_knots = knots,
        share_range = share_range,
        spatiotemporal = purrr::map2(spatiotemporal1, spatiotemporal2, list),
        sdmtmb_control = list(
          sdmTMB::sdmTMBcontrol(
            map = list(b_j = map_pos, b_j2 = map_pos),
            start = list(b_j = start_pos, b_j2 = start_pos),
            newton_loops = 1 # increase for real models
          )
        )
      ),
      .f = indexwc::run_sdmtmb
    )
  )
