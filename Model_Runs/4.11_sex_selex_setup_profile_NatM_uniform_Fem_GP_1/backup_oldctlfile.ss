#V3.30.23.1;_safe;_compile_date:_Dec  5 2024;_Stock_Synthesis_by_Richard_Methot_(NOAA)_using_ADMB_13.2
#_Stock_Synthesis_is_a_work_of_the_U.S._Government_and_is_not_subject_to_copyright_protection_in_the_United_States.
#_Foreign_copyrights_may_apply._See_copyright.txt_for_more_information.
#_User_support_available_at:NMFS.Stock.Synthesis@noaa.gov
#_User_info_available_at:https://vlab.noaa.gov/group/stock-synthesis
#_Source_code_at:_https://github.com/nmfs-ost/ss3-source-code

#C file created using an r4ss function
#C file write time: 2025-03-28  18:30:08
#_data_and_control_files: YTRK.North.data.ss // YTRK.North.control.ss
0  # 0 means do not read wtatage.ss; 1 means read and use wtatage.ss and also read and use growth parameters
1  #_N_Growth_Patterns (Growth Patterns, Morphs, Bio Patterns, GP are terms used interchangeably in SS3)
1 #_N_platoons_Within_GrowthPattern 
#_Cond 1 #_Platoon_within/between_stdev_ratio (no read if N_platoons=1)
#_Cond sd_ratio_rd < 0: platoon_sd_ratio parameter required after movement params.
#_Cond  1 #vector_platoon_dist_(-1_in_first_val_gives_normal_approx)
#
4 # recr_dist_method for parameters:  2=main effects for GP, Area, Settle timing; 3=each Settle entity; 4=none (only when N_GP*Nsettle*pop==1)
1 # not yet implemented; Future usage: Spawner-Recruitment: 1=global; 2=by area
1 #  number of recruitment settlement assignments 
0 # unused option
#GPattern month  area  age (for each settlement assignment)
 1 1 1 0
#
#_Cond 0 # N_movement_definitions goes here if Nareas > 1
#_Cond 1.0 # first age that moves (real age at begin of season, not integer) also cond on do_migration>0
#_Cond 1 1 1 2 4 10 # example move definition for seas=1, morph=1, source=1 dest=2, age1=4, age2=10
#
2 #_Nblock_Patterns
 2 1 #_blocks_per_pattern 
# begin and end years of blocks
 2004 2016 2017 2024
 2015 2024
#
# controls for all timevary parameters 
1 #_time-vary parm bound check (1=warn relative to base parm bounds; 3=no bound check); Also see env (3) and dev (5) options to constrain with base bounds
#
# AUTOGEN
 1 1 1 1 1 # autogen: 1st element for biology, 2nd for SR, 3rd for Q, 4th reserved, 5th for selex
# where: 0 = autogen time-varying parms of this category; 1 = read each time-varying parm line; 2 = read then autogen if parm min==-12345
#
#_Available timevary codes
#_Block types: 0: P_block=P_base*exp(TVP); 1: P_block=P_base+TVP; 2: P_block=TVP; 3: P_block=P_block(-1) + TVP
#_Block_trends: -1: trend bounded by base parm min-max and parms in transformed units (beware); -2: endtrend and infl_year direct values; -3: end and infl as fraction of base range
#_EnvLinks:  1: P(y)=P_base*exp(TVP*env(y));  2: P(y)=P_base+TVP*env(y);  3: P(y)=f(TVP,env_Zscore) w/ logit to stay in min-max;  4: P(y)=2.0/(1.0+exp(-TVP1*env(y) - TVP2))
#_DevLinks:  1: P(y)*=exp(dev(y)*dev_se;  2: P(y)+=dev(y)*dev_se;  3: random walk;  4: zero-reverting random walk with rho;  5: like 4 with logit transform to stay in base min-max
#_DevLinks(more):  21-25 keep last dev for rest of years
#
#_Prior_codes:  0=none; 6=normal; 1=symmetric beta; 2=CASAL's beta; 3=lognormal; 4=lognormal with biascorr; 5=gamma
#
# setup for M, growth, wt-len, maturity, fecundity, (hermaphro), recr_distr, cohort_grow, (movement), (age error), (catch_mult), sex ratio 
#_NATMORT
0 #_natM_type:_0=1Parm; 1=N_breakpoints;_2=Lorenzen;_3=agespecific;_4=agespec_withseasinterpolate;_5=BETA:_Maunder_link_to_maturity;_6=Lorenzen_range
  #_no additional input for selected M option; read 1P per morph
