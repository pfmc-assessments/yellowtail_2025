#V3.30.23.1;_safe;_compile_date:_Dec  5 2024;_Stock_Synthesis_by_Richard_Methot_(NOAA)_using_ADMB_13.2
#_Stock_Synthesis_is_a_work_of_the_U.S._Government_and_is_not_subject_to_copyright_protection_in_the_United_States.
#_Foreign_copyrights_may_apply._See_copyright.txt_for_more_information.
#_User_support_available_at:NMFS.Stock.Synthesis@noaa.gov
#_User_info_available_at:https://vlab.noaa.gov/group/stock-synthesis
#_Source_code_at:_https://github.com/nmfs-ost/ss3-source-code

#C file created using an r4ss function
#C file write time: 2025-03-24  13:47:57
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
3 #_Nblock_Patterns
 10 1 1 #_blocks_per_pattern 
# begin and end years of blocks
 2002 2002 2003 2003 2004 2004 2005 2005 2006 2006 2007 2007 2008 2008 2009 2009 2010 2010 2011 2024
 2002 2024
 2003 2024
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
 0.02 0.25 0.1531 -2.12 0.438 3 2 0 0 0 0 0 0 0 # NatM_uniform_Fem_GP_1
# Sex: 1  BioPattern: 1  Growth
 1 25 14.5452 22 99 0 3 0 0 0 0 0 0 0 # L_at_Amin_Fem_GP_1
 35 70 53.3305 55 99 0 2 0 0 0 0 0 0 0 # L_at_Amax_Fem_GP_1
 0.1 0.4 0.13892 0.1 99 0 3 0 0 0 0 0 0 0 # VonBert_K_Fem_GP_1
 0.03 0.16 0.106431 0.1 99 0 5 0 0 0 0 0 0 0 # CV_young_Fem_GP_1
 0.03 0.16 0.0401697 0.1 99 0 5 0 0 0 0 0 0 0 # CV_old_Fem_GP_1
# Sex: 1  BioPattern: 1  WtLen
 0 3 1.38743e-05 99 99 0 -50 0 0 0 0 0 0 0 # Wtlen_1_Fem_GP_1
 2 4 3.02201 99 99 0 -50 0 0 0 0 0 0 0 # Wtlen_2_Fem_GP_1
# Sex: 1  BioPattern: 1  Maturity&Fecundity
 30 56 10 42.49 99 0 -50 0 0 0 0 0 0 0 # Mat50%_Fem_GP_1
 -2 1 -0.67 -0.40078 99 0 -50 0 0 0 0 0 0 0 # Mat_slope_Fem_GP_1
 0 6 1.1185e-11 99 99 0 -50 0 0 0 0 0 0 0 # Eggs_scalar_Fem_GP_1
 2 7 4.59 4.59 99 0 -50 0 0 0 0 0 0 0 # Eggs_exp_len_Fem_GP_1
# Sex: 2  BioPattern: 1  NatMort
 -3 3 -0.129487 0 99 0 2 0 0 0 0 0 0 0 # NatM_uniform_Mal_GP_1
# Sex: 2  BioPattern: 1  Growth
 -1 1 0 0 99 0 -2 0 0 0 0 0 0 0 # L_at_Amin_Mal_GP_1
 -1 1 -0.148728 0 99 0 2 0 0 0 0 0 0 0 # L_at_Amax_Mal_GP_1
 -1 1 0.369316 0 99 0 3 0 0 0 0 0 0 0 # VonBert_K_Mal_GP_1
 -1 1 0 0 99 0 -5 0 0 0 0 0 0 0 # CV_young_Mal_GP_1
 -1 1 0.322268 0 99 0 5 0 0 0 0 0 0 0 # CV_old_Mal_GP_1
# Sex: 2  BioPattern: 1  WtLen
 0 3 1.18399e-05 99 99 0 -50 0 0 0 0 0 0 0 # Wtlen_1_Mal_GP_1
 2 4 3.06734 99 99 0 -50 0 0 0 0 0 0 0 # Wtlen_2_Mal_GP_1
# Hermaphroditism
#  Recruitment Distribution 
#  Cohort growth dev base
 0 2 1 1 99 0 -50 0 0 0 0 0 0 0 # CohortGrowDev
