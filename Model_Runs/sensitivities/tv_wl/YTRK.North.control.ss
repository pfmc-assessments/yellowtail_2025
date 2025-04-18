#C file created using an r4ss function
#C file write time: 2025-04-18  13:57:25
#
0 # 0 means do not read wtatage.ss; 1 means read and usewtatage.ss and also read and use growth parameters
1 #_N_Growth_Patterns
1 #_N_platoons_Within_GrowthPattern
4 # recr_dist_method for parameters
1 # not yet implemented; Future usage:Spawner-Recruitment; 1=global; 2=by area
1 # number of recruitment settlement assignments 
0 # unused option
# for each settlement assignment:
#_GPattern	month	area	age
1	1	1	0	#_recr_dist_pattern1
#
#_Cond 0 # N_movement_definitions goes here if N_areas > 1
#_Cond 1.0 # first age that moves (real age at begin of season, not integer) also cond on do_migration>0
#_Cond 1 1 1 2 4 10 # example move definition for seas=1, morph=1, source=1 dest=2, age1=4, age2=10
#
3 #_Nblock_Patterns
2 1 21 #_blocks_per_pattern
#_begin and end years of blocks
2004 2016 2017 2024
2015 2024
2003 2003 2004 2004 2005 2005 2006 2006 2007 2007 2008 2008 2009 2009 2010 2010 2011 2011 2012 2012 2013 2013 2014 2014 2015 2015 2016 2016 2017 2017 2018 2018 2019 2019 2021 2021 2022 2022 2023 2023 2024 2024
#
# controls for all timevary parameters 
1 #_env/block/dev_adjust_method for all time-vary parms (1=warn relative to base parm bounds; 3=no bound check)
#
# AUTOGEN
1 1 1 1 1 # autogen: 1st element for biology, 2nd for SR, 3rd for Q, 4th reserved, 5th for selex
# where: 0 = autogen all time-varying parms; 1 = read each time-varying parm line; 2 = read then autogen if parm min==-12345
#
# setup for M, growth, maturity, fecundity, recruitment distibution, movement
#
0 #_natM_type:_0=1Parm; 1=N_breakpoints;_2=Lorenzen;_3=agespecific;_4=agespec_withseasinterpolate;_5=Maunder_M;_6=Age-range_Lorenzen
#_no additional input for selected M option; read 1P per morph
1 # GrowthModel: 1=vonBert with L1&L2; 2=Richards with L1&L2; 3=age_specific_K_incr; 4=age_specific_K_decr;5=age_specific_K_each; 6=NA; 7=NA; 8=growth cessation
2 #_Age(post-settlement)_for_L1;linear growth below this
25 #_Growth_Age_for_L2 (999 to use as Linf)
-999 #_exponential decay for growth above maxage (value should approx initial Z; -999 replicates 3.24; -998 to not allow growth above maxage)
0 #_placeholder for future growth feature
#
0 #_SD_add_to_LAA (set to 0.1 for SS2 V1.x compatibility)
0 #_CV_Growth_Pattern:  0 CV=f(LAA); 1 CV=F(A); 2 SD=F(LAA); 3 SD=F(A); 4 logSD=F(A)
2 #_maturity_option:  1=length logistic; 2=age logistic; 3=read age-maturity matrix by growth_pattern; 4=read age-fecundity; 5=disabled; 6=read length-maturity
1 #_First_Mature_Age
2 #_fecundity option:(1)eggs=Wt*(a+b*Wt);(2)eggs=a*L^b;(3)eggs=a*Wt^b; (4)eggs=a+b*L; (5)eggs=a+b*W
0 #_hermaphroditism option:  0=none; 1=female-to-male age-specific fxn; -1=male-to-female age-specific fxn
2 #_parameter_offset_approach (1=none, 2= M, G, CV_G as offset from female-GP1, 3=like SS2 V1.x)
#
#_growth_parms
#_LO	HI	INIT	PRIOR	PR_SD	PR_type	PHASE	env_var&link	dev_link	dev_minyr	dev_maxyr	dev_PH	Block	Block_Fxn
 0.02	 0.25	      0.126	-2.07	0.31	3	  2	0	0	0	0	0	0	0	#_NatM_p_1_Fem_GP_1  
    1	   25	    15.0337	   22	  99	0	  3	0	0	0	0	0	0	0	#_L_at_Amin_Fem_GP_1 
   35	   70	    53.8936	   55	  99	0	  2	0	0	0	0	0	0	0	#_L_at_Amax_Fem_GP_1 
  0.1	  0.4	    0.13556	  0.1	  99	0	  3	0	0	0	0	0	0	0	#_VonBert_K_Fem_GP_1 
 0.03	 0.16	     0.0989	  0.1	  99	0	  5	0	0	0	0	0	0	0	#_CV_young_Fem_GP_1  
 0.03	 0.16	    0.04357	  0.1	  99	0	  5	0	0	0	0	0	0	0	#_CV_old_Fem_GP_1    
    0	    4	1.38743e-05	   99	  99	0	-50	0	0	0	0	0	3	2	#_Wtlen_1_Fem_GP_1   
    0	    4	    3.02201	   99	  99	0	-50	0	0	0	0	0	3	2	#_Wtlen_2_Fem_GP_1   
    1	   30	         10	   99	  99	0	-50	0	0	0	0	0	0	0	#_Mat50%_Fem_GP_1    
   -2	    1	      -0.67	   99	  99	0	-50	0	0	0	0	0	0	0	#_Mat_slope_Fem_GP_1 
    0	    6	 1.1185e-11	   99	  99	0	-50	0	0	0	0	0	0	0	#_Eggs_alpha_Fem_GP_1
    2	    7	       4.59	   99	  99	0	-50	0	0	0	0	0	0	0	#_Eggs_beta_Fem_GP_1 
   -3	    3	    -0.1386	    0	  99	0	  2	0	0	0	0	0	0	0	#_NatM_p_1_Mal_GP_1  
   -1	    1	          0	    0	  99	0	 -2	0	0	0	0	0	0	0	#_L_at_Amin_Mal_GP_1 
   -1	    1	     -0.149	    0	  99	0	  2	0	0	0	0	0	0	0	#_L_at_Amax_Mal_GP_1 
   -1	    1	     0.3779	    0	  99	0	  3	0	0	0	0	0	0	0	#_VonBert_K_Mal_GP_1 
   -1	    1	          0	    0	  99	0	 -5	0	0	0	0	0	0	0	#_CV_young_Mal_GP_1  
   -1	    1	    0.16921	    0	  99	0	  5	0	0	0	0	0	0	0	#_CV_old_Mal_GP_1    
    0	    4	1.18399e-05	   99	  99	0	-50	0	0	0	0	0	3	2	#_Wtlen_1_Mal_GP_1   
    0	    4	    3.06734	   99	  99	0	-50	0	0	0	0	0	3	2	#_Wtlen_2_Mal_GP_1   
    0	    2	          1	   99	  99	0	-50	0	0	0	0	0	0	0	#_CohortGrowDev      
