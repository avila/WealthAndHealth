*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*** MA: The health-wealth nexus over the life cycle
*** Au: Marcelo Rainho Avila (4679876)
*** Dt: 07.02.2024
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

cap log close _all
log using $log/tmp/03_a_clean_variables.log, text replace


*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# Clean Variables
* 
* - clean up variables
* - deal with labels
* - generate transformations
* - finalize dataset for analysis
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

use $inter/02_gathered_controls.dta, clear
desc, short
* pequiv
rename_relabel d11108     educ_highschool       // Education With Respect to High School
rename_relabel d11109     educ_years            // Number of Years of Education
rename_relabel i11101     hhinc_pre             // HH Pre-Government Income
rename_relabel i11102     hhinc_post            // HH Post-Government Income
rename_relabel e11105_v1  occup_isco88          // Occupation of Individual (ISCO88)
rename_relabel e11105_v2  occup_isco08          // Occupation of Individual (ISCO08)
rename_relabel e11106     ind_code_1d           // 1 Digit Industry Code of Individual
rename_relabel e11107     ind_code_2di          // 2 Digit Industry Code of Individual
rename_relabel d11104     marital_status        // Marital Status of Individual
rename_relabel d11107     children              // Number of Children in HH
rename_relabel e11101     work_hours            // Annual Work Hours of Individual
rename_relabel e11102     empl_status           // Employment Status of Individual
rename_relabel e11103     empl_level            // Employment Level of Individual
rename_relabel e11104     prim_activity         // Primary Activity of Individual
rename_relabel i11110     labor_earns           // Individual Labor Earnings

lab var educ_years "Years of Education"

* health vars ple


* relabels
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# gen age
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
gen age = syear - gebjahr
lab var age "Age"

if 0 {
    tabstat *_ever age if syear==2011, by(nw_pile)
    sort syear nw_pile
    bys nw_pile : sum ple0011_ever

    sort pid syear

    gen _tmp = 1 in 1/100
    egen _mk2 = max(_tmp), by(pid)

    list pid syear *_f wealth_ptil* ple0011_ever-ple0013_ever  if _mk2 == 1, sepby(pid)

    drop _mk2 _tmp    
}


* flags
lab def impflags 0 "Valid" 1 "Edited" 2 "Imputed"
lab val flag_nw impflags

* health diagnosed variables 
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
rename_relabel ple0008  current_health                           // Current Health
rename_relabel ple0009  limitat_due_hlt                          // Limitations In Daily Life Because Of Health Problems

rename_relabel ple0011  hd_sleep                               // Sleep Disturbances
rename_relabel ple0012  hd_diabetes                            // Diabetes
rename_relabel ple0013  hd_asthma                              // asthma
rename_relabel ple0014  hd_cardio                              // Cardiopathy
rename_relabel ple0015  hd_cancer                              // Cancer
rename_relabel ple0016  hd_stroke                              // Apoplectic Stroke
rename_relabel ple0017  hd_migraine                            // Megrim
rename_relabel ple0018  hd_blood_pres                          // High Blood Presure
rename_relabel ple0019  hd_depression                          // Depressive Psychosis
rename_relabel ple0020  hd_dementia                            // Dementia
rename_relabel ple0021  hd_joint                               // Joint Disorder (also: Arthrosis, Rheumatism)
rename_relabel ple0022  hd_back_pain                           // Chronic Back Complaints
rename_relabel ple0023  hd_other                               // Other Illness
rename_relabel ple0024  hd_no_illness                          // No Illness


cap drop *_ever *_cumsum *_change *_ever_change
global vars_diagnosed_rn /* current_health limitat_due_hlt */ hd_sleep hd_diabetes hd_asthma hd_cardio hd_cancer hd_stroke /// 
    hd_migraine hd_blood_pres hd_depression hd_dementia hd_joint hd_back_pain hd_other hd_no_illness
