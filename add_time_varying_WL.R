#' Rename fleets used in the 2017 assessment
#'
#' Function to help with bridging from 2017 to 2025 assessments
#' Returns a modified list with fleets renamed.
#'
#' @param model List created by r4ss::SS_read()
#' @param sex_specific_wl Logical indicating whether the time-varying WL block parameters should be sex-specific
#' @param wcbts_start_yr First year of WCBTS survey. Used to set the beginning year of time block design (likely won't be modified)
#' @param wcbts_end_yr Last year of WL time blocks specified by user. Default set to 2024 (last year of data). Can be set earlier for models not run through 2024 
#' 



# Load WL data ------------------------------------------------------------
W_L_pars <- readr::read_csv(here::here("Data/Processed/W_L_pars.csv"))
W_L_pars_yr <- readr::read_csv(here::here("Data/Processed/W_L_pars_yr.csv"))



add_tv_wl <- function(model, sex_specific_wl = T, wcbts_start_yr = 2003, wcbts_end_yr = 2024){
  
  # update LO and HI for original parameters
  model$ctl$MG_parms[c(7,8, 19, 20), 1] <- 0
  model$ctl$MG_parms[c(7,8, 19, 20), 2] <- 4
  
  ### Block design 
  wcbts_yrs <- seq(wcbts_start_yr, wcbts_end_yr, 1)
  
  if(wcbts_end_yr >= 2020){
    # remove 2020 b/c don't have year-specific WL params, will use base parameters
    wcbts_yrs <- wcbts_yrs[-(which(wcbts_yrs == 2020))]
  }else{}
  
  # not sure if new models have more time block designs
  # want to add the time varying WL as the last time block so not to overwrite
  tv_wl_block <- model$ctl$N_Block_Designs + 1
  
  model$ctl$N_Block_Designs <- tv_wl_block # update number of block designs
  model$ctl$blocks_per_pattern[tv_wl_block] <- length(wcbts_yrs) # specify number of blocks in WL block design
  names(model$ctl$blocks_per_pattern)[tv_wl_block] <- paste0("blocks_per_pattern_", tv_wl_block) # name block pattern
  model$ctl$Block_Design[[tv_wl_block]] <- rep(wcbts_yrs, each = 2) # set beginning and end year for each time block
  
  # add block parameters to WL long lines
  # update MG params to include block info for WL
  model$ctl$MG_parms[c(7,8, 19, 20), 13] <- 4 # block design reference #
  model$ctl$MG_parms[c(7,8, 19, 20), 14] <- 2 # type of block (2 = replace parameters)
  
  
  if(sex_specific_wl){
    # sex specific base parameters
    model$ctl$MG_parms[c(7, 8, 19, 20), 3] <- c(W_L_pars$A[1], W_L_pars$B[1], W_L_pars$A[2], W_L_pars$B[2])
    
    ### Time block params
    # create vector of WL pars
    input_pars_f <- W_L_pars_yr |>
      dplyr::filter(Sex == "F") |>
      dplyr::filter(Year >= wcbts_start_yr) |>
      dplyr::filter(Year <= wcbts_end_yr) |>
      dplyr::select(-n) |>
      dplyr::arrange(Sex, Year)
    
    input_pars_m <- W_L_pars_yr |>
      dplyr::filter(Sex == "M") |>
      dplyr::filter(Year >= wcbts_start_yr) |>
      dplyr::filter(Year <= wcbts_end_yr) |>
      dplyr::select(-n) |> 
      dplyr::arrange(Sex, Year)
    
    
    # create rows names for mg tv data
    model_rownames_f <- c(paste0("Wtlen_1_Fem_GP_1_BLK4repl_", wcbts_yrs), 
                          paste0("Wtlen_2_Fem_GP_1_BLK4repl_", wcbts_yrs))
    model_rownames_m <- c(paste0("Wtlen_1_Mal_GP_1_BLK4repl_", wcbts_yrs), 
                          paste0("Wtlen_2_Mal_GP_1_BLK4repl_", wcbts_yrs))
    model_rownames <- c(model_rownames_f, model_rownames_m)
    
    # Fill in data frame
    row_num <- length(model_rownames)
    model$ctl$MG_parms_tv <-  data.frame(LO = rep(0, row_num),
                                         HI = rep(4, row_num),
                                         INIT = c(input_pars_f$A, input_pars_f$B, input_pars_m$A, input_pars_m$B),
                                         PRIOR = rep(99, row_num),
                                         PR_SD = rep(99, row_num),
                                         PR_type = rep(0, row_num),
                                         PHASE = rep(-50, row_num),
                                         row.names = model_rownames)
  }else{
    # updated base parameters (calculated using data through 2024)
    model$ctl$MG_parms[c(7, 8, 19, 20), 3] <- rep(c(W_L_pars$A[3], W_L_pars$B[3]), 2)
    
    ### Time block params
    # create vector of WL pars
    input_pars <- W_L_pars_yr |>
      dplyr::filter(Sex == "B") |>
      dplyr::filter(Year >= wcbts_start_yr) |>
      dplyr::filter(Year <= wcbts_end_yr) |>
      dplyr::select(-n) |>
      dplyr::arrange(Sex, Year)
    
    # create rows names for mg tv data
    model_rownames_f <- c(paste0("Wtlen_1_Fem_GP_1_BLK4repl_", wcbts_yrs), 
                          paste0("Wtlen_2_Fem_GP_1_BLK4repl_", wcbts_yrs))
    model_rownames_m <- c(paste0("Wtlen_1_Mal_GP_1_BLK4repl_", wcbts_yrs), 
                          paste0("Wtlen_2_Mal_GP_1_BLK4repl_", wcbts_yrs))
    model_rownames <- c(model_rownames_f, model_rownames_m)
    
    # Fill in data frame
    row_num <- length(model_rownames)
    model$ctl$MG_parms_tv <-  data.frame(LO = rep(0, row_num),
                                         HI = rep(4, row_num),
                                         INIT = rep(c(input_pars$A, input_pars$B, input_pars$A, input_pars$B)),
                                         PRIOR = rep(99, row_num),
                                         PR_SD = rep(99, row_num),
                                         PR_type = rep(0, row_num),
                                         PHASE = rep(-50, row_num),
                                         row.names = model_rownames)
    
  }
  
  # sex specific base parameters
  model$ctl$MG_parms[c(7, 8, 19, 20), 3] <- c(W_L_pars$A[1], W_L_pars$B[1], W_L_pars$A[2], W_L_pars$B[2])
  
  ### Time block params
  # create vector of WL pars
  input_pars_f <- W_L_pars_yr |>
    dplyr::filter(Sex == "F") |>
    dplyr::select(-n) |>
    dplyr::arrange(Sex, Year)
  
  input_pars_m <- W_L_pars_yr |>
    dplyr::filter(Sex == "M") |> 
    dplyr::select(-n) |> 
    dplyr::arrange(Sex, Year)
  
  
  # create rows names for mg tv data
  model_rownames_f <- c(paste0("Wtlen_1_Fem_GP_1_BLK4repl_", wcbts_yrs), 
                        paste0("Wtlen_2_Fem_GP_1_BLK4repl_", wcbts_yrs))
  model_rownames_m <- c(paste0("Wtlen_1_Mal_GP_1_BLK4repl_", wcbts_yrs), 
                        paste0("Wtlen_2_Mal_GP_1_BLK4repl_", wcbts_yrs))
  model_rownames <- c(model_rownames_f, model_rownames_m)
  
  # Fill in data frame
  row_num <- length(model_rownames)
  model$ctl$MG_parms_tv <-  data.frame(LO = rep(0, row_num),
                                       HI = rep(4, row_num),
                                       INIT = c(input_pars_f$A, input_pars_f$B, input_pars_m$A, input_pars_m$B),
                                       PRIOR = rep(99, row_num),
                                       PR_SD = rep(99, row_num),
                                       PR_type = rep(0, row_num),
                                       PHASE = rep(-50, row_num),
                                       row.names = model_rownames)
  
  # return model with time-varying WL
  return(model)
}




