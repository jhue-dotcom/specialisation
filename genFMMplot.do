// Cell definitions:
//   Cell 1 = No Exposure, No Info
//   Cell 2 = No Exposure, Info
//   Cell 3 = Exposure, No Info
//   Cell 4 = Exposure, Info

//==============================================================================
// PART 1: Extract type probabilities for Easy Taskers
//==============================================================================

global p13 "1 - /tp11 - /tp12"
global p23 "1 - /tp21 - /tp22"
global p33 "1 - /tp31 - /tp32"
global p43 "1 - /tp41 - /tp42"

estimates restore FMM_d0

// Type 1: Egalitarians
nlcom (NoExp: 0.5*(/tp11 + /tp21)) ///
      (Exp: 0.5*(/tp31 + /tp41)) ///
      (NoInfo: 0.5*(/tp11 + /tp31)) ///
      (Info: 0.5*(/tp21 + /tp41)), post
local easy_noexp_eg = _b[NoExp] * 100
local easy_exp_eg = _b[Exp] * 100
local easy_noinfo_eg = _b[NoInfo] * 100
local easy_info_eg = _b[Info] * 100

// Type 2: Surface-level meritocrats
estimates restore FMM_d0
nlcom (NoExp: 0.5*(/tp12 + /tp22)) ///
      (Exp: 0.5*(/tp32 + /tp42)) ///
      (NoInfo: 0.5*(/tp12 + /tp32)) ///
      (Info: 0.5*(/tp22 + /tp42)), post
local easy_noexp_sl = _b[NoExp] * 100
local easy_exp_sl = _b[Exp] * 100
local easy_noinfo_sl = _b[NoInfo] * 100
local easy_info_sl = _b[Info] * 100

// Type 3: Weighted meritocrats
estimates restore FMM_d0
nlcom (NoExp: 0.5*(($p13) + ($p23))) ///
      (Exp: 0.5*(($p33) + ($p43))) ///
      (NoInfo: 0.5*(($p13) + ($p33))) ///
      (Info: 0.5*(($p23) + ($p43))), post
local easy_noexp_wt = _b[NoExp] * 100
local easy_exp_wt = _b[Exp] * 100
local easy_noinfo_wt = _b[NoInfo] * 100
local easy_info_wt = _b[Info] * 100

//==============================================================================
// PART 2: Extract type probabilities for Hard Taskers
//==============================================================================

global h13 "1 - /th11 - /th12"
global h23 "1 - /th21 - /th22"
global h33 "1 - /th31 - /th32"
global h43 "1 - /th41 - /th42"

// Type 1: Egalitarians
estimates restore FMM_d0
nlcom (NoExp: 0.5*(/th11 + /th21)) ///
      (Exp: 0.5*(/th31 + /th41)) ///
      (NoInfo: 0.5*(/th11 + /th31)) ///
      (Info: 0.5*(/th21 + /th41)), post
local hard_noexp_eg = _b[NoExp] * 100
local hard_exp_eg = _b[Exp] * 100
local hard_noinfo_eg = _b[NoInfo] * 100
local hard_info_eg = _b[Info] * 100

// Type 2: Surface-level meritocrats
estimates restore FMM_d0
nlcom (NoExp: 0.5*(/th12 + /th22)) ///
      (Exp: 0.5*(/th32 + /th42)) ///
      (NoInfo: 0.5*(/th12 + /th32)) ///
      (Info: 0.5*(/th22 + /th42)), post
local hard_noexp_sl = _b[NoExp] * 100
local hard_exp_sl = _b[Exp] * 100
local hard_noinfo_sl = _b[NoInfo] * 100
local hard_info_sl = _b[Info] * 100

// Type 3: Weighted meritocrats
estimates restore FMM_d0
nlcom (NoExp: 0.5*(($h13) + ($h23))) ///
      (Exp: 0.5*(($h33) + ($h43))) ///
      (NoInfo: 0.5*(($h13) + ($h33))) ///
      (Info: 0.5*(($h23) + ($h43))), post
local hard_noexp_wt = _b[NoExp] * 100
local hard_exp_wt = _b[Exp] * 100
local hard_noinfo_wt = _b[NoInfo] * 100
local hard_info_wt = _b[Info] * 100

//==============================================================================
// PART 3: Create dataset for plotting
//==============================================================================

clear
set obs 12

gen panel = .
gen type = .
gen treat0 = .
gen treat1 = .

// Easy Taskers - Exposure
replace panel = 1 in 1/3
replace type = 1 in 1
replace type = 2 in 2
replace type = 3 in 3
replace treat0 = `easy_noexp_eg' in 1
replace treat0 = `easy_noexp_sl' in 2
replace treat0 = `easy_noexp_wt' in 3
replace treat1 = `easy_exp_eg' in 1
replace treat1 = `easy_exp_sl' in 2
replace treat1 = `easy_exp_wt' in 3

// Hard Taskers - Exposure
replace panel = 2 in 4/6
replace type = 1 in 4
replace type = 2 in 5
replace type = 3 in 6
replace treat0 = `hard_noexp_eg' in 4
replace treat0 = `hard_noexp_sl' in 5
replace treat0 = `hard_noexp_wt' in 6
replace treat1 = `hard_exp_eg' in 4
replace treat1 = `hard_exp_sl' in 5
replace treat1 = `hard_exp_wt' in 6

// Easy Taskers - Information
replace panel = 3 in 7/9
replace type = 1 in 7
replace type = 2 in 8
replace type = 3 in 9
replace treat0 = `easy_noinfo_eg' in 7
replace treat0 = `easy_noinfo_sl' in 8
replace treat0 = `easy_noinfo_wt' in 9
replace treat1 = `easy_info_eg' in 7
replace treat1 = `easy_info_sl' in 8
replace treat1 = `easy_info_wt' in 9

// Hard Taskers - Information
replace panel = 4 in 10/12
replace type = 1 in 10
replace type = 2 in 11
replace type = 3 in 12
replace treat0 = `hard_noinfo_eg' in 10
replace treat0 = `hard_noinfo_sl' in 11
replace treat0 = `hard_noinfo_wt' in 12
replace treat1 = `hard_info_eg' in 10
replace treat1 = `hard_info_sl' in 11
replace treat1 = `hard_info_wt' in 12

// X positions for paired bars
gen xpos0 = type - 0.2
gen xpos1 = type + 0.2

// Label positions
gen label0_pos = treat0 + 2.5
gen label1_pos = treat1 + 2.5

// String labels
gen label0 = string(treat0, "%3.1f")
gen label1 = string(treat1, "%3.1f")

***************************************************************************************************************************************