foreach var of global vars_diagnosed_rn {
    /* 
    generate binary if ever got diagnosed with X disease.
    note: var_cumsum shows that people tend to switch back to no disease quite a lot
    */
    
    di 120 * "~" 
    di "VAR: `var' `: variable label `var'' " 

    cap drop `var'_*
    bysort pid (syear) : gen int `var'_cumsum = sum(`var')
    order `var'_cumsum, after(`var')
    gen int `var'_ever = `var'_cumsum >= 1, after(`var'_cumsum)

    bysort pid (syear): gen `var'_change = `var'_ever != `var'_ever[_n-1] & _n > 1
    order `var'_change, after(`var'_ever)
    egen `var'_ever_change = max(`var'_change), by(pid)
    order `var'_ever_change, after(`var'_change)

    /* copy label to new variable */
    local lab : variable label `var'
    local newlab "`lab'"
    label variable `var'_ever "`newlab'"

    /* check output */
    tab syear `var'_cumsum, m
}

if $do_checks {
    preserve
    keep if syear>=2009
        cls
        foreach var of global vars_diagnosed_rn {
            list pid syear `var'* in 1/500, sepby(pid) head(50)    
        }
    restore
}

if $do_checks {
    cls
    format $vars_diagnosed_rn %9.0g
    list pid syear hd_sleep-hd_cardio_cumsum in 1/1000, sepby(pid) head(50)
    list pid syear hd_cancer-hd_blood_pres_cumsum in 1/1000, sepby(pid) head(50)
    list pid syear hd_depression-hd_back_pain_ever_change   in 1/1000, sepby(pid) head(50)
    /* shows that generation of "_ever" and "_change" is fine */
}

if $do_checks {
    // sum individual changes (==1 for each change)
    sum *_change
    // sum ever changes (==1 per id)
    sum *_ever_change
}


label var hd_sleep_ever          "Sleep Disorder"
label var hd_diabetes_ever       "Diabetes"
label var hd_asthma_ever         "Asthma"
label var hd_cardio_ever         "Cardiopathy"
label var hd_cancer_ever         "Cancer"
label var hd_stroke_ever         "Stroke"
label var hd_migraine_ever       "Migraine"
label var hd_blood_pres_ever     "Blood Pressure"
label var hd_depression_ever     "Depression"
label var hd_dementia_ever       "Dementia"
label var hd_joint_ever          "Joint Disorder"
label var hd_back_pain_ever      "Back Pain"
label var hd_other_ever          "Other"
label var hd_no_illness_ever     "No Illness"

label define yesno 0 "no" 1 "yes"
label val hd_sleep_ever hd_diabetes_ever hd_asthma_ever hd_cardio_ever hd_cancer_ever hd_stroke_ever /// 
    hd_migraine_ever hd_blood_pres_ever hd_depression_ever hd_dementia_ever hd_joint_ever hd_back_pain_ever hd_other_ever hd_no_illness_ever yesno


rename_relabel ple0036  chronically_ill                          // Chronically Ill
rename_relabel ple0040  legal_handicapped_bin                    // Legally Handicapped, Reduced Employment
rename_relabel ple0041  legal_handicapped_rate                   // Legally Handicapped, Reduced Employment
rename_relabel ple0046  days_off_sick_prev_year                  // Number Of Days Off Work Sick Prev. Year
rename_relabel ple0048  days_off_child_prev_year_bin             // no days off work child sick
rename_relabel ple0049  days_off_child_prev_year_nr              // number of days off work child sick
rename_relabel ple0050  days_off_other_reason                    // days off work due to other reasons
rename_relabel ple0051  days_off_other_reason_nr                 // number of days off work due to other reasons
rename_relabel ple0052  days_off_persn_reas_nr                   // no days absent because of personal reasons
rename_relabel ple0053  hosp_stay_prev_year                      // Hospital Stay Prev. Year
rename_relabel ple0055  hosp_stay_number                         // Number Of Hospital Stays Prev. Year
rename_relabel ple0056  hosp_stay_nights                         // Nights Of Hospital Stay Prev. Year
rename_relabel ple0072  doc_visit_l3month                        // Number Of Doctor Visits Last Three Mths.
rename_relabel ple0073  doc_visit_l3month_zero                   // No Doctor Visit Last Three Mths.

rename_relabel ple0097  insurance_type                           // Type Of Health Insurance
lab def insurance_type 1 "Statutory" 2 "Private" 3 "Neither"
lab val insurance_type insurance_type
rename_relabel ple0175  days_off_relative_numbers                // Not Worked Due to Care For Relative Prev Yr, Days