0.001	0.999	        0.5	   99	 0.5	0	-99	0	0	0	0	0	0	0	#_FracFemale_GP_1    
#_timevary MG parameters
#_LO	HI	INIT	PRIOR	PR_SD	PR_type	PHASE
0	4	 8.5889e-06	99	99	0	-50	#_Wtlen_1_Fem_GP_1_BLK3repl_2003
0	4	8.56242e-06	99	99	0	-50	#_Wtlen_1_Fem_GP_1_BLK3repl_2004
0	4	7.58035e-06	99	99	0	-50	#_Wtlen_1_Fem_GP_1_BLK3repl_2005
0	4	2.02044e-05	99	99	0	-50	#_Wtlen_1_Fem_GP_1_BLK3repl_2006
0	4	2.66415e-05	99	99	0	-50	#_Wtlen_1_Fem_GP_1_BLK3repl_2007
0	4	1.39797e-05	99	99	0	-50	#_Wtlen_1_Fem_GP_1_BLK3repl_2008
0	4	2.04629e-05	99	99	0	-50	#_Wtlen_1_Fem_GP_1_BLK3repl_2009
0	4	 1.9994e-05	99	99	0	-50	#_Wtlen_1_Fem_GP_1_BLK3repl_2010
0	4	1.20991e-05	99	99	0	-50	#_Wtlen_1_Fem_GP_1_BLK3repl_2011
0	4	1.22696e-05	99	99	0	-50	#_Wtlen_1_Fem_GP_1_BLK3repl_2012
0	4	1.45218e-05	99	99	0	-50	#_Wtlen_1_Fem_GP_1_BLK3repl_2013
0	4	1.61293e-05	99	99	0	-50	#_Wtlen_1_Fem_GP_1_BLK3repl_2014
0	4	 1.4354e-05	99	99	0	-50	#_Wtlen_1_Fem_GP_1_BLK3repl_2015
0	4	1.43647e-05	99	99	0	-50	#_Wtlen_1_Fem_GP_1_BLK3repl_2016
0	4	1.62252e-05	99	99	0	-50	#_Wtlen_1_Fem_GP_1_BLK3repl_2017
0	4	 1.1848e-05	99	99	0	-50	#_Wtlen_1_Fem_GP_1_BLK3repl_2018
0	4	1.53089e-05	99	99	0	-50	#_Wtlen_1_Fem_GP_1_BLK3repl_2019
0	4	1.10368e-05	99	99	0	-50	#_Wtlen_1_Fem_GP_1_BLK3repl_2021
0	4	1.25644e-05	99	99	0	-50	#_Wtlen_1_Fem_GP_1_BLK3repl_2022
0	4	4.49824e-05	99	99	0	-50	#_Wtlen_1_Fem_GP_1_BLK3repl_2023
0	4	1.87726e-05	99	99	0	-50	#_Wtlen_1_Fem_GP_1_BLK3repl_2024
0	4	    3.15369	99	99	0	-50	#_Wtlen_2_Fem_GP_1_BLK3repl_2003
0	4	    3.15208	99	99	0	-50	#_Wtlen_2_Fem_GP_1_BLK3repl_2004
0	4	    3.18693	99	99	0	-50	#_Wtlen_2_Fem_GP_1_BLK3repl_2005
0	4	    2.92499	99	99	0	-50	#_Wtlen_2_Fem_GP_1_BLK3repl_2006
0	4	    2.84548	99	99	0	-50	#_Wtlen_2_Fem_GP_1_BLK3repl_2007
0	4	    3.01451	99	99	0	-50	#_Wtlen_2_Fem_GP_1_BLK3repl_2008
0	4	    2.92017	99	99	0	-50	#_Wtlen_2_Fem_GP_1_BLK3repl_2009
0	4	    2.92594	99	99	0	-50	#_Wtlen_2_Fem_GP_1_BLK3repl_2010
0	4	    3.05776	99	99	0	-50	#_Wtlen_2_Fem_GP_1_BLK3repl_2011
0	4	    3.05319	99	99	0	-50	#_Wtlen_2_Fem_GP_1_BLK3repl_2012
0	4	    3.01957	99	99	0	-50	#_Wtlen_2_Fem_GP_1_BLK3repl_2013
0	4	    2.99358	99	99	0	-50	#_Wtlen_2_Fem_GP_1_BLK3repl_2014
0	4	    3.01695	99	99	0	-50	#_Wtlen_2_Fem_GP_1_BLK3repl_2015
0	4	    3.00653	99	99	0	-50	#_Wtlen_2_Fem_GP_1_BLK3repl_2016
0	4	    2.97693	99	99	0	-50	#_Wtlen_2_Fem_GP_1_BLK3repl_2017
0	4	     3.0591	99	99	0	-50	#_Wtlen_2_Fem_GP_1_BLK3repl_2018
0	4	    2.99561	99	99	0	-50	#_Wtlen_2_Fem_GP_1_BLK3repl_2019
0	4	    3.08972	99	99	0	-50	#_Wtlen_2_Fem_GP_1_BLK3repl_2021
0	4	    3.04884	99	99	0	-50	#_Wtlen_2_Fem_GP_1_BLK3repl_2022
0	4	    2.71734	99	99	0	-50	#_Wtlen_2_Fem_GP_1_BLK3repl_2023
0	4	    2.93913	99	99	0	-50	#_Wtlen_2_Fem_GP_1_BLK3repl_2024
0	4	1.12309e-05	99	99	0	-50	#_Wtlen_1_Mal_GP_1_BLK3repl_2003
0	4	1.43026e-05	99	99	0	-50	#_Wtlen_1_Mal_GP_1_BLK3repl_2004
0	4	1.32106e-05	99	99	0	-50	#_Wtlen_1_Mal_GP_1_BLK3repl_2005
0	4	3.95162e-05	99	99	0	-50	#_Wtlen_1_Mal_GP_1_BLK3repl_2006
0	4	1.67269e-05	99	99	0	-50	#_Wtlen_1_Mal_GP_1_BLK3repl_2007
0	4	1.71836e-05	99	99	0	-50	#_Wtlen_1_Mal_GP_1_BLK3repl_2008
0	4	2.17036e-05	99	99	0	-50	#_Wtlen_1_Mal_GP_1_BLK3repl_2009
0	4	 3.0408e-05	99	99	0	-50	#_Wtlen_1_Mal_GP_1_BLK3repl_2010
0	4	8.25016e-06	99	99	0	-50	#_Wtlen_1_Mal_GP_1_BLK3repl_2011
0	4	9.31348e-06	99	99	0	-50	#_Wtlen_1_Mal_GP_1_BLK3repl_2012
0	4	1.46778e-05	99	99	0	-50	#_Wtlen_1_Mal_GP_1_BLK3repl_2013
0	4	2.51873e-05	99	99	0	-50	#_Wtlen_1_Mal_GP_1_BLK3repl_2014
0	4	1.57071e-05	99	99	0	-50	#_Wtlen_1_Mal_GP_1_BLK3repl_2015
0	4	1.10081e-05	99	99	0	-50	#_Wtlen_1_Mal_GP_1_BLK3repl_2016
0	4	1.23867e-05	99	99	0	-50	#_Wtlen_1_Mal_GP_1_BLK3repl_2017
0	4	9.12432e-06	99	99	0	-50	#_Wtlen_1_Mal_GP_1_BLK3repl_2018
0	4	2.10888e-05	99	99	0	-50	#_Wtlen_1_Mal_GP_1_BLK3repl_2019
0	4	2.27514e-05	99	99	0	-50	#_Wtlen_1_Mal_GP_1_BLK3repl_2021
0	4	8.56822e-06	99	99	0	-50	#_Wtlen_1_Mal_GP_1_BLK3repl_2022
0	4	1.25808e-05	99	99	0	-50	#_Wtlen_1_Mal_GP_1_BLK3repl_2023
0	4	1.86687e-05	99	99	0	-50	#_Wtlen_1_Mal_GP_1_BLK3repl_2024
0	4	    3.08922	99	99	0	-50	#_Wtlen_2_Mal_GP_1_BLK3repl_2003
0	4	    3.01872	99	99	0	-50	#_Wtlen_2_Mal_GP_1_BLK3repl_2004
0	4	    3.04529	99	99	0	-50	#_Wtlen_2_Mal_GP_1_BLK3repl_2005
0	4	    2.74802	99	99	0	-50	#_Wtlen_2_Mal_GP_1_BLK3repl_2006
0	4	    2.97063	99	99	0	-50	#_Wtlen_2_Mal_GP_1_BLK3repl_2007
0	4	    2.95971	99	99	0	-50	#_Wtlen_2_Mal_GP_1_BLK3repl_2008
0	4	    2.90974	99	99	0	-50	#_Wtlen_2_Mal_GP_1_BLK3repl_2009
0	4	    2.82049	99	99	0	-50	#_Wtlen_2_Mal_GP_1_BLK3repl_2010
0	4	    3.16309	99	99	0	-50	#_Wtlen_2_Mal_GP_1_BLK3repl_2011
0	4	    3.13773	99	99	0	-50	#_Wtlen_2_Mal_GP_1_BLK3repl_2012
0	4	    3.01979	99	99	0	-50	#_Wtlen_2_Mal_GP_1_BLK3repl_2013
0	4	    2.87365	99	99	0	-50	#_Wtlen_2_Mal_GP_1_BLK3repl_2014
0	4	    2.99658	99	99	0	-50	#_Wtlen_2_Mal_GP_1_BLK3repl_2015
0	4	    3.08207	99	99	0	-50	#_Wtlen_2_Mal_GP_1_BLK3repl_2016
0	4	    3.05096	99	99	0	-50	#_Wtlen_2_Mal_GP_1_BLK3repl_2017
0	4	    3.13381	99	99	0	-50	#_Wtlen_2_Mal_GP_1_BLK3repl_2018
0	4	    2.91255	99	99	0	-50	#_Wtlen_2_Mal_GP_1_BLK3repl_2019
0	4	    2.90488	99	99	0	-50	#_Wtlen_2_Mal_GP_1_BLK3repl_2021
0	4	    3.15268	99	99	0	-50	#_Wtlen_2_Mal_GP_1_BLK3repl_2022
0	4	    3.05158	99	99	0	-50	#_Wtlen_2_Mal_GP_1_BLK3repl_2023
0	4	    2.94456	99	99	0	-50	#_Wtlen_2_Mal_GP_1_BLK3repl_2024
# info on dev vectors created for MGparms are reported with other devs after tag parameter section
#
#_seasonal_effects_on_biology_parms
0 0 0 0 0 0 0 0 0 0 #_femwtlen1,femwtlen2,mat1,mat2,fec1,fec2,Malewtlen1,malewtlen2,L1,K
#_ LO HI INIT PRIOR PR_SD PR_type PHASE
#_Cond -2 2 0 0 -1 99 -2 #_placeholder when no seasonal MG parameters
#
3 #_Spawner-Recruitment; 2=Ricker; 3=std_B-H; 4=SCAA;5=Hockey; 6=B-H_flattop; 7=survival_3Parm;8=Shepard_3Parm
0 # 0/1 to use steepness in initial equ recruitment calculation
0 # future feature: 0/1 to make realized sigmaR a function of SR curvature
#_LO	HI	INIT	PRIOR	PR_SD	PR_type	PHASE	env-var	use_dev	dev_mnyr	dev_mxyr	dev_PH	Block	Blk_Fxn # parm_name
  5	 20	   12	   10	    5	0	  1	0	0	0	0	0	0	0	#_SR_LN(R0)  