#  Movement
#  Platoon StDev Ratio 
#  Age Error from parameters
#  catch multiplier
#  fraction female, by GP
 0.001 0.999 0.5 0.5 0.5 0 -99 0 0 0 0 0 0 0 # FracFemale_GP_1
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
             5            20       10.5242            10             5             0          1          0          0          0          0          0          0          0 # SR_LN(R0)
           0.2             1         0.718         0.718         0.158             0         -6          0          0          0          0          0          0          0 # SR_BH_steep
           0.5           1.2        0.4997          0.67            99             0         -6          0          0          0          0          0          0          0 # SR_sigmaR
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
#  0.00510671 0.00535105 0.00551473 0.00557398 0.0055268 0.00541235 0.00533612 0.00546212 0.00601571 0.00733702 0.00984539 0.013917 0.0196898 0.0269207 0.0353043 0.0449694 0.0550457 0.0606719 0.0515188 0.0179121 -0.0362954 -0.0944321 -0.141987 -0.178643 -0.218271 -0.260999 -0.278728 -0.213745 -0.00631937 0.282284 0.149009 -0.16309 -0.338886 -0.362357 -0.350378 -0.23281 0.0914912 -0.0762907 -0.394053 -0.649101 -0.395326 -0.160874 0.498078 0.229177 0.157442 0.265525 0.00672501 -0.531086 -0.255136 0.0987151 -0.472498 0.175317 0.600247 0.0805372 0.176484 0.431919 -0.181197 0.681249 0.725656 0.457056 0.0272417 -0.214634 0.140761 0.103591 -0.404637 -0.0284871 0.371399 0.339258 0.68667 -0.0146768 -0.628794 -0.189743 0.0560919 -0.609806 0.606403 -0.371053 0.948154 -0.609082 0.606503 -0.174166 0.106824 0.154909 0.300242 -0.0782793 -0.0767691 -0.576059 -0.733408 -0.554814 -0.358819 -0.106412 -0.000375605 -6.25031e-05 0 0 0 0 0 0 0 0 0 0 0 0 0
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
# Commercial 1.6177e-06 1.84747e-06 3.22079e-06 3.05766e-05 2.68295e-05 2.68299e-05 7.22243e-06 1.6618e-06 1.69271e-06 9.59128e-07 2.27733e-06 2.2829e-06 2.94405e-06 3.60643e-06 4.27005e-06 8.58297e-06 5.59333e-06 6.25557e-06 6.9165e-06 9.51737e-06 8.24091e-06 8.9031e-06 9.56529e-06 1.02275e-05 1.08897e-05 1.15519e-05 1.34639e-05 4.54852e-05 7.77048e-05 0.000198186 6.08745e-05 7.15548e-05 9.49211e-05 7.35299e-05 4.03574e-05 7.91638e-05 0.000189198 0.00019994 0.000345858 0.000315234 0.000415506 0.000591757 0.00069492 0.000464045 0.000428436 0.000409754 0.000660126 0.000659391 0.000722324 0.00087798 0.0010102 0.00194319 0.00260781 0.0042083 0.0173685 0.0312759 0.0597574 0.0374607 0.0192429 0.0177481 0.013868 0.0169781 0.0177297 0.0225047 0.0126906 0.0164734 0.0163405 0.018971 0.0194379 0.0201581 0.0207258 0.025421 0.0241842 0.032868 0.0275264 0.0231451 0.0222762 0.0626071 0.054831 0.0532401 0.0697789 0.0444432 0.0352303 0.0542899 0.0647194 0.0494182 0.0314204 0.081529 0.120664 0.18186 0.179684 0.189345 0.269151 0.305654 0.352832 0.196509 0.124603 0.166061 0.16343 0.213882 0.176625 0.16423 0.138136 0.207257 0.199096 0.192161 0.17025 0.181136 0.0616723 0.0750095 0.0622743 0.0763278 0.0481583 0.0247881 0.00938543 0.0124666 0.0165732 0.00731419 0.00550657 0.00512734 0.00971729 0.0132849 0.020386 0.0258077 0.0189608 0.0230535 0.0304677 0.0228416 0.0427274 0.0500214 0.0511916 0.053127 0.0432647 0.0466314 0.0463604 0.043322 0.0942496 0.0942496 0.0942496 0.0942496 0.0942496 0.0942496 0.0942497 0.0942502 0.0942506 0.0942504 0.0942501 0.0942499
# At-Sea-Hake 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.0010239 0.000270594 0.00296657 0.00367372 0.0128822 0.00864772 0.0365748 0.0426325 0.02799 0.0151969 0.0450248 0.0423846 0.0327421 0.0148244 0.0238682 0.0388763 0.055264 0.0224575 0.0459997 0.0527154 0.0590927 0.0305657 0.0298819 0.0737304 0.0360617 0.0113537 0.00939817 0.0016891 0.00205199 0.00459305 0.0042693 0.00294837 0.00624462 0.00600976 0.0049381 0.00324103 0.0013577 0.0084402 0.00130709 0.00266487 0.00190617 0.00833481 0.00685436 0.00943431 0.00497265 0.00246022 0.000816307 0.00798254 0.000438757 0.000954541 0.000954541 0.000954541 0.000954541 0.000954541 0.000954541 0.000954542 0.000954546 0.00095455 0.000954549 0.000954546 0.000954544
# Recreational 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 6.26546e-07 1.2532e-06 1.44046e-06 1.92103e-06 2.40188e-06 2.88255e-06 3.36323e-06 3.84383e-06 4.32442e-06 5.12551e-06 5.04043e-06 4.40725e-06 6.34675e-06 5.86791e-06 3.11901e-06 2.98699e-06 2.47178e-06 3.34214e-06 5.90842e-06 4.73102e-06 9.45285e-06 1.22473e-05 1.48846e-05 1.70901e-05 1.48438e-05 1.26417e-05 1.56411e-05 1.86226e-05 2.08222e-05 1.80803e-05 3.16448e-05 2.92288e-05 2.20766e-05 1.68896e-05 2.02092e-05 1.43863e-05 1.1064e-05 1.82198e-05 1.94438e-05 0.000333999 4.16387e-05 4.70417e-05 0.000156575 0.000139879 0.00015329 0.000241484 0.000199837 0.00016945 0.000228922 0.000137642 0.000188456 0.00032262 0.000354988 0.000345419 0.000671139 0.000219971 0.000553032 0.00026599 0.00060133 0.000565292 0.000343288 0.000322154 0.000515382 0.000932169 0.000951246 0.00171009 0.000557273 0.000639972 0.000535089 0.000666449 0.000910523 0.000887295 0.000489038 0.000340699 0.000272994 0.000338362 0.000349577 0.000316035 0.000202316 0.000234503 0.000215751 0.00043135 0.000561226 0.000681025 0.000337443 0.00039119 0.000512551 0.00044961 0.000404957 0.000557669 0.000674892 0.000726911 0.000911786 0.000859574 0.00119463 0.00180065 0.00133404 0.00290228 0.00290228 0.00290228 0.00290228 0.00290228 0.00290228 0.00290228 0.0029023 0.00290231 0.00290231 0.0029023 0.00290229
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
           -30            15      -1.05236             0             1             0          2          0          0          0          0          0          0          0  #  LnQ_base_Triennial(5)
             0           0.5      0.291641             0             1             0          2          0          0          0          0          0          0          0  #  Q_extraSD_Triennial(5)
           -30            15      -1.23087             0             1             0          2          0          0          0          0          0          0          0  #  LnQ_base_WCGBTS(6)
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
 24 0 0 0 # 1 Commercial
 24 0 0 0 # 2 At-Sea-Hake
 24 0 0 0 # 3 Recreational
 24 0 0 0 # 4 PLACEHOLDER
 24 0 0 0 # 5 Triennial
 24 0 0 0 # 6 WCGBTS
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
            20            55       49.5375             0            99             0          1          0          0          0          0          0          0          0  #  Size_DblN_peak_Commercial(1)
           -20            70            70             0            99             0         -4          0          0          0          0          0          0          0  #  Size_DblN_top_logit_Commercial(1)
            -5            20       4.38678             0            99             0          3          0          0          0          0          0          0          0  #  Size_DblN_ascend_se_Commercial(1)
            -5            70            70             0            99             0         -4          0          0          0          0          0          0          0  #  Size_DblN_descend_se_Commercial(1)
          -999            25          -999             0            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_Commercial(1)
          -999            25          -999             0            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_Commercial(1)
