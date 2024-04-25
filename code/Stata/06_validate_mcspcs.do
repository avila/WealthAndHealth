*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*** MA: The health-wealth nexus over the life cycle
*** Au: Marcelo Rainho Avila (4679876)
*** Dt: 07.02.2024
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

cap log close _all
log using $log/tmp/06_validate_mcspcs.log, text replace


*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# 06_validate_mcspcs.do
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

use $inter/health_factor_scores.dta, clear
merge 1:1 pid syear using $inter/03_clean_lr_even_years.dta, keep(3) gen(_mg)
collapse gh_p bp_p pf_p rp_p  vt_m sf_m mh_m re_m ?cs_main ?cs_def, by(age_cuts_05)
stdize pcs_def mcs_def pcs_main mcs_main gh_p pf_p bp_p rp_p mh_m vt_m re_m sf_m , mean(50) sd(10) replace
save /tmp/xxxxxxxxxxxxxx.dta, replace

lab var pcs_def   "PCS (sf12)"
lab var mcs_def   "MCS (sf12)"
lab var pcs_main  "PCS (oblique)"
lab var mcs_main  "MCS (oblique)"
lab var gh_p      "General Health"
lab var pf_p      "Physical Function"
lab var bp_p      "Bodily Pain"
lab var rp_p      "Role Physical"
lab var mh_m      "Mental Health"
lab var vt_m      "Vitality"
lab var re_m      "Role Emotional"
lab var sf_m      "Social Function"

keep if inrange(age_cuts_05, 20, 85)


      


