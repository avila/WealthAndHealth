*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# The health-wealth nexus over the life cycle
*** Marcelo Rainho Avila (4679876)
*** 07.02.2024
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# Prog: rename_relabel
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
/*
description:
    renames the variable as built-in rename command but also applies the label of the old_name to the
    new_name in order to keep track which input variable the renamed variable is based upon.

syntax:
     rename_relabel old_name new_name

example:
. desc plb0022_h
plb0022_h: Erwerbsstatus [harmonisiert]

. rename_relabel plb0022_h erwstatus_h

. desc erwstatus_h
erwstatus_h: Erwerbsstatus [harmonisiert] | plb0022_h
*/
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

cap program drop rename_relabel
program rename_relabel
    syntax namelist(min=2 max=2), [Keepvarname]
    tokenize `namelist'
    local var       `1'
    local newvar    `2'
    if 0 {
        /* debug */
        di "var: `var'"
        di "newvar: `newvar'"
        di "keepvarname: `keepvarname'"    
    }
    local lab : variable label `var'
    if "`keepvarname'"!=""      local newlab "`var':`lab'"
    else                        local newlab "`lab'"
    rename `var' `newvar'
    label variable `newvar' "`newlab'"
end

*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# stdize: helper to standardize multiple variables at once
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
capture program drop stdize
program define stdize
    syntax varlist, [Mean(integer 0) Sd(integer 1) replace nolabel]
    
    foreach var of varlist `varlist' {
        cap drop `var'_std
        egen `var'_std = std(`var'), mean(`mean') sd(`sd')

        if "`nolabel'" == "" {
            local lab_short = substr("`: variable label `var''", 1, 40)
            lab var `var'_std "std(`var', mean=`mean', sd=`sd') | [`lab_short']"
        }

        if "`replace'"!="" {
            drop `var'
            rename `var'_std `var'
        }
    }

end