# 2   At-Sea-Hake LenSelex
            20            55            55             0            99             0          1          0          0          0          0          0          0          0  #  Size_DblN_peak_At-Sea-Hake(2)
           -20            70            70             0            99             0         -4          0          0          0          0          0          0          0  #  Size_DblN_top_logit_At-Sea-Hake(2)
            -5            20       4.46156             0            99             0          3          0          0          0          0          0          0          0  #  Size_DblN_ascend_se_At-Sea-Hake(2)
            -5            70            70             0            99             0         -4          0          0          0          0          0          0          0  #  Size_DblN_descend_se_At-Sea-Hake(2)
          -999            25          -999             0            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_At-Sea-Hake(2)
          -999            25          -999             0            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_At-Sea-Hake(2)
# 3   Recreational LenSelex
            20            55        28.755             0            99             0          6          0          0          0          0          0          3          2  #  Size_DblN_peak_Recreational(3)
           -20            70           -20             0            99             0         -4          0          0          0          0          0          0          0  #  Size_DblN_top_logit_Recreational(3)
            -5            20       2.62805             0            99             0          6          0          0          0          0          0          3          2  #  Size_DblN_ascend_se_Recreational(3)
            -5            20            20             0            99             0         -4          0          0          0          0          0          3          2  #  Size_DblN_descend_se_Recreational(3)
          -999            25          -999             0            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_Recreational(3)
          -999            25          -999             0            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_Recreational(3)
