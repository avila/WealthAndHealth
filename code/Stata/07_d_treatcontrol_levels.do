*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*** MA: The health-wealth nexus over the life cycle
*** Au: Marcelo Rainho Avila (4679876)
*** Dt: 07.02.2024
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

cap log close _all
log using $log/tmp/07_d_treatcontrol_levels.log, text replace


*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# options
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
scalar tleadmax = 10
scalar tlagsmax = 12
scalar crit     =  2

set graph off
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# plot options
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
global gropt_sizes_ck  scale(1.8) xsize(11) ysize(7) xlab(-\`=tleadmax'(2)\`=tlagsmax', nogrid) ylab(, nogrid) 
global gropt_canva_ck  xline(-2, lc(gs8) lp(dash) lw(.2)) graphregion(color(white)) bgcolor(white) ylabel(, angle(horizontal)) 
global gropt_title_ck  xtitle("Years since the event") ytitle("mean( Y | e, treat={0,1})") 
global gropt_legen_ck  leg(off) /// legend(order(1 "Untreated" 3 "Treated")  cols(1) region(fcolor(gs16%80)) )




*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
use $inter/07_did_gentreattime_small.dta, clear 

lab val syear syear
sum age syear pid
distinct pid
* keep if educ_highschool == 1

* keep pid syear age ?cs_rmean ?cs_sep ?cs_def ?cs_main *treat*  *timeto* gw nw nw_nlog gw_nlog n N labor_earns expft expue empl_status tatzeit
* keep if (inrange(age,18,65))

preserve
foreach hnum of numlist 1 2 /* 2 3 4 */ {
local cstype : word `hnum' of  /*1*/main  /*2*/def  /*3*/sep  /*4*/rmean
    foreach i of numlist 0 1 {
        global kpn   `i'      /* keep based on n */   
        global kpwin  1      /* keep based on windonw */   
        * set graph off
        
        foreach varhealth of varlist pcs_`cstype' mcs_`cstype' {
            
            local vartreat  treat_any_`varhealth'
            local varby     _timeto_`varhealth'
            * local varby     syear
            local let_i = 1 
            if      "`varhealth'"=="pcs_`cstype'" local firstvars pcs_`cstype' mcs_`cstype'
            else if "`varhealth'"=="mcs_`cstype'" local firstvars mcs_`cstype' pcs_`cstype' 
            else break 
            foreach var of varlist `firstvars'    gw gw_nlog    nw nw_nlog expft expue empl_status tatzeit labor_earns  sats_health  sats_life sats_pinc sats_work freq_angry freq_worried freq_happy freq_sad {
                local let : word `let_i' of `c(ALPHA)'
                cap drop touse
                gen touse = 1
                sum touse age N _timeto_`varhealth' if touse
                if $kpn replace touse = 0 if !(N>=20)
                if $kpwin replace touse = 0 if !(inrange(_timeto_`varhealth', -`=tleadmax', `=tlagsmax'))
                sum touse age N _timeto_`varhealth' if touse
                local ylab "`: var lab `var''"
                di "var: `var'"
                di "ylab: `ylab'"
                statsby mean = r(mean) ub = r(ub) lb = r(lb) if touse, by(`varby' `vartreat') clear: ci means  `var', level(99)
                twoway  (rcap  ub lb `varby' if `vartreat'==0 , lcolor(stc1%66)) (conn mean `varby' if `vartreat'==0, ms(o) mcolor(stc1) lcolor(stc1%66)) /// 
                        (rcap  ub lb `varby' if `vartreat'==1 , lcolor(stc2%66)) (conn mean `varby' if `vartreat'==1, ms(t) mcolor(stc2) lcolor(stc2%66)) ///
                        , name(`var'_`varhealth'_n${kpn}_win${kpwin}, replace) $gropt_legen_ck $gropt_title_ck $gropt_canva_ck $gropt_sizes_ck
                * graph export $figures/csdid2/h_descr/f_`var'_`varhealth'_n${kpn}_win${kpwin}.pdf, replace
                restore, preserve
                local let_i = `let_i' + 1 
            }
        }
        if 0 { /* export graph combined? */
            grc1leg2 mcs_`cstype'_mcs_`cstype' pcs_`cstype'_mcs_`cstype'    gw_mcs_`cstype' gw_nlog_mcs_`cstype'   nw_mcs_`cstype' nw_nlog_mcs_`cstype', name(gc_mcs_`cstype'${kpn}${kpwin}, replace) colfirst loff scale(1.2)
            grc1leg2 pcs_`cstype'_pcs_`cstype' mcs_`cstype'_pcs_`cstype'    gw_pcs_`cstype' gw_nlog_pcs_`cstype'   nw_pcs_`cstype' nw_nlog_pcs_`cstype', name(gc_pcs_`cstype'${kpn}${kpwin}, replace) colfirst loff scale(1.2)
            set graph on
            graph dis gc_mcs_`cstype'${kpn}${kpwin}
            * graph export $figures/csdid2/h_descr/gc_mcs_`cstype'_n${kpn}_win${kpwin}.pdf, replace 
            graph dis gc_pcs_`cstype'${kpn}${kpwin}
            * graph export $figures/csdid2/h_descr/gc_pcs_`cstype'_n${kpn}_win${kpwin}.pdf, replace    
        }
    }
}

graph close _all


*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# done
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
log close  
cp $log/tmp/07_d_treatcontrol_levels.log $log/, replace


exit
