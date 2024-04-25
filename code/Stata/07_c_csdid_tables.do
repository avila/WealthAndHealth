*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*** MA: The health-wealth nexus over the life cycle
*** Au: Marcelo Rainho Avila (4679876)
*** Dt: 07.02.2024
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

cap log close _all
log using $log/tmp/07_c_csdid_tables.log, text replace


*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# globals
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
global exportgraph     1


*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# read data
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
use $inter/07_did_gentreattime.dta, clear
desc, short
sort pid syear
xtset pid syear, delta(2)

/* keep smaller dta in memory for faster loops */
merge 1:1 pid syear using $inter/07_csdid_1_nobs.dta, gen(mg_nobs)



*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# overview tables
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

tab syear treat_post_pcs_main if _smp_gw_pcs_main
tab syear treat_post_mcs_main if _smp_gw_mcs_main

distinct pid if _smp_gw_pcs_main
distinct pid if _smp_gw_mcs_main


*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# generate counters
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

global contvars  age educ_years ?cs_main gw_nlog nw_nlog gw nw expue expft 
global factvars  sex marital_status educ_highschool empl_status // i.east
cap drop rowmiss rowcomplete
egen rowmiss = rowmiss($contvars $factvars)
gen rowcomplete = (rowmiss==0)
cap drop pid_x_n*
bys pid (syear): gen pid_x_n_pcs_main = _N if _to_keep_pcs_main & rowcomplete & _smp_gw_pcs_main
bys pid (syear): gen pid_x_n_mcs_main = _N if _to_keep_mcs_main & rowcomplete & _smp_gw_mcs_main
bys pid: gen n_smp_pcs_main = _n if _smp_gw_pcs_main
bys pid: gen n_smp_mcs_main = _n if _smp_gw_mcs_main
bys pid (syear): gen pid_x_n_pcs_def = _N if _to_keep_pcs_def & rowcomplete & _smp_gw_pcs_def
bys pid (syear): gen pid_x_n_mcs_def = _N if _to_keep_mcs_def & rowcomplete & _smp_gw_mcs_def
bys pid: gen n_smp_pcs_def = _n if _smp_gw_pcs_def
bys pid: gen n_smp_mcs_def = _n if _smp_gw_mcs_def


*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# table
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
collect clear
global ifcond _to_keep_mcs_main & _smp_gw_mcs_main & rowcomplete

numlabel sex_EN d11104 d11108 e11102 , remove mask("[#] ")
lab var  treat_any_pcs_main "Eventually Treated (PCS)"
lab var  treat_any_mcs_main "Eventually Treated (MCS)"
label define treated 0 "no" 1 "yes"
lab val treat_any_* treat_post_* treated

local hvar pcs_main
dtable if n_smp_`hvar'==1 &  _to_keep_`hvar', by(treat_any_`hvar', nototal tests)  /// 
    continuous($contvars, stat(mean sd)) /// 
    factor($factvars) ///
    sample(, statistic(frequency percent) place(seplabels) )  ///
    nformat(%16.2fc mean sd) nformat(%16.0fc total)  nolistwise name(t2)  replace /// 
    export($incl_thesis/tbls/t1_`hvar'.tex, replace  tableonly)
styletextab , fragment


local hvar mcs_main
dtable if n_smp_`hvar'==1 &  _to_keep_`hvar', by(treat_any_`hvar', nototal tests)  /// 
    continuous($contvars, stat(mean sd)) /// 
    factor($factvars) ///
    sample(, statistic(frequency percent) place(seplabels) )  ///
    nformat(%16.2fc mean sd) nformat(%16.0fc total)  nolistwise name(t2)  replace /// 
    export($incl_thesis/tbls/t1_`hvar'.tex, replace  tableonly)
styletextab , fragment

*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# overlap support 
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


foreach varhealth of varlist ?cs_main ?cs_def {
    di "var: `varhealth'"
    if mi("$csdidcovars") {
        di as err "make sure global 'csdidcovars' is defined "
        exit 42
    }
    qui logit treat_any_pcs_main $csdidcovars if _smp_gw_`varhealth' & _timeto_`varhealth'==0
    cap drop pi_`varhealth' 
    predict pi_`varhealth'
    cap drop ipw_`varhealth'
    gen     ipw_`varhealth' = 1/pi_`varhealth'          if treat_post_`varhealth' == 1
    replace ipw_`varhealth' = 1 / (1-pi_`varhealth')    if treat_post_`varhealth' == 0
}


**# plot options
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
global gropt_sizes_os  scale(2.2) xsize(9) ysize(6)
global gropt_canva_os  graphregion(color(white)) bgcolor(white) ylabel(, angle(horizontal)) 
global gropt_title_os  xtitle("\`yvar'") ytitle("Density( Y | treat={0,1})") 
global gropt_legen_os  legend(order(1 "Untreated" 2 "Treated")  cols(1) ring(0) pos(\`legpos') region(fcolor(gs16%80)) )
global gropt_linp0_os  lc(stc1) lp(dash)  /* lw(.5) */
global gropt_linp1_os  lc(stc2) lp(solid) /* lw(.5) */


set graph off

**# plot
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
preserve
foreach hnum of numlist  1 2 /* 3 4 */ {
local cstype : word `hnum' of  /*1*/main  /*2*/def  /*3*/sep  /*4*/rmean
    foreach varhealth of varlist pcs_`cstype' mcs_`cstype' {
        keep if _smp_gw_`varhealth' & n_smp_`varhealth'==1
        if      "`varhealth'"=="pcs_`cstype'" local firstvars pcs_`cstype' mcs_`cstype'
        else if "`varhealth'"=="mcs_`cstype'" local firstvars mcs_`cstype' pcs_`cstype' 
        foreach var of varlist /* `firstvars' */ pi_`varhealth' /* gw gw_nlog nw nw_nlog age */  {
            local regex `"nw_nlog|kd_pcs_main_pcs_main|kd_pcs_def_pcs_def|kd_mcs_main_mcs_main"'
            if ustrregexm("kd_`var'_`varhealth'", "`regex'")          local legpos 11
            else                                                      local legpos 1
            twoway kdensity `var' if treat_any_`varhealth' == 0, $gropt_linp0_os || kdensity `var' if treat_any_`varhealth' == 1, $gropt_linp1_os ///
                name(kd_`var'_`varhealth', replace) $gropt_sizes_os $gropt_canva_os $gropt_title_os $gropt_legen_os
            if $exportgraph graph export $figures/csdid2/g_kdens/kd_`var'_`varhealth'.pdf, replace
        }
        restore, preserve
    }
}





