library(ggplot2)
library(dplyr)
library(readxl)
library(r4ss)

# double read data come from three sources: ODFW, WDFW, and PSMFC (NWFSC lab)
# in the objects created below, "format1" refers to the data in a standardized format
# with columns age1, age2, age3 (optional), agedby1, agedby2, agedby3 (optional)
# "format2" refers to the data in a wide format with one column per ager

# switch to allow the file to be sourced without reading the data again
read_data <- TRUE
if (read_data) {
  ##############################################################################
  # ODFW double reads (read by PSMFC / CAP lab at NWFSC)
  ##############################################################################

  # ODFW double reads come were sent by email from Mark Terwilliger <mark.r.terwilliger@odfw.oregon.gov>
  # on 13-Feb-2025 "Subject: Yellowtail double reads"
  # NOTE: warning message is just about the few non-empty values in the comments column
  ODFW_double_reads <- readxl::read_excel(
    "Data/Confidential/ageing/2018-2024 combined ODFW Yellowtail aged data-Downs-Run 2-29-2024.xlsx"
  )

  # clean up ODFW data
  ODFW_double_reads_format1 <- ODFW_double_reads |>
    dplyr::rename(
      agedby1 = age_reader_code_1,
      agedby2 = age_reader_code_2,
      age1 = age_1,
      age2 = age_2
    ) |>
    dplyr::select(age1, age2, agedby1, agedby2)

  table(ODFW_double_reads_format1$agedby1, ODFW_double_reads_format1$agedby2)
  #          WDFW/JT WDFW/MS4
  # WDFW/JT      219     1256
  # WDFW/MS4       0        1
  # WDFW/SR      280      171

  # ODFW_double_reads |>
  #   ggplot() +
  #   geom_point(aes(x = age1, y = age2), alpha = 0.1, position = "jitter") +
  #   geom_abline(slope = 1, intercept = 0) +
  #   scale_x_continuous(limits = c(0, 40), expand = c(0, 0)) +
  #   scale_y_continuous(limits = c(0, 40), expand = c(0, 0))

  ##############################################################################
  # PSMFC double reads (CAP lab at NWFSC)
  ##############################################################################

  # PSMFC double reads shared by email from Patrick McDonald on 16-Feb-2025 "Subject: YTRK Update"
  # "All Double Reads" sheet gets read by default which contains everything in the other two sheets ("In House" and "CARE Exchanges")
  # The CARE exchanges comparing WDFW and PSMFC were aged by WDFW in 2005 and PSMFC in 2017
  PSMFC_double_reads <- readxl::read_excel(
    "Data/Confidential/ageing/YTRK Double Reads 2025.xlsx",
    skip = 2
  )

  table(
    PSMFC_double_reads$ager_id,
    PSMFC_double_reads$double_read_ager_id,
    useNA = "always"
  )
  #              bkamikawa ewallingford jtopping lortiz pmcdonald <NA>
  # bkamikawa            0            0        0      0      1052    0
  # ewallingford         0            0       50    280         0    0
  # jtopping             0           50        0      0         0    0
  # lortiz               0          384        0      0         0    0
  # wdfw               121            0        0      0         0    0
  # <NA>                 0            0        0      0         0    0

  ################################################################
  # clean up PSMFC data
  PSMFC_double_reads_format1 <- PSMFC_double_reads |>
    dplyr::rename(
      agedby1 = ager_id,
      agedby2 = double_read_ager_id,
      age1 = age_original,
      age2 = double_read_age
    ) |>
    dplyr::mutate(
      agedby1 = dplyr::case_when(
        agedby1 == "bkamikawa" ~ "NMFS/BK",
        agedby1 == "ewallingford" ~ "NMFS/EW",
        agedby1 == "jtopping" ~ "WDFW/JT", # data in PacFIN makes it clear that JT is at WDFW
        agedby1 == "lortiz" ~ "NMFS/LO",
        agedby1 == "pmcdonald" ~ "NWFSC/PM",
        agedby1 == "wdfw" ~ "WDFW",
        TRUE ~ "MISSING_READER_NAME" # any case not covered already
      ),
      agedby2 = dplyr::case_when(
        agedby2 == "bkamikawa" ~ "NMFS/BK",
        agedby2 == "ewallingford" ~ "NMFS/EW",
        agedby2 == "jtopping" ~ "WDFW/JT",
        agedby2 == "lortiz" ~ "NMFS/LO",
        agedby2 == "pmcdonald" ~ "NWFSC/PM",
        agedby2 == "wdfw" ~ "WDFW",
        TRUE ~ "MISSING_READER_NAME" # any case not covered already
      )
    ) |>
    dplyr::select(age1, age2, agedby1, agedby2)

  # WDFW double reads are in PacFIN
  load(
    "Data/Confidential/Commercial/pacfin-2025-03-10/PacFIN.YTRK.bds.10.Mar.2025.RData"
  )

  # clean data to remove fish from Canada and Puget Sound among other things
  # the cleanPacFIN() function also aligns the ageing method codes:
  # i Age methods were originally coded to 'NA', '2', '9', 'B', 'BB', '1', 'S', '4' or '6'
  # i Age methods are now coded to (n = 1), B (n = 153797), L (n = 1), S (n = 17944), T (n = 2) and NA (n = 78513)
  # i Number of samples (n) per combinations of ageing methods
  #   AGE_METHOD1 AGE_METHOD2 AGE_METHOD3 Age method for best age      n
  # 1           B           B           B                       B   2345
  # 2           B           B        <NA>                              1
  # 3           B           B        <NA>                       B   5138
  # 4           B        <NA>        <NA>                       B 146314
  # 5           B        <NA>        <NA>                    <NA>     43
  # 6           L        <NA>        <NA>                       L      1
  # 7           S        <NA>        <NA>                       S  17944
  # 8           T        <NA>        <NA>                       T      2
  # 9        <NA>        <NA>        <NA>                    <NA>  78470
  bds_clean <- bds.pacfin |>
    pacfintools::cleanPacFIN(
      keep_sample_type = c("M", "S"),
      keep_age_method = c("B", "S"),
      CLEAN = FALSE
    )
  # copy some fields that weren't included in the cleaned data
  bds_clean$agedby1 <- bds.pacfin$agedby1
  bds_clean$agedby2 <- bds.pacfin$agedby2
  bds_clean$agedby3 <- bds.pacfin$agedby3
  # filter samples in the same way as Rscripts/commercial_comps.R
  bds_clean <- bds_clean |>
    filter(
      SAMPLE_TYPE == "M" | (state == "OR" & SAMPLE_YEAR <= 1986), # keep old OR special request
      state == "WA" |
        state == "OR" |
        PACFIN_GROUP_PORT_CODE == "CCA" |
        PACFIN_GROUP_PORT_CODE == "ERA" # only y-t north
    ) |>
    filter(
      !is.na(age2) | !is.na(age3) # remove fish with no double reads
    )
  # only 27 fish are removed by cleaning step
  table(bds_clean$CLEAN)
  # FALSE  TRUE
  #    27  7412
  bds_clean <- bds_clean |> dplyr::filter(CLEAN)

  table(c(bds_clean$agedby1, bds_clean$agedby2, bds_clean$agedby3))
  #  NMFS/BK  WDFW/JT WDFW/MS4  WDFW/SR
  #       10     5157     1295    10694

  # eliminate the 10 fish aged by NMFS/BK under the assumption that these
  # are included in the table of CARE exchanges (and it's only 10 fish anyway)
  bds_clean <- bds_clean |> filter(agedby2 != "NMFS/BK")
  WDFW_double_reads_format1 <- bds_clean |>
    dplyr::select(age1, age2, age3, agedby1, agedby2, agedby3)

  # WDFW-PSMFC CARE exchanges from 2024 were shared in a separate file
  # shared by email from Emily Wallingford <emily.wallingford@noaa.gov> on 8-Nov-2024 "Subject: Re: Yellowtail Rockfish Exchanges"
  exchanges <- readxl::read_excel(
    "Data/Raw_not_confidential/Exchanges_24-007_and_24-010.xlsx"
  )
  # exchanges_format1 <- exchanges |>
  #   dplyr::rename(
  #     age1 = PSMFC,
  #     age2 = WDFW
  #   ) |>
  #   agedby1 = "NMFS",

  # confirm that 2024 exchanges are all represented in the PSMFC file
  plot(exchanges$PSMFC, exchanges$WDFW) # black dots are from the exchanges file
  PSMFC_double_reads_format1 |> # red dots are 2024 exchanges first read by WDFW
    filter(agedby1 == "WDFW/JT") |>
    dplyr::select(age2, age1) |>
    points(col = 2, pch = "x")
  PSMFC_double_reads_format1 |> # green dots are 2024 exchanges first read by PSMFC
    filter(agedby2 == "WDFW/JT") |>
    dplyr::select(age1, age2) |>
    points(col = 3, pch = "x")
}

