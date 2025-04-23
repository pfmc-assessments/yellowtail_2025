library(ggplot2)
library(dplyr)
theme_set(theme_classic())

maturity <- readRDS('data/raw_not_confidential/maturity.rds')

maturity |>
  ggplot(aes(x = age)) +
  geom_line(aes(y = p)) +
  geom_point(aes(y = n_mature/n, size = n), alpha = 0.5) +
  xlim(0, max(maturity$age * !is.na(maturity$n)) + 1) +
  labs(x = 'Age (years)', y = 'Proportion mature', size = 'Number of samples')
ggsave('report/figures/maturity_with_data.png', device = 'png')

yt_survey_bio <- nwfscSurvey::pull_bio(common_name = 'yellowtail rockfish', survey = 'NWFSC.Combo') 

yt_n_survey_bio <- filter(yt_survey_bio, Latitude_dd > 40 + 1/6)

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

# looking at how growth varies over space and time
# clear break point in selectivity between age 5 and 6.
filter(yt_n_survey_bio, Age_years <= 20, Age_years >= 6) |>
  ggplot() +
  geom_point(aes(x = Year, y = Length_cm, col = Age_years), alpha = 0.2) +
  stat_smooth(aes(x = Year, y = Length_cm, group = Age_years, col = Age_years), se = FALSE)
# possible decrease in length at age of older fish in last 4 years of data. TBD with 8 more years!

filter(yt_survey_bio, Age_years <= 20, Age_years >= 6) |>
  ggplot() +
  geom_point(aes(x = Latitude_dd, y = Length_cm, col = Age_years), alpha = 0.2) +
  stat_smooth(aes(x = Latitude_dd, y = Length_cm, group = Age_years, col = Age_years), se = FALSE, method = 'lm')
# Larger max size farther north (consistent with theory)

yt_survey_bio |>
  ggplot(aes(x = Latitude_dd, y = Age_years)) +
  geom_point(alpha = 0.1) +
  stat_smooth(se = FALSE)
# Latitudinal age structure: below 43 degrees, avg age ~10, above 45 degrees, avg age ~15

ggplot(yt_n_survey_bio) +
  geom_point(aes(x = Age_years, y = Length_cm, col = Sex), alpha = 0.1)
# Large fish female, old fish male prevails, but not as notable as with canary.

yt_n_survey_bio |>
  group_by(Age_years) |>
  summarise(pct_f = sum(Sex == 'F')/n(),
            se = sqrt(pct_f * (1-pct_f) / n())) |>
  ggplot() +
  geom_point(aes(x = Age_years, y = pct_f)) +
  geom_errorbar(aes(x = Age_years, ymin = pct_f - se, ymax = pct_f + se))

laa_by_lat_lm <- lm(Length_cm ~ I(Latitude_dd-mean(Latitude_dd))*factor(Age_years), 
                    data = yt_n_survey_bio, 
                    subset = Age_years < 20 & Age_years >= 6)

laa_by_age <- lm(Length_cm ~ factor(Age_years), data = yt_n_survey_bio, 
                 subset = Age_years < 20 & Age_years >= 6)

W_L_pars <- yt_n_survey_bio |> nwfscSurvey::estimate_weight_length()

write.csv(W_L_pars, here('Data/Processed/W_L_pars.csv'), row.names = FALSE)

### Megan this is where I look at time-varying weight-length
W_L_pars |>
  dplyr::mutate(out.dfr = purrr::map2(A, B, ~ dplyr::tibble(len = 1:max(yt_n_survey_bio$Length_cm, na.rm = TRUE), 
                                                            wgt = 1000 * .x*len^.y))) |>
  tidyr::unnest(out.dfr) |>
  dplyr::filter(Sex != 'B') |>
  ggplot() +
  geom_point(aes(x = Length_cm, y = Weight, col = Sex), alpha = 0.15, 
             data = dplyr::filter(yt_n_survey_bio, Sex != 'U')) +
  geom_line(aes(x = len, y = wgt, col = Sex), linewidth = 1) +
  labs(x = 'Length (cm)', y = 'Weight (kg)') +
  scale_color_manual(values = c('F' = 'red', 'M' = 'blue')) +
  facet_wrap(~ Year) 

yt_n_survey_bio |>
  dplyr::filter(!is.na(Length_cm), !is.na(Weight_kg)) %>%
  broom::augment(lm(log(Weight_kg) ~ log(Length_cm), data = .),
                 .) |>
  group_by(Year) |>
  summarise(mean_resid = mean(.resid)) |>
  ggplot() +
  geom_line(aes(x = Year, y = mean_resid)) +
  geom_hline(yintercept = 0)
