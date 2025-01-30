```{r pacfin-catch, cache=TRUE}
load(here('data/confidential/commercial/pacfin_12-11-2024/PacFIN.YTRK.CompFT.11.Dec.2024.RData'))
# I have checked and LANDING_YEAR = PACFIN_YEAR for all rows.

yt_n_catch_pacfin <- catch.pacfin |>
  filter(
    AGENCY_CODE == 'W' | AGENCY_CODE == 'O' | COUNTY_NAME == 'DEL NORTE' | COUNTY_NAME == 'HUMBOLDT', # OR, WA, N. CA
    LANDING_YEAR < 2024
  )


# landings by tribal vs non-tribal
yt_n_catch_pacfin |>
  group_by(PARTICIPATION_GROUP_NAME, LANDING_YEAR) |>
  summarise(catch_mt = sum(ROUND_WEIGHT_MTONS)) |>
  ggplot() +
  geom_col(aes(x = LANDING_YEAR, y = catch_mt, fill = PARTICIPATION_GROUP_NAME)) +
  ggtitle('PacFIN landings by participation group') +
  labs(fill = 'PARTICIPATION_GROUP_NAME', y = "Landings (mt)", x = 'Year') +
  theme_grey(base_size = 14)