# convert from longer format to wider format (separate column for each ager)
# initially only works for 3 readers per sample
format_double_reads <- function(dat) {
  agers <- dat |>
    dplyr::select(dplyr::starts_with("agedby")) |>
    unlist() |>
    unique()
  agers <- agers[!is.na(agers)]
  dat_wide <- data.frame(matrix(
    data = -999,
    nrow = nrow(dat),
    ncol = length(agers)
  ))
  colnames(dat_wide) <- agers

  # this part only works for up to 3 reads per otolith
  # (could try tidyr::pivot_wider() in the future for a more generalized solution)
  for (irow in 1:nrow(dat)) {
    dat_wide[irow, dat$agedby1[irow]] <- dat$age1[irow]
    dat_wide[irow, dat$agedby2[irow]] <- dat$age2[irow]
    if ("agedby3" %in% names(dat) && !is.na(dat$agedby3[irow])) {
      dat_wide[irow, dat$agedby3[irow]] <- dat$age3[irow]
    }
  }

  return(dat_wide)
}

################################################################
### simplify WDFW reads for now

# majority of samples are aged by the same person
table(WDFW_double_reads_format1$agedby1 == WDFW_double_reads_format1$agedby2)
# FALSE  TRUE
#  2695  4707

# majority of samples have only 2 ages
table(is.na(WDFW_double_reads_format1$age3))
# FALSE  TRUE
#  2332  5070

