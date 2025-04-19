model_name <- "5.03_smurf"
model_dir <- here::here("Model_Runs",model_name)
inputs<- SS_read('model_runs/2.02_bias_adjust')
modcatch <-inputs$dat$catch%>%filter(fleet==1)%>%select(catch)
rownames(modcatch) <- NULL
colnames(modcatch) <- NULL
catch_tab <-
  data.frame(Yr = sort(unique(inputs$dat$catch$year[inputs$dat$catch$year>=inputs[["dat"]][["styr"]]])),
             ComWA=NA,
             ComOR=NA,
             ComCA=NA,
             ComDiscards=NA,
             Foreign=NA,
             ComTotal=NA,
             ComModelTotal=modcatch,
             ASHOP=NA,
             RecWA=NA,
             RecOR=NA,
             RecCA=NA)
rownames(catch_tab) <- NULL
catch <- readRDS("Data/Processed/catch_wide.rds")%>%
  dplyr::select(YEAR, WA, OR, CA,Foreign)
catch_tab$ComWA<-catch$WA
catch_tab$ComOR<-catch$OR
catch_tab$ComCA<-catch$CA
catch_tab$Foreign<-catch$Foreign
  # read processed GEMM data and apply fleet numbers
  dead_discards <- readRDS("Data/Processed/gemm_discards_by_fleet.rds") |>
    dplyr::filter(fleet == "Commercial")
  for(irow in 1:nrow(dead_discards)){
    y <- dead_discards$year[irow]
    subset <- catch_tab$Yr == y
    catch_tab$ComDiscards[subset] <- dead_discards$catch[irow]
  }
  # inflate time series of catch prior to 2002 by the average rate from the Pikitch study
  # NOTE: an alternative would be to use a catch multiplier parameter with a time block but that seems more complex
  Prate<- 0.0451
  subset <- catch_tab$Yr < 2002
  catch_tab$ComDiscards[subset] <- 
    Prate *(catch_tab$ComOR[subset]+catch_tab$ComCA[subset]+catch_tab$ComWA[subset]+catch_tab$Foreign[subset])
  catch_tab$ComTotal<-catch_tab$ComWA + catch_tab$ComOR + catch_tab$ComCA + catch_tab$ComDiscards+catch_tab$Foreign
write.csv(catch_tab, "report/Tables/CatchTable.csv")  