#
1 # GrowthModel: 1=vonBert with L1&L2; 2=Richards with L1&L2; 3=age_specific_K_incr; 4=age_specific_K_decr; 5=age_specific_K_each; 6=NA; 7=NA; 8=growth cessation
2 #_Age(post-settlement) for L1 (aka Amin); first growth parameter is size at this age; linear growth below this
25 #_Age(post-settlement) for L2 (aka Amax); 999 to treat as Linf
-999 #_exponential decay for growth above maxage (value should approx initial Z; -999 replicates 3.24; -998 to not allow growth above maxage)
0  #_placeholder for future growth feature
#
0 #_SD_add_to_LAA (set to 0.1 for SS2 V1.x compatibility)
0 #_CV_Growth_Pattern:  0 CV=f(LAA); 1 CV=F(A); 2 SD=F(LAA); 3 SD=F(A); 4 logSD=F(A)
#
2 #_maturity_option:  1=length logistic; 2=age logistic; 3=read age-maturity matrix by growth_pattern; 4=read age-fecundity; 5=disabled; 6=read length-maturity
1 #_First_Mature_Age
2 #_fecundity_at_length option:(1)eggs=Wt*(a+b*Wt);(2)eggs=a*L^b;(3)eggs=a*Wt^b; (4)eggs=a+b*L; (5)eggs=a+b*W
0 #_hermaphroditism option:  0=none; 1=female-to-male age-specific fxn; -1=male-to-female age-specific fxn
2 #_parameter_offset_approach for M, G, CV_G:  1- direct, no offset**; 2- male=fem_parm*exp(male_parm); 3: male=female*exp(parm) then old=young*exp(parm)
#_** in option 1, any male parameter with value = 0.0 and phase <0 is set equal to female parameter
#
#_growth_parms
#_ LO HI INIT PRIOR PR_SD PR_type PHASE env_var&link dev_link dev_minyr dev_maxyr dev_PH Block Block_Fxn
# Sex: 1  BioPattern: 1  NatMort
 0.02 0.25 0.152147 -2.12 0.438 3 2 0 0 0 0 0 0 0 # NatM_uniform_Fem_GP_1
# Sex: 1  BioPattern: 1  Growth
 1 25 14.608 22 99 0 3 0 0 0 0 0 0 0 # L_at_Amin_Fem_GP_1
 35 70 53.3826 55 99 0 2 0 0 0 0 0 0 0 # L_at_Amax_Fem_GP_1
 0.1 0.4 0.135034 0.1 99 0 3 0 0 0 0 0 0 0 # VonBert_K_Fem_GP_1
 0.03 0.16 0.109359 0.1 99 0 5 0 0 0 0 0 0 0 # CV_young_Fem_GP_1
 0.03 0.16 0.0402954 0.1 99 0 5 0 0 0 0 0 0 0 # CV_old_Fem_GP_1
# Sex: 1  BioPattern: 1  WtLen
 0 3 1.38743e-05 99 99 0 -50 0 0 0 0 0 0 0 # Wtlen_1_Fem_GP_1
 2 4 3.02201 99 99 0 -50 0 0 0 0 0 0 0 # Wtlen_2_Fem_GP_1
# Sex: 1  BioPattern: 1  Maturity&Fecundity
 1 30 10 99 99 0 -50 0 0 0 0 0 0 0 # Mat50%_Fem_GP_1
 -2 1 -0.67 99 99 0 -50 0 0 0 0 0 0 0 # Mat_slope_Fem_GP_1
 0 6 1.1185e-11 99 99 0 -50 0 0 0 0 0 0 0 # Eggs_scalar_Fem_GP_1
 2 7 4.59 99 99 0 -50 0 0 0 0 0 0 0 # Eggs_exp_len_Fem_GP_1
# Sex: 2  BioPattern: 1  NatMort
 -3 3 -0.140049 0 99 0 2 0 0 0 0 0 0 0 # NatM_uniform_Mal_GP_1
# Sex: 2  BioPattern: 1  Growth
 -1 1 0 0 99 0 -2 0 0 0 0 0 0 0 # L_at_Amin_Mal_GP_1
 -1 1 -0.144933 0 99 0 2 0 0 0 0 0 0 0 # L_at_Amax_Mal_GP_1
 -1 1 0.365849 0 99 0 3 0 0 0 0 0 0 0 # VonBert_K_Mal_GP_1
 -1 1 0 0 99 0 -5 0 0 0 0 0 0 0 # CV_young_Mal_GP_1
 -1 1 0.283209 0 99 0 5 0 0 0 0 0 0 0 # CV_old_Mal_GP_1
# Sex: 2  BioPattern: 1  WtLen
 0 3 1.18399e-05 99 99 0 -50 0 0 0 0 0 0 0 # Wtlen_1_Mal_GP_1
 2 4 3.06734 99 99 0 -50 0 0 0 0 0 0 0 # Wtlen_2_Mal_GP_1
# Hermaphroditism
#  Recruitment Distribution 
#  Cohort growth dev base
 0 2 1 99 99 0 -50 0 0 0 0 0 0 0 # CohortGrowDev
#  Movement
#  Platoon StDev Ratio 
#  Age Error from parameters
#  catch multiplier
#  fraction female, by GP
 0.001 0.999 0.5 99 0.5 0 -99 0 0 0 0 0 0 0 # FracFemale_GP_1
#  M2 parameter for each predator fleet
#
#_no timevary MG parameters
#
#_seasonal_effects_on_biology_parms
 0 0 0 0 0 0 0 0 0 0 #_femwtlen1,femwtlen2,mat1,mat2,fec1,fec2,Malewtlen1,malewtlen2,L1,K
