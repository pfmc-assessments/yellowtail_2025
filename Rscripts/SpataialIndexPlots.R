library(dplyr)
library(tidyr)
library(r4ss)
library(tidyverse)
library(devtools)
#install_github("pfmc-assessments/indexwc")
library(indexwc)
library(purrr)
library(sdmTMB)
library(tibble)

#### Request 8

indexv1 <- read.csv("Data/Processed/STAR_requests/est_by_area.csv")%>%filter(area=="North of Cape Mendocino") #mendocino breaks  
index <- read.csv("Data/Confidential/stateruns/wcgbts/delta_gamma/index/est_by_area.csv") #state breaks
 
colnames(index)

OR<-index%>%filter(area=='OR')
WA<-index%>%filter(area=='WA')
mean(OR$est/(WA$est+OR$est))
mean(OR$est/(WA$est))

#showing states are just additive for mendocino breaks an not informative
ggplot(data=index,aes(x=year, y=est, lty=area, col=area))+
  geom_line()+
  theme_bw()

#combining into a single dataframe
index3<-index%>%filter(area=="North of Cape Mendocino")%>%
  rename(state=est)%>%
  left_join(indexv1%>%select(year, est))%>%
  rename(N_S=est)

#comparing both indices
ORWA<- ggplot(data=index3)+
  geom_line(col='red', aes(x=year,y=N_S))+
  geom_line(aes(x=year, y=state), col='blue')+
  theme_bw()
ORWA

png("figures/WA_OR2.png",res=600, width=4800, height=3000)
ORWA
dev.off()

#comparing OR vs WA in single wrapped plot with free scales
index2<-index%>%filter(area=='WA'|area=="OR")
wrapped<-ggplot(data=index2,aes(x=year, y=est))+
  geom_line(aes(col=area, group=area))+
  geom_ribbon(aes(ymin=lwr,ymax=upr, fill=area),  alpha=0.1)+
 # geom_line(aes(y=upr), lty=2)+
  facet_wrap(~area,scales="free")+
  theme_bw()
wrapped


png("figures/WA_ORscalesfree2.png",res=600, width=4800, height=3000)
wrapped
dev.off()

#for state index, looking at standardized TS
index3<-index2%>%group_by(area)%>%
  mutate(est_standardized=scale(est))

stand<-ggplot(data=index3,aes(x=year, y=est_standardized, lty=area, col=area))+
  geom_line()+
  #geom_ribbon(aes(ymin=lwr,ymax=upr, fill=area),  alpha=0.1)+
  theme_bw()
stand

png("figures/WA_ORstand.png",res=600, width=4800, height=3000)
stand
dev.off()

ggplot(data=index,aes(x=year, y=est))+
  geom_line(aes(col=area, group=area))+
 # geom_ribbon(aes(ymin=lwr,ymax=upr, fill=area),  alpha=0.1)+
  # geom_line(aes(y=upr), lty=2)+
  facet_wrap(~area,scales="free")+
  theme_bw()

ggplot(data=index%>%filter(area=="North of Cape Mendocino"|area=="South of Cape Mendocino"),aes(x=year, y=est))+
  geom_line(aes(col=area, group=area))+
  # geom_ribbon(aes(ymin=lwr,ymax=upr, fill=area),  alpha=0.1)+
  # geom_line(aes(y=upr), lty=2)+
  facet_wrap(~area,scales="free")+
  theme_bw()


png("figures/NS_mendo.png",res=600, width=4800, height=3000)
ggplot(data=index%>%filter(area=="North of Cape Mendocino"|area=="South of Cape Mendocino"),aes(x=year, y=est))+
  geom_line(aes(col=area, group=area))+
  # geom_ribbon(aes(ymin=lwr,ymax=upr, fill=area),  alpha=0.1)+
  # geom_line(aes(y=upr), lty=2)+
  facet_wrap(~area,scales="free")+
  theme_bw()
dev.off()


### Request 14
#### Comparison of coastwide indices
yellowtail_coast <- read.csv("Data/Processed/STAR_requests/est_by_area.csv")%>%filter(area=="Coastwide")%>%
  mutate(species="yellowtail")
widow_coast <- read.csv("Data/Processed/STAR_requests/est_Widow_coastwide.csv")%>%filter(area=="Coastwide")%>%
  mutate(species="widow")
canary_coast <- read.csv("Data/Processed/STAR_requests/est_Canary_coastwide.csv")%>%filter(area=="coastwide")%>%
  mutate(species="canary")
colnames(canary_coast)
colnames(yellowtail_coast)
coastwide<-yellowtail_coast%>%bind_rows(widow_coast)%>%bind_rows(canary_coast)

box<-data.frame(xmin=c(2013.5,2013.5,2013.5), xmax=c(2019.5,2019.5,2019.5), ymin = c(0,0,0),ymax = c(40000, 12500,100000), species=c("canary", "widow", "yellowtail"))

facet_coastwide <-ggplot(data=coastwide,aes(x=year, y=est, col=species))+
  geom_point(cex=1.5)+
  ggtitle("Coastwide WCGBTS Index")+
  # geom_ribbon(aes(ymin=lwr,ymax=upr, fill=area),  alpha=0.1)+
  # geom_line(aes(y=upr), lty=2)+
  geom_errorbar(aes(ymin = lwr, ymax = upr))+
  facet_wrap(~species,scales="free")+
  geom_rect(data=box, aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax =ymax), 
           alpha = .25,inherit.aes = FALSE)+
  xlim(c(2003, 2025))+
  theme_bw()

png("figures/STAR_request14/facet_coastwide.png",res=600, width=4800, height=3000)
facet_coastwide
dev.off()
