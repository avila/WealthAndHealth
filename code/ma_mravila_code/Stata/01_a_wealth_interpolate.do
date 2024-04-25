*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*** MA: The health-wealth nexus over the life cycle
*** Au: Marcelo Rainho Avila (4679876)
*** Dt: 07.02.2024
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# 2) Merge with WEALTH 
/* 
DESC:
- in this section we gather data from pwealth.dta and merge with health data. 
- wealth module is present in five years intervals from 2002 on (2002 2007 2012 2017).
- interpolation is generated for missing years so to be able to merge with health. 
    - strong assumption, but I think best it can be done, and better than just carrying forward values. 

*/
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

cap log close _all
log using $log/tmp/01_a_wealth_interpolate.log, text replace

use $root/data/input/SC19_final_JK.dta, clear 
desc, short
lab language EN
replace syear = 2020 if syear==2019
/* data from Johannes, already imputed, needs only to make w0111 consistent */
tab syear /* only 2019 */
tabstat w01110 v01000 s01000, by(syear)
sum w01110 v01000 s01000, det 

clonevar nw_incl       = w01110 // Net Overall Wealth
clonevar w_vehicles_value  = v01000 // Vehicles Market Value
clonevar w_student_loan    = s01000 // Student Loans Market Value

/* generade w0111a to merge with pwealth.dta */
gen w0111a = nw_incl - w_vehicles_value + w_student_loan
lab var w0111a "Net Overall Wealth (imputed)"
sum w0111a, det


* save intermediary data set
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
clonevar w0101a = w01010 // Gross Overall Wealth, rename for consistency


* drop M samples (missing wealth)
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
fre psample if mi(w0101a)
fre psample if mi(w0111a)
drop if mi(w0111a) | mi(w0101a)
/* RESULTS: check number of dropped in M samples */


keep pid syear hid w0111a w0101a
save $inter/pwealth_2019_JK.dta, replace

*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# get cpi to deflate wealth variables
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
import delim using $indata/destatis_cpi_germany.csv, clear
rename year syear 

foreach year of numlist 2000(5)2020 {
    di "`year'"
    cap drop _x
    gen _x = cpi if syear==`year'
    sum _x 
    scalar cpi_`year' = r(mean)
    sca li 
    gen cpi_`year' = (cpi / `=cpi_`year'') 
}

drop _x cpi_pct_change
li
save $inter/destatis_cpi_germany.dta, replace


*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# interpolate wealth and deflate 
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
global vars_pwealth ///
    n0101a /// Gross Overall Wealth Incl. Vehicl. imp.a
    n0111a /// Net Overall Wealth Incl. Vehicl. and Student Loans imp.a
    w0111a /// Net Overall Wealth imp.a
    w02220 /// Net Overall Wealth Flag
    w0101a /// Gross Overall Wealth
    w0011a  // Gross Overall Debts
    

use pid hid syear $vars_pwealth if syear >= 2002 using $soep_data/pwealth.dta, clear
append using $inter/pwealth_2019_JK.dta, /* keep(pid syear w0111a) */
merge 1:1 pid syear using $inter/data_general_sample_all_years.dta, nogen keep(3) keepus(phrf pbleib) /* p HRF for wheighted xtile */
merge m:1 hid syear using $soep_data/hwealth.dta, keepus(w011ha w010ha) gen(_mg_phwealth) keep(1 3)
merge m:1 syear using $inter/destatis_cpi_germany.dta, keepus(cpi_2020) keep(3)
if 0 save $temp/xxxx.dta, replace
if 0 use $temp/xxxx.dta, clear

tab syear 
tabstat $vars_pwealth, by(syear)
lab language EN

/* !!! */
xtset pid syear, delta(1)
tsfill, full
distinct pid
/* RESULT: get number of distinct individuals */

mvdecode _all, mv(-1 = .a \ -2 = .b \ -3 = .c \ -4 = .d \ -5 = .e \ -6 = .f \ -7 = .g \ -8 = .h) 

tabstat $vars_pwealth w011ha w010ha, by(syear)

foreach var of varlist $vars_pwealth w011ha w010ha {
    di as res  "var: `var', `: var lab `var''"
    if "`var'"=="w02220" continue
    replace `var' = `var' / cpi_2020
    local lab : variable label `var'
    lab var `var' "`lab' (defl. CPI 2020)"
}

tabstat $vars_pwealth w011ha w010ha, by(syear)

* personal wealth
rename_relabel w0101a gw
rename_relabel n0111a nw_incl
rename_relabel w0111a nw

rename_relabel w02220 flag_nw /* check only */

* household wealth
rename_relabel w011ha hh_nw
rename_relabel w010ha hh_gw

cap drop sum_hh_nw sum_hh_gw
egen sum_hh_nw = sum(nw) if !mi(hid), by(hid syear)
egen sum_hh_gw = sum(gw) if !mi(hid), by(hid syear)

replace hh_nw = sum_hh_nw if mi(hh_nw)
replace hh_gw = sum_hh_gw if mi(hh_gw)

replace hh_nw = round(sum_hh_nw)
replace hh_gw = round(sum_hh_gw)

replace hid = l.hid if pid == l.pid & mi(hid)


global vars_wealth_renamed        ///
    gw               /// n0101a: Gross Overall Wealth Incl. Vehicl. imp.a
    nw_incl          /// n0111a: Net Overall Wealth Incl. Vehicl. and Student Loans imp.a
    nw               /// w0111a: Net Overall Wealth imp.a
    hh_nw                /// w011ha:HH Net Overall Wealth imp.a
    hh_gw                 // w010ha:HH Gross Overall Wealth imp.a


