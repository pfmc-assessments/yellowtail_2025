library(ggplot2)
library(dplyr)
theme_set(theme_classic())

maturity <- readRDS('data/raw_not_confidential/maturity.rds')

maturity |>
  ggplot(aes(x = age)) +
  geom_line(aes(y = p)) +
  geom_point(aes(y = n_mature/n, size = n), alpha = 0.5) +
  xlim(0, max(maturity$age * !is.na(maturity$n)) + 1) +
  labs(x = 'Age (years)', y = 'Proportion mature', size = 'Number of samples')
ggsave('report/figures/maturity_with_data.png', device = 'png')
