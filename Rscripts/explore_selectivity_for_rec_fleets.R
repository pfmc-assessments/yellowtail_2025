# compare rec selectivity separate or mirrored
yt1 <- SS_output("Model_Runs/base_2017_3.30.23")
yt2 <- SS_output("Model_Runs/2017_plus_mirror_rec_selex")

png("figures/explore_selectivity_for_rec_fleets.png",
  width = 6.5, height = 6.5, res = 300, units = "in"
)
par(mfrow = c(2, 1))
SSplotSelex(yt1c,
  subplots = 1, fleets = 3:4, years = 1900:2025,
  mar = c(2, 2, 1, 1), legendloc = "topleft"
)
SSplotSelex(yt2,
  subplots = 1, fleets = 3:4, years = 1900:2025,
  mar = c(2, 2, 1, 1), legendloc = NA
)
dev.off()

# calculate fraction of catch from rec fleets
catch_by_fleet <- yt1$timeseries |>
  dplyr::filter(Yr < 2017) |>
  dplyr::select(dplyr::starts_with("dead(B)"))
catch_by_fleet$total <- rowSums(catch_by_fleet)
catch_total_across_years <- colSums(catch_by_fleet)
catch_by_fleet_proportions <- catch_by_fleet
catch_proportion_across_years <- catch_total_across_years
for (i in 1:5) {
  catch_by_fleet_proportions[, i] <- round(catch_by_fleet[, i] /
    catch_by_fleet$total, 3)
  catch_proportion_across_years[i] <- round(catch_total_across_years[i] /
    catch_total_across_years[5], 3)
}

# proportion of total
catch_proportion_across_years
# dead(B):_1 dead(B):_2 dead(B):_3 dead(B):_4      total
#      0.935      0.053      0.009      0.004      1.000

# max proportion among all years
apply(catch_by_fleet_proportions, 2, max, na.rm = TRUE)
# dead(B):_1 dead(B):_2 dead(B):_3 dead(B):_4      total
#      1.000      0.336      0.051      0.044      1.000

SStableComparisons(SSsummarize(list(yt1, yt2)), names = "Bratio_2017")
#              Label      model1      model2
# 1       TOTAL_like 1058.150000 1080.350000
# 2      Survey_like   -3.141660   -3.207830
# 3 Length_comp_like  344.774000  365.853000
# 4    Age_comp_like  808.718000  809.827000
# 5 Parm_priors_like    0.354722    0.342573
# 6      Bratio_2017    0.761776    0.763372

SSplotComps(yt2, plot = FALSE, print = TRUE, subplots = 21, fleets = 3:4, maxrows = 1, pheight = 3, plotdir = "figures")
file.rename("figures/comp_lenfit__aggregated_across_time.png", "figures/comp_lenfit__aggregated_across_time_mirror.png")
SSplotComps(yt1, plot = FALSE, print = TRUE, subplots = 21, fleets = 3:4, maxrows = 1, pheight = 3, plotdir = "figures")

SSplotComps(yt1, plot = FALSE, print = TRUE, subplots = 24, fleets = 3:4, plotdir = "figures")