#_ LO HI INIT PRIOR PR_SD PR_type PHASE
#_Cond -2 2 0 0 -1 99 -2 #_placeholder when no seasonal MG parameters
#
3 #_Spawner-Recruitment; Options: 1=NA; 2=Ricker; 3=std_B-H; 4=SCAA; 5=Hockey; 6=B-H_flattop; 7=survival_3Parm; 8=Shepherd_3Parm; 9=RickerPower_3parm
0  # 0/1 to use steepness in initial equ recruitment calculation
0  #  future feature:  0/1 to make realized sigmaR a function of SR curvature
#_          LO            HI          INIT         PRIOR         PR_SD       PR_type      PHASE    env-var    use_dev   dev_mnyr   dev_mxyr     dev_PH      Block    Blk_Fxn #  parm_name
             5            20       10.4345            10             5             0          1          0          0          0          0          0          0          0 # SR_LN(R0)
           0.2             1         0.718         0.718         0.158             0         -6          0          0          0          0          0          0          0 # SR_BH_steep
           0.4           1.2        0.4997          0.67            99             0         -6          0          0          0          0          0          0          0 # SR_sigmaR
            -5             5             0             0            99             0        -50          0          0          0          0          0          0          0 # SR_regime
             0             2             0             1            99             0        -50          0          0          0          0          0          0          0 # SR_autocorr
#_no timevary SR parameters
1 #do_recdev:  0=none; 1=devvector (R=F(SSB)+dev); 2=deviations (R=F(SSB)+dev); 3=deviations (R=R0*dev; dev2=R-f(SSB)); 4=like 3 with sum(dev2) adding penalty
1962 # first year of main recr_devs; early devs can precede this era
2018 # last year of main recr_devs; forecast devs start in following year
2 #_recdev phase 
1 # (0/1) to read 13 advanced options
 1932 #_recdev_early_start (0=none; neg value makes relative to recdev_start)
 5 #_recdev_early_phase
 5 #_forecast_recruitment phase (incl. late recr) (0 value resets to maxphase+1)
 1 #_lambda for Fcast_recr_like occurring before endyr+1
 1950.5 #_last_yr_nobias_adj_in_MPD; begin of ramp
 1976.9 #_first_yr_fullbias_adj_in_MPD; begin of plateau
 2016.5 #_last_yr_fullbias_adj_in_MPD
 2021.6 #_end_yr_for_ramp_in_MPD (can be in forecast to shape ramp, but SS3 sets bias_adj to 0.0 for fcast yrs)
 0.7855 #_max_bias_adj_in_MPD (typical ~0.8; -3 sets all years to 0.0; -2 sets all non-forecast yrs w/ estimated recdevs to 1.0; -1 sets biasadj=1.0 for all yrs w/ recdevs)
 0 #_period of cycles in recruitment (N parms read below)
 -6 #min rec_dev
 6 #max rec_dev
 0 #_read_recdevs
