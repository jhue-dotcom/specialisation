global path "`c(pwd)'"
global tablepath "$path\outputv2"
global graphpath "$path\figuresv2"
cd "$path\cleaneddata"

set scheme stcolor


***************************************************************************************************************************************
*******************************************************Appendix A *********************************************************************
***************************************************************************************************************************************



***************************************************************************************************************************************
************************************************Table A1: Breakdown of Demographics****************************************************
***************************************************************************************************************************************


use data_full, clear
preserve
// Keep one observation per participant
bysort SID: keep if _n == 1
// -----------------------------------------------------------------------------
// 1. Define the four treatment-arm samples
// -----------------------------------------------------------------------------
local sample1 "TREAT == 1"  // NoExp-NoInfo
local sample2 "TREAT == 2"  // NoExp-Info
local sample3 "TREAT == 3"  // Exp-NoInfo
local sample4 "TREAT == 4"  // Exp-Info
// -----------------------------------------------------------------------------
// 2. Create category indicators and divide them across the two tables
//
// Table 1: Gender, Academic Year, and Nationality
// Table 2: School
// -----------------------------------------------------------------------------
local tablevars_1
local tablevars_2
local gender_first
local year_first
local course_first
local nationality_first
foreach v in PGender PYear PCourseSchool PNationalityGroup {
    levelsof `v' if !missing(`v'), local(levels)
    local vallab : value label `v'
    local first_in_block 1
    foreach value of local levels {
        tempvar indicator
        gen byte `indicator' = (`v' == `value') if !missing(`v')
        local category "`value'"
        if "`vallab'" != "" {
            local category : label `vallab' `value'
        }
        // Use the category name as the table row label
        label variable `indicator' "`category'"
        // Table 1: Gender, Academic Year, and Nationality
        if inlist("`v'", "PGender", "PYear", "PNationalityGroup") {
            local tablevars_1 "`tablevars_1' `indicator'"
        }
        // Table 2: School
        if "`v'" == "PCourseSchool" {
            local tablevars_2 "`tablevars_2' `indicator'"
        }
        // Record the first category in each block for section headings
        if `first_in_block' {
            if "`v'" == "PGender" {
                local gender_first `indicator'
            }
            if "`v'" == "PYear" {
                local year_first `indicator'
            }
            if "`v'" == "PCourseSchool" {
                local course_first `indicator'
            }
            if "`v'" == "PNationalityGroup" {
                local nationality_first `indicator'
            }
        }
        local first_in_block 0
    }
}
// -----------------------------------------------------------------------------
// 3. Table 1: Gender, Academic Year, and Nationality
// -----------------------------------------------------------------------------
eststo clear
eststo NoExpNoInfo: quietly estpost summarize `tablevars_1' if `sample1'
eststo NoExpInfo:   quietly estpost summarize `tablevars_1' if `sample2'
eststo ExpNoInfo:   quietly estpost summarize `tablevars_1' if `sample3'
eststo ExpInfo:     quietly estpost summarize `tablevars_1' if `sample4'
esttab NoExpNoInfo NoExpInfo ExpNoInfo ExpInfo ///
    using "$tablepath/Table_Demographics_1.tex", ///
    replace ///
    label ///
    cells(mean(fmt(3)) sd(par fmt(3))) ///
    mtitles("NoExp-NoInfo" "NoExp-Info" "Exp-NoInfo" "Exp-Info") ///
    collabels("mean/sd") ///
    refcat(`gender_first'      "Gender" ///
           `year_first'        "Academic Year" ///
           `nationality_first' "Nationality") ///
    nonotes ///
    booktabs
// -----------------------------------------------------------------------------
// 4. Table 2: School
// -----------------------------------------------------------------------------
eststo clear
eststo NoExpNoInfo: quietly estpost summarize `tablevars_2' if `sample1'
eststo NoExpInfo:   quietly estpost summarize `tablevars_2' if `sample2'
eststo ExpNoInfo:   quietly estpost summarize `tablevars_2' if `sample3'
eststo ExpInfo:     quietly estpost summarize `tablevars_2' if `sample4'
esttab NoExpNoInfo NoExpInfo ExpNoInfo ExpInfo ///
    using "$tablepath/Table_Demographics_2.tex", ///
    replace ///
    label ///
    cells(mean(fmt(3)) sd(par fmt(3))) ///
    mtitles("NoExp-NoInfo" "NoExp-Info" "Exp-NoInfo" "Exp-Info") ///
    collabels("mean/sd") ///
    refcat(`course_first' "School") ///
    nonotes ///
    booktabs
restore
	
//==============================================================================
// Joint balance tests across the four treatment conditions
// Null: demographic-category distributions are equal across TREAT = 1, 2, 3, 4
//==============================================================================

bysort SID: keep if _n == 1


foreach v in PGender PYear PCourseSchool PNationalityGroup PEthnicityGroup {

    di ""
    di as text "============================================================"
    di as text "Joint test across treatments: `v'"

    tabulate `v' TREAT, chi2

    di as result "Chi-square(" r(df) ") = " %6.2f r(chi2) ///
        ", p = " %6.3f r(p)
}
	

// Gender - p = 0.235
// Year - p = 0.496
// Course - p = 0.029
// Nationality - p = 0.027
// Ethnicity - p = 0.091


***************************************************************************************************************************************
**************************************************Figure A1: Inequality graphs*********************************************************
***************************************************************************************************************************************

use data_full, clear

xtile pct_rank_hard = Score if Difficult == 1, nq(10)
xtile pct_rank_easy = Score if Difficult == 0, nq(10)
gen pct_rank =  pct_rank_hard if Difficult == 1
replace  pct_rank =  pct_rank_easy if Difficult == 0


//Initial claim percentiles
sort(pct_rank_hard)
by pct_rank_hard: egen mean_percent0 = mean(InitialClaim) if Difficult == 1 

sort(pct_rank_easy)
by pct_rank_easy: egen mean_percent_easy0 = mean(InitialClaim) if Difficult == 0
replace mean_percent0 = mean_percent_easy0 if Difficult == 0


// Claim Percentiles
sort(pct_rank_hard)
by pct_rank_hard: egen mean_percent = mean(OwnClaimPercent) if Difficult == 1 

sort(pct_rank_easy)
by pct_rank_easy: egen mean_percent_easy = mean(OwnClaimPercent) if Difficult == 0
replace mean_percent = mean_percent_easy if Difficult == 0

//Round Earnings percentiles
sort(pct_rank_hard)
by pct_rank_hard: egen mean_earning = mean(RoundEarning) if Difficult == 1

sort(pct_rank_easy)
by pct_rank_easy: egen mean_earning_easy = mean(RoundEarning) if Difficult == 0
replace mean_earning = mean_earning_easy if Difficult == 0


replace pct_rank_easy = pct_rank - 0.2  // Shift Easy Task left
replace pct_rank_hard = pct_rank + 0.2  // Shift Hard Task right


graph twoway ///
   (bar mean_percent pct_rank_easy if Difficult == 0, barwidth(0.4) color(gs6) ) ///
   (bar mean_percent pct_rank_hard if Difficult == 1, barwidth(0.4) color(stc3) ), ///
   legend(label(1 "Easy Task") label(2 "Hard Task") bmargin(zero)) ///
   ytitle("Final Share (%) in Round", size(medium)) ///
   xtitle("") ///
   xlabel(1 "1" 2 "2" 3 "3" 4 "4" 5 "5" 6 "6" 7 "7" 8 "8" 9 "9" 10 "10", angle(45) labsize(medium)) ///
   legend(pos(6) col(2) size(medium)) ///
   name(A,replace)

graph display A, scale(1.2)   
graph export "$graphpath\FigureA1a.png", width(4000) replace
   
graph twoway ///
   (bar mean_earning pct_rank_easy if Difficult == 0, barwidth(0.4) color(gs6)) ///
   (bar mean_earning pct_rank_hard if Difficult == 1, barwidth(0.4) color(stc3)), ///
   legend(label(1 "Easy Task") label(2 "Hard Task")) ///
   ytitle("Final Payoff (ECUs) in Round", size(medium)) ///
   xtitle("") ///
   xlabel(1 "1" 2 "2" 3 "3" 4 "4" 5 "5" 6 "6" 7 "7" 8 "8" 9 "9" 10 "10", angle(45) labsize(medium)) ///
   legend(pos(6) col(2) size(medium)) ///
   yscale(range(0 1800)) ///
   name(B,replace)

graph display B, scale(1.2)         `'
graph export "$graphpath\FigureA1b.png", width(4000) replace

***************************************************************************************************************************************




***************************************************************************************************************************************
***************************************************Table A2: Descriptive Statistics****************************************************
***************************************************************************************************************************************


//Descriptive statistics by task

use data_full, clear

//Set non-applicable observations to missing
replace OwnClaimPercent=. if Agreed==0
replace Harder_Task =. if Period>1
replace Self_MoreEffort =. if Period>1


gen Type2=2-Type //left to right difference

//Part 1
eststo clear 
by Type, sort: eststo: quietly estpost summarize Score InitialClaim OwnClaimPercent RoundEarning 
eststo: quietly estpost_clustered_diff Score InitialClaim OwnClaimPercent RoundEarning, by(Type2) cluster(SESSION) //SESSION CLUSTERS

esttab using "$tablepath/tableA2-1.tex", ///
    cells("mean(pattern(1 1 0) fmt(3)) b(star pattern(0 0 1) fmt(3))" "sd(par pattern(1 1 0)) se(pattern(0 0 1) par fmt(3))") ///
    starlevels(* 0.05 ** 0.01 *** 0.001) ///
    mtitles("Grid" "Slider" "Difference") ///
    label nodepvar nonote replace

//Part 2
eststo clear 
by Type, sort: eststo: quietly estpost summarize Harder_Task Self_MoreEffort 
eststo: quietly estpost_clustered_diff Harder_Task Self_MoreEffort, by(Type2) cluster(SESSION) //SESSION CLUSTERS

esttab using "$tablepath/tableA2-2.tex", ///
    cells("mean(pattern(1 1 0) fmt(3)) b(star pattern(0 0 1) fmt(3))" "sd(par pattern(1 1 0)) se(pattern(0 0 1) par fmt(3))") ///
    starlevels(* 0.05 ** 0.01 *** 0.001) ///
    mtitles("Grid" "Slider" "Difference") ///
    label nodepvar nonote replace


//Part 3
eststo clear

xtset SESSION

bysort PAIRID: assert _N == 2
bysort PAIRID: assert Type[1] != Type[2]

by PAIRID (Type), sort: gen SCORERATIO2=Score[1]/Score[2] //Grid Score/Slider Score

xtreg InitialClaim i.Type i.Type#c.SCORERATIO2, re vce(cluster SESSION)

//Extract values: Grid (1) and Slider (2)
local b1 = _b[1.Type#c.SCORERATIO2]
local v1 = _se[1.Type#c.SCORERATIO2]^2

local b2 = _b[2.Type#c.SCORERATIO2]
local v2 = _se[2.Type#c.SCORERATIO2]^2

//Calculate Diff in magnitude
quietly lincom 1.Type#c.SCORERATIO2 + 2.Type#c.SCORERATIO2 //one is positive and the other is negative so take the sum.
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

esttab est1 est2 est3 using "$tablepath/tableA2-3.tex", ///
    cells(b(star fmt(3)) se(par fmt(3))) ///
    starlevels(* 0.05 ** 0.01 *** 0.001) ///
    mtitles("Grid" "Slider" "Difference") ///
    collabels(none) ///
    nodepvar nonote replace


***************************************************************************************************************************************
**********************************************Figure A2 Distributions by easy and hard*************************************************
***************************************************************************************************************************************


use data_full, clear
twoway (hist Score if Difficult==0, start(10) width(5) fraction color(gs6%70)) (hist Score if Difficult==1, fraction start(10) width(5)  color(stc3%60)) , xscale(range(10 115))  xlabel(10 (20) 115) xtitle("")  subtitle("Score") legend(rows(1) order(1 "Easy Task" 2 "Hard Task") size(small)) name(A,replace) 
twoway (hist InitialClaim if Difficult==0, start(0) width(5) fraction color(gs6%70)) (hist InitialClaim if Difficult==1, fraction start(0) width(5)  color(stc3%60)) ,  subtitle("Initial Claims") xtitle("")  name(B,replace) 
twoway (hist OwnClaimPercent if Difficult==0 & Agreed==1, start(0) width(5) fraction color(gs6%70)) (hist OwnClaimPercent if Difficult==1 & Agreed==1, start(0) width(5) fraction color(stc3%60)), xtitle("")   subtitle("Final Share")  name(C,replace) 
twoway (hist RoundEarning if Difficult==0, start(100) width(100) fraction color(gs6%70)) (hist RoundEarning if Difficult==1, fraction start(100) width(100)  color(stc3%60)) ,  subtitle("Earnings") xtitle("")  name(D,replace) 
twoway (hist Harder_Task if Difficult==0  & Period==1, discrete fraction color(gs6%70)) (hist Harder_Task if Difficult==1 , discrete fraction color(stc3%60)), xtitle("")   subtitle("Own task is harder") xlabel(1(1)7)   name(E,replace) 
twoway (hist Self_MoreEffort if Difficult==0 & Period==1, discrete fraction color(gs6%70)) (hist Self_MoreEffort if Difficult==1, fraction discrete  color(stc3%60)) ,  subtitle("Put in more effort than counterpart") xtitle("") xlabel(1(1)7)  name(F,replace) 


grc1leg A B C D E F, legendfrom(A) name(G,replace) 
graph display G, xsize(18) ysize(10) scale(1.2)
graph export "$graphpath\FigureA2.png", width(4000) replace

//Tests of differences. 
reghdfe Score i.Difficult, vce(cluster easyID diffID) //p=0.000
reghdfe InitialClaim i.Difficult, vce(cluster easyID diffID) //p=0.000
reghdfe OwnClaimPercent i.Difficult if Agreed==1, vce(cluster easyID diffID) //p=0.000
reghdfe RoundEarning i.Difficult, vce(cluster easyID diffID) //p=0.000
reghdfe Harder_Task i.Difficult if Period==1, vce(cluster easyID diffID) //p=0.000
reghdfe Self_MoreEffort i.Difficult if Period==1, vce(cluster easyID diffID) //p=0.929


use data_full, clear

tab Score if Difficult==1 //90th percentile is around 42
tab Score if Difficult==0  //92 percent perform better than 42.

***************************************************************************************************************************************


***************************************************************************************************************************************
*********************************************Figure A3: Distributions by grid and slider***********************************************
***************************************************************************************************************************************



use data_full, clear
twoway (hist Score if Type==1, start(10) width(5) fraction color(gs2%90)) (hist Score if Type==2, fraction start(10) width(5)  color(stc4%50)) , xscale(range(10 115))  xlabel(10 (20) 115) xtitle("")  subtitle("Score") legend(rows(1) order(1 "Grid Task" 2 "Slider Task") size(small)) name(A,replace) 
twoway (hist InitialClaim if Type==1, start(0) width(5) fraction color(gs2%90)) (hist InitialClaim if Type==2, fraction start(0) width(5)  color(stc4%50)) ,  subtitle("Initial Claims") xtitle("")   name(B,replace) 
twoway (hist OwnClaimPercent if Type==1 & Agreed==1, start(0) width(5) fraction color(gs2%90)) (hist OwnClaimPercent if Type==2 & Agreed==1, start(0) width(5) fraction color(stc4%50)), xtitle("")   subtitle("Final Share")  name(C,replace) 
twoway (hist RoundEarning if Type==1, start(100) width(100) fraction color(gs2%90)) (hist RoundEarning if Type==2, fraction start(100) width(100)  color(stc4%50)) ,  subtitle("Earnings") xtitle("")   name(D,replace) 
twoway (hist Harder_Task if Type==1  & Period==1, discrete fraction color(gs2%90)) (hist Harder_Task if Type==2  & Period==1, discrete fraction color(stc4%50)), xtitle("")   subtitle("Own task is harder")  xlabel(1(1)7) name(E,replace) 
twoway (hist Self_MoreEffort if Type==1 & Period==1, discrete fraction color(gs2%90)) (hist Self_MoreEffort if Type==2 & Period==1, fraction discrete  color(stc4%50)) ,  subtitle("Put in more effort than counterpart") xtitle("") xlabel(1(1)7)  name(F,replace) 


grc1leg A B C D E F, legendfrom(A) name(G,replace) 
graph display G, xsize(18) ysize(10) scale(1.2)
graph export "$graphpath\FigureA3.png", width(4000) replace

//Tests of differences.
reghdfe Score i.Type, vce(cluster easyID diffID) //p=0.893
reghdfe InitialClaim i.Type, vce(cluster easyID diffID) //p=0.017
reghdfe OwnClaimPercent i.Type if Agreed==1, vce(cluster easyID diffID) //0.034
reghdfe RoundEarning i.Type, vce(cluster easyID diffID) //0.196
reghdfe Harder_Task i.Type if Period==1, vce(cluster easyID diffID) //p=0.974
reghdfe Self_MoreEffort i.Type if Period==1, vce(cluster easyID diffID) //p=0.033


***************************************************************************************************************************************


***************************************************************************************************************************************
***************************************Table A3: Treatment Effects on initial claims and final share***********************************
***************************************************************************************************************************************


use data_full, clear

xtset SESSION

//global control i1.DifficultyVersion i1.highexchange i.Period

global control "i.Type i.highexchange i.Period"


eststo clear
eststo: qui xtreg InitialClaim i1.Exposure i1.Info ib4.q_SCORERATIO PoolECU $control if Difficult==0, re vce(cluster SESSION) //test 1.Exposure = 1.Info 0.0462
eststo: qui xtreg InitialClaim i1.Exposure i1.Info ib4.q_SCORERATIO PoolECU $control  if Difficult==1,  re vce(cluster SESSION) //test 1.Exposure = 1.Info //p=0.3787
eststo: qui xtreg OwnClaimPercent i1.Exposure i1.Info ib4.q_SCORERATIO PoolECU $control  if Difficult==0 & Agreed==1, re vce(cluster SESSION) 

esttab using  "$tablepath/tableA3.tex", replace ///
    nogaps nobaselevels label se staraux onecell nonumbers fragment ///
    starlevels(* 0.10 ** 0.05 *** 0.01) ///
    indicate("Joint Earnings = PoolECU" "Round, Task, Exchange Rate Fixed effects = *.Type *.highexchange *.Period" , ///
             labels("\checkmark" " ")) ///
    cells("b(fmt(3) star)" "se(fmt(3) par)") ///
    mtitles("Initial Claims (Easy)" "Initial Claims (Hard)" "Final Share (Easy)") 


//Robustness:

reghdfe InitialClaim i1.Exposure i1.Info ib4.q_SCORERATIO PoolECU if Difficult==0, absorb($control) vce(cluster SESSION)
reghdfe InitialClaim i1.Exposure i1.Info ib4.q_SCORERATIO PoolECU if Difficult==1,  absorb($control) vce(cluster SESSION)
reghdfe OwnClaimPercent i1.Exposure i1.Info ib4.q_SCORERATIO PoolECU if Difficult==0 & Agreed==1,  absorb($control) vce(cluster SESSION) 

wildbootstrap reg InitialClaim i1.Exposure i1.Info ib4.q_SCORERATIO PoolECU i.Type i.highexchange i.Period if Difficult==0,  cluster(SESSION ) rseed(12345) test(1.Exposure = 1.Info)  errorweight(webb)
wildbootstrap reg InitialClaim i1.Exposure i1.Info ib4.q_SCORERATIO PoolECU i.Type i.highexchange i.Period if Difficult==1,  cluster(SESSION ) rseed(12345)
wildbootstrap reg OwnClaimPercent i1.Exposure i1.Info ib4.q_SCORERATIO PoolECU i.Type i.highexchange i.Period if Difficult==0,  cluster(SESSION ) rseed(12345)




***************************************************************************************************************************************


***************************************************************************************************************************************
*******************************************Table A4: Marginal effects on outcomes by quantitle*****************************************
***************************************************************************************************************************************


use data_full, clear

xtset SESSION

global control "i.Type i.highexchange i.Period"


eststo clear
eststo: qui xtreg InitialClaim ib4.q_SCORERATIO  i1.Exposure#i.q_SCORERATIO i1.Info#i.q_SCORERATIO PoolECU $control if Difficult==0, re vce(cluster SESSION)
eststo: qui xtreg InitialClaim ib4.q_SCORERATIO  i1.Exposure#i.q_SCORERATIO i1.Info#i.q_SCORERATIO PoolECU $control if Difficult==1, re vce(cluster SESSION)
eststo: qui xtreg OwnClaimPercent ib4.q_SCORERATIO  i1.Exposure#i.q_SCORERATIO i1.Info#i.q_SCORERATIO PoolECU $control if Difficult==0 & Agreed==1, re vce(cluster SESSION)
esttab using  "$tablepath/table_A4.tex", replace ///
    nogaps label se staraux onecell nonumbers fragment ///
    starlevels(* 0.10 ** 0.05 *** 0.01) ///
    indicate("Joint Earnings = PoolECU" "Round, Task, Exchange Rate Fixed effects = *.Type *.highexchange *.Period" , ///
             labels("\checkmark" " ")) ///
    cells("b(fmt(3) star)" "se(fmt(3) par)") ///
    mtitles("Initial Claims (Easy)" "Initial Claims (Hard)" "Final Share (Easy)") 


//Tests in main text:
qui xtreg InitialClaim ib4.q_SCORERATIO  i1.Exposure#i.q_SCORERATIO i1.Info#i.q_SCORERATIO PoolECU $control if Difficult==0, re vce(cluster SESSION)
lincom 1.Exposure#3.q_SCORERATIO //quantile 3: p=0.041
lincom 1.Exposure#4.q_SCORERATIO //quantile 4: p=0.046


//Robustness
reghdfe InitialClaim ib4.q_SCORERATIO  i1.Exposure#i.q_SCORERATIO i1.Info#i.q_SCORERATIO PoolECU if Difficult==0, absorb($control) vce(cluster SESSION)
reghdfe InitialClaim ib4.q_SCORERATIO  i1.Exposure#i.q_SCORERATIO i1.Info#i.q_SCORERATIO PoolECU if Difficult==1,  absorb($control) vce(cluster SESSION)
reghdfe OwnClaimPercent ib4.q_SCORERATIO  i1.Exposure#i.q_SCORERATIO i1.Info#i.q_SCORERATIO PoolECU if Difficult==0 & Agreed==1,  absorb($control) vce(cluster SESSION) 

wildbootstrap reg InitialClaim ib4.q_SCORERATIO  i1.Exposure#i.q_SCORERATIO i1.Info#i.q_SCORERATIO PoolECU i.Type i.highexchange i.Period if Difficult==0,  cluster(SESSION ) rseed(12345)
wildbootstrap reg InitialClaim ib4.q_SCORERATIO  i1.Exposure#i.q_SCORERATIO i1.Info#i.q_SCORERATIO PoolECU i.Type i.highexchange i.Period if Difficult==1,  cluster(SESSION ) rseed(12345)
wildbootstrap reg OwnClaimPercent ib4.q_SCORERATIO  i1.Exposure#i.q_SCORERATIO i1.Info#i.q_SCORERATIO PoolECU i.Type i.highexchange i.Period if Difficult==0,  cluster(SESSION ) rseed(12345)


/*
//negligible session random effects
mixed InitialClaim  ||SESSION: || easyID: if Difficult==0
mixed InitialClaim  ||SESSION: || diffID: if Difficult==1
*/



***************************************************************************************************************************************

***************************************************************************************************************************************
*******************************************Table A4: Marginal effects on outcomes by round ********************************************
***************************************************************************************************************************************


use data_full, clear

xtset SESSION

global control "i.Type i.highexchange i.Period"

eststo clear


********************************************************************************
* Easy taskers
********************************************************************************

eststo PB_Easy: xtreg InitialClaim 1.Exposure#ib1.Period  1.Info#ib1.Period  ib4.q_SCORERATIO PoolECU  $control if Difficult==0, re vce(cluster SESSION)


********************************************************************************
* Hard taskers
********************************************************************************

eststo PB_Hard: xtreg InitialClaim 1.Exposure#ib1.Period 1.Info#ib1.Period ib4.q_SCORERATIO PoolECU $control if Difficult==1,  re vce(cluster SESSION)



********************************************************************************
* Export
********************************************************************************

esttab PB_Easy PB_Hard using "$tablepath/tableA5.tex", replace ///
    nogaps label nonumbers fragment ///
    starlevels(* 0.10 ** 0.05 *** 0.01) ///
    coeflabels( ///
        1.Exposure#1.Period "Exposure $\times$ Round 1" ///
        1.Exposure#2.Period "Exposure $\times$ Round 2" ///
        1.Exposure#3.Period "Exposure $\times$ Round 3" ///
        1.Exposure#4.Period "Exposure $\times$ Round 4" ///
        1.Exposure#5.Period "Exposure $\times$ Round 5" ///
        1.Exposure#6.Period "Exposure $\times$ Round 6" ///
        1.Info#1.Period "Information $\times$ Round 1" ///
        1.Info#2.Period "Information $\times$ Round 2" ///
        1.Info#3.Period "Information $\times$ Round 3" ///
        1.Info#4.Period "Information $\times$ Round 4" ///
        1.Info#5.Period "Information $\times$ Round 5" ///
        1.Info#6.Period "Information $\times$ Round 6" ///
    ) ///
    indicate( ///
        "Joint Earnings = PoolECU" ///
        "Round, Task, Exchange Rate Fixed effects = *.Type *.highexchange 1.Period 2.Period 3.Period 4.Period 5.Period 6.Period" ///
        "Score Ratio Fixed effects = *.q_SCORERATIO", ///
        labels("\checkmark" " ")) ///
    drop(_cons) ///
    cells("b(fmt(3) star)" "se(fmt(3) par)") ///
    mtitles("Easy Taskers" "Hard Taskers") 

***************************************************************************************************************************************



***************************************************************************************************************************************
***************************************************Table A6: FMM Raw Estimates*********************************************************
***************************************************************************************************************************************


do "$path/genFMM.do"


eststo clear
forvalues i=1/4{

estimates restore FMM_d0
eststo: xlincom (beta=/tb) (sig=/tsig) (SE=/tp`i'1) (NLE=/tp`i'2) (WLE=1-/tp`i'1-/tp`i'2),post
}

esttab using "$tablepath/tableA6_Easy.tex", starlevels(* 0.10 ** 0.05 *** 0.01) cells("b(fmt(3) star)" "se(fmt(3) par)") label se staraux onecell  nogaps replace mtitles("No Exp No Info" "No Exp Info" "Exp No Info" "Exp Info") coeflabels( beta "$\beta$" sig "$\sigma$" )



eststo clear
forvalues i=1/4{
estimates restore FMM_d0
eststo: xlincom (beta=/tb) (sig=/tsig) (SE=/th`i'1) (NLE=/th`i'2) (WLE=1-/th`i'1-/th`i'2), post
}
esttab using "$tablepath/tableA6_Hard.tex", starlevels(* 0.10 ** 0.05 *** 0.01) cells("b(fmt(3) star)" "se(fmt(3) par)") label se staraux onecell  nogaps replace mtitles("No Exp No Info" "No Exp Info" "Exp No Info" "Exp Info") coeflabels( beta "$\beta$" sig "$\sigma$" )



***************************************************************************************************************************************


***************************************************************************************************************************************
*******************************************Table A7: Regression like FMM Estimates*****************************************************
***************************************************************************************************************************************

//Note needs to be run after Table A5

estimates restore FMM_d0

//Easy tasker

global p13 "1 - /tp11 -/tp12 "
global p23 "1 - /tp21 -/tp22 "
global p33 "1 - /tp31 -/tp32 "
global p43 "1 - /tp41 -/tp42 "


eststo clear

//No interaction
forvalues i=1/2{

//i=1 is fraction of SE
//i=2 is fraction of NLE


//Exposure reduces the share of surface-level meritocrats among easy taskers by 14.3\% ($p=0.040$), mirroring the observed decline in their initial claims. In contrast, Information has no corresponding effect for easy taskers ($p=0.860$) -> see estimates in output

estimates restore FMM_d0
eststo: xlincom (Exposure= 0.5*(/tp4`i' - /tp2`i' ) + 0.5*( /tp3`i' - /tp1`i')) (Info= 0.5*(/tp4`i' - /tp3`i' ) + 0.5*( /tp2`i' - /tp1`i')) (Constant= 0.75* /tp1`i' + 0.25* /tp3`i' + 0.25* /tp2`i'-0.25* /tp4`i'), post
}


estimates restore FMM_d0
eststo: xlincom (Exposure= 0.5*(($p43) - ($p23) ) + 0.5*( ($p33) - ($p13))) (Info= 0.5*(($p43) - ($p33) ) + 0.5*( ($p23) - ($p13))) (Constant= 0.75*($p13) + 0.25*($p33) + 0.25*($p23)-0.25*($p43)) , post


esttab using "$tablepath/tableA7_regEASY.tex", starlevels(* 0.10 ** 0.05 *** 0.01) cells("b(fmt(3) star)" "se(fmt(3) par)") label se staraux onecell order(Exposure Info Constant)  nogaps replace mtitles("SE" "NLE" "WLE" "SE" "NLE" "WLE")


//Hard tasker


global h13 "1 - /th11 -/th12 "
global h23 "1 - /th21 -/th22 "
global h33 "1 - /th31 -/th32 "
global h43 "1 - /th41 -/th42 "

eststo clear


//No interaction
forvalues i=1/2{

estimates restore FMM_d0
eststo: xlincom (Exposure= 0.5*(/th4`i' - /th2`i' ) + 0.5*( /th3`i' - /th1`i')) (Info= 0.5*(/th4`i' - /th3`i' ) + 0.5*( /th2`i' - /th1`i')) (Constant= 0.75* /th1`i' + 0.25* /th3`i' + 0.25* /th2`i'-0.25* /th4`i'), post
}

estimates restore FMM_d0
eststo: xlincom (Exposure= 0.5*(($h43) - ($h23) ) + 0.5*( ($h33) - ($h13))) (Info= 0.5*(($h43) - ($h33) ) + 0.5*( ($h23) - ($h13))) (Constant= 0.75*($h13) + 0.25*($h33) + 0.25*($h23)-0.25*($h43)) , post


esttab using "$tablepath/tableA7_regHARD.tex", starlevels(* 0.10 ** 0.05 *** 0.01) cells("b(fmt(3) star)" "se(fmt(3) par)") label se staraux onecell  order(Exposure Info Constant)   nogaps replace mtitles("SE" "NLE" "WLE" "SE" "NLE" "WLE")




***************************************************************************************************************************************
****************************************************Table A8: Potential mechanisms*****************************************************
***************************************************************************************************************************************


use data_full, clear

xtset SESSION

gen Groupy = OIOSGrid-OIOSLine if Type==1
replace Groupy = OIOSLine-OIOSGrid if Type==2

by SID, sort: egen mean_SCORERATIO=mean(SCORERATIO)
by SID, sort: egen mean_PoolECU=mean(PoolECU)

//Post-experiment variables

xtile q_SCORERATIO2=mean_SCORERATIO , nquantiles(7) 


global control2 "i.Type i.highexchange i.q_SCORERATIO i.Period"
global control "i.Type i.highexchange i.q_SCORERATIO2"

eststo clear
eststo: qui xtreg Self_Better i1.Exposure i1.Info PoolECU $control2 if Difficult==0 , re vce(cluster SESSION) 
eststo: qui xtreg Self_MoreEffort i1.Exposure i1.Info PoolECU $control2 if Difficult==0 , re vce(cluster SESSION) 
eststo: qui xtreg Harder_Task i1.Exposure i1.Info mean_PoolECU $control if Difficult==0 & Period==1, re vce(cluster SESSION) 
eststo: qui xtreg Understand_Other i1.Exposure i1.Info mean_PoolECU $control if Difficult==0 & Period==1, re vce(cluster SESSION) 
eststo: qui xtreg Earn_More i1.Exposure i1.Info mean_PoolECU $control if Difficult==0 & Period==1, re vce(cluster SESSION) 
eststo: qui xtreg Affected_Past i1.Exposure i1.Info mean_PoolECU $control if Difficult==0 & Period==1, re vce(cluster SESSION) 
eststo: qui xtreg Hard_Agreement i1.Exposure i1.Info  mean_PoolECU $control if Difficult==0 & Period==1,re vce(cluster SESSION) 
eststo: qui xtreg Cooperation_Needed i1.Exposure i1.Info mean_PoolECU $control  if Difficult==0 & Period==1, re vce(cluster SESSION) 
eststo: qui xtreg IOS i1.Exposure i1.Info mean_PoolECU $control  if Difficult==0 & Period==1, re vce(cluster SESSION) 
eststo: qui xtreg Groupy i1.Exposure i1.Info mean_PoolECU $control  if Difficult==0 & Period==1, re vce(cluster SESSION) 
eststo: qui xtreg OIOSA i1.Exposure i1.Info mean_PoolECU $control  if Difficult==0 & Period==1, re vce(cluster SESSION) 

esttab using  "$tablepath/tableA8_EASY.tex", replace ///
    nogaps label se staraux onecell nonumbers fragment ///
    starlevels(* 0.10 ** 0.05 *** 0.01) ///
    keep(1.Exposure 1.Info _cons) ///
    cells("b(fmt(3) star)" "se(fmt(3) par)") ///
    mtitles("(1)" "(2)" "(3)" "(4)" "(5)" "(6)" "(7)" "(8)" "(9)" "(10)" "(11)") 


eststo clear
eststo: qui xtreg Self_Better i1.Exposure i1.Info PoolECU $control2 if Difficult==1 , re vce(cluster SESSION) 
eststo: qui xtreg Self_MoreEffort i1.Exposure i1.Info PoolECU $control2 if Difficult==1 , re vce(cluster SESSION) 
eststo: qui xtreg Harder_Task i1.Exposure i1.Info mean_PoolECU $control if Difficult==1 & Period==1, re vce(cluster SESSION) 
eststo: qui xtreg Understand_Other i1.Exposure i1.Info mean_PoolECU $control if Difficult==1 & Period==1, re vce(cluster SESSION) 
eststo: qui xtreg Earn_More i1.Exposure i1.Info mean_PoolECU $control if Difficult==1 & Period==1, re vce(cluster SESSION) 
eststo: qui xtreg Affected_Past i1.Exposure i1.Info mean_PoolECU $control if Difficult==1 & Period==1, re vce(cluster SESSION) 
eststo: qui xtreg Hard_Agreement i1.Exposure i1.Info  mean_PoolECU $control if Difficult==1 & Period==1, re vce(cluster SESSION) 
eststo: qui xtreg Cooperation_Needed i1.Exposure i1.Info mean_PoolECU $control  if Difficult==1 & Period==1, re vce(cluster SESSION) 
eststo: qui xtreg IOS i1.Exposure i1.Info mean_PoolECU $control  if Difficult==1 & Period==1,  re vce(cluster SESSION) 
eststo: qui xtreg Groupy i1.Exposure i1.Info mean_PoolECU $control  if Difficult==1 & Period==1, re vce(cluster SESSION) 
eststo: qui xtreg OIOSA i1.Exposure i1.Info mean_PoolECU $control  if Difficult==1 & Period==1,  re vce(cluster SESSION) 


esttab using  "$tablepath/tableA8_HARD.tex", replace ///
    nogaps label se staraux onecell nonumbers fragment ///
    starlevels(* 0.10 ** 0.05 *** 0.01) ///
    keep(1.Exposure 1.Info _cons) ///
    cells("b(fmt(3) star)" "se(fmt(3) par)") ///
    mtitles("(1)" "(2)" "(3)" "(4)" "(5)" "(6)" "(7)" "(8)" "(9)" "(10)" "(11)") 


//No differences in perceived difficulty of task by specialisation.
xtreg Harder_Task i.Difficult i.Type if Period==1, re  vce(cluster SESSION)
xtreg Self_MoreEffort  i.Difficult i.Type if Period==1, re  vce(cluster SESSION) 



***************************************************************************************************************************************
**************************Table A9: Controlling for task understanding vs controlling for deservingness********************************
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
eststo: qui xtreg InitialClaim i1.Exposure i1.Info ib4.q_SCORERATIO Harder_Task Understand_Other PoolECU $control if Difficult==0, re  vce(cluster SESSION) 
eststo: qui xtreg InitialClaim i1.Exposure i1.Info ib4.q_SCORERATIO IOS Groupy  PoolECU $control  if Difficult==0, re vce(cluster SESSION) 
eststo: qui xtreg InitialClaim i1.Exposure i1.Info ib4.q_SCORERATIO Earn_More PoolECU  $control  if Difficult==0, re vce(cluster SESSION) 
eststo: qui xtreg InitialClaim i1.Exposure i1.Info ib4.q_SCORERATIO Harder_Task Understand_Other PoolECU  $control  if Difficult==1, re vce(cluster SESSION) 
eststo: qui xtreg InitialClaim i1.Exposure i1.Info ib4.q_SCORERATIO IOS Groupy PoolECU $control  if Difficult==1,  re vce(cluster SESSION) 
eststo: qui xtreg InitialClaim i1.Exposure i1.Info ib4.q_SCORERATIO Earn_More PoolECU  $control  if Difficult==1,  re vce(cluster SESSION) 
esttab using  "$tablepath/tableA9.tex", replace ///
	nogaps nobaselevels label se staraux onecell nonumbers fragment ///
	starlevels(* 0.10 ** 0.05 *** 0.01) ///
	indicate("Joint Earnings = PoolECU" "Round, Task, Exchange Rate Fixed effects = *.Type *.highexchange *.Period" "Score ratio Fixed effects = *.q_SCORERATIO", ///
             labels("\checkmark" " ")) ///
	cells("b(fmt(3) star)" "se(fmt(3) par)") ///
	mtitles("Initial Claims (Easy)" "Initial Claims (Easy)" "Initial Claims (Easy)" "Initial Claims (Easy)" "Initial Claims (Easy)" "Initial Claims (Easy)") 


xtreg InitialClaim i1.Exposure i1.Info ib4.q_SCORERATIO IOS Groupy PoolECU $control if Difficult==0, re  vce(cluster SESSION) 


***************************************************************************************************************************************



***************************************************************************************************************************************
**********************************************Table A10: Treatment Effects on bargains**************************************************
***************************************************************************************************************************************


use data_full, clear

xtset SESSION

label values q_SCORERATIO QSCORE

//global control i1.DifficultyVersion i1.highexchange i.Period

global control "i.Type i.highexchange i.Period i.q_SCORERATIO"


eststo clear
eststo: xtreg BargainTime i1.Exposure i1.Info  PoolECU $control if Difficult==0  & Agreed==1, re vce(cluster SESSION)
eststo: xtreg nBargain i1.Exposure i1.Info  PoolECU $control if Difficult==0 & Agreed==1, re vce(cluster SESSION) 

esttab using  "$tablepath/tableA10.tex", replace ///
    nogaps nobaselevels label se staraux onecell nonumbers fragment ///
    starlevels(* 0.10 ** 0.05 *** 0.01) ///
    indicate("Joint Earnings = PoolECU" "Round, Task, Exchange Rate Fixed effects = *.Type *.highexchange *.Period" "Score Ratio Fixed effects = *.q_SCORERATIO" , ///
             labels("\checkmark" " ")) ///
    cells("b(fmt(3) star)" "se(fmt(3) par)") ///
    mtitles("Bargain Time" "# Bargains") 




***************************************************************************************************************************************


***************************************************************************************************************************************
**************************************************Table A11: Adjustments of claims*****************************************************
***************************************************************************************************************************************
use BARGAINdata_full,clear

global control "i.Type i.highexchange i.Period i.q_SCORERATIO"

xtset RID n
gen l_claimcompare=l.claimcompare


gen VALID=0 if l_claimcompare!=.
replace VALID =1 if Difficult==0 & l_claimcompare<=2 & l_claimcompare!=.
replace VALID =1 if Difficult==1 & l_claimcompare>=2 & l_claimcompare!=. 

tab VALID

drop adjustup
gen adjustup = 0
replace adjustup = 1 if ClaimPercent>l.ClaimPercent

xtset SESSION


eststo clear
eststo: xtreg adjustdown i.Exposure i.Info  PoolECU $control if Difficult==0 & VALID==1, re vce(cluster SESSION) 
eststo: xtreg adjustup i.Exposure i.Info PoolECU $control if Difficult==1 & VALID==1, re vce(cluster SESSION)


esttab using  "$tablepath/tableA11.tex", replace ///
    nogaps nobaselevels label se staraux onecell nonumbers fragment ///
    starlevels(* 0.10 ** 0.05 *** 0.01) ///
    indicate("Joint Earnings = PoolECU" "Round, Task, Exchange Rate Fixed effects = *.Type *.highexchange *.Period" "Score Ratio Fixed effects = *.q_SCORERATIO" , ///
             labels("\checkmark" " ")) ///
    cells("b(fmt(3) star)" "se(fmt(3) par)") ///
    mtitles("(1)" "(2)" "(3)" "(4)") 




***************************************************************************************************************************************


***************************************************************************************************************************************
**************************************Table A12: Treatment effects on productivity over time*******************************************
***************************************************************************************************************************************

use data_full,clear 

xtset SESSION

global control "i.Type i.highexchange"

bysort Exposure Difficult Type: egen STD_WarmUpScore2 = std(WarmUpScore)

by Difficult, sort: egen STD_Score=std(Score)

replace Period=Period-1

gen x=1

eststo clear 
eststo: xtreg STD_Score i.Exposure i.Info c.Period i.Exposure#c.Period i.Info#c.Period $control  if Difficult == 0, re vce(cluster SESSION)
eststo: xtreg STD_Score i.Exposure i.Info c.Period i.Exposure#c.Period i.Info#c.Period TrainingScore STD_WarmUpScore2 $control   if Difficult == 0, re vce(cluster SESSION)
eststo: xtreg STD_Score i.Exposure i.Info c.Period i.Exposure#c.Period i.Info#c.Period  $control  if Difficult == 1, re vce(cluster SESSION)
eststo: xtreg STD_Score i.Exposure i.Info c.Period i.Exposure#c.Period i.Info#c.Period TrainingScore STD_WarmUpScore2  $control  if Difficult == 1, re vce(cluster SESSION)
esttab using  "$tablepath/TableA12.tex", replace ///
    nogaps nobaselevels label se staraux onecell nonumbers fragment ///
    starlevels(* 0.10 ** 0.05 *** 0.01) ///
    indicate("Task, Exchange Rate Fixed Effects = *.Type *.highexchange" , labels("\checkmark" " "))  ///
    cells("b(fmt(3) star)" "se(fmt(3) par)") ///

xtreg STD_Score c.Period i.Exposure i.Info i.Exposure#c.Period i.Info#c.Period $control if Difficult == 0, re vce(cluster SESSION)
test 1.Exposure#c.Period==1.Info#c.Period //p=0.0701
test 1.Exposure==1.Info //p=0.6479



***************************************************************************************************************************************





***************************************************************************************************************************************
********************************************** Appendix B Robustness Analyses *******************************************************
**************************************************************************************************************************************


***************************************************************************************************************************************
*********************Table B1: Treatment Effects on initial claims and final share, with demographic controls**************************
***************************************************************************************************************************************

use data_full, clear

xtset SESSION

global control "i.Type i.highexchange i.Period"
 
global demographics "i.PGender i.PYear i.PCourseSchool i.PNationalityGroup"


eststo clear

eststo: quietly xtreg InitialClaim  i1.Exposure i1.Info ib4.q_SCORERATIO PoolECU $control $demographics if Difficult == 0, re vce(cluster SESSION)

eststo: quietly xtreg InitialClaim  i1.Exposure i1.Info ib4.q_SCORERATIO PoolECU $control $demographics if Difficult == 1, re vce(cluster SESSION)

eststo: quietly xtreg OwnClaimPercent i1.Exposure i1.Info ib4.q_SCORERATIO PoolECU $control $demographics if Difficult == 0 & Agreed == 1, re vce(cluster SESSION)

esttab using "$tablepath/tableB1.tex", replace ///
    nogaps nobaselevels label se staraux onecell nonumbers fragment ///
    starlevels(* 0.10 ** 0.05 *** 0.01) ///
    indicate("Joint Earnings = PoolECU" "Round, Task, Exchange Rate Fixed effects = *.Type *.highexchange *.Period" "Gender, Academic Year, School, Nationality Fixed effects = *.PGender *.PYear *.PCourseSchool *.PNationalityGroup",labels("\checkmark" " ")) ///
    cells("b(fmt(3) star)" "se(fmt(3) par)") ///
    mtitles("Initial Claims (Easy)" "Initial Claims (Hard)" "Final Share (Easy)") 



***************************************************************************************************************************************

***************************************************************************************************************************************
**************************Table B2: Marginal effects on outcomes by quantitle, with demographic controls*******************************
***************************************************************************************************************************************

use data_full, clear

xtset SESSION

global control "i.Type i.highexchange i.Period"
 
global demographics "i.PGender i.PYear i.PCourseSchool i.PNationalityGroup"


eststo clear


eststo: quietly xtreg InitialClaim  ib4.q_SCORERATIO i1.Exposure#i.q_SCORERATIO i1.Info#i.q_SCORERATIO PoolECU $control $demographics if Difficult == 0, re vce(cluster SESSION)

eststo: quietly xtreg InitialClaim  ib4.q_SCORERATIO i1.Exposure#i.q_SCORERATIO i1.Info#i.q_SCORERATIO PoolECU $control $demographics if Difficult == 1, re vce(cluster SESSION)

eststo: quietly xtreg OwnClaimPercent ib4.q_SCORERATIO i1.Exposure#i.q_SCORERATIO i1.Info#i.q_SCORERATIO PoolECU $control $demographics if Difficult == 0 & Agreed == 1, re vce(cluster SESSION)

esttab using "$tablepath/tableB2.tex", replace ///
    nogaps label se staraux onecell nonumbers fragment ///
    starlevels(* 0.10 ** 0.05 *** 0.01) ///
    indicate("Joint Earnings = PoolECU" "Round, Task, Exchange Rate Fixed effects = *.Type *.highexchange *.Period" "Gender, Academic Year, School, Nationality Fixed effects = *.PGender *.PYear *.PCourseSchool *.PNationalityGroup",labels("\checkmark" " ")) ///
    cells("b(fmt(3) star)" "se(fmt(3) par)") ///
    mtitles("Initial Claims (Easy)" "Initial Claims (Hard)" "Final Share (Easy)") 






***************************************************************************************************************************************
**************************Table B3: Robustness specifications, different clustering methods and p-value *******************************
***************************************************************************************************************************************

//Robustness specifications: Initial Easy

use data_full, clear
xtset SESSION

global controls "ib4.q_SCORERATIO PoolECU i.Type i.highexchange i.Period"

eststo clear


*------------------------------------------------------------
* (1) Session RE + session-clustered SE
*------------------------------------------------------------
eststo: xtreg InitialClaim i1.Exposure i1.Info $controls if Difficult==0,  re vce(cluster SESSION)

*------------------------------------------------------------
* (2) OLS + two-way clustered SE
*------------------------------------------------------------
eststo: regress InitialClaim i1.Exposure i1.Info $controls if Difficult==0, vce(cluster easyID diffID)

*------------------------------------------------------------
* (3) OLS + session-clustered SE
*------------------------------------------------------------
eststo: regress InitialClaim i1.Exposure i1.Info $controls if Difficult==0, vce(cluster SESSION)

*------------------------------------------------------------
* (4) Same OLS coefficients, WCB inference: filled manually.
*------------------------------------------------------------

wildbootstrap regress InitialClaim  i1.Exposure i1.Info $controls if Difficult==0, cluster(SESSION)  errorweight(webb) reps(9999)  rseed(12345) coefficients(1.Exposure 1.Info)


******************************************************

esttab using "$tablepath/robust_easy.tex", replace ///
    keep(1.Exposure 1.Info) ///
    order(1.Exposure 1.Info) ///
    indicate("Joint Earnings = PoolECU" "Round, Task, Exchange Rate Fixed effects = *.Type *.highexchange *.Period" "Score Ratio Fixed effects= *.q_SCORERATIO" , ///
             labels("\checkmark" " ")) ///
    coeflabels(1.Exposure "Exposure" ///
               1.Info "Information") ///
    cells("b(fmt(3) star)" "se(fmt(3) par)") ///
    starlevels(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("Session RE" ///
            "OLS: Two-way" ///
            "OLS: Session") ///
    nonumbers fragment nogaps


***************************************************************************************************************************************

//Robustness specifications: Initial Hard

use data_full, clear
xtset SESSION

global controls "ib4.q_SCORERATIO PoolECU i.Type i.highexchange i.Period"

eststo clear


*------------------------------------------------------------
* (1) Session RE + session-clustered SE
*------------------------------------------------------------
eststo: xtreg InitialClaim i1.Exposure i1.Info $controls if Difficult==1,  re vce(cluster SESSION)

*------------------------------------------------------------
* (2) OLS + two-way clustered SE
*------------------------------------------------------------
eststo: regress InitialClaim i1.Exposure i1.Info $controls if Difficult==1, vce(cluster easyID diffID)

*------------------------------------------------------------
* (3) OLS + session-clustered SE
*------------------------------------------------------------
eststo: regress InitialClaim i1.Exposure i1.Info $controls if Difficult==1, vce(cluster SESSION)

*------------------------------------------------------------
* (4) Same OLS coefficients, WCB inference: filled manually.
*------------------------------------------------------------

wildbootstrap regress InitialClaim  i1.Exposure i1.Info $controls if Difficult==1, cluster(SESSION)  errorweight(webb) reps(9999)  rseed(12345) coefficients(1.Exposure 1.Info)


******************************************************

esttab using "$tablepath/robust_hard.tex", replace ///
    keep(1.Exposure 1.Info) ///
    order(1.Exposure 1.Info) ///
    indicate("Joint Earnings = PoolECU" "Round, Task, Exchange Rate Fixed effects = *.Type *.highexchange *.Period" "Score Ratio Fixed effects= *.q_SCORERATIO" , ///
             labels("\checkmark" " ")) ///
    coeflabels(1.Exposure "Exposure" ///
               1.Info "Information") ///
    cells("b(fmt(3) star)" "se(fmt(3) par)") ///
    starlevels(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("Session RE" ///
            "OLS: Two-way" ///
            "OLS: Session") ///
    nonumbers fragment nogaps



***************************************************************************************************************************************


//Robustness specifications: Final Easy

use data_full, clear
xtset SESSION

global controls "ib4.q_SCORERATIO PoolECU i.Type i.highexchange i.Period"

eststo clear


*------------------------------------------------------------
* (1) Session RE + session-clustered SE
*------------------------------------------------------------
eststo: xtreg OwnClaimPercent i1.Exposure i1.Info $controls if Difficult==0 & Agreed==1,  re vce(cluster SESSION)

*------------------------------------------------------------
* (2) OLS + two-way clustered SE
*------------------------------------------------------------
eststo: regress OwnClaimPercent i1.Exposure i1.Info $controls if Difficult==0 & Agreed==1, vce(cluster easyID diffID)

*------------------------------------------------------------
* (3) OLS + session-clustered SE
*------------------------------------------------------------
eststo: regress OwnClaimPercent i1.Exposure i1.Info $controls if Difficult==0 & Agreed==1, vce(cluster SESSION)

*------------------------------------------------------------
* (4) Same OLS coefficients, WCB inference: filled manually.
*------------------------------------------------------------

wildbootstrap regress OwnClaimPercent  i1.Exposure i1.Info $controls if Difficult==0 & Agreed==1, cluster(SESSION)  errorweight(webb) reps(9999)  rseed(12345) coefficients(1.Exposure 1.Info)


******************************************************

esttab using "$tablepath/robust_easy_FINAL.tex", replace ///
    keep(1.Exposure 1.Info) ///
    order(1.Exposure 1.Info) ///
    indicate("Joint Earnings = PoolECU" "Round, Task, Exchange Rate Fixed effects = *.Type *.highexchange *.Period" "Score Ratio Fixed effects= *.q_SCORERATIO" , ///
             labels("\checkmark" " ")) ///
    coeflabels(1.Exposure "Exposure" ///
               1.Info "Information") ///
    cells("b(fmt(3) star)" "se(fmt(3) par)") ///
    starlevels(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("Session RE" ///
            "OLS: Two-way" ///
            "OLS: Session") ///
    nonumbers fragment nogaps



***************************************************************************************************************************************


//Robustness specifications: Bargaining

use data_full, clear
xtset SESSION

global controls "ib4.q_SCORERATIO PoolECU i.Type i.highexchange i.Period"

eststo clear


*------------------------------------------------------------
* (1) Session RE + session-clustered SE
*------------------------------------------------------------
eststo: xtreg nBargain i1.Exposure i1.Info $controls if Difficult==0 & Agreed==1,  re vce(cluster SESSION)

*------------------------------------------------------------
* (2) OLS + two-way clustered SE
*------------------------------------------------------------
eststo: regress nBargain i1.Exposure i1.Info $controls if Difficult==0 & Agreed==1, vce(cluster easyID diffID)

*------------------------------------------------------------
* (3) OLS + session-clustered SE
*------------------------------------------------------------
eststo: regress nBargain i1.Exposure i1.Info $controls if Difficult==0 & Agreed==1, vce(cluster SESSION)

*------------------------------------------------------------
* (4) Same OLS coefficients, WCB inference: filled manually.
*------------------------------------------------------------

wildbootstrap regress nBargain i1.Exposure i1.Info $controls if Difficult==0 & Agreed==1, cluster(SESSION)  errorweight(webb) reps(9999)  rseed(12345) coefficients(1.Exposure 1.Info)


******************************************************

esttab using "$tablepath/robust_bargain.tex", replace ///
    keep(1.Exposure 1.Info) ///
    order(1.Exposure 1.Info) ///
    indicate("Joint Earnings = PoolECU" "Round, Task, Exchange Rate Fixed effects = *.Type *.highexchange *.Period" "Score Ratio Fixed effects= *.q_SCORERATIO" , ///
             labels("\checkmark" " ")) ///
    coeflabels(1.Exposure "Exposure" ///
               1.Info "Information") ///
    cells("b(fmt(3) star)" "se(fmt(3) par)") ///
    starlevels(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("Session RE" ///
            "OLS: Two-way" ///
            "OLS: Session") ///
    nonumbers fragment nogaps



***************************************************************************************************************************************

//Robustness specifications: Easy productivity


use data_full,clear 

xtset SESSION

bysort Exposure Difficult Type: egen STD_WarmUpScore2 = std(WarmUpScore)

by Difficult, sort: egen STD_Score=std(Score) // standardised productivity

replace Period=Period-1

global control "i.Type i.highexchange TrainingScore STD_WarmUpScore2"

eststo clear 

*------------------------------------------------------------
* (1) Session RE + session-clustered SE
*------------------------------------------------------------
eststo: xtreg STD_Score i.Exposure i.Info c.Period i.Exposure#c.Period i.Info#c.Period $control  if Difficult == 0, re vce(cluster SESSION)

*------------------------------------------------------------
* (2) OLS + two-way clustered SE
*------------------------------------------------------------
eststo: reg STD_Score i.Exposure i.Info c.Period i.Exposure#c.Period i.Info#c.Period $control  if Difficult == 0, vce(cluster easyID diffID)

*------------------------------------------------------------
* (3) OLS + session-clustered SE
*------------------------------------------------------------
eststo: reg STD_Score i.Exposure i.Info c.Period i.Exposure#c.Period i.Info#c.Period $control  if Difficult == 0, vce(cluster SESSION)

*------------------------------------------------------------
* (4) Same OLS coefficients, WCB inference: filled manually.
*------------------------------------------------------------

wildbootstrap reg STD_Score i.Exposure i.Info c.Period i.Exposure#c.Period i.Info#c.Period $control if Difficult == 0, cluster(SESSION) errorweight(webb) reps(9999)  rseed(12345) coefficients(1.Exposure#c.Period 1.Info#c.Period)


******************************************************

esttab using "$tablepath/robust_productivity_easy.tex", replace ///
    keep(1.Exposure#c.Period 1.Info#c.Period) ///
    order(1.Exposure#c.Period 1.Info#c.Period) ///
    indicate("Task, Exchange Rate Fixed Effects = *.Type *.highexchange" "Ability controls = STD_WarmUpScore2 TrainingScore" , labels("\checkmark" " "))  ///
    coeflabels(1.Exposure#c.Period "Exposure $\times$ Round" ///
               1.Info#c.Period "Information $\times$ Round") ///
    cells("b(fmt(3) star)" "se(fmt(3) par)") ///
    starlevels(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("Session RE" ///
            "OLS: Two-way" ///
            "OLS: Session") ///
    nonumbers fragment nogaps





***************************************************************************************************************************************

***************************************************************************************************************************************
*******************************Table B4: Marginal effects on outcomes by quantitle, with interactions**********************************
***************************************************************************************************************************************


use data_full, clear

xtset SESSION

global control "i.Type i.highexchange i.Period"

eststo clear
eststo: qui xtreg InitialClaim i1.Exposure##i1.Info ib4.q_SCORERATIO $control PoolECU if Difficult==0, re vce(cluster SESSION) 
eststo: qui xtreg InitialClaim i1.Exposure##i1.Info ib4.q_SCORERATIO $control PoolECU if Difficult==1,  re vce(cluster SESSION)
eststo: qui xtreg OwnClaimPercent i1.Exposure##i1.Info ib4.q_SCORERATIO $control PoolECU if Difficult==0 & Agreed==1, re vce(cluster SESSION) 

esttab using  "$tablepath/tableB4.tex", replace ///
    nogaps nobaselevels label se staraux onecell nonumbers fragment ///
    starlevels(* 0.10 ** 0.05 *** 0.01) ///
    indicate("Round, Task, Exchange Rate Fixed effects = *.Type *.highexchange *.Period" "Joint Earnings = PoolECU", labels("\checkmark" " "))  ///
    cells("b(fmt(3) star)" "se(fmt(3) par)") ///
    mtitles("Initial Claims (Easy)" "Initial Claims (Hard)" "Final Share (Easy)") 




***************************************************************************************************************************************


***************************************************************************************************************************************
************************* Appendix D: Minimum Distance Classification Robustness Analyses ********************************************
**************************************************************************************************************************************



***************************************************************************************************************************************
************************************************Figure D1: Types using minimum distance ***********************************************
***************************************************************************************************************************************

do "$path/genSimpleTypes.do"

do "$path/genSimpleTypesplot.do"

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


// Common settings
local xlab "xlabel(1 "Egalitarians" 2 `""Surface-level" "meritocrats""' 3 `""Weighted" "meritocrats""', noticks labsize(medsmall))"
local yax "ylabel(0(20)80, angle(0) labsize(medsmall) )"
local clean "plotregion(margin(b=0 t=3))"

//Figure C1: Plots of types (Simple classification)

//==============================================================================
// Generate subplots
//==============================================================================

// --- Panel 1: Easy Taskers - Exposure ---
preserve
keep if panel == 1

twoway (bar treat0 xpos0, barwidth(0.35) color("`col_noexp'") lpattern(dash) lcolor("`col_exp'") lwidth(medthick) ) ///
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

twoway (bar treat0 xpos0, barwidth(0.35) color("`col_noexp'") lpattern(dash) lcolor("`col_exp'") lwidth(medthick) ) ///
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

twoway (bar treat0 xpos0, barwidth(0.35) color("`col_noinfo'") lpattern(dash) lcolor("`col_info'") lwidth(medthick) ) ///
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

twoway (bar treat0 xpos0, barwidth(0.35) color("`col_noinfo'") lpattern(dash) lcolor("`col_info'") lwidth(medthick) ) ///
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



//Combine Easy panels
graph combine exp_easy info_easy, ///
    rows(2) colfirst ///
    imargin(tiny) ///
    graphregion(color(white) margin(0 0 0 0)) ///
    plotregion(margin(0 0 0 0)) ///
    xsize(5.5) ysize(7.5) ///
    name(panel_exp, replace) ///
    scale(1.4)

graph export "$graphpath/FigureD1a.png", as(png) width(4000) replace


//Combine Hard panels
graph combine exp_hard info_hard, ///
    rows(2) colfirst ///
    imargin(tiny) ///
    graphregion(color(white) margin(0 0 0 0)) ///
    plotregion(margin(0 0 0 0)) ///
    xsize(5.5) ysize(7.5) ///
    name(panel_info, replace) ///
    scale(1.4)


graph export "$graphpath/FigureD1b.png", as(png) width(4000) replace



***************************************************************************************************************************************

***************************************************************************************************************************************
**********************************************Table D1: Regression of types: minimum distance******************************************
***************************************************************************************************************************************


use data_full_wtypes, clear 

xtset SESSION

eststo clear
eststo: xtreg TYPE_ind21 i.Exposure i.Info if Difficult==0 & Period==1, re vce(cluster SESSION)
eststo: xtreg TYPE_ind22 i.Exposure i.Info if Difficult==0 & Period==1, re vce(cluster SESSION)
eststo: xtreg TYPE_ind23 i.Exposure i.Info if Difficult==0 & Period==1, re vce(cluster SESSION)
esttab using "$tablepath/tableD1-Easy.tex", starlevels(* 0.10 ** 0.05 *** 0.01) cells("b(fmt(3) star)" "se(fmt(3) par)") label se staraux onecell  nobaselevels nogaps replace mtitles("Egalitarian" "Surface-level" "Weighted")

eststo clear
eststo: xtreg TYPE_ind21 i.Exposure i.Info if Difficult==1 & Period==1, vce(cluster SESSION)
eststo: xtreg TYPE_ind22 i.Exposure i.Info if Difficult==1 & Period==1, vce(cluster SESSION)
eststo: xtreg TYPE_ind23 i.Exposure i.Info if Difficult==1 & Period==1, vce(cluster SESSION)
esttab using "$tablepath/tableD1-Hard.tex", starlevels(* 0.10 ** 0.05 *** 0.01) cells("b(fmt(3) star)" "se(fmt(3) par)") label se staraux onecell  nobaselevels nogaps replace mtitles("Egalitarian" "Surface-level" "Weighted")


***************************************************************************************************************************************