* health vars plh
rename_relabel plh0171 sats_health              // "Satisfaction With Health"
rename_relabel plh0172 sats_sleep               // "satisfaction with sleep"
rename_relabel plh0173 sats_work                // "Satisfaction With Work"
rename_relabel plh0174 sats_housework           // "Satisfaction With Housework"
rename_relabel plh0175 sats_hinc                // "Satisfaction With Household Income"
rename_relabel plh0176 sats_pinc                // "Satisfaction With Personal Income"
rename_relabel plh0177 sats_dwelling            // "Satisfaction With Dwelling"
rename_relabel plh0178 sats_leisure             // "Satisfaction With Amount Of Leisure Time"
rename_relabel plh0179 sats_chicare             // "Satisfaction With Child Care"
rename_relabel plh0180 sats_famlife             // "Satisfaction with family life"
rename_relabel plh0182 sats_life                // "Satisfaction with Life Overall"
rename_relabel plh0164 sats_educ                // "Satisfaction With School Education and Vocational Retraining"
rename_relabel plh0184 freq_angry               // "Frequency of being angry in the last 4 weeks" 
rename_relabel plh0185 freq_worried             // "Frequency of being worried in the last 4 weeks"
rename_relabel plh0186 freq_happy               // "Frequency of being happy in the last 4 weeks"
rename_relabel plh0187 freq_sad                 // "Frequency of being sad in the last 4 weeks"


/* cap variables only available in even years */
cap rename_relabel ple0004  state_stairs                         // State Of Health Affects Ascending Stairs
cap rename_relabel ple0005  state_tasks                          // State Of Health Affects Tiring Tasks
cap rename_relabel ple0006  height_cm                            // Height, cm
cap rename_relabel ple0007  weight                               // Weight

cap rename_relabel ple0026  l4w_pressed_for_time                 // Pressed For Time Last 4 Weeks
cap rename_relabel ple0027  l4w_melancholy                       // Run-down, Melancholy Last 4 Weeks
cap rename_relabel ple0028  l4w_well_balanced                    // Well-balanced Last 4 Weeks
cap rename_relabel ple0029  l4w_felt_energy                      // Used Energy Last 4 Weeks
cap rename_relabel ple0030  l4w_physical_pain                    // Physical pain last four weeks
cap rename_relabel ple0031  l4w_accomplished_less_physical       // Accomplished Less Due To Physical Problems
cap rename_relabel ple0032  l4w_limitations_physical             // Limitations Due To Physical Problems
cap rename_relabel ple0033  l4w_accomplished_less_emotional      // Accomplished Less Due To Emotional Problems
cap rename_relabel ple0034  l4w_less_careful_emotional           // Less Careful Due To Emotional Problems
cap rename_relabel ple0035  l4w_socially_limited_due_health      // Limited Socially Due To Health

cap rename_relabel ple0082  smoke_age_start                      // Age When Started To Smoke
cap rename_relabel ple0083  smoke_never_regular                  // Never Regularly Smoked
cap rename_relabel ple0084  smoke_gaveup_year                    // When Gave Up Smoking, Year
cap rename_relabel ple0085  smoke_gaveup_month                   // When Gave Up Smoking, Month
cap rename_relabel ple0089  smoking_item_nonresponse             // Smoking: Total Item Nonresponse
cap rename_relabel ple0090  alcohol_beer                         // Alcoholic Beverages: Beer
cap rename_relabel ple0091  alcohol_wine                         // Alcoholic Beverages: Wine, Champagne
cap rename_relabel ple0092  alcohol_spirits                      // Alcoholic Beverages: Spirits
cap rename_relabel ple0093  alcohol_mixed                        // Alcoholic Beverages: Mixed Drinks


*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# recode missing
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

local vars      days_off_sick_prev_year hosp_stay_number hosp_stay_nights
foreach var of local vars {
    replace `var' = 0 if `var' == .b    
}

replace legal_handicapped_bin = l2.legal_handicapped_bin if mi(legal_handicapped_bin) & !mi(l2.legal_handicapped_bin) & inrange(syear, 2002, 2020)
replace legal_handicapped_bin = f2.legal_handicapped_bin if mi(legal_handicapped_bin) & !mi(f2.legal_handicapped_bin) & inrange(syear, 2002, 2020)
replace legal_handicapped_bin = 2 if legal_handicapped_rate==.b

/* a few observations with missing, but in order not to loose the information carry forward last known value */
replace marital_status = l.marital_status if mi(marital_status ) & !mi(l.marital_status)

*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# recode logicals
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

replace doc_visit_l3month = 0 if doc_visit_l3month_zero==1

* children 
cap drop children_d
recode children (0 = 2 "no child") (1/99 = 1 ">=1 child(ren)"), gen(children_d) lab(children_d)



