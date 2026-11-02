

use data_full_wtypes, clear 
keep if Period==1

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
local yax "ylabel(0(20)80, angle(0) labsize(medsmall) nogrid)"
local clean "plotregion(margin(b=0 t=3))"

//==============================================================================
// Calculate percentages manually
//==============================================================================

// Easy Taskers - Exposure/Info

forvalues t = 1/3 {


      reghdfe TYPE_ind2`t' i.Exposure i.Info if Difficult==0 & Period==1, noabsorb vce(robust)
      margins Exposure, post

      local pct_noexp_easy_`t' = _b[0.Exposure] *100
      local pct_exp_easy_`t' = _b[1.Exposure]  *100
    }


// Hard Taskers - Exposure

forvalues t = 1/3 {


      reghdfe TYPE_ind2`t' i.Exposure i.Info if Difficult==1 & Period==1, noabsorb vce(robust)
      margins Exposure, post

      local pct_noexp_hard_`t' = _b[0.Exposure]  *100
      local pct_exp_hard_`t' = _b[1.Exposure] *100
    }


// Easy Taskers - Info

forvalues t = 1/3 {


      reghdfe TYPE_ind2`t' i.Exposure i.Info if Difficult==0 & Period==1, noabsorb vce(robust)
      margins Info, post

      local pct_noinfo_easy_`t' = _b[0.Info]  *100
      local pct_info_easy_`t' = _b[1.Info] *100
    }


// Hard Taskers - Info

forvalues t = 1/3 {


      reghdfe TYPE_ind2`t' i.Exposure i.Info if Difficult==1 & Period==1, noabsorb vce(robust)
      margins Info, post

      local pct_noinfo_hard_`t' = _b[0.Info]  *100
      local pct_info_hard_`t' = _b[1.Info] *100
    }


/*

forvalues t = 1/3 {
    qui count if Difficult==0 & Exposure==0
    local total_noexp_easy = r(N)
    qui count if Difficult==0 & Exposure==0 & TYPE2==`t'
    local pct_noexp_easy_`t' = (r(N)/`total_noexp_easy')*100
    
    qui count if Difficult==0 & Exposure==1
    local total_exp_easy = r(N)
    qui count if Difficult==0 & Exposure==1 & TYPE2==`t'
    local pct_exp_easy_`t' = (r(N)/`total_exp_easy')*100
}

// Hard Taskers - Exposure
forvalues t = 1/3 {
    qui count if Difficult==1 & Exposure==0
    local total_noexp_hard = r(N)
    qui count if Difficult==1 & Exposure==0 & TYPE2==`t'
    local pct_noexp_hard_`t' = (r(N)/`total_noexp_hard')*100
    
    qui count if Difficult==1 & Exposure==1
    local total_exp_hard = r(N)
    qui count if Difficult==1 & Exposure==1 & TYPE2==`t'
    local pct_exp_hard_`t' = (r(N)/`total_exp_hard')*100
}

// Easy Taskers - Information
forvalues t = 1/3 {
    qui count if Difficult==0 & Info==0
    local total_noinfo_easy = r(N)
    qui count if Difficult==0 & Info==0 & TYPE2==`t'
    local pct_noinfo_easy_`t' = (r(N)/`total_noinfo_easy')*100
    
    qui count if Difficult==0 & Info==1
    local total_info_easy = r(N)
    qui count if Difficult==0 & Info==1 & TYPE2==`t'
    local pct_info_easy_`t' = (r(N)/`total_info_easy')*100
}

// Hard Taskers - Information
forvalues t = 1/3 {
    qui count if Difficult==1 & Info==0
    local total_noinfo_hard = r(N)
    qui count if Difficult==1 & Info==0 & TYPE2==`t'
    local pct_noinfo_hard_`t' = (r(N)/`total_noinfo_hard')*100
    
    qui count if Difficult==1 & Info==1
    local total_info_hard = r(N)
    qui count if Difficult==1 & Info==1 & TYPE2==`t'
    local pct_info_hard_`t' = (r(N)/`total_info_hard')*100
}

*/
//==============================================================================
// Create plotting dataset
//==============================================================================

clear
set obs 12

gen panel = .
gen type = .
gen treat0 = .
gen treat1 = .

// Easy Taskers - Exposure (panel 1)
replace panel = 1 in 1/3
replace type = 1 in 1
replace type = 2 in 2
replace type = 3 in 3
replace treat0 = `pct_noexp_easy_1' in 1
replace treat0 = `pct_noexp_easy_2' in 2
replace treat0 = `pct_noexp_easy_3' in 3
replace treat1 = `pct_exp_easy_1' in 1
replace treat1 = `pct_exp_easy_2' in 2
replace treat1 = `pct_exp_easy_3' in 3

// Hard Taskers - Exposure (panel 2)
replace panel = 2 in 4/6
replace type = 1 in 4
replace type = 2 in 5
replace type = 3 in 6
replace treat0 = `pct_noexp_hard_1' in 4
replace treat0 = `pct_noexp_hard_2' in 5
replace treat0 = `pct_noexp_hard_3' in 6
replace treat1 = `pct_exp_hard_1' in 4
replace treat1 = `pct_exp_hard_2' in 5
replace treat1 = `pct_exp_hard_3' in 6

// Easy Taskers - Information (panel 3)
replace panel = 3 in 7/9
replace type = 1 in 7
replace type = 2 in 8
replace type = 3 in 9
replace treat0 = `pct_noinfo_easy_1' in 7
replace treat0 = `pct_noinfo_easy_2' in 8
replace treat0 = `pct_noinfo_easy_3' in 9
replace treat1 = `pct_info_easy_1' in 7
replace treat1 = `pct_info_easy_2' in 8
replace treat1 = `pct_info_easy_3' in 9

// Hard Taskers - Information (panel 4)
replace panel = 4 in 10/12
replace type = 1 in 10
replace type = 2 in 11
replace type = 3 in 12
replace treat0 = `pct_noinfo_hard_1' in 10
replace treat0 = `pct_noinfo_hard_2' in 11
replace treat0 = `pct_noinfo_hard_3' in 12
replace treat1 = `pct_info_hard_1' in 10
replace treat1 = `pct_info_hard_2' in 11
replace treat1 = `pct_info_hard_3' in 12

// X positions for paired bars
gen xpos0 = type - 0.2
gen xpos1 = type + 0.2

// Label positions
gen label0_pos = treat0 + 2.5
gen label1_pos = treat1 + 2.5

// String labels
gen label0 = string(treat0, "%3.1f")
gen label1 = string(treat1, "%3.1f")
