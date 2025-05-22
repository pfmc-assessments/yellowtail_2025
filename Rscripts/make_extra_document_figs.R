library(ggplot2)
library(dplyr)
theme_set(theme_classic())


# Load data ---------------------------------------------------------------

maturity <- readRDS('data/raw_not_confidential/maturity.rds')

yt_survey_bio <- nwfscSurvey::pull_bio(common_name = 'yellowtail rockfish', survey = 'NWFSC.Combo') 
yt_survey_catch <- nwfscSurvey::pull_catch(common_name = 'yellowtail rockfish', survey = 'NWFSC.Combo') 
yt_n_survey_bio <- filter(yt_survey_bio, Latitude_dd > 40 + 1/6)

load(here('Data/Confidential/Commercial/pacfin-2025-03-10/PacFIN.YTRK.bds.10.Mar.2025.RData'))
bds_clean <- bds.pacfin |>
  pacfintools::cleanPacFIN(keep_sample_type = c('M', 'S'),
                           keep_age_method = c('B', 'S')) |>
  mutate(fleet = 1) |> # assign everything to fleet 1
  filter(SAMPLE_TYPE == 'M' | (state == 'OR' & SAMPLE_YEAR <= 1986),  # keep old OR special request
         state == 'WA' | state == 'OR' | PACFIN_GROUP_PORT_CODE == 'CCA' | PACFIN_GROUP_PORT_CODE == 'ERA') |> # only y-t north
  group_by(year, SEX) |>
  mutate(n = n()) |>
  filter(n > 100) # filter to sex-year combinations >100, avoid sparse lengths.

recfin_ages <- read.csv(here::here("Data/Confidential/rec/SD506--1984---2024_ages.csv")) |>
  tibble::as_tibble()


# Make document plots -----------------------------------------------------

maturity |>
  ggplot(aes(x = age)) +
  geom_line(aes(y = p)) +
  geom_point(aes(y = n_mature/n, size = n), alpha = 0.5) +
  xlim(0, max(maturity$age * !is.na(maturity$n)) + 1) +
  labs(x = 'Age (years)', y = 'Proportion mature', size = 'Number of samples')
ggsave('report/figures/maturity_with_data.png', device = 'png')


W_L_pars <- yt_n_survey_bio |> nwfscSurvey::estimate_weight_length()

yt_n_survey_bio <- yt_n_survey_bio |>
  mutate(pred_wt_f = W_L_pars[1,'A'] * Length_cm ^ W_L_pars[1,'B'],
         pred_wt_m = W_L_pars[2,'A'] * Length_cm ^ W_L_pars[2,'B'],
         pred_wt = ifelse(Sex == 'F', pred_wt_f, pred_wt_m))

filter(yt_n_survey_bio, Sex != 'U') |>
  ggplot(aes(x = Length_cm, col = Sex, group = Sex)) +
  geom_point(aes(y = Weight_kg), alpha = 0.05) +
  geom_line(aes(y = pred_wt), linewidth = 1) +
  scale_color_manual(values = c('F' = 'red', 'M' = 'blue')) +
  labs(x = 'Length (cm)', y = 'Weight (kg)')
ggsave('report/figures/length_weight_with_data.png', device = 'png')

filter(yt_n_survey_bio, Sex != 'U') |>
  ggplot(aes(x = Length_cm, col = Sex, group = Sex)) +
  geom_point(aes(y = Weight_kg), alpha = 0.05) +
  geom_line(aes(y = pred_wt)) +
  scale_color_manual(values = c('F' = 'red', 'M' = 'blue')) +
  facet_wrap(~Year)
ggsave('report/figures/length_weight_by_year.png', device = 'png')

nwfscSurvey::PlotMap.fn(dat = yt_survey_catch, dir = 'report/figures')

# looking at how growth varies over space and time
growth_time <- filter(yt_n_survey_bio, Age_years <= 20, Age_years > 6) |>
  ggplot() +
  geom_point(aes(x = Year, y = Length_cm, col = Age_years), alpha = 0.1, position = 'jitter') +
  stat_smooth(aes(x = Year, y = Length_cm, group = Age_years, col = Age_years), se = FALSE) +
  viridis::scale_color_viridis() +
  labs(y = 'Length (cm)', col = 'Age (yrs)')