*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# groups
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
drop if age<17 

* age group c(17, 35, 45, 55, 68, 110) (close to quantiles)
cap drop age_g1
recode age   (17/34 = 1 "17-34")   (35/44 = 2 "35-44")   (45/54 = 3 "45-54")   (55/67 = 4 "55-67")   (68/110 = 5 ">=68"), gen(age_g1)
fre age_g1
tabstat age, by(age_g1) stat(mean min max n)

cap drop age_g2
recode age   (17/29 = 1 "17-29")   (30/39 = 2 "30-39")   (40/49 = 3 "40-49")   (50/59 = 4 "50-59")   (60/110 = 5 ">=60"), gen(age_g2) 
fre age_g2
tabstat age, by(age_g2) stat(mean min max n)

cap drop age_g3
recode age   (17/34 = 1 "17-34")   (35/50 = 2 "35-50")   (51/67 = 3 "51-67")   (68/110 = 4 ">=68"), gen(age_g3)
fre age_g3
tabstat age, by(age_g3) stat(mean min max n)


* age group c(17, 35, 45, 55, 68, 110) (close to quantiles)
cap drop age_g22
recode age   (17/49 = 1 "17-49")   (50/999 = 2 ">=50"), gen(age_g22)
fre age_g22
tabstat age, by(age_g22) stat(mean min max n)



* age cut by 5 and by 10
cap drop age_cuts_*
egen age_cuts_05 = cut(age), at(0(5)90 110) 
egen age_cuts_10 = cut(age), at(0(10)90 110)


* educ 
recode educ_highschool (1/2 = 1 "No higher educ") (3=2 "Higher educ"), gen(educ_g1)


* birth cohorts
cap drop birth_coh_*
egen birth_coh_05 = cut(gebjahr), at(1900(05)2020)
fre birth_coh_05
egen birth_coh_10 = cut(gebjahr), at(1900 1940(10)1990 2020)
fre birth_coh_10
egen birth_coh_20 = cut(gebjahr), at(1900 1940(20)1990 2020)
fre birth_coh_20

* close to quantiles (around 15 to 20% in each group)
egen birth_coh_qt = cut(gebjahr), at(1900 1950(10)1980 2020)
sum gebjahr
lab def birth_coh_qtlab 1900 "1900-1949" 1950 "1950-1959" 1960 "1960-1969" 1970 "1970-1979" 1980 "1980-`r(max)'", replace
lab val birth_coh_qt birth_coh_qtlab
fre birth_coh_qt
bys birth_coh_qt : sum gebjahr



**# interquartile groups of net_wealth
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
recode nw_pile (1/25 = 1) (26/75 = 2) (76/100 = 3), gen(nw_iqr_3)
lab var nw_iqr_3 "Net Wealth Interquartile Group"
lab def nw_iqr_3_lab 1 "lower quartile" 2 "interquartile" 3 "upper quartile"
lab val nw_iqr_3 nw_iqr_3_lab

recode gw_pile (1/25 = 1) (26/75 = 2) (76/100 = 3), gen(gw_iqr_3)
lab var gw_iqr_3 "Gross Wealth Interquartile Group"
lab def gw_iqr_3_lab 1 "lower quartile" 2 "interquartile" 3 "upper quartile"
lab val gw_iqr_3 gw_iqr_3_lab

recode gw_pile (1/50 = 1) (51/90 = 2) (91/100 = 3), gen(gw_groups)
lab var gw_groups "Gross Wealth Interquartile Group"
lab def gw_groups_l 1 "bottom 50 ptile" 2 "51-90 ptiles" 3 "top 10 ptile"
lab val gw_groups gw_groups_l

recode nw_pile (1/50 = 1) (51/90 = 2) (91/100 = 3), gen(nw_groups)
lab var nw_groups "Net Wealth Interquartile Group"
lab val nw_groups gw_groups_l

*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# splines
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

cap drop age_sp?
mkspline age_sp = age, cubic

cap drop educ_years_sp?
mkspline educ_years_sp = educ_years, cubic

**# Wealth at age x
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