0.2	  1	0.718	0.718	0.158	0	 -6	0	0	0	0	0	0	0	#_SR_BH_steep
0.4	1.2	  0.5	 0.67	   99	0	 -6	0	0	0	0	0	0	0	#_SR_sigmaR  
 -5	  5	    0	    0	   99	0	-50	0	0	0	0	0	0	0	#_SR_regime  
  0	  2	    0	    1	   99	0	-50	0	0	0	0	0	0	0	#_SR_autocorr
#_no timevary SR parameters
1 #do_recdev:  0=none; 1=devvector (R=F(SSB)+dev); 2=deviations (R=F(SSB)+dev); 3=deviations (R=R0*dev; dev2=R-f(SSB)); 4=like 3 with sum(dev2) adding penalty
1962 # first year of main recr_devs; early devs can preceed this era
2018 # last year of main recr_devs; forecast devs start in following year
2 #_recdev phase
1 # (0/1) to read 13 advanced options
1932 #_recdev_early_start (0=none; neg value makes relative to recdev_start)
5 #_recdev_early_phase
5 #_forecast_recruitment phase (incl. late recr) (0 value resets to maxphase+1)
1 #_lambda for Fcast_recr_like occurring before endyr+1
1950.62 #_last_yr_nobias_adj_in_MPD; begin of ramp
1975.09 #_first_yr_fullbias_adj_in_MPD; begin of plateau
2015.12 #_last_yr_fullbias_adj_in_MPD
2024.92 #_end_yr_for_ramp_in_MPD (can be in forecast to shape ramp, but SS sets bias_adj to 0.0 for fcast yrs)
0.8053 #_max_bias_adj_in_MPD (-1 to override ramp and set biasadj=1.0 for all estimated recdevs)
0 #_period of cycles in recruitment (N parms read below)
-6 #min rec_dev
6 #max rec_dev
0 #_read_recdevs
#_end of advanced SR options
#
#_placeholder for full parameter lines for recruitment cycles
# read specified recr devs
#_Yr Input_value
#
#Fishing Mortality info
0.3 # F ballpark
1984 # F ballpark year (neg value to disable)
1 # F_Method:  1=Pope; 2=instan. F; 3=hybrid (hybrid is recommended)
0.95 # max F or harvest rate, depends on F_Method
#
#_initial_F_parms; count = 0
#
#_Q_setup for fleets with cpue or survey data
#_fleet	link	link_info	extra_se	biasadj	float  #  fleetname
    4	1	0	1	0	0	#_H&L_survey
    5	1	0	1	0	0	#_Triennial 
    6	1	0	1	0	0	#_WCGBTS    
    7	1	0	1	0	0	#_SMURF     