# possible decrease in length at age of older fish in last 4 years of data. TBD with 8 more years!

growth_space <- filter(yt_n_survey_bio, Age_years <= 20, Age_years > 6) |>
  ggplot() +
  geom_point(aes(x = Latitude_dd, y = Length_cm, col = Age_years), alpha = 0.1, position = 'jitter') +
  stat_smooth(aes(x = Latitude_dd, y = Length_cm, group = Age_years, col = Age_years), se = FALSE) +
  viridis::scale_color_viridis() +
  labs(x = 'Latitude (degrees)', y = 'Length (cm)', col = 'Age (yrs)')
# Larger max size farther north (consistent with theory)

occurence_depth <- yt_n_survey_bio |>
  ggplot(aes(x = Latitude_dd, y = Age_years)) +
  geom_point(alpha = 0.1, position = 'jitter') +
  stat_smooth(method = 'loess', col = 'red', se = FALSE) +
  labs(x = 'Latitude (degrees)', y = 'Age (yrs)')


all_bio_data <- bind_rows(
  bds_clean |>
    mutate(fleet = 'Commercial') |>
    select(year, SEX, Age, fleet, lengthcm),
  recfin_ages |>
    mutate(fleet = 'Recreational', lengthcm = 0.1 * RECFIN_LENGTH_MM) |>
    select(year = SAMPLE_YEAR, SEX = RECFIN_SEX_CODE, Age = USE_THIS_AGE, lengthcm, fleet),
  yt_n_survey_bio |>
    select(year = Year, SEX = Sex, Age = Age_years, lengthcm = Length_cm) |>
    mutate(fleet = 'WCGBTS')
) 

sex_ratio <- all_bio_data |>
  filter(!is.na(Age), SEX != 'U', Age < 60) |>
  group_by(Age, fleet) |>
  summarise(pct_f = mean(SEX == 'F'), sd = sqrt(pct_f*(1-pct_f)/n())) |>
  mutate(Age = Age + as.numeric(as.factor(fleet)) * 0.1,
         ylow = pct_f - 1.96*sd,
         ylow = ifelse(ylow < 0, 0, ylow),
         yhi = pct_f + 1.96*sd, 
         yhi = ifelse(yhi > 1, 1, yhi)) |> 
  ggplot(aes(x = Age, y = pct_f, ymin = ylow, ymax = yhi, col = fleet)) +
  geom_hline(yintercept = 0.5) +
  geom_point() +
  geom_linerange(alpha = 0.5) +
  ylim(0,1) +
  labs(x = 'Age (yrs)', y = 'Fraction female', col = 'Fleet') +
  scale_color_manual(values = viridis::viridis(n = 5)[c(1,3,4)])

cowplot::plot_grid(growth_space, growth_time, occurence_depth, sex_ratio, labels = paste0(letters[1:4], ')'))
ggsave('report/figures/biology.png', device = 'png', width = 9, height = 7)

# These are for presentations ---------------------------------------------

strata <- nwfscSurvey::CreateStrataDF.fn(
  names = c("shallow_OR/CA", "deep_OR/CA", "shallow_WA", "deep_WA"),
  depths.shallow = c(55, 183, 55, 183),
  depths.deep = c(183, 400, 183, 400),
  lats.south = c(40.166667, 40.166667, 46, 46),
  lats.north = c(46, 46, 49, 49)
)

