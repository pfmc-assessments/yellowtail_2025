library(dplyr)
library(tidyr)
library(r4ss)
library(dplyr)
library(tidyverse)


model_name <- "5.03_smurf" #model to compare data to
model_dir <- here::here("Model_Runs",model_name)
inputs<- SS_read('model_runs/5.03_smurf')
modcatch <-inputs$dat$catch%>%filter(fleet==1)%>%filter(year!=-999)%>%select(catch)
rownames(modcatch) <- NULL
colnames(modcatch) <- NULL

#generating an empty dataframe to fill
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

#pulling in the catch data
catch <- readRDS("Data/Processed/catch_wide.rds")%>%
  dplyr::select(YEAR, WA, OR, CA,Foreign)
catch_tab$ComWA<-catch$WA
catch_tab$ComOR<-catch$OR
catch_tab$ComCA<-catch$CA
catch_tab$Foreign<-catch$Foreign

# read processed GEMM data and apply fleet numbers
  dead_discards <- readRDS("Data/Processed/gemm_discards_by_fleet.rds") |>
    dplyr::filter(fleet == "Commercial")
#fill in discard data for years with gemm
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
 
#### pulling in rec data
  
  rec_landings <-readRDS("Data/Confidential/rec/rec_wide.rds")
  rec_WA<-rec_landings%>%filter(State=="WA (mt)")
  
  for(irow in 1:nrow(rec_WA)){
    y <- rec_WA$RECFIN_YEAR[irow]
    subset <- catch_tab$Yr == y
    catch_tab$RecWA[subset] <- rec_WA$Dead_Catch[irow]
  }
  
rec_CA<-rec_landings%>%filter(State=="CA (mt)")
  
  for(irow in 1:nrow(rec_CA)){
    y <- rec_CA$RECFIN_YEAR[irow]
    subset <- catch_tab$Yr == y
    catch_tab$RecCA[subset] <- rec_CA$Dead_Catch[irow]
  }  
  
rec_OR<-rec_landings%>%filter(State=="OR (mt)")

for(irow in 1:nrow(rec_OR)){
  y <- rec_OR$RECFIN_YEAR[irow]
  subset <- catch_tab$Yr == y
  catch_tab$RecOR[subset] <- rec_OR$Dead_Catch[irow]
} 
  catch_tab$RecWA<- rec_landings%>%filter(State=="WA (mt)")
  catch_tab$ComOR<-catch$OR
  catch_tab$ComCA<-catch$CA

### ashop data 
  
  ashop_catch <-readRDS("Data/Confidential/ASHOP/ashop_catch.rds")
  
  for(irow in 1:nrow(ashop_catch)){
    y <- ashop_catch$YEAR[irow]
    subset <- catch_tab$Yr == y
    catch_tab$ASHOP[subset] <- ashop_catch$catch_mt[irow]
  } 
 
catch_tab<-  data.frame(year=catch_tab$Yr,round(catch_tab[2:12],1))


#writing in a csv to the tables - can transfer code to code chunk in quarto alternatively
catch_table <- catch_tab%>%select(-ComModelTotal)
write.csv(catch_table, "report/Tables/CatchTable.csv")  


#checking ASHOP and rec totals

ashop_catch_mod <-inputs$dat$catch%>%filter(fleet==2)%>%filter(year!=-999)%>%select(catch)
ashop_catch_compare <- cbind(catch_tab%>%select(year, ASHOP), ashop_catch_mod)

rec_catch_mod <-inputs$dat$catch%>%filter(fleet==3)%>%filter(year!=-999)%>%select(catch)
totalrec<-rowSums(catch_tab%>%select(RecWA, RecOR, RecCA))
rec_catch_compare <- cbind(catch_tab%>%select(year),totalrec,rec_catch_mod)
