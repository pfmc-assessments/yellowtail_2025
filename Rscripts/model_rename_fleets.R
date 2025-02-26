#' Rename fleets used in the 2017 assessment
#'
#' Function to help with bridging from 2017 to 2025 assessments
#' Returns a modified list with fleets renamed.
#'
#' @param inputs List created by r4ss::SS_read()
#' @examples
#' \dontrun{
#' inputs <- SS_read(...)
#' inputs2 <- rename_fleets(inputs)
#' SS_write(inputs2)
#' }
rename_fleets <- function(inputs) {
  # rename fleets
  inputs$dat$fleetinfo$fleetname <- c("Commercial", "At-Sea-Hake", "Recreational", "PLACEHOLDER", "Triennial", "WCGBTS")
  r4ss::SS_write(inputs, "Model_Runs/temp", overwrite = TRUE)
  # stopph -1 causes model to write ss_new files without running anything
  r4ss::run("Model_Runs/temp", extras = "-nohess -stopph -1")
  inputs2 <- r4ss::SS_read("Model_Runs/temp", ss_new = TRUE)

  return(invisible(inputs2))

  #   # stuff to change if/when renumbering fleets
  #   inputs$dat$Nfleets
  #   inputs$dat$fleetinfo
  #   inputs$dat$fleetnames # can probably be ignored
  #   inputs$dat$surveytiming
  #   inputs$dat$units_of_catch
  #   inputs$dat$areas
  #   inputs$dat$catch
  #   inputs$dat$CPUEinfo
  #   inputs$dat$CPUE
  #   inputs$dat$len_info
  #   inputs$dat$lencomp
  #   inputs$dat$age_info
  #   inputs$dat$agecomp
  #   # I think these fleet-specific things can be ignored
  #   # because they are derived from the stuff above and not written
  #   # by SS_write().
  #   inputs$dat$Nfleet
  #   inputs$dat$Nsurveys
  #   inputs$dat$fleetinfo1
  #   inputs$dat$fleetinfo2
  #   inputs$dat$comp_tail_compression
  #   inputs$dat$add_to_comp
  #   inputs$dat$max_combined_lbin
}