-9999	0	0	0	0	0	#_terminator
#_Q_parms(if_any);Qunits_are_ln(q)
#_LO	HI	INIT	PRIOR	PR_SD	PR_type	PHASE	env-var	use_dev	dev_mnyr	dev_mxyr	dev_PH	Block	Blk_Fxn  #  parm_name
-30	 15	-1	0	1	0	  2	0	0	0	0	0	0	0	#_LnQ_base_H&L_survey(4) 
  0	0.5	 0	0	1	0	-99	0	0	0	0	0	0	0	#_Q_extraSD_H&L_survey(4)
-30	 15	-1	0	1	0	  2	0	0	0	0	0	0	0	#_LnQ_base_Triennial(5)  
  0	0.5	 0	0	1	0	-99	0	0	0	0	0	0	0	#_Q_extraSD_Triennial(5) 
-30	 15	-1	0	1	0	  2	0	0	0	0	0	0	0	#_LnQ_base_WCGBTS(6)     
  0	0.5	 0	0	1	0	-99	0	0	0	0	0	0	0	#_Q_extraSD_WCGBTS(6)    
-30	 15	-1	0	1	0	  2	0	0	0	0	0	0	0	#_LnQ_base_SMURF(7)      
  0	0.5	 0	0	1	0	-99	0	0	0	0	0	0	0	#_Q_extraSD_SMURF(7)     