# 4   PLACEHOLDER LenSelex
            20            55            55             0            99             0         -6          0          0          0          0          0          3          2  #  Size_DblN_peak_PLACEHOLDER(4)
           -20            70           -20             0            99             0         -4          0          0          0          0          0          0          0  #  Size_DblN_top_logit_PLACEHOLDER(4)
            -5            20       5.36503             0            99             0          6          0          0          0          0          0          3          2  #  Size_DblN_ascend_se_PLACEHOLDER(4)
            -5            70            20             0            99             0         -4          0          0          0          0          0          3          2  #  Size_DblN_descend_se_PLACEHOLDER(4)
          -999            25          -999             0            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_PLACEHOLDER(4)
          -999            25          -999             0            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_PLACEHOLDER(4)
# 5   Triennial LenSelex
            20            55            55             0            99             0         -1          0          0          0          0          0          0          0  #  Size_DblN_peak_Triennial(5)
           -20            70            70             0            99             0         -4          0          0          0          0          0          0          0  #  Size_DblN_top_logit_Triennial(5)
            -5            20       5.10114             0            99             0          3          0          0          0          0          0          0          0  #  Size_DblN_ascend_se_Triennial(5)
            -5            70            70             0            99             0         -4          0          0          0          0          0          0          0  #  Size_DblN_descend_se_Triennial(5)
          -999            25          -999             0            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_Triennial(5)
          -999            25          -999             0            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_Triennial(5)
# 6   WCGBTS LenSelex
            20            55       47.8215             0            99             0          1          0          0          0          0          0          0          0  #  Size_DblN_peak_WCGBTS(6)
           -20            70            70             0            99             0         -4          0          0          0          0          0          0          0  #  Size_DblN_top_logit_WCGBTS(6)
            -5            20       4.27885             0            99             0          3          0          0          0          0          0          0          0  #  Size_DblN_ascend_se_WCGBTS(6)
            -5            70            70             0            99             0         -4          0          0          0          0          0          0          0  #  Size_DblN_descend_se_WCGBTS(6)
          -999            25          -999             0            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_WCGBTS(6)
          -999            25          -999             0            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_WCGBTS(6)
# 1   Commercial AgeSelex
# 2   At-Sea-Hake AgeSelex
# 3   Recreational AgeSelex
# 4   PLACEHOLDER AgeSelex
# 5   Triennial AgeSelex
# 6   WCGBTS AgeSelex
#_No_Dirichlet parameters
# timevary selex parameters 
#_          LO            HI          INIT         PRIOR         PR_SD       PR_type    PHASE  #  parm_name
            20            55       32.4004             0            99             0      6  # Size_DblN_peak_Recreational(3)_BLK3repl_2003
            -5            20       3.00486             0            99             0      6  # Size_DblN_ascend_se_Recreational(3)_BLK3repl_2003
            -5            20        7.4153             0            99             0      6  # Size_DblN_descend_se_Recreational(3)_BLK3repl_2003
            20            55         33.46             0            99             0      6  # Size_DblN_peak_PLACEHOLDER(4)_BLK3repl_2003
            -5            20       2.72607             0            99             0      6  # Size_DblN_ascend_se_PLACEHOLDER(4)_BLK3repl_2003
            -5            70       8.84111             0            99             0      6  # Size_DblN_descend_se_PLACEHOLDER(4)_BLK3repl_2003
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
#      5    13     1     3     2     0     0     0     0     0     0     0
#      5    15     2     3     2     0     0     0     0     0     0     0
#      5    16     3     3     2     0     0     0     0     0     0     0
#      5    19     4     3     2     0     0     0     0     0     0     0
#      5    21     5     3     2     0     0     0     0     0     0     0
#      5    22     6     3     2     0     0     0     0     0     0     0
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
      4      1  0.037734
      4      2   0.24848
      4      3  0.007305
      4      4   0.02964
      4      5  0.069924
      4      6  0.099682
      5      1  0.243385
      5      4  0.021984
      5      5  0.182982
      5      6  0.130932
      5      3  0.023143
      5      2  0.133212
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

