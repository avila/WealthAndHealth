*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*** MA: The health-wealth nexus over the life cycle
*** Au: Marcelo Rainho Avila (4679876)
*** Dt: 07.02.2024
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//
//  Generate physical and mental health scores from factors of normalized health related variables 
//
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


cap log close _all
log using $log/tmp/01_c_health_factoring.log, text replace



*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# 01 - Prepare
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

use pid syear ple0004 ple0005 ple0008 ple0026-ple0035 ple0040 ple0041 ple0044_h ple0046 ple0048 ple0049 ple0050 ple0051 ple0072 ple0073 ple0081_h plh0171 if syear>=2002 using $soep_data/pl.dta, clear
mvdecode pl*, mv(-1 = .a \ -2 = .b \ -3 = .c \ -4 = .d \ -5 = .e \ -6 = .f \ -7 = .g \ -8 = .h) 

*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# rename
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

rename_relabel ple0008   gh  // ple0008 // <- revert!!      general health    : Current Health                               orig. lab: very good [1] -> bad [5] 
rename_relabel ple0004   pf1 // ple0004 //                  physical func     : State Of Health Affects Ascending Stairs     orig. lab: stark [1] -> gar nicht [3]
rename_relabel ple0005   pf2 // ple0005 //                  physical func     : State Of Health Affects Tiring Tasks         orig. lab: stark [1] -> gar nicht [3]
rename_relabel ple0026   st  // ple0026 //                  stress (not inc.) : Pressed For Time Last 4 Weeks                orig. lab: always [1] -> never [5]
rename_relabel ple0027   mh1 // ple0027 //                  mental            : Run-down, Melancholy Last 4 Weeks            orig. lab: always [1] -> never [5]
rename_relabel ple0028   mh2 // ple0028 // <- revert!!      mental            : Well-balanced Last 4 Weeks                   orig. lab: always [1] -> never [5]
rename_relabel ple0029   vt  // ple0029 // <- revert!!      vitality          : Used Energy Last 4 Weeks                     orig. lab: always [1] -> never [5]
rename_relabel ple0030   bp  // ple0030 //                  bodily pain       : Physical pain last four weeks                orig. lab: always [1] -> never [5]
rename_relabel ple0031   rp1 // ple0031 //                  role physical     : Accomplished Less Due To Physical Problems   orig. lab: always [1] -> never [5]
rename_relabel ple0032   rp2 // ple0032 //                  role physical     : Limitations Due To Physical Problems         orig. lab: always [1] -> never [5]
rename_relabel ple0033   re1 // ple0033 //                  emotional         : Accomplished Less Due To Emotional Problems  orig. lab: always [1] -> never [5]
rename_relabel ple0034   re2 // ple0034 //                  emotional         : Less Careful Due To Emotional Problems       orig. lab: always [1] -> never [5]
rename_relabel ple0035   sf  // ple0035 //                  social func       : Limited Socially Due To Health               orig. lab: always [1] -> never [5]

/* 
ple0008   gh  Q: How would you describe your current health?
ple0004   pf1 Q: When you have to climb several flights of stairs on foot, does your health limit you greatly, somewhat, or not at all?
ple0005   pf2 Q: And what about other demanding everyday activities, such as when youhave to lift something heavy or
    do something requiring physical mobility: Does your health limit you greatly, somewhat, or not at all?
ple0026   st  Q: feel rushed or pressed for time?
ple0027   mh1 Q: feel down and gloomy?
ple0028   mh2 Q: feel calm and relaxed?
ple0029   vt  Q: feel energetic?
ple0030   bp  Q: have severe physical pain?
ple0031   rp1 Q: feel that due to physical health problems you achieved less than you wanted to at work or in
    everyday activities?
ple0032   rp2 Q: feel that due to physical health problems you were limited in some way at work or in everyday
    activities?
ple0033   re1 Q: feel that due to mental health or emotional problems you achieved less than you wanted to at work or
    in everyday activities?
ple0034   re2 Q: feel that due to mental health or emotional problems you carried out your work or everyday tasks
    less thoroughly than usual?
ple0035   sf  Q: feel that due to physical or mental health problems you were limited socially, that is, in contact
    with friends, acquaintances, or relatives? */