*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# get wealth at age
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
/* 
Description: program to extract wealth at certain age. 
Arguments:
- type: nw, gw or both
- age: age to extract wealth
- range: allows for extracting wealth at age+range or age-range, due to bi-yearly data
- genquantiles: optionally generates quantiles of wealth at certain age
- debug: prints some stuff for debuging purposes
*/
capture program drop get_wealth_at_age
program define get_wealth_at_age

    syntax, type(str) age(integer) range(integer) [genquantiles] [nlog] [curt] [debug]
    di 80 * "~ " "type: `type'" _skip(3) "age: `age'" _skip(3) "range: `range'"

    scalar age_range = `range'
    scalar age_target = `age'

    cap drop _age_diff 
    cap drop _age_diff_min
    gen _age_diff = (age - `=age_target')
    bys pid : egen _age_diff_min = min(abs(_age_diff))
    cap drop age_at_`=age_target'
    bysort pid : gen age_at_`=age_target' = age if _age_diff == _age_diff_min & _age_diff<=`=age_range'

/*     if !inlist("`type'", "nw", "gw", "both") {
        di as error "type must be one of: 'nw', 'gw' or 'both'"
        error 9
    } */
    if "`type'"=="both" local type nw gw

    foreach vartype of local type {
        di "type: `vartype'"
        local vartype_label : di  `=`"strupper("`vartype'")"''
        cap drop `vartype'_at_`=age_target'
        bysort pid : gen `vartype'_at_`=age_target' = `vartype' if _age_diff == _age_diff_min & abs(_age_diff<=`=age_range')        
        label var `vartype'_at_`=age_target' "`vartype_label' at age `=age_target'"
        bys pid : fillmissing `vartype'_at_`=age_target' age_at_`=age_target' , with(any)
        if "`genquantiles'"!="" {
            gquantiles `vartype'_at_`=age_target'_pile = `vartype'_at_`=age_target', xtile nquantiles(100) by(syear) replace
            label var `vartype'_at_`=age_target'_pile "pctile of `vartype_label' at age `=age_target'"
            // sum nw_at_`=age_target'_pile
        }

        if !missing("`nlog'") {
            cap drop `vartype'_at_`=age_target'_nlog
            gen `vartype'_at_`=age_target'_nlog = sign(`vartype'_at_`=age_target') * log(1 + abs(`vartype'_at_`=age_target'))
            label var `vartype'_at_`=age_target'_nlog "neglog of `vartype_label' at age `=age_target'"
        }
        if !missing("`curt'") {
            cap drop `vartype'_at_`=age_target'_curt
            gen `vartype'_at_`=age_target'_curt = cond(`vartype'_at_`=age_target' < 0 , -(-`vartype'_at_`=age_target')^(1/3), `vartype'_at_`=age_target'^(1/3))
            label var `vartype'_at_`=age_target'_curt "cubic root of `vartype_label' at age `=age_target'"
        }    
    }

    if "`debug'"!="" list pid syear age age_at_`=age_target' gebjahr ?w ?w_at_`=age_target' ?w_at_`=age_target'_????  _age_diff _age_diff_min in 1000/5000, sepby(pid) head(50)

    **# drop temp vars
    *** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    cap drop _age_diff _age_diff_min

end 
//get_wealth_at_age, type(both) age(22) range(1) genquantiles curt debug
//desc ?w_at_*

*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# get_sample
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
capture program drop get_sample
program define get_sample
    cap drop x
    gen x = e(sample)
    cap drop to_keep
    cap drop __n
    bys pid (syear) : gen __n = _n if x==1
    cap drop _min
    bys pid (syear) : egen _min = min(__n)
    bys pid : gen to_keep = (_n == _min)
end

*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# Programs for interactive use (just to save some typing)
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

/* short for tab syear VARNAME */
cap program drop t
program define t 
    syntax  [varlist(default=none)] [, *]
    if "`varlist'"=="" {
        tab syear
    }
    else {
        foreach var of local varlist {
            di "`var'"
            tab syear `var', `options'
        }
    }
end
if 0 {
    t sats*, m
}

/* short for tab syear VARNAME */
cap program drop tt
program define tt 
    syntax  [varlist(max=1 default=none)] [,*  Soepmissings]
    if mi(`"`varlist'"') local varlist pid
    if !mi("`soepmissings'")    tab syear if inrange(`varlist', 0, 9e9), `options'
    else                        tab syear if !mi(`varlist'), `options'
end
if 0 {
    tt sats*, m
}


/* short for lookfor VARNAME */
cap program drop lf
program define lf
    lookfor `1'
end

/* short to check for valid obs by syear */
cap program drop ll
program define ll
    syntax varlist
    clear results
    foreach var of varlist `varlist' {
        local lab : variable label `var'
        di "`var': `lab'"
        qui levelsof syear if inrange(`var', 0, 9e9), sep(,)    
        di "`var': `r(levels)'"
    }
end

cap program drop levels_valid
program define levels_valid
    return clear
    clear results 
    qui glevelsof syear if inrange(`1', 0, 9e9), sep(,)
    di as res "`1': `r(levels)'; waves: `r(J)'"
end

/* short to check for valid obs by syear */
cap program drop lluse
program define lluse
    syntax varlist
    clear results
    foreach var of varlist `varlist' {
        local lab : variable label `var'
        local lab_80 = substr("`lab'", 1, 60)
        qui levelsof syear if inrange(`var', 0, 9e9), sep(,)    
        di "`var'" _colum(22) " /// `lab_80'" _colum(90) " | `r(levels)'"
    }
end

/* revert (invert) a variable, useful when logical interpretation of variable 
follows inverse order of the categories */
capture program drop revert
program define revert
    syntax varlist
    clear results
    foreach var of varlist `varlist' {
        qui sum `var'
        replace `var' = 1 + r(max) - `var' if !mi(`var')
        label values `var' . /* drop var labs */
    }
end


capture program drop summary_table_procTraj
program summary_table_procTraj
    preserve
    *updating code to drop missing assigned observations
    drop if missing(_traj_Group)
    *now lets look at the average posterior probability
    gen Mp = 0
    foreach i of varlist _traj_ProbG* {
        replace Mp = `i' if `i' > Mp 
    }
    sort _traj_Group
    *and the odds of correct classification
    by _traj_Group: gen countG = _N
    by _traj_Group: egen groupAPP = mean(Mp)
    by _traj_Group: gen counter = _n
    gen n = groupAPP/(1 - groupAPP)
    gen p = countG/ _N
    gen d = p/(1-p)
    gen occ = n/d
    *Estimated proportion for each group
    scalar c = 0
    gen TotProb = 0
    foreach i of varlist _traj_ProbG* {
       scalar c = c + 1
       quietly summarize `i'
       replace TotProb = r(sum)/ _N if _traj_Group == c 
    }
    gen d_pp = TotProb/(1 - TotProb)
    gen occ_pp = n/d_pp
    *This displays the group number [_traj_~p], 
    *the count per group (based on the max post prob), [countG]
    *the average posterior probability for each group, [groupAPP]
    *the odds of correct classification (based on the max post prob group assignment), [occ] 
    *the odds of correct classification (based on the weighted post. prob), [occ_pp]
    *and the observed probability of groups versus the probability [p]
    *based on the posterior probabilities [TotProb]
    list _traj_Group countG groupAPP occ occ_pp p TotProb if counter == 1
    restore
end


capture program drop qhist
program define qhist
    syntax varlist [, *]
    foreach var of varlist `varlist' {
        di "plotting histogram of: `var'"
        qui hist `var', name(`var', replace) nodraw
    }
    di "plotting combined `varlist'"
    graph combine `varlist', `options'
end
capture program drop qh
program define qh
    syntax varlist [, *]
    foreach var of varlist `varlist' {
        di "plotting histogram of: `var'"
        qui hist `var', name(`var', replace) nodraw
    }
    di "plotting combined `varlist'"
    graph combine `varlist', `options'
end


capture program drop genleadlags 
program define genleadlags 
    syntax, TIMETOvar(varname) TTIME(string asis) leads(integer) lags(integer) [leadsuffix(string asis) lagsuffix(string asis)] delta(integer) 
    if mi("`leadsuffix'") local leadsuffix    tm /* for forward */
    if mi("`lagsuffix'")  local lagsuffix     tp /* for lags */
    if mi("`delta'")      local delta         1
    cap drop `leadsuffix'??
    cap drop `lagsuffix'??
    forvalues i = `leads' (-`delta') 2 {
        * local i : dis %02.0f  `i'
        di "lead: i: `i'"
        cap drop `leadsuffix'`i'
        gen `leadsuffix'`i' = `timetovar'==-`i'
    }
    forvalues i = 0 (`delta') `lags' {
        * local i : dis %02.0f  `i'
        di "lag: i: `i'"
        cap drop `lagsuffix'`i'
        gen `lagsuffix'`i' = `timetovar'==`i'
    }
    /* p: 1 pre-period. c: concurrent */
    if "`ttime'" == "c" {
        scal xline = (((`leads')+2)/2)-.5
        drop `lagsuffix'0 /* = 0 */
    }
    else if "`ttime'" == "p" {
        scal xline = ((`leads')/2)-.5
        drop  `leadsuffix'2 /* = 0 */
    }
    sum `leadsuffix'?? `leadsuffix'?  `lagsuffix'? `lagsuffix'??, separator(0)
end



capture program drop gentreats
program define gentreats
    syntax if/, [verbose] [suffix(str)] [runningvar(varname)]
    quiet {
        if "`runningvar'"=="" local runningvar syear
        sort pid `runningvar'
        scalar criter = "`if'"
        cap drop treat_i`suffix'
        gen treat_i`suffix' = (`if')
        lab var treat_i`suffix' "`if'"
        cap drop treat_any`suffix'
        egen treat_any`suffix' = max(treat_i`suffix'==1), by(pid)
        cap drop treat_sum`suffix'
        bys pid (`runningvar'): gen treat_sum`suffix' = sum(treat_i`suffix'==1)
        cap drop *reat_time`suffix'
        egen _treat_time`suffix' = min(`runningvar') if treat_sum`suffix'==1, by(pid)                                   /* year of first occurrence */
        egen treat_time`suffix' = mean(_treat_time`suffix'), by(pid)

        cap drop treat_post`suffix' 
        gen treat_post`suffix' = treat_sum`suffix'>=1

        egen sd_treat_any`suffix' = sd(treat_any`suffix') , by(pid)
        assert sd_treat_any`suffix'==0 | mi(sd_treat_any`suffix')
        drop sd_treat_any`suffix'

        egen sd_treat`suffix' = sd(_treat_time`suffix') , by(pid)
        assert sd_treat`suffix'==0 | mi(sd_treat`suffix')
        drop sd_treat`suffix'

        cap drop timeto`suffix'
        gen timeto`suffix' = `runningvar' - treat_time`suffix'                                                    /* relative year of occurrence */
        sort pid `runningvar' 

        cap drop timeto_max`suffix' timeto_min`suffix'
        bys pid: egen timeto_max`suffix' = max(timeto`suffix')
        bys pid: egen timeto_min`suffix' = min(timeto`suffix')
        drop _treat_time`suffix'
    }
    if "`verbose'"!="" {
        sum treat_*`suffix' timeto*`suffix'
    }
end


capture program drop gentreats2
program define gentreats2
    /* same as above, but allows for "critical" number of treatment... so that only 
    assigned to treatment if bad health outcome happens more often than `crit' times */
    syntax if/, [verbose] [suffix(str)] [runningvar(varname)] [crit(integer 1)]
    qui {
        if "`runningvar'"=="" local runningvar syear
        sort pid `runningvar'
        scalar criter = "`if'"
        cap drop treat_i`suffix'
        gen treat_i`suffix' = (`if')
        lab var treat_i`suffix' "`if'"
        
        cap drop treat_sum`suffix'
        bys pid (`runningvar'): gen treat_sum`suffix' = sum(treat_i`suffix'==1)
        di as error "sum"
        cap drop treat_max`suffix'
        bys pid (`runningvar'): egen treat_max`suffix' = total(treat_i`suffix'==1)
        di as error "max"
        cap drop *reat_time`suffix'
        egen _treat_time`suffix' = min(`runningvar') if treat_i`suffix'==1 & treat_max`suffix'>=`crit', by(pid)                                   /* year of first occurrence */
        di as error "Crit: `crit'"
        egen treat_time`suffix' = mean(_treat_time`suffix'), by(pid)
        cap drop treat_any`suffix'
        egen treat_any`suffix' = max(!mi(treat_time`suffix')), by(pid)

        cap drop treat_post`suffix' 
        gen treat_post`suffix' = treat_sum`suffix'>=1
        replace treat_post`suffix' = 0 if treat_any`suffix'==0

        egen sd_treat_any`suffix' = sd(treat_any`suffix') , by(pid)
        assert sd_treat_any`suffix'==0 | mi(sd_treat_any`suffix')
        drop sd_treat_any`suffix'

        egen sd_treat`suffix' = sd(_treat_time`suffix') , by(pid)
        assert sd_treat`suffix'==0 | mi(sd_treat`suffix')
        drop sd_treat`suffix'

        cap drop timeto`suffix'
        gen timeto`suffix' = `runningvar' - treat_time`suffix'                                                    /* relative year of occurrence */
        sort pid `runningvar' 

        cap drop timeto_max`suffix' timeto_min`suffix'
        bys pid: egen timeto_max`suffix' = max(timeto`suffix')
        bys pid: egen timeto_min`suffix' = min(timeto`suffix')
        drop _treat_time`suffix'
    }
    if "`verbose'"!="" {
        sum treat_*`suffix' timeto*`suffix'
    }
end


***start of do-file***
/* from https://www.stata.com/statalist/archive/2007-06/msg00636.html */
capt prog drop mergemodels
prog mergemodels, eclass
    // assuming that last element in e(b)/e(V) is _cons
    /* in that case, uncomment the 3 occurrences of "-1" below */
    version 8
    syntax namelist
    tempname b V tmp
    foreach name of local namelist {
        qui est restore `name'
        mat `b' = nullmat(`b') , e(b)
        mat `b' = `b'[1,1..colsof(`b')/* -1 */]
        mat `tmp' = e(V)
        mat `tmp' = `tmp'[1..rowsof(`tmp')/* -1 */,1..colsof(`tmp')/* -1 */]
        capt confirm matrix `V'
        if _rc {
            mat `V' = `tmp'
        }
        else {
            mat `V' = ///
            ( `V' , J(rowsof(`V'),colsof(`tmp'),0) ) \ ///
            ( J(rowsof(`tmp'),colsof(`V'),0) , `tmp' )
        }
    }
    local names: colfullnames `b'
    mat coln `V' = `names'
    mat rown `V' = `names'
    eret post `b' `V'
    eret local cmd "csdid"
