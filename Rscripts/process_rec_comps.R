# process rec comps

# code copied from rec bio section of /docs/data_summary_doc.qmd
# then modified and expanded


# dir("Data/Confidential/Rec")

# # files with rec catch
# "CTE501-WASHINGTON-1990---2023.csv"         
# "Oregon Recreational landings_433_2023.csv" 

# # files with MRFSS bio data
# "MRFSS_BIO_2025 CYCLE_433.csv"              # rec bio from OR
# "MRFSS_lengths_CA_WA.csv"                   # rec bio from WA & OR

# # files with bio data from RECFIN
# "RecFIN_ages.csv"
# "RecFIN_CA_MRFSS.csv"
# "RecFIN_lengths.csv"                        

# # other files with bio data
# "ytrk_sport_biodata.csv"                    # rec bio from WA

# recent length data
rec_bio <- read.csv(here("Data/Confidential/rec/RecFIN_Lengths.csv")) |>
  tibble::as_tibble() |>
  filter(STATE_NAME == "OREGON" | STATE_NAME == "WASHINGTON" | grepl("REDWOOD", RECFIN_PORT_NAME))

recfin_ages <- read.csv(here("Data/Confidential/rec/RecFIN_Ages.csv")) |>
  tibble::as_tibble()

# or mrfss data
or_mrfss <- read.csv(here("Data/Confidential/rec/MRFSS_BIO_2025 CYCLE_433.csv")) |>
  tibble::as_tibble()

or_mrfss_smry <- or_mrfss |> 
  filter(Length_Flag == 'measured') |>
  group_by(Year) |> 
  summarise(n_length = n()) |>
  mutate(STATE_NAME = 'OR (MRFSS)') |>
  tidyr::pivot_wider(names_from = STATE_NAME, values_from = n_length)

# ca/wa mrfss data
ca_wa_mrfss <- read.csv(here("Data/Confidential/rec/MRFSS_lengths_CA_WA.csv")) |>
  as_tibble() |> 
  filter(ST_NAME == 'Washington' | (ST_NAME == 'California' & (CNTY == 15 | CNTY == 23))) |> # 15 = Del Norte, 23 = Humboldt, FIPS codes
  filter(T_LEN %% 1 == 0 | LNGTH %% 1 == 0) # I believe this will filter to measured lengths

ca_wa_mrfss_smry <- ca_wa_mrfss |>
  group_by(YEAR, ST_NAME) |>
  summarise(n_length = n()) |>
  ungroup() |>
  mutate(state = case_when(ST_NAME == 'California' ~ 'CA (MRFSS)',
                           ST_NAME == 'Washington' ~ 'WA (MRFSS)')) |>
  tidyr::pivot_wider(names_from = state, values_from = n_length, id_cols = YEAR, values_fill = 0) |>
  rename(Year = YEAR)

# separate file shared by WDFW via Google Drive:
rec_bio_wa <- read.csv(here("Data/Confidential/rec/ytrk_sport_biodata.csv"))
rec_bio_wa_smry <- rec_bio_wa |>
  dplyr::rename(Year = sample_year) |>
  group_by(Year) |> 
  summarise(n_length = n()) |>
  mutate(STATE_NAME = 'WA (GDrive)') |>
  tidyr::pivot_wider(names_from = STATE_NAME, values_from = n_length)

# subset of WDFW-provided data with ages
rec_bio_wa_age_smry <- rec_bio_wa |>
  filter(!is.na(best_age)) |>
  dplyr::rename(Year = sample_year) |>
  group_by(Year) |> 
  summarise(n_length = n()) |>
  mutate(STATE_NAME = 'WA (GDrive)') |>
  tidyr::pivot_wider(names_from = STATE_NAME, values_from = n_length)

# plot distributions from RecFIN data
rec_bio |>
  ggplot() +
  geom_density(aes(x = RECFIN_LENGTH_MM, col = STATE_NAME, fill = IS_RETAINED), 
               linewidth = 1, alpha = 0.2) +
  scale_fill_manual(values = c('red', 'blue')) +
  labs('RecFIN length compositions by state and disposition') +
  viridis::scale_color_viridis(discrete = TRUE) 

# summary sample sizes of length data by source
# Note: 1993 uses total length. 1994 onward uses fork length.
rec_bio_smry_table <- rec_bio |>
  filter(!is.na(RECFIN_LENGTH_MM)) |> 
  mutate(state = case_when(STATE_NAME == 'WASHINGTON' ~'WA',
                           STATE_NAME == 'OREGON' ~ 'OR',
                           STATE_NAME == 'CALIFORNIA' ~ 'CA')) |>
  group_by(RECFIN_YEAR, state, IS_RETAINED) |>
  summarize(n_length = n()) |>
  rename(Year = RECFIN_YEAR) |> 
  tidyr::pivot_wider(names_from = c(state, IS_RETAINED), values_from = n_length, 
                     values_fill = 0) |> 
  full_join(or_mrfss_smry) |>        # OR MRFSS data
  full_join(ca_wa_mrfss_smry) |>     # CA and WA MRFSS data
  full_join(rec_bio_wa_smry) |>      # add in WA data from Google Drive
  arrange(Year) |>                   # order by year
  mutate(across(everything(), ~tidyr::replace_na(.x, 0)))