global ms ms(D O d oh dh th sh )
global lp lp(l l  _ - . -. -#-   __.__.)
global op scale(1.5) yline(50,lp(dash)lc(gray)) xsize(9) ysize(8) xtitle("age (grouped by 5-years intervals)")

tw connected  mcs_main mcs_def     ??_m             age_cuts_05, ///
      name(mcs,replace) leg(col(2))  $ms $lp $op  
      

tw connected  pcs_main pcs_def     ??_p             age_cuts_05, ///
      name(pcs,replace) leg(col(2)) $ms $lp $op  



**# read data
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
use if syear >= 2002 using $inter/03_clean_lr_all_years.dta, clear
merge m:1 pid using $inter/05_traj_modelled_unique_pid.dta, gen(_mg_traj_lr)
merge 1:1 pid syear using  $inter/07_did_gentreattime.dta, gen(_mg_07treattime)

keep if _mg_traj_lr==3 & _mg_07treattime==3
drop if sex==-3
replace mcs_sep = mcs_sep + rnormal()
replace pcs_sep = pcs_sep + rnormal()
replace mcs_rmean = mcs_rmean + rnormal()
replace pcs_rmean = pcs_rmean + rnormal()

**# explore
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

ll mcs_main hd_*_ever

/* foreach var of varlist hd_*_ever {
    di "var: `var'"
    tabstat ?cs_main ?cs_def ?cs_main_sd, by(`var')
} */



**# gen covars
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
/* for some reason working with interaction terms bugs binsreg */
gen age_sq = age^2


**# graphs
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

global binsreg_opts      /* cb(3 3) */ ci(3 3) /* level(99) */ /* polyreg(3) */ usegtools(on) /* absorb(syear) */
global graph_opts_validmcspcs        aspect(1) xsize(6) ysize(6) scale(1.2) ciplotopt(mcolor(%65) color(%65) lcolor(%65) ) dotsplotopt(mcolor(%65) ylab(0(.05).3)) 

**# mcs
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
graph drop _all
if 0 {
    foreach var of varlist hd_*_ever {
        di "var: `var'"
        binslogit `var' mcs_main age_sp?, name(gr_mcs_`var', replace) by(traj_Group) ci(3 3) scale(1.5)
    }    
}

scatterfit pcs_main  age if inrange(age,20,75), binned $sfcol opts(name(pcs_main_age,  replace) title("Main alternative",pos(11)) subtitle("Oblique rotation",pos(11)) ytitle("")  ) by(educ_highschool) fit(lpoly) bw(3) 
scatterfit mcs_main  age if inrange(age,20,75), binned $sfcol opts(name(mcs_main_age,  replace) title("Main alternative",pos(11)) subtitle("Oblique rotation",pos(11)) ytitle("")  ) by(educ_highschool) fit(lpoly) bw(3) 
scatterfit pcs_def   age if inrange(age,20,75), binned $sfcol opts(name(pcs_def_age,   replace) title("SOEPs default",pos(11)) subtitle("SF12 method",pos(11)) ytitle("")  ) by(educ_highschool) fit(lpoly) bw(3) 
scatterfit mcs_def   age if inrange(age,20,75), binned $sfcol opts(name(mcs_def_age,   replace) title("SOEPs default",pos(11)) subtitle("SF12 method",pos(11)) ytitle("")  ) by(educ_highschool) fit(lpoly) bw(3) 
scatterfit pcs_rmean age if inrange(age,20,75), binned $sfcol opts(name(pcs_rmean_age, replace) title("Simple alternative",pos(11)) subtitle("simple average",pos(11)) ytitle("")  ) by(educ_highschool) fit(lpoly) bw(3) 
scatterfit mcs_rmean age if inrange(age,20,75), binned $sfcol opts(name(mcs_rmean_age, replace) title("Simple alternative",pos(11)) subtitle("simple average",pos(11)) ytitle("")  ) by(educ_highschool) fit(lpoly) bw(3) 

grc1leg2 mcs_def_age mcs_main_age mcs_rmean_age, rows(1) ycommon xcommon xsize(12) ysize(7) /// 
    title("Comparison of different mental health scores over age by education level")  scale(1.2)  lrow(1) 
graph export $figures/validatingmcspcs/mcs_comp_age.png, replace wid(5000)

grc1leg2 pcs_def_age mcs_def_age, name(def_age, replace) title("SOEPs default (SF12 method)", pos(11)) ycommon
grc1leg2 pcs_main_age mcs_main_age, name(main_age, replace) title("Main alternative (Oblique Rotation)", pos(11)) ycommon
grc1leg2 pcs_rmean_age mcs_rmean_age, name(rmean_age, replace) title("Simple average of input variables", pos(11)) ycommon

scatterfit hd_depression_ever pcs_main  if pcs_main>20 & inrange(age,20,75), binned $sfcol opts(name(pcs_main_depre,  replace) title("Main alternative",pos(11)) subtitle("Oblique rotation",pos(11)) ytitle("P(d=depression|pcs_main)")  ) fitm(lpm) fit(quadratic) nquantiles(100)
scatterfit hd_depression_ever mcs_main  if mcs_main>20 & inrange(age,20,75), binned $sfcol opts(name(mcs_main_depre,  replace) title("Main alternative",pos(11)) subtitle("Oblique rotation",pos(11)) ytitle("P(d=depression|mcs_main)")  ) fitm(lpm) fit(quadratic) nquantiles(100)
scatterfit hd_depression_ever pcs_def   if pcs_def>20 & inrange(age,20,75), binned $sfcol opts(name(pcs_def_depre,   replace) title("SOEPs default",pos(11)) subtitle("SF12 method",pos(11)) ytitle("P(d=depression|pcs_def)")  ) fitm(lpm) fit(quadratic) nquantiles(100)
scatterfit hd_depression_ever mcs_def   if mcs_def>20 & inrange(age,20,75), binned $sfcol opts(name(mcs_def_depre,   replace) title("SOEPs default",pos(11)) subtitle("SF12 method",pos(11)) ytitle("P(d=depression|mcs_def)")  ) fitm(lpm) fit(quadratic) nquantiles(100)

graph dis pcs_main_depre
graph dis mcs_main_depre
graph dis pcs_def_depre
graph dis mcs_def_depre



scalar yvar = "hd_blood_pres_ever"
scalar yvar = "hd_depression_ever"

scalar type = "def"
if 1 binsreg `=yvar' pcs_`=type' /* age_sp? */, ci(2 2) name(gr_pcs_`=type'_`=yvar', replace) /* by(traj_Group) */ xtitle("`: var lab pcs_`=type''") ytitle("`: var lab `=yvar''") $graph_opts_validmcspcs nbins(40)
if 1 binsreg `=yvar' mcs_`=type' /* age_sp? */, ci(2 2) name(gr_mcs_`=type'_`=yvar', replace) /* by(traj_Group) */ xtitle("`: var lab mcs_`=type''") ytitle("`: var lab `=yvar''") $graph_opts_validmcspcs nbins(40)
graph combine gr_pcs_`=type'_`=yvar' gr_mcs_`=type'_`=yvar', name(comb_`=type'_`=yvar', replace) ycommon ysize(3) xsize(6)  scale(1.5)
graph export $figures/validatingmcspcs/comb_`=type'_`=yvar'.pdf, replace

scalar type = "main"
if 1  binsreg `=yvar' pcs_`=type' /* age_sp? */, ci(2 2) name(gr_pcs_`=type'_`=yvar', replace) /* by(traj_Group) */ xtitle("`: var lab pcs_`=type''") ytitle("`: var lab `=yvar''") $graph_opts_validmcspcs nbins(40)
if 1  binsreg `=yvar' mcs_`=type' /* age_sp? */, ci(2 2) name(gr_mcs_`=type'_`=yvar', replace) /* by(traj_Group) */ xtitle("`: var lab mcs_`=type''") ytitle("`: var lab `=yvar''") $graph_opts_validmcspcs nbins(40)
graph combine gr_pcs_`=type'_`=yvar' gr_mcs_`=type'_`=yvar', name(comb_`=type'_`=yvar', replace) ycommon ysize(3) xsize(6) scale(1.5)
graph export $figures/validatingmcspcs/comb_`=type'_`=yvar'.pdf, replace

scalar type = "sep"
if 1 binsreg `=yvar' pcs_`=type' /* age_sp? */, ci(2 2) name(gr_pcs_`=type'_`=yvar', replace) /* by(traj_Group) */ xtitle("`: var lab pcs_`=type''") ytitle("`: var lab `=yvar''") $graph_opts_validmcspcs nbins(40)
if 1 binsreg `=yvar' mcs_`=type' /* age_sp? */, ci(2 2) name(gr_mcs_`=type'_`=yvar', replace) /* by(traj_Group) */ xtitle("`: var lab mcs_`=type''") ytitle("`: var lab `=yvar''") $graph_opts_validmcspcs nbins(40)
graph combine gr_pcs_`=type'_`=yvar' gr_mcs_`=type'_`=yvar', name(comb_`=type'_`=yvar', replace) ycommon ysize(3) xsize(6) scale(1.5)
graph export $figures/validatingmcspcs/comb_`=type'_`=yvar'.pdf, replace

scalar type = "rmean"
if 1 binsreg `=yvar' pcs_`=type' /* age_sp? */, ci(2 2) name(gr_pcs_`=type'_`=yvar', replace) /* by(traj_Group) */ xtitle("`: var lab pcs_`=type''") ytitle("`: var lab `=yvar''") $graph_opts_validmcspcs nbins(40)
if 1 binsreg `=yvar' mcs_`=type' /* age_sp? */, ci(2 2) name(gr_mcs_`=type'_`=yvar', replace) /* by(traj_Group) */ xtitle("`: var lab mcs_`=type''") ytitle("`: var lab `=yvar''") $graph_opts_validmcspcs nbins(40)
graph combine gr_pcs_`=type'_`=yvar' gr_mcs_`=type'_`=yvar', name(comb_`=type'_`=yvar', replace) ycommon ysize(3) xsize(6) scale(1.5)
graph export $figures/validatingmcspcs/comb_`=type'_`=yvar'.pdf, replace

graph close _all

graph display comb_def_hd_depression_ever
graph display comb_main_hd_depression_ever
graph display comb_sep_hd_depression_ever
graph display comb_rmean_hd_depression_ever

if 0 {
    scalar type = "obli"
    binslogit `=yvar' pcs_`=type' age_sp?, ci(3 3) name(gr_pcs_`=type'_`=yvar', replace) xtitle("`: var lab pcs_`=type''") ytitle("`: var lab `=yvar''") $graph_opts_validmcspcs
    binslogit `=yvar' mcs_`=type' age_sp?, ci(3 3) name(gr_mcs_`=type'_`=yvar', replace) xtitle("`: var lab mcs_`=type''") ytitle("`: var lab `=yvar''") $graph_opts_validmcspcs
    graph combine gr_pcs_`=type'_`=yvar' gr_mcs_`=type'_`=yvar', name(comb_`=type'_`=yvar', replace) ycommon
    graph export $figures/validatingmcspcs/comb_`=type'_`=yvar'.pdf, replace

    scalar type = "ortho"
    binslogit `=yvar' pcs_`=type' age_sp?, ci(3 3) name(gr_pcs_`=type'_`=yvar', replace) /* by(traj_Group) */ xtitle("`: var lab pcs_`=type''") ytitle("`: var lab `=yvar''") $graph_opts_validmcspcs
    binslogit `=yvar' mcs_`=type' age_sp?, ci(3 3) name(gr_mcs_`=type'_`=yvar', replace) /* by(traj_Group) */ xtitle("`: var lab mcs_`=type''") ytitle("`: var lab `=yvar''") $graph_opts_validmcspcs
    graph combine gr_pcs_`=type'_`=yvar' gr_mcs_`=type'_`=yvar', name(comb_`=type'_`=yvar', replace) ycommon
    graph export $figures/validatingmcspcs/comb_`=type'_`=yvar'.pdf, replace
}



*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# 07_did_gentreattime
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
use $inter/07_did_gentreattime.dta, clear 
egen age_cuts_02 = cut(age), at(0(2)90 110)

local varhealth mcs_main
cap drop touse
gen touse = 1
replace touse = 0 if !inrange(age, 20,70)
replace touse = 0 if !_to_keep_`varhealth'
local varby   age_cuts_02
local vartreat treat_post_`varhealth' // treat_post_`varhealth'
local var gw
statsby mean = r(mean) ub = r(ub) lb = r(lb) if touse, by(`varby' `vartreat') clear: ci means  `var', level(99)
twoway  (rcap  ub lb `varby' if `vartreat'==0 , lc(stc1%66)) (sc mean `varby' if `vartreat'==0, ms(o) mc(stc1) lc(stc1%66)) /// 
        (rcap  ub lb `varby' if `vartreat'==1 , lc(stc2%66)) (sc mean `varby' if `vartreat'==1, ms(t) mc(stc2) lc(stc2%66)) ///
        , name(`var'_`vartreat', replace) scale(1.7) xsize(10) ysize(7) xtitle("Age") ytitle("Gross Wealth, k€, winsored") ///
        leg(off) /// legend(order(2 "Untreated" 4 "Post-Treated")  cols(1) region(fcolor(gs16%80)) pos(4) ring(0) size(3)) 
        ysc(range(0 250)) ylab(0(50)250)

graph export $figures/csdid2/h_descr/wealth_by_age_over_treated_gw.pdf, replace
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

use $inter/07_did_gentreattime.dta, clear 
egen age_cuts_02 = cut(age), at(0(2)90 110)

local varhealth mcs_main
cap drop touse
gen touse = 1
replace touse = 0 if !inrange(age, 20,70)
replace touse = 0 if !_to_keep_`varhealth'
local varby   age_cuts_02
local vartreat treat_post_`varhealth' // treat_post_`varhealth'
local var nw
statsby mean = r(mean) ub = r(ub) lb = r(lb) if touse, by(`varby' `vartreat') clear: ci means  `var', level(99)
twoway  (rcap  ub lb `varby' if `vartreat'==0 , lc(stc1%66)) (sc mean `varby' if `vartreat'==0, ms(o) mc(stc1) lc(stc1%66)) /// 
        (rcap  ub lb `varby' if `vartreat'==1 , lc(stc2%66)) (sc mean `varby' if `vartreat'==1, ms(t) mc(stc2) lc(stc2%66)) ///
        , name(`var'_`vartreat', replace) scale(1.7) xsize(10) ysize(7) xtitle("Age") ytitle("Net Wealth, k€, winsored") ///
        legend(order(2 "Untreated" 4 "Post-Treated")  cols(1) region(fcolor(gs16%80)) pos(4) ring(0) size(3))  ///
        ysc(range(0 250)) ylab(0(50)250)

graph export $figures/csdid2/h_descr/wealth_by_age_over_treated_nw.pdf, replace
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


graph dir

set graph off

ds *migraine_ever *depression_ever
scalar rr = r(varlist)
scalar li rr

scalar xx = cond(regexm("`=rr'", "_()_"),regexs(1),9)
sca li xx

regexm
"_([^_]+)_"

regexs(0) if(regexm(address, "[0-9][0-9][0-9][0-9][0-9]"))


sca drop _all



foreach xvar of varlist mcs_def mcs_obli mcs_ortho mcs_rmean mcs_lrm mcs_sgl mcs_sep {
    foreach yvar of varlist hd_migraine_ever hd_depression_ever hd_sleep_ever hd_dementia_ever hd_other_ever hd_no_illness_ever  {
        if (regexm("`yvar'", "_([^_]+)_")) local scalar_name  "`=regexs(1)'"
        di 120 * "x"
        di as res "model: `yvar' ~ `xvar'"
        logit `yvar' c.`xvar'
        lroc, /* name(lroc_`xvar', replace) */ nograph
        scalar sc_`xvar'_`scalar_name' = r(area)
    }
}

foreach xvar of varlist mcs_def mcs_obli mcs_ortho mcs_rmean mcs_lrm mcs_sgl mcs_sep {
    scalar sc_mean_`xvar' = sum(`=sc_`xvar'_migraine'+`=sc_`xvar'_depression'+`=sc_`xvar'_sleep'+`=sc_`xvar'_dementia'+`=sc_`xvar'_other'+`=sc_`xvar'_no')/6
    sca li sc_mean_`xvar'
}

*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# 
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
foreach xvar of varlist pcs_def pcs_obli pcs_ortho pcs_rmean pcs_lrm pcs_sgl pcs_sep {
    foreach yvar of varlist hd_diabetes_ever hd_cardio_ever hd_stroke_ever hd_joint_ever hd_back_pain_ever   {
        if (regexm("`yvar'", "_([^_]+)_")) local scalar_name  "`=regexs(1)'"
        di 120 * "x"
        di as res "model: `yvar' ~ `xvar'"
        logit `yvar' c.`xvar'
        lroc, /* name(lroc_`xvar', replace) */ nograph
        scalar sc_`xvar'_`scalar_name' = r(area)
    }
}

foreach xvar of varlist pcs_def pcs_obli pcs_ortho pcs_rmean pcs_lrm pcs_sgl pcs_sep {
    scalar sc_mean_`xvar' = sum(`=sc_`xvar'_diabetes'+`=sc_`xvar'_cardio'+`=sc_`xvar'_stroke'+`=sc_`xvar'_joint'+`=sc_`xvar'_back')/5
    sca li sc_mean_`xvar'
}


scalar list

hd_diabetes_ever hd_cardio_ever hd_stroke_ever hd_joint_ever hd_back_pain_ever


qhist ?cs_main, name(cs_main, replace) xsize(8) ysize(4) note(\`varlist')
qhist ?cs_def, name(cs_def, replace) xsize(8) ysize(4) note(\`varlist')
qhist ?cs_ortho, name(cs_ortho, replace) xsize(8) ysize(4) note(\`varlist')
qhist ?cs_obli, name(cs_obli, replace) xsize(8) ysize(4) note(\`varlist')

qhist ?cs_rmean, name(cs_rmean, replace) xsize(8) ysize(4) note(\`varlist')
qhist ?cs_mst, name(cs_mst, replace) xsize(8) ysize(4) note(\`varlist')

qhist ?cs_lrm, name(cs_mst, replace) xsize(8) ysize(4) note(\`varlist')

graph combine cs_main cs_def cs_ortho cs_obli cs_rmean cs_mst, ycommon xsize(20)  ysize(7)

revert ?cs_rmean
gen mcs_lrm = log(mcs_rmean)
gen pcs_lrm = log(pcs_rmean)
revert mcs_lrm pcs_lrm
revert ?cs_rmean


cor ?cs_main  ?cs_def  ?cs_ortho  ?cs_obli  ?cs_rmean  ?cs_mst

graph close _all
graph dis    gc_gr_mcs_rmean_depression
graph dis    gc_gr_mcs_def_depression
graph dis    gc_gr_mcs_main_depression

graph dis    gc_gr_mcs_sep_depression
graph dis    gr_pcs_sgl_depression


binslogit hd_depression_ever pcs_`=type' mcs_`=type' age_sp?, ci(3 3) name(gr_pcs_`=type'_depression_ctrl, replace) /* by(traj_Group) */ ytitle("`: var lab hd_depression_ever'") $graph_opts_validmcspcs
binslogit hd_depression_ever pcs_`=type' mcs_`=type' age_sp?, ci(3 3) name(gr_pcs_`=type'_depression_ctrl, replace) /* by(traj_Group) */ ytitle("`: var lab hd_depression_ever'") $graph_opts_validmcspcs
binslogit hd_depression_ever mcs_`=type' pcs_`=type' age_sp?, ci(3 3) name(gr_mcs_`=type'_depression_ctrl, replace) /* by(traj_Group) */ ytitle("`: var lab hd_depression_ever'") $graph_opts_validmcspcs


binslogit hd_depression_ever pcs_`=type' mcs_`=type' age_sp?, ci(3 3) name(gr_pcs_`=type'_depression_ctrl, replace) /* by(traj_Group) */ ytitle("`: var lab hd_depression_ever'") $graph_opts_validmcspcs
binslogit hd_depression_ever mcs_`=type' pcs_`=type' age_sp?, ci(3 3) name(gr_mcs_`=type'_depression_ctrl, replace) /* by(traj_Group) */ ytitle("`: var lab hd_depression_ever'") $graph_opts_validmcspcs
if 0 graph export $figures/validatingmcspcs/fig_binslog_depression_mcs_`=type'_bytraj.pdf, replace

binslogit hd_migraine_ever mcs_`=type' age_sp?, ci(3 3) name(gr_mcs_`=type'_migraine, replace) by(traj_Group) ytitle("`: var lab hd_migraine_ever'") $graph_opts_validmcspcs
if 0 graph export $figures/validatingmcspcs/fig_binslog_migraine_mcs_`=type'_bytraj.pdf, replace

binslogit hd_depression_ever mcs_`=type'_sd age_sp?, ci(3 3) name(gr_mcs_`=type'_sd_depression, replace) by(traj_Group) ytitle("`: var lab hd_depression_ever'") $graph_opts_validmcspcs
if 0 graph export $figures/validatingmcspcs/fig_binslog_depression_mcs_`=type'_sd_bytraj.pdf, replace

binslogit hd_migraine_ever mcs_`=type'_sd age_sp?, ci(3 3) name(gr_mcs_`=type'_sd_migraine, replace) by(traj_Group) ytitle("`: var lab hd_migraine_ever'") $graph_opts_validmcspcs
if 0 graph export $figures/validatingmcspcs/fig_binslog_migraine_mcs_`=type'_sd_bytraj.pdf, replace



**# pcs
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
if 0 {
    foreach var of varlist hd_*_ever {
        di "var: `var'"
        binslogit `var' pcs_main age_sp?, ci(3 3) name(gr_pcs_`var', replace) by(traj_Group) $graph_opts_validmcspcs
    }
}

