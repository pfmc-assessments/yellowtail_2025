## Oceanographic Index

### Oceanographic Index V1

1. Number of variables: 9
2. Number of cases/rows: 32
3. Variable List: 
    year: year ln(rec dev) was predicted from the oceanographic model
    fit: prediction of ln(rec dev) from oceanographic model
    se.fit: standard error of ln(rec dev) predictions (confidence interval SE)
    type: type of prediction as follows:
    	"Train" the model was fit to these data. Here: 1994 - 2019
    	"Predictions" out of sample predictions based on oceanographic conditions. Here: 2020 - 2024
    
    residuals: residuals of the fitted model
    uprP: upper bound of prediction interval
    lwrP: lower bound of prediction interval
    uprCI: upper bound of confidence interval
    lwrCI: lower bound of confidence interval
    se.p: standard error of prediction interval 
    
#### Data Treatment

For this index version the oceanographic model was fit to ln(re devs) from 1994 - 2019 and the last 5 years of oceanographic data, 2021 - 2024 were used for out of sample prediction.
This version used the "Expanded PacFIN" ln(rec devs) provided Feb. 24 2025

#### Oceanographic Conditions Included
  
This index is derived from the following oceanographic conditions
1. CutiSTI: Spring transition data calculated from the Coastal Upwelling Transport Index (ROMS)
2. DDegg: Degree Days during egg fertilization and incubation
3. LSTpjuv: long-shore transport during the pelagic juvenile life stage
4. ONIpjuv: Oceanic Nino Index during the pelagic juvenile lifestage 	
    	
    