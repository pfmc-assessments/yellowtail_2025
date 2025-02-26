#' Remove retention parameters and discard data from a Yellowtail Rockfish model
#'
#' Function to help with bridging from 2017 to 2025 assessments
#' after making decision to remove parametric retention function
#' and add discards to retained catch instead of estimating internally
#'
#' @param inputs List created by r4ss::SS_read()
#' @examples
#' \dontrun{
#' inputs <- SS_read(...)
#' inputs2 <- remove_retention(inputs)
#' SS_write(inputs2)
#' }
remove_retention <- function(inputs) {
  ### control file changes

  # remove specification of discard in selectivity setup
  inputs$ctl$size_selex_types$Discard <- 0
  # remove retention base parameters
  inputs$ctl$size_selex_parms <- inputs$ctl$size_selex_parms |>
    dplyr::filter(!grepl("PRet", rownames(inputs$ctl$size_selex_parms)))
  # remove retention time-varying parameters
  inputs$ctl$size_selex_parms_tv <- inputs$ctl$size_selex_parms_tv |>
    dplyr::filter(!grepl("PRet", rownames(inputs$ctl$size_selex_parms_tv)))

  ### cata file changes

  # remove discard fraction data
  inputs$dat$N_discard_fleets <- 0
  inputs$dat$discard_fleet_info <- NULL
  inputs$dat$discard_fleet_info <- NULL
  inputs$dat$discard_data <- NULL
  # remove discard comps (partition 1)
  inputs$dat$lencomp <- inputs$dat$lencomp |> dplyr::filter(part != 1)

  # return modified list
  return(invisible(inputs))
}

#' Add discard catch to a Yellowtail Rockfish model
#'
#' Function to help with bridging from 2017 to 2025 assessments
#' after making decision to remove parametric retention function
#' and add discards to retained catch instead of estimating internally
#' See /Rscripts/explore_discards.R for processing of GEMM and Pikitch data
#'
#' @param inputs List created by r4ss::SS_read()
#' @examples
#' \dontrun{
#' inputs <- SS_read(...)
#' inputs2 <- add_discard_catch(inputs)
#' SS_write(inputs2)
#' }
add_discards <- function(inputs) {
  # read processed GEMM data and apply fleet numbers
  dead_discards <- readRDS("Data/Processed/gemm_discards_by_fleet.rds") |>
    dplyr::mutate(
      fleet = dplyr::case_when(
        fleet == "Commercial" ~ 1,
        fleet == "At-Sea-Hake" ~ 2,
        fleet == "Recreational" ~ 3
      )
    )
  # simple loop over rows in gemm summary to add into data file
  for (irow in 1:nrow(dead_discards)) {
    y <- dead_discards$year[irow]
    f <- dead_discards$fleet[irow]
    subset <- inputs$dat$catch$year == y & inputs$dat$catch$fleet == f
    inputs$dat$catch$catch[subset] <- inputs$dat$catch$catch[subset] + dead_discards$catch[irow]
  }

  # TODO: add Pikitch data to early commercial catch either via catch multiplier parameter or 
  #       by modifying the time series of catch as done for the GEMM data above
  
  # return modified list
  return(invisible(inputs))
}
