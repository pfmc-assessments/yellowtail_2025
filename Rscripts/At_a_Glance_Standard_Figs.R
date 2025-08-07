library(ggplot2)
library(tidyr)
library(dplyr)
library(stringr)
library(r4ss)

model_output <- r4ss::SS_output(here::here("model_runs", "5.09_no_extra_se"))
model_output_high <- r4ss::SS_output(here::here("model_runs", "6.27_highR0_forecast"))
model_output_low <- r4ss::SS_output(here::here("model_runs", "6.26_lowR0_forecast"))

mymodels <- list(model_output_high,model_output,model_output_low)
mysummary <- SSsummarize(mymodels)

############################################
############################################
#Plot removals figure (front page middle panel)

landings <- model_output$catch |> 
  dplyr::mutate(
    year = Yr,
    catch_mt = dead_bio,
    Fleet = dplyr::case_when(
      Fleet_Name == "At-Sea-Hake" ~ "At-sea hake",
      .default = Fleet_Name)
  )

ggplot(landings,  aes(x = year, y = catch_mt, fill = Fleet)) +
  geom_bar(stat = 'identity') +
  theme_bw() +
  labs(x = "Year", y = "Removals (mt)") +
  xlim(NA, 2025) + 
  scale_y_continuous(
    labels = function(x) format(x, scientific = FALSE)) +
  scale_fill_viridis_d() +
  theme(
    legend.key.height =  unit(0.05, "cm"),
    legend.position = 'inside',
    legend.position.inside = c(0.20, 0.65),
    legend.title=element_text(size = 16), 
    legend.text =  element_text(size = 16),
    axis.text.y =  element_text(angle = 90, vjust = 0.5, hjust = 0.5),
    axis.text =  element_text(size = 19),
    axis.title =  element_text(size = 21)
  )

ggsave(filename = here::here("figures", "at_at_glance", "removals.png"), height = 8/1.7, width = 8, dpi = 500)


############################################
############################################
#Plot stock status with error and states of nature (front page bottom panel)

#make above in ggplot2
bratio_pt <- mysummary[["Bratio"]] %>%
  pivot_longer(
    cols = starts_with("model"),
    names_to = "Model",
    values_to = "Bratio"
  )

bratio_lims <- purrr::map(mysummary[c('BratioLower', 'BratioUpper')], pivot_longer,
                          cols = starts_with('model'), names_to = 'Model', 
                          values_to = 'Bratio'
                          ) |>
  bind_rows(.id = 'lim') |>
  filter(Model == 'model2') |>
  pivot_wider(names_from = lim, values_from = Bratio)

p1 <- ggplot(bratio_pt) +
  geom_ribbon(aes(x = Yr, ymin = BratioLower, ymax = BratioUpper), 
              data = bratio_lims, fill = "blue", alpha = 0.2) +
  geom_line(aes(x = Yr, y = Bratio, color = Model), size = 1.2) +
  labs(x = "Year", y = "Fraction of unfished\nspawning output") +
  lims(x = c(2000, 2037)) +
  scale_color_manual(labels = c("High State of Nature", "Base Model","Low State of Nature"), 
                     values = c("darkolivegreen4", "blue", "brown4")) +
  annotate('rect', xmin = 2025, xmax = 2037, ymin = 0, ymax = 1, alpha = 0.3, fill='gray35') +
  geom_hline(yintercept = 0.25, linetype = "dashed", color = "red", linewidth = 0.7) +
  geom_hline(yintercept = 0.40, linetype = "dashed", color = "red", linewidth = 0.7) +
  annotate(geom = "text", x = 2015, y = 0.41, label = "Management Target", 
           color = "red", vjust = 0, size = 5) +
  annotate(geom = "text", x = 2015, y = 0.26, label = "Minimum Stock Size Threshold", 
           color = "red", vjust = 0, size = 5) +
  annotate(geom="text", x = 2027, y = 0.05, label = "Forecast Period", 
           color = "gray35", hjust = 0, size = 5) +
  annotate(geom = "text", x = 2000, y = 0.02, 
           label = "Blue shading represents 95% uncertainty range\nfor the base model", 
           color = "gray40", hjust = 0, vjust = 0, size = 4) +
  theme_bw() +
  theme(
    # plot.margin = margin(60, 5.5, 5.5, 5.5, unit = 'pt'),
    legend.key.height = unit(0.05, "cm"),
    legend.position = 'inside',
    legend.position.inside = c(0.80, 1),
    legend.title = element_blank(), 
    legend.text = element_text(size = 16),
    axis.text = element_text(size = 19),
    axis.title = element_text(size = 21)
  ) +
  NULL
  
p2 <- ggplot() +
  geom_ribbon(aes(x = Yr, ymin = BratioLower, ymax = BratioUpper), 
              data = bratio_lims, fill = "blue", alpha = 0.2) +
  geom_line(data = bratio_pt, aes(x=Yr,y=Bratio, color = Model), size = 0.8) +
  scale_color_manual(values = c("darkolivegreen4", "blue", "brown4")) +
  annotate('rect', xmin = 2025, xmax = 2037, ymin = 0, ymax = 1.0, alpha = 0.3, fill='gray35') +
  geom_hline(yintercept = 0.25, linetype = "dashed", color = "red", size = 0.5) +
  geom_hline(yintercept = 0.40, linetype = "dashed", color = "red", size = 0.5) +
  theme_bw() +
  theme(
    legend.position = "none",
    axis.text.x = element_text(size = 14),
    axis.text.y = element_blank(),
    axis.title = element_blank(), 
  ) +
  NULL

layout <- c(
  patchwork::area(t = 3, l = 1, b = 17, r = 50),
  patchwork::area(t = 1, l = 2, b = 5, r = 22)
)

p1 + p2 + patchwork::plot_layout(design = layout)

ggsave(filename = here::here("figures", "at_at_glance", "fraction_unfished.png"), height = 8/1.7, width = 8, dpi = 500)