# table showing all sources of rec length data and retained vs. released
rec_bio_smry_table |> 
  knitr::kable(align = 'l')

# table showing only WA length sample sizes
rec_bio_smry_table |> 
  rename("WA (RecFIN)" = WA_RETAINED) |>
  select("WA (GDrive)", "WA (RecFIN)", "WA (MRFSS)") |>
  knitr::kable(align = 'l')

# temporarily pasting results prior to integration into Quarto doc

# |Year |WA (GDrive) |WA (RecFIN) |WA (MRFSS) |
# |:----|:-----------|:-----------|:----------|
# |1979 |11          |0           |0          |
# |1980 |0           |0           |224        |
# |1981 |28          |0           |131        |
# |1982 |9           |0           |61         |
# |1983 |0           |0           |34         |
# |1984 |0           |0           |24         |
# |1985 |0           |0           |50         |
# |1986 |0           |0           |22         |
# |1987 |0           |0           |39         |
# |1988 |0           |0           |14         |
# |1989 |0           |0           |1          |
# |1993 |0           |3           |0          |
# |1994 |0           |34          |0          |
# |1995 |13          |26          |0          |
# |1996 |6           |27          |5          |
# |1997 |137         |147         |8          |
# |1998 |0           |53          |130        |
# |1999 |5           |23          |9          |
# |2000 |0           |0           |3          |
# |2001 |0           |0           |5          |
# |2002 |194         |194         |3          |
# |2003 |800         |800         |0          |
# |2004 |675         |675         |0          |
# |2005 |869         |869         |0          |
# |2006 |362         |362         |0          |
# |2007 |313         |313         |0          |
# |2008 |190         |189         |0          |
# |2009 |464         |464         |0          |
# |2010 |218         |218         |0          |
# |2011 |391         |391         |0          |
# |2012 |228         |228         |0          |
# |2013 |358         |356         |0          |
# |2014 |680         |680         |0          |
# |2015 |683         |683         |0          |
# |2016 |928         |928         |0          |
# |2017 |1319        |1326        |0          |
# |2018 |905         |908         |0          |
# |2019 |1798        |1800        |0          |
# |2020 |891         |891         |0          |
# |2021 |827         |831         |0          |
# |2022 |669         |669         |0          |
# |2023 |1534        |1534        |0          |
# |2024 |1279        |0           |0          |

# table of age sample sizes
rec_ages_smry_table <- recfin_ages |>
  mutate(state = case_when(SAMPLING_AGENCY_NAME == 'WDFW' ~'WA (RecFIN)',
                           SAMPLING_AGENCY_NAME == 'ODFW' ~ 'OR (RecFIN)',
                           TRUE ~ "OTHER")) |> # there shouldn't be any other states
  group_by(SAMPLE_YEAR, state) |>
  summarize(n_length = n()) |>
  rename(Year = SAMPLE_YEAR) |> 
  tidyr::pivot_wider(names_from = c(state), values_from = n_length, 
                     values_fill = 0) |> 
  full_join(rec_bio_wa_age_smry) |>  # add in WA data from Google Drive
  arrange(Year) |>                   # order by year
  mutate(across(everything(), ~tidyr::replace_na(.x, 0))) |> 
  select("WA (GDrive)", "WA (RecFIN)", "OR (RecFIN)")

rec_ages_smry_table |> 
  knitr::kable(align = 'r')

# temporarily pasting results prior to integration into Quarto doc

# | Year| WA (GDrive)| WA (RecFIN)| OR (RecFIN)|
# |----:|-----------:|-----------:|-----------:|
# | 1997|         100|         100|           0|
# | 1999|           0|           0|         327|
# | 2000|           0|           0|         192|
# | 2001|           0|           0|          12|
# | 2006|          18|          18|           0|
# | 2009|           6|           7|           0|
# | 2010|          17|          17|           0|
# | 2011|          15|          15|           0|
# | 2013|           0|           4|           0|
# | 2014|         533|         533|           0|
# | 2015|         624|         624|           0|
# | 2016|         836|         836|           0|
# | 2017|        1150|        1150|           0|
# | 2018|         641|         645|           0|
# | 2019|        1306|        1311|           0|
# | 2020|         882|         882|           0|
# | 2021|         683|         695|           0|
# | 2022|         613|         615|           0|
# | 2023|        1247|        1251|           0|
# | 2024|         613|           0|           0|