db_index <- nwfscSurvey::get_design_based(yt_survey_catch, strata = strata)  
db_index$biomass_by_strata |>
  tidyr::separate_wider_delim(cols = stratum, delim = "_", names = c('depth', 'latitude')) |>
  group_by(year, latitude) |>
  summarise(ntows = sum(ntows),
            area = sum(area),
            mean_cpue = sum(area * mean_cpue) / sum(area),
            var_cpue = sum(var_cpue * area^2 / sum(area)^2),
            mean_est = sum(est),
            se = sqrt(sum(var))
  ) |>
  mutate(cv = se / mean_est,
         log_var = log(cv^2 + 1),
         est = mean_est * exp(-0.5 * log_var),
         se_log = sqrt(log_var),
         lwr = exp((log(est) + qnorm(0.025, sd = se_log))), 
         upr = exp((log(est) + qnorm(0.975, sd = se_log)))
         # year = ifelse(latitude == 'S', year + 0.2, year)
  ) |>
  select(year, est, se_log, lwr, upr, latitude) |>
  bind_rows(mutate(db_index$biomass, latitude = 'N. of 40-10')) |>
  ggplot(aes(x = year, y = est, 
             # ymin = lwr, ymax = upr, 
             group = latitude)) + 
  geom_point(aes(col = latitude)) +
  geom_line(linetype = 'dashed') +
  # geom_linerange(aes(col = latitude), alpha = 0.5) +
  labs(x = 'Year', y = 'Design-based index (mt)', col = 'Area')
ggsave('figures/index_by_area.png', device = 'png', dpi = 500, width = 6, height = 4, units = 'in')

yt_n_survey_bio |>
  filter(!is.na(Age_years), Year >= 2011) |>
  mutate(is_2008 = case_when(Year - Age_years == 2008 & Latitude_dd < 46 ~ '2008 OR/CA',
                             Year - Age_years == 2008 ~ '2008 WA',
                             TRUE ~ 'Other yr class')) |>
  count(Year, Age_years, is_2008) |>
  filter(Age_years <= 30) |>
  ggplot() +
  geom_col(aes(x = Age_years, y = n, fill = is_2008)) +
  facet_wrap(~ Year, nrow = 3) +
  labs(x = 'Age (yrs)', y = '# of samples', fill = 'Year class') +
  scale_fill_manual(values = viridis::viridis(n = 5)[c(1,3,4)])
ggsave('figures/highlight_2008.png', device = 'png', dpi = 500, width = 9, height = 4, units = 'in')

yt_n_survey_bio |>
  filter(Sex != 'U') |>
  ggplot() +
  geom_point(aes(x = Age_years, y = Length_cm, col = Sex), alpha = 0.1) +
  scale_color_manual(values = c(F = 'red', M = 'blue')) +
  labs(x = 'Age (yrs)', y = "Length (cm)")
# Large fish female, old fish male prevails, but not as notable as with canary.
ggsave(here('figures/age_length_scatter.png'), dpi = 500)


# STAR request 1 ----------------------------------------------------------


bds_clean <- bds.pacfin |>
  pacfintools::cleanPacFIN(keep_sample_type = c('M', 'S'),
                           keep_age_method = c('B', 'S'), CLEAN = FALSE) 



comm_freq <- bind_cols(bds.pacfin, select(bds_clean, CLEAN)) |>
  mutate(fleet = 1) |> # assign everything to fleet 1
  filter(SAMPLE_TYPE == 'M' | (AGENCY_CODE == 'O' & SAMPLE_YEAR <= 1986),  # keep old OR special request
         AGENCY_CODE == 'W' | AGENCY_CODE == 'O' | PACFIN_GROUP_PORT_CODE == 'CCA' | PACFIN_GROUP_PORT_CODE == 'ERA',
         CLEAN = TRUE,
         PACFIN_GEAR_CODE == 'MDT',
         !is.na(age1),
         SAMPLE_YEAR >= 2017, SAMPLE_YEAR < 2025,
         SEX_CODE != 'U') |> # only y-t north
  count(SAMPLE_YEAR, age1, SEX_CODE) |>
  rename(Sex = SEX_CODE, Year = SAMPLE_YEAR, Age_years = age1)

surv_freq <- yt_n_survey_bio |>
  filter(Year >= 2017, !is.na(Age_years), Sex != 'U') |>
  count(Year, Age_years, Sex) 

