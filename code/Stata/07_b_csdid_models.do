*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*** MA: The health-wealth nexus over the life cycle
*** Au: Marcelo Rainho Avila (4679876)
*** Dt: 07.02.2024
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# options
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

cap log close _all 
estim drop _all
graph drop _all
csdid2 , clear

* global options




global plotopt1     plottype(connected)  ciplottype(rcap) perturb(-.2 .2) ///
                    lag_opt1(color(stc1) msym(O) lp(solid))     lag_ci_opt1(color(stc1%66)) ///
                    lag_opt2(color(stc2) msym(T) lp(dash))      lag_ci_opt2(color(stc2%66)) ///
                    lag_opt3(color(stc5) msym(D) lp(shortdash)) lag_ci_opt3(color(stc5%66)) ///
                    legend_opt(region(lstyle(none))) noautolegend together

global gropt_sizes  scale(1.8) xsize(11) ysize(7) xlab(-\`=tleadmax'(2)\`=tlagsmax', nogrid)
global gropt_canva  xline(-2, lc(gs8) lp(dash) lw(.2)) yline(0, lw(.2) lc(gs8)) graphregion(color(white)) bgcolor(white) ylabel(, angle(horizontal)) 
global gropt_title  xtitle("Years since the event") ytitle("ATT") // subtitle("\`: variable label \`wvar''") 
global gropt_legen  legend(order(1 "Physical Health (oblique)" 3 "Mental Health (oblique)")   cols(1) pos(\`legpos') ring(0) region(fcolor(gs16%80)) )
global gropt_stubs  stub_lag(tp# tp#) stub_lead(tm# tm#)


global csdid2opts   method(drimp) long2 

global csdidcovars  age_sp? i.bula i.legal_handicapped_bin i.marital_status i.sex educ_years

global olscovars    age_sp? i.bula i.legal_handicapped_bin i.marital_status educ_years 

global pbleib       0

global exportgraph  1 

global rerun        0

set graph off

*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

use $inter/07_did_gentreattime.dta, clear
desc, short
sort pid syear
xtset pid syear, delta(2)

/* keep smaller dta in memory for faster loops */
keep pid syear sex timeto* treat* ?w* age* bula legal* marital_status ?cs* _to_keep_* _timeto* /* tm* tp* */ n N educ_years ///
    educ_highschool exp?? empl_status tatzeit labor_earns empl_status sats_health sats_life  ///
    sats_pinc sats_work per_risk freq_* pbleib hd_*_ever east 


/* rename necessary because varname used in model name and that cannot be too long */
rename hd_sleep_ever            sleep_ev
rename hd_diabetes_ever         diabetes_ev
rename hd_asthma_ever           asthma_ev
rename hd_cardio_ever           cardio_ev
rename hd_cancer_ever           cancer_ev
rename hd_stroke_ever           stroke_ev
rename hd_migraine_ever         migraine_ev
rename hd_blood_pres_ever       blood_ev
rename hd_depression_ever       depres_ev
rename hd_dementia_ever         dement_ev
rename hd_joint_ever            joint_ev
rename hd_back_pain_ever        backpain_ev
rename hd_other_ever            other_ev
rename hd_no_illness_ever       no_illns_ev
lab var pcs_def "Physical Health (sf12)"
lab var mcs_def "Mental Health (sf12)"

cap recode educ_highschool (1/2 = 1 "No higher educ") (3=2 "Higher educ"), gen(educ_g1)
recode sex (0=2 "Female") (1=1 "Male"), gen(sex2)

* age group c(17, 35, 45, 55, 68, 110) (close to quantiles)
cap drop age_g22
recode age   (18/49 = 1 "18-49")   (50/999 = 2 ">=50"), gen(age_g22)
fre age_g22
tabstat age, by(age_g22) stat(mean min max n)

replace age_cuts_10= 20 if age_cuts_10 == 10
cap drop nw_pile_age
gquantiles nw_pile_age = nw, xtile nquantiles(100) by(age_cuts_10)
recode nw_pile_age (1/50 = 1 "below median") (51/100 = 2 "above median"), gen(nw_age_gr2)
cap drop gw_pile_age
gquantiles gw_pile_age = gw, xtile nquantiles(100) by(age_cuts_10)
recode gw_pile_age (1/50 = 1 "below median") (51/100 = 2 "above median"), gen(gw_age_gr2)

cap drop age_g3 
recode age (18/39 = 1 "18-39") (40/55 = 2 "40-55") (56/75 = 3 "56-75"), gen(age_g3)


save $inter/07_did_gentreattime_small.dta, replace


*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# CSDID 1
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

if 1 {
    cap log close _all
    log using $log/tmp/07_a_csdid_models_csdid1.log, text replace 

    foreach hnum of numlist 1/2 {
        cd $inter/estim
        local cstype : word `hnum' of  /*1*/main  /*2*/def  /*3*/sep  /*4*/rmean
        foreach wnum of numlist 1/4 {
            /* make sure in estim folder to save rif file */
            assert "`=usubinstr("`c(pwd)'", "/home/`c(username)'", "~", 1)'" == "$inter/estim"
            local wvar : word `wnum' of gw_nlog  nw_nlog  gw  nw
            di as res 120*"~" " " "var: `wvar'| cs type: `cstype'"
            foreach hvar of varlist ?cs_`cstype' {
                if mi("`=nobs_`hvar''") { /* only compute if scalars not defined already */
                    csdid `wvar' $csdidcovars if _to_keep_`hvar', ivar(pid) time(syear) gvar(treat_time_`hvar') /// 
                    method(drimp) long2 saverif(rif_`hvar'_`wvar') replace
                    gen _smp_`wvar'_`hvar' = e(sample)
                    estat simple, estore(satt_`hvar')
                    scalar nobs_`wvar'_`hvar' = `e(N)'
                    estat event, estore(evatt_`hvar')
                    eststo m1_`hvar'_`wvar': mergemodels satt_`hvar' evatt_`hvar'
                    estadd local Obs `=nobs_`wvar'_`hvar'' : m1_`hvar'_`wvar'
                    di "=nobs_`wvar'_`hvar': `=nobs_`wvar'_`hvar''"
                    sca li nobs_`wvar'_`hvar'
                }
           }
        }
        cd $temp
    }

    capture confirm var _smp_*
    if _rc == 0 {
        preserve 
            keep pid syear _smp_*
            save $inter/07_csdid_1_nobs.dta, replace
            if 0 {

                /* extract nobs (if already defined and export to 07_csdid_1_nobs dataset ) */
                preserve
                use $inter/07_csdid_1_nobs.dta
                count if _smp_gw_nlog_pcs_main==1
                scalar nobs_gw_nlog_pcs_main = r(N)
                scalar nobs_mcs_main = r(N) 

                foreach hv in pcs_main mcs_main pcs_def mcs_def {
                    foreach wv in gw_nlog nw_nlog gw nw {
                        distinct pid if _smp_`wv'_`hv'==1
                        scalar nobs_`wv'_`hv' = r(N)
                        scalar nobs_`hv' = r(N) 
                        scalar pids_`hv' = r(ndistinct)
                        di "nobs_`wv'_`hv' (nobs_`hv'): `r(N)'"
                    }
                }
                restore

            }
        restore     
    }

    local modelnames  ///
            m1_pcs_main_gw       m1_mcs_main_gw       m1_pcs_main_nw       m1_mcs_main_nw ///
            m1_pcs_main_gw_nlog  m1_mcs_main_gw_nlog  m1_pcs_main_nw_nlog  m1_mcs_main_nw_nlog

    cap estim dir `modelnames'
    if _rc==0 { /* if models present  */

        esttab  `modelnames' ///
                using `c(tmpdir)'/tex.tex, label replace cells(b(star fmt(3)) se(par fmt(2))) ///
                stats(Obs) scalars("Obs") type
    }
    else {
        di "Models not in memory, to rerun, drop scalars nobs_* so that models run again."
    }

    if 0 sca drop nobs_pcs_main nobs_mcs_main nobs_pcs_def nobs_mcs_def

    log close  
    cp $log/tmp/07_a_csdid_models_csdid1.log $log/, replace

}


*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# comparison mcs pcs (C&S only)
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

if 1 {

    cap log close _all
    log using $log/tmp/07_b_csdid_models_mcspcscsonly_`=condstrov'_ct`=crit'.log, text replace

    foreach hnum of numlist 1 2 {
        local cstype : word `hnum' of  /*1*/main  /*2*/def   /*3*/sep  /*4*/rmean
            foreach wnum of numlist 1/4 {
            local wvar : word `wnum' of gw_nlog  nw_nlog  gw  nw
            if regexm("`wvar'","log") { /* check if log or lev */
                local islog 1 
                local ylab      ylab(-.4(.1).33, /* gstyle(major) */ /* nogrid */)
            }
            else {
                local ylab      ylab(-30(10)20, /* gstyle(major) */ /* nogrid */)
            }
            di as res 120*"~" " " "var: `wvar' | cs type: `cstype'"
            local eventplots ""
            local lev = 1
            local leg = ""
            foreach hvar of varlist ?cs_`cstype' {
                local eqname4plot event_`hvar'_`wvar'/* _ny */
                cap estimates dir `eqname4plot'
                if _rc!=0 | $rerun  { /* if estimates already there, do run model again */
                    csdid2 , clear
                    qui csdid2 `wvar' $csdidcovars  if _to_keep_`hvar', ivar(pid) time(syear) gvar(treat_time_`hvar') $csdid2opts
                    di as res 50*"~" " " "var: `wvar' | cs type: `cstype'"
                    qui estat group, estore(group_`hvar'_`wvar')
                    qui estat calendar, estore(cal_`hvar'_`wvar')
                    if 1 { /*  for table */
                        estat pretrend
                        scalar pre_df    = r(df)   
                        scalar pre_pchi2 = r(pchi2)
                        scalar pre_chi2  = r(chi2) 
                        estat simple, estore(satt2_`hvar'_`wvar') 
                        estat event, estore(`eqname4plot') wboot rseed(42) 
                        
                        eststo m2_`hvar'_`wvar': mergemodels satt2_`hvar'_`wvar' `eqname4plot'
                        if mi("`=nobs_`hvar''") error 1
                        estadd scalar Obs  `=nobs_`hvar''  : m2_`hvar'_`wvar'
                        estadd scalar Pids `=pids_`hvar''  : m2_`hvar'_`wvar'
                        di 1
                        * pretrend test
                        estadd scalar pre_chi2   `=pre_chi2'  : m2_`hvar'_`wvar'
                        estadd scalar pre_df     `=pre_df'    : m2_`hvar'_`wvar'
                        estadd scalar pre_pchi2  `=pre_pchi2' : m2_`hvar'_`wvar'
                    }
                }
                local eventplots `eventplots' `eqname4plot'
                local lab : variable label `hvar'
                local levx2 = (`lev'*2)-1
                local leg `leg' `levx2' "`lab'"
                local lev = `lev'+1
            }
            if 1 { /* Do plots! */
                di "eventplots: `eventplots'"
                event_plot `eventplots', $gropt_stubs $plotopt1  ///
                graph_opt( ///
                    $gropt_title /// xtitle("Years since the event")  ytitle("ATT") subtitle("`: variable label `wvar''") ///
                    legend(order(`leg') cols(1) pos(8) ring(0) region(fcolor(gs16%80))) ///
                    $gropt_sizes /// scale(1.2) xsize(10) ysize(12) ///
                    name(`wvar'_comp_`cstype'_`=crit'_`=condstrov', replace) ///
                    xlab(-`=tleadmax'(2)`=tlagsmax', nogrid) `ylab' ///
                    $gropt_canva ///
                ) 
                if $exportgraph graph export $figures/csdid2/b_mcspcs/f_`wnum'`hnum'_`wvar'_`=condstrov'_ct`=crit'.pdf, replace
            }
        }
    }
    **# main
    *** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    * graph combine gw_nlog_comp_main nw_nlog_comp_main, name(gc_log_main, replace) scale(1.2) xsize(12) ysize(6) 
    * if $exportgraph graph export $figures/csdid2/b_mcspcs/fcomb_`=condstrov'_ct`=crit'_log.pdf, replace
    * graph combine gw_comp_main      nw_comp_main,      name(gc_lev_main, replace) scale(1.2) xsize(12) ysize(6) 
    * if $exportgraph graph export $figures/csdid2/b_mcspcs/fcomb_`=condstrov'_ct`=crit'_lev.pdf, replace

    **# def 
    *** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    cap graph combine gw_nlog_comp_def nw_nlog_comp_def, ycom name(gc_log_def, replace)
    cap graph combine gw_comp_def nw_comp_def, ycom name(gc_lev_def, replace)

    if 0 {
        graph close _all 
        graph dis gc_log_main
        graph dis gc_lev_main
        graph dis gc_log_def
        graph dis gc_lev_def
    }


    **# export table
    *** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    if 1 { /* export table main */

        esttab  m2_pcs_main_gw_nlog m2_pcs_main_nw_nlog m2_pcs_main_gw m2_pcs_main_nw ///
                m2_mcs_main_gw_nlog m2_mcs_main_nw_nlog m2_mcs_main_gw m2_mcs_main_nw ///
                using "$tables/tbl_full_main.tex",  /// 
                label replace cells(b(star fmt(2)) se(par fmt(2))) ///
                stats( ///
                    Obs Pids pre_chi2 pre_df   pre_pchi2, layout("{@}" "{@}"  `""{@ (@)}""' "{@}") fmt(%9.0gc %9.0gc 1 0 3) ///
                    labels("N" "Unique N" "Pretrend \$\chi^2\$ (df)" "Pretrend p-value") ///
                    )  nomtitles nonumbers depvars  /// 
                 nolines  prefoot(\midrule)  booktabs ///
                mlabels(,none) collabels(,none) type prehead("") postfoot("\bottomrule") /// 
                transform(100*(exp(@)-1) 100*exp(@) , pattern(1 1 0 0 1 1 0 0 ))
                /* since we are dealing with log-lin, transform for easier interpretation */

        export_tex_body_only $tables/tbl_full_main.tex $tables/tbl_full_main_bd_`=condstrov'_ct`=crit'.tex
        if c(os) == "Unix" { /* replaces varnames with nicer looking (e.g.: tm10 -> \theta(-10)) */
            !sed -E -i s/tm\([0-9]\{0,9\}\)/\$\\\\hat\{\\\\theta\}_\{es\}\(-\\1\)\$/g $tables/tbl_full_main_bd_`=condstrov'_ct`=crit'.tex
            !sed -E -i s/tp\([0-9]\{0,9\}\)/\$\\\\hat\{\\\\theta\}_\{es\}\(\\1\)\$/g $tables/tbl_full_main_bd_`=condstrov'_ct`=crit'.tex
            !sed -E -i s/\\\\_avg/" "average/g $tables/tbl_full_main_bd_`=condstrov'_ct`=crit'.tex    
        }
        cp $tables/tbl_full_main_bd_`=condstrov'_ct`=crit'.tex $incl_thesis/tbls/, replace
        cat $tables/tbl_full_main_bd_`=condstrov'_ct`=crit'.tex
    }

    if 1 { /* export table def */

        esttab  m2_pcs_def_gw_nlog m2_pcs_def_nw_nlog m2_pcs_def_gw m2_pcs_def_nw ///
                m2_mcs_def_gw_nlog m2_mcs_def_nw_nlog m2_mcs_def_gw m2_mcs_def_nw ///
                using "$tables/tbl_full_def.tex",  /// 
                label replace cells(b(star fmt(2)) se(par fmt(2))) ///
                stats( ///
                    Obs Pids pre_chi2 pre_df   pre_pchi2, layout("{@}" "{@}"  `""{@ (@)}""' "{@}") fmt(%9.0gc %9.0gc 1 0 3) ///
                    labels("N" "Unique N" "Pretrend \$\chi^2\$ (df)" "Pretrend p-value") ///
                    )  nomtitles nonumbers depvars  /// 
                 nolines  prefoot(\midrule)  booktabs ///
                mlabels(,none) collabels(,none) type prehead("") postfoot("\bottomrule") /// 
                transform(100*(exp(@)-1) 100*exp(@) , pattern(1 1 0 0 1 1 0 0 ))
                /* since we are dealing with log-lin, transform for easier interpretation */

        export_tex_body_only $tables/tbl_full_def.tex $tables/tbl_full_def_bd_`=condstrov'_ct`=crit'.tex
        if c(os) == "Unix" { /* replaces varnames with nicer looking (e.g.: tm10 -> \theta(-10)) */
            !sed -E -i s/tm\([0-9]\{0,9\}\)/\$\\\\hat\{\\\\theta\}_\{es\}\(-\\1\)\$/g $tables/tbl_full_def_bd_`=condstrov'_ct`=crit'.tex
            !sed -E -i s/tp\([0-9]\{0,9\}\)/\$\\\\hat\{\\\\theta\}_\{es\}\(\\1\)\$/g $tables/tbl_full_def_bd_`=condstrov'_ct`=crit'.tex
            !sed -E -i s/\\\\_avg/" "average/g $tables/tbl_full_def_bd_`=condstrov'_ct`=crit'.tex
        }
        cp $tables/tbl_full_def_bd_`=condstrov'_ct`=crit'.tex $incl_thesis/tbls/, replace
        cat $tables/tbl_full_def_bd_`=condstrov'_ct`=crit'.tex
    }

    log close  
    cp $log/tmp/07_b_csdid_models_mcspcscsonly_`=condstrov'_ct`=crit'.log $log/, replace

}

*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# OTHER VARIABLES
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

if 1 {
    cap log close _all
    log using $log/tmp/07_c_csdid_models_othervars.log, text replace

    * set graph off

    foreach hnum of numlist 1 2 {
        local cstype : word `hnum' of  /*1*/main  /*2*/def  /*3*/sep  /*4*/rmean
        local vargp_1    expft expue empl_status tatzeit labor_earns sats_health  sats_life
        local vargp_2     sats_pinc sats_work freq_angry freq_worried freq_happy freq_sad
        local vargp_3    ?cs_main ?cs_def 
        local vargp_4    sleep_ev cardio_ev migraine_ev backpain_ev depres_ev
        foreach wvar of varlist /* `vargp_1' /* `vargp_2' `vargp_3'  */`vargp_4' */ sats_work sats_pinc {
            di as res 120*"~" " " "var: `wvar'| cs type: `cstype'"
            local eventplots ""
            local lev = 1
            local leg = ""
            * for legpos
            local regex `"expue|_ev|freq_angry|freq_worried|freq_sad"'
            if ustrregexm("`wvar'", "`regex'")          local legpos 4
            else if ustrregexm("`wvar'", "sats_")       local legpos 2
            else                                        local legpos 8
            * for ylab
            if ustrregexm("`wvar'", "labor_earns")                   local ylab -5000(2500)5000
            else if ustrregexm("`wvar'", "s_health|s_life")    local ylab -1.5(.5).5
            else if ustrregexm("`wvar'", "s_work|s_pinc")    local ylab -.8(.4).8
            else                                                     local ylab 
            
            * xxx
            if regexm("`wvar'", "freq_")    local shift "-2"
            else                            local shift ""
            foreach hvar of varlist ?cs_`cstype' {
                * egen _todrop = max(treat_time_`hvar'  == 2002 ), by(pid)
                * drop if _todrop==1
                local eqname event_`hvar'_`wvar'/* _ny */
                cap estimates dir `eqname'
                if _rc!=0 | $rerun { /* if estimates already there, do run model again */
                    csdid2 , clear
                    csdid2 `wvar'  $csdidcovars if _to_keep_`hvar', ivar(pid) time(syear) gvar(treat_time_`hvar') ///
                        method(drimp) long2 agg(simple) 
                    estat event, revent(-`=tleadmax`shift''/`=tlagsmax`shift'') estore(`eqname')
                }
                else estim replay `eqname'
                local eventplots `eventplots' `eqname'
                local lab : variable label `hvar'
                local levx2 = (`lev' * 2)-1
                local leg `leg' `levx2' "`lab'"
                local lev = `lev'+1
            }
            di "eventplots: `eventplots'"
            event_plot `eventplots', $gropt_stubs  $plotopt1 ///
            graph_opt( ///
                $gropt_title $gropt_sizes $gropt_canva ///
                legend(order(`leg') cols(1) pos(`legpos') ring(0) region(fcolor(gs16%80))) ///
                xlab(-`=tleadmax`shift''(2)`=tlagsmax`shift'', nogrid) ylab(`ylab') ///
                name(`wvar'_compare_hs_`cstype', replace) ///
            ) 
            if $exportgraph graph export $figures/csdid2/c_othervars/f_`hnum'_`wvar'_`=condstrov'_`cstype'.pdf, replace
        }
    }

    if 0 {
        graph combine sats_life_compare_hs_main sats_health_compare_hs_main, ycommon xsize(10) ysize(5)

        graph combine freq_worried_compare_hs_main freq_worried_compare_hs_def, name(freq_worried) ycommon
        graph combine expft_compare_hs_main expft_compare_hs_def, name(expft_compare) ycommon
        graph combine expue_compare_hs_main expue_compare_hs_def, name(expue_compare) ycommon
        graph combine sats_health_compare_hs_main sats_health_compare_hs_def, name(sats_health) ycommon
        graph combine sats_life_compare_hs_main sats_life_compare_hs_def, name(sats_life) ycommon    
    }


    log close  
    cp $log/tmp/07_c_csdid_models_othervars.log $log/, replace
}

*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# Heterogeneity checks (by groups)
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


if 1 {
    cap estim drop ev_*
    use $inter/07_did_gentreattime_small.dta, clear

    global plotopt_all_het  plottype(connected)  ciplottype(rcap) perturb(-.2 .2) ///
                            legend_opt(region(lstyle(none))) noautolegend together
                            
    global plotopt_pcs  lag_opt1(color(stc1)    msym(O) lp(solid))     lag_ci_opt1(color(stc1%66)) ///
                            lag_opt2(color(navy8)  msym(T) lp(dash))      lag_ci_opt2(color(navy8%66)) ///
                            lag_opt3(color(ltblue)    msym(D) lp(shortdash)) lag_ci_opt3(color(ltblue%66)) ///
                            
    global plotopt_mcs  lag_opt1(color(stc2) msym(O) lp(solid))     lag_ci_opt1(color(stc2%66)) ///
                            lag_opt2(color(purple) msym(T) lp(dash))      lag_ci_opt2(color(purple %66)) ///
                            lag_opt3(color( reddish ) msym(D) lp(shortdash)) lag_ci_opt3(color( reddish %66)) ///

    scalar tleadmaxby = 10 /* + 4 */
    scalar tlagsmaxby = 12 /* + 4 */
    scalar trim       =  4 /* + 4 */
    numlabel sex_EN sex d11108 d11104, remove mask("[#] ")

    graph set window fontface "Liberation Serif" // "Times New Roman" /* narrower to keep labels "thinner" */
    cap log close _all 
    if $exportgraph log using $log/tmp/07_d_csdid_models_hetoreg.log, text replace
    numlabel sex_EN age_g22 educ_g1, remove mask("[#] ")
    foreach byvar of varlist   age_g3 /* gw_age_gr2 */ educ_g1 /* sex */ /* age_g22 */  {
        local vargp_1    expue // expft empl_status tatzeit labor_earns
        local vargp_2    sats_health  sats_life sats_pinc sats_work freq_angry freq_worried freq_happy freq_sad
        local vargp_3    ?cs_main ?cs_def 
        local vargp_4    sleep_ev cardio_ev migraine_ev backpain_ev
        local byvar_i = 1
        foreach wvar of varlist gw_nlog /* nw_nlog gw nw */ `vargp_1' /* `vargp_2' `vargp_3' `vargp_4' */ {
            local regex `"expue|_ev|freq_angry|freq_worried|freq_sad"'
            if ustrregexm("`wvar'", "`regex'")          local legpos 4
            else if ustrregexm("`wvar'", "sats_")       local legpos 2
            else                                        local legpos 8
            /* local regex `"expue"'
            if ustrregexm("`wvar'", "`regex'")          local ylab -4(2)10
            else                                        local ylab -.4(.2).4 */

            foreach hvar of varlist pcs_main mcs_main {
                local regex `"pcs"'
                if ustrregexm("`hvar'", "`regex'") {
                    local title         "{bf:(i)} Physical Health" 
                    local hdomain       pcs
                }
                else {
                    local title "{bf:(ii)} Mental Health"
                    local hdomain       mcs
                }
                di "hdomain: `hdomain'"
        
                local leg ""
                local evenplots ""
                levelsof `byvar', local(levels)
                foreach lev of local levels {
                    local levlab`lev' : label (`byvar') `lev'
                    di 70 * "~" " vars: wvar: `wvar'. hvar: `hvar'. lev: `lev'." 
                    di 70 * "~" " lev: `lev'. `levlab`lev''." 
                    local levx2 = (`lev' * 2)-1
                    local leg `leg' `levx2' "`levlab`lev''"
                    
                    local evenplots `evenplots' ev_`wvar'_`hvar'_`lev'
                    csdid2 , clear
                    csdid2 `wvar'  if `byvar'==`lev' & _to_keep_`hvar', ivar(pid) time(syear) gvar(treat_time_`hvar')   $csdid2opts
                    estat event, revent(-`=tleadmaxby'/`=tlagsmaxby') estore(ev_`wvar'_`hvar'_`lev')
                    
                }
                event_plot `evenplots', $gropt_stubs $plotopt_all_het  ${plotopt_`hdomain'} ///
                trimlead(`=tleadmaxby-trim') trimlag(`=tlagsmaxby-trim') ///
                    graph_opt( ///
                        $gropt_canva $gropt_title /// 
                        scale(1.8) xsize(9) ysize(7) xlab(-`=tleadmaxby-trim'(2)`=tlagsmaxby-trim', nogrid) ylab(`ylab') ///
                        legend(order(`leg') pos(`legpos') ring(0) region(fcolor(gs16%80)) size(*1) ) ///
                        name(`wvar'_`hvar'_`byvar', replace) subtitle("`title'", size(18pt)) ///
                    ) 
                * if $exportgraph graph export $figures/csdid2/d_heterog/by_`byvar'_`hvar'_`wvar'.pdf, replace         
            }
            graph combine `wvar'_pcs_main_`byvar' `wvar'_mcs_main_`byvar', name(`wvar'_`byvar', replace) ycommon ysize(7) xsize(16) /* ///
                pos(11) ring(0) legscale(*1.4) lxo(18) lyo(-8) graphon */
            if $exportgraph graph export $figures/csdid2/d_heterog/comb_by_`byvar'_`wvar'_main.pdf, replace         
        }
    }
    /* TODO: adapt plot (aesthetics) */
    log close  
    cp $log/tmp/07_d_csdid_models_hetoreg.log $log/, replace

}

if 0 {
    graph dis         gw_nlog_age_g3
    graph dis         gw_nlog_educ_g1
    graph dis         expue_age_g3
    graph dis         expue_educ_g1

}


*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# comparison TWFE C&S
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

if 1  {
    use $inter/07_did_gentreattime_small.dta, clear


    cap log close _all
    log using $log/tmp/07_e_csdid_models_twfecs.log, text replace


    global pbleib 0

    foreach hnum of numlist 1 {
        local cstype : word `hnum' of  /*1*/main  /*2*/def  /*3*/sep  /*4*/rmean
        foreach csphme in pcs mcs {
            di "csphme: `csphme'"
            local var `csphme'_`cstype'
            di "var: `var'"
            local listofgraphs  ""
            foreach wnum of numlist 1 2 3 4 {
                /*                       1        2        3   4                             */
                local w : word `wnum' of gw_nlog  nw_nlog  gw  nw
                di as res 120*"~" " " "var: `w' | cstype: `cstype' | var: `var'"
                if "$pbleib"=="1" {
                    local pbleib [aw=pbleib]
                }
                
                **# run regressions
                *** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                
                cap estimates dir ols_`w'_`=condstrov'_`var'${pbleib}
                if _rc!=0 | $rerun { /* if estimates already there, do run model again */
                    **# csdid  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                    csdid2 , clear
                    csdid2 `w' $csdidcovars  if _to_keep_`var' `pbleib', ivar(pid) time(syear) gvar(treat_time_`var') $csdid2opts
                    estat simple
                    scalar sc`hnum'`wnum'_satt_b          = string(r(table)["b","SimpleATT"], "%04.3f")
                    scalar sc`hnum'`wnum'_satt_se         = string(r(table)["se","SimpleATT"], "%04.3f")
                    scalar sc`hnum'`wnum'_satt_pvalue     = string(r(table)["pvalue","SimpleATT"], "%04.3f")
                    estat pretrend, window(-`=tleadmax'/`=tlagsmax')
                    scalar sc`hnum'`wnum'_df              = string(r(df), "%4.3g")
                    scalar sc`hnum'`wnum'_pchi2           = string(r(pchi2), "%04.3f")
                    scalar sc`hnum'`wnum'_chi2            = string(r(chi2), "%04.1f")
                    estat event, revent(-`=tleadmax'/`=tlagsmax') estore(cs_`w'_`=condstrov'_`var'${pbleib}) /* wboot rseed(42) */ /* no wboot, due to lack of pvalue */
                    scalar sc`hnum'`wnum'_pre_avg_b       = string(r(table)["b","Pre_avg"], "%04.3f")
                    scalar sc`hnum'`wnum'_pre_avg_se      = string(r(table)["se","Pre_avg"], "%04.3f")
                    scalar sc`hnum'`wnum'_pre_avg_pvalue  = string(r(table)["pvalue","Pre_avg"], "%04.3f")
                    scalar sc`hnum'`wnum'_post_avg_b      = string(r(table)["b","Post_avg"], "%04.3f")
                    scalar sc`hnum'`wnum'_post_avg_se     = string(r(table)["se","Post_avg"], "%04.3f")
                    scalar sc`hnum'`wnum'_post_avg_pvalue = string(r(table)["pvalue","Post_avg"], "%04.3f")
                    
                    **# ols ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                    qui genleadlags, timeto(timeto_`var') ttime(p) leads(`=tleadmax') lags(`=tlagsmax') delta(2) 
                    reghdfe `w' tm?? tm? tp? tp?? $csdidcovars if _to_keep_`var' `pbleib' , abs(pid syear) vce(cluster pid)
                    est store ols_`w'_`=condstrov'_`var'${pbleib}
                    * coefplot, keep(tm* tp*)  $coefplot_opts $cfpopt name(cfp_`=health_var'_`w', replace) 
                }

                **# save plot
                *** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                
                event_plot ols_`w'_`=condstrov'_`var'${pbleib}  cs_`w'_`=condstrov'_`var'${pbleib}, /// 
                    trimlead(`=tleadmax') trimlag(`=tlagsmax')  $gropt_stubs ///
                    $plotopt1 ///
                    graph_opt( ///
                        $gropt_title $gropt_sizes $gropt_canva /// xtitle("Years since the event")  ytitle("ATT (`: variable label `w'')")  ///
                        legend(order(1 "TWFE" /* 2 "95% CI" */ 3 "C&S " /* 4 "95% CI" */) cols(1) pos(8) ring(0) region(fcolor(gs16%70))) /// 
                            note( ///
                                "Results from C&S specification" " " ///
                                "Simple ATT: `=sc`hnum'`wnum'_satt_b' (se: `=sc`hnum'`wnum'_satt_se'; pval: `=sc`hnum'`wnum'_satt_pvalue')" ///
                                "Pre-avg: `=sc`hnum'`wnum'_pre_avg_b' (se: `=sc`hnum'`wnum'_pre_avg_se'; pval: `=sc`hnum'`wnum'_pre_avg_pvalue')" ///
                                "Post-avg: `=sc`hnum'`wnum'_post_avg_b' (se: `=sc`hnum'`wnum'_post_avg_se'; pval: `=sc`hnum'`wnum'_post_avg_pvalue')" ///
                                "Pretrend χ²: `=sc`hnum'`wnum'_chi2' (df: `=sc`hnum'`wnum'_df'; pval: `=sc`hnum'`wnum'_pchi2')", ///
                                box ring(0) pos(1) size(*1.1) fcolor(gs16%70) just(right) ///
                            ) ///
                        name(`w'_`=condstrov'_`var', replace) ///
                        xlab(-`=tleadmax'(2)`=tlagsmax', nogrid) /* ylab(, ) */ ///
                    ) 
                if $exportgraph graph export $figures/csdid2/e_cs_twfe/c_`w'_`var'_`=condstrov'_`cstype'_pb${pbleib}.pdf, replace 
                local listofgraphs  "`listofgraphs' `w'_`=condstrov'_`var'"
            }
            * graph combine `listofgraphs', name(`var'_comb, replace) ysize(20) xsize(20) scale(1/5)  iscale(*.8)
            if $exportgraph graph export $figures/csdid2/e_cs_twfe/c_`=tleadmax'`=tlagsmax'_`w'_`var'_`=condstrov'_`cstype'_pb${pbleib}.pdf, replace 
        }
    }
    graph close _all
    cap graph dis mcs_main_comb
    cap graph dis mcs_def_comb
    cap graph dis pcs_def_comb
    cap graph dis pcs_main_comb


    log close  
    cp $log/tmp/07_e_csdid_models_twfecs.log $log/, replace
}

*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# N>=20 
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

if 1 {

    cap log close _all
    log using $log/tmp/07_f_csdid_models_stricsample.log, text replace

    scalar tleadmaxn20 = 10 
    scalar tlagsmaxn20 = 12 
    
    foreach hnum of numlist 1/2 {
        local cstype : word `hnum' of  /*1*/main  /*2*/def  /*3*/sep  /*4*/rmean
            foreach wnum of numlist 1/4 {
            local wvar : word `wnum' of gw_nlog  nw_nlog  gw  nw
            if regexm("`wvar'","log") { /* check if log or lev */
                local islog 1 
                local ylab      ylab(-.4(.1).3, /* noticks */)
            }
            else {
                local ylab      ylab(-30(10)20, /* noticks */)
            }
            di as res 120*"~" " " "var: `wvar' | cs type: `cstype'"
            local eventplots ""
            local lev = 1
            local leg = ""
            foreach hvar of varlist ?cs_`cstype' {
                local eqname4plot e`hvar'_`wvar'n20
                cap estimates dir `eqname4plot'
                if _rc!=0 | $rerun { /* if estimates already there, do run model again */
                    csdid2 , clear
                    local ncrit = 20 
                    csdid2 `wvar' $csdidcovars  if N>=`ncrit', ivar(pid) time(syear) gvar(treat_time_`hvar') $csdid2opts
                    estat event, revent(-`=tleadmaxn20'/`=tlagsmaxn20') estore(`eqname4plot') wboot rseed(42)
                    estat group, estore(group_`hvar'_`wvar')
                    estat calendar, estore(cal_`hvar'_`wvar')
                    if 1 { /*  for table */
                        estat pretrend
                        scalar pre_df    = r(df)   
                        scalar pre_pchi2 = r(pchi2)
                        scalar pre_chi2  = r(chi2) 
                        estat simple, estore(satt2_`hvar') 
                        estat event, estore(evatt2_`hvar') wboot rseed(42) 
                        eststo m2_`hvar'_`wvar': mergemodels satt2_`hvar' evatt2_`hvar'
                        estadd local Obs  `=nobs_`wvar'_`hvar''  : m2_`hvar'_`wvar'
                        * pretrend test
                        estadd scalar pre_chi2   `=pre_chi2'  : m2_`hvar'_`wvar'
                        estadd scalar pre_df     `=pre_df'    : m2_`hvar'_`wvar'
                        estadd scalar pre_pchi2  `=pre_pchi2' : m2_`hvar'_`wvar'    
                    }
                }
                local eventplots `eventplots' `eqname4plot'
                local lab : variable label `hvar'
                local levx2 = (`lev'*2)-1
                local leg `leg' `levx2' "`lab'"
                local lev = `lev'+1
            }
            if 1 { /* Do plots! */
                di "eventplots: `eventplots'"
                event_plot `eventplots', $gropt_stubs $plotopt1 ///
                graph_opt( ///
                    $gropt_title $gropt_sizes $gropt_canva ///
                    legend(order(`leg') cols(1) pos(8) ring(0) region(fcolor(gs16%80))) ///
                    name(`wvar'_comp_`cstype', replace) ///
                    xlab(-`=tleadmaxn20'(2)`=tlagsmaxn20', /* noticks */ nogrid) `ylab' ///
                ) 
                if $exportgraph graph export $figures/csdid2/f_robust/f_`wnum'`hnum'_`wvar'_`=condstrov'_n`ncrit'.pdf, replace
            }
        }
    }

    log close  
    cp $log/tmp/07_f_csdid_models_stricsample.log $log/, replace
}

**# main
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# Robustness: varying specification 
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


if 1 {

    global yes "\$\checkmark\$"
    globa  no " "

    foreach wvar of varlist gw_nlog /* nw_nlog gw nw expue expft empl_status labor_earns cardio_ev depres_ev */ {
        local regex `"expue|_ev|freq_angry|freq_worried|freq_sad"'
        if ustrregexm("`wvar'", "`regex'")          local legpos 4
        else if ustrregexm("`wvar'", "sats_")       local legpos 2
        else                                        local legpos 8
        di "legpos: `legpos'"

        * step 1
        * model: mp1
        eststo simp: csdid2 `wvar' $csdidcovars if _to_keep_pcs_main, ivar(pid) time(syear) gvar(treat_time_pcs_main) method(drimp) long2  agg(simple) notyet
        estat event, revent(-10/12) estore(mp1) wboot rseed(42) 
        savepretrend
        eststo mp1f: mergemodels simp mp1
        estaddpretrend

        * model: mm1
        eststo simp: csdid2 `wvar' $csdidcovars if _to_keep_mcs_main, ivar(pid) time(syear) gvar(treat_time_mcs_main) method(drimp) long2  agg(simple) notyet
        estat event, revent(-10/12) estore(mm1) wboot rseed(42)
        savepretrend
        eststo mm1f: mergemodels simp mm1
        estaddpretrend
        estadd local balanced   "$no",  replace : mp1f mm1f
        estadd local pbleib     "$no",  replace : mp1f mm1f
        estadd local covariates "$yes",  replace : mp1f mm1f
        estadd local notyet     "$yes",  replace : mp1f mm1f
        event_plot mp1 mm1, $gropt_stubs $plotopt1  graph_opt(name(ep1_`wvar', replace) $gropt_sizes $gropt_canva $gropt_title $gropt_legen) 
        if $exportgraph graph export $figures/csdid2/f_robust/ep1_`wvar'.pdf, replace

        * step 2
        * model: mp2    
        eststo simp: csdid2 `wvar'              if _to_keep_pcs_main, ivar(pid) time(syear) gvar(treat_time_pcs_main) method(drimp) long2  agg(simple) 
        estat event, revent(-10/12) estore(mp2) wboot rseed(42)
        savepretrend
        eststo mp2f: mergemodels simp mp2
        estaddpretrend

        * model: mm2    
        eststo simp: csdid2 `wvar'              if _to_keep_mcs_main, ivar(pid) time(syear) gvar(treat_time_mcs_main) method(drimp) long2  agg(simple) 
        estat event, revent(-10/12) estore(mm2) wboot rseed(42)
        savepretrend
        eststo mm2f: mergemodels simp mm2
        estaddpretrend

        estadd local balanced   "$no",  replace : mp2f mm2f
        estadd local pbleib     "$no",  replace : mp2f mm2f
        estadd local covariates "$no", replace : mp2f mm2f
        event_plot mp2 mm2, $gropt_stubs $plotopt1 graph_opt(name(ep2_`wvar', replace) $gropt_sizes $gropt_canva $gropt_title $gropt_legen) 
        if $exportgraph graph export $figures/csdid2/f_robust/ep2_`wvar'.pdf, replace

        * step 3
        * model: mp3    
        eststo simp: csdid2 `wvar' $csdidcovars if _to_keep_pcs_main [aw=pbleib], ivar(pid) time(syear) gvar(treat_time_pcs_main) method(drimp) long2  agg(simple) 
        estat event, revent(-10/12) estore(mp3) wboot rseed(42)
        savepretrend
        eststo mp3f: mergemodels simp mp3
        estaddpretrend

        * model: mm3    
        eststo simp: csdid2 `wvar' $csdidcovars if _to_keep_mcs_main [aw=pbleib], ivar(pid) time(syear) gvar(treat_time_mcs_main) method(drimp) long2  agg(simple) 
        estat event, revent(-10/12) estore(mm3) wboot rseed(42)
        savepretrend
        eststo mm3f: mergemodels simp mm3
        estaddpretrend

        estadd local balanced   "$no",  replace : mp3f mm3f
        estadd local pbleib     "$yes", replace : mp3f mm3f
        estadd local covariates "$yes", replace : mp3f mm3f
        event_plot mp3 mm3, $gropt_stubs $plotopt1 graph_opt(name(ep3_`wvar', replace) $gropt_sizes $gropt_canva $gropt_title $gropt_legen) 
        if $exportgraph graph export $figures/csdid2/f_robust/ep3_`wvar'.pdf, replace

        * step 4
        * model: mp4    
        eststo simp: csdid2 `wvar' $csdidcovars if _to_keep_pcs_main & N==20 , ivar(pid) time(syear) gvar(treat_time_pcs_main) method(drimp) long2  agg(simple)
        estat event, revent(-10/12) estore(mp4) wboot rseed(42)
        savepretrend
        eststo mp4f: mergemodels simp mp4
        estaddpretrend

        * model: mm4    
        eststo simp: csdid2 `wvar' $csdidcovars if _to_keep_mcs_main & N==20 , ivar(pid) time(syear) gvar(treat_time_mcs_main) method(drimp) long2  agg(simple)
        estat event, revent(-10/12) estore(mm4) wboot rseed(42)
        savepretrend
        eststo mm4f: mergemodels simp mm4
        estaddpretrend

        estadd local balanced   "$yes", replace : mp4f mm4f
        estadd local pbleib     "$no",  replace : mp4f mm4f
        estadd local covariates "$yes", replace : mp4f mm4f
        event_plot mp4 mm4, $gropt_stubs $plotopt1 graph_opt(name(ep4_`wvar', replace) $gropt_sizes $gropt_canva $gropt_title $gropt_legen) 
        if $exportgraph graph export $figures/csdid2/f_robust/ep4_`wvar'.pdf, replace

        
        estadd scalar Obs = `=nobs_pcs_main', replace : mp1f mp2f mp3f
        estadd scalar Obs = `=nobs_mcs_main', replace : mm1f mm2f mm3f
        estadd scalar Pids = `=pids_pcs_main', replace : mp1f mp2f mp3f
        estadd scalar Pids = `=pids_mcs_main', replace : mm1f mm2f mm3f

        distinct pid if N==20 & _to_keep_pcs_main & !(treat_time_pcs_main==syear & _n==1)
        estadd scalar Pids = r(ndistinct)  , replace : mp4f 
        estadd scalar Obs  = r(N)          , replace : mp4f 
        distinct pid if N==20 & _to_keep_mcs_main & !(treat_time_mcs_main==syear & _n==1)
        estadd scalar Pids = r(ndistinct)  , replace : mm4f 
        estadd scalar Obs  = r(N)          , replace : mm4f 
            
        * local wvar gw_nlog
        esttab mp1f mp2f mp3f mp4f    mm1f mm2f mm3f mm4f ///
           using $incl_thesis/tbls/t_cmp_`wvar'.tex, ///
            /* s(N covariates pbleib balanced, l("Covariates" "Inv.Pr(stay)" "Balanced")) */ ///
            label replace cells(b(star fmt(2)) se(par fmt(2))) ///
            stats( ///
                Obs Pids pre_chi2 pre_df   pre_pchi2 covariates pbleib balanced notyet, ///
                layout("{@}" "{@}" `""{@ (@)}""' "{@}" "{@}" "{@}" "{@}" "{@}") fmt(%9.0gc %9.0gc %9.3gc  %9.2gc 3) ///
                labels("N" "Unique N" "Pretrend \$\chi^2\$ (df)" "Pretrend p-value" "Covariates" "Inv.Pr(stay)" "Balanced" "Not Yet") ///
            )  nomtitles nonumbers depvars  /// 
            nolines  prefoot(\midrule)  booktabs ///
            mlabels(,none) collabels(,none) type prehead("") postfoot("\bottomrule") ///
            transform(100*(exp(@)-1) 100*exp(@)) /* all models are log, transform all coefs */
            /* since we are dealing with log-lin, transform for easier interpretation */


            fixtable $incl_thesis/tbls/t_cmp_`wvar'.tex
    }

}

*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# table
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
dtable ?cs_main gw_nlog nw_nlog nw gw  age i.sex i.educ_highschool N if n==1 &  _to_keep_pcs_main, by(treat_any_pcs_main)
dtable ?cs_main gw_nlog nw_nlog nw gw  age i.sex i.educ_highschool N if n==1 &  _to_keep_mcs_main, by(treat_any_mcs_main)



exit 
