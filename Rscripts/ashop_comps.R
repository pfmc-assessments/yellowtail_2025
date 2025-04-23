# Try unexpanded. Catches are low. This is what we did with Canary. If struggling with fits, expand.

ashop_lengths_old <- readxl::read_excel(
  here("Data/Confidential/ASHOP/Oken_YLT_Length data_1976-2023_102824_ASHOP.xlsx"), 
  sheet = "YLT_Length data 1976-1989",
  col_types = c(rep('guess', 4), 'text', rep('guess', 11)))
ashop_lengths_new <- readxl::read_excel(here("Data/Confidential/ASHOP/Oken_YLT_Length data_1976-2023_102824_ASHOP.xlsx"), 
                                        sheet = "YLT_Length data1990-2023", 
                                        col_types = c(rep('guess', 3), 'text', rep('guess', 10)))
ashop_lengths_2024 <- readxl::read_excel('Data/Confidential/ASHOP/Oken_YLT_Length data_2024_020425.xlsx') 

ashop_lengths <- bind_rows(
  select(ashop_lengths_old, Sex = SEX, Length_cm = SIZE_GROUP, FREQUENCY, Year = YEAR, HAUL_JOIN),
  select(ashop_lengths_new, Sex = SEX, Length_cm = LENGTH, FREQUENCY, Year = YEAR, HAUL_JOIN),
  select(ashop_lengths_2024, Sex = SEX, Length_cm = LENGTH, FREQUENCY, Year = YEAR, HAUL_JOIN)
)

ntow <- ashop_lengths |>
  group_by(Year) |>
  summarise(ntow = length(unique(HAUL_JOIN)))

ss3_ashop_comps <- ashop_lengths |> 
  filter(Sex != 'U') |> # most (by orders of magnitude) samples are sexed
  tidyr::uncount(weights = FREQUENCY) |>
  mutate(Age = NA) |> # just to make function work
  as.data.frame() %>% # function does not play with tibbles
  nwfscSurvey::UnexpandedLFs.fn(dir = NULL,
                                datL = ., 
                                lgthBins = len_bin, # sourced above
                                partition = 0, 
                                fleet = 2, 
                                month = 7) |> 
  purrr::pluck('comps') |>
  left_join(ntow, by = c(year = 'Year')) |>
  mutate(Nsamp = ntow) |>
  select(-ntow) |>
  rename_with(~ stringr::str_to_lower(stringr::str_remove(.x, '-')), `F-20`:`M-56`) |>
  arrange(year) # consider filtering out low n

saveRDS(ss3_ashop_comps, file = 'Data/processed/ss3_ashop_comps_2023.rds')

ashop_ages <- readxl::read_excel('Data/Confidential/ASHOP/Oken_YLT_Bio data_ages added_2019-2024_022125.xlsx')

ashop_ages |>
  filter(YEAR != 2020, !is.na(AGE)) |> # only one sample in 2020
  rename(trawl_id = HAUL_JOIN) |>
  as.data.frame() |>
  nwfscSurvey::get_raw_comps(comp_bins = age_bin, comp_column_name = 'AGE', input_n_method = 'tows', two_sex_comps = TRUE,
                             month = 7, fleet = 2, partition = 0, ageerr = 1) |>
  purrr::pluck(1) |>
  saveRDS('Data/processed/ss3_ashop_ages.rds')

# tables for report
length_tab <- ashop_lengths |>
  group_by(Year) |>
  summarise(`ntow length` = length(unique(HAUL_JOIN)),
            `nfish length` = sum(FREQUENCY)) 

age_tab <- ashop_ages |>
  filter(!is.na(AGE), YEAR != 2020) |>
  rename(Year = YEAR) |>
  group_by(Year) |>
  summarise(`ntow age` = length(unique(HAUL_JOIN)),
            `nfish age` = n()) 

left_join(length_tab, age_tab) |>
  mutate(across(everything(), ~tidyr::replace_na(., replace = 0))) |>
  write.csv('report/tables/ashop_comps.csv', row.names = FALSE)
  