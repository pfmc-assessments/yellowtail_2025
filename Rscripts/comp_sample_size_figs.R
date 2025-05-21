library(ggplot2)
theme_set(theme_classic(base_size = 14))


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
  #viridis::scale_fill_viridis(discrete = TRUE) +
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
  #viridis::scale_fill_viridis(discrete = TRUE) +
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
  #viridis::scale_fill_viridis(discrete = TRUE) +
  # ggtitle("WCGBTS Biological Samples by Year") +
  labs(fill = "Sample type") +
  theme(legend.position = "top")
ggsave(
  filename = "report/figures/comp_samples_wcgbts.png",
  width = 6.5, height = 3.5
)

tri_bio_table <- read.csv("Data/Processed/input_n_tri.csv", check.names = FALSE)

# Add all years from 1980 to 2004 (fill missing with zeros)
all_years <- data.frame(year = 1980:2004)
tri_bio_table <- dplyr::right_join(tri_bio_table, all_years, by = "year") |>
  dplyr::arrange(year)

tri_bio_table |>
  dplyr::mutate(dplyr::across(dplyr::everything(), ~ tidyr::replace_na(., 0))) |>
  dplyr::select(year, n_ages, n_lengths) |>
  dplyr::mutate(`Length only` = n_lengths - n_ages) |>
  dplyr::select(-n_lengths) |>
  dplyr::rename(`Age and length` = n_ages) |>
  tidyr::pivot_longer(-year, names_to = "Sample type", values_to = "Count") |>
  ggplot() +
  geom_col(aes(x = year, y = Count, fill = factor(`Sample type`, levels = c("Length only", "Age and length")))) +
  #viridis::scale_fill_viridis(discrete = TRUE) +
  # ggtitle("WCGBTS Biological Samples by Year") +
  labs(fill = "Sample type") +
  theme(legend.position = "top")
ggsave(
  filename = "report/figures/comp_samples_tri.png",
  width = 6.5, height = 3.5
)

# hook and line samples from model input files
# (assuming that Nsamp is the number of fish)
mod_in$dat$lencomp |>
  dplyr::filter(fleet == 4) |>
  dplyr::select(year, Nsamp) |>
  dplyr::rename(Count = Nsamp) |>
  ggplot() +
  geom_col(aes(x = year, y = Count), fill = "#F8766D")
ggsave(
  filename = "report/figures/comp_samples_HnL.png",
  width = 6.5, height = 3.5
)

# mean length plots
mean_length_multifleet <- function(fleets = 1:3, type = "len", filename, datonly = TRUE) {
  # open PNG file
  png(
    filename = file.path("report/figures/", filename),
    width = 6.5, height = 3.5, units = "in", res = 300
  )
  ylim <- c(15, 70)
  if (type == "age") {
    ylim <- c(0, 25)
  }
  # set up panels
  par(mfrow = c(1, 3), mar = c(2, 0, 2, 0), oma = c(2, 4, 1, 1))
  for (f in fleets) {
    plot(0,
      xlim = c(1970, 2024),
      ylim = ylim,
      type = "n", xlab = "", ylab = "",
      axes = FALSE
    )
    axis(1)
    if (f == fleets[1]) {
      axis(2, las = 1)
    }
    box()
    SSMethod.TA1.8(mod_out, fleet = f, type = type, datonly = datonly, add = TRUE, set.pars = FALSE)
    title(main = mod_out$FleetNames[f])
  }
  mtext(ifelse(type == "len", "Mean length (cm)", "Mean age (years)"),
    outer = TRUE, side = 2, line = 2.5
  )
  mtext("Year", outer = TRUE, side = 1, line = 0.5)
  dev.off()
}
# loop through fleet groups include fit or not to make plots
for (fleet_group in 1:2) {
  for (datonly in c(TRUE, FALSE)) {
    for (type in c("len", "age")) {
      if (fleet_group == 1) {
        fleets <- 1:3
      } else {
        fleets <- 4:6
      }
      mean_length_multifleet(
        fleets = fleets,
        type = type,
        filename = paste0(
          "mean_", type, "_fishery",
          ifelse(fleet_group == 1, "fisheries", "surveys"),
          ifelse(datonly, "_data", "_fit"),
          ".png"
        ),
        datonly = datonly
      )
    }
  }
}