*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# DONE
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
log close  
cp $log/tmp/07_c_csdid_tables.log $log/, replace


exit 



/* 
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  _______                        _       
 |__   __|                      | |      
    | |     _ __    __ _   ___  | |__    
    | |    | '__|  / _` | / __| | '_ \   
    | |    | |    | (_| | \__ \ | | | |  
    |_|    |_|     \__,_| |___/ |_| |_|  
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/


/* 
dtable ?cs_main gw_nlog nw_nlog nw gw  age i.sex i.educ_highschool N if smp_gw_mcs_main & _to_keep_mcs_main, by(treat_any_mcs_main)



dtable ?cs_main /* ?cs_def */  gw_nlog nw_nlog nw gw /* nw_r gw_r */  age i.sex educ_years  i.educ_highschool N if _timeto_mcs_main==0 & _to_keep_mcs_main & smp_gw_nlog_mcs_main, by(treat_any_mcs_main, tests)
dtable ?cs_main /* ?cs_def */  gw_nlog nw_nlog nw gw /* nw_r gw_r */  age i.sex educ_years  i.educ_highschool N if _timeto_mcs_main==0 & _to_keep_mcs_main & smp_gw_nlog_mcs_main, by(treat_any_mcs_main, tests)

use  $inter/07_did_gentreattime.dta, clear 

global contvars  N age educ_years ?cs_main gw_nlog nw_nlog gw nw expue expft  
global factvars  sex marital_status educ_highschool // i.east
cap drop rowmiss
egen rowmiss = rowmiss($contvars $factvars)

cap drop pid_x_n*
bys pid (syear): gen pid_x_n_mcs_main = _N if _to_keep_mcs_main==1 & rowmiss==0
bys pid (syear): gen pid_x_n_pcs_main = _N if _to_keep_pcs_main==1 & rowmiss==0

lab var pid_x_n_mcs_main "Total Obs. (N\texttimes T)"
lab var pid_x_n_pcs_main "Total Obs. (N\texttimes T)"
numlabel sex_EN sex d11108 d11104, remove mask("[#] ")
lab var educ_years       "Years of Education"
lab var expue            "Unemployment Experience (years)"
lab var expft            "Full-Time Experience (years)"
lab var educ_highschool  "Educational Attainment"

foreach hvar of varlist ?cs_main {
    dtable if _timeto_`hvar'==0 &  _to_keep_`hvar', by(treat_any_`hvar')  /// 
    continuous(pid_x_n_`hvar', stat(totobs)) /// 
    continuous($contvars, stat(mean sd)) /// 
    factor($factvars) ///
    sample(Unique Obs., place(items)) ///
    nformat(%16.2fc mean sd) nformat(%16.0fc total)  ///
    define(totobs =  total perc  , delimiter("") notrim) ///
    name(t1) replace export(/tmp/t1_`hvar'.tex, replace  tableonly) ///
    nolistwise
}
cp /tmp/t1_mcs_main.tex $incl_thesis/tbls/, replace
cp /tmp/t1_pcs_main.tex $incl_thesis/tbls/, replace