# format 2 is just reader1 vs reader2
WDFW_double_reads_format2 <- WDFW_double_reads_format1 |>
  dplyr::select(-age3, -agedby3) |> # remove triple reads for now
  dplyr::filter(agedby1 != agedby2) |> # remove fish aged by the same person
  dplyr::mutate(agedby1 = "reader1", agedby2 = "reader2") |> # rename readers to treat all readers equally
  format_double_reads()

# check the number of -999 values in each row
apply(WDFW_double_reads_format2, 1, function(x) {
  sum(x == -999)
}) |>
  table()
#    0
# 2695

# format 3 had reader names
WDFW_double_reads_format3 <- WDFW_double_reads_format1 |>
  dplyr::filter(agedby1 != agedby2) |> # remove fish aged by the same person
  format_double_reads()

# check the number of -999 values in each row
apply(WDFW_double_reads_format2, 1, function(x) {
  sum(x == -999)
}) |>
  table()

################################################################
### simplify ODFW reads

# small fraction of samples are aged by the same person
table(ODFW_double_reads_format1$agedby1 == ODFW_double_reads_format1$agedby2)
# FALSE  TRUE
#  1707   220
ODFW_double_reads_format2 <- ODFW_double_reads_format1 |>
  dplyr::filter(agedby1 != agedby2) |> # remove fish aged by the same person
  dplyr::mutate(agedby1 = "reader1", agedby2 = "reader2") |> # rename readers to treat all readers equally
  format_double_reads()

