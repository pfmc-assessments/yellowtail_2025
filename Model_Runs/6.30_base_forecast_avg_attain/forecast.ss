#C file created using an r4ss function
#C file write time: 2025-05-22  16:36:30
#
1 #_benchmarks
2 #_MSY
0.5 #_SPRtarget
0.4 #_Btarget
#_Bmark_years: beg_bio, end_bio, beg_selex, end_selex, beg_relF, end_relF,  beg_recr_dist, end_recr_dist, beg_SRparm, end_SRparm (enter actual year, or values of 0 or -integer to be rel. endyr)
0 0 0 0 0 0 0 0 0 0
2 #_Bmark_relF_Basis
1 #_Forecast
12 #_Nforecastyrs
1 #_F_scalar
#_Fcast_years:  beg_selex, end_selex, beg_relF, end_relF, beg_recruits, end_recruits (enter actual year, or values of 0 or -integer to be rel. endyr)
0 0 0 0 0 0
0 #_Fcast_selex
1 #_ControlRuleMethod
0.4 #_BforconstantF
0.1 #_BfornoF
-1 #_Flimitfraction
 #_year fraction
   2025    1.000
   2026    1.000
   2027    0.935
   2028    0.930
   2029    0.926
   2030    0.922
   2031    0.917
   2032    0.913
   2033    0.909
   2034    0.904
   2035    0.900
   2036    0.896
-9999 0
3 #_N_forecast_loops
3 #_First_forecast_loop_with_stochastic_recruitment
0 #_fcast_rec_option
1 #_fcast_rec_val
0 #_Fcast_loop_control_5
2027 #_FirstYear_for_caps_and_allocations
0 #_stddev_of_log_catch_ratio
0 #_Do_West_Coast_gfish_rebuilder_output
0 #_Ydecl
0 #_Yinit
1 #_fleet_relative_F
# Note that fleet allocation is used directly as average F if Do_Forecast=4 
2 #_basis_for_fcast_catch_tuning
# enter list of fleet number and max for fleets with max annual catch; terminate with fleet=-9999
-9999 -1
# enter list of area ID and max annual catch; terminate with area=-9999
-9999 -1
# enter list of fleet number and allocation group assignment, if any; terminate with fleet=-9999
-9999 -1
2 #_InputBasis
 #_year seas fleet catch_or_F                comment
   2025    1     1  3497.0000  #sum_for_2025: 4060.1
   2025    1     2   360.0000                       
   2025    1     3   203.1000                       
   2026    1     1  3503.0000  #sum_for_2026: 4066.1
   2026    1     2   360.0000                       
   2026    1     3   203.1000                       
   2027    1     1  2461.7835 #sum_for_2027: 4722.88
   2027    1     2    13.3760                       
   2027    1     3   122.4245                       
   2028    1     1  2361.6780 #sum_for_2028: 4540.29
   2028    1     2    12.6775                       
   2028    1     3   122.8040                       
   2029    1     1  2308.5040 #sum_for_2029: 4445.23
   2029    1     2    12.2045                       
   2029    1     3   124.1680                       
   2030    1     1  2294.6715 #sum_for_2030: 4420.53
   2030    1     2    11.9680                       
   2030    1     3   124.6520                       
   2031    1     1  2303.2130 #sum_for_2031: 4435.12
   2031    1     2    11.9130                       
   2031    1     3   124.1900                       
   2032    1     1  2321.1650 #sum_for_2032: 4466.55
   2032    1     2    11.9955                       
   2032    1     3   123.4420                       
   2033    1     1  2332.3190 #sum_for_2033: 4485.13
   2033    1     2    12.0945                       
   2033    1     3   122.4080                       
   2034    1     1  2328.7605 #sum_for_2034: 4476.24
   2034    1     2    12.1385                       
   2034    1     3   121.0330                       
   2035    1     1  2316.8365 #sum_for_2035: 4452.09
   2035    1     2    12.1275                       
   2035    1     3   119.6855                       
   2036    1     1  2297.3940 #sum_for_2036: 4414.12
   2036    1     2    12.0560                       
   2036    1     3   118.3160                       
-9999 0 0 0
#
999 # verify end of input 
