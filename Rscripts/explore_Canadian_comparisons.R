# Canadian yellowtail rockfish assessment from 2024
# SS3 input files stored at 
# https://github.com/pbs-software/pbs-synth/tree/master/PBSsynth/inst/input/2024/YTR/BC/Base/B1.R02v2/02.01
# but need to be run locally to get output

require(r4ss)
require(ggplot2)

# load base model from elsewhere 
can2024 <- SS_output('C:/Users/ian.taylor/Documents/reviews/2024_DFO_yellowtail/models/02.01')

# note: "model" object is created in \Rscripts\make_r4ss_figs_tables.R from current base model
summary <- SSsummarize(list(model, can2024))

# get first year of main recdevs (currently 1962)
main_recdev_start <- model$recruit |> 
  dplyr::filter(era == "Main") |> 
  dplyr::pull(Yr) |> 
  min()

# correlations for all years, or just years form main period onward
cor(summary$recdevs$model1, summary$recdevs$model2, use = "complete.obs")
# [1] 0.6170315
cor(summary$recdevs$model1[summary$recdevs$Yr >= main_recdev_start], 
    summary$recdevs$model2[summary$recdevs$Yr >= main_recdev_start], use = "complete.obs")
# [1] 0.6124846


# make plot
summary$recdevs |>
  dplyr::filter(Yr >= main_recdev_start) |>
  ggplot(aes(x = model2, y = model1, color = Yr, label = Yr)) +
  geom_point() +
  geom_text(hjust = 0, nudge_x = 0.05) +
  geom_abline(slope = 1, intercept = 0) +
  scale_color_viridis_c(direction = -1) +
  xlab("recruit dev from Canadian model from 2024") +
  ylab("recruit dev from U.S. base model") +
  xlim(-1, 2) +
  ylim(-1, 2) +
  stat_smooth(method = 'lm') +
  theme_classic()
ggsave("report/Figures/Canada_vs_US_recdevs.png", width = 7, height = 7)

r4ss::plot_twopanel_comparison(
  mods = list(model, can2024),
  subplot1 = 4,
  subplot2 = 11,
  legendlabels = c("U.S. base model", "Canadian model from 2024"),
  file = "Canada_vs_US_timeseries.png",
  endyrvec = c(2025, 2024),
  xlim = c(1940, 2025),
  dir = "report/Figures/"
)