# format 3 had reader names
ODFW_double_reads_format3 <- ODFW_double_reads_format1 |>
  dplyr::filter(agedby1 != agedby2) |> # remove fish aged by the same person
  format_double_reads()


################################################################
### simplify PSMFC reads

# no samples are aged by the same person
table(PSMFC_double_reads_format1$agedby1 == PSMFC_double_reads_format1$agedby2)
# FALSE
#  1937
PSMFC_double_reads_format2 <- PSMFC_double_reads_format1 |>
  dplyr::filter(agedby1 != agedby2) |> # remove fish aged by the same person
  dplyr::mutate(agedby1 = "reader1", agedby2 = "reader2") |> # rename readers to treat all readers equally
  format_double_reads()

PSMFC_double_reads_format3 <- PSMFC_double_reads_format1 |>
  dplyr::filter(agedby1 != agedby2) |> # remove fish aged by the same person
  format_double_reads()

# all_data <- rbind(
#   WDFW_double_reads_format2 |> dplyr::mutate(source = "WDFW"),
#   ODFW_double_reads_format2 |> dplyr::mutate(source = "ODFW"),
#   PSMFC_double_reads_format2 |> dplyr::mutate(source = "PSMFC")
# )


################################################################
### run models
# as of 2025-04-02, the "dev" branch of AgeingError is required 
# to use the functions below. Install via something like
# pak::pak("pfmc-assessments/AgeingError@dev")

# simplest model where all double reads are treated equal
all_data <- rbind(
  WDFW_double_reads_format2,
  ODFW_double_reads_format2,
  PSMFC_double_reads_format2
)

# write files in format required by ageing error software
dir_run1 <- "Data/Processed/ageing_error/run1_simple"
all_data |> AgeingError::write_files(dir = dir_run1)
run1_out <- AgeingError::run(dir = dir_run1)

run1_out$ErrorAndBiasArray["CV", "Age 0", "Reader 1"]
# [1] 0.06063202
# saving run1 output in format used by SS3 (40 is max population age in SS3 model)
run1_out$output$ErrorAndBiasArray[c("Expected_age", "SD"), 1 + 0:40, 1] |> 
  as.data.frame() |> 
  readr::write_csv("Data/Processed/ageing_error/final_ageing_error.csv")

### notes on applying simple model to subsets of the data (models not saved)
# all data CV = 0.0606
# WDFW only = 0.055
# ODFW only = 0.0694
# PSMFC only = 0.0598

# more complex model where each reader is separate, but still has a single shared CV and no bias
all_readers <- c(
  names(WDFW_double_reads_format3),
  names(ODFW_double_reads_format3),
  names(PSMFC_double_reads_format3)
) |>
  sort() |>
  unique()

# Ensure all dataframes have the same columns by adding missing columns with NA
for (reader in all_readers) {
  if (!reader %in% names(WDFW_double_reads_format3)) {
    WDFW_double_reads_format3[[reader]] <- -999
  }
  if (!reader %in% names(ODFW_double_reads_format3)) {
    ODFW_double_reads_format3[[reader]] <- -999
  }
  if (!reader %in% names(PSMFC_double_reads_format3)) {
    PSMFC_double_reads_format3[[reader]] <- -999
  }
}

# Reorder columns to ensure consistency
WDFW_double_reads_format4 <- WDFW_double_reads_format3[, all_readers]
ODFW_double_reads_format4 <- ODFW_double_reads_format3[, all_readers]
PSMFC_double_reads_format4 <- PSMFC_double_reads_format3[, all_readers]

all_data_all_readers <- rbind(
  WDFW_double_reads_format4,
  ODFW_double_reads_format4,
  PSMFC_double_reads_format4
)
# stats for report
nrow (all_data_all_readers)
# [1] 6339
lab1 <- !apply(all_data_all_readers[,1:4], 1, function(x) all(x == -999))
lab2 <- !apply(all_data_all_readers[,5:8], 1, function(x) all(x == -999))
table(lab1, lab2)
#        lab2
# lab1    FALSE TRUE
#   FALSE     0 4402
#   TRUE   1716  221