#_no timevary Q parameters
#
#_size_selex_patterns
#_Pattern	Discard	Male	Special
24	0	3	0	#_1 Commercial  
24	0	3	0	#_2 At-Sea-Hake 
24	0	3	0	#_3 Recreational
24	0	3	0	#_4 H&L_survey  
24	0	3	0	#_5 Triennial   
24	0	3	0	#_6 WCGBTS      
 0	0	0	0	#_7 SMURF       
#
#_age_selex_patterns
#_Pattern	Discard	Male	Special
10	0	0	0	#_1 Commercial  
10	0	0	0	#_2 At-Sea-Hake 
10	0	0	0	#_3 Recreational
10	0	0	0	#_4 H&L_survey  
10	0	0	0	#_5 Triennial   
10	0	0	0	#_6 WCGBTS      
10	0	0	0	#_7 SMURF       
#
#_SizeSelex
#_LO	HI	INIT	PRIOR	PR_SD	PR_type	PHASE	env-var	use_dev	dev_mnyr	dev_mxyr	dev_PH	Block	Blk_Fxn  #  parm_name
  20	55	48.6485	0	99	0	  1	0	0	0	0	0	0	0	#_SizeSel_P_1_Commercial(1)        
 -20	70	     70	0	99	0	 -4	0	0	0	0	0	0	0	#_SizeSel_P_2_Commercial(1)        
  -5	20	4.27222	0	99	0	  3	0	0	0	0	0	0	0	#_SizeSel_P_3_Commercial(1)        
  -5	70	     70	0	99	0	 -4	0	0	0	0	0	0	0	#_SizeSel_P_4_Commercial(1)        