#_end of advanced SR options
#
#_placeholder for full parameter lines for recruitment cycles
# read specified recr devs
#_year Input_value
#
# all recruitment deviations
#  1932E 1933E 1934E 1935E 1936E 1937E 1938E 1939E 1940E 1941E 1942E 1943E 1944E 1945E 1946E 1947E 1948E 1949E 1950E 1951E 1952E 1953E 1954E 1955E 1956E 1957E 1958E 1959E 1960E 1961E 1962R 1963R 1964R 1965R 1966R 1967R 1968R 1969R 1970R 1971R 1972R 1973R 1974R 1975R 1976R 1977R 1978R 1979R 1980R 1981R 1982R 1983R 1984R 1985R 1986R 1987R 1988R 1989R 1990R 1991R 1992R 1993R 1994R 1995R 1996R 1997R 1998R 1999R 2000R 2001R 2002R 2003R 2004R 2005R 2006R 2007R 2008R 2009R 2010R 2011R 2012R 2013R 2014R 2015R 2016R 2017R 2018R 2019F 2020F 2021F 2022F 2023F 2024F 2025F 2026F 2027F 2028F 2029F 2030F 2031F 2032F 2033F 2034F 2035F 2036F
#  -0.000620984 -0.00086482 -0.00121226 -0.00169826 -0.00234077 -0.00311608 -0.00393731 -0.00466064 -0.00510241 -0.0049493 -0.00378435 -0.00117038 0.00314824 0.00895827 0.0156295 0.0222867 0.0268511 0.024951 0.0111896 -0.0171795 -0.0562485 -0.0954767 -0.123522 -0.140279 -0.165355 -0.205503 -0.224861 -0.161647 0.0358566 0.291086 0.214165 -0.101629 -0.301775 -0.328187 -0.274768 -0.161372 0.156102 -0.000368028 -0.314023 -0.566233 -0.331445 -0.11569 0.57507 0.309058 0.133862 0.303297 -0.0495765 -0.5327 -0.296884 0.0457218 -0.522654 0.123913 0.54466 0.0249223 0.169076 0.385029 -0.197359 0.728672 0.781114 0.519683 0.0423642 -0.340394 0.219443 0.16913 -0.389347 0.00234687 0.51034 0.311702 0.818979 -0.0232721 -0.6506 -0.207786 -0.0159775 -0.729021 0.517515 -0.442877 0.866211 -0.799529 0.426268 -0.277596 0.0485344 0.107633 0.241221 -0.203605 -0.106596 -0.49084 -0.523929 -0.214613 -0.0866497 -0.0517642 1.85686e-05 5.78532e-06 0 0 0 0 0 0 0 0 0 0 0 0 0
#
#Fishing Mortality info 
0.3 # F ballpark value in units of annual_F
1984 # F ballpark year (neg value to disable)
1 # F_Method:  1=Pope midseason rate; 2=F as parameter; 3=F as hybrid; 4=fleet-specific parm/hybrid (#4 is superset of #2 and #3 and is recommended)
0.95 # max F (methods 2-4) or harvest fraction (method 1)
# F_Method 1:  no additional input needed
#
#_initial_F_parms; for each fleet x season that has init_catch; nest season in fleet; count = 0
#_for unconstrained init_F, use an arbitrary initial catch and set lambda=0 for its logL
#_ LO HI INIT PRIOR PR_SD  PR_type  PHASE
#
# F rates by fleet x season
#_year:  1889 1890 1891 1892 1893 1894 1895 1896 1897 1898 1899 1900 1901 1902 1903 1904 1905 1906 1907 1908 1909 1910 1911 1912 1913 1914 1915 1916 1917 1918 1919 1920 1921 1922 1923 1924 1925 1926 1927 1928 1929 1930 1931 1932 1933 1934 1935 1936 1937 1938 1939 1940 1941 1942 1943 1944 1945 1946 1947 1948 1949 1950 1951 1952 1953 1954 1955 1956 1957 1958 1959 1960 1961 1962 1963 1964 1965 1966 1967 1968 1969 1970 1971 1972 1973 1974 1975 1976 1977 1978 1979 1980 1981 1982 1983 1984 1985 1986 1987 1988 1989 1990 1991 1992 1993 1994 1995 1996 1997 1998 1999 2000 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020 2021 2022 2023 2024 2025 2026 2027 2028 2029 2030 2031 2032 2033 2034 2035 2036
# seas:  1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
# Commercial 1.53231e-06 1.74995e-06 3.05078e-06 2.89626e-05 2.54133e-05 2.54138e-05 6.84122e-06 1.57409e-06 1.60336e-06 9.08495e-07 2.15709e-06 2.16236e-06 2.78858e-06 3.41597e-06 4.04454e-06 8.12965e-06 5.2979e-06 5.92515e-06 6.55117e-06 9.01466e-06 7.80561e-06 8.43281e-06 9.06002e-06 9.68722e-06 1.03144e-05 1.09416e-05 1.27526e-05 4.30824e-05 7.36e-05 0.000187717 5.76591e-05 6.77753e-05 8.99074e-05 6.96461e-05 3.82258e-05 7.49824e-05 0.000179204 0.00018938 0.000327592 0.000298588 0.000393567 0.000560517 0.000658242 0.000439559 0.000405831 0.000388137 0.000625302 0.000624613 0.000684241 0.000831734 0.000957102 0.00184142 0.00247205 0.00399098 0.0164808 0.0297079 0.0568472 0.0357258 0.0183826 0.0169704 0.0132717 0.0162598 0.0169949 0.0215939 0.0121928 0.0158429 0.0157357 0.0182967 0.0187816 0.0195163 0.0201057 0.0247021 0.0235305 0.031987 0.0267751 0.0224696 0.0215601 0.0603659 0.0527 0.0509067 0.0662658 0.0419281 0.0330514 0.0507651 0.0604594 0.0461407 0.0292621 0.0755527 0.111235 0.166977 0.164733 0.173442 0.245615 0.276803 0.316782 0.175881 0.111818 0.150147 0.149885 0.199577 0.16834 0.159256 0.13571 0.205175 0.199418 0.194295 0.173583 0.184882 0.0625694 0.0745889 0.0610662 0.0744265 0.0469916 0.0242208 0.00917545 0.0121706 0.0161222 0.00706446 0.00526045 0.00484435 0.00911584 0.0124448 0.0191673 0.0244408 0.0181166 0.0222144 0.0295847 0.0223603 0.0421985 0.0500057 0.0518678 0.0545063 0.044832 0.0486073 0.0485243 0.0454681 0.0829643 0.0829643 0.0829643 0.0829643 0.0829643 0.0829643 0.0829645 0.0829646 0.0829647 0.0829647 0.0829646 0.0829645
# At-Sea-Hake 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.0011336 0.000298552 0.00326279 0.00403382 0.0141481 0.00952997 0.0406177 0.0479647 0.0320266 0.0175564 0.0522149 0.0495048 0.0385598 0.0177167 0.0289365 0.0479309 0.0692551 0.0288782 0.0603035 0.0703818 0.0798398 0.0416343 0.0400341 0.0970045 0.0466813 0.0144611 0.0117684 0.00208168 0.00249149 0.0055084 0.00506923 0.00346817 0.00727913 0.00694395 0.00565827 0.00368714 0.00153704 0.00953904 0.00148031 0.00169408 0.00121828 0.0053417 0.00441317 0.00612889 0.00327092 0.0016402 0.000550072 0.00542491 0.000300305 0.000547957 0.000547957 0.000547957 0.000547957 0.000547957 0.000547957 0.000547958 0.000547959 0.000547959 0.000547959 0.000547959 0.000547958
# Recreational 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 9.31419e-07 1.86301e-06 2.14142e-06 2.85588e-06 3.57079e-06 4.28542e-06 5.00006e-06 5.71473e-06 6.43043e-06 7.62405e-06 7.50049e-06 6.56131e-06 9.45359e-06 8.74553e-06 4.65158e-06 4.45798e-06 3.69386e-06 5.00383e-06 8.87282e-06 7.11748e-06 1.4234e-05 1.8458e-05 2.24497e-05 2.5804e-05 2.24429e-05 1.91494e-05 2.37303e-05 2.83006e-05 3.16797e-05 2.7524e-05 4.81619e-05 4.44315e-05 3.34836e-05 2.5545e-05 3.04703e-05 2.16379e-05 1.66076e-05 2.72845e-05 2.89165e-05 0.000492891 6.11098e-05 6.88794e-05 0.000229129 0.000204511 0.000223789 0.000350777 0.000288375 0.00024332 0.000328256 0.000197856 0.000271658 0.000462077 0.00050548 0.000491284 0.000954369 0.000313754 0.000799184 0.000389714 0.000887798 0.000848814 0.000523768 0.00049487 0.000795525 0.00144643 0.00147567 0.0026733 0.0008662 0.000980439 0.000810351 0.00100982 0.00138232 0.00134726 0.000742414 0.000519707 0.000416501 0.000455732 0.000706667 0.000625728 0.000401147 0.000475219 0.000449995 0.000926675 0.00123274 0.00151112 0.000746211 0.000858924 0.00113015 0.0010041 0.000918573 0.000805452 0.00098393 0.00106532 0.00133474 0.00125243 0.00172147 0.00256509 0.00188029 0.00343091 0.00343091 0.00343091 0.00343091 0.00343091 0.00343091 0.00343091 0.00343092 0.00343092 0.00343092 0.00343092 0.00343091
# PLACEHOLDER 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
#
#_Q_setup for fleets with cpue or survey or deviation data
#_1:  fleet number
#_2:  link type: 1=simple q; 2=mirror; 3=power (+1 parm); 4=mirror with scale (+1p); 5=offset (+1p); 6=offset & power (+2p)
#_     where power is applied as y = q * x ^ (1 + power); so a power value of 0 has null effect
#_     and with the offset included it is y = q * (x + offset) ^ (1 + power)
#_3:  extra input for link, i.e. mirror fleet# or dev index number
#_4:  0/1 to select extra sd parameter
#_5:  0/1 for biasadj or not
#_6:  0/1 to float
#_   fleet      link link_info  extra_se   biasadj     float  #  fleetname
         5         1         0         1         0         0  #  Triennial
         6         1         0         1         0         0  #  WCGBTS
