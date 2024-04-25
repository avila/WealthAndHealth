*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*** MA: The health-wealth nexus over the life cycle
*** Au: Marcelo Rainho Avila (4679876)
*** Dt: 07.02.2024
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

cap log close _all
log using $log/tmp/06_attrition.log, text replace

*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# health shocks impact in wealth build up
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

use pid syear using $soep_data/pgen.dta, clear
merge 1:1 pid syear using $soep_data/ppathl.dta, gen(_mg_pgen_ppathl) keepus(gebjahr erstbefr) keep(3)
merge 1:1 pid syear using $inter/03_clean_lr_all_years.dta, gen(_mg_pgen_allyears)

drop age
gen age = syear - gebjahr
drop if mi(age)
mvdecode gebjahr erstbefr, mv(-1 = .a \ -2 = .b \ -3 = .c \ -4 = .d \ -5 = .e \ -6 = .f \ -7 = .g \ -8 = .h) 
save $temp/xatri.dta, replace

**# 
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
use $temp/xatri.dta, clear

scalar cs_type = "main"
scalar last_x = 10
scalar min_n = 2
sort pid syear

tsset pid syear

cap drop pcs_mu
cap drop mcs_mu
tsegen pcs_mu = rowmean( L(1/`=last_x').pcs_`=cs_type', `=min_n' )
tsegen mcs_mu = rowmean( L(1/`=last_x').mcs_`=cs_type', `=min_n' )

cap drop pcs_sd
cap drop mcs_sd
tsegen pcs_sd = rowsd( L(1/`=last_x').pcs_`=cs_type', `=min_n' )
tsegen mcs_sd = rowsd( L(1/`=last_x').mcs_`=cs_type', `=min_n' )

**# nrm
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
cap drop pcs_mu_nrm
egen pcs_mu_nrm = std(pcs_mu)
lab var pcs_mu_nrm "norm(mean(pcs)) [`=cs_type']"
cap drop mcs_mu_nrm
egen mcs_mu_nrm = std(mcs_mu)
lab var mcs_mu_nrm "norm(mean(mcs)) [`=cs_type']"

cap drop pcs_sd_nrm
egen pcs_sd_nrm = std(pcs_sd)
lab var pcs_sd_nrm "norm(sd(pcs)) [`=cs_type']"
cap drop mcs_sd_nrm
egen mcs_sd_nrm = std(mcs_sd)
lab var mcs_sd_nrm "norm(sd(mcs)) [`=cs_type']"

**# log
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
cap drop pcs_mu_log
gen pcs_mu_log = log(pcs_mu)
lab var pcs_mu_log "log(mean(pcs)) [`=cs_type']"
cap drop mcs_mu_log
gen mcs_mu_log = log(mcs_mu)
lab var mcs_mu_log "log(mean(mcs)) [`=cs_type']"

cap drop pcs_sd_log
gen pcs_sd_log = log(pcs_sd)
lab var pcs_sd_log "log(sd(pcs)) [`=cs_type']"
cap drop mcs_sd_log
gen mcs_sd_log = log(mcs_sd)
lab var mcs_sd_log "log(sd(mcs)) [`=cs_type']"




sum pcs_mu mcs_mu pcs_sd mcs_sd pcs_mu_nrm mcs_mu_nrm pcs_sd_nrm mcs_sd_nrm 

save $temp/xatri2.dta, replace

*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# stset 
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
use $temp/xatri2.dta, clear

bys pid (syear): gen N = _N 
bys pid (syear): gen n = _n 
bys pid (syear): gen yoe = syear[_n==1]
bys pid (syear): egen maxage = max(age)

cap drop out 
gen out = 0 
replace out = 1 if n==N & syear < 2020
replace out = -1 if syear >= 2020
*replace out = -2 if maxage>=68 & out == 1 /* if they drop out after "retirement", does not count */
* tag pid syear psample age n N out mcs pcs nw_curt if inrange(N, 3, 7) & out==1
* tag pid syear psample age n N out mcs pcs nw_curt if inrange(N, 3, 7) & out==2
* tag pid syear psample age n N out mcs pcs nw_curt if inrange(N, 3, 7) & inlist(out,1,2)
* tag pid syear psample age n N out ?cs_main ?cs_main_sd ?cs_?? nw_curt if inrange(N, 3, 7) & out==1

*keep if n == 1 

if 1 {
    stset syear , failure(out==1) id(pid) origin(time erstbefr) 
}
else {
    keep if syear>=2002
    stset n , failure(out==1) id(pid) origin(n==1)
}

sum _st _d _t _t0
* tag pid syear psample n N out _st _d _t _t0 if _st==1
if 0 {
    stsum, by(nw_qile)
    sts graph    
}

cap drop gw_age_q?

levelsof age_cuts_05, local(agelevs)
foreach lv of local agelevs {
    di "lv (age level): `lv'"
    cap drop gw_age_q`lv'
    gquantiles gw_age_q`lv' = gw if age_cuts_05==`lv', xtile nq(5)
}
cap drop W
egen W = rowtotal(gw_age_q??), missing
lab def WQ_age_5 1 "1st"  2 "2nd"  3 "3rd"  4 "4th"  5 "5th", replace
lab val W WQ_age_5
fre  W

sts graph,  by(W) name(kpme_nw_qile_age, replace) ci   ysize(6) xsize(7) leg(cols(3)) title("") scale(1.3) leg(title("Gross Wealth Quintile", size(vsmall)))
graph export $figures/attrition/kpme_surv_nw_qile_age.pdf, replace


stphplot, by(nw_qile_age )
streg ?cs_??_nrm, distribution(weibull) strata(nw_qile_age )
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

foreach var of varlist ?cs_??_nrm {
    foreach num of numlist 1/4 {
        di "var: `var'.  num: `num'"
        cap drop `var'_q_`num'
        gquantiles `var'_q_`num' = `var' if age_g1==`num', xtile nq(4)
    }
    cap drop `var'_q_age
    egen `var'_q_age = rowtotal(`var'_q_?), missing
}
sts graph, by(pcs_mu_nrm_q_age) name(kpme_pcs_mu_nrm_q_age, replace) ci  ysize(5) xsize(5)
graph export $figures/attrition/kpme_pcs_mu_nrm_q_age.pdf
sts graph, by(pcs_sd_nrm_q_age) name(kpme_pcs_sd_nrm_q_age, replace) ci  ysize(5) xsize(5)
graph export $figures/attrition/kpme_pcs_sd_nrm_q_age.pdf
sts graph, by(mcs_mu_nrm_q_age) name(kpme_mcs_mu_nrm_q_age, replace) ci  ysize(5) xsize(5)
graph export $figures/attrition/kpme_mcs_mu_nrm_q_age.pdf
sts graph, by(mcs_sd_nrm_q_age) name(kpme_mcs_sd_nrm_q_age, replace) ci  ysize(5) xsize(5)
graph export $figures/attrition/kpme_mcs_sd_nrm_q_age.pdf

sts graph, ysize(5) xsize(5) ci
graph export $figures/attrition/kpme_main.pdf, replace

stcox pcs_mu_nrm `=covs' i.nw_dile
stcox pcs_sd_nrm `=covs' i.nw_dile
stcox mcs_mu_nrm `=covs' i.nw_dile
stcox mcs_sd_nrm `=covs' i.nw_dile

stcox pcs_main `=covs' i.nw_dile
stcox pcs_main_sd `=covs' i.nw_dile
stcox mcs_main `=covs' i.nw_dile
stcox mcs_main_sd `=covs' i.nw_dile

stcox nw_nlog `=covs'


sts graph if inrange(age_g1, 1,4), by(empl_level) name(kpme_`var', replace)
sts graph, by(educ_highschool) 

sts list, by(empl_level)  

sts graph, by(educ_highschool)


foreach var of varlist ?cs_main ?cs_main_sd  {
    di "var: `var'"
    cap drop `var'_q
    gquantiles `var'_q = `var', xtile nq(4)
    fre `var'_q
    sts graph, survival by(`var'_q) name(kpme_`var', replace) ci lost
}

stcox pcs_mu mcs_mu pcs_sd mcs_sd `=covs'

estimate drop _all
foreach var of varlist ?cs_??_nrm {
    di "var: `var'"
    stcox i.`var'_q `=covs' expue expft i.educ_highschool
    est sto cox_`var'_`x'
}

*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# variation by levels of level var (mcs pcs)
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sum ?cs_main
qhist ?cs_main

cap drop  pcs_lv
egen pcs_lv = cut(pcs_main), at(0 30 40 50 60 9e9) ic lab
cap drop  mcs_lv
egen mcs_lv = cut(mcs_main), at(0 30 40 50 60 9e9) ic lab
fre ?cs_lv

sts graph, by(pcs_lv) name(kpme_pcs_lv, replace) ci
sts graph, by(mcs_lv) name(kpme_mcs_lv, replace) ci

bys pid: egen pcs_d = max(pcs_main<=35)
bys pid: egen mcs_d = max(mcs_main<=35)
sts graph if inrange(age, 20, 60), by(pcs_d) name(kpme_pcs_d, replace) ci
sts graph if inrange(age, 20, 60), by(mcs_d) name(kpme_mcs_d, replace) ci


cap drop pcs_min
bys pid: egen pcs_min = min(pcs_main)
cap drop mcs_min
bys pid: egen mcs_min = min(mcs_main)
cap drop  pcs_min_lv
egen pcs_min_lv = cut(pcs_min), at(0 30 40 50 60 /* 9e9 */) ic lab
cap drop  mcs_min_lv
egen mcs_min_lv = cut(mcs_min), at(0 30 40 50 60 /* 9e9 */) ic lab

sts graph, by(pcs_min_lv) name(kpme_pcs_lv, replace) ci
sts graph, by(mcs_min_lv) name(kpme_mcs_lv, replace) ci


*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# by age group
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
scalar covs = "c.age##c.age"
estimate drop _all
foreach var of varlist ?cs_??_nrm  nw_nlog {
    foreach ag of numlist 1/3 {
        di "var: `var'. age group: `ag'"
        count if  age_g1==`ag'
        qui stcox `var' `=covs' /* expue expft i.educ_highschool */ if age_g1==`ag'
        est sto cox_`var'_`ag'  
    }
}

gen nw_nlog2 = nw_nlog^2

stcox /* ?cs_??_nrm  */  c.nw_nlog##c.nw_nlog  `=covs'  /* expue expft educ_highschool */
est sto cox_all
estimate table cox*, star(.1 .05 .01) drop(`=covs') stats(N ll r2 aic rank)


stcox pcs_mu_nrm `=covs' i.nw_qile  /* expue expft educ_highschool */
stcox pcs_sd_nrm `=covs' i.nw_qile  /* expue expft educ_highschool */
stcox mcs_mu_nrm `=covs' i.nw_qile  /* expue expft educ_highschool */
stcox mcs_sd_nrm `=covs' i.nw_qile  /* expue expft educ_highschool */


*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# 
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
stcox /* ?cs_??_nrm  */  c.nw_nlog##c.nw_nlog  `=covs'  /* expue expft educ_highschool */
margins, at(nw_nlog=(-7 -5 -3 -1 1 3 5 7 9))
marginsplot, x(nw_nlog ) name(nw_nlog, replace)

stcox /* ?cs_??_nrm  */  c.gw_nlog##c.gw_nlog  `=covs'  /* expue expft educ_highschool */
margins, at(gw_nlog=(0 1 3 5 7 9))
marginsplot, x(gw_nlog ) name(gw_nlog, replace)

*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# single
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
scalar covs = "c.age##c.age"
estimate drop _all
foreach var of varlist ?cs_??_nrm  ?w_nlog {
        di "var: `var'. age group: `ag'"
        
        qui stcox `var' `=covs' /* expue expft i.educ_highschool */
        est sto cox_`var'_single
}
estimate table cox*_single, star(.1 .05 .01) drop(`=covs') stats(N ll r2 aic rank)


foreach var of varlist ?cs_??_nrm {
    reg nw_nlog `var'
}
reg nw_nlog ?cs_??_nrm





if 0 {
    use https://www.stata-press.com/data/r18/drugtr, clear
    st
    list
    summarize
}



*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

log close  
cp $log/tmp/06_attrition.log $log/, replace



exit 