end


*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# install csdid2
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
capture program drop fra
program define fra
    syntax anything, [all replace force]
    local from  "https://friosavila.github.io/stpackages"
    tokenize `anything'

    if "`1'`2'"==""  net from `from' 
    else if !inlist("`1'","describe", "install", "get") {
        display as error "`1' invalid subcommand"
    }
    else {
        net `1' `2', `all' `replace' from(`from')
    }
    qui:net from http://www.stata.com/
end



* Define program ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
cap program drop export_tex_body_only
program define export_tex_body_only
    preserve
    qui {
        clear
        set obs 1
        local texInp "`1'" // first arg
        local texOut "`2'" // second arg 

        confirm file "`texInp'"
        generate strL s = fileread("`texInp'") /* if fileexists("`texInp'") */
        assert filereaderror(s)==0
        replace s = subinstr(s,"\begin{","%%\begin{",1)   
        replace s = subinstr(s,"\end{","%%\end{",1)           
        gen byte fw = filewrite("`texOut'",s,1)
    }
    restore
    di as txt `"Latex file written to {browse `texOut'}"'
    cat `texOut'
end
* END program ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

if 0 {
    * test
    export_tex_body_only  "~/devel/WealthAndHealth/output/tables/tab_full_main.tex"  "~/devel/WealthAndHealth/output/tables/tab_full_main_bd.tex"
    cat ~/devel/WealthAndHealth/output/tables/tab_full_main.tex
    cat ~/devel/WealthAndHealth/output/tables/tab_full_main_bd.tex
}

/* current, working version */
capture program drop estaddpretrend
program define estaddpretrend
    syntax [anything]
    estadd scalar pre_df     `=pre_df'    /* : `anything' */
    estadd scalar pre_pchi2  `=pre_pchi2' /* : `anything' */
    estadd scalar pre_chi2   `=pre_chi2'  /* : `anything' */