bind_rows(list(wcgbts = surv_freq, mdt = comm_freq), .id = 'source') |> 
  group_by(Sex, Year, source) |>
  mutate(freq = (n / sum(n)),
         freq = ifelse(Sex == 'F', freq, -1 * freq)) |>
  ggplot() +
  geom_line(aes(x = Age_years, y = freq, col = paste(source, Sex)), linewidth = 0.75) +
  facet_wrap(~Year) +
  geom_hline(yintercept = 0)
ggsave('figures/star_request_1.png', device = 'png', dpi = 500, width = 9, height = 5, units = 'in')  

bind_rows(list(wcgbts = surv_freq, mdt = comm_freq), .id = 'source') |> 
  group_by(Sex, source, Age_years) |>
  summarise(n = sum(n)) |>
  mutate(freq = (n / sum(n)),
             freq = ifelse(Sex == 'F', freq, -1 * freq)) |>
  # ungroup() |> group_by(source, Sex) |> summarise(sum(freq))

  ggplot() +
  # geom_col(aes(x = Age_years, y = freq, fill = source), position = 'dodge') +
  geom_line(aes(x = Age_years, y = freq, col = paste(source, Sex)), linewidth = 0.75) +
  geom_hline(yintercept = 0)
ggsave('figures/star_request_1_age_agg.png', device = 'png', dpi = 500, width = 4.5, height = 5, units = 'in')  

comm_freq <- bind_cols(bds.pacfin, select(bds_clean, CLEAN, lengthcm)) |>
  mutate(fleet = 1) |> # assign everything to fleet 1
  filter(SAMPLE_TYPE == 'M' | (AGENCY_CODE == 'O' & SAMPLE_YEAR <= 1986),  # keep old OR special request
         AGENCY_CODE == 'W' | AGENCY_CODE == 'O' | PACFIN_GROUP_PORT_CODE == 'CCA' | PACFIN_GROUP_PORT_CODE == 'ERA',
         CLEAN = TRUE,
         PACFIN_GEAR_CODE == 'MDT',
         !is.na(lengthcm),
         SAMPLE_YEAR >= 2017, SAMPLE_YEAR < 2025,
         SEX_CODE != 'U') |> # only y-t north
  mutate(len_bin = pacfintools::comps_bins(vector = lengthcm, breaks = len_bin, includeplusgroup = FALSE, 
                                           returnclass = 'numeric')) |>
  count(SAMPLE_YEAR, len_bin, SEX_CODE) |>
  mutate(n = ifelse(SEX_CODE == 'F', n, -n)) |>
  rename(Sex = SEX_CODE, Year = SAMPLE_YEAR)


surv_freq <- yt_n_survey_bio |>
  filter(Year >= 2017, !is.na(Length_cm), Sex != 'U') |>
  mutate(len_bin = pacfintools::comps_bins(vector = Length_cm, breaks = len_bin, includeplusgroup = FALSE,
                                           returnclass = 'numeric')) |>
  count(Year, len_bin, Sex) |>
  mutate(n = ifelse(Sex == 'F', n, -n))

bind_rows(list(wcgbts = surv_freq, mdt = comm_freq), .id = 'source') |> 
  group_by(Sex, Year, source) |>
  mutate(freq = (n / sum(n)),
         freq = ifelse(Sex == 'F', freq, -1 * freq)) |> 
  ggplot() +
  geom_line(aes(x = len_bin, y = freq, col = paste(source, Sex)), linewidth = 0.75) +
  geom_hline(yintercept = 0) +
  xlab('Length (cm)') +
  facet_wrap(~ Year)
ggsave('figures/star_request_1_lengths.png', device = 'png', dpi = 500, width = 9, height = 5, units = 'in')  

bind_rows(list(wcgbts = surv_freq, mdt = comm_freq), .id = 'source') |> 
  group_by(Sex, source, len_bin) |>
  summarise(n = sum(n)) |>
  mutate(freq = (n / sum(n)),
         freq = ifelse(Sex == 'F', freq, -1 * freq)) |> 
  ggplot() +
  geom_line(aes(x = len_bin, y = freq, col = paste(source, Sex)), linewidth = 0.75) +
  geom_hline(yintercept = 0) +
  xlab('Length (cm)')
ggsave('figures/star_request_1_len_agg.png', device = 'png', dpi = 500, width = 4.5, height = 5, units = 'in')  