4402+1716+221
# [1] 6339

# run2 has separate readers but same single shared CV and no bias
dir_run2 <- "Data/Processed/ageing_error/run2_simple_all_readers"
all_data_all_readers |> AgeingError::write_files(dir = dir_run2)
run2_out <- AgeingError::run(dir = dir_run2)

run2_out$output$ErrorAndBiasArray["CV", "Age 0", "Reader 1"]
# [1] 0.06064513 # almost the same as the simpler model

# run 3 allows separate bias and CV for WDFW vs PSMFC
all_readers
# [1] "NMFS/BK"  "NMFS/EW"  "NMFS/LO"  "NWFSC/PM" "WDFW"     "WDFW/JT"  "WDFW/MS4" "WDFW/SR"
dir_run3 <- "Data/Processed/ageing_error/run3_compare_labs"
biasopt <- c(0, 0, 0, 0, 1, -5, -5, -5) # 0 = no bias, 1 = constant CV bias, -5 = mirror bias parameter
sigopt <- c(1, -1, -1, -1, 1, -5, -5, -5) # 1 = constant CV, -1 = mirror CV for reader 1, -5 = mirror CV for reader 5
all_data_all_readers |> AgeingError::write_files(dir = dir_run3, biasopt = biasopt, sigopt = sigopt)
run3_out <- AgeingError::run(dir = dir_run3)

run3_out$output$ErrorAndBiasArray["CV", "Age 0", c("Reader 1", "Reader 5")]
#   Reader 1   Reader 5
# 0.05947753 0.06151904

run3_out$model$par[1:3]
#    BiasPar      SDPar      SDPar
# 1.00596854 0.05947753 0.06151904

# run 4 allows separate bias and CV for each reader (arbitrarily assuming NWFSC/PM is unbiased)
all_readers
# [1] "NMFS/BK"  "NMFS/EW"  "NMFS/LO"  "NWFSC/PM" "WDFW"     "WDFW/JT"  "WDFW/MS4" "WDFW/SR"
dir_run4 <- "Data/Processed/ageing_error/run4_compare_labs"
biasopt <- c(0, 1, 1, 1, 1, 1, 1, 1) # 0 = no bias, 1 = constant CV bias, -5 = mirror bias parameter
sigopt <- c(1, 1, 1, 1, 1, 1, 1, 1) # 1 = constant CV, -1 = mirror CV for reader 1, -5 = mirror CV for reader 5
all_data_all_readers[,c(2:3, 1, 4:8)] |> AgeingError::write_files(dir = dir_run4, biasopt = biasopt, sigopt = sigopt)
run4_out <- AgeingError::run(dir = dir_run4)

run4_out$output$ErrorAndBiasArray["CV", "Age 0", c("Reader 1", "Reader 7")]
run4_out$model$par[1:7]
#   BiasPar   BiasPar   BiasPar   BiasPar   BiasPar   BiasPar   BiasPar
# 0.9995851 0.9893656 0.9995490 1.0267567 1.0150870 0.9730622 1.0236832
summary(run4_out$model$par[1:7])
#    Min. 1st Qu.  Median    Mean 3rd Qu.    Max.
#  0.9731  0.9945  0.9996  1.0039  1.0194  1.0268
run4_out$model$par[8:15]
#      SDPar      SDPar      SDPar      SDPar      SDPar      SDPar      SDPar      SDPar
# 0.03022009 0.05848543 0.06670974 0.06294592 0.07382336 0.05889063 0.04957072 0.05763505
summary(run4_out$model$par[8:15])
#    Min. 1st Qu.  Median    Mean 3rd Qu.    Max.
# 0.03022 0.05562 0.05869 0.05729 0.06389 0.07382


