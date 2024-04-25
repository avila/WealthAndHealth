*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
/* TODO
-> example 10 of "help margins": testing margins - contrasts of marings
 */

*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# read in data
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

use $inter/03_clean_sample_2011_2019_biyearly.dta, clear
xtset pid syear, delta(2)
desc, short
notes



*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# globals
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

global hd_ever_diag     hd_sleep_ever hd_diabetes_ever hd_asthma_ever hd_cardio_ever hd_cancer_ever hd_stroke_ever ///
    hd_migraine_ever hd_blood_pres_ever hd_depression_ever hd_dementia_ever hd_joint_ever hd_back_pain_ever /// 
    hd_other_ever hd_no_illness_ever 


*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# basic overview
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

tab syear _keep_all


*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# regression
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


**# A
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
/* xtLogit: dummy of having a certain disease on: net wealth quartiles, age dummies …. + Margins Margins plot  */

global y hd_sleep_ever
global x i.nw_qile
global ctrl i.age_cuts_10 i.educ_highschool i.sex i.marital_status i.legal_handicapped_bin children i.children_d i.insurance_type 

xtlogit $y $x $ctrl


global y hd_sleep_ever
global x i.nw_dile
global ctrl i.age_cuts_10 i.educ_highschool i.sex i.marital_status i.legal_handicapped_bin children i.children_d i.insurance_type 

xtlogit $y $x $ctrl



global y hd_cardio_ever
global x i.gw_qile
global ctrl i.age_cuts_10 i.educ_highschool i.sex i.marital_status i.legal_handicapped_bin children i.children_d i.insurance_type 

xtlogit $y $x $ctrl





**# B
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

/* xtologit (or xtreg) of health satisfaction on: net wealth quartiles, having a certain disease, interaction net wealth
   quartiles x having a certain disease, age dummies …. External validation of health variables: Compare pop shares in
   SOEP with a certain disease and external admin statistics */


global y sats_health
global interaction i.hd_sleep_ever##i.nw_qile
global ctrl i.age_cuts_10 i.educ_highschool i.sex i.marital_status i.legal_handicapped_bin children i.children_d i.insurance_type 

xtologit $y $interaction $ctrl





*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# binned scatter plots
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


foreach var of varlist $hd_ever_diag {

    global y sats_health
    global x i.nw_qile##i.`var'

    reg $y $x $ctrl i.birth_coh_qt  i.syear
    margins $x
    marginsplot, name(`var', replace)       
            
}
xtreg $y $x $ctrl
reg $y $x $ctrl i.birth_coh_qt  i.syear
margins $x
marginsplot, name($y)



scalar intercative = 1
local counter = 1
foreach var of varlist $hd_ever_diag {
    scalar y = "`var'"
    scalar control = "age educ_highschool"
    scalar byVar = "sex" /* educ_highschool */

    set graph off
    qui binslogit `=y' nw_qile `=control',  ci(2 2) by(`=byVar') name(g`counter', replace) ///
        yscale(r(0))
    
    if mod(`counter', 2)==0 {
        di 1 
        set graph on
        grc1leg2 g`counter' g`=`counter'-1', ycommon legendfrom(g`counter') ///
            title("Predicted probability of being ever diagnosed with _x_") ///
            note("Adjusted for `=control'")
        *graph export $figures/recap/hd_evers/f_g_`counter'_ever_diag_byWealth_`=byVar'Educ.png, replace

        local counter = `counter' + 1
        if `=intercative'==1 {
            sleep 3e3 /* sleeps 3 seconds */
        }
    }
}