-9999 0 0 0 0 0
#
#_Q_parameters
#_          LO            HI          INIT         PRIOR         PR_SD       PR_type      PHASE    env-var    use_dev   dev_mnyr   dev_mxyr     dev_PH      Block    Blk_Fxn  #  parm_name
           -30            15     -0.899242             0             1             0          2          0          0          0          0          0          0          0  #  LnQ_base_Triennial(5)
             0           0.5      0.286375             0             1             0          2          0          0          0          0          0          0          0  #  Q_extraSD_Triennial(5)
           -30            15      -1.10434             0             1             0          2          0          0          0          0          0          0          0  #  LnQ_base_WCGBTS(6)
             0           0.5             0             0             1             0        -99          0          0          0          0          0          0          0  #  Q_extraSD_WCGBTS(6)
#_no timevary Q parameters
#
#_size_selex_patterns
#Pattern:_0;  parm=0; selex=1.0 for all sizes
#Pattern:_1;  parm=2; logistic; with 95% width specification
#Pattern:_5;  parm=2; mirror another size selex; PARMS pick the min-max bin to mirror
#Pattern:_11; parm=2; selex=1.0  for specified min-max population length bin range
#Pattern:_15; parm=0; mirror another age or length selex
#Pattern:_6;  parm=2+special; non-parm len selex
#Pattern:_43; parm=2+special+2;  like 6, with 2 additional param for scaling (mean over bin range)
#Pattern:_8;  parm=8; double_logistic with smooth transitions and constant above Linf option
#Pattern:_9;  parm=6; simple 4-parm double logistic with starting length; parm 5 is first length; parm 6=1 does desc as offset
#Pattern:_21; parm=2*special; non-parm len selex, read as N break points, then N selex parameters
#Pattern:_22; parm=4; double_normal as in CASAL
#Pattern:_23; parm=6; double_normal where final value is directly equal to sp(6) so can be >1.0
#Pattern:_24; parm=6; double_normal with sel(minL) and sel(maxL), using joiners
#Pattern:_2;  parm=6; double_normal with sel(minL) and sel(maxL), using joiners, back compatibile version of 24 with 3.30.18 and older
#Pattern:_25; parm=3; exponential-logistic in length
#Pattern:_27; parm=special+3; cubic spline in length; parm1==1 resets knots; parm1==2 resets all 
#Pattern:_42; parm=special+3+2; cubic spline; like 27, with 2 additional param for scaling (mean over bin range)
#_discard_options:_0=none;_1=define_retention;_2=retention&mortality;_3=all_discarded_dead;_4=define_dome-shaped_retention
#_Pattern Discard Male Special
 24 0 3 0 # 1 Commercial
 24 0 3 0 # 2 At-Sea-Hake
 24 0 3 0 # 3 Recreational
 0 0 0 0 # 4 PLACEHOLDER
 24 0 3 0 # 5 Triennial
 24 0 3 0 # 6 WCGBTS