rename ($vars_wealth_renamed) =_raw

foreach var of global vars_wealth_renamed {
    di "VAR: `var'"
    bys pid : ipolate `var'_raw syear, gen(`var') /* epolate */
}
if 1 {
    tabstat *nw* *gw*, by(syear)
}

cap drop  flag_nw_ipol
gen flag_nw_ipol = !mi(nw_raw)
cap drop  flag_gw_ipol
gen flag_gw_ipol = !mi(gw_raw)

**# labsl
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

label variable gw       "Gross Overall Wealth"
label variable nw_incl  "Net Overall Wealth Incl. Vehicl. and Student Loans"
label variable nw       "Net Overall Wealth"
label variable hh_nw    "HH Net Overall Wealth"
label variable hh_gw    "HH Gross Overall Wealth"


*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# generate quantile groups
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
lab language EN

/* add minimal random variation to avoind heaping at 0 wealth and jumping a few quantiles altogether
-> without this variation, qantiles could jump eg from 6 to 23, missing the 10pctile altogether */
gen double nw_for_tiling = nw + (runiform(-1,1)/1e6)


**# net wealth
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
cap drop  nw_?ile*
gquantiles nw_pile = nw_for_tiling, xtile nquantiles(100) by(syear)
label variable nw_pile "Net Wealth percentile"
gquantiles nw_dile = nw_for_tiling, xtile nquantiles(10) by(syear)
label variable nw_dile "Net Wealth decile"
gquantiles nw_qile = nw_for_tiling, xtile nquantiles(4) by(syear)
label variable nw_qile "Net Wealth quartile"

cap drop  nw_?ile_w
gquantiles nw_pile_w = nw_for_tiling [fw=round(phrf)], xtile nquantiles(100) by(syear)
label variable nw_pile_w "Net Wealth percentile (weighted)"
gquantiles nw_dile_w = nw_for_tiling [fw=round(phrf)], xtile nquantiles(10) by(syear)
label variable nw_dile_w "Net Wealth decile (weighted)"
gquantiles nw_qile_w = nw_for_tiling [fw=round(phrf)], xtile nquantiles(4) by(syear)
label variable nw_qile_w "Net Wealth quartile (weighted)"

**# gross wealth
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
gen double gw_for_tiling = gw  + (runiform(-1,1)/1e6)

cap drop  gw_?ile*
gquantiles gw_pile = gw_for_tiling, xtile nquantiles(100) by(syear)
label variable gw_pile "Gross Wealth percentile"
gquantiles gw_dile = gw_for_tiling, xtile nquantiles(10) by(syear)
label variable gw_dile "Gross Wealth decile"
gquantiles gw_qile = gw_for_tiling, xtile nquantiles(4) by(syear)
label variable gw_qile "Gross Wealth quartile"

cap drop  gw_?ile_w
gquantiles gw_pile_w = gw_for_tiling [fw=round(phrf)], xtile nquantiles(100) by(syear)
label variable gw_pile_w "Gross Wealth percentile (weighted)"
gquantiles gw_dile_w = gw_for_tiling [fw=round(phrf)], xtile nquantiles(10) by(syear)
label variable gw_dile_w "Gross Wealth decile (weighted)"
gquantiles gw_qile_w = gw_for_tiling [fw=round(phrf)], xtile nquantiles(4) by(syear)
label variable gw_qile_w "Gross Wealth quartile (weighted)"

if 0 {
    compare nw_for_tiling nw
    keep if syear == 2017
    fre nw_pile
    compare gw_for_tiling gw
}

drop *_for_tiling 
drop phrf
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

log close  
cp $log/tmp/01_a_wealth_interpolate.log $log/, replace

save $inter/wealth_interpolated.dta, replace
exit 
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# tests
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//keep if inlist(syear, 2009, 2011, 2013, 2015, 2017, 2019) 
sort pid syear
merge 1:1 pid syear using $inter/gathered_p_ppath.dta, gen(_mg_gath_p_ppath) 

tab syear if nw<. & _mg_gath_p_ppath==3 
tab syear if gw<. & _mg_gath_p_ppath==3 
/*     
       2009 |     13,072       11.79       11.79
       2011 |     12,951       11.68       23.47
       2013 |     16,150       14.57       38.04
       2015 |     15,978       14.41       52.45
       2017 |     26,835       24.20       76.65
       2019 |     25,887       23.35      100.00
      Total |    110,873      100.00
*/

tab syear if _mg_gath_p_ppath == 3 
/*     
       2009 |     18,171       12.12       12.12
       2011 |     26,651       17.78       29.90
       2013 |     27,287       18.20       48.10
       2015 |     24,932       16.63       64.73
       2017 |     26,873       17.92       82.65
       2019 |     26,013       17.35      100.00
------------+-----------------------------------
      Total |    149,927      100.00
*/

drop psample /* for merging again and keeping all years */
*merge 1:1 pid syear using $soep_data/ppathl.dta, keepus(phrf psample sex) /* keep(3) */ gen(_mg_wealth_ppath)
merge 1:1 pid syear using $inter/data_general_sample_all_years.dta, keepus(psample) gen(_mg_wealth_valid)

lab language EN
drop if syear<2002

tab syear
tab syear if !mi(nw)
tab syear if _mg_wealth_valid == 1
tab syear if _mg_wealth_valid == 2
tab syear if _mg_wealth_valid == 3

*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# finished tests
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~