# STAR request 10 ---------------------------------------------------------

load(here('Data/Confidential/Commercial/pacfin-2025-03-10/PacFIN.YTRK.CompFT.10.Mar.2025.RData'))

quotas <- read.csv('data/raw_not_confidential/GMT016-final specifications-.csv') |>
  filter(SPECIFICATION_NAME == 'SB IFQ Total', 
         YEAR < 2025)

cum_catch_dat <- catch.pacfin |>
  filter(PACFIN_GROUP_GEAR_CODE == 'TWL',
         PACFIN_YEAR %in% 2011:2024,
         AGENCY_CODE == 'O' | AGENCY_CODE == 'W' | PACFIN_GROUP_PORT_CODE == 'CCA' | PACFIN_GROUP_PORT_CODE == 'ERA') |> 
  left_join(quotas, by = c(LANDING_YEAR = 'YEAR')) |>
  mutate(j_day = lubridate::yday(LANDING_DATE),
         sector = case_when(PACFIN_GEAR_CODE == 'MDT' & DAHL_GROUNDFISH_CODE %in% c('03', '17') ~ 'shoreside hake',
                            PACFIN_GEAR_CODE == 'MDT' ~ 'midwater rockfish',
                            TRUE ~ 'bottom trawl')) |> 
  group_by(PACFIN_YEAR, sector) |>
  arrange(PACFIN_YEAR, sector, j_day) |> 
  mutate(cum_catch_sector = cumsum(ROUND_WEIGHT_MTONS)) |>
  ungroup() |>
  group_by(PACFIN_YEAR) |>
  arrange(PACFIN_YEAR, j_day) |>
  mutate(cum_catch = cumsum(ROUND_WEIGHT_MTONS)) |>
  ungroup() |>
  mutate(attainment_sector = cum_catch_sector / VAL,
         attainment = cum_catch / VAL)

cum_catch_dat |>
  ggplot() +
  geom_line(aes(x = j_day, y = cum_catch_sector, col = sector)) +
  facet_wrap(~ LANDING_YEAR, ncol = 5) +
  theme_minimal(base_size = 14) +
  theme(strip.text = element_text(size = 10))
ggsave('figures/cum_catch_sector.png', device = 'png', dpi = 500, width = 9, height = 4, units = 'in')

cum_catch_dat |>
  ggplot() +
  geom_line(aes(x = j_day, y = attainment_sector, col = sector)) +
  facet_wrap(~ LANDING_YEAR, scales = 'free_y', ncol = 5) +
  theme_minimal(base_size = 14) +
  theme(strip.text = element_text(size = 10))
ggsave('figures/attain_sector.png', device = 'png', dpi = 500, width = 9, height = 4, units = 'in')

cum_catch_dat |>
  ggplot() +
  geom_line(aes(x = j_day, y = cum_catch)) +
  facet_wrap(~ LANDING_YEAR, ncol = 5) +
  geom_hline(aes(yintercept = VAL), data = rename(quotas, LANDING_YEAR = YEAR)) +
  theme_minimal(base_size = 14) +
  theme(strip.text = element_text(size = 10))
ggsave('figures/cum_catch.png', device = 'png', dpi = 500, width = 9, height = 4, units = 'in')


cum_catch_dat |>
  ggplot() +
  geom_line(aes(x = j_day, y = attainment)) +
  facet_wrap(~ LANDING_YEAR, ncol = 5) +
  ylim(0,1) +
  theme_minimal(base_size = 14) +
  theme(strip.text = element_text(size = 10))
ggsave('figures/attain.png', device = 'png', dpi = 500, width = 9, height = 4, units = 'in')

cum_catch_dat |>
  ggplot(aes(col = LANDING_YEAR, group = LANDING_YEAR)) +
  geom_line(aes(x = j_day, y = attainment)) +
  theme_minimal(base_size = 14) +
  theme(strip.text = element_text(size = 10))
ggsave('figures/cum_attain_color.png', device = 'png', dpi = 500, width = 9, height = 4, units = 'in')