* scalar age_range = 2 // age range (in case no match in exact age. )
* foreach age of numlist 20(5)70 22(10)62 {
*     get_wealth_at_age, type(both) age(`age') range(1) genquantiles /* debug */ curt
* }

/* foreach age of numlist 20(5)70 { 
    scalar age_gr = `age'
    di 80 * "~ " "`=age_gr'"

    cap drop _age_diff _age_diff_min
    gen _age_diff = abs(age - `=age_gr')
    bys pid : egen _age_diff_min = min(_age_diff)

    cap drop nw_at_`=age_gr'
    bysort pid : gen nw_at_`=age_gr' = nw if _age_diff == _age_diff_min & _age_diff<=`=age_range'
    cap drop gw_at_`=age_gr'
    bysort pid : gen gw_at_`=age_gr' = gw if _age_diff == _age_diff_min & _age_diff<=`=age_range'
    cap drop age_at_`=age_gr'
    bysort pid : gen age_at_`=age_gr' = age if _age_diff == _age_diff_min & _age_diff<=`=age_range'

    if 0 list pid syear age age_at_`=age_gr' gebjahr nw  nw gw gw nw_at_`=age_gr' gw_at_`=age_gr' _age_diff _age_diff_min in 1/100, sepby(pid) head(50)

    * fill up missing
    bys pid : fillmissing age_at_`=age_gr' nw_at_`=age_gr' gw_at_`=age_gr'
    sort pid syear
    if 0 list pid syear age age_at_`=age_gr' gebjahr nw  nw gw gw nw_at_`=age_gr' gw_at_`=age_gr' _age_diff _age_diff_min in 1/100, sepby(pid) head(50)

    **# a) net 
    * quantiles at certain ages
    cap drop nw_at_`=age_gr'_pile
    gquantiles nw_at_`=age_gr'_pile = nw_at_`=age_gr', xtile nquantiles(100) by(syear) replace

    /* cap drop nw_at_`=age_gr'_groups
    recode nw_at_`=age_gr'_pile (1/50 = 1) (51/90 = 2) (91/100 = 3), gen(nw_at_`=age_gr'_groups)
    lab var nw_at_`=age_gr'_groups "Net Wealth At `=age_gr' Group"
    lab val nw_at_`=age_gr'_groups gw_groups_l

    cap drop nw_at_`=age_gr'_groups_2
    recode nw_at_`=age_gr'_pile (1/10 = 1) (11/25 = 2) (26/90 =3) (91/100 = 4), gen(nw_at_`=age_gr'_groups_2)
    lab var nw_at_`=age_gr'_groups_2 "Net Wealth At `=age_gr' Group"
    cap lab def nw_at_grp2 1  "1~10ptile" 2  "11~25ptile" 3  "26~90ptile" 4  "91~100ptile"
    lab val nw_at_`=age_gr'_groups_2 nw_at_grp2
    */

    **# b) gross 
    * quantiles at certain ages
    cap drop gw_at_`=age_gr'_pile
    gquantiles gw_at_`=age_gr'_pile = gw_at_`=age_gr', xtile nquantiles(100) by(syear) replace

    /*  cap drop gw_at_`=age_gr'_groups
    recode gw_at_`=age_gr'_pile (1/50 = 1) (51/90 = 2) (91/100 = 3), gen(gw_at_`=age_gr'_groups)
    lab var gw_at_`=age_gr'_groups "Gross Wealth At `=age_gr' Group"
    lab val gw_at_`=age_gr'_groups gw_groups_l

    cap drop gw_at_`=age_gr'_groups_2
    recode gw_at_`=age_gr'_pile (1/10 = 1) (11/25 = 2) (26/90 =3) (91/100 = 4), gen(gw_at_`=age_gr'_groups_2)
    lab var gw_at_`=age_gr'_groups_2 "Gross Wealth At `=age_gr' Group"
    cap lab def gw_at_grp2 1  "1~10ptile" 2  "11~25ptile" 3  "26~90ptile" 4  "91~100ptile"
    lab val gw_at_`=age_gr'_groups_2 nw_at_grp2
    */
    if 0 list pid syear age age_at_`=age_gr' gebjahr nw nw_at_`=age_gr' gw_at_`=age_gr' gw_at_`=age_gr'_groups _age_diff _age_diff_min in 1/1000, sepby(pid) head(50)
}
 */
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# wealth by 1e3
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

replace nw = nw/1e3
replace gw = gw/1e3 

label variable nw  "Net Wealth (k€)"
label variable gw  "Gross Wealth (k€)"

*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# useful transformations or normalizations
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
save `c(tmpdir)'/use_trans.dta, replace

if 0 use `c(tmpdir)'/use_trans.dta, clear

rename plh0204_v2 per_risk
label var per_risk "Risk Tolerance"
tab syear per_risk, m

/* fill missing with previous value (assume no big change in risk tolerance) */
tsset pid syear, delta(1)
replace per_risk = l2.per_risk if syear>=2002 & mi(per_risk) & !mi(l2.per_risk)
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
/* per_rist not present in 2002. get the value from 2004, assuming personal risk preferences do not vary in the short term */
tab syear per_risk, m

mygen per_risk_1st = firstnonmissing(per_risk) if inrange(syear, 2000,2010), by(pid) sort(syear)
if 0 tag pid syear per_risk* if mi(per_risk) & syear==2004

replace per_risk = per_risk_1st if mi(per_risk) & syear==2002

drop per_risk_1st

*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# missings
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
/* . tabstat educ_years , by(educ_highschool )

Summary for variables: educ_years
Group variable: educ_highschool (d11108:Education With Respect to High School)

 educ_highschool |      Mean
-----------------+----------
[1] Less than H  |  9.024537
 [2] High School |  11.56059
[3] More than H  |  15.81218
-----------------+----------
           Total |  12.48593
---------------------------- */

replace educ_years =  9   if educ_highschool==1 & mi(educ_years)
replace educ_years = 11.5 if educ_highschool==2 & mi(educ_years)
replace educ_years = 16   if educ_highschool==3 & mi(educ_years)

replace educ_highschool = 1 if educ_highschool==.a & educ_years==7

/* get first non missing */
mygen educ_years_1st = firstnonmissing(educ_years), by(pid) sort(syear)
if 0 tag pid syear educ_years educ_years_1st if mi(educ_years)

bysort pid (syear): carryforward educ_years if syear>=2002, gen(_tmp)
bysort pid (syear): replace _tmp = f._tmp if mi(_tmp) & !mi(f._tmp) & _n==1
replace educ_years = _tmp if mi(educ_years) & !mi(_tmp)

drop educ_years_1st 
sort pid syear

**# personality traits
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
/* todo */

*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# factor
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

foreach var of varlist  mcs pcs pcs_def mcs_def pcs_ortho mcs_ortho pcs_obli mcs_obli pcs_main mcs_main pcs_mst mcs_mst pcs_nort mcs_nort {
    di "var: `var'"
    cap drop `var'_sd
    by pid : egen `var'_sd = sd(`var')
}



**# normalize exp variables by age
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

foreach var of varlist exp?? {
    di "`var'"
    gen `var'_norm = `var' / age
}

lab var expft_norm "Full-time exp. (age-normalized)"
lab var exppt_norm "Part-time exp. (age-normalized)"
lab var expue_norm "Unemployment exp. (age-normalized)"

foreach var of varlist exp?? {
    di "transform from years exp to months exp: `var'"
    replace `var' = `var' * 12
}

lab var expft "Full-Time exp. (months)"
lab var exppt "Part-Time exp. (months)"
lab var expue "Unemployment exp. (months)"


*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# transformations
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

/* check some transformations */
/* check up some transfomations */

foreach var of varlist nw gw hh_nw hh_gw  {
    replace `var' = round(`var')
    * gen var in thousends
    /* cap drop `var't
    gen `var't = `var'/1e3 */
}

foreach var of varlist nw hh_nw gw hh_gw /* ?w_at_?? */  {
    di "`var'"
    
    cap drop `var'_nlog
    gen  `var'_nlog = sign(`var') * log(1 + abs(`var'))

    cap drop `var'_curt
    gen  `var'_curt = cond(`var' < 0 , -(-`var')^(1/3), `var'^(1/3)) 

    /* cap drop `var'_sqrt
    gen  `var'_sqrt = cond(`var' < 0 , -(-`var')^(1/2), `var'^(1/2))

    cap drop `var'_4rt
    gen  `var'_4rt = cond(`var' < 0 , -(-`var')^(1/4), `var'^(1/4)) 

    cap drop `var'_5rt
    gen  `var'_5rt = cond(`var' < 0 , -(-`var')^(1/5), `var'^(1/5)) 
    
    cap drop `var'_asinh
    gen  `var'_asinh = asinh(`var') */
}

