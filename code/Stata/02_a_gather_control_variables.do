*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*** MA: The health-wealth nexus over the life cycle
*** Au: Marcelo Rainho Avila (4679876)
*** Dt: 07.02.2024
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

cap log close _all
log using $log/tmp/02_a_gather_control_variables.log, text replace



*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# Gather and merge further (control) variables
*
* Intermediary input file:  $inter/01_p_ppath_wealth.dta
* output file:              $data/.............dta
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# parents 
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
/* use $inter/bioparen.dta, clear */
use ?currloc ?profedu ?isei?? ?siops?? ?profedu ?sedu ?egp?? ?ydeath ?ybirth  using $inter/bioparen.dta, clear
d 
misstable summ
/*
?currloc 
?profedu
?isei??
?siops??
?profedu
?sedu
?egp??
*/

gen f_age_death = fydeath - fybirth
gen m_age_death = mydeath - mybirth

foreach var in isei siops egp {
    foreach i in m f {
        cap drop `i'`var'00
        gen `i'`var'00 = .z
        replace `i'`var'00 = `i'`var'08 if !mi(`i'`var'08)
        replace `i'`var'00 = `i'`var'88 if !mi(`i'`var'88) & `i'`var'00==.z
        lab var `i'`var'00 "`var' merged"
        lab val `i'`var'00 `i'`var'08
    }
}

**# save
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
save $inter/parents.dta, replace



*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# xx) pequiv
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
use $soep_data/pequiv.dta, clear
lookfor income
lookfor wealth
lookfor education


local pequiv_vars ///
    d11108      /// Education With Respect to High School
    d11109      /// Number of Years of Education
    i11101      /// HH Pre-Government Income
    i11102      /// HH Post-Government Income
    e11105_v1   /// Occupation of Individual (ISCO88)
    e11105_v2   /// Occupation of Individual (ISCO08)
    e11106      /// 1 Digit Industry Code of Individual
    e11107      /// 2 Digit Industry Code of Individual
    d11104      /// Marital Status of Individual
    d11107      /// Number of Children in HH
    e11101      /// Annual Work Hours of Individual
    e11102      /// Employment Status of Individual
    e11103      /// Employment Level of Individual
    e11104      /// Primary Activity of Individual
    i11110      /// Individual Labor Earnings
    e11201      /// Impute Annual Work Hours of Individual
    //e11106      /// 1 Digit Industry Code of Individual
    //e11107       // 2 Digit Industry Code of Individual


desc `pequiv_vars'