save $inter/plhealth.dta, replace

*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# normalize
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

if 0 use $inter/plhealth.dta, clear

lab language EN
lab li  ple0008 ple0004 ple0005 ple0026 ple0027 ple0028 ple0029 ple0030 ple0031 ple0032 ple0033 ple0034 ple0035

/* revert so variables are from bad -> good */
revert gh mh2 vt

lab def lkrt3bg 1 "negative" 2 "." 3 "positive"
lab def lkrt5bg 1 "negative" 2 "." 3 "." 4 "." 5 "positive"
lab val pf1 pf2    lkrt3bg
lab val gh st mh1 mh2 vt bp rp1 rp2 re1 re2 sf    lkrt5bg

fre gh pf1 pf2 bp rp1 rp2 st mh1 mh2 vt  re1 re2 sf
sum gh pf1 pf2 bp rp1 rp2 st mh1 mh2 vt  re1 re2 sf

scalar phys = "gh pf1 pf2 bp rp1 rp2"
scalar ment = "st mh1 mh2 vt re1 re2 sf"

lab var bp "Physical pain Last 4 weeks"

if "`=doplot'"=="1" {
    *** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    **# graph frequencies of input variables
    *** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    scalar y_axis = `"ylab(#10) yscale(range(0 60)) ytitle("")"'
    scalar opt_ti = "justification(left) bexpand"
    scalar opt_ti = `"\`var': `: variable label `var''", `=opt_ti'"'

    local i = 1
    foreach var of varlist `=ment' {
        di "`i++': `var'.  `:  variable label `var''" // title("`var': `: variable label `var''", `=opt_ti') <- title of plot
        graph bar, over(`var') name(gm_`var', replace) /* nodraw */ title("") `=y_axis' scale(3)
        graph export $figures/descriptives/fig_ment_`var'.pdf, replace
    }

    local i = 1
    foreach var of varlist `=phys' {
        *di "`i++': `var'.  `:  variable label `var''"
        graph bar, over(`var') name(gp_`var', replace) /* nodraw */ title("") `=y_axis'  scale(3)
        graph export $figures/descriptives/fig_phys_`var'.pdf, replace  
    }
    
    graph combine gp_gh gp_pf1 gp_pf2 gp_bp gp_rp1 gp_rp2, name(graphs_combined_physical, replace) ycommon scale(.7)
    //graph export $figures/descriptives/fig_combined_physical.pdf, replace
    graph combine /* gm_st */ gm_mh1 gm_mh2 gm_vt gm_re1 gm_re2 gm_sf, name(graphs_combined_mental, replace) ycommon scale(.7)
    //graph export $figures/descriptives/fig_combined_mental.pdf, replace

    graph close gp* gm*
}



*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# demeaning
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

foreach var of varlist gh pf1 pf2 st mh1 mh2 vt bp rp1 rp2 re1 re2 sf {
    egen `var'_mean = mean(`var')
    gen `var'_0 = `var' - `var'_mean
    replace `var'_0 = `var' if mi(`var') & mi(`var'_0)
    drop `var'_mean 
}

save `c(tmpdir)'/xxxxx.dta, replace

*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# fill missing with corresponding var of same concept
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
use `c(tmpdir)'/xxxxx.dta, clear

order pid syear gh pf1 pf2 bp rp1 rp2 st mh1 mh2 vt re1 re2 sf
cls
local varpref pf rp mh re
foreach var of local varpref {
    di "Var: `var' " 120*"."
    /* assert same categories in v1 and v2 of same concept */
    egen x1_max = max(`var'1) 
    egen x2_max = max(`var'2)
    egen x1_min = min(`var'1)
    egen x2_min = min(`var'2)
    assert x1_min==x2_min
    assert x1_max==x2_max
    drop x?_???
    fre `var'2
    fre `var'2 if mi(`var'1) & !mi(`var'2)
    fre `var'1
    fre `var'1 if mi(`var'2) & !mi(`var'1)
    replace `var'1 = `var'2 if mi(`var'1) & !mi(`var'2)
    replace `var'2 = `var'1 if mi(`var'2) & !mi(`var'1)
}

/* in the default sf12 method (at least in soeps procedure), the means of same sub-scale are computed first, and factors
   extracted from these variables istead of using each individual variable in the factor model */
egen pf = rowmean(pf1 pf2)
egen rp = rowmean(rp1 rp2)
egen mh = rowmean(mh1 mh2)
egen re = rowmean(re1 re2)

*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# std
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

/* physical */
foreach var of varlist gh pf1 pf2 bp rp1 rp2 pf rp {
    cap drop `var'_p
    egen `var'_p = std(`var'), mean(0) sd(1)
    replace `var'_p = `var' if mi(`var') & mi(`var'_p)
}

/* mental */
foreach var of varlist st mh1 mh2 vt re1 re2 sf mh re  {
    cap drop `var'_m
    egen `var'_m = std(`var'), mean(0) sd(1)
    replace `var'_m = `var' if mi(`var') & mi(`var'_m)
}


*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# relabel
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

lab var pf_p "Physical Function"
lab var gh_p "General Health"
lab var bp_p "Bodily Pain"
lab var rp_p "Role Physical"
lab var mh_m "Mental Health"
lab var re_m "Role Emotional"
lab var sf_m "Social Function"
lab var vt_m "Vitality"
lab var st_m "Stress"

lab var pf1_p "Physical Function 1"
lab var pf2_p "Physical Function 2"

lab var rp1_p "Role Physical 1"
lab var rp2_p "Role Physical 2"

lab var mh1_m "Mental Health 1"
lab var mh2_m "Mental Health 2"

lab var re1_m "Role Emotional 1"
lab var re2_m "Role Emotional 2"


*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# check missings and save inter data
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
missings report if mod(syear,2)==0

drop pf rp mh re
order pid syear gh pf1 pf2 bp rp1 rp2 st mh1 mh2 vt re1 re2 sf ??*_p ??*_m ???_p ???_m
desc
sum 

reg pid gh pf1 pf2 bp rp1 rp2 st mh1 mh2 vt re1 re2
keep if e(sample)==1 /* drop if missing some of above variables */
save $inter/01_health_factor.dta, replace

*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# 02 - Generate Scores
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**# options
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

set seed          42
set graph         on // off/on
scalar doplot    = 1 
scalar promax     = 1.6
scalar method     = "reg"  
/* help rotate: Larger promax powers simplify the loadings (generate numbers closer to zero and one)
but at the cost of additional correlation between factors. */

scalar blank_th         = .333
//scalar fplotopt       = "aspect(1) yline(0) xline(0) xlab(0(.2)1) ylab(0(.2)1) ysize(7) xsize(7) xtitle(Factor 1 (physical health)) ytitle(Factor 2 (mental health))"
scalar fplotopt         = "aspect(1) yline(0) xline(0) xlab(-0.2(.2)1) ylab(-0.1(.2)1) ysize(5) xsize(5) xtitle(Factor 1 (physical health)) ytitle(Factor 2 (mental health))"
scalar fplotopt_norot   = "aspect(1) yline(0) xline(0) xlab(-0.2(.2)1) ylab(-0.4(.2)1) ysize(5) xsize(5) xtitle(Factor 1 (physical health)) ytitle(Factor 2 (mental health))"
scalar fplotopt         = "aspect(1) yline(0) xline(0) xlab(-0.2(.2)1) ylab(-0.1(.2)1) ysize(5) xsize(5) xtitle(Factor 1 (physical health)) ytitle(Factor 2 (mental health))"
scalar fplotopt_pdf     = `"aspect(1) yline(0) xline(0) xlab(-0.1(.2)1) ylab(-0.1(.2)1) ysize(5) xsize(5) xtitle(Factor 1 (physical health)) ytitle(Factor 2 (mental health)) title("") note("") scale(1.5)"' 

global phys_simple      gh_p pf_p bp_p rp_p /* used in soep default */
global ment_simple      mh_m vt_m re_m sf_m /* used in soep default */
global ment_simnov      mh_m      re_m sf_m

global phys_unique      gh_p pf1_p pf2_p bp_p rp1_p rp2_p
global ment_unique      mh1_m mh2_m vt_m re1_m re2_m sf_m
global ment_uninov      mh1_m mh2_m      re1_m re2_m sf_m

if 1 use $inter/01_health_factor.dta, clear

*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# single components
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

* Physical Health (separate factors)
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
factor $phys_unique,      factors(1) blank(`=blank_th') pcf
rotate, varimax blank(`=blank_th')
if "`=doplot'"=="1" screeplot
cap drop pcs_sep
predict double pcs_sep, `=method'
lab var pcs_sep "Physical Health (separate factors)"

* Mental Health (separate factors)
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
factor $ment_unique,      factors(1) blank(`=blank_th') pcf
rotate, varimax blank(`=blank_th') 
if "`=doplot'"=="1" screeplot
cap drop mcs_sep
predict double mcs_sep,  `=method'
lab var mcs_sep "Mental Health (separate factors)"

corr  pcs_sep mcs_sep

qui reg $phys_unique $ment_unique
gen n_sep = e(sample)

*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# Simple row average
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

cap drop pcs_rmean
egen pcs_rmean = rowmean($phys_unique)
cap drop mcs_rmean
egen mcs_rmean = rowmean($ment_unique)
corr pcs_rmean mcs_rmean

lab var pcs_rmean "Physical Health (simple average)"
lab var mcs_rmean "Mental Health (simple average)"

corr  pcs_rmean $phys_unique
corr  mcs_rmean $phys_unique
corr  pcs_rmean $ment_unique
corr  mcs_rmean $ment_unique

*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# MAIN
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

factor $phys_unique $ment_unique, blank(`=blank_th')  factors(2)
cap drop n_main
gen byte n_main = e(sample)
rotate, promax(`=promax') oblique blank(`=blank_th')  factors(2) /* altdiv */
rotate2, promax(`=promax') oblique blank(`=blank_th')  mat(main) factors(2) /* altdiv */nosort uniqueness nolabel
mat2tex using $incl_thesis/tbls/factor_rot_main.tex , m(main) replace format("%9.3f") 
! sed -i -e 's/.z/ /g'  $incl_thesis/tbls/factor_rot_main.tex
! sed -i -e 's/\_/\\_/g'  $incl_thesis/tbls/factor_rot_main.tex
cat $incl_thesis/tbls/factor_rot_main.tex

if "`=doplot'"=="1" {
    loadingplot, name(gmain, replace) `=fplotopt_pdf' /* title(Factor Loadings (Oblique main, raw input vars)) */
    graph export $figures/factor/factor_loadings_b_oblique_main_raw_input_vars.pdf, replace
    screeplot
}

estat kmo
estat struc
estat common

cap drop pcs_main mcs_main 
predict double pcs_main double mcs_main, r
lab var pcs_main "Physical Health (oblique)"
lab var mcs_main "Mental Health (oblique)"

mat scoefmain = r(scoef)
mat2tex using $incl_thesis/tbls/factor_scoef_main.tex , m(scoefmain) replace format("%9.3f")
! sed -i -e 's/\_/\\_/g'  $incl_thesis/tbls/factor_scoef_main.tex


if "`=doplot'"=="1" {
    corr ???_main
    hist pcs_main, name(g_pcs_main_1, replace) bin(100)
    hist mcs_main, name(g_mcs_main_1, replace) bin(100)
}

*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# DEF: closest to SOEP default (PCF, varmimax norm)
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

if 0 {
    /* to reproduce https://stats.oarc.ucla.edu/spss/output/factor-analysis/ */
    factor ITEM13-ITEM24, blank(.3) factors(3) pcf
    factor ITEM13-ITEM24, blank(.3) factors(3) ipf altdiv
    rotate, varimax norm altdiv
}

factor $phys_simple $ment_simple,      factors(2) blank(`=blank_th') pcf
cap drop n_def
gen byte n_def = e(sample)
rotate, varimax norm blank(`=blank_th') altdiv /* varimax with kaiser normalization (as Andersen 2007) */
rotate2, varimax norm /* blank(`=blank_th') */ altdiv matrix(def) nosort uniqueness nolabel
mat2tex using $incl_thesis/tbls/factor_rot_def.tex , m(def) replace format("%9.3f")
! sed -i -e 's/.z/ /g'  $incl_thesis/tbls/factor_rot_def.tex
! sed -i -e 's/\_/ /g'  $incl_thesis/tbls/factor_rot_def.tex
cat $incl_thesis/tbls/factor_rot_def.tex


estat kmo
estat common
estat struc
if "`=doplot'"=="1" {
    loadingplot, name(gdef, replace) `=fplotopt_pdf' /* Factor Loadings (SOEPs default) */
    graph export $figures/factor/factor_loadings_a_soeps_default.pdf, replace
    screeplot
}

cap drop pcs_def mcs_def 
predict double pcs_def double mcs_def, regression 
lab var pcs_def "Physical Health (sf12)"
lab var mcs_def "Mental Health (sf12)"

mat scoefdef = r(scoef)
mat2tex using $incl_thesis/tbls/factor_scoef_def.tex , m(scoefdef) replace format("%9.3f")


if 0 {
    corr  ???_def
    hist pcs_def, name(g_pcs_def, replace)
    hist mcs_def, name(g_mcs_def, replace)    

    corr pcs_def $phys_simple $ment_simple st
    corr mcs_def $phys_simple $ment_simple st
}

*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# ORTHO (pf varimax norm)
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

factor $phys_unique $ment_unique,      factors(2) blank(`=blank_th')  
cap drop n_ortho
gen byte n_ortho = e(sample)
rotate, varimax norm blank(`=blank_th')

estat kmo
estat common
estat struc
if "`=doplot'"=="1" {
    loadingplot, name(gortho, replace) `=fplotopt_pdf' title(Factor Loadings (Ortho. rot., raw input vars))
    graph export $figures/factor/factor_loadings_c_ortho_pf_varimax_norm.pdf, replace
    screeplot
}

cap drop pcs_ortho mcs_ortho 
predict double pcs_ortho double mcs_ortho, `=method'

if 0 {
    corr  ???_ortho
    hist pcs_ortho, name(g_pcs_ortho, replace) bin(100)
    hist mcs_ortho, name(g_mcs_ortho, replace) bin(100)
}

lab var pcs_ortho "Physical Health (Ortho)"
lab var mcs_ortho "Mental Health (Ortho)"

*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# OBLIQUE
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

factor $phys_simple $ment_simple,      factors(2) blank(`=blank_th') altdiv
cap drop n_obli
gen byte n_obli = e(sample)
rotate, promax(`=promax') oblique blank(`=blank_th') factors(2) altdiv
if "`=doplot'"=="1" {
    loadingplot, name(goblique, replace) `=fplotopt_pdf' title(Factor Loadings (Oblique rot.)) note(promax: `=promax') mcolor(blue%60) /* msymbol(d) */
    graph export $figures/factor/factor_loadings_d_oblique.pdf, replace
    screeplot
}

estat kmo
estat common
estat struc

cap drop pcs_obli mcs_obli 
predict double pcs_obli double mcs_obli, `=method'
if 0 {
    corr ???_obli
    hist pcs_obli, name(g_pcs_obli, replace) bin(100)
    hist mcs_obli, name(g_mcs_obli, replace) bin(100)
}
lab var pcs_obli "Physical Health (Oblique Rot.)"
lab var mcs_obli "Mental Health (Oblique Rot.)"


*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# Oblique with stress
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

factor $phys_unique $ment_unique st_m, blank(`=blank_th')  factors(2) 
cap drop n_mst
gen byte n_mst = e(sample)
rotate, promax(`=promax') oblique blank(`=blank_th') factors(2) altdiv

if "`=doplot'"=="1" {
    loadingplot, name(gstress, replace) `=fplotopt_pdf'  title(Factor Loadings (Oblique, raw input incl. stress))
    graph export $figures/factor/factor_loadings_oblique_raw_input_incl_stress.pdf, replace
    screeplot
}

if `=doplot' loadingplot, name(gstress, replace) matrix factors(2)

estat kmo
estat common
estat struc

cap drop pcs_mst /* ecs_mst */ mcs_mst 
predict double pcs_mst /* ecs_mst */ double mcs_mst,  /* norotate */ `=method'
lab var pcs_mst "Physical Health (from raw variables, oblique rot.)"
lab var mcs_mst "Mental Health (from raw variables, oblique rot.)"

if "`=doplot'"=="1" {
    hist pcs_mst, name(g_pcs_2, replace) bin(90)
    cap hist ecs_mst, name(g_ecs_2, replace) bin(90)
    hist mcs_mst, name(g_mcs_2, replace) bin(90)

    cor ?cs_mst
}


**# No Rotation
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

factor $phys_simple $ment_simple, blank(`=blank_th')  factors(2) pcf 
cap drop pcs_nort mcs_nort
predict double pcs_nort double mcs_nort,  norotate `=method'

lab var pcs_nort "1st Factor (no rotation)"
lab var mcs_nort "2nd Factor (no rotation)"
corr pcs_nort mcs_nort
if "`=doplot'"=="1" {
    loadingplot, name(gnorot, replace) aspect(1) scale(1.5) yline(0) xline(0) ysize(5) xsize(5) ///
        xlab(-0.6(.2).8) ylab(-0.6(.2).6) ///
        xtitle(Factor 1) ytitle(Factor 2)  title("") 
    graph export $figures/factor/factor_loadings_norotate.pdf, replace
}

*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# SINGLE factor
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

factor $phys_unique $ment_unique, factors(1) blank(`=blank_th') 
cap drop n_ortho
gen byte n_ortho = e(sample)

// rotate, varimax norm blank(`=blank_th')
rotate2, oblique promax(3) f(1) mat(main)
mat2tex using $incl_thesis/tbls/factor_rot_def.tex , m(main) replace format("%9.3f")
! sed -i -e 's/.z/ /g'  $incl_thesis/tbls/factor_rot_main.tex
! sed -i -e 's/\_/ /g'  $incl_thesis/tbls/factor_rot_main.tex
estat kmo
estat common
estat struc
if "`=doplot'"=="1" {
    // loadingplot, name(gortho_single, replace) `=fplotopt_pdf' title(Factor Loadings (Ortho. rot., raw input vars))
    // -> only one factor
    graph export $figures/factor/factor_loadings_c_single.pdf, replace
    screeplot
    graph export $figures/factor/factor_loadings_c_singles_scree.pdf, replace
}
cap drop pcs_sgl
predict double pcs_sgl , `=method'
cor pcs_sgl pcs_ortho pcs_def pcs_main
cor pcs_sgl mcs_ortho mcs_def mcs_main
lab var pcs_sgl "Single score"


*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# more factors
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

factor $phys_unique $ment_unique  , blank(`=blank_th')  factors(5)
rotate,  promax oblique blank(.2) factors(4) 
* rotate,  varimax blank(`=blank_th') factors(3) norm
if "`=doplot'"=="1" screeplot
estat common
if "`=doplot'"=="1" loadingplot, factors(4) combined aspect(1)
cap drop pcs_3fct ecs_3fct mcs_3fct
predict double pcs_3fct double ecs_3fct double mcs_3fct, `=method' 
cap noi tabstat pcs_3fct ecs_3fct mcs_3fct, by(age_cuts_10)

drop ?cs_3fct
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# standardize?
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
ds ?cs_* 
foreach var of varlist `r(varlist)' {
    di "var: `var'"
    egen __tmpvar = std(`var'), mean(50) sd(10)
    replace `var' = __tmpvar 
    drop __tmpvar 
}

ds ?cs_* 
sum `r(varlist)'

*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# check corrs
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

foreach type in main main ortho obli nort {
    di "`type'"
    corr mcs_`type' pcs_`type'
}


pwcorr pcs_def pcs_main pcs_nort pcs_obli 
pwcorr mcs_def mcs_main mcs_nort mcs_obli 

*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# Finalize
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

log close  
cp $log/tmp/01_c_health_factoring.log $log/, replace


sum ?cs*, sep(2)
keep pid syear pcs_* mcs_* gh pf1 pf2 bp rp1 rp2 st mh1 mh2 vt re1 re2 sf ??_m ??_p 
save $inter/health_factor_scores.dta, replace
exit


*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# tests
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
if 0 {
    desc using $inter/health_factor_scores.dta, short

    use $inter/health_factor_scores.dta, clear
    tab syear if !mi(mcs_def)
    tab syear if !mi(mcs_main)

    cap drop in19
    bys pid (syear): egen in19=max(!mi(mcs_main) & syear == 2019)
    fre in19
    tab syear in19
    cap drop in17
    bys pid (syear): egen in17=max(!mi(mcs_main) & syear == 2017)
    fre in17
    tab syear in17

    sum mcs* pcs*
}

if 0 {
    desc using $inter/data_general_sample_all_years.dta, short
    desc using $inter/health_factor_scores.dta, short

    use $inter/health_factor_scores.dta, clear
    tab syear
    merge 1:1 pid syear using $inter/data_general_sample_all_years.dta  /* just to keep only valid obs */
}

if 0 {
    desc using $inter/i_wealth_ipol.dta, short
    desc using $inter/health_factor_scores.dta, short

    use $inter/health_factor_scores.dta, clear
    tab syear

    merge 1:1 pid syear using $inter/i_wealth_ipol.dta, gen(_mg1)  /* just to keep only valid obs */
    drop psample
    merge 1:1 pid syear using $inter/data_general_sample_all_years.dta, gen(_mg2)  /* just to keep only valid obs */   
    tab syear if _mg1 == 1
    fre psample if _mg1==1
}


if 0 {
    use $soep_data/pwealth.dta, clear
    merge 1:1 pid syear using $inter/data_general_sample_all_years.dta, gen(_mg2)  /* just to keep only valid obs */   
}

if 0 {
    use $inter/health_factor_scores.dta, clear
    merge 1:1 pid syear using $inter/health_biyearly.dta, gen(_mg_01)
}
if 0 {
    use $inter/04_wrangled_2002_2020.dta, clear
    sum syear mcs* pcs* if mi(pcs)
    Variable |        Obs
-------------+-----------
       syear |    148,333
         mcs |          0
     mcs_def |      2,816
   mcs_ortho |      2,816
    mcs_obli |      2,816
-------------+-----------
    mcs_main |          0
     mcs_mst |          0
    mcs_diff |          0
         pcs |          0
     pcs_def |      2,816
-------------+-----------
   pcs_ortho |      2,816
    pcs_obli |      2,816
    pcs_main |          0
     pcs_mst |          0
    pcs_diff |          0
    /* TODO: check about 2.8k missing obs (mcs pcs somewhere in the generation). */
}

if 0 {
    use $inter/health_factor_scores.dta, clear
    merge 1:1 pid syear using $inter/04_wrangled_2002_2020.dta, gen(_mg_01)
    sum syear mcs* pcs* if mi(pcs)
}




if 0 graph close _all 