#
#_age_selex_patterns
#Pattern:_0; parm=0; selex=1.0 for ages 0 to maxage
#Pattern:_10; parm=0; selex=1.0 for ages 1 to maxage
#Pattern:_11; parm=2; selex=1.0  for specified min-max age
#Pattern:_12; parm=2; age logistic
#Pattern:_13; parm=8; age double logistic. Recommend using pattern 18 instead.
#Pattern:_14; parm=nages+1; age empirical
#Pattern:_15; parm=0; mirror another age or length selex
#Pattern:_16; parm=2; Coleraine - Gaussian
#Pattern:_17; parm=nages+1; empirical as random walk  N parameters to read can be overridden by setting special to non-zero
#Pattern:_41; parm=2+nages+1; // like 17, with 2 additional param for scaling (mean over bin range)
#Pattern:_18; parm=8; double logistic - smooth transition
#Pattern:_19; parm=6; simple 4-parm double logistic with starting age
#Pattern:_20; parm=6; double_normal,using joiners
#Pattern:_26; parm=3; exponential-logistic in age
#Pattern:_27; parm=3+special; cubic spline in age; parm1==1 resets knots; parm1==2 resets all 
#Pattern:_42; parm=2+special+3; // cubic spline; with 2 additional param for scaling (mean over bin range)
#Age patterns entered with value >100 create Min_selage from first digit and pattern from remainder
#_Pattern Discard Male Special
 10 0 0 0 # 1 Commercial
 10 0 0 0 # 2 At-Sea-Hake
 10 0 0 0 # 3 Recreational
 10 0 0 0 # 4 PLACEHOLDER
 10 0 0 0 # 5 Triennial
 10 0 0 0 # 6 WCGBTS
#
#_          LO            HI          INIT         PRIOR         PR_SD       PR_type      PHASE    env-var    use_dev   dev_mnyr   dev_mxyr     dev_PH      Block    Blk_Fxn  #  parm_name
# 1   Commercial LenSelex
            20            55       46.6442             0            99             0          1          0          0          0          0          0          0          0  #  Size_DblN_peak_Commercial(1)
           -20            70            70             0            99             0         -4          0          0          0          0          0          0          0  #  Size_DblN_top_logit_Commercial(1)
            -5            20       3.97917             0            99             0          3          0          0          0          0          0          0          0  #  Size_DblN_ascend_se_Commercial(1)
            -5            70            70             0            99             0         -4          0          0          0          0          0          0          0  #  Size_DblN_descend_se_Commercial(1)
          -999            25          -999             0            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_Commercial(1)
          -999            25          -999             0            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_Commercial(1)
           -10            10             0             0            99             0        -99          0          0          0          0          0          0          0  #  SzSel_Male_Peak_Commercial(1)
           -10            10             0             0            99             0        -99          0          0          0          0          0          0          0  #  SzSel_Male_Ascend_Commercial(1)
           -10            10             0             0            99             0        -99          0          0          0          0          0          0          0  #  SzSel_Male_Descend_Commercial(1)
           -10            10             0             0            99             0        -99          0          0          0          0          0          0          0  #  SzSel_Male_Final_Commercial(1)
             0             2             1             0            99             0        -99          0          0          0          0          0          0          0  #  SzSel_Male_Scale_Commercial(1)
# 2   At-Sea-Hake LenSelex
            20            55            55             0            99             0          1          0          0          0          0          0          2          2  #  Size_DblN_peak_At-Sea-Hake(2)
           -20            70            70             0            99             0         -4          0          0          0          0          0          0          0  #  Size_DblN_top_logit_At-Sea-Hake(2)
            -5            20       4.40253             0            99             0          3          0          0          0          0          0          2          2  #  Size_DblN_ascend_se_At-Sea-Hake(2)
            -5            70            70             0            99             0         -4          0          0          0          0          0          0          0  #  Size_DblN_descend_se_At-Sea-Hake(2)
          -999            25          -999             0            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_At-Sea-Hake(2)
          -999            25          -999             0            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_At-Sea-Hake(2)
           -10            10             0             0            99             0        -99          0          0          0          0          0          0          0  #  SzSel_Male_Peak_At-Sea-Hake(2)
           -10            10             0             0            99             0        -99          0          0          0          0          0          0          0  #  SzSel_Male_Ascend_At-Sea-Hake(2)
           -10            10             0             0            99             0        -99          0          0          0          0          0          0          0  #  SzSel_Male_Descend_At-Sea-Hake(2)
           -10            10             0             0            99             0        -99          0          0          0          0          0          0          0  #  SzSel_Male_Final_At-Sea-Hake(2)
             0             2             1             0            99             0        -99          0          0          0          0          0          0          0  #  SzSel_Male_Scale_At-Sea-Hake(2)