/* use $inter/01_p_ppath_wealth_merged.dta, clear */ //<- old dataset, 5yearly. 
desc using $inter/i_wealth_ipol.dta, short
use $inter/i_wealth_ipol.dta, clear
/* keep if mod(syear, 2)==0 // keep even years, 2002 - 2018. */
merge 1:1 pid syear using $soep_data/pequiv.dta, keep(1 3) gen(_mg_inter_pequiv) keepus(`pequiv_vars')
mvdecode `pequiv_vars', mv(-1 = .a \ -2 = .b \ -3 = .c \ -4 = .d \ -5 = .e \ -6 = .f \ -7 = .g \ -8 = .h) 
if $do_checks{
    fre syear if _mg_inter_pequiv == 1
    fre psample if _mg_inter_pequiv == 1
    fre phrf if _mg_inter_pequiv == 1
    /* note: 108 not matched from master. Don't know reason why.
    unmatched distributed across year and samples */
}

drop if _mg_inter_pequiv == 1 & phrf == 0 /* drop, since phrf 0 anyways */

save $temp/mgcntrl_pequiv.dta, replace
if 0 use $temp/mgcntrl_pequiv.dta, clear
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# pgen 
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
cap frame create _temp 
frame _temp {
    use pid syear pgexp?? pg???zeit pgstib pgnation using $soep_data/pgen, clear
    lab lang EN
    rename pg* *
    d,s
    mvdecode _all, mv(-1 = .a \ -2 = .b \ -3 = .c \ -4 = .d \ -5 = .e \ -6 = .f \ -7 = .g \ -8 = .h)
    save $inter/pgen_selected_vars.dta, replace
}

merge 1:1 pid syear using $inter/pgen_selected_vars.dta, gen(_mg_pgen)

*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# bioedu
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
frame _temp {
    use pid bex4age bex4cert bex4cert2 using $soep_data/bioedu.dta, clear
    mvdecode _all, mv(-1 = .a \ -2 = .b \ -3 = .c \ -4 = .d \ -5 = .e \ -6 = .f \ -7 = .g \ -8 = .h)
    
    save $inter/bioedu_selected_vars.dta, replace
}
merge m:1 pid using $inter/bioedu_selected_vars.dta, gen(_mg_bioedu)

*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# Health 
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

merge 1:1 pid syear using $inter/health_biyearly.dta, keepus(mcs pcs *_nbs) gen(_mg_health)
keep if inlist(_mg_health, 1, 3)
/* no mcs pcs for 2019 sample -> no extrapolation from 2018 onto 2019! */
tab syear

if 0 save /tmp/xxxxxxx.dta, replace
if 0 use /tmp/xxxxxxx.dta, clear

merge 1:1 pid syear using $inter/health_factor_scores.dta, ///
    keepus(mcs* pcs* *_m *_p pf2 pf1 rp2 rp1 bp gh re1 re2 sf mh1 mh2 vt st ) gen(_mg_factoring)
* keep if _mg_factoring==3
/* -> keeps only merge, removes ind with valid health info but not wealth info! */
distinct pid


*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# Personality traits (big five)
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
cap frame create _temp
frame _temp {

    use pid syear plh0182 ple0011 plh0215 plh0220 plh0225 plh0218 plh0212 plh0222 plh0223 plh0213 plh0219 plh0214 plh0217 plh0224 plh0226 plh0216 plh0221 using $soep_data/pl.dta, clear
    lab language EN
    mvdecode _all, mv(-1 = .a \ -2 = .b \ -3 = .c \ -4 = .d \ -5 = .e \ -6 = .f \ -7 = .g \ -8 = .h)

    **# Personality (BIG FIVE)
    *** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    **# Openness
    *** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    sum plh0215 plh0220 plh0225                     // Originell, künstl. Erfahrung, lebhafte Phantasie
    alpha plh0215 plh0220 plh0225, i c g(open)
    egen open_z = std(open)

    **# Conscientiousness
    *** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    gen plh0218_rev = 8-plh0218
    sum plh0212 plh0218_rev plh0222                    // Faul, gründlich arbeiten, Aufgaben wirksam erledigen
    alpha plh0212 plh0218_rev plh0222, i c g(cons)
    egen cons_z = std(cons)
     
    **# Extraversion
    *** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    gen plh0223_rev = 8-plh0223
    sum plh0213 plh0219 plh0223_rev                    // zurückhaltend, Kommunikativ, Gesellig
    alpha plh0213 plh0219 plh0223_rev, i c g(extra)
    egen extra_z = std(extra)
     
    **# Agreeableness
    *** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    gen plh0214_rev = 8-plh0214
    sum plh0214_rev plh0217 plh0224                    // Manchmal grob, Verzeihen können, Rücksichtsvoll
    alpha plh0214_rev plh0217 plh0224, i c g(agree)
    egen agree_z = std(agree)
     

    **# Neuroticism
    *** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    gen plh0226_rev = 8-plh0226
    sum plh0216 plh0221 plh0226_rev                    // Mit Stress umgehen, oft Sorgen, leicht nervös
    alpha plh0216 plh0221 plh0226_rev, i c g(neuro)
    egen neuro_z = std(neuro)


    bys pid : fillmissing *_z, with(previous)
    **# save
    *** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    save $inter/big_five.dta, replace    
}
merge 1:1 pid syear using $inter/big_five.dta, gen(_mg_bigfive) keepus(open_z cons_z extra_z agree_z neuro_z)

*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# bula
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
cap frame create _temp
frame _temp {
    use pid hid syear using $soep_data/pgen.dta, clear
    merge m:1 hid syear using $soep_data/hgen.dta, gen(_mg_pgen_hgen) keepus(hgnuts1)
    mvdecode _all, mv(-1 = .a \ -2 = .b \ -3 = .c \ -4 = .d \ -5 = .e \ -6 = .f \ -7 = .g \ -8 = .h)
    rename hgnuts1 bula
    replace bula = .b if bula == . 
    gen east = inlist(bula,3,4,8,13,14,16) 
    
    label var east "Residence in East Germany =1"
    label def east 0 "0: West (w/o Berlin)" 1 "1: East (incl. Berlin)"

    save $inter/hgen_bula.dta,replace
}
drop hid 
merge 1:1 pid syear using $inter/hgen_bula.dta, gen(_mg_hgen) keepus(hid bula east) keep(1 3)

*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# migrants
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

gen german = nation==1 
drop nation
label var german "German Citizen"


*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# labels: revert to original labels due to issue with statsby
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
lab val syear syear
lab val pid pid


*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# finalize
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

desc, short
scalar k_var_before = r(k)
/* drop if ALL missing! */
foreach var of varlist _all {
    capture assert `var'==.h
    if !_rc {
        di "drop `var'"
        t `var', m
        drop `var'
    }
}
desc, short
scalar k_var_after = r(k)
sca li k_var_after k_var_before
mvdecode pid, mv(-1 = .a \ -2 = .b \ -3 = .c \ -4 = .d \ -5 = .e \ -6 = .f \ -7 = .g \ -8 = .h) 
save $inter/02_gathered_controls.dta, replace




log close  
cp $log/tmp/02_a_gather_control_variables.log $log/, replace


*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
clear frames
exit 


*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
use $inter/02_gathered_controls.dta, clear