lab var gw_nlog "Gross Wealth (log)"
lab var nw_nlog "Net Wealth (neglog)"

lab var gw_curt "Gross Wealth (cubic root)"
lab var nw_curt "Net Wealth (cubic root)"


*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# winsor
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

foreach var of varlist gw nw {
    clonevar `var'_r = `var'
    winsor2 `var' , cuts(1 99) replace
}


label var gw              "Gross Wealth (k€, winsored)"
label var gw_nlog         "Gross Wealth (log)"
label var nw              "Net Wealth (k€, winsored)"
label var nw_nlog         "Net Wealth (neglog)"    
desc ?w ?w_nlog ?w*_r 


*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# drops 
/*
drop variables that are not relevant for analysis
*/
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
drop sats_educ /* only valid in 2019 */
drop doc_visit_l3month_zero /* already applied in doc_visit_l3month */
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# organize
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~



*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# final
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
cap order nw_at* gw_at* , last alpha
order pid syear 
save $temp/temp_data.dta, replace

* construct final sample
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
if 1 {  
 
    /* only late odd years */
    if 1 use $temp/temp_data.dta, clear 
    fre psample
    keep if inlist(syear, /* 2009, */ 2011, 2013, 2015, 2017, 2019)
    tab syear
    scalar nr_years = r(r)

    cap drop _keep
    egen _keep = max(syear==2019), by(pid)

    cap drop _keep_all
    cap drop _tmp*
    gen _tmp = 1 if inlist(syear, 2011, 2013, 2015, 2017, 2019)
    egen _tmp2 = sum(_tmp), by(pid)
    egen _keep_all = max(_tmp2==`=nr_years'), by(pid)

    tab syear _tmp
    tab syear _tmp2
    tab syear _keep_all
    cap drop _tmp*

    tsset, clear
    sort pid syear
    desc, short
    missings dropvars, force
    save $inter/03_clean_sr_biyearly.dta, replace

}