-999	25	   -999	0	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_5_Commercial(1)        
-999	25	   -999	0	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_6_Commercial(1)        
 -10	10	      0	0	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_PMalOff_1_Commercial(1)  
 -10	10	      0	0	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_PMalOff_2_Commercial(1)  
 -10	10	      0	0	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_PMalOff_3_Commercial(1)  
 -10	10	      0	0	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_PMalOff_4_Commercial(1)  
   0	 2	      1	0	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_PMalOff_5_Commercial(1)  
  20	55	     55	0	99	0	-99	0	0	0	0	0	2	2	#_SizeSel_P_1_At-Sea-Hake(2)       
 -20	70	     70	0	99	0	 -4	0	0	0	0	0	0	0	#_SizeSel_P_2_At-Sea-Hake(2)       
  -5	20	 4.2846	0	99	0	  3	0	0	0	0	0	2	2	#_SizeSel_P_3_At-Sea-Hake(2)       
  -5	70	     70	0	99	0	 -4	0	0	0	0	0	0	0	#_SizeSel_P_4_At-Sea-Hake(2)       
-999	25	   -999	0	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_5_At-Sea-Hake(2)       
-999	25	   -999	0	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_6_At-Sea-Hake(2)       
 -10	10	      0	0	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_PMalOff_1_At-Sea-Hake(2) 
 -10	10	      0	0	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_PMalOff_2_At-Sea-Hake(2) 
 -10	10	      0	0	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_PMalOff_3_At-Sea-Hake(2) 
 -10	10	      0	0	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_PMalOff_4_At-Sea-Hake(2) 
   0	 2	      1	0	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_PMalOff_5_At-Sea-Hake(2) 
  20	55	 30.811	0	99	0	  6	0	0	0	0	0	1	2	#_SizeSel_P_1_Recreational(3)      
 -20	70	    -20	0	99	0	 -4	0	0	0	0	0	0	0	#_SizeSel_P_2_Recreational(3)      
  -5	20	  3.173	0	99	0	  6	0	0	0	0	0	0	0	#_SizeSel_P_3_Recreational(3)      
  -5	20	      7	0	99	0	  4	0	0	0	0	0	1	2	#_SizeSel_P_4_Recreational(3)      
