# load new triennial index run with indexwc/sdmTMB
tri_new <- read.csv("\\\\nwcfile/fram/Assessments/CurrentAssessments/yellowtail_rockfish_north/data/surveys/triennial/delta_gamma/index/est_by_area.csv")
# repurpose area column to indicate which model run
tri_new <- tri_new |> 
  dplyr::filter(area == "North of Cape Mendocino") |> 
  dplyr::mutate(area = "new indexwc")

# load old model (3.30.23 version separates input and adjusted SE in output)
yt1 <- SS_output("Model_Runs/base_2017_3.30.23")
# format old model index to match indexwc output
tri_old <- yt1$cpue |> 
  dplyr::filter(Fleet_name == "Triennial" & Use == 1) |> 
  dplyr::select(Yr, Obs, SE_input) |> 
  dplyr::mutate(area = "old VAST from 2017", .before = "Yr") |> 
  dplyr::rename(year = "Yr", est = Obs, se = SE_input) |> 
  dplyr::mutate(
    lwr = qlnorm(p = 0.025, meanlog = log(est), sdlog = se),
    upr = qlnorm(p = 0.975, meanlog = log(est), sdlog = se),
    log_est = log(est),
    .before = "se"
  ) |> 
  dplyr::mutate(type = "index")

# use indexwc function
index_compare <- indexwc::plot_indices(rbind(tri_new, tri_old)) + 
  ggplot2::scale_color_discrete()  # viridis default yellow was too pale
# replace file saved by indexwc::plot_indices() with viridis colors
ggsave("figures/index_comparisons_triennial_sdmTMB_vs_VAST.png")
