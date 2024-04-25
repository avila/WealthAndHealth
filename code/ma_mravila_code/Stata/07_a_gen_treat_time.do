*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*** MA: The health-wealth nexus over the life cycle
*** Au: Marcelo Rainho Avila (4679876)
*** Dt: 07.02.2024
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

cap log close _all
log using $log/tmp/07_a_gen_treat_time.log, text replace


*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# merge final dataset
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
use $inter/health_factor_scores.dta, clear
sort pid syear
merge 1:1 pid syear using $inter/03_clean_lr_even_years.dta, gen(_mg_scor_03even)
merge 1:1 pid syear using $inter/data_general_sample_all_years.dta, nogen keep(3) keepus(phrf pbleib)
keep if _mg_scor_03even==3

*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**#  get final obss
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
egen rm0 = rowmiss(mcs_main pcs_main)
egen rm1 = rowmiss(mcs_main pcs_main nw gw)
egen rm2 = rowmiss(mcs_main pcs_main nw gw sex age bula legal_handicapped_bin marital_status)
egen rm3 = rowmiss(educ_highschool educ_years)
fre rm?

keep if rm1==0 
keep if rm2==0 
* keep if rm3==0


* restrict age
keep if inrange(age, 18, 75)


cap drop N
bys pid: gen N = _N*2
label var N "Years in SOEP"
sort pid syear
cap drop n
bys pid: gen int n = _n

keep if N>=4
* qhist ?w ?w_nlog


*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# options and set final dataset
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
* https://www.statalist.org/forums/forum/general-stata-discussion/general/1705205-csdid-of-callaway-and-sant-anna-2021-framework-how-to-obtain-the-propensity-scores-in-the-ipw-estimator-in-stata

scalar tleadmax = 10
scalar tlagsmax = 12
scalar crit     =  2           //   2    / 1
scalar condstr  = "1/2"        //  "1/2" / 1

foreach hnum of numlist 1 2 3 4  {
    local cstype : word `hnum' of  /*1*/main  /*2*/def  /*3*/sep  /*4*/rmean
    foreach csphme in pcs mcs {
        di "csphme: `csphme'"
        local var `csphme'_`cstype'
        di "var: `var'"
        cap drop mean_`var'
        bys age sex : egen mean_`var' = mean(`var')
        cap drop diff_`var'
        gen diff_`var' = `var' - mean_`var'
        qui sum diff_`var', detail
        local sd = round(r(sd), 0.01)
        local med = round(r(p50), 0.01)

        scalar condstrov = ustrregexrf("`=condstr'", "/", "o")
        scalar cond_fin = (`med'-((`=condstr')*`sd'))
        di as error "cond_fin: `=cond_fin'. sd diff_var: `sd'. cond: `=condstr'"
        sort pid syear
        gentreats2 if diff_`var' < `=cond_fin', verbose suffix(_`var') crit(`=crit')
        * genleadlags, timeto(timeto_`var') ttime(p) leads(`=tleadmax') lags(`=tlagsmax') delta(2) 
        replace treat_time_`var'=0 if mi(treat_time_`var')    
        cap drop _to_keep_`var'
        if 1 {
            /* keep if within window with enough obs in each group. Small N outside window -> high estim variance */
            gen _to_keep_`var' = (inrange(timeto_`var',-`=tleadmax',`=tlagsmax') | mi(timeto_`var'))
        }
        if 1 {
            /* replace to 0 if always treated. same behaviour as in Stata's xtdidregress command */
            /* it seems csdid drop them as well automatically */
            replace _to_keep_`var' = 0 if (/* syear==2002 & */ treat_time_`var'==2002)
            replace _to_keep_`var' = 0 if n == 1 & treat_time_`var'==syear /* drop if always treatd (first syear == firsttreatyear) */
        }
        if 1 { /* untreated */
            cap drop _treat_time_`var'
            bys pid (diff_`var'): gen _treat_time_`var' = syear[1] /* get first obs (lowest health variable) */
            cap drop _timeto_`var'
            gen _timeto_`var' = syear - _treat_time_`var' 
            replace _timeto_`var' = timeto_`var' if !mi(timeto_`var')
            label var _treat_time_`var' "Treatment year"
            label var _timeto_`var' "Years relative to treatment"
        }
    }
}

dtable ?cs_main ?cs_def  gw_nlog nw_nlog nw gw  age i.sex educ_years  i.educ_highschool N if n==1 &  _to_keep_pcs_main, by(treat_any_pcs_main)
dtable ?cs_main ?cs_def  gw_nlog nw_nlog nw gw  age i.sex educ_years  i.educ_highschool N if n==1 &  _to_keep_mcs_main, by(treat_any_mcs_main)

tab treat_any_mcs_main  treat_post_mcs_main
tab treat_any_pcs_main  treat_post_pcs_main
tab treat_any_pcs_def  treat_post_pcs_def


**# notes
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
notes drop _all 
note: tleadmax = `=tleadmax' 
note: tlagsmax = `=tlagsmax' 
note: crit     = `=crit' 
note: condstr  = `=condstr' 

**# save
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
save $inter/07_did_gentreattime.dta, replace


log close  
cp $log/tmp/07_a_gen_treat_time.log $log/, replace
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
exit

if 0 {
    /* alternative models */
    scalar crit     =   1           //   2    / 1
    scalar condstr  =   "1"        //  "1/2" / 1
    global rerun        1    
}
