#' max_age_sim
#'
#' simple simulation of age samples with ageing imprecision, M, and F
#'
#' @param nsamp number of age samples to calculate
#' @param CV CV of ageing imprecision
#' @param M natural mortality rate
#' @param F fishing mortality rate
#' @param Asel first age at which fish are selected (knife edge)
#' @param maxage maximum age of fish within the simulation (independent of M)
#' @return list with n_at_age, sel_at_age, and samples
#'
max_age_sim <- function(nsamp = 100, CV = 0.1, M = 0.1, F = 0.2, Asel = 5, maxage = 200) {
  n_at_age <- c(100, maxage) # vector of length maxage (ignoring age 0)
  # calculate numbers at age and selected fish at each age
  for (a in 2:maxage) {
    n_at_age[a] <- n_at_age[a - 1] * exp(-M - ifelse(a >= Asel, F, 0))
  }

  # number of selected fish at each age (knife-edge selectivity)
  sel_at_age <- n_at_age
  sel_at_age[1:maxage < Asel] <- 0

  # randomly sample fish
  samples <- data.frame(age_true = sample(1:maxage, size = nsamp, replace = TRUE, prob = sel_at_age))
  # apply ageing error
  samples$age_obs <- rnorm(n = nsamp, mean = samples$age_true, sd = CV * samples$age_true) |> round()


  return(list(
    n_at_age = n_at_age,
    sel_at_age = sel_at_age,
    samples = samples,
    true_ages0.995 = which(cumsum(n_at_age / sum(n_at_age)) > 0.995) |> min()
  ))
}

# create a grid of simulation configurations
design <- expand.grid(
  nsamp = c(100, 1000, 10000),
  CV = c(0.1, 0.2, 0.3),
  M = c(0.05, 0.1, 0.2),
  F_label = c("F = 0", "F = M", "F = 0.2"),
  sim = 1:100,
  maxage = NA,
  true_ages0.995 = NA,
  obs_ages0.990 = NA,
  obs_ages0.999 = NA
)

# calculate F as a function of the F label
design <- design |>
  dplyr::mutate(F = dplyr::case_when(
    F_label == "F = 0" ~ 0,
    F_label == "F = M" ~ M,
    F_label == "F = 0.2" ~ 0.2
  ))

# loop over configurations to simulate max age
for (irow in 1:nrow(design)) {
  results <- max_age_sim(
    nsamp = design$nsamp[irow],
    CV = design$CV[irow],
    M = design$M[irow],
    F = design$F[irow]
  )
  design$maxage[irow] <- results$samples$age_obs |> max()
  design$true_ages0.995[irow] <- results$true_ages0.995
  design$obs_ages0.990[irow] <- results$samples$age_obs |> quantile(0.99)
  design$obs_ages0.999[irow] <- results$samples$age_obs |> quantile(0.999)
}

# estimate M from max observed age and from quantiles
design <- design |>
  dplyr::mutate(
    est_M = 5.4 / maxage,
    est_M0.990 = 5.4 / obs_ages0.990,
    est_M0.999 = 5.4 / obs_ages0.999
  )

# plot of estimated M
est_M_plot <- function(quantile = c(1, 0.999, 0.990)) {
  if (quantile == 1) {
    y_var <- "est_M"
    title <- "estimated M from max observed age"
  }
  if (quantile == 0.999) {
    y_var <- "est_M0.999"
    title <- "estimated M from 0.999 quantile of observed ages"
  }
  if (quantile == 0.99) {
    y_var <- "est_M0.990"
    title <- "estimated M from 0.990 quantile of observed ages"
  }
  filename <- ifelse(quantile == 1, "est_M1.0", y_var)

  # make plot
  ggplot(design, aes(x = factor(CV), y = .data[[y_var]], color = factor(nsamp))) +
    geom_violin(draw_quantiles = 0.5, bw = 0.01) +
    facet_grid(M ~ F_label, labeller = labeller(
      M = label_both,
      F_label = label_value
    )) +
    labs(
      title = title,
      subtitle = "Horizontal line at true M",
      x = "ageing error CV",
      y = title,
      color = "Number of Samples"
    ) +
    geom_hline(aes(yintercept = M), linetype = "dashed") +
    scale_y_continuous(limits = c(0, 0.4), expand = c(0, 0))
  ggsave(paste0("figures/max_age_sim/sim_", filename, ".png"))
}

# make plots of estimated M at different quantiles
est_M_plot(1)
est_M_plot(0.999)
est_M_plot(0.99)

max_age_plot <- function(quantile = c(1, 0.999, 0.990)) {
  if (quantile == 1) {
    y_var <- "maxage"
    title <- "max observed age"
  }
  if (quantile == 0.999) {
    y_var <- "obs_ages0.999"
    title <- "0.999 quantile of observed ages"
  }
  if (quantile == 0.99) {
    y_var <- "obs_ages0.990"
    title <- "0.990 quantile of observed ages"
  }
  filename <- ifelse(quantile == 1, "obs_max", y_var)


  # plot of observed max age
  ggplot(design, aes(x = factor(CV), y = .data[[y_var]], color = factor(nsamp))) +
    geom_violin(draw_quantiles = 0.5, bw = 10) +
    facet_grid(M ~ F_label, labeller = labeller(
      M = label_both,
      F_label = label_value
    )) +
    labs(
      title = title,
      subtitle = "horizontal line at 0.995 quantile of true ages",
      x = "Ageing error CV",
      y = title,
      color = "Number of Samples"
    ) +
    geom_hline(aes(yintercept = true_ages0.995), linetype = "dashed")
  ggsave(paste0("figures/max_age_sim/sim_", filename, ".png"))
}

# make plots of max age at different quantiles
max_age_plot(1)
max_age_plot(0.999)
max_age_plot(0.99)
