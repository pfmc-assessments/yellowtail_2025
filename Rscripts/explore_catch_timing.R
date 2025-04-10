load(here('data/confidential/commercial/pacfin-2025-03-03/PacFIN.YTRK.CompFT.03.Mar.2025.RData'))
# I have checked and LANDING_YEAR = PACFIN_YEAR for all rows.

yt_n_catch_pacfin <- catch.pacfin |>
  filter(
    AGENCY_CODE == 'W' | AGENCY_CODE == 'O' | COUNTY_NAME == 'DEL NORTE' | COUNTY_NAME == 'HUMBOLDT', # OR, WA, N. CA
    LANDING_YEAR < 2025
  )

z <- yt_n_catch_pacfin |> 
  dplyr::group_by(LANDING_YEAR, LANDING_MONTH) |> 
  dplyr::summarize(total_landings_mt = sum(LANDED_WEIGHT_MTONS))
z |> ggplot() + 
  geom_col(aes(x = LANDING_MONTH, y = total_landings_mt)) + 
  facet_wrap(vars(LANDING_YEAR))

z <- yt_n_catch_pacfin |> 
  dplyr::group_by(LANDING_MONTH) |> 
  dplyr::summarize(total_landings_mt = sum(LANDED_WEIGHT_MTONS))
z |> ggplot() + 
  geom_col(aes(x = LANDING_MONTH, y = total_landings_mt)) +
  scale_x_discrete(labels = 1:13)
  
ggsave("figures/catch-timing.png")