# 3   Recreational LenSelex
            20            55       30.5443             0            99             0          6          0          0          0          0          0          1          2  #  Size_DblN_peak_Recreational(3)
           -20            70           -20             0            99             0         -4          0          0          0          0          0          0          0  #  Size_DblN_top_logit_Recreational(3)
            -5            20       3.06221             0            99             0          6          0          0          0          0          0          0          0  #  Size_DblN_ascend_se_Recreational(3)
            -5            20       8.18996             0            99             0          4          0          0          0          0          0          1          2  #  Size_DblN_descend_se_Recreational(3)
          -999            25          -999             0            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_Recreational(3)
          -999            25          -999             0            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_Recreational(3)
           -10            10             0             0            99             0        -99          0          0          0          0          0          0          0  #  SzSel_Male_Peak_Recreational(3)
           -10            10             0             0            99             0        -99          0          0          0          0          0          0          0  #  SzSel_Male_Ascend_Recreational(3)
           -10            10      -1.65065             0            99             0          6          0          0          0          0          0          0          0  #  SzSel_Male_Descend_Recreational(3)
           -10            10             0             0            99             0        -99          0          0          0          0          0          0          0  #  SzSel_Male_Final_Recreational(3)
             0             2      0.650392             0            99             0          6          0          0          0          0          0          0          0  #  SzSel_Male_Scale_Recreational(3)
# 4   PLACEHOLDER LenSelex
# 5   Triennial LenSelex
            20            55            55             0            99             0         -1          0          0          0          0          0          0          0  #  Size_DblN_peak_Triennial(5)
           -20            70            70             0            99             0         -4          0          0          0          0          0          0          0  #  Size_DblN_top_logit_Triennial(5)
            -5            20       5.07356             0            99             0          3          0          0          0          0          0          0          0  #  Size_DblN_ascend_se_Triennial(5)
            -5            70            70             0            99             0         -4          0          0          0          0          0          0          0  #  Size_DblN_descend_se_Triennial(5)
          -999            25          -999             0            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_Triennial(5)
          -999            25          -999             0            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_Triennial(5)
           -10            10             0             0            99             0        -99          0          0          0          0          0          0          0  #  SzSel_Male_Peak_Triennial(5)
           -10            10             0             0            99             0        -99          0          0          0          0          0          0          0  #  SzSel_Male_Ascend_Triennial(5)
           -10            10             0             0            99             0        -99          0          0          0          0          0          0          0  #  SzSel_Male_Descend_Triennial(5)
           -10            10             0             0            99             0        -99          0          0          0          0          0          0          0  #  SzSel_Male_Final_Triennial(5)
             0             2             1             0            99             0        -99          0          0          0          0          0          0          0  #  SzSel_Male_Scale_Triennial(5)
# 6   WCGBTS LenSelex
            20            55       47.8376             0            99             0          1          0          0          0          0          0          0          0  #  Size_DblN_peak_WCGBTS(6)
           -20            70            70             0            99             0         -4          0          0          0          0          0          0          0  #  Size_DblN_top_logit_WCGBTS(6)
            -5            20       4.27722             0            99             0          3          0          0          0          0          0          0          0  #  Size_DblN_ascend_se_WCGBTS(6)
            -5            70            70             0            99             0         -4          0          0          0          0          0          0          0  #  Size_DblN_descend_se_WCGBTS(6)
          -999            25          -999             0            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_WCGBTS(6)
          -999            25          -999             0            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_WCGBTS(6)
           -10            10             0             0            99             0        -99          0          0          0          0          0          0          0  #  SzSel_Male_Peak_WCGBTS(6)
           -10            10             0             0            99             0        -99          0          0          0          0          0          0          0  #  SzSel_Male_Ascend_WCGBTS(6)
           -10            10             0             0            99             0        -99          0          0          0          0          0          0          0  #  SzSel_Male_Descend_WCGBTS(6)
           -10            10             0             0            99             0        -99          0          0          0          0          0          0          0  #  SzSel_Male_Final_WCGBTS(6)
             0             2             1             0            99             0        -99          0          0          0          0          0          0          0  #  SzSel_Male_Scale_WCGBTS(6)
# 1   Commercial AgeSelex
# 2   At-Sea-Hake AgeSelex
# 3   Recreational AgeSelex
# 4   PLACEHOLDER AgeSelex
# 5   Triennial AgeSelex
# 6   WCGBTS AgeSelex
#_No_Dirichlet parameters
# timevary selex parameters 
#_          LO            HI          INIT         PRIOR         PR_SD       PR_type    PHASE  #  parm_name
            20            55       47.4714             0            99             0      6  # Size_DblN_peak_At-Sea-Hake(2)_BLK2repl_2015
            -5            20       3.45819             0            99             0      6  # Size_DblN_ascend_se_At-Sea-Hake(2)_BLK2repl_2015
            20            55       32.0884             0            99             0      6  # Size_DblN_peak_Recreational(3)_BLK1repl_2004
            20            55       35.3373             0            99             0      6  # Size_DblN_peak_Recreational(3)_BLK1repl_2017
            -5            20       5.90738             0            99             0      6  # Size_DblN_descend_se_Recreational(3)_BLK1repl_2004
            -5            20       8.67228             0            99             0      6  # Size_DblN_descend_se_Recreational(3)_BLK1repl_2017
