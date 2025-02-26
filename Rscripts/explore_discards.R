# explore GEMM and create time series of discards to include in the model
# explore Pikitch data and calculate rate that could be applied to early years
# see also \Rscripts\model_remove_retention.R


# pull new GEMM data from warehouse
if (FALSE) {
  # allow pull_gemm() to work on Ian's computer using stuff from the following:
  # https://github.com/pfmc-assessments/nwfscSurvey/issues/165
  # https://github.com/HenrikBengtsson/startup/blob/develop/R/is_radian.R
  if (nzchar(Sys.getenv("RADIAN_VERSION"))) {
    Sys.setlocale("LC_ALL", Sys.getenv("LANG"))
  }
  # run function to extract GEMM table
  gemm <- nwfscSurvey::pull_gemm(common_name = "Yellowtail Rockfish", dir = "Data/Processed/")
} else {
  # load previously extracted GEMM table (saved as variable "gemm")
  load("Data/Processed/gemm_Yellowtail_Rockfish.rdata")
}

table(gemm$grouping)
### NOTE: removed degree symbol from line below due to UTF-8 issue with styler
# Minor shelf rockfish (South of 4010' N. lat.)                    Yellowtail rockfish (Coast)  Yellowtail rockfish (North of 4010' N. lat.)
#                                            179                                              2                                            393

# the only catch NOT assigned to North or South is research catch in 2007-08 where there were NO discards
gemm |> dplyr::filter(grepl("Coast", grouping))
#   cv                    grouping   sector             species total_discard_and_landings_mt total_discard_mt
# 1 NA Yellowtail rockfish (Coast) Research Yellowtail Rockfish                      3.293030                0
# 2 NA Yellowtail rockfish (Coast) Research Yellowtail Rockfish                      4.307944                0
#   total_discard_with_mort_rates_applied_and_landings_mt total_discard_with_mort_rates_applied_mt total_landings_mt       type year
# 1                                              3.293030                                        0                 0 groundfish 2008
# 2                                              4.307944                                        0                 0 groundfish 2007


# filter to northern area only and sector2 which is a courses grouping of sector
gemm2 <- gemm |>
  dplyr::filter(grepl("North", grouping)) |>
  dplyr::mutate(
    sector2 =
      dplyr::case_when(
        grepl("At-Sea Hake", sector) ~ "At-Sea Hake",
        grepl("Limited Entry Trawl", sector) ~ "LE/CS Trawl",
        grepl("CS", sector) & grepl("Trawl", sector) ~ "LE/CS Trawl",
        grepl("Midwater Rockfish", sector) ~ "Midwater Rockfish",
        grepl("Midwater Hake", sector) ~ "Midwater Hake",
        grepl("Recreational", sector) ~ "Recreational",
        TRUE ~ "Other"
      ),
    fleet = dplyr::case_when(
        grepl("At-Sea Hake", sector) ~ "At-Sea-Hake",
        grepl("Recreational", sector) ~ "Recreational",
        TRUE ~ "Commercial"
      )
  )

# barplot of discards for all sectors
gemm2 |>
  group_by(sector, year) |>
  ggplot() +
  geom_col(aes(x = year, y = total_discard_mt, fill = sector))
# ggtitle("") +
# labs(fill = "", x = "") #+

# barplot of discards by grouped sectors
gemm2 |>
  group_by(sector2, year) |>
  ggplot() +
  geom_col(aes(x = year, y = total_discard_mt, fill = sector2))

# barplot of discards by fleets in the model
gemm2 |>
  group_by(fleet, year) |>
  ggplot() +
  geom_col(aes(x = year, y = total_discard_mt, fill = fleet))

# summary table of discards by sector
gemm2 |>
  dplyr::group_by(sector) |>
  dplyr::summarize(catch = sum(total_discard_with_mort_rates_applied_mt)) |>
  arrange(desc(catch)) |>
  print(n = 20)
# # A tibble: 29 x 2
#    sector                             catch
#    <chr>                              <dbl>
#  1 At-Sea Hake MSCV                834.
#  2 At-Sea Hake CP                  368.
#  3 Limited Entry Trawl             123.
#  4 Midwater Hake                    13.1
#  5 Midwater Rockfish                12.1
#  6 Midwater Hake EM                 10.5
#  7 Washington Recreational           9.38
#  8 Pink Shrimp                       7.73
#  9 Oregon Recreational               6.31
# 10 Midwater Rockfish EM              6.25
# 11 LE Sablefish - Hook & Line        6.20
# 12 Nearshore                         5.61
# 13 Tribal At-Sea Hake                4.40
# 14 CS - Bottom Trawl                 1.80
# 15 OA Fixed Gear - Hook & Line       1.73
# 16 LE Fixed Gear DTL - Hook & Line   0.530
# 17 California Recreational           0.453
# 18 CS - Hook & Line                  0.0439
# 19 Directed P Halibut                0.0409
# 20 CS - Bottom and Midwater Trawl    0.0370
# # i 9 more rows
# # i Use `print(n = ...)` to see more rows

