*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*** MA: The health-wealth nexus over the life cycle
*** Au: Marcelo Rainho Avila (4679876)
*** Dt: 07.02.2024
*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

* Packages ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

/* check if packages installed, if not install them. Packages that are not within homonimous .ado file are checked
against their help file (sthlp) */
local list_of_packages tsegen.sthlp addplot binscatter csdid drdid carryforward coefplot distinct egenmore.sthlp ///
fillmissing fre heatplot indeplist kmatch missings /* moremata */ reghdfe rotate2 scatterfit vreverse winsor2 styletextab
foreach pack of local list_of_packages {
    di "`pack'"
    cap which `pack'
    di _rc
    if _rc == 111 {
        ssc install `pack'
    }
}

/* *  ColrSpace -- Mata class for color management
capt mata: ___S = ColrSpace()
if _rc == 3499  /* ColrSpace() not found */ {
    ssc install colrspace
} */

capt mata: ___S = mm_quantile()
if _rc == 3499  /* moremata (mm_quantile() is one of moremata's functions) not found */ ssc install moremata


* gtools Faster Stata for big data
cap which gtools
if _rc == 111 net install gtools, from("https://raw.githubusercontent.com/mcaceresb/stata-gtools/master/build/") replace
cap which ftools
if _rc == 111 net install ftools, from("https://github.com/sergiocorreia/ftools/raw/master/src/") replace

cap which mat2tex
if _rc == 111 net install mat2tex, from("https://raw.githubusercontent.com/avila/mat2tex/master/") replace

cap which traj 
if _rc == 111 net install traj, from("https://www.andrew.cmu.edu/user/bjones/traj/") replace

cap which binscatter2
if _rc == 111 net install binscatter2, from("https://raw.githubusercontent.com/mdroste/stata-binscatter2/master/") replace

cap which binsreg
if _rc == 111 net install binsreg, from("https://raw.githubusercontent.com/nppackages/binsreg/master/stata") replace

cap which tag
if _rc == 111 net install SOEPutils, from("https://git.soep.de/mavila/soeputils/-/raw/main") replace

cap which csdid2
if _rc == 111 net install csdid2, from("https://friosavila.github.io/stpackages") replace

cap which logging
if _rc == 111 net install logging, from("https://raw.githubusercontent.com/avila/logging/master/")

* cleanplots
cap which scheme-cleanplots.scheme
if _rc != 0 net install cleanplots, from("https://tdmize.github.io/data/cleanplots")
/* cleanplots has a good scheme that saves up spaces a bit */

*** Color palettes
cap which colorpalette
if _rc != 0 net install palettes, from("https://raw.githubusercontent.com/benjann/palettes/master/")
/* offers a wide range of color palettes */

cap which scheme-black_brbg.scheme /* random scheme from scheme pack to check if it is installed */
if _rc != 0 net install schemepack, from("https://raw.githubusercontent.com/asjadnaqvi/stata-schemepack/main/installation/") replace
