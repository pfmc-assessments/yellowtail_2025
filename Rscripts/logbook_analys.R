library(dplyr)

observer <- read.csv('data/confidential/wcgop_logbook/ward_oken_observer_data_2024-09-10.csv') |>
  as_tibble() |>
  filter(AVG_LAT > 40+1/6, 
         sector == 'Midwater Rockfish',
         DATATYPE == 'Analysis Data') 

observer_yt <- observer|>
  group_by(HAUL_ID) |>
  summarise(has_yt = 'Yellowtail Rockfish' %in% species,
            across(AVG_DEPTH:YEAR, first)) |>
  filter(!has_yt) |>
  mutate(species = 'Yellowtail Rockfish', MT = 0) |>
  select(-has_yt) |>
  bind_rows(
    filter(observer, species == 'Yellowtail Rockfish')
  ) |>
  mutate(DRVID = as.integer(DRVID))

em <- read.csv('data/confidential/wcgop_logbook/ward_oken_em_data_2024-12-03.csv') |>
  as_tibble() |> 
  filter(AVG_LAT > 40+1/6, sector == 'Midwater Rockfish EM') 

em_yt <- em |>
  group_by(HAUL_ID) |>
  summarise(has_yt = 'Yellowtail Rockfish' %in% species,
            across(AVG_DEPTH:YEAR, first)) |> 
  filter(!has_yt) |>
  mutate(species = 'Yellowtail Rockfish', MT = 0) |>
  select(-has_yt) |>
  bind_rows(
    filter(em, species == 'Yellowtail Rockfish')
  )

all_hauls_yt <- bind_rows(list(obs = observer_yt, em = em_yt), .id = 'program') |>
  filter(HAUL_DURATION > 0, HAUL_DURATION < 10) |>
  mutate(depth_std = (AVG_DEPTH - mean(AVG_DEPTH))/sd(AVG_DEPTH),
         fyear = factor(YEAR), log_duration = log(HAUL_DURATION),
         cpue = MT/HAUL_DURATION, month = lubridate::month(as.Date(SET_DATE)),
         fDRVID = factor(DRVID), fport = factor(R_PORT)) # note D_PORT is NA in some cases, R_PORT is always defined (fish ticket)

yt_mesh <- sdmTMB::make_mesh(all_hauls_yt, xy_cols = c('AVG_LONG', 'AVG_LAT'), n_knots = 50)
plot(yt_mesh)
# this does not look like a st model is a good idea. very clear "hotspots" of fishing effort.
# but we need it for sdmTMB to work (not actually used)

mod_simple <- sdmTMB::sdmTMB(formula = cpue ~ fyear + s(depth_std) + s(month, bs = 'cc') + program + (1|fDRVID) + (1|fport) - 1, family = sdmTMB::delta_lognormal(),
                             data = all_hauls_yt, spatial = 'off', spatiotemporal = 'off', time = 'fyear', mesh = yt_mesh)

summary(mod_simple)


resids <- residuals(mod_simple, model = 2) # the presence/absence model looks consistently good
qqnorm(resids)
qqline(resids)

sdmTMB::visreg_delta(mod_simple, xvar = "depth_std", model = 1, gg = TRUE)
sdmTMB::visreg_delta(mod_simple, xvar = "depth_std", model = 2, gg = TRUE)
sdmTMB::visreg_delta(mod_simple, xvar = "month", model = 1, gg = TRUE)
sdmTMB::visreg_delta(mod_simple, xvar = "month", model = 2, gg = TRUE)

preds <- predict(mod_simple, 
                 newdata = tibble(fyear = factor(2012:2023), depth_std = 0, month = 6, program = 'obs', fDRVID = '546053', fport = 'NEWPORT'), 
                 return_tmb_object = TRUE, re_form = NA, re_form_iid = NA)

ind <- sdmTMB::get_index(preds, bias_correct = TRUE)

ind |> 
  ggplot(aes(x = as.numeric(fyear), y = est, ymin = lwr, ymax = upr)) +
  geom_line() +
  geom_errorbar()


all_hauls_yt |>
  ggplot() +
  geom_point(aes(x = HAUL_DURATION, y = MT))
  geom_density(aes(x = HAUL_DURATION, col = YEAR, group = YEAR))
  
### general observation: as I have added terms to the model, the signal in the index went from well-defined to noisy and meaningless.
### the port (8 levels) and vessel (46 levels) effects really did it in. should think more carefully about what terms to include.
### note 3962 hauls, 2762 positive hauls over 12 years. ~330 hauls/yr, 230 positive hauls/yr. effort varies a lot by year.
### (increases 2012-2018)