# summary by sector groups
gemm2 |>
  dplyr::group_by(sector2) |>
  dplyr::summarize(catch = sum(total_discard_with_mort_rates_applied_mt)) |>
  arrange(desc(catch)) |>
  print(n = 20)
#   sector2            catch
#   <chr>              <dbl>
# 1 At-Sea Hake       1206.
# 2 LE/CS Trawl        125.
# 3 Midwater Hake       23.6
# 4 Other               21.9
# 5 Midwater Rockfish   18.3
# 6 Recreational        16.1

# table by modeled fleet / year
dead_discards <- gemm2 |>
  dplyr::group_by(year, fleet) |>
  dplyr::summarize(catch = sum(total_discard_with_mort_rates_applied_mt))
saveRDS(dead_discards, file = "Data/Processed/gemm_discards_by_fleet.rds")

# load package for river plots
require(ggalluvial)

# river plot showing grouping of sectors
ggplot(
  data = gemm2,
  aes(
    axis1 = sector, axis2 = sector2,
    y = total_discard_with_mort_rates_applied_mt
  )
) +
  # scale_x_discrete(limits = c("Class", "Sex", "Age"), expand = c(.2, .05)) +
  # xlab("Demographic") +
  geom_alluvium(aes(fill = sector)) +
  geom_stratum() +
  geom_text(stat = "stratum", min.y = 10, aes(label = after_stat(stratum))) +
  theme(legend.position = "none") +
  theme_minimal() #+


# longer dataframe with a column for fate
gemm3 <- rbind(
  gemm2 |> dplyr::mutate(
    fate = "retained",
    catch_mt = total_landings_mt
  ),
  gemm2 |> dplyr::mutate(
    fate = "discarded",
    catch_mt = total_discard_mt
  )
)

# longer dataframe with a column for fate
gemm3 <- rbind(
  gemm2 |> dplyr::mutate(
    fate = "retained",
    catch_mt = total_landings_mt
  ),
  gemm2 |> dplyr::mutate(
    fate = "discarded dead",
    catch_mt = total_discard_with_mort_rates_applied_mt
  ),
  gemm2 |> dplyr::mutate(
    fate = "discarded alive",
    catch_mt = total_discard_mt - total_discard_with_mort_rates_applied_mt
  )
)

# river plot showing discard vs retained
ggplot(
  data = gemm3,
  aes(
    axis1 = sector2, axis2 = fate,
    y = catch_mt
  )
) +
  scale_x_discrete(limits = c("Sector group", "retention"), expand = c(.2, .05)) +
  ylab("Catch (mt)") +
  geom_alluvium(aes(fill = sector2)) +
  geom_stratum() +
  geom_text(stat = "stratum", aes(label = after_stat(stratum))) +
  theme_classic() +
  labs(fill = "Sector group") +
  ggtitle(
    "Discards from GEMM (2002-2023)",
    "stratified by sector group and retention"
  ) +
  theme(legend.position = "none")

ggsave("figures/discards_from_GEMM_river_plot.png")

### Pikitch data

# load file shared by John Wallace via 
# \\nwcfile\FRAM\Assessments\CurrentAssessments\yellowtail_rockfish_north\Pikitch et al. Discard Study (1995-87) Analysis
load("Data/Confidential/Pikitch et al. Discard Study (1995-87) Analysis/Discard Rates/Pikitch.et.al.Yellowtail.Discards.Rates 4 Dec 2024.RData")

# filter to get rates for all areas (none of these are in California)
pikitch <- Pikitch.et.al.Yellowtail.Discards.Rates |> dplyr::filter(Areas == "2B 2C 3A 3B 3S")

# discard rates are pretty stable without a strong trend (based on plot)
range(pikitch$DiscardRate.Sp.Wt.Wgting)
# [1] 0.0368 0.0542
(rate <- round(mean(pikitch$DiscardRate.Sp.Wt.Wgting), 4))
# [1] 0.0451
