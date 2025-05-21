# Plot age 15+ fractions for commercial and WCGBTS
X <- 15
f <- 1
v1 <- mod_outagedbase  |> 
  dplyr::filter(Fleet == f & Bin >= X) |> 
  dplyr::group_by(Yr) |>
  dplyr::summarise(obsXplus = sum(Obs)) 

v2 <- mod_outagedbase  |> 
  dplyr::filter(Fleet == f & Bin >= X) |> 
  dplyr::group_by(Yr) |>
  dplyr::summarise(obsXplus = sum(Exp)) 

f <- 6
v3 <- mod_outghostagedbase  |> 
  dplyr::filter(Fleet == f & Bin >= X) |> 
  dplyr::group_by(Yr) |>
  dplyr::summarise(obsXplus = sum(Obs)) 

v4 <- mod_outghostagedbase  |> 
  dplyr::filter(Fleet == f & Bin >= X) |> 
  dplyr::group_by(Yr) |>
  dplyr::summarise(obsXplus = sum(Exp)) 

png(
  filename = "figures/age15plus_comps.png",
  width = 6.5, height = 4.5, units = "in", res = 300
)
plot(v1, col = 2, pch = 16, xlab = "Year", ylab = "Fraction of commercial catch ages 15+", ylim = c(0, 1.1*max(v1$obsXplus, v2$obsXplus)), yaxs = "i", las = 1)
lines(v2, col = 2, lwd = 3)
points(v3, col = 4, pch = 16)
lines(v4, col = 4, lwd = 3)
legend("top", legend = c("Commercial", "WCGBTS"), fill = c(2, 4), bty = "n")
dev.off()
