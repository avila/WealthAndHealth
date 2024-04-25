*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*** MA: The health-wealth nexus over the life cycle
*** Au: Marcelo Rainho Avila (4679876)
*** Dt: 07.02.2024
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
* master do file 
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

* set options ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

set more off
set linesize 255
set logtype text
set varabbrev off
set scrollbufsize 2000000
set max_preservemem 4g

* stata globals 
/* some table output cleaning requires `sed', probably only works in Linux/Unix systems */
global S_SHELL bash 


* clear stuff 
clear all
capture noisily log close _all
macro drop _all
clear frames

* set globals ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


global root         "~/devel/WealthAndHealth"
if "`c(username)'" == "mavila" global root  "//hume/soep-data/STUD/mavila/Projects/avila_github/WealthAndHealth"

global do           "$root/code/Stata"
global out          "$root/output"
*global inter        "$root/inter"
global log          "$root/logs"
global tables       "$out/tables"
global figures      "$out/figures"
global indata       "$root/data/input"
global inter        "$root/data/intermediary"
global incl_thesis  "$root/manuscripts/thesis/incl"

global temp         "/tmp"
if "`c(username)'" == "mavila" global temp         "`c(tmpdir)'"

global soep_data    "/data/SOEP/SOEPv36b"
global soep_data    "/data/SOEP/SOEPv37"
if "`c(username)'" == "mavila" global soep_data    "//hume/rdc-prod/complete/soep-core/soep.v37/consolidated14"

* global options ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

global do_checks        1
global export_tables    0

global keep_odd_years   0

global lsopts           head(50) sepby(pid) noobs


* helper programs ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
run $do/00_b_packages.do
run $do/00_b_helper_programs.do
run $do/tag.ado


*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# 00b) set some scheme and options
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

* drop and discard graphs stuff
graph drop _all 

graph query, schemes
set scheme tab2
*set scheme cleanplots /* net install cleanplots, from("https://tdmize.github.io/data/cleanplots") */
*set scheme plotplain /* alternative */
*set scheme s2color /* default */
* graph set window fontface "Nimbus Sans Narrow" /* narrower to keep labels "thinner" */

* exit ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
mac list 
exit


*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# outline
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


**# pre-process
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

do $do/00_c_general_all_years.do
/* output file: $inter/data_general_sample_all_years.dta */

do $do/01_a_wealth_interpolate.do
/* output file: $inter/wealth_interpolated.dta, will be merged in 01_b_gather_wealth_health_vars.do */

do $do/01_b_gather_wealth_health_vars.do
/* output files:
- $inter/i_wealth_ipol.dta
- $inter/01_p_ppath_wealth_2002_2019_5yrl.dta */

do $do/01_c_health_interpolate.do
/* output file: $inter/health_ipol.dta. NOTE: maybe no longer used */

do $do/01_c_health_factoring.do
/* output file: $inter/health_factor_scores.dta */

do $do/02_a_gather_control_variables.do 
/* output file: $inter/02_gathered_controls.dta */

do $do/03_a_clean_variables.do 
/* output files:
   use $inter/03_clean_sr_biyearly.dta, clear
   use $inter/03_clean_lr_5yearly.dta, clear
   use $inter/03_clean_lr_even_years.dta, clear
   use $inter/03_clean_lr_all_years.dta, clear
*/

* do $do/03_clear_sr_only_full_vars.do
/* output file: use $inter/03_clean_sr_biyearly_only_full_vars.dta */

* do $do/04_a_wrangle_dynamics.do
/* output file: use $inter/04_wrangled_2002_2020.dta */


*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# Clustering (not used in final analysis)
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

/* do $do/05_longitudinal_clust.do */
/* output file: 05_traj_`=traj_type_all'.dta */
/* takes a while! might not be used in final analysis */
/* do $do/05_longitudinal_clust_regression.do */
/* do $do/05_dif_health_by_clust.do */


*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# descriptives
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

do $do/06_descriptives_tables.do

do $do/06_descriptives_graphs.do

do $do/06_validate_mcspcs.do

do $do/06_attrition.do

*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# DID
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

do $do/07_gen_treat_time.do
/* use $inter/07_did_gentreattime.dta, clear */

do $do/07_csdid_models.do

do $do/07_treatcontrol_levels.do

