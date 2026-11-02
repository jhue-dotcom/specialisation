/*
global path "C:\Users\oeyno\Dropbox\Research\Labour Markets from a Behavioural Persepective\Stata"
global tablepath "$path\output"
global graphpath "$path\figures"
cd "$path\cleaneddata"
*/
/*
global path "C:\Users\hueju\Dropbox\Labour Markets from a Behavioural Persepective\Stata"
global tablepath "$path\output"
global graphpath "$path\figures"
cd "$path\cleaneddata"
*/
set scheme stcolor


***************************************************************************************************************************************
//Simple type classification.
use data_full,clear 

 gen given_mean = 14.5*2 if Difficult == 1 & Type == 1
 replace given_mean = 25*2 if Difficult == 0 & Type == 1
 replace given_mean = 15.6*2 if Difficult == 1 & Type == 2
 replace given_mean = 23*2 if Difficult == 0 & Type == 2
 
 gen given_opp_mean = 14.5*2 if Difficult == 0 & Type == 2
 replace given_opp_mean = 25*2 if Difficult == 1 & Type == 2
 replace given_opp_mean = 15.6*2 if Difficult == 0 & Type == 1
 replace given_opp_mean = 23*2 if Difficult == 1 & Type == 1



* Fairness benchmarks
gen fair_SE = 0.5
gen fair_SM = Score/(Score + OppScore)
gen fair_WM = ((Score/given_mean)/((Score/given_mean) + (OppScore/given_opp_mean)))

* Round-level absolute deviations
gen dev_SE = abs(InitialClaim/100 - fair_SE)
gen dev_SM = abs(InitialClaim/100 - fair_SM)
gen dev_WM = abs(InitialClaim/100 - fair_WM)

* Require six usable production rounds per participant
bysort SID: assert _N == 6
assert !missing(dev_SE, dev_SM, dev_WM)

* Individual-level mean absolute deviations
bysort SID: egen mean_dev_SE = mean(dev_SE)
bysort SID: egen mean_dev_SM = mean(dev_SM)
bysort SID: egen mean_dev_WM = mean(dev_WM)

* Check uniqueness of minimum
egen min_dev = rowmin(mean_dev_SE mean_dev_SM mean_dev_WM)
gen n_min = ///
    (abs(mean_dev_SE-min_dev)<1e-10) + ///
    (abs(mean_dev_SM-min_dev)<1e-10) + ///
    (abs(mean_dev_WM-min_dev)<1e-10)

bysort SID: assert n_min[1] == 1

* Classification
gen TYPE2 = 1 if mean_dev_SE == min_dev
replace TYPE2 = 2 if mean_dev_SM == min_dev
replace TYPE2 = 3 if mean_dev_WM == min_dev


label define T 1 "Equal" 2 "Surface-level" 3 "Weighted"
label values TYPE2 T

tab TYPE2, generate(TYPE_ind2) //Individual level

save data_full_wtypes, replace 


***************************************************************************************************************************************
