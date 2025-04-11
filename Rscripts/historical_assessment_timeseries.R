# make plot of historical time series for yellowtail rockfish
# adapted from https://github.com/iantaylor-NOAA/YTRK_doc/blob/master/Rcode/historical_assessment_timeseries.R

# read base model
# TODO: make this dynamic
mod1 <- SS_output('Model_Runs/4.12_age_and_M')

# switch on whether to create the CSV file with the data or not
# (only needed to be run once but saving code here for future reference)
make_csv <- FALSE
if (make_csv) {
  # read CSV file from 2017 assessment
  old_csv <- read.csv(
    "https://raw.githubusercontent.com/iantaylor-NOAA/YTRK_doc/refs/heads/master/txt_files/Yellowtail_historical_assessment_time_series.csv",
    check.names = FALSE
  )
  # reorder to put the earlier models first
  old_csv <- old_csv[, c(1, ncol(old_csv):2)]
  # save old names that aren't unique
  old_names <- names(old_csv)
  names(old_csv) <- make.names(old_names, unique = TRUE)
  # update names to work with dplyr

  # add 2013 Data-Moderate
  # read data-moderate results
  results2013 <- read.csv(
    "https://raw.githubusercontent.com/iantaylor-NOAA/YTRK_doc/refs/heads/master/txt_files/age4plus_bio_from_Yellowtail_2013_DataModerate.csv"
  ) |>
    dplyr::filter(Yr <= 2013) |>
    dplyr::rename(Year = Yr, median2013 = Age4plus_bio.median) |>
    dplyr::select(Year, median2013)

  m2017 <- SS_output("Model_Runs/1.01_base_2017")
  results2017 <- m2017$timeseries |>
    dplyr::filter(Yr <= 2017) |>
    dplyr::rename(Year = Yr, mid2017 = Bio_smry) |>
    dplyr::select(Year, mid2017)

  # combined past results to make new table without current model
  new_csv <- old_csv |>
    dplyr::full_join(results2013, by = "Year") |>
    dplyr::full_join(results2017, by = "Year") |>
    dplyr::arrange(Year)
  # add assessment year
  new_csv[new_csv$Year == -999, "median2013"] <- 2013
  new_csv[new_csv$Year == -999, "mid2017"] <- 2017
  new_names <- c(old_names, "Age.4.median.2013", "Age.4.2017")
  names(new_csv) <- new_names
  # save new csv file
  write.csv(
    new_csv,
    file = "Data/Raw_not_confidential/Yellowtail_historical_assessment_time_series.csv",
    row.names = FALSE,
    quote = FALSE
  )
}

totcatch <- aggregate(mod1$catch$dead_bio, by = list(mod1$catch$Yr), FUN = sum)
names(totcatch) <- c("Yr", "dead_bio")

# compare summary biomass across previous stock assessments
stocks <- read.csv(
  "Data/Raw_not_confidential/Yellowtail_historical_assessment_time_series.csv",
) |>
  dplyr::select(-dplyr::starts_with("Spawning")) # exclude columns that didn't contain summary biomass

# get assessment year from first row and then remove that row
assess.yrs <- as.numeric(stocks[1, -1])
assess.colors <- viridis::turbo(length(unique(assess.yrs)))
stocks <- stocks[-1, ]

png(
  filename = "report/Figures/historical_assessment_timeseries.png",
  width = 7,
  height = 5.5,
  res = 300,
  units = "in"
)
par(mar = c(4, 4, 1, 1))
# empty plot
plot(
  0,
  type = "n",
  xlim = c(1940, 2024),
  ylim = c(0, 200000),
  axes = FALSE,
  xaxs = "i",
  yaxs = "i",
  xlab = "Year",
  ylab = "Age 4+ biomass (x1000 mt)"
)
axis(1)
axis(2, at = pretty(c(0, 200000)), lab = pretty(c(0, 200000)) / 1000, las = 1)
# add lines for the older assessments
# using matplot because some years have 2 lines
for (istock in 1:ncol(stocks)) {
  assess.yr <- sort(unique(assess.yrs))[istock]
  matplot(
    x = stocks$Year,
    y = stocks[, 1 + which(assess.yrs == assess.yr)],
    col = assess.colors[istock],
    type = "l",
    lty = 1,
    lwd = 2,
    add = TRUE
  )
}

# add current model estimate
lines(
  mod1$timeseries[mod1$timeseries$Yr <= 2025, c("Yr", "Bio_smry")],
  col = 1,
  lwd = 3
)
abline(
  h = mod1$timeseries$Bio_smry[1],
  col = 1,
  lwd = 1,
  lty = 3
)
text(
  x = 2010,
  y = 1.2 * mod1$timeseries$Bio_smry[1],
  col = 1,
  labels = "unfished equilibrium\nin base model"
)
arrows(
  x0 = 2010,
  x1 = 2015,
  y0 = 1.12 * mod1$timeseries$Bio_smry[1],
  y1 = mod1$timeseries$Bio_smry[1],
  length = 0.05
)
legendnames <- c(
  "Base model for current assmt",
  paste(sort(unique(assess.yrs), decreasing = TRUE), "assmt")
)
# earliest 4 assessments (last 4 entries in legend) had separate low and high time series
legendnames[(-3:0) + length(legendnames)] <- paste(legendnames[(-3:0) + length(legendnames)], "(low & high)")
points(x = totcatch$Yr, y = totcatch$dead_bio, type = "h", lwd = 6, lend = 3)
text(x = 2015, y = 0, col = 1, labels = "total catch\nin base model", pos = 3)
legend(
  "bottomleft",
  legend = legendnames,
  col = c(1, rev(assess.colors)),
  lwd = c(3, rep(2, ncol(stocks))),
  bty = "n"
)
box()
dev.off()