if 1 {
    /* only years of wealth modules */
    if 1 use $temp/temp_data.dta, clear 
    fre psample
    keep if inlist(syear,2002, 2007, 2012, 2017, 2019)
    tab syear
    scalar nr_years = r(r)

    cap drop _keep
    egen _keep = max(syear==2019), by(pid)

    cap drop _keep_all
    cap drop _tmp*
    levels_valid nw
    gen _tmp = 1 if inlist(syear,2002, 2007, 2012, 2017, 2019)
    egen _tmp2 = sum(_tmp), by(pid)
    egen _keep_all = max(_tmp2==`=nr_years'), by(pid)

    tab syear _tmp
    tab syear _tmp2
    tab syear _keep_all
    cap drop _tmp*


    tsset, clear
    sort pid syear
    desc, short
    save $inter/03_clean_lr_5yearly.dta, replace       
}

if 1 {
    /* even years (for health module 2002 - 2018, biyearly) */
    if 1 use $temp/temp_data.dta, clear 
    fre psample
    keep if mod(syear, 2)==0 & syear >= 2002 /* keep only valid years */
    tab syear
    scalar nr_years = r(r)

    cap drop _keep
    egen _keep = max(syear==2020), by(pid)

    cap drop _keep_all
    cap drop _tmp*
    gen _tmp = 1 
    egen _tmp2 = sum(_tmp), by(pid)
    egen _keep_all = max(_tmp2==`=nr_years'), by(pid)

    tab syear _tmp
    tab syear _tmp2
    tab syear _keep_all
    cap drop _tmp*

    tsset, clear
    sort pid syear
    desc, short
    save $inter/03_clean_lr_even_years.dta, replace       

}


if 1 {
    /* all years */
    if 1 use $temp/temp_data.dta, clear 
    keep if syear>=2002
    fre psample
    tab syear
    scalar nr_years = r(r)

    cap drop _keep
    egen _keep = max(syear==2020), by(pid)

    cap drop _keep_all
    cap drop _tmp*
    gen _tmp = 1 
    egen _tmp2 = sum(_tmp), by(pid)
    egen _keep_all = max(_tmp2==`=nr_years'), by(pid)

    tab syear _tmp
    tab syear _tmp2
    tab syear _keep_all
    cap drop _tmp*

    tsset, clear
    sort pid syear
    desc, short
    save $inter/03_clean_lr_all_years.dta, replace

}

/* mvdecode _all, mv(-1 = .a \ -2 = .b \ -3 = .c \ -4 = .d \ -5 = .e \ -6 = .f \ -7 = .g \ -8 = .h)  */
/* every now and then check if there are still un-decoded missings, find out why if it is the case! */

*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# clear and exit
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
log close  
cp $log/tmp/03_a_clean_variables.log $log/, replace


cap graph drop Graph
exit