binslogit hd_cardio_ever mcs_`=type' age_sp?, ci(3 3) name(gr_mcs_`=type'_cardio, replace) by(traj_Group) ytitle("`: var lab hd_cardio_ever'") $graph_opts_validmcspcs
binslogit hd_cardio_ever pcs_`=type' age_sp?, ci(3 3) name(gr_pcs_`=type'_cardio, replace) by(traj_Group) ytitle("`: var lab hd_cardio_ever'") $graph_opts_validmcspcs

binslogit hd_cardio_ever mcs_`=type' pcs_`=type' age_sp?, ci(3 3) name(gr_mcs_`=type'_cardio_ctrl, replace) by(traj_Group) ytitle("`: var lab hd_cardio_ever'") $graph_opts_validmcspcs
binslogit hd_cardio_ever pcs_`=type' mcs_`=type' age_sp?, ci(3 3) name(gr_pcs_`=type'_cardio_ctrl, replace) by(traj_Group) ytitle("`: var lab hd_cardio_ever'") $graph_opts_validmcspcs

if 0 graph export $figures/validatingmcspcs/fig_binslog_cardio_pcs_`=type'_bytraj.pdf, replace

binslogit hd_asthma_ever mcs_`=type' age_sp?, ci(3 3) name(gr_mcs_`=type'_asthma, replace) by(traj_Group) ytitle("`: var lab hd_asthma_ever'") $graph_opts_validmcspcs
binslogit hd_asthma_ever pcs_`=type' age_sp?, ci(3 3) name(gr_pcs_`=type'_asthma, replace) by(traj_Group) ytitle("`: var lab hd_asthma_ever'") $graph_opts_validmcspcs
if 0 graph export $figures/validatingmcspcs/fig_binslog_asthma_pcs_`=type'_bytraj.pdf, replace

binslogit hd_cardio_ever mcs_`=type'_sd age_sp?, ci(3 3) name(gr_mcs_`=type'_sd_cardio, replace) by(traj_Group) ytitle("`: var lab hd_cardio_ever'") $graph_opts_validmcspcs
binslogit hd_cardio_ever pcs_`=type'_sd age_sp?, ci(3 3) name(gr_pcs_`=type'_sd_cardio, replace) by(traj_Group) ytitle("`: var lab hd_cardio_ever'") $graph_opts_validmcspcs
if 0 graph export $figures/validatingmcspcs/fig_binslog_cardio_pcs_`=type'_sd_bytraj.pdf, replace

binslogit hd_asthma_ever mcs_`=type'_sd age_sp?, ci(3 3) name(gr_mcs_`=type'_sd_asthma, replace) by(traj_Group) ytitle("`: var lab hd_asthma_ever'") $graph_opts_validmcspcs
binslogit hd_asthma_ever pcs_`=type'_sd age_sp?, ci(3 3) name(gr_pcs_`=type'_sd_asthma, replace) by(traj_Group) ytitle("`: var lab hd_asthma_ever'") $graph_opts_validmcspcs
if 0 graph export $figures/validatingmcspcs/fig_binslog_asthma_pcs_`=type'_sd_bytraj.pdf, replace

foreach var of varlist hd_*_ever {
    di "var: `var'"
    binslogit `var' mcs_main_sd age age2, ci(3 3) name(gr_mcs_sd_`var', replace)
}

