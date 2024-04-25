*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*** MA: The health-wealth nexus over the life cycle
*** Au: Marcelo Rainho Avila (4679876)
*** Dt: 07.02.2024
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

cap log close _all
log using $log/tmp/06_descriptives_graphs.log, text replace


use $inter/health_factor_scores.dta, clear
merge 1:1 pid syear using $inter/03_clean_lr_even_years.dta, gen(_mg_test)
keep if _mg_test==3
tab syear

scalar rangex0   = 0 
scalar rangex1   = 80

scalar rangey0   = 0 
scalar rangey1   = 80

scalar by      = 10

gen ru = runiform()

local type def main
foreach cstype of local type  {
    sum ?cs_`cstype'
    keep if inrange(pcs_`cstype', `=rangex0', `=rangex1')
    keep if inrange(mcs_`cstype', `=rangex0', `=rangex1')

    * scatter ?cs_`cstype', xscale(range(0 30)) yscale(range(0 30)) xlab(`=rangex0'(`=by')`=rangex1')
    /* g2 */scatter mcs_`cstype' pcs_`cstype' if !mi(nw_dile) & ru>.5 , mcolor(%55) msym(point) saving(twsc, replace) ///
        ysca(range(`=rangey0' `=rangey1')  alt)  xsca(range(`=rangex0' `=rangex1')  alt)   xlabel(`=rangey0'(`=by')`=rangey1', grid gmax) ///
        ylab(`=rangey0'(`=by')`=rangey1', labgap(5) labelminlen(6)) 
    /* g1 */hist mcs_`cstype', saving(kd_pcs, replace) xsca(alt reverse) horiz fxsize(25)  ysca(range(`=rangey0' `=rangey1')) xlab(, nogrid) ylab(`=rangey0'(`=by')`=rangey1', gmin gmax)
    /* g3 */hist pcs_`cstype', saving(kd_mcs, replace) ysca(alt reverse) ylab(, nogrid labgap(5) labelminlen(6)) xlab(`=rangey0'(`=by')`=rangey1', gmin gmax   ) fysize(25) xsca(range(`=rangex0' `=rangex1')) 
    graph drop _all
    graph combine     kd_pcs.gph twsc.gph kd_mcs.gph , hole(3) imargin(zero) graphregion(margin(l=2 r=2 t=2 b=2))  ysize(12) xsize(13)
    graph export $figures/factor/bidens_`cstype'.png, width(1200) replace
}

graph combine     kd_pcs.gph twsc.gph kd_mcs.gph , hole(3) imargin(zero) graphregion(margin(l=2 r=2 t=2 b=2))  ysize(12) xsize(13)
graph export $figures/factor/bidens_`cstype'.png, width(2400) replace


*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# done
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

log close  
cp $log/tmp/06_descriptives_graphs.log $log/, replace


exit
