library(dplyr)
library(r4ss)

yt_survey_bio <- nwfscSurvey::pull_bio(common_name = 'yellowtail rockfish', survey = 'NWFSC.Combo') 

yt_n_survey_bio <- filter(yt_survey_bio, Latitude_dd > 40 + 1/6)

calc_w_l <- function(dat) {
  dat |>
    tidyr::nest(data = -Sex) |> 
    # Fit model
    dplyr::mutate(fit = purrr::map(data, ~ lm(log(Weight) ~ log(Length_cm), data = .)),
                  tidied = purrr::map(fit, broom::tidy),
                  # Transform W-L parameters, account for lognormal bias
                  out = purrr::map2(tidied, fit, function(.x, .y) {
                    sd_res <- sigma(.y)
                    .x |>
                      dplyr::mutate(term = c('A', 'B'),
                                    median = ifelse(term == 'A', exp(estimate), estimate),
                                    mean = ifelse(term == 'A', median * exp(0.5 * sd_res^2),
                                                  median)) |>
                      dplyr::select(term, mean)
                  }),
                  n = purrr::map(fit, ~ length(resid(.)))) |>
    tidyr::unnest(c(out, n)) |>
    dplyr::select(Sex, term, mean, n) |>
    tidyr::pivot_wider(names_from = term, values_from = mean)
}

mod <- SS_read('model_runs/base_2017_3.30.23')

# interestingly, the 2017 model fit a single W-L curve for all fish
# admittedly, the differences between males and females are quite small.
# (age-length differences much more pronounced between sexes)
w_l_2008 <- filter(yt_n_survey_bio, Year == 2008) |>
  mutate(Sex = 'B') |>
  calc_w_l()

mod$ctl$MG_parms['Wtlen_1_Fem_GP_1', 'INIT'] <- mod$ctl$MG_parms['Wtlen_1_Mal_GP_1', 'INIT'] <- w_l_2008$A
mod$ctl$MG_parms['Wtlen_2_Fem_GP_1', 'INIT'] <- mod$ctl$MG_parms['Wtlen_2_Mal_GP_1', 'INIT'] <- w_l_2008$B

SS_write(mod, 'model_runs/skinny_w_l', overwrite = TRUE)

w_l_2014 <- filter(yt_n_survey_bio, Year == 2014) |>
  mutate(Sex = 'B') |>
  calc_w_l()

mod$ctl$MG_parms['Wtlen_1_Fem_GP_1', 'INIT'] <- mod$ctl$MG_parms['Wtlen_1_Mal_GP_1', 'INIT'] <- w_l_2014$A
mod$ctl$MG_parms['Wtlen_2_Fem_GP_1', 'INIT'] <- mod$ctl$MG_parms['Wtlen_2_Mal_GP_1', 'INIT'] <- w_l_2014$B

SS_write(mod, 'model_runs/fat_w_l', overwrite = TRUE)

out <- SSgetoutput(dirvec = glue::glue('Model_Runs/{size}_w_l', size = c('skinny', 'fat')), getcomp = FALSE, verbose = FALSE)

out |>
  SSsummarize() |> 
  SSplotComparisons(subplots = c(1, 18), legendlabels = c('2008 W-L (skinny)', '2014 W-L (fat)'))

out |>
  SSsummarize() |>
  SStableComparisons(names = 'OFLCatch_2017', modelnames = c('2008 W-L (skinny)', '2014 W-L (fat)'))