-999	25	   -999	0	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_5_Recreational(3)      
-999	25	   -999	0	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_6_Recreational(3)      
 -10	10	      0	0	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_PMalOff_1_Recreational(3)
 -10	10	      0	0	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_PMalOff_2_Recreational(3)
 -10	10	      0	0	99	0	  6	0	0	0	0	0	0	0	#_SizeSel_PMalOff_3_Recreational(3)
 -10	10	      0	0	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_PMalOff_4_Recreational(3)
   0	 2	      1	0	99	0	  6	0	0	0	0	0	0	0	#_SizeSel_PMalOff_5_Recreational(3)
  20	55	 30.811	0	99	0	  6	0	0	0	0	0	0	0	#_SizeSel_P_1_H&L_survey(4)        
 -20	70	    -20	0	99	0	 -4	0	0	0	0	0	0	0	#_SizeSel_P_2_H&L_survey(4)        
  -5	20	  3.173	0	99	0	  6	0	0	0	0	0	0	0	#_SizeSel_P_3_H&L_survey(4)        
  -5	20	      7	0	99	0	  4	0	0	0	0	0	0	0	#_SizeSel_P_4_H&L_survey(4)        
-999	25	   -999	0	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_5_H&L_survey(4)        
-999	25	   -999	0	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_6_H&L_survey(4)        
 -10	10	      0	0	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_PMalOff_1_H&L_survey(4)  
 -10	10	      0	0	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_PMalOff_2_H&L_survey(4)  
 -10	10	      0	0	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_PMalOff_3_H&L_survey(4)  
 -10	10	      0	0	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_PMalOff_4_H&L_survey(4)  
   0	 2	      1	0	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_PMalOff_5_H&L_survey(4)  
  20	55	     55	0	99	0	 -1	0	0	0	0	0	0	0	#_SizeSel_P_1_Triennial(5)         
 -20	70	     70	0	99	0	 -4	0	0	0	0	0	0	0	#_SizeSel_P_2_Triennial(5)         
  -5	20	5.11635	0	99	0	  3	0	0	0	0	0	0	0	#_SizeSel_P_3_Triennial(5)         
  -5	70	     70	0	99	0	 -4	0	0	0	0	0	0	0	#_SizeSel_P_4_Triennial(5)         
