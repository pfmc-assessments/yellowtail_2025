library(dplyr)
library(tidyr)
library(r4ss)
library(dplyr)
library(tidyverse)

indexv1 <- read.csv("Data/Confidential/est_by_area.csv")%>%filter(area=="North of Cape Mendocino")
index <- read.csv("Rscripts/yellowtail_rockfish/wcgbts/delta_gamma/index/est_by_area.csv")

colnames(index)

ggplot(data=index,aes(x=year, y=est, lty=area, col=area))+
  geom_line()+
  theme_bw()

index3<-index%>%filter(area=="North of Cape Mendocino")%>%
  rename(state=est)%>%
  left_join(indexv1%>%select(year, est))%>%
  rename(N_S=est)
#index2<-index%>%filter(area=='WA'|area=="OR"|area=="CA")


ORWA<- ggplot(data=index3)+
  geom_line(col='red', aes(x=year,y=N_S))+
  geom_line(aes(x=year, y=state), col='blue')+
  theme_bw()
ORWA

png("figures/WA_OR2.png",res=600, width=4800, height=3000)
ORWA
dev.off()

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