# run 5 explores alternative functions for variability
# applied to the simple assumption where all readers are equal
dir_run5 <- "Data/Processed/ageing_error/run5_nonlinear"
all_data |> AgeingError::write_files(dir = dir_run5, sigopt = c(2, rep(-1, 7)), maxage = 50)
run5_out <- AgeingError::run(dir = dir_run5)

# run 6 removes an outlier to see if it makes a difference
# applied to the simple assumption where all readers are equal
dir_run6 <- "Data/Processed/ageing_error/run6_nonlinear_no_outlier"
all_data |> dplyr::filter(reader1 != 48) |> # remove outlier
  AgeingError::write_files(dir = dir_run6, sigopt = c(2, rep(-1, 7)), maxage = 50)
run6_out <- AgeingError::run(dir = dir_run6)

# run 7 removes all old fish to see if CV continues to increase with age
# applied to the simple assumption where all readers are equal
dir_run7 <- "Data/Processed/ageing_error/run7_nonlinear_no_old_fish"
all_data |> dplyr::filter(reader1 < 40 & reader2 < 40) |> # remove age 40+ fish
  AgeingError::write_files(dir = dir_run7, sigopt = c(2, rep(-1, 7)), maxage = 40)
run7_out <- AgeingError::run(dir = dir_run7)


# run 8 removes all old fish but returns to the original linear assumption
# applied to the simple assumption where all readers are equal
dir_run8 <- "Data/Processed/ageing_error/run8_linear_no_old_fish"
all_data |> dplyr::filter(reader1 < 40 & reader2 < 40) |> # age 40+ fish
  AgeingError::write_files(dir = dir_run8, maxage = 40)
run8_out <- AgeingError::run(dir = dir_run8)

# trivial impact on estimated CV of excluding old fish
run1_out$model$par[1]
#      SDPar
# 0.06063202
run8_out$model$par[1]
#      SDPar
# 0.06043453



##############################################################################
### testing the impact on the assessment results
# read most recent model
inputs4.11 <- SS_read("Model_Runs/4.11_sex_selex_setup")
inputs4.12 <- inputs4.11
inputs4.12$dat$N_ageerror_definitions <- 1 # all age comps already associated with ageing error definition 1
inputs4.12$dat$ageerror <- read.csv("Data/Processed/ageing_error/final_ageing_error.csv")
inputs4.12$dir <- "Model_Runs/4.12_ageing_error"
SS_write(inputs4.12, dir = inputs4.12$dir, overwrite = TRUE)
r4ss::run("Model_Runs/4.12_ageing_error", skipfinished = FALSE)
mod4.11 <- SS_output(inputs4.11$dir, printstats = FALSE, verbose = FALSE)
mod4.12 <- SS_output(inputs4.12$dir, printstats = FALSE, verbose = FALSE)
SStableComparisons(SSsummarize(list(mod4.11, mod4.12)))
SSplotComparisons(SSsummarize(list(mod4.11, mod4.12)), subplots = 1)
#                    Label      model1      model2
# 1             TOTAL_like 1176.530000 1170.830000
# 2            Survey_like    0.886036    0.875494
# 3       Length_comp_like  278.495000  278.251000
# 4          Age_comp_like  908.168000  903.909000
# 5       Parm_priors_like    0.173946    0.171327
# 6   Recr_Virgin_millions   35.739800   35.729600
# 7              SR_LN(R0)   10.484000   10.483700
# 8            SR_BH_steep    0.718000    0.718000
# 9  NatM_uniform_Fem_GP_1    0.155415    0.155112
# 10 NatM_uniform_Mal_GP_1   -0.139348   -0.139253
# 11    L_at_Amax_Fem_GP_1   53.255900   53.220800
# 12    L_at_Amax_Mal_GP_1   -0.144460   -0.144094
# 13    VonBert_K_Fem_GP_1    0.138126    0.138426
# 14    VonBert_K_Mal_GP_1    0.365438    0.364657
# 15            SSB_Virgin   14.758700   14.816500
# 16           Bratio_2023    0.666852    0.659480
# 17         SPRratio_2022    0.664495    0.667943