-999	25	   -999	0	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_5_Triennial(5)         
-999	25	   -999	0	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_6_Triennial(5)         
 -10	10	      0	0	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_PMalOff_1_Triennial(5)   
 -10	10	      0	0	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_PMalOff_2_Triennial(5)   
 -10	10	      0	0	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_PMalOff_3_Triennial(5)   
 -10	10	      0	0	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_PMalOff_4_Triennial(5)   
   0	 2	      1	0	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_PMalOff_5_Triennial(5)   
  20	55	49.7058	0	99	0	  1	0	0	0	0	0	0	0	#_SizeSel_P_1_WCGBTS(6)            
 -20	70	     70	0	99	0	 -4	0	0	0	0	0	0	0	#_SizeSel_P_2_WCGBTS(6)            
  -5	20	4.53247	0	99	0	  3	0	0	0	0	0	0	0	#_SizeSel_P_3_WCGBTS(6)            
  -5	70	     70	0	99	0	 -4	0	0	0	0	0	0	0	#_SizeSel_P_4_WCGBTS(6)            
-999	25	   -999	0	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_5_WCGBTS(6)            
-999	25	   -999	0	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_6_WCGBTS(6)            
 -10	10	      0	0	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_PMalOff_1_WCGBTS(6)      
 -10	10	      0	0	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_PMalOff_2_WCGBTS(6)      
 -10	10	      0	0	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_PMalOff_3_WCGBTS(6)      
 -10	10	      0	0	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_PMalOff_4_WCGBTS(6)      
   0	 2	      1	0	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_PMalOff_5_WCGBTS(6)      
#_AgeSelex
#_No age_selex_parm
# timevary selex parameters 
#_LO	HI	INIT	PRIOR	PR_SD	PR_type	PHASE
20	55	48.6485	0	99	0	6	#_SizeSel_P_1_At-Sea-Hake(2)_BLK2repl_2015 
-5	20	  4.248	0	99	0	6	#_SizeSel_P_3_At-Sea-Hake(2)_BLK2repl_2015 
20	55	  31.22	0	99	0	6	#_SizeSel_P_1_Recreational(3)_BLK1repl_2004
20	55	  31.22	0	99	0	6	#_SizeSel_P_1_Recreational(3)_BLK1repl_2017
-5	20	  4.248	0	99	0	6	#_SizeSel_P_4_Recreational(3)_BLK1repl_2004
-5	20	  4.248	0	99	0	6	#_SizeSel_P_4_Recreational(3)_BLK1repl_2017
# info on dev vectors created for selex parms are reported with other devs after tag parameter section
#
0 #  use 2D_AR1 selectivity(0/1):  experimental feature
#_no 2D_AR1 selex offset used
# Tag loss and Tag reporting parameters go next
0 # TG_custom:  0=no read; 1=read if tags exist
#_Cond -6 6 1 1 2 0.01 -4 0 0 0 0 0 0 0  #_placeholder if no parameters
#
# Input variance adjustments factors: 
#_factor	fleet	value
    4	1	0.056408	#_Variance_adjustment_list1 
    4	2	0.166351	#_Variance_adjustment_list2 
    4	3	0.020013	#_Variance_adjustment_list3 
    4	4	0.051835	#_Variance_adjustment_list4 
    4	5	0.075715	#_Variance_adjustment_list5 
    4	6	0.095639	#_Variance_adjustment_list6 
    5	1	0.238724	#_Variance_adjustment_list7 
    5	4	0.021984	#_Variance_adjustment_list8 
    5	5	  0.1366	#_Variance_adjustment_list9 
    5	6	0.140055	#_Variance_adjustment_list10
    5	3	0.018235	#_Variance_adjustment_list11
    5	2	0.129856	#_Variance_adjustment_list12
-9999	0	       0	#_terminator                
#
5 #_maxlambdaphase
1 #_sd_offset; must be 1 if any growthCV, sigmaR, or survey extraSD is an estimated parameter
# read 1 changes to default Lambdas (default value is 1.0)
#_like_comp	fleet	phase	value	sizefreq_method
   17	1	5	0	0	#_F-ballpark_Commercial_Phz5
-9999	0	0	0	0	#_terminator                
#
0 # 0/1 read specs for more stddev reporting
#
999
