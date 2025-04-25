library(ggplot2)
library(dplyr)
theme_set(theme_classic())

# LOAD DATA

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

# MAKE PLOTS

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
  stat_smooth(method = 'loess', col = 'black', se = FALSE) +
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
