library(dplyr)

observer <- read.csv('data/confidential/wcgop_logbook/ward_oken_observer_data_2024-09-10.csv') |>
  as_tibble() |>
  filter(AVG_LAT > 40+1/6, 
         sector == 'Midwater Rockfish',
         DATATYPE == 'Analysis Data') 

# add catch of zero for midwater rockfish hauls without yellowtail
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

# add catch of zero for midwater rockfish hauls without yellowtail
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
         fDRVID = factor(DRVID), fport = factor(R_PORT),
         program = factor(program),
         area = factor(ifelse(AVG_LAT > 46.2, 'North', 'South')),
         constrained = factor(ifelse(YEAR < 2017, TRUE, FALSE)),
         julian_date = lubridate::yday(SET_DATE)) # note D_PORT is NA in some cases, R_PORT is always defined (fish ticket)

nrow(filter(all_hauls_yt, MT>0)) / nrow(all_hauls_yt)
# good to monitor % positive hauls. This is pretty high (70%).

yt_mesh <- sdmTMB::make_mesh(all_hauls_yt, xy_cols = c('AVG_LONG', 'AVG_LAT'), n_knots = 50)
plot(yt_mesh)
# this does not look like a st model is a good idea. very clear "hotspots" of fishing effort.
# but we need it for sdmTMB to work (not actually used)

yt_no_outlier <- filter(all_hauls_yt, cpue < 90)

filter(yt_no_outlier, MT > 0) |> 
  ggplot() + 
  geom_histogram(aes(x = cpue)) +
  xlab('CPUE (mt/hr)')
ggsave('figures/cpue_index/tow_hist.png', device = 'png', dpi = 500, width = 3, height = 3, units = 'in')

yt_big_boats <- yt_no_outlier |> 
  group_by(fDRVID) |>
  mutate(n_haul = n()) |>
  filter(n_haul > 30)

mod_simple <- sdmTMB::sdmTMB(formula = cpue ~ fyear + s(depth_std) + s(julian_date) + (1|fDRVID) + program + area - 1, family = sdmTMB::delta_lognormal(),
                             data = yt_no_outlier, spatial = 'off', spatiotemporal = 'off', time = 'fyear', mesh = yt_mesh)

mod_data_rich <- sdmTMB::sdmTMB(formula = cpue ~ fyear + s(depth_std) + s(julian_date, by = fDRVID) + (1|fDRVID) + program + area - 1, family = sdmTMB::delta_lognormal(),
                                data = yt_big_boats, spatial = 'off', spatiotemporal = 'off', time = 'fyear', mesh = yt_mesh)

mod_2017 <- sdmTMB::sdmTMB(formula = cpue ~ (1|fyear) + s(depth_std) + s(julian_date) + (1|fDRVID) + program + area + constrained - 1, family = sdmTMB::delta_lognormal(),
                                data = yt_no_outlier, spatial = 'off', spatiotemporal = 'off', time = 'fyear', mesh = yt_mesh)

mod_fall <- yt_no_outlier |>
  filter(month > 8) %>%
  sdmTMB::sdmTMB(formula = cpue ~ fyear + s(depth_std) + s(julian_date) + (1|fDRVID) + program + area - 1, family = sdmTMB::delta_lognormal(),
                 data = ., spatial = 'off', spatiotemporal = 'off', time = 'fyear', mesh = yt_mesh)

mod_wa <- yt_no_outlier |>
  filter(area == 'North') %>%
  sdmTMB::sdmTMB(formula = cpue ~ fyear + s(depth_std) + s(julian_date) + (1|fDRVID) + program - 1, family = sdmTMB::delta_lognormal(),
                           data = ., spatial = 'off', spatiotemporal = 'off', time = 'fyear', mesh = yt_mesh)

resids <- residuals(mod_simple, model = 2) # the presence/absence model looks consistently good
qqnorm(resids)
qqline(resids)

depth_presence <- sdmTMB::visreg_delta(mod_simple, xvar = "depth_std", model = 1, gg = TRUE) +
  ggtitle('Presence model')
depth_catch <- sdmTMB::visreg_delta(mod_simple, xvar = "depth_std", model = 2, gg = TRUE) +
  ggtitle('Positive catch model')
month_presence <- sdmTMB::visreg_delta(mod_simple, xvar = "julian_date", model = 1, gg = TRUE) +
  ggtitle('Presence model')
month_catch <- sdmTMB::visreg_delta(mod_simple, xvar = "julian_date", model = 2, gg = TRUE) +
  ggtitle('Positive catch model')

cowplot::plot_grid(depth_presence, depth_catch)
ggsave('figures/cpue_index/depth_effects.png', device = 'png', dpi = 500, width = 9, height = 4, units = 'in')

cowplot::plot_grid(month_presence, month_catch)
ggsave('figures/cpue_index/day_effects.png', device = 'png', dpi = 500, width = 9, height = 4, units = 'in')

