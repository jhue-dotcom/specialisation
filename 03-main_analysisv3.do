global path "`c(pwd)'"
global tablepath "$path\outputv2"
global graphpath "$path\figuresv2"
cd "$path\cleaneddata"


set scheme stcolor

***************************************************************************************************************************************
************************************************ Table 1 Descriptive Statistics *******************************************************
***************************************************************************************************************************************


use data_full, clear


//Set non-applicable observations to missing
replace OwnClaimPercent=. if Agreed==0
replace Harder_Task =. if Period>1
replace Self_MoreEffort =. if Period>1

gen Easy=1-Difficult //to get left minus right order

//Part 1
eststo clear 
by Difficult, sort: eststo: quietly estpost summarize Score InitialClaim OwnClaimPercent RoundEarning 
eststo: quietly estpost_clustered_diff Score InitialClaim OwnClaimPercent RoundEarning, by(Easy) cluster(SESSION) //SESSION CLUSTERS

esttab using "$tablepath/table1-1.tex", ///
    cells("mean(pattern(1 1 0) fmt(3)) b(star pattern(0 0 1) fmt(3))" "sd(par pattern(1 1 0)) se(pattern(0 0 1) par fmt(3))") ///
    starlevels(* 0.05 ** 0.01 *** 0.001) ///
    mtitles("Easy" "Hard" "Difference") ///
    label nodepvar nonote replace

//Part 2
eststo clear 
by Difficult, sort: eststo: quietly estpost summarize Harder_Task Self_MoreEffort 
eststo: quietly estpost_clustered_diff Harder_Task Self_MoreEffort, by(Easy) cluster(SESSION) //SESSION CLUSTERS

esttab using "$tablepath/table1-2.tex", ///
    cells("mean(pattern(1 1 0) fmt(3)) b(star pattern(0 0 1) fmt(3))" "sd(par pattern(1 1 0)) se(pattern(0 0 1) par fmt(3))") ///
    starlevels(* 0.05 ** 0.01 *** 0.001) ///
    mtitles("Easy" "Hard" "Difference") ///
    label nodepvar nonote replace


//Part 3
eststo clear

xtset SESSION
xtreg InitialClaim i.Difficult i.Difficult#c.SCORERATIO, re vce(cluster SESSION) //p=0.000

