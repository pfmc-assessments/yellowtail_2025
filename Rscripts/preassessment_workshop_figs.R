# This script is very much not reproducible! Don't try!

theme_set(theme_classic(base_size = 14))

comm_catch |> tidyr::pivot_longer(-year, names_to = 'State', values_to = 'Landings (mt)') |>
  ggplot() + geom_col(aes(x = year, y = `Landings (mt)`, 
                          fill = factor(State, levels = c('Foreign', 'CA', 'OR', 'WA')))) +
  labs(title = 'Commercial landings through 2023 by state',
       fill = 'State') +
  geom_vline(xintercept = 2016.5, lty = 'dotted') +
  viridis::scale_fill_viridis(discrete = TRUE)

rec_landings |>
  filter(grepl('(mt)', State)) |>
  mutate(State = stringr::str_remove(State, '[:space:]\\(mt\\)')) |>
  ggplot() +
  geom_col(aes(x = RECFIN_YEAR, y = Dead_Catch, fill = factor(State, levels = c('WA', 'OR', 'CA')))) +
  geom_vline(xintercept = 2016.5, lty = 'dotted', linewidth = 1) +
  viridis::scale_fill_viridis(discrete = TRUE) +
  labs(fill = 'State', x = 'Year', y = 'Landings (mt)')

all_landings <- readRDS('Data/processed/ss3_landings_2023.rds')

all_landings |>
  mutate(fleet = case_when(fleet == 1 ~ 'Commercial', 
                           fleet == 2 ~ 'At-sea hake',
                           fleet == 3 ~ 'Recreational')) |>
  ggplot() +
  geom_col(aes(x = year, y = catch, fill = factor(fleet, levels = c('Commercial', 'At-sea hake', 'Recreational')))) +
  labs(x = 'Year', y = 'Landings (mt)', fill = 'Fleet') +
  viridis::scale_fill_viridis(discrete = TRUE) +
  geom_vline(xintercept = 2016.5, linetype = 'dotted', linewidth = 1)


filter(bds_clean, !is.na(length), !is.na(Age)) |> 
  select(FISH_LENGTH, FORK_LENGTH, length, Age) |>
  View()

bds_clean |>
  group_by(year) |>
  summarise(n_length = sum(!is.na(length)),
            `Age and length` = sum(!is.na(Age)),
            `Length only` = n_length - `Age and length`) |> 
  select(-n_length) |>
  tidyr::pivot_longer(-year, names_to = 'Sample type', values_to = 'Count') |>
  ggplot() +
  geom_col(aes(x = year, y = Count, fill = factor(`Sample type`, levels = c('Length only', 'Age and length')))) +
  viridis::scale_fill_viridis(discrete = TRUE) +
  labs(fill = 'Sample type')

bds_clean |> 
  filter(year > 2010) |>
  ggplot() +
  ggridges::geom_density_ridges(aes(x = Age, y = year, group = year), stat = 'binline', alpha = 0.75)

bds_clean |>
  ggplot() +
  geom_density(aes(x = length, fill = state), bw = 10, alpha = 0.5) +
  viridis::scale_fill_viridis(discrete = TRUE)

bds_clean |>
  ggplot() +
  geom_histogram(aes(x = Age, fill = state), position = 'dodge') +
  viridis::scale_fill_viridis(discrete = TRUE)

bds_clean |>
  group_by(year) |>
  summarise(mn_size = mean(lengthcm, na.rm = TRUE),
            sd_size = sd(lengthcm, na.rm = TRUE)) |>
  ggplot(aes(x = year, y = mn_size)) +
  geom_errorbar(aes(ymin = mn_size + sd_size, ymax = mn_size  - sd_size)) +
  geom_point() + geom_line() +
  ylab('Mean length (cm)')

bds_clean |>
  group_by(year) |>
  summarise(mn_size = mean(Age, na.rm = TRUE),
            sd_size = sd(Age, na.rm = TRUE)) |>
  ggplot(aes(x = year, y = mn_size)) +
  geom_errorbar(aes(ymin = mn_size + sd_size, ymax = mn_size  - sd_size)) +
  geom_point() + geom_line() +
  ylab('Mean age (yrs)')

bind_rows(
  list(
    comm = {bds_clean |>
        select(length_cm = lengthcm, sex = SEX, year) 
    },
    rec = {rec_bio_cleaned |>
        select(year, sex, length_cm)
    },
    hake = {ss3_ashop_comps |>
        select(sex = Sex, length_cm = Length_cm, year = Year)
    }
    ), .id = 'fleet'
  ) |>
  ggplot() +
  geom_density(aes(x = length_cm, fill = fleet), bw = 1, alpha = 0.5) +
  viridis::scale_fill_viridis(discrete = TRUE)

ggplot(bds_clean) +
  geom_density(aes(x = lengthcm), bw = 1, alpha = 0.5)

ss3_ashop_comps |>
  group_by(Year) |>
  summarise(`# lengths` = n()) |>
  ggplot() +
  geom_col(aes(x = Year, y = `# lengths`)) 

bind_rows(list(
  length = rec_bio_cleaned,
  age = rec_ages_cleaned),
  .id = 'type'
  ) |>
  count(type, year) |> 
  tidyr::pivot_wider(names_from = type, values_from = n) |>
  mutate(`length only` = length - age) |>
  select(-length) |>
  tidyr::pivot_longer(cols = -year, names_to = 'Sample type', values_to = 'Count') |>
  ggplot() +
  geom_col(aes(x = year, y = Count, fill = factor(`Sample type`, levels = c('length only', 'age')))) +
  labs(fill = 'Sample type') +
  viridis::scale_fill_viridis(discrete = TRUE)

yt_n_survey_bio |>
  group_by(Year) |>
  summarise(`age and length` = sum(!is.na(Age_years)),
            n_length = sum(!is.na(Length_cm)),
            `length only` = n_length - `age and length`) |>
  select(-n_length) |>
  tidyr::pivot_longer(-Year, names_to = 'Sample type', values_to = 'Count') |>
  ggplot() +
  geom_col(aes(x = Year, y = Count, fill = factor(`Sample type`, levels = c('length only', 'age and length')))) +
  labs(fill = 'Sample type', title = 'WCGBTS') +
  viridis::scale_fill_viridis(discrete = TRUE)

bind_rows(
  list(
    length = { yt_n_tri_bio$length_data |>
        select(Year, measurement = Length_cm)
    },
    `age and length` = { yt_n_tri_bio$age_data |>
        select(Year, measurement = Age_years)
    }),
  .id = 'Sample type') |> 
  count(Year, `Sample type`) |>
  tidyr::pivot_wider(names_from = `Sample type`, values_from = n) |>
  mutate(`length only` = length - `age and length`) |>
  select(-length) |>
  tidyr::pivot_longer(-Year, names_to = 'Sample type', values_to = 'Count') |>
  ggplot() +
  geom_col(aes(x = Year, y = Count, fill = factor(`Sample type`, levels = c('length only', 'age and length'))), width = 1) +
  labs(fill = 'Sample type', title = 'Triennial') +
  viridis::scale_fill_viridis(discrete = TRUE)

bds_clean |>
  filter(geargroup != 'XXX') |>
  mutate(gear = ifelse(geargroup == 'TWL' | geargroup == 'TWL', 'TWL + TWS', 'Non-TWL')) |>
  ggplot() +
  geom_density(aes(x = length, fill = gear), bw = 20, alpha = 0.5)
