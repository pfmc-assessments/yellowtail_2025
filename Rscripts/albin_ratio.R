# csv contains the Yellowtail Rockfish rows form the 6 year-specific Tables 1 in 
# Albin et al. 1993 which contains county-specific catch estimates for 1981-1986
#
# CSV file matches format of the this file used for Lingcod in 2021:
# https://github.com/pfmc-assessments/lingcod/blob/main/data-raw/Albin_et_al_1993_Lingcod_rows.csv
# and code below is adapted from Kelli Johnson's code at
# https://github.com/pfmc-assessments/lingcod/blob/main/doc/catch.Rmd#L761-L855
# The numbers in the Albin et al. PDF were initially copied to 
# https://docs.google.com/spreadsheets/d/1xAeGBCw-xz1UaFx38A9tQvSzdY4kzi5p4aWCl7XJP28/edit?gid=0#gid=0
# and QA/QC'd in that sheet

file_albin <- 'data/Raw_not_confidential/yellowtail_rows_from_Albin_et_al_1993.csv'
data_albin <- read.csv(file = file_albin,
  skip = 2, header = TRUE, check.names = FALSE
) %>%
  rlang::set_names(paste(sep = "_",
    read.csv(
      file = file_albin,
      skip = 1, header = FALSE, check.names = FALSE, nrows = 1
    ),
    colnames(.))
  ) %>%
  dplyr::select(-NA_Table) |> 
  dplyr::rename(Year = "NA_Year") %>%
  tidyr::gather("type", "value", -Year) %>%
  tidyr::separate(type, into = c("Area", "type"), sep = "_") %>%
  tidyr::spread(key = "type", value = "value") %>%
  dplyr::arrange(Area) %>%
  dplyr::mutate(Source = "albinetal1993") %>%
  dplyr::filter(Area != "Total") %>%
  dplyr::group_by(Year) %>%
  dplyr::mutate(sum = sum(Est)) %>%
  dplyr::group_by(Area, Year) %>%
  dplyr::mutate(prop_source = Est / sum) %>%
  dplyr::ungroup()

albinmeanpropN <- data_albin %>%
          dplyr::group_by(Year) %>%
          dplyr::mutate(YearT = sum(Est)) %>%
          dplyr::ungroup() %>% dplyr::group_by(Area) %>%
          dplyr::summarize(wm = stats::weighted.mean(prop_source, w = YearT)) %>%
          dplyr::filter(grepl("Del", Area)) %>% dplyr::pull(wm)

albinmeanpropN
# [1] 0.0203143