//Extract values: Easy (1) and Hard (2)
local b1 = _b[0.Difficult#c.SCORERATIO]
local v1 = _se[0.Difficult#c.SCORERATIO]^2

local b2 = _b[1.Difficult#c.SCORERATIO]
local v2 = _se[1.Difficult#c.SCORERATIO]^2

//Calculate Diff in magnitude
lincom 0.Difficult#c.SCORERATIO + 1.Difficult#c.SCORERATIO 
local b3 = r(estimate)
local v3 = r(se)^2

forvalues i = 1/3 {
    matrix b = (`b`i'')
    matrix v = (`v`i'')
    matrix colnames b = "SCORERATIO"
    matrix colnames v = "SCORERATIO"
    matrix rownames v = "SCORERATIO"
    ereturn post b v
    eststo
}

esttab est1 est2 est3 using "$tablepath/table1-3.tex", ///
    cells(b(star fmt(3)) se(par fmt(3))) ///
    starlevels(* 0.05 ** 0.01 *** 0.001) ///
    mtitles("Easy Slope" "Hard Slope" "Difference") ///
    collabels(none) ///
    nodepvar nonote replace


***************************************************************************************************************************************
******************************* Figure 2: perceived fair shares under two meritocratic benchmarks. ***********************************
***************************************************************************************************************************************

* Figure 2: perceived fair shares under two meritocratic benchmarks.
*   average output ratio qbar_1/qbar_2 = 5
*   realized relative performance q_1/q_2 ranges from 0.5 to 15.
*
* Surface-level meritocracy (alpha = 0):
*   Easy share = r/(r+1); Hard share = 1/(r+1).
* Weighted meritocracy (alpha = 1):
*   Easy share = r/(r+rbar); Hard share = rbar/(r+rbar).

clear

local rbar = 5
local rmin = 0.5
local rmax = 15
local turning = sqrt(`rbar')
local xmax_plot = `rmax' - `rmin'
local turning_plot = `turning' - `rmin'
local rbar_plot = `rbar' - `rmin'
local turning_label = `turning_plot' + 0.28
local rbar_label = `rbar_plot' + 0.28

set obs 2001
gen double r = `rmin' + (`rmax' - `rmin') * (_n - 1) / (_N - 1)
* Affine plotting coordinate removes Stata's automatic zero padding.
* The published x axis has no numeric labels; all model calculations remain in r.
gen double plotx = r - `rmin'

gen double easy_a0 = 100 * r / (r + 1)
gen double easy_a1 = 100 * r / (r + `rbar')
gen double hard_a0 = 100 / (r + 1)
gen double hard_a1 = 100 * `rbar' / (r + `rbar')

assert abs(easy_a0 + hard_a0 - 100) < 1e-10
assert abs(easy_a1 + hard_a1 - 100) < 1e-10

quietly summarize easy_a0 if _n == 1
noi di as text "Calibration: qbar_1/qbar_2 = " as result %4.1f `rbar'
noi di as text "Turning point sqrt(qbar_1/qbar_2) = " as result %6.3f `turning'
noi di as text "Weighted shares at average relative performance: Easy = " ///
    as result %5.1f (100*`rbar'/(`rbar'+`rbar')) ///
    as text ", Hard = " as result %5.1f (100*`rbar'/(`rbar'+`rbar'))
noi di as text "Endpoint checks (r = 0.5, 15):"
noi di as text "  Easy alpha=0: " as result %5.1f easy_a0[1] " to " %5.1f easy_a0[_N]
noi di as text "  Easy alpha=1: " as result %5.1f easy_a1[1] " to " %5.1f easy_a1[_N]
noi di as text "  Hard alpha=0: " as result %5.1f hard_a0[1] " to " %5.1f hard_a0[_N]
noi di as text "  Hard alpha=1: " as result %5.1f hard_a1[1] " to " %5.1f hard_a1[_N]

set scheme s1color
graph set window fontface "Times New Roman"
graph set print fontface "Times New Roman"

local axiscolor "120 120 120"
local refln1 "20 20 20"
local refln2 "10 10 10"
local easy0 "198 198 198"
local hard0 "177 235 216"
local hard1 "84 164 138"


twoway ///
    (line easy_a0 plotx, sort lcolor("`easy0'") lpattern(longdash) lwidth(vthick)) ///
    (line easy_a1 plotx, sort lcolor(black) lpattern(solid) lwidth(vthick)), ///
    name(fig2_easy, replace) ///
    title("Panel A. Easy tasker", size(vlarge) color(black)) ///
    ytitle("Perceived fair share (%)", size(large)) ///
    xtitle("Observed Relative Performance ({it:q}{sub:1}/{it:q}{sub:2})", size(large)) ///
    yscale(range(0 100) lcolor("`axiscolor'") lwidth(thin)) ///
    ylabel(0(20)100, angle(horizontal) nogrid labsize(medlarge) tlcolor("`axiscolor'")) ///
    xscale(range(0 `xmax_plot') noextend lcolor("`axiscolor'") lwidth(thin)) ///
    xlabel(0 `xmax_plot', nolabels noticks) ///
    xline(`turning_plot', lcolor("`refln1'") lpattern(shortdash) lwidth(medthick)) ///
    xline(`rbar_plot', lcolor("`refln2'") lpattern(dot) lwidth(medthick)) ///
    text(13 `turning_label' "Turning point", orientation(vertical) size(medlarge) color("90 90 90")) ///
    text(9 `rbar_label' "q̄₁/q̄₂", orientation(vertical) size(medlarge) color("110 110 110")) ///
    legend(order(1 "{&alpha} = 0" 2 "{&alpha} = 1") cols(1) position(3) ring(0) ///
           size(medlarge) symxsize(8) region(lcolor(none) fcolor(none))) ///
    graphregion(color(white) margin(small)) ///
    plotregion(color(white) margin(zero))

twoway ///
    (line hard_a0 plotx, sort lcolor("`hard0'") lpattern(longdash) lwidth(vthick)) ///
    (line hard_a1 plotx, sort lcolor("`hard1'") lpattern(solid) lwidth(vthick)), ///
    name(fig2_hard, replace) ///
    title("Panel B. Hard tasker", size(vlarge) color(black)) ///
    ytitle(" ", color(white)) ///
    xtitle("Observed Relative Performance ({it:q}{sub:1}/{it:q}{sub:2})", size(large)) ///
    yscale(range(0 100) lcolor("`axiscolor'") lwidth(thin)) ///
    ylabel(0(20)100, angle(horizontal) nogrid labsize(medlarge) ///
           labcolor(white) tlcolor("`axiscolor'")) ///
    xscale(range(0 `xmax_plot') noextend lcolor("`axiscolor'") lwidth(thin)) ///
    xlabel(0 `xmax_plot', nolabels noticks) ///
    xline(`turning_plot', lcolor("`refln1'") lpattern(shortdash) lwidth(medthick)) ///
    xline(`rbar_plot', lcolor("`refln2'") lpattern(dot) lwidth(medthick)) ///
    text(13 `turning_label' "Turning point", orientation(vertical) size(medlarge) color("90 90 90")) ///
    text(9 `rbar_label' "q̄₁/q̄₂", orientation(vertical) size(medlarge) color("110 110 110")) ///
    legend(order(1 "{&alpha} = 0" 2 "{&alpha} = 1") cols(1) position(3) ring(0) ///
           size(medlarge) symxsize(8) region(lcolor(none) fcolor(none))) ///
    graphregion(color(white) margin(small)) ///
    plotregion(color(white) margin(zero))

graph combine fig2_easy fig2_hard, cols(2) ycommon xcommon ///
	iscale(*1.2) ///
    imargin(3 3 0 0) ///
    graphregion(color(white) margin(small)) ///
    name(Figure2_panels, replace) ///
    xsize(10.75) ysize(4.0) 

graph export "$graphpath\Figure2_panels.png", width(2406) replace


//Change graph scheme back
set scheme stcolor

***************************************************************************************************************************************


***************************************************************************************************************************************
****************************** Figure 3,5: Treatment effects on claims across score-ratio quantiles. ***********************************
***************************************************************************************************************************************

********************************************************************************
* Top row: Exposure effects; bottom row: Information effects
* Columns: Initial claims, Easy | Initial claims, Hard | Final claims, Easy
* Confidence bands are 95% intervals (approximately plus/minus one SE).
********************************************************************************

use data_full, clear

xtset SESSION

global control "i.Type i.highexchange i.Period"
label values q_SCORERATIO .
gen x = 1

* Aggregate treatment effects for the three outcome-by-role panels.
capture program drop make_effect_note
program define make_effect_note, rclass
    args treatment
    quietly lincom 1.`treatment'

    local b = r(estimate)
    local se = r(se)
    local p = r(p)

    local stars ""
    if `p' < .10 local stars "*"
    if `p' < .05 local stars "**"
    if `p' < .01 local stars "***"

    local b_fmt  : display %5.2f `b'
    local se_fmt : display %5.2f `se'

    return scalar p = `p'
    return scalar b = `b'
    return scalar se = `se'
    return local note "Pooled Effect: `b_fmt'`stars' (`se_fmt')"
end

* Initial claims: easy taskers
quietly xtreg InitialClaim i1.Exposure i1.Info ib4.q_SCORERATIO PoolECU $control if Difficult == 0 , re  vce(cluster SESSION)
make_effect_note Exposure
local easy_initial_exposure_note "`r(note)'"
make_effect_note Info
local easy_initial_info_note "`r(note)'"

* Initial claims: hard taskers
quietly xtreg InitialClaim i1.Exposure i1.Info ib4.q_SCORERATIO PoolECU $control if Difficult == 1 , re  vce(cluster SESSION)
make_effect_note Exposure
local hard_initial_exposure_note "`r(note)'"
make_effect_note Info
local hard_initial_info_note "`r(note)'"

* Final claims: easy taskers who reached agreement
quietly xtreg OwnClaimPercent  i1.Exposure i1.Info ib4.q_SCORERATIO PoolECU $control if Difficult == 0 & Agreed==1 , re  vce(cluster SESSION)
make_effect_note Exposure
local easy_final_exposure_note "`r(note)'"
make_effect_note Info
local easy_final_info_note "`r(note)'"


********************************************************************************
* Top row: Exposure effects
********************************************************************************

local LEVEL 95

* Upper left: Easy taskers' initial claims
xtreg InitialClaim i1.Exposure#i.q_SCORERATIO i1.Info#i.q_SCORERATIO ib4.q_SCORERATIO PoolECU $control if Difficult == 0 , re  vce(cluster SESSION)
margins Exposure, at(q_SCORERATIO=(1 2 3 4 5 6 7)) level(`LEVEL')
marginsplot, recastci(rarea) ///
    ci1opts(color(stc1%10) lwidth(none)) ///
    ci2opts(color(stc1%35) lwidth(none)) ///
    ytitle("") xtitle("") title("") subtitle("Exposure vs No Exposure", size(medium) margin(b=-2)) ///
    plotregion(margin(tiny)) yline(50, lcolor(gs8)) ///
    text(70 4 "`easy_initial_exposure_note'", placement(c) size(small) color(black)) ///
    plot1opts(lpattern(dash) msymbol(T) lcolor(stc1%60) mcolor(stc1%60)) ///
    plot2opts(lcolor(stc1) mcolor(stc1)) ///
    legend(off) name(EXP_EASY_INITIAL, replace) ///
    yscale(range(48 73)) ylabel(50(5)70)

* Upper middle: Hard taskers' initial claims
xtreg InitialClaim i1.Exposure#i.q_SCORERATIO i1.Info#i.q_SCORERATIO ib4.q_SCORERATIO PoolECU $control if Difficult == 1 , re  vce(cluster SESSION)
margins Exposure, at(q_SCORERATIO=(1 2 3 4 5 6 7)) level(`LEVEL')
marginsplot, recastci(rarea) ///
    ci1opts(color(stc1%10) lwidth(none)) ///
    ci2opts(color(stc1%35) lwidth(none)) ///
    ytitle("") xtitle("") title("") subtitle("Exposure vs No Exposure", size(medium) margin(b=-2)) ///
    plotregion(margin(tiny)) yline(50, lcolor(gs8)) ///
    text(60 4 "`hard_initial_exposure_note'", placement(c) size(small) color(black)) ///
    plot1opts(lpattern(dash) msymbol(T) lcolor(stc1%60) mcolor(stc1%60)) ///
    plot2opts(lcolor(stc1) mcolor(stc1)) ///
    legend(off) name(EXP_HARD_INITIAL, replace) ///
    yscale(range(38 63)) ylabel(40(5)60)

* Upper right: Easy taskers' final claims
xtreg OwnClaimPercent i1.Exposure#i.q_SCORERATIO i1.Info#i.q_SCORERATIO ib4.q_SCORERATIO PoolECU $control if Difficult == 0 & Agreed==1 , re  vce(cluster SESSION)
margins Exposure, at(q_SCORERATIO=(1 2 3 4 5 6 7)) level(`LEVEL')
marginsplot, recastci(rarea) ///
    ci1opts(color(stc1%10) lwidth(none)) ///
    ci2opts(color(stc1%35) lwidth(none)) ///
    ytitle("") xtitle("") title("") subtitle("Exposure vs No Exposure", size(medium) margin(b=-2)) ///
    plotregion(margin(tiny)) yline(50, lcolor(gs8)) ///
    text(65 4 "`easy_final_exposure_note'", placement(c) size(small) color(black)) ///
    plot1opts(lpattern(dash) msymbol(T) lcolor(stc1%60) mcolor(stc1%60)) ///
    plot2opts(lcolor(stc1) mcolor(stc1)) ///
    legend(off) name(EXP_EASY_FINAL, replace) ///
    yscale(range(43 68)) ylabel(45(5)65)

********************************************************************************
* Bottom row: Information effects
********************************************************************************

* Lower left: Easy taskers' initial claims
xtreg InitialClaim i1.Exposure#i.q_SCORERATIO i1.Info#i.q_SCORERATIO ib4.q_SCORERATIO PoolECU $control if Difficult == 0 , re  vce(cluster SESSION)
margins Info, at(q_SCORERATIO=(1 2 3 4 5 6 7)) level(`LEVEL')
marginsplot, recastci(rarea) ///
    ci1opts(color(stc2%10) lwidth(none)) ///
    ci2opts(color(stc2%35) lwidth(none)) ///
    ytitle("") xtitle("") title("") subtitle("Information vs No Information", size(medium) margin(b=-2)) ///
    plotregion(margin(tiny)) yline(50, lcolor(gs8)) ///
    text(70 4 "`easy_initial_info_note'", placement(c) size(small) color(black)) ///
    plot1opts(lpattern(dash) msymbol(T) lcolor(stc2%60) mcolor(stc2%60)) ///
    plot2opts(lcolor(stc2) mcolor(stc2)) ///
    legend(off) name(INFO_EASY_INITIAL, replace) ///
    yscale(range(48 73)) ylabel(50(5)70)

* Lower middle: Hard taskers' initial claims
xtreg InitialClaim i1.Exposure#i.q_SCORERATIO i1.Info#i.q_SCORERATIO ib4.q_SCORERATIO PoolECU $control if Difficult == 1 , re  vce(cluster SESSION)
margins Info, at(q_SCORERATIO=(1 2 3 4 5 6 7)) level(`LEVEL')
marginsplot, recastci(rarea) ///
    ci1opts(color(stc2%10) lwidth(none)) ///
    ci2opts(color(stc2%35) lwidth(none)) ///
    ytitle("") xtitle("") title("") subtitle("Information vs No Information", size(medium) margin(b=-2)) ///
    plotregion(margin(tiny)) yline(50, lcolor(gs8)) ///
    text(60 4 "`hard_initial_info_note'", placement(c) size(small) color(black)) ///
    plot1opts(lpattern(dash) msymbol(T) lcolor(stc2%60) mcolor(stc2%60)) ///
    plot2opts(lcolor(stc2) mcolor(stc2)) ///
    legend(off) name(INFO_HARD_INITIAL, replace) ///
    yscale(range(38 63)) ylabel(40(5)60)

* Lower right: Easy taskers' final claims
xtreg OwnClaimPercent i1.Exposure#i.q_SCORERATIO i1.Info#i.q_SCORERATIO ib4.q_SCORERATIO PoolECU $control if Difficult == 0 & Agreed==1 , re  vce(cluster SESSION)
margins Info, at(q_SCORERATIO=(1 2 3 4 5 6 7)) level(`LEVEL')
marginsplot, recastci(rarea) ///
    ci1opts(color(stc2%10) lwidth(none)) ///
    ci2opts(color(stc2%35) lwidth(none)) ///
    ytitle("") xtitle("") title("") subtitle("Information vs No Information", size(medium) margin(b=-2)) ///
    plotregion(margin(tiny)) yline(50, lcolor(gs8)) ///
    text(65 4 "`easy_final_info_note'", placement(c) size(small) color(black)) ///
    plot1opts(lpattern(dash) msymbol(T) lcolor(stc2%60) mcolor(stc2%60)) ///
    plot2opts(lcolor(stc2) mcolor(stc2)) ///
    legend(off) name(INFO_EASY_FINAL, replace) ///
    yscale(range(43 68)) ylabel(45(5)65)


* Build a standalone legend graphic. The six data panels have legends off,
* so this is the only legend exported by this script.
twoway ///
    (scatteri . . . ., connect(l) msymbol(T) msize(*2) mcolor(stc1%60) lcolor(stc1%60) lwidth(*2) lpattern(dash)) ///
    (scatteri . . . ., connect(l) msymbol(O) msize(*2) mcolor(stc1) lcolor(stc1) lwidth(*2)) ///
    (scatteri . . . ., connect(l) msymbol(T) msize(*2) mcolor(stc2%60) lcolor(stc2%60) lwidth(*2) lpattern(dash)) ///
    (scatteri . . . ., connect(l) msymbol(O) msize(*2) mcolor(stc2) lcolor(stc2) lwidth(*2)), ///
    legend(order(1 "No exposure" 2 "Exposure" 3 "No information" 4 "Information") ///
        rows(1) position(6) ring(0) region(fcolor(none) lcolor(none)) size(*2)) ///
    xscale(off) yscale(off) xlabel(none) ylabel(none) ///
    graphregion(fcolor(white) lcolor(none)) plotregion(fcolor(white) lcolor(none)) ///
    xsize(16) ysize(2.4) name(Figure3_Legend, replace)

* Export each outcome-by-role column as a separate two-row graphic.  The
* final LaTeX figure can place these three graphics and the legend together.


graph combine EXP_EASY_INITIAL INFO_EASY_INITIAL, rows(2) cols(1) ///
    imargin(0 0 0 0) iscale(1.4) xsize(3.5) ysize(6.7) name(Figure3_InitialEasy, replace)
graph export "$graphpath\Figure3_InitialEasy.png", width(1800) replace

graph combine EXP_HARD_INITIAL INFO_HARD_INITIAL, rows(2) cols(1) ///
    imargin(0 0 0 0) iscale(1.4) xsize(3.5) ysize(6.7) name(Figure3_InitialHard, replace)
graph export "$graphpath\Figure3_InitialHard.png", width(1800) replace

graph combine EXP_EASY_FINAL INFO_EASY_FINAL, rows(1) cols(2) ///
    imargin(2 2 2 2) iscale(1.4) xsize(6.7) ysize(3.5) name(Figure3_FinalEasy, replace)
graph export "$graphpath\Figure5_FinalEasy.png", width(1800) replace

graph display Figure3_Legend
graph export "$graphpath\Figure3_Legend.png", width(4800) replace

***************************************************************************************************************************************




***************************************************************************************************************************************
************************************* Figure 4: Treatment effects on claims across rounds. ********************************************
***************************************************************************************************************************************

********************************************************************************
* Treatment effects on initial claims across rounds
* Easy taskers
********************************************************************************

use data_full, clear

xtset SESSION

global control "i.Type i.highexchange i.Period"

* Treatment effects allowed to vary by block.
* Period FE absorb the Block main effects.
xtreg InitialClaim 1.Exposure#ib1.Period 1.Info#ib1.Period ib4.q_SCORERATIO PoolECU $control if Difficult==0, re vce(cluster SESSION)

margins Period, dydx(Exposure) level(95)

marginsplot, ///
    recast(connected) ///
    recastci(rarea) ///
    ci1opts(color(stc1%35) lwidth(none)) ///
    ytitle("") ///
    xtitle("") ///
    xscale(range(.75 6.25)) ///
    yscale(range(-5.5 5)) ylabel(-5(1)5) ///
    yline(0, lcolor(gs8) lpattern(dash)) ///
    subtitle("Effects of Exposure") title("") ///
    plotopts(msymbol(O) msize(medlarge) mcolor(stc1) lcolor(stc1) lwidth(medthick) ) ///
    ciopts(lcolor(stc1) lwidth(medthin)) ///
    legend(off) ///
    name(Block_Exposure, replace)

margins Period, dydx(Info) level(95)

marginsplot, ///
    recast(connected) ///
    recastci(rarea) ///
    ci1opts(color(stc2%35) lwidth(none)) ///
    ytitle("") ///
    xtitle("") ///
    xscale(range(.75 6.25)) ///
    yscale(range(-5.5 5)) ylabel(-5(1)5) ///
    yline(0, lcolor(gs8) lpattern(dash)) ///
    subtitle("Effects of Information") title("") ///
    plotopts(msymbol(O) msize(medlarge) mcolor(stc2) lcolor(stc2) lwidth(medthick) ) ///
    ciopts(lcolor(stc2) lwidth(medthin)) ///
    legend(off) ///
    name(Block_Info, replace)


graph combine Block_Exposure Block_Info, ///
    imargin(0.5 0.5 0.5 0.5) ///
    rows(2) ///
    xsize(3.5) ysize(6.7) iscale(1.4) ///
    graphregion(color(white)) ///
    name(Block_Effects, replace)

graph export "$graphpath/Figure_BlockEffects_InitialEASY.png", ///
    width(4000) replace

***************************************************************************************************************************************

********************************************************************************
* Treatment effects on initial claims across rounds
* Hard taskers
********************************************************************************


use data_full, clear

xtset SESSION

global control "i.Type i.highexchange i.Period"

* Treatment effects allowed to vary by block.
* Period FE absorb the Block main effects.
xtreg InitialClaim 1.Exposure#ib1.Period 1.Info#ib1.Period ib4.q_SCORERATIO PoolECU $control if Difficult==1, re vce(cluster SESSION)

margins Period, dydx(Exposure) level(95)

marginsplot, ///
    recast(connected) ///
    recastci(rarea) ///
    ci1opts(color(stc1%35) lwidth(none)) ///
    ytitle("") ///
    xtitle("") ///
    xscale(range(.75 6.25)) ///
    yscale(range(-5.5 5)) ylabel(-5(1)5) ///
    yline(0, lcolor(gs8) lpattern(dash)) ///
    subtitle("Effects of Exposure") title("") ///
    plotopts(msymbol(O) msize(medlarge) mcolor(stc1) lcolor(stc1) lwidth(medthick) ) ///
    ciopts(lcolor(stc1) lwidth(medthin)) ///
    legend(off) ///
    name(Block_Exposure, replace)

margins Period, dydx(Info) level(95)

marginsplot, ///
    recast(connected) ///
    recastci(rarea) ///
    ci1opts(color(stc2%35) lwidth(none)) ///
    ytitle("") ///
    xtitle("") ///
    xscale(range(.75 6.25)) ///
    yscale(range(-5.5 5)) ylabel(-5(1)5) ///
    yline(0, lcolor(gs8) lpattern(dash)) ///
    subtitle("Effects of Information") title("") ///
    plotopts(msymbol(O) msize(medlarge) mcolor(stc2) lcolor(stc2) lwidth(medthick) ) ///
    ciopts(lcolor(stc2) lwidth(medthin)) ///
    legend(off) ///
    name(Block_Info, replace)


graph combine Block_Exposure Block_Info, ///
     imargin(0.5 0.5 0.5 0.5) ///
    rows(2) ///
    xsize(3.5) ysize(6.7) iscale(1.4) ///
    graphregion(color(white)) ///
    name(Block_Effects, replace)

graph export "$graphpath/Figure_BlockEffects_InitialHARD.png", ///
    width(4000) replace

***************************************************************************************************************************************


***************************************************************************************************************************************
****************************************************** Figure 6: FMM Types ************************************************************
***************************************************************************************************************************************
do "$path/genFMM.do"
do "$path/genFMMplot.do"


//==============================================================================
// Generate subplots
//==============================================================================


local col_noexp "stc1%20"    // light blue
local col_exp "stc1"       // dark blue
local col_noinfo "stc2%20"   // light pink
local col_info "stc2"       // dark pink

// Define colors RGB format
/*
local col_noexp "199 219 239"    // light blue
local col_exp "33 102 172"       // dark blue
local col_noinfo "252 206 206"   // light pink
local col_info "177 24 43"       // dark red
*/

// Common graph settings - MUCH LARGER FONTS
local xlab "xlabel(1 "Egalitarians" 2 `""Surface-level" "meritocrats""' 3 `""Weighted" "meritocrats""', noticks labsize(medsmall))"
local yax "ylabel(0(20)80, angle(0) labsize(medsmall))"
local clean "plotregion(margin(b=0 t=3))"


// --- Panel 1: Easy Taskers - Exposure ---
preserve
keep if panel == 1

twoway (bar treat0 xpos0, barwidth(0.35) color("`col_noexp'") lcolor("`col_exp'") lwidth(medthick) lpattern(dash)) ///
       (bar treat1 xpos1, barwidth(0.35) color("`col_exp'") lcolor(gs8) lwidth(vthin)) ///
       (scatter label0_pos xpos0, msymbol(none) mlabel(label0) mlabposition(0) mlabcolor(gs3) mlabsize(small)) ///
       (scatter label1_pos xpos1, msymbol(none) mlabel(label1) mlabposition(0) mlabcolor(gs3) mlabsize(small)), ///
       `xlab' `yax' ///
       ytitle("Percent", size(medsmall)) ///
       subtitle("Exposure vs No Exposure", size(medium) margin(b=0)) ///
       legend(off) ///
       `clean' ///
       xscale(range(0.5 3.5)) ///
       name(exp_easy, replace)
restore

// --- Panel 2: Hard Taskers - Exposure ---
preserve
keep if panel == 2

twoway (bar treat0 xpos0, barwidth(0.35) color("`col_noexp'") lcolor("`col_exp'") lwidth(medthick) lpattern(dash)) ///
       (bar treat1 xpos1, barwidth(0.35) color("`col_exp'") lcolor(gs8) lwidth(vthin)) ///
       (scatter label0_pos xpos0, msymbol(none) mlabel(label0) mlabposition(0) mlabcolor(gs3) mlabsize(small)) ///
       (scatter label1_pos xpos1, msymbol(none) mlabel(label1) mlabposition(0) mlabcolor(gs3) mlabsize(small)), ///
       `xlab' `yax' ///
       ytitle("Percent", size(medsmall)) ///
       subtitle("Exposure vs No Exposure", size(medium) margin(b=0)) ///
       legend(off) ///
       `clean' ///
       xscale(range(0.5 3.5)) ///
       name(exp_hard, replace)
restore

// --- Panel 3: Easy Taskers - Information ---
preserve
keep if panel == 3

twoway (bar treat0 xpos0, barwidth(0.35) color("`col_noinfo'") lcolor("`col_info'") lwidth(medthick) lpattern(dash)) ///
       (bar treat1 xpos1, barwidth(0.35) color("`col_info'") lcolor(gs8) lwidth(vthin)) ///
       (scatter label0_pos xpos0, msymbol(none) mlabel(label0) mlabposition(0) mlabcolor(gs3) mlabsize(small)) ///
       (scatter label1_pos xpos1, msymbol(none) mlabel(label1) mlabposition(0) mlabcolor(gs3) mlabsize(small)), ///
       `xlab' `yax' ///
       ytitle("Percent", size(medsmall)) ///
       subtitle("Information vs No Information", size(medium) margin(b=0)) ///
       legend(off) ///
       `clean' ///
       xscale(range(0.5 3.5)) ///
       name(info_easy, replace)
restore

// --- Panel 4: Hard Taskers - Information ---
preserve
keep if panel == 4

twoway (bar treat0 xpos0, barwidth(0.35) color("`col_noinfo'") lcolor("`col_info'") lwidth(medthick) lpattern(dash)) ///
       (bar treat1 xpos1, barwidth(0.35) color("`col_info'") lcolor(gs8) lwidth(vthin)) ///
       (scatter label0_pos xpos0, msymbol(none) mlabel(label0) mlabposition(0) mlabcolor(gs3) mlabsize(small)) ///
       (scatter label1_pos xpos1, msymbol(none) mlabel(label1) mlabposition(0) mlabcolor(gs3) mlabsize(small)), ///
       `xlab' `yax' ///
       ytitle("Percent", size(medsmall)) ///
       subtitle("Information vs No Information", size(medium) margin(b=0)) ///
       legend(off) ///
       `clean' ///
       xscale(range(0.5 3.5)) ///
       name(info_hard, replace)
restore

//==============================================================================
// Combine into final figure
//==============================================================================


graph combine exp_easy info_easy, ///
    rows(2) colfirst ///
    imargin(tiny) ///
    graphregion(color(white) margin(0 0 0 0)) ///
    plotregion(margin(0 0 0 0)) ///
    xsize(5.5) ysize(7.5) ///
    name(panel_exp, replace) ///
    scale(1.4)

graph export "$graphpath/FigureFMMEASY.png", as(png) width(4000) replace



graph combine exp_hard info_hard, ///
    rows(2) colfirst ///
    imargin(tiny) ///
    graphregion(color(white) margin(0 0 0 0)) ///
    plotregion(margin(0 0 0 0)) ///
    xsize(5.5) ysize(7.5) ///
    name(panel_info, replace) ///
    scale(1.4)

graph export "$graphpath/FigureFMMHARD.png", as(png) width(4000) replace

//==============================================================================
// Standalone legend for LaTeX assembly
//==============================================================================



twoway (bar treat0 xpos0 if 0, barwidth(0.35) color("`col_noexp'") lcolor("`col_exp'") lwidth(medthick) lpattern(dash)) ///
       (bar treat1 xpos1 if 0, barwidth(0.35) color("`col_exp'") lcolor(gs8) lwidth(vthin)) ///
       (bar treat0 xpos0 if 0, barwidth(0.35) color("`col_noinfo'") lcolor("`col_info'") lwidth(medthick) lpattern(dash)) ///
       (bar treat1 xpos1 if 0, barwidth(0.35) color("`col_info'") lcolor(gs8) lwidth(vthin)) ///
       , legend(order(1 "No exposure" 2 "Exposure" 3 "No information" 4 "Information") rows(1) ring(0) position(6)  region(fcolor(none) lcolor(none)) size(*2)) ///
        xscale(off) yscale(off) ///
        xlabel(none) ylabel(none) ///
        graphregion(fcolor(white) lcolor(none)) ///
        plotregion(fcolor(white) lcolor(none)) ///
        xsize(16) ysize(2.4) 

graph export "$graphpath/Figure6_Legend.png", ///
    as(png) width(4800) replace




***************************************************************************************************************************************
**************************************** Table 2: Controlling for mechanisms **********************************************************
***************************************************************************************************************************************



use data_full, clear

xtset SESSION

gen Groupy = OIOSGrid-OIOSLine if Type==1
replace Groupy = OIOSLine-OIOSGrid if Type==2

label var Groupy "Ingroup $-$ Outgroup Closeness"
label var Earn_More "My task should earn more"
label var Harder_Task "Own task is harder"
label var Understand_Other "Did not understand other's task"

global control "i.Type i.highexchange i.Period"



eststo clear
eststo: qui xtreg InitialClaim i1.Exposure i1.Info ib4.q_SCORERATIO PoolECU $control if Difficult==0, re  vce(cluster SESSION) 
eststo: qui xtreg InitialClaim i1.Exposure i1.Info ib4.q_SCORERATIO Harder_Task Understand_Other PoolECU $control  if Difficult==0, re vce(cluster SESSION) 
eststo: qui xtreg InitialClaim i1.Exposure i1.Info ib4.q_SCORERATIO IOS Groupy PoolECU $control  if Difficult==0, re vce(cluster SESSION) 
eststo: qui xtreg InitialClaim i1.Exposure i1.Info ib4.q_SCORERATIO Earn_More PoolECU  $control  if Difficult==0, re vce(cluster SESSION) 
esttab using  "$tablepath/tableMECHANISMS.tex", replace ///
    nogaps nobaselevels label se staraux onecell nonumbers fragment ///
    starlevels(* 0.10 ** 0.05 *** 0.01) ///
    indicate("Joint Earnings = PoolECU" "Round, Task, Exchange Rate Fixed effects = *.Type *.highexchange *.Period" "Score ratio Fixed effects = *.q_SCORERATIO" ///
            "Task-understanding controls =Harder_Task Understand_Other" "Closeness controls = IOS Groupy " "Perceived Deservingness control = Earn_More", ///
             labels("\checkmark" " ")) ///
    cells("b(fmt(3) star)" "se(fmt(3) par)") ///
    scalars("ll likelihood") ///
    mtitles("Easy Taskers" "Easy Taskers" "Easy Taskers" "Easy Taskers") ///
    postfoot("\begin{minipage}{0.98\textwidth} \footnotesize \vspace{1mm} Standard errors in parentheses clustered at session level. * 0.10 ** 0.05 *** 0.01. Score Ratio is computed by (Score of Easy Tasker/Score of Hard Tasker) and split into 7 quantiles. \end{minipage}") 





***************************************************************************************************************************************
************************************************** Figure 7: Other outcomes ***********************************************************
***************************************************************************************************************************************

//Other outcome figures


********************************************************************************
* MAIN-TEXT FIGURE: Bargaining and productivity
*
* Column 1: Bargaining
* Column 2: Easy-task productivity
* Column 3: Hard-task productivity
*
* Top row:    Effects of Exposure
* Bottom row: Effects of Information
********************************************************************************


********************************************************************************
* Colours
********************************************************************************

local col_noexp  "stc1%20"     // light blue
local col_exp    "stc1"        // dark blue
local col_noinfo "stc2%20"     // light pink
local col_info   "stc2"        // dark pink

********************************************************************************
* COLUMN 1: BARGAINING
********************************************************************************

use data_full, clear

* Keep one observation per pair
keep if Difficult==0

* Treat non-agreement as surviving beyond the bargaining window
replace BargainTime=320 if Agreed==0


*---------------------------------------------------------------------------
* Exposure
*---------------------------------------------------------------------------

preserve

cumul BargainTime if Exp==1, gen(expcmul)
replace expcmul = 1-expcmul

cumul BargainTime if Exp==0, gen(noexpcmul)
replace noexpcmul = 1-noexpcmul

stack expcmul BargainTime noexpcmul BargainTime, ///
    into(c BargainTime) wide clear

label variable expcmul   "Exposure"
label variable noexpcmul "No Exposure"

twoway ///
    (line noexpcmul BargainTime if BargainTime<=300, ///
        lcolor("`col_noexp'") lpattern(dash) sort) ///
    (line expcmul BargainTime if BargainTime<=300, ///
        lcolor("`col_exp'") sort), ///
    ytitle("Proportion of disagreed pairs") ///
    xtitle("Time (seconds)") ///
    title("") ///
    subtitle("Effects of Exposure", size(medium) margin(b=0)) ///
    legend( ///
        ring(0) position(3) ///
        cols(1) ///
        order(1 "No Exposure" 2 "Exposure") ///
        region(fcolor(none) lcolor(none)) ///
        size(small)) ///
    graphregion(color(white)) ///
    bgcolor(white) ///
    name(BARG_EXP, replace)

restore

*---------------------------------------------------------------------------
* Information
*---------------------------------------------------------------------------

preserve

cumul BargainTime if Info==1, gen(infocmul)
replace infocmul = 1-infocmul

cumul BargainTime if Info==0, gen(noinfocmul)
replace noinfocmul = 1-noinfocmul

stack infocmul BargainTime noinfocmul BargainTime, ///
    into(c BargainTime) wide clear

label variable infocmul   "Information"
label variable noinfocmul "No Information"

twoway ///
    (line noinfocmul BargainTime if BargainTime<=300, ///
        lcolor("`col_noinfo'") lpattern(dash) sort) ///
    (line infocmul BargainTime if BargainTime<=300, ///
        lcolor("`col_info'") sort), ///
    ytitle("Proportion of disagreed pairs") ///
    xtitle("Time (seconds)") ///
    title("") ///
    subtitle("Effects of Information", size(medium) margin(b=0)) ///
    legend( ///
        ring(0) position(3) ///
        cols(1) ///
        order(1 "No Info" 2 "Info") ///
        region(fcolor(none) lcolor(none)) ///
        size(small)) ///
    graphregion(color(white)) ///
    bgcolor(white) ///
    name(BARG_INFO, replace)

restore



*---------------------------------------------------------------------------
* Combine and export bargaining column
*---------------------------------------------------------------------------

graph combine BARG_EXP BARG_INFO, ///
    rows(2) cols(1) ///
    ycommon ///
    iscale(1.4) ///
    imargin(0.5 0.5 0.5 0.5) ///
    graphregion(color(white)) ///
    xsize(3.5) ysize(6.7) ///
    name(Figure_Bargaining, replace)

graph export "$graphpath\Figure_Bargaining.png", ///
    width(1800) replace


***************************************************************************************************************************************

********************************************************************************
* COLUMNS 2 AND 3: PRODUCTIVITY
********************************************************************************

use data_full, clear

* Add training-period observation, as in Figure A6
expand 2 if Period==1, gen(x)

replace Period=0 if x==1
replace Score=TrainingScore*2/3 if Period==0

xtset SID Period


************** Column 2 Easy task ***************

lgraph Score Period Exposure if Difficult==0, ///
    loptions( ///
        0 lpattern(dash) ///
          lcolor(stc1%20) ///
          mcolor(stc1%20) ///
          msymbol(t) ; ///
        1 lcolor(stc1) ///
          mcolor(stc1) ///
    ) ///
    legend( ///
        ring(0) position(5) ///
        region(fcolor(none) lcolor(none)) ///
        size(small)) ///
    ytitle("Score") ///
    xtitle("Round") ///
    xlabel(0 "Training" 1 "1" 2 "2" 3 "3" 4 "4" 5 "5" 6 "6") ///
    title("") ///
    subtitle("Effects of Exposure", size(medium) margin(b=0)) ///
    name(PROD_EASY_EXP, replace)


lgraph Score Period Info if Difficult==0, ///
    loptions( ///
        0 lpattern(dash) ///
          lcolor(stc2%20) ///
          mcolor(stc2%20) ///
          msymbol(t) ; ///
        1 lcolor(stc2) ///
          mcolor(stc2) ///
    ) ///
    legend( ///
        ring(0) position(5) ///
        region(fcolor(none) lcolor(none)) ///
        size(small)) ///
    ytitle("Score") ///
    xtitle("Round") ///
    xlabel(0 "Training" 1 "1" 2 "2" 3 "3" 4 "4" 5 "5" 6 "6") ///
    title("") ///
    subtitle("Effects of Information", size(medium) margin(b=0)) ///
    name(PROD_EASY_INFO, replace)

graph combine PROD_EASY_EXP PROD_EASY_INFO, ///
    rows(2) cols(1) ///
    ycommon ///
    iscale(1.4) ///
    imargin(0.5 0.5 0.5 0.5) ///
    graphregion(color(white)) ///
    xsize(3.5) ysize(6.7) ///
    name(Figure_Productivity_Easy, replace)

graph export "$graphpath\Figure_Productivity_Easy.png", ///
    width(1800) replace


***************************************************************************************************************************************

************** Column 3 Hard task ***************

use data_full, clear

* Add training-period observation, as in Figure A6
expand 2 if Period==1, gen(x)

replace Period=0 if x==1
replace Score=TrainingScore*2/3 if Period==0

xtset SID Period


lgraph Score Period Exposure if Difficult==1, ///
    loptions( ///
        0 lpattern(dash) ///
          lcolor(stc1%20) ///
          mcolor(stc1%20) ///
          msymbol(t) ; ///
        1 lcolor(stc1) ///
          mcolor(stc1) ///
    ) ///
    legend( ///
        ring(0) position(5) ///
        region(fcolor(none) lcolor(none)) ///
        size(small)) ///
    ytitle("Score") ///
    xtitle("Round") ///
    xlabel(0 "Training" 1 "1" 2 "2" 3 "3" 4 "4" 5 "5" 6 "6") ///
    title("") ///
    subtitle("Effects of Exposure", size(medium) margin(b=0)) ///
    name(PROD_HARD_EXP, replace)


lgraph Score Period Info if Difficult==1, ///
    loptions( ///
        0 lpattern(dash) ///
          lcolor(stc2%20) ///
          mcolor(stc2%20) ///
          msymbol(t) ; ///
        1 lcolor(stc2) ///
          mcolor(stc2) ///
    ) ///
    legend( ///
        ring(0) position(5) ///
        region(fcolor(none) lcolor(none)) ///
        size(small)) ///
    ytitle("Score") ///
    xtitle("Round") ///
    xlabel(0 "Training" 1 "1" 2 "2" 3 "3" 4 "4" 5 "5" 6 "6") ///
    title("") ///
    subtitle("Effects of Information", size(medium) margin(b=0)) ///
    name(PROD_HARD_INFO, replace)

graph combine PROD_HARD_EXP PROD_HARD_INFO, ///
    rows(2) cols(1) ///
    ycommon ///
    iscale(1.4) ///
    imargin(0.5 0.5 0.5 0.5) ///
    graphregion(color(white)) ///
    xsize(3.5) ysize(6.7) ///
    name(Figure_Productivity_Hard, replace)

graph export "$graphpath\Figure_Productivity_Hard.png", ///
    width(1800) replace


***************************************************************************************************************************************
*************************************************Other Tests cited in the text:********************************************************
***************************************************************************************************************************************

** The two initial claims exceed the available surplus in 77\% of pairs, although 96\% ultimately reach agreement before the bargaining time limit.
** In approximately 8\% of pairs, combined initial claims sum to less than 100\% and therefore also fail to produce agreement.
use data_full, clear


assert !missing(InitialClaim)

bysort SESSION Period Group: assert _N == 2
bysort SESSION Period Group: egen combined_initial = total(InitialClaim)
bysort SESSION Period Group: egen ultimately_agreed = max(Agreed)

gen initial_exceeds = combined_initial > 100
gen initial_below   = combined_initial < 100
gen initial_exact   = combined_initial == 100

bysort SESSION Period Group: keep if _n == 1

foreach x in initial_exceeds initial_below ultimately_agreed {
    quietly count if !missing(`x')
    local denominator = r(N)

    quietly count if `x' == 1
    local numerator = r(N)

    local percentage = 100 * `numerator' / `denominator'

    display as text "`x': " ///
        as result %5.1f `percentage' "% " ///
        as text "(" as result `numerator' "/" `denominator' as text ")"
}


***************************************************************************************************************************************

** across all performance deciles, easy taskers earn significantly more than hard taskers (p < 0.001).

use data_full, clear


xtile pct_rank_hard = Score if Difficult == 1, nq(10)
xtile pct_rank_easy = Score if Difficult == 0, nq(10)
gen pct_rank =  pct_rank_hard if Difficult == 1
replace  pct_rank =  pct_rank_easy if Difficult == 0

capture drop pct_rank_hard pct_rank_easy pct_rank

xtile pct_rank_hard = Score if Difficult == 1, nq(10)
xtile pct_rank_easy = Score if Difficult == 0, nq(10)

gen pct_rank = pct_rank_hard if Difficult == 1
replace pct_rank = pct_rank_easy if Difficult == 0

label variable pct_rank "Performance decile within task specialization"

local max_p = 0
local all_supported = 1

forvalues d = 1/10 {

    quietly reg OwnECU i.Difficult if pct_rank == `d', ///
        vce(cluster SESSION)

    quietly lincom -1.Difficult

    local b  = r(estimate)
    local se = r(se)
    local p  = r(p)

    display as text "Decile `d':  Easy - Hard = " ///
        as result %8.3f `b' ///
        as text "  SE = " as result %8.3f `se' ///
        as text "  p = " as result %8.5f `p'

    if (`p' > `max_p') {
        local max_p = `p'
        local max_decile = `d'
    }

    if (`b' <= 0 | `p' >= 0.001) {
        local all_supported = 0
    }
}

display as text "Largest p-value: " ///
    as result %8.5f `max_p' ///
    as text " (decile `max_decile')"


***************************************************************************************************************************************
**Hard taskers’ ratings are further from neutral than easy taskers’ ratings (p < 0.001)

use data_full, clear

//Set non-applicable observations to missing
replace Harder_Task =. if Period>1

reg Harder_Task i.Difficult, vce(cluster SESSION) 

//Absolute Difference from 4 for easy is 4 - _cons
//Absolute Difference from 4 for hard is _cons +1.Difficult - 4

//Difference in distance from neutral is (_cons +1.Difficult - 4) - (4 - _cons) = 1.Difficult + 2_cons - 8 

lincom  1.Difficult + 2*_cons - 8  //p=0.000


***************************************************************************************************************************************
** Tests for figure 3:

use data_full, clear

xtset SESSION

//global control i1.DifficultyVersion i1.highexchange i.Period

global control "i.Type i.highexchange i.Period"

*Exposure reduces easy taskers’ initial claims by 2.3 percentage points in the pooled specification
qui xtreg InitialClaim i1.Exposure i1.Info ib4.q_SCORERATIO PoolECU $control if Difficult==0, re vce(cluster SESSION)
lincom 1.Exposure //p=0.024

*Effects for easy taskers are most pronounced at intermediate levels of relative performance
qui xtreg InitialClaim ib4.q_SCORERATIO  i1.Exposure#i.q_SCORERATIO i1.Info#i.q_SCORERATIO PoolECU $control if Difficult==0, re vce(cluster SESSION)
lincom 1.Exposure#3.q_SCORERATIO //p=0.041
lincom 1.Exposure#4.q_SCORERATIO //p=0.046

*No significant effects for hard taskers
qui xtreg InitialClaim i1.Exposure i1.Info ib4.q_SCORERATIO PoolECU $control if Difficult==1, re vce(cluster SESSION)
lincom 1.Exposure //p=0.120

*No effects of information for either easy or hard
qui xtreg InitialClaim i1.Exposure i1.Info ib4.q_SCORERATIO PoolECU $control if Difficult==0, re vce(cluster SESSION)
lincom 1.Info //p=0.502

qui xtreg InitialClaim i1.Exposure i1.Info ib4.q_SCORERATIO PoolECU $control if Difficult==1, re vce(cluster SESSION)
lincom 1.Info //p=0.822


**The pooled effects of Exposure and Information differ for easy taskers (p = 0.046)

qui xtreg InitialClaim i1.Exposure i1.Info ib4.q_SCORERATIO PoolECU $control if Difficult == 0, re vce(cluster SESSION)
lincom 1.Exposure - 1.Info

***************************************************************************************************************************************
** Tests for figure 5:

use data_full, clear

xtset SESSION

//global control i1.DifficultyVersion i1.highexchange i.Period

global control "i.Type i.highexchange i.Period"

qui xtreg OwnClaimPercent i1.Exposure i1.Info ib4.q_SCORERATIO PoolECU $control  if Difficult==0 & Agreed==1, re vce(cluster SESSION) 

lincom 1.Exposure //p=0.051


***************************************************************************************************************************************
** Hard taskers disadvantaged for 98% of rounds
use data_full, clear

gen disadvantaged =0 if Difficult==1
replace disadvantaged=1 if SCORERATIO>1 & Difficult==1

sum disadvantaged //mean =0.977


***************************************************************************************************************************************
//Tests for nbargains

use data_full, clear

xtset SESSION

label values q_SCORERATIO QSCORE

//global control i1.DifficultyVersion i1.highexchange i.Period

global control "i.Type i.highexchange i.Period i.q_SCORERATIO"

qui xtreg nBargain i1.Exposure i1.Info  PoolECU $control if Difficult==0 & Agreed==1, re vce(cluster SESSION) 
lincom 1.Exposure //p=0.002


***************************************************************************************************************************************

use data_full, clear
keep if Period==1

**easy taskers tend to disagree that their task is more difficult (mean = 2.91), while hard taskers strongly agree (mean = 6.66), with the difference highly significant in all treatment arms 
mean Harder_Task, over(Difficult)

//p=0.0000 in all cases
ranksum Harder_Task if TREAT==1 , by(Difficult)
ranksum Harder_Task if TREAT==2 , by(Difficult)
ranksum Harder_Task if TREAT==3 , by(Difficult)
ranksum Harder_Task if TREAT==4 , by(Difficult)


//When asked who they would prefer as a third-party allocator, a majority of participants (87\%) indicated a preference for a “generalist”
tab Third_Party Type


//Participants are themselves aware of the importance of appreciation: they prefer working with partners who understand what their work is about and express a strong desire to experience their colleagues’ tasks. 
sum Tryout //5.38
sum Prefer_Working //6.02

//These preferences are particularly pronounced among hard taskers, consistent with their experience of being systematically disadvantaged.
ranksum Tryout, by(Difficult) //p=0.0000
ranksum Prefer_Working, by(Difficult) //p=0.0045


use data_full, clear

//In appendix:
sum SCORERATIO if Difficult==0 //mean is 1.822
gen X=0
replace X=1 if SCORERATIO >sqrt(`r(mean)')
sum X if Difficult==0 //84.7

***************************************************************************************************************************************