foreach var of varlist hd_*_ever {
    di "var: `var'"
    binslogit `var' pcs_main_sd age age2, ci(3 3) name(gr_pcs_sd_`var', replace)
}


graph drop _all
binslogit hd_depression_ever mcs_main age age2 i.gw_qile, ci(3 3) name(gr_mcs_`var', replace) by(gw_qile)
logit hd_depression_ever mcs_main mcs_main_sd age age2 i.nw_groups, or


tabstat hd_depression_ever , by(nw_qile)

binslogit hd_depression_ever mcs_mst age, ci(3 3) name(gr_mcs_`var'_1, replace) by(nw_qile)
binslogit hd_depression_ever pcs_mst age i.age_group, ci(3 3) name(gr_mcs_`var'_1, replace) by(nw_qile)
binslogit hd_depression_ever mcs_main age, ci(3 3) name(gr_mcs_`var'_2, replace)
binslogit hd_depression_ever mcs_main age, ci(3 3) name(gr_mcs_`var'_3, replace)

drop if sex==-3

graph drop _all
binslogit hd_depression_ever mcs_mst age , name(gr_mcs_`var'_3, replace) by(sex) ci(3 3)
binslogit hd_depression_ever mcs_main age , name(gr_mcs_`var'_33, replace) by(sex) ci(3 3)
binslogit hd_depression_ever mcs_main age if age_group==17, name(gr_mcs_`var'_1, replace) by(gw_groups) ci( 3 3 )
binslogit hd_depression_ever mcs_main age if age_group==35, name(gr_mcs_`var'_2, replace) by(gw_groups) ci( 3 3 )
binslogit hd_depression_ever mcs_main age if age_group==45, name(gr_mcs_`var'_3, replace) by(gw_groups) ci( 3 3 )
binslogit hd_depression_ever mcs_main age if age_group==55, name(gr_mcs_`var'_4, replace) by(gw_groups) ci( 3 3 )
binslogit hd_depression_ever mcs_main age if age_group==65, name(gr_mcs_`var'_5, replace) by(gw_groups) ci( 3 3 )

binsreg expft mcs_main_sd pcs_main age_sp?, by(traj_Group) ci(3 3)
binsreg expft mcs_main_sd pcs_main age_sp?, by(traj_Group) ci(3 3)

binsreg expft mcs_main pcs_main age_sp?, by(traj_Group) ci(3 3)
binsreg expft mcs_main pcs_main age_sp?, by(traj_Group) ci(3 3)

binsreg exppt mcs_main /* pcs_main */ age_sp?, by(traj_Group) ci(3 3)
binsreg exppt mcs_main /* pcs_main */ age_sp?, by(traj_Group) ci(3 3)

binsreg expue mcs_main pcs_main age_sp?, by(traj_Group) ci(3 3)
binsreg expue mcs_main pcs_main age_sp?, by(traj_Group) ci(3 3)

binsreg hhinc_pre_log pcs_main mcs_main  age_sp?, by(traj_Group) ci(3 3)
binsreg hhinc_pre_log pcs_main mcs_main  age_sp?, by(traj_Group) ci(3 3)

binsreg hhinc_pre_log pcs_main_sd mcs_main  age_sp?, by(traj_Group) ci(3 3)
binsreg hhinc_pre_log pcs_main_sd mcs_main  age_sp?, by(traj_Group) ci(3 3)

binslogit hd_depression_ever mcs_main age if age_group==65, name(gr_mcs_`var'_5, replace) by(traj_Group) ci( 3 3 ) cb(3 3)

tabstat mcs_main pcs_main mcs_mst pcs_mst, by(traj_Group ) stat(mean sd med p1 p5 p10 p25 p50 p75 p90 p95 p99 n min max)


graph drop _all
scalar controls = "i.marital_status i.legal_handicapped_bin children i.insurance_type educ_years_sp?"

cls
reg expft_norm /* ?cs_main ?cs_main_sd */   age_sp? i.sex educ_years_sp? `=controls'
reg expft_norm ?cs_main ?cs_main_sd   age_sp? i.sex educ_years_sp? `=controls'
reg exppt ?cs_main ?cs_main_sd   age_sp? i.sex educ_years_sp?
reg expue ?cs_main ?cs_main_sd   age_sp? i.sex educ_years_sp?


**# main
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

binsreg hosp_stay_nights mcs_main  age_sp?, by(traj_Group) ci( 3 3 ) name(by_traj_Group_mcs, replace) $graph_opts_validmcspcs
graph export $figures/validatingmcspcs/fig_binslog_hosp_stay_nights_traj_Group_mcs.pdf, replace
binsreg hosp_stay_nights pcs_main  age_sp?, by(traj_Group) ci( 3 3 ) name(by_traj_Group_pcs, replace) $graph_opts_validmcspcs
graph export $figures/validatingmcspcs/fig_binslog_hosp_stay_nights_traj_Group_pcs.pdf, replace

**# sd
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
binsreg hosp_stay_nights mcs_main_sd  age_sp?, by(traj_Group) ci( 3 3 ) name(by_traj_Group_mcs_sd, replace) $graph_opts_validmcspcs
graph export $figures/validatingmcspcs/fig_binslog_hosp_stay_nights_by_j_Group_mcs_sd.pdf, replace
binsreg hosp_stay_nights pcs_main_sd  age_sp?, by(traj_Group) ci( 3 3 ) name(by_traj_Group_pcs_sd, replace) $graph_opts_validmcspcs
graph export $figures/validatingmcspcs/fig_binslog_hosp_stay_nights_by_j_Group_pcs_sd.pdf, replace


**# main
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
binsreg days_off_sick_prev_year mcs_main  age_sp?, by(traj_Group) ci( 3 3 ) name(by_traj_Group_mcs, replace) $graph_opts_validmcspcs
graph export $figures/validatingmcspcs/fig_binslog_days_off_sick_prev_year_traj_Group_mcs.pdf, replace
binsreg days_off_sick_prev_year pcs_main  age_sp?, by(traj_Group) ci( 3 3 ) name(by_traj_Group_pcs, replace) $graph_opts_validmcspcs
graph export $figures/validatingmcspcs/fig_binslog_days_off_sick_prev_year_traj_Group_pcs.pdf, replace

**# sd
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
binsreg days_off_sick_prev_year mcs_main_sd  age_sp?, by(traj_Group) ci( 3 3 ) name(by_traj_Group_mcs_sd, replace) $graph_opts_validmcspcs
graph export $figures/validatingmcspcs/fig_binslog_days_off_sick_prev_year_by_j_Group_mcs_sd.pdf, replace
binsreg days_off_sick_prev_year pcs_main_sd  age_sp?, by(traj_Group) ci( 3 3 ) name(by_traj_Group_pcs_sd, replace) $graph_opts_validmcspcs
graph export $figures/validatingmcspcs/fig_binslog_days_off_sick_prev_year_by_j_Group_pcs_sd.pdf, replace






/* difference between using trajgroup and wealth quantiles */
replace age_cuts_10= 20 if age_cuts_10 == 10

cap drop nw_pile_age
gquantiles nw_pile_age = nw_for_tiling, xtile nquantiles(100) by(age_cuts_10)
recode nw_pile_age (1/20 = 1) (21/45 = 2) (46/95 = 3) (96/100 = 4), gen(nw_groups_age)
lab var gw_groups "Net Wealth Interquartile Group over age"



graph drop _all


binsreg expft  pcs_main age_sp?, by(traj_Group )  $graph_opts_validmcspcs ci(2 2) name(pcs_main, replace)
binsreg expft  mcs_main age_sp?, by(traj_Group )  $graph_opts_validmcspcs ci(2 2) name(mcs_main, replace)

binsreg expft  pcs_main_sd age_sp?, by(traj_Group )  $graph_opts_validmcspcs ci(2 2) name(pcs_main_sd, replace)
binsreg expft  mcs_main_sd age_sp?, by(traj_Group )  $graph_opts_validmcspcs ci(2 2) name(mcs_main_sd, replace)




*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# SEM
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

use $inter/health_factor_scores.dta, replace
merge 1:1 pid syear using $inter/03_clean_lr_even_years.dta, gen(_mg_test)

qui sem ( P1 -> pf1 pf2 rp1 rp2 bp gh )  ///
    ( P2 -> re1 re2 sf mh1 mh2 ), /* var(P1*P2@0) */

estat gof, stats(all)
cap drop p1 p2 
predict p1 p2, latent 


qui sem ( P1 -> pf1 pf2 rp1 rp2 bp gh re1 re2 sf mh1 mh2 )  ///
    ( P2 -> pf1 pf2 rp1 rp2 bp re1 re2 sf mh1 mh2 ), var(P1*P2@0)

estat gof, stats(all)
cap drop p21 p22 
predict p21 p22, latent 

cor ?cs_main  p1 p2
cor ?cs_def  p1 p2
cor ?cs_sep  p1 p2

qhist ?cs_sep p1 p2

foreach xvar of varlist /* pcs_def pcs_obli pcs_ortho pcs_rmean pcs_lrm pcs_sgl */ pcs_sep p1 p2 p0 {
    foreach yvar of varlist hd_diabetes_ever hd_cardio_ever hd_stroke_ever hd_joint_ever hd_back_pain_ever   {
        if (regexm("`yvar'", "_([^_]+)_")) local scalar_name  "`=regexs(1)'"
        di 120 * "x"
        di as res "model: `yvar' ~ `xvar'"
        qui logit `yvar' c.`xvar'
        lroc, /* name(lroc_`xvar', replace) */ nograph
        scalar sc_`xvar'_`scalar_name' = r(area)
    }
}

foreach xvar of varlist pcs_def pcs_obli pcs_ortho pcs_rmean /* pcs_lrm */ pcs_sgl pcs_sep p1 p2 p0 {
    scalar sc_mean_`xvar' = sum(`=sc_`xvar'_diabetes'+`=sc_`xvar'_cardio'+`=sc_`xvar'_stroke'+`=sc_`xvar'_joint'+`=sc_`xvar'_back')/5
    sca li sc_mean_`xvar'
}


foreach xvar of varlist /* mcs_def mcs_obli mcs_ortho mcs_rmean  mcs_lrm mcs_sgl */ mcs_sep p2 p1 p0 {
    foreach yvar of varlist hd_migraine_ever hd_depression_ever hd_sleep_ever hd_dementia_ever  {
        di "yvar: `yvar'"
        if (regexm("`yvar'", "_([^_]+)_")) local scalar_name  "`=regexs(1)'"
        di 120 * "x" " `scalar_name'"
        di as res "model: `yvar' ~ `xvar'"
        qui logit `yvar' c.`xvar'
        lroc, /* name(lroc_`xvar', replace) */ nograph
        scalar sc_`xvar'_`scalar_name' = r(area)
    }
}

foreach xvar of varlist mcs_def mcs_obli mcs_ortho mcs_rmean /* mcs_lrm */ /* mcs_sgl */ mcs_sep p1 p2 p0 {
    scalar sc_mean_`xvar' = sum(`=sc_`xvar'_migraine'+`=sc_`xvar'_depression'+`=sc_`xvar'_sleep'/* +`=sc_`xvar'_dementia' */)/3
    sca li sc_mean_`xvar'
}
foreach xvar of varlist pcs_def pcs_obli pcs_ortho pcs_rmean /* pcs_lrm */ pcs_sgl pcs_sep p1 p2 p0 {
    scalar sc_mean_`xvar' = sum(`=sc_`xvar'_diabetes'+`=sc_`xvar'_cardio'+`=sc_`xvar'_stroke'+`=sc_`xvar'_joint'+`=sc_`xvar'_back')/5
    sca li sc_mean_`xvar'
}




binslogit hd_cardio_ever p1 age_sp?, ci(3 3) name(gr_p1_`=type'_cardio, replace) ytitle("`: var lab hd_cardio_ever'") $graph_opts_validmcspcs
binslogit hd_cardio_ever p2 age_sp?, ci(3 3) name(gr_p2_`=type'_cardio, replace) ytitle("`: var lab hd_cardio_ever'") $graph_opts_validmcspcs
binslogit hd_cardio_ever p1 p2 age_sp?, ci(3 3) name(gr_p1p2_`=type'_cardio, replace) ytitle("`: var lab hd_cardio_ever'") $graph_opts_validmcspcs

binslogit hd_depression_ever p1 age_sp?, ci(3 3) name(gr_p1_`=type'_depress, replace) ytitle("`: var lab hd_depression_ever'") $graph_opts_validmcspcs
binslogit hd_depression_ever p2 age_sp?, ci(3 3) name(gr_p2_`=type'_depress, replace) ytitle("`: var lab hd_depression_ever'") $graph_opts_validmcspcs
binslogit hd_depression_ever p0 age_sp?, ci(3 3) name(gr_p0_`=type'_depress, replace) ytitle("`: var lab hd_depression_ever'") $graph_opts_validmcspcs

binslogit hd_depression_ever p1 , ci(3 3) name(gr_p1_noage_depress, replace) ytitle("`: var lab hd_depression_ever'") $graph_opts_validmcspcs
binslogit hd_depression_ever p2 , ci(3 3) name(gr_p2_noage_depress, replace) ytitle("`: var lab hd_depression_ever'") $graph_opts_validmcspcs
binslogit hd_depression_ever p0 , ci(3 3) name(gr_p0_noage_depress, replace) ytitle("`: var lab hd_depression_ever'") $graph_opts_validmcspcs



binslogit hd_cardio_ever pcs_3fct age_sp?, ci(3 3) name(gr_3fct_pcs_cardio, replace) ytitle("`: var lab hd_cardio_ever'") $graph_opts_validmcspcs
binslogit hd_cardio_ever ecs_3fct age_sp?, ci(3 3) name(gr_3fct_ecs_cardio, replace) ytitle("`: var lab hd_cardio_ever'") $graph_opts_validmcspcs
binslogit hd_cardio_ever mcs_3fct age_sp?, ci(3 3) name(gr_3fct_mcs_cardio, replace) ytitle("`: var lab hd_cardio_ever'") $graph_opts_validmcspcs

binslogit hd_cardio_ever pcs_def age_sp?, ci(3 3) name(gr_pcs_def_`=type'_cardio, replace) ytitle("`: var lab hd_cardio_ever'") $graph_opts_validmcspcs
binslogit hd_cardio_ever mcs_def age_sp?, ci(3 3) name(gr_mcs_def_`=type'_cardio, replace) ytitle("`: var lab hd_cardio_ever'") $graph_opts_validmcspcs


binslogit hd_depression_ever pcs_3fct age_sp?, ci(3 3) name(gr_3fct_pcs_depression, replace) ytitle("`: var lab hd_depression_ever'") $graph_opts_validmcspcs
binslogit hd_depression_ever ecs_3fct age_sp?, ci(3 3) name(gr_3fct_ecs_depression, replace) ytitle("`: var lab hd_depression_ever'") $graph_opts_validmcspcs
binslogit hd_depression_ever mcs_3fct age_sp?, ci(3 3) name(gr_3fct_mcs_depression, replace) ytitle("`: var lab hd_depression_ever'") $graph_opts_validmcspcs
graph combine gr_3fct_pcs_depression gr_3fct_ecs_depression gr_3fct_mcs_depression, name(gc_3fct, replace)


binslogit hd_depression_ever pcs_def age_sp?, ci(3 3) name(gr_pcs_def_pcs_def_depression, replace) ytitle("`: var lab hd_depression_ever'") $graph_opts_validmcspcs
binslogit hd_depression_ever mcs_def age_sp?, ci(3 3) name(gr_mcs_def_mcs_def_depression, replace) ytitle("`: var lab hd_depression_ever'") $graph_opts_validmcspcs
graph combine gr_pcs_def_pcs_def_depression gr_mcs_def_mcs_def_depression, name(gc_def, replace)

binslogit hd_depression_ever pcs_main age_sp?, ci(3 3) name(gr_pcs_main_depression, replace) ytitle("`: var lab hd_depression_ever'") $graph_opts_validmcspcs
binslogit hd_depression_ever mcs_main age_sp?, ci(3 3) name(gr_mcs_main_depression, replace) ytitle("`: var lab hd_depression_ever'") $graph_opts_validmcspcs






*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
log close  
cp $log/tmp/06_validate_mcspcs.log $log/, replace


exit




















