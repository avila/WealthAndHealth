*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*** MA: The health-wealth nexus over the life cycle
*** Au: Marcelo Rainho Avila (4679876)
*** Dt: 07.02.2024
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


cap log close _all
log using $log/tmp/01_c_health_interpolate.log, text replace



*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# wrangle wealth: interpolate and save intermediary data
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

/* NOTE: maybe not a good idea to interpolate health variables... 
-> instead interpolate only wealth and merge on years where health variables are available */


use if syear>=2002 using $soep_data/health.dta, clear
mvdecode mcs pcs *_nbs, mv(-1 = .a \ -2 = .b \ -3 = .c \ -4 = .d \ -5 = .e \ -6 = .f \ -7 = .g \ -8 = .h) 
desc, short 
tabstat pcs mcs, by(syear) stat(mean count)



/* interpolate */
/* foreach var of varlist mcs pcs pf_nbs - height weight {
    rename `var' `var'_r
    di "VAR: `var'"
    bys pid : ipolate `var'_r syear, gen(`var') /* epolate */
} 

tabstat pcs pcs_r mcs mcs_r, by(syear) stat(mean count)
drop *_r */

*keep if inlist(syear, 2002, 2007, 2012, 2017)
keep if mod(syear, 2)==0 /* keep only valid years */
save $inter/health_biyearly.dta, replace 
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


log close  
cp $log/tmp/01_c_health_interpolate.log $log/, replace

exit
