// -----------------------------------------------------------------------------
// Define program for differences, multiway clustered SEs, and native p-values
// -----------------------------------------------------------------------------
capture program drop estpost_clustered_diff
program estpost_clustered_diff, eclass
    // Changed cluster(varname) to cluster(string) to allow multiple cluster IDs
    syntax varlist [if] [in], by(varname) cluster(string)
    
    marksample touse, novarlist
    
    // Create temporary matrices
    tempname b V p_val
    local num_vars : word count `varlist'
    matrix `b' = J(1, `num_vars', .)
    matrix `V' = J(`num_vars', `num_vars', 0)
    matrix `p_val' = J(1, `num_vars', .)
    
    local i = 1
    foreach var of local varlist {
        // 1. Regress variable on the group dummy with multiway clustering
        quietly regress `var' `by' if `touse', vce(cluster `cluster')
        
        // 2. Store the difference (b) and variance (V)
        matrix `b'[1, `i'] = _b[`by'] 
        matrix `V'[`i', `i'] = _se[`by']^2
        
        // 3. Use Stata's native test command to extract the exact p-value
        quietly test `by'
        matrix `p_val'[1, `i'] = r(p)
        
        local ++i
    }
    
    // Name the matrix columns so esttab matches them to the variables
    matrix colnames `b' = `varlist'
    matrix colnames `V' = `varlist'
    matrix rownames `V' = `varlist'
    matrix colnames `p_val' = `varlist'
    
    // Post to e() so eststo and esttab can capture them
    ereturn post `b' `V'
    ereturn matrix p = `p_val'
    ereturn local cmd "estpost_clustered_diff"
end

// -----------------------------------------------------------------------------
