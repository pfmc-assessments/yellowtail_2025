# bds_clean is from Rscripts/commercial_comps.R
bds_clean |>
  group_by(year) |>
  summarise(
    n_length = sum(!is.na(length)),
    `Age and length` = sum(!is.na(Age)),
    `Length only` = n_length - `Age and length`
  ) |>
  select(-n_length) |>
  tidyr::pivot_longer(-year, names_to = "Sample type", values_to = "Count") |>
  ggplot() +
  geom_col(aes(x = year, y = Count, fill = factor(`Sample type`, levels = c("Length only", "Age and length")))) +
  viridis::scale_fill_viridis(discrete = TRUE) +
  # ggtitle("Commercial Biological Samples by Year") +
  labs(fill = "Sample type") +
  theme(legend.position = "top")
ggsave(
  filename = "report/figures/comp_samples_comm.png",
  width = 6.5, height = 3.5
)

# # get length and age sample sizes from tables
# commlengths <- read.csv("report/Tables/pacfin_lengths.csv")
# commages <-read.csv("report/Tables/pacfin_ages.csv")

ashop_comps <- read.csv("report/tables/ashop_comps.csv")
ashop_comps |>
  dplyr::select(Year, nfish.length, nfish.age) |>
  rename(year = Year, `Length only` = nfish.length, `Age and length` = nfish.age) |>
  tidyr::pivot_longer(-year, names_to = "Sample type", values_to = "Count") |>
  ggplot() +
  geom_col(aes(x = year, y = Count, fill = factor(`Sample type`, levels = c("Length only", "Age and length")))) +
  viridis::scale_fill_viridis(discrete = TRUE) +
  # ggtitle("At-Sea Hake Biological Samples by Year") +
  labs(fill = "Sample type") +
  theme(legend.position = "top")
ggsave(
  filename = "report/figures/comp_samples_ashop.png",
  width = 6.5, height = 3.5
)


rec_bio_table <- read.csv("Data/Processed/rec_bio_sample_size_table.csv", check.names = FALSE)
rec_bio_table |>
  rename(
    year = Year,
    WA = Washington,
    OR = Oregon,
    CA = California,
    `WA ages` = `Washington ages`
  ) |>
  dplyr::mutate(`WA length only` = WA - `WA ages`) |>
  dplyr::select(-WA) |>
  dplyr::rename(`WA age and length` = `WA ages`) |>
  tidyr::pivot_longer(-year, names_to = "Sample type", values_to = "Count") |>
  ggplot() +
  geom_col(aes(
    x = year, y = Count,
    fill = factor(`Sample type`, levels = c("CA", "OR", "WA length only", "WA age and length"))
  )) +
  viridis::scale_fill_viridis(discrete = TRUE) +
  # ggtitle("Recreational Biological Samples by Year") +
  labs(fill = "Sample type") +
  theme(legend.position = "top")
ggsave(
  filename = "report/figures/comp_samples_rec.png",
  width = 6.5, height = 3.5
)

wcgbts_bio_table <- read.csv("Data/Processed/input_n_wcgbts.csv", check.names = FALSE)
wcgbts_bio_table |>
  dplyr::mutate(dplyr::across(dplyr::everything(), ~ tidyr::replace_na(., 0))) |>
  dplyr::select(year, n_ages, n_lengths) |>
  dplyr::mutate(`Length only` = n_lengths - n_ages) |>
  dplyr::select(-n_lengths) |>
  dplyr::rename(`Age and length` = n_ages) |>
  tidyr::pivot_longer(-year, names_to = "Sample type", values_to = "Count") |>
  ggplot() +
  geom_col(aes(x = year, y = Count, fill = factor(`Sample type`, levels = c("Length only", "Age and length")))) +
  viridis::scale_fill_viridis(discrete = TRUE) +
  # ggtitle("WCGBTS Biological Samples by Year") +
  labs(fill = "Sample type") +
  theme(legend.position = "top")
ggsave(
  filename = "report/figures/comp_samples_wcgbts.png",
  width = 6.5, height = 3.5
)

tri_bio_table <- read.csv("Data/Processed/input_n_tri.csv", check.names = FALSE)
tri_bio_table |>
  dplyr::mutate(dplyr::across(dplyr::everything(), ~ tidyr::replace_na(., 0))) |>
  dplyr::select(year, n_ages, n_lengths) |>
  dplyr::mutate(`Length only` = n_lengths - n_ages) |>
  dplyr::select(-n_lengths) |>
  dplyr::rename(`Age and length` = n_ages) |>
  tidyr::pivot_longer(-year, names_to = "Sample type", values_to = "Count") |>
  ggplot() +
  geom_col(aes(x = year, y = Count, fill = factor(`Sample type`, levels = c("Length only", "Age and length")))) +
  viridis::scale_fill_viridis(discrete = TRUE) +
  # ggtitle("WCGBTS Biological Samples by Year") +
  labs(fill = "Sample type") +
  theme(legend.position = "top")
ggsave(
  filename = "report/figures/comp_samples_tri.png",
  width = 6.5, height = 3.5
)