preds_simple <- predict(mod_simple, 
                 newdata = tibble(fyear = factor(2012:2023), depth_std = 0, julian_date = 250, program = 'obs', area = 'North', fDRVID = '546053', fport = 'NEWPORT'), 
                 return_tmb_object = TRUE, re_form = NA, re_form_iid = NA)

ind_simple <- sdmTMB::get_index(preds_simple, bias_correct = TRUE, level = 0.68) |>
  rename(year = fyear) |>
  mutate(year = as.numeric(year))

preds_wa <- predict(mod_wa, 
                        newdata = tibble(fyear = factor(2012:2023), depth_std = 0, julian_date = 250, program = 'obs', fDRVID = '546053', fport = 'NEWPORT'), 
                        return_tmb_object = TRUE, re_form = NA, re_form_iid = NA)

ind_wa <- sdmTMB::get_index(preds_wa, bias_correct = TRUE, level = 0.68) |>
  rename(year = fyear) |>
  mutate(year = as.numeric(year))

preds_data_rich <- predict(mod_data_rich, 
                           newdata = tibble(fyear = factor(2012:2023), depth_std = 0, julian_date = 250, program = 'obs', area = 'North', fDRVID = factor('546053'), fport = 'NEWPORT'), 
                           return_tmb_object = TRUE, re_form = NA, re_form_iid = NULL)

ind_data_rich <- sdmTMB::get_index(preds_data_rich, bias_correct = TRUE, level = 0.68) |>
  rename(year = fyear) |>
  mutate(year = as.numeric(year))

preds_fall <- predict(mod_fall, 
                           newdata = tibble(fyear = factor(2012:2023), depth_std = 0, julian_date = 250, program = 'obs', area = 'North', fDRVID = '546053', fport = 'NEWPORT'), 
                           return_tmb_object = TRUE, re_form = NA, re_form_iid = NA)

ind_fall <- sdmTMB::get_index(preds_fall, bias_correct = TRUE, level = 0.68) |>
  rename(year = fyear) |>
  mutate(year = as.numeric(year))

preds_2017 <- predict(mod_2017, 
                      newdata = tibble(fyear = factor(2012:2023), depth_std = 0, julian_date = 250, program = 'obs', area = 'North', fDRVID = factor(546053), constrained = factor(FALSE),
                                       fport = 'NEWPORT'), 
                      return_tmb_object = TRUE, re_form = NA, re_form_iid = NULL)

ind_2017 <- sdmTMB::get_index(preds_2017, bias_correct = TRUE, level = 0.68) |>
  rename(year = fyear) |>
  mutate(year = as.numeric(year))

load("data/confidential/wcgbts_updated/interaction/delta_lognormal/index/sdmTMB_save.RData")

bind_rows(list(basic = ind_simple,
               `common boats` = ind_data_rich,
               fall = ind_fall,
               wa = ind_wa,
               `2017 flag` = ind_2017,
               WCGBTS = filter(results_by_area$`North of Cape Mendocino`$index, year > 2011, year < 2024)
               ), 
          .id = 'model') |>
  group_by(model) |>
  mutate(std_index = est / mean(est)) |>
  ggplot(aes(x = year, y = std_index, col = model)) +
  geom_point() + geom_line(linewidth = 0.75) +
  viridis::scale_color_viridis(discrete = TRUE)
ggsave('figures/cpue_index/all_indices.png', device = 'png', dpi = 500, width = 9, height = 4, units = 'in')

bind_rows(list(WCGOP = ind_simple,
               WCGBTS = results_by_area$`North of Cape Mendocino`$index), 
          .id = 'index') |>
  group_by(index) |>
  mutate(lwr = (lwr - mean(est)) / sd(est),
         upr = (upr - mean(est)) / sd(est),
         est = (est - mean(est)) / sd(est),
         year = ifelse(index == 'WCGOP', year + 0.25, year)) |>
  ggplot(aes(x = year, y = est, ymin = lwr, ymax = upr, col = index, group = index)) +
  geom_line() +
  geom_linerange(alpha = 0.25) +
  geom_point() +
  labs(x = 'Year', y = 'Standardized CPUE', col = 'Index source') +
  scale_color_manual(values = viridis::viridis(n = 3)[1:2])
ggsave('report/figures/wcgop.png', device = 'png', width = 9, height = 4, units = 'in', dpi = 500)

ind_for_ss3 <- ind |>
  select(year = fyear, obs = est, se_log = se) |>
  mutate(index = 1, month = 7)

write.csv(ind_for_ss3, file = 'data/processed/observer_index.csv', row.names = FALSE)

all_hauls_yt |>
  ggplot() +
  geom_point(aes(x = HAUL_DURATION, y = MT))
geom_density(aes(x = HAUL_DURATION, col = YEAR, group = YEAR))

### general observation: as I have added terms to the model, the signal in the index went from well-defined to noisy and meaningless.
### the port (8 levels) and vessel (46 levels) effects really did it in. should think more carefully about what terms to include.
### note 3962 hauls, 2762 positive hauls over 12 years. ~330 hauls/yr, 230 positive hauls/yr. # of hauls varies a lot by year.
### (increases 2012-2018)