# info on dev vectors created for selex parms are reported with other devs after tag parameter section 
#
0   #  use 2D_AR1 selectivity? (0/1)
#_no 2D_AR1 selex offset used
#_specs:  fleet, ymin, ymax, amin, amax, sigma_amax, use_rho, len1/age2, devphase, before_range, after_range
#_sigma_amax>amin means create sigma parm for each bin from min to sigma_amax; sigma_amax<0 means just one sigma parm is read and used for all bins
#_needed parameters follow each fleet's specifications
# -9999  0 0 0 0 0 0 0 0 0 0 # terminator
#
# Tag loss and Tag reporting parameters go next
0  # TG_custom:  0=no read and autogen if tag data exist; 1=read
#_Cond -6 6 1 1 2 0.01 -4 0 0 0 0 0 0 0  #_placeholder if no parameters
#
# deviation vectors for timevary parameters
#  base   base first block   block  env  env   dev   dev   dev   dev   dev
#  type  index  parm trend pattern link  var  vectr link _mnyr  mxyr phase  dev_vector
#      5    12     1     2     2     0     0     0     0     0     0     0
#      5    14     2     2     2     0     0     0     0     0     0     0
#      5    23     3     1     2     0     0     0     0     0     0     0
#      5    26     5     1     2     0     0     0     0     0     0     0
     #
# Input variance adjustments factors: 
 #_1=add_to_survey_CV
 #_2=add_to_discard_stddev
 #_3=add_to_bodywt_CV
 #_4=mult_by_lencomp_N
 #_5=mult_by_agecomp_N
 #_6=mult_by_size-at-age_N
 #_7=mult_by_generalized_sizecomp
#_factor  fleet  value
      4      1  0.035145
      4      2  0.264277
      4      3  0.007447
      4      4  0.030608
      4      5  0.076482
      4      6  0.091935
      5      1  0.210445
      5      4  0.021984
      5      5  0.149247
      5      6  0.126917
      5      3  0.022016
      5      2  0.148289
 -9999   1    0  # terminator
#
5 #_maxlambdaphase
1 #_sd_offset; must be 1 if any growthCV, sigmaR, or survey extraSD is an estimated parameter
# read 3 changes to default Lambdas (default value is 1.0)
# Like_comp codes:  1=surv; 2=disc; 3=mnwt; 4=length; 5=age; 6=SizeFreq; 7=sizeage; 8=catch; 9=init_equ_catch; 
# 10=recrdev; 11=parm_prior; 12=parm_dev; 13=CrashPen; 14=Morphcomp; 15=Tag-comp; 16=Tag-negbin; 17=F_ballpark; 18=initEQregime
#like_comp fleet  phase  value  sizefreq_method
 1 1 1 0 0
 1 2 1 0 0
 17 1 5 0 0
-9999  1  1  1  1  #  terminator
#
# lambdas (for info only; columns are phases)
#  0 0 0 0 0 #_CPUE/survey:_1
#  0 0 0 0 0 #_CPUE/survey:_2
#  0 0 0 0 0 #_CPUE/survey:_3
#  0 0 0 0 0 #_CPUE/survey:_4
#  1 1 1 1 1 #_CPUE/survey:_5
#  1 1 1 1 1 #_CPUE/survey:_6
#  1 1 1 1 1 #_lencomp:_1
#  1 1 1 1 1 #_lencomp:_2
#  1 1 1 1 1 #_lencomp:_3
#  0 0 0 0 0 #_lencomp:_4
#  1 1 1 1 1 #_lencomp:_5
#  1 1 1 1 1 #_lencomp:_6
#  1 1 1 1 1 #_agecomp:_1
#  1 1 1 1 1 #_agecomp:_2
#  1 1 1 1 1 #_agecomp:_3
#  0 0 0 0 0 #_agecomp:_4
#  1 1 1 1 1 #_agecomp:_5
#  1 1 1 1 1 #_agecomp:_6
#  1 1 1 1 1 #_init_equ_catch1
#  1 1 1 1 1 #_init_equ_catch2
#  1 1 1 1 1 #_init_equ_catch3
#  1 1 1 1 1 #_init_equ_catch4
#  1 1 1 1 1 #_init_equ_catch5
#  1 1 1 1 1 #_init_equ_catch6
#  1 1 1 1 1 #_recruitments
#  1 1 1 1 1 #_parameter-priors
#  1 1 1 1 1 #_parameter-dev-vectors
#  1 1 1 1 1 #_crashPenLambda
#  1 1 1 1 0 # F_ballpark_lambda
0 # (0/1/2) read specs for more stddev reporting: 0 = skip, 1 = read specs for reporting stdev for selectivity, size, and numbers, 2 = add options for M,Dyn. Bzero, SmryBio
 # 0 2 0 0 # Selectivity: (1) fleet, (2) 1=len/2=age/3=both, (3) year, (4) N selex bins
 # 0 0 # Growth: (1) growth pattern, (2) growth ages
 # 0 0 0 # Numbers-at-age: (1) area(-1 for all), (2) year, (3) N ages
 # -1 # list of bin #'s for selex std (-1 in first bin to self-generate)
 # -1 # list of ages for growth std (-1 in first bin to self-generate)
 # -1 # list of ages for NatAge std (-1 in first bin to self-generate)
999

