#' Plot all indices in one figure
#'
#' Initially just the single plot of fits, but could also be used to
#' show the data only or any other quantity of interest
#' Based on https://github.com/pfmc-assessments/lingcod/blob/main/R/plot_indices.R.
#'
#' @param mod A model object created by [get_mod()]. Could also be
#' created by `r4ss::SS_output()` but needs to have an element "area"
#' added to the list.
#' @param fleets which fleets to plot. Default is all fleets in numerical order.
#' @param dir directory (relative to model directory) where png file will be written. If NULL then plot will be sent to current graphics device.
#' @param fit include fit or just data only
#' @param log plot on a log scale
#' @export
#' @author Ian G. Taylor
#' @return A figure showing the fit to all indices.


plot_indices <- function(mod, fleets = NULL, dir = NULL, fit = TRUE, log = FALSE) {
  subplot <- 2
  if (!is.null(dir)) {
    filename <- file.path(dir, "index_fits_all_fleets.png")

    # make caption
    caption <- paste0(
      "Index fits for all fleets. ",
      "Lines indicate 95\\% uncertainty interval around estimated values ",
      "based on the model assumption of lognormal error. ",
      "Thicker lines (if present) indicate input uncertainty ",
      "before addition of an estimated additional uncertainty parameter ",
      "which is added to the standard error of all years within an index."
    )

    if (log & !fit) {
      stop("Function doesn't support log-scale plot without fits")
    }
    if (log) {
      subplot <- 5
      filename <- gsub("index", "index_log", filename)
      caption <- gsub("fits", "fits on a log scale", caption)
    }
    if (!fit) {
      subplot <- 1
      filename <- gsub("fits", "data", filename)
      caption <- paste0(
        "Index observations for all fleets with 95\\% uncertainty ",
        "intervals as input to the model before any estimation of ",
        "additional uncertainty parameters."
      )
    }

    # open PNG file
    png(filename, width = 6.5, height = 5, units = "in", res = 300, pointsize = 10)
  }

  # make number of panels dynamic
  par(mfrow = c(2, 2), mar = c(3, 1, 1, 1), oma = c(2, 2, 0, 0))

  # get fleets with indices
  if (is.null(fleets)) {
    fleets <- unique(mod$cpue$Fleet)
  }

  # make a panel for each one
  for (f in fleets) {
    r4ss::SSplotIndices(mod,
      fleets = f,
      subplots = subplot,
      # col3 = get_fleet(f, col = paste0("col.", mod$area)),
      mainTitle = FALSE
    )
    title(main = mod$FleetNames[f])
  }
  mtext("Year", side = 1, line = 0, outer = TRUE)
  mtext(ifelse(log, "Log-scale index", "Index"), side = 2, line = 1, outer = TRUE)

  # close png file
  if (!is.null(dir)) {
    dev.off()
  }
}