end
capture program drop savepretrend
program define savepretrend, rclass
    estat pretrend
    scalar pre_df    = r(df)   
    scalar pre_pchi2 = r(pchi2)
    scalar pre_chi2  = r(chi2) 
end
capture program drop fixtable
program define fixtable
    syntax anything
    confirm file `anything'
    !sed -E -i s/tm\([0-9]\{0,9\}\)/\$\\\\hat\{\\\\theta\}_\{es\}\(-\\1\)\$/g `anything'
    !sed -E -i s/tp\([0-9]\{0,9\}\)/\$\\\\hat\{\\\\theta\}_\{es\}\(\\1\)\$/g `anything'
    !sed -E -i s/\\\\_avg/" "average/g `anything'   
end

capture program drop removebeginend
program define removebeginend
    syntax anything
    confirm file `anything'
    !sed -i s/\\\\begin{table/%\\\\begin{table/ `anything'
    !sed -i s/\\\\end{table/%\\\\end{table/ `anything'
    cat `anything'
end
            

*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
**# custom egen
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

/* custom egen */
/* from friosavila https://www.statalist.org/forums/forum/general-stata-discussion/general/1598944 */
capture program drop mygen
program mygen,   sortpreserve
   syntax anything(equalok) [if] [in] , [* weights(varname) by(varlist) ]
    ** parse
    gettoken  y rest:0 , parse("=")
    gettoken  rest rest:0 , parse("=")
    gettoken  fnc rest:rest, parse("(")
    gettoken  rest rest2:rest, parse(")")
    local fnc = strltrim(subinstr("`fnc'","=","",1))
    local rest = subinstr("`rest'","(","",.)
    local rest = subinstr("`rest'",")","",.)
    ** checks for varype
    if `:word count `y''==2 {
        tokenize `y'
        local vartype `1'
        local y       `2'
    }
    if `:word count `y''==1 {
        local vartype `=c(type)'
    }
    marksample touse, novarlist
    markout `touse' `weight' `by'
    _g`fnc' `vartype' `y' = `rest' if `touse', `options' by(`by')
end

capture program drop _gfun
program define _gfun
    di "_gfun" 
end

capture program drop _gfirstnonmissing
program define _gfirstnonmissing, sortpreserve
    syntax newvarname =/exp [if] [in],  ///
        BY(varname)                     /// /* by variable also used to sort */
        [SORT(varname)]                 /// /* will sort with "sort `by' `sort'" */
        [debug]                          // /* for debug */
    
    local exp = subinstr("`exp'"," ","",.) /* trim white spaces */
    if !mi("`debug'") di "exp: '`exp''"
    if !mi("`debug'") di "typlist: '`typlist''"
    if !mi("`debug'") di "namelist: '`varlist''"
    tempvar touse
    qui:gen byte `touse'=0
    qui:replace `touse'=1 `if' `in'
        
    * ignore user-supplied `type' and use same as `exp' variable
    local type : type `exp' 
    qui tempvar count
    sort `by' `sort'
    qui by `by' : gen `count' = sum(!missing(`exp')) if !missing(`exp') & `touse'
    bysort `by'  (`count') : gen `type' `varlist' = `exp'[1] if `touse' & !mi(`exp[1]')
end


