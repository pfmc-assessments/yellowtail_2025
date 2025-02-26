# Canadian yellowtail rockfish assessment from 2024
# SS3 input files stored at 
# https://github.com/pbs-software/pbs-synth/tree/master/PBSsynth/inst/input/2024/YTR/BC/Base/B1.R02v2/02.01

require(r4ss)

m2.05 = SS_output('Model_Runs/2.05_data_deadline_comps/')
can2024 <- SS_output('C:\\Users\\ian.taylor\\Documents\\reviews\\2024_DFO_yellowtail\\models\\02.01')

summary <- SSsummarize(list(m2.05, can2024))

cor(summary$recdevs$model1, summary$recdevs$model2, use = "complete.obs")
# [1] 0.6205295

ggplot(summary$recdevs, aes(x = model2, y = model1, color = Yr, label = Yr)) + 
  geom_point() +
  geom_text(hjust = 0, nudge_x = 0.05) + 
  geom_abline(slope = 1, intercept = 0) +
  scale_color_viridis_c(direction = -1) +
  xlab("recruit dev from Canadian model from 2024") + 
  ylab("recruit dev from U.S. model (in-prep model 2.05)") +
  xlim(-1, 2) + 
  ylim(-1, 2)

ggsave("figures/recdevs_Canada_vs_US.png", width = 7, height = 7)

dir.create("figures/Canada_vs_US")
SSplotComparisons(summary, png = TRUE, plot = FALSE,
  legendlabels = c("U.S. model (in-prep model 2.05)", "Canadian model from 2024"),
  plotdir = "figures/Canada_vs_US")
