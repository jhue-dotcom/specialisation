/*
global path "C:\Users\oeyno\Dropbox\Research\Labour Markets from a Behavioural Persepective\Stata"
global tablepath "$path\output"
global graphpath "$path\figures"
cd "$path\cleaneddata"
*/

set scheme stcolor


/*
global path "C:\Users\hueju\Dropbox\Labour Markets from a Behavioural Persepective\Stata"
cd "$path\cleaneddata"
global graphpath "$path\figures"
global tablepath "$path\output"
*/

***************************************************************************************************************************************
/*To add in FMM estimation here*/


************ Finite mixture model with initial claims *******************
use data_full,clear 
    
 gen given_mean = 14.5*2 if Difficult == 1 & Type == 1
 replace given_mean = 25*2 if Difficult == 0 & Type == 1
 replace given_mean = 15.6*2 if Difficult == 1 & Type == 2
 replace given_mean = 23*2 if Difficult == 0 & Type == 2
 
 gen given_opp_mean = 14.5*2 if Difficult == 0 & Type == 2
 replace given_opp_mean = 25*2 if Difficult == 1 & Type == 2
 replace given_opp_mean = 15.6*2 if Difficult == 0 & Type == 1
 replace given_opp_mean = 23*2 if Difficult == 1 & Type == 1
 
gen y = InitialClaim/100 * PoolECU
gen x = PoolECU

gen mse = x/2
gen mle = (Score/(Score+OppScore))*x
gen mle_weighted_given = ((Score/given_mean)/((Score/given_mean) + (OppScore/given_opp_mean)))*x

gen i = SID
gen t = Period

gen treat1 = cond(TREAT == 1, 1,0)
gen treat2 = cond(TREAT == 2, 1,0)
gen treat3 = cond(TREAT == 3, 1,0)
gen treat4 = cond(TREAT == 4, 1,0)


sort i t

bysort SID: assert _N == 6
assert !missing(InitialClaim, Score, OppScore, PoolECU, ///
                given_mean, given_opp_mean)

save data_full_FMM, replace

********************************************************************************************

use data_full_FMM, clear

capture prog drop fairnessCEH
prog define fairnessCEH
    args todo b logl

    // Extract parameters from vector 'b'
    tempvar tb tsig tp11 tp12 tp21 tp22 tp31 tp32 tp41 tp42
    tempvar th11 th12 th21 th22 th31 th32 th41 th42
    
    mleval `tb'   = `b', eq(1)    // b
    mleval `tsig' = `b', eq(2)    // sig
    mleval `tp11' = `b', eq(3)    // p11
    mleval `tp12' = `b', eq(4)    // p12
    mleval `tp21' = `b', eq(5)    // p21
    mleval `tp22' = `b', eq(6)    // p22
    mleval `tp31' = `b', eq(7)    // p31
    mleval `tp32' = `b', eq(8)    // p32
    mleval `tp41' = `b', eq(9)    // p41
    mleval `tp42' = `b', eq(10)   // p42
    mleval `th11' = `b', eq(11)   // h11
    mleval `th12' = `b', eq(12)   // h12
    mleval `th21' = `b', eq(13)   // h21
    mleval `th22' = `b', eq(14)   // h22
    mleval `th31' = `b', eq(15)   // h31
    mleval `th32' = `b', eq(16)   // h32
    mleval `th41' = `b', eq(17)   // h41
    mleval `th42' = `b', eq(18)   // h42

    // Temporary variables for densities and products
    tempvar f11 f12 f13 f21 f22 f23 f31 f32 f33 f41 f42 f43
    tempvar fh11 fh12 fh13 fh21 fh22 fh23 fh31 fh32 fh33 fh41 fh42 fh43
    tempvar pp11 pp12 pp13 pp21 pp22 pp23 pp31 pp32 pp33 pp41 pp42 pp43
    tempvar ph11 ph12 ph13 ph21 ph22 ph23 ph31 ph32 ph33 ph41 ph42 ph43
    tempvar pp
	
	
      quietly gen double `f11'=cond(treat1 ==1 & Difficult == 0,(1/`tsig')*normalden((y-(x/`tb')-mse)/`tsig'),0)
      quietly gen double `f12'=cond(treat1 ==1 & Difficult == 0,(1/`tsig')*normalden((y-(x/`tb')-mle)/`tsig'),0)
      quietly gen double `f13'=cond(treat1 ==1 & Difficult == 0,(1/`tsig')*normalden((y-(x/`tb')-mle_weighted_given)/`tsig') ,0)
      quietly gen double `f21'=cond(treat2 ==1 & Difficult == 0,(1/`tsig')*normalden((y-(x/`tb')-mse)/`tsig'),0)
      quietly gen double `f22'=cond(treat2 ==1 & Difficult == 0,(1/`tsig')*normalden((y-(x/`tb')-mle)/`tsig'),0)
      quietly gen double `f23'=cond(treat2 ==1 & Difficult == 0,(1/`tsig')*normalden((y-(x/`tb')-mle_weighted_given)/`tsig') ,0)
      quietly gen double `f31'=cond(treat3 ==1 & Difficult == 0,(1/`tsig')*normalden((y-(x/`tb')-mse)/`tsig'),0)
      quietly gen double `f32'=cond(treat3 ==1 & Difficult == 0,(1/`tsig')*normalden((y-(x/`tb')-mle)/`tsig') ,0)
      quietly gen double `f33'=cond(treat3 ==1 & Difficult == 0,(1/`tsig')*normalden((y-(x/`tb')-mle_weighted_given)/`tsig'),0)
      quietly gen double `f41'=cond(treat4 ==1 & Difficult == 0,(1/`tsig')*normalden((y-(x/`tb')-mse)/`tsig'),0)
      quietly gen double `f42'=cond(treat4 ==1 & Difficult == 0,(1/`tsig')*normalden((y-(x/`tb')-mle)/`tsig'),0)
      quietly gen double `f43'=cond(treat4 ==1 & Difficult == 0,(1/`tsig')*normalden((y-(x/`tb')-mle_weighted_given)/`tsig'),0)
      quietly gen double `fh11'=cond(treat1 ==1 & Difficult == 1,(1/`tsig')*normalden((y-(x/`tb')-mse)/`tsig'),0)
      quietly gen double `fh12'=cond(treat1 ==1 & Difficult == 1,(1/`tsig')*normalden((y-(x/`tb')-mle)/`tsig'),0)
      quietly gen double `fh13'=cond(treat1 ==1 & Difficult == 1,(1/`tsig')*normalden((y-(x/`tb')-mle_weighted_given)/`tsig') ,0)
      quietly gen double `fh21'=cond(treat2 ==1 & Difficult == 1,(1/`tsig')*normalden((y-(x/`tb')-mse)/`tsig'),0)
      quietly gen double `fh22'=cond(treat2 ==1 & Difficult == 1,(1/`tsig')*normalden((y-(x/`tb')-mle)/`tsig'),0)
      quietly gen double `fh23'=cond(treat2 ==1 & Difficult == 1,(1/`tsig')*normalden((y-(x/`tb')-mle_weighted_given)/`tsig') ,0)
      quietly gen double `fh31'=cond(treat3 ==1 & Difficult == 1,(1/`tsig')*normalden((y-(x/`tb')-mse)/`tsig'),0)
      quietly gen double `fh32'=cond(treat3 ==1 & Difficult == 1,(1/`tsig')*normalden((y-(x/`tb')-mle)/`tsig') ,0)
      quietly gen double `fh33'=cond(treat3 ==1 & Difficult == 1,(1/`tsig')*normalden((y-(x/`tb')-mle_weighted_given)/`tsig'),0)
      quietly gen double `fh41'=cond(treat4 ==1 & Difficult == 1,(1/`tsig')*normalden((y-(x/`tb')-mse)/`tsig'),0)
      quietly gen double `fh42'=cond(treat4 ==1 & Difficult == 1,(1/`tsig')*normalden((y-(x/`tb')-mle)/`tsig'),0)
      quietly gen double `fh43'=cond(treat4 ==1 & Difficult == 1,(1/`tsig')*normalden((y-(x/`tb')-mle_weighted_given)/`tsig'),0)
      quietly gen double `pp11'=.
      quietly gen double `pp12'=.
      quietly gen double `pp13'=.
      quietly gen double `pp21'=.
      quietly gen double `pp22'=.
      quietly gen double `pp23'=.
      quietly gen double `pp31'=.
      quietly gen double `pp32'=.
      quietly gen double `pp33'=.
      quietly gen double `pp41'=.
      quietly gen double `pp42'=.
      quietly gen double `pp43'=.
      quietly gen double `ph11'=.
      quietly gen double `ph12'=.
      quietly gen double `ph13'=.
      quietly gen double `ph21'=.
      quietly gen double `ph22'=.
      quietly gen double `ph23'=.
      quietly gen double `ph31'=.
      quietly gen double `ph32'=.
      quietly gen double `ph33'=.
      quietly gen double `ph41'=.
      quietly gen double `ph42'=.
      quietly gen double `ph43'=.


      by i: replace `pp11'=exp(sum(ln(max(`f11',1e-12))))
      by i: replace `pp12'=exp(sum(ln(max(`f12',1e-12))))
      by i: replace `pp13'=exp(sum(ln(max(`f13',1e-12))))
      by i: replace `pp21'=exp(sum(ln(max(`f21',1e-12))))
      by i: replace `pp22'=exp(sum(ln(max(`f22',1e-12))))
      by i: replace `pp23'=exp(sum(ln(max(`f23',1e-12))))
      by i: replace `pp31'=exp(sum(ln(max(`f31',1e-12))))
      by i: replace `pp32'=exp(sum(ln(max(`f32',1e-12))))
      by i: replace `pp33'=exp(sum(ln(max(`f33',1e-12))))
      by i: replace `pp41'=exp(sum(ln(max(`f41',1e-12))))
      by i: replace `pp42'=exp(sum(ln(max(`f42',1e-12))))
      by i: replace `pp43'=exp(sum(ln(max(`f43',1e-12))))
      by i: replace `ph11'=exp(sum(ln(max(`fh11',1e-12))))
      by i: replace `ph12'=exp(sum(ln(max(`fh12',1e-12))))
      by i: replace `ph13'=exp(sum(ln(max(`fh13',1e-12))))
      by i: replace `ph21'=exp(sum(ln(max(`fh21',1e-12))))
      by i: replace `ph22'=exp(sum(ln(max(`fh22',1e-12))))
      by i: replace `ph23'=exp(sum(ln(max(`fh23',1e-12))))
      by i: replace `ph31'=exp(sum(ln(max(`fh31',1e-12))))
      by i: replace `ph32'=exp(sum(ln(max(`fh32',1e-12))))
      by i: replace `ph33'=exp(sum(ln(max(`fh33',1e-12))))
      by i: replace `ph41'=exp(sum(ln(max(`fh41',1e-12))))
      by i: replace `ph42'=exp(sum(ln(max(`fh42',1e-12))))
      by i: replace `ph43'=exp(sum(ln(max(`fh43',1e-12))))

    // Final mixture probability (use PARAMETER VARIABLES tp11, th11, etc.)
    quietly gen double `pp' = ///
        treat1 * (1 - Difficult) * (`tp11'*`pp11' + `tp12'*`pp12' + (1 - `tp11' - `tp12')*`pp13') + ///
        treat2 * (1 - Difficult) * (`tp21'*`pp21' + `tp22'*`pp22' + (1 - `tp21' - `tp22')*`pp23') + ///
        treat3 * (1 - Difficult) * (`tp31'*`pp31' + `tp32'*`pp32' + (1 - `tp31' - `tp32')*`pp33') + ///
        treat4 * (1 - Difficult) * (`tp41'*`pp41' + `tp42'*`pp42' + (1 - `tp41' - `tp42')*`pp43') + ///
        treat1 * Difficult * (`th11'*`ph11' + `th12'*`ph12' + (1 - `th11' - `th12')*`ph13') + ///
        treat2 * Difficult * (`th21'*`ph21' + `th22'*`ph22' + (1 - `th21' - `th22')*`ph23') + ///
        treat3 * Difficult * (`th31'*`ph31' + `th32'*`ph32' + (1 - `th31' - `th32')*`ph33') + ///
        treat4 * Difficult * (`th41'*`ph41' + `th42'*`ph42' + (1 - `th41' - `th42')*`ph43')
    
    quietly replace `pp' = . if last ~= 1
    mlsum `logl' = ln(`pp') if last == 1
	
	  quietly replace postpP11=(`tp11'*`pp11')/(`tp11'*`pp11'+`tp12'*`pp12' + (1-`tp11'-`tp12')*`pp13')
      quietly replace postpP12=(`tp12'*`pp12')/(`tp11'*`pp11'+`tp12'*`pp12' + (1-`tp11'-`tp12')*`pp13')
      quietly replace postpP13=((1- `tp11' -`tp12')*`pp13')/(`tp11'*`pp11'+`tp12'*`pp12' + (1-`tp11'-`tp12')*`pp13')
      quietly replace postpP21=(`tp21'*`pp21')/(`tp21'*`pp21'+`tp22'*`pp22' + (1-`tp21'-`tp22')*`pp23')
      quietly replace postpP22=(`tp22'*`pp22')/(`tp21'*`pp21'+`tp22'*`pp22' + (1-`tp21'-`tp22')*`pp23')
      quietly replace postpP23=((1- `tp21' -`tp22')*`pp23')/(`tp21'*`pp21'+`tp22'*`pp22' + (1-`tp21'-`tp22')*`pp23')
      quietly replace postpP31=(`tp31'*`pp31')/(`tp31'*`pp31'+`tp32'*`pp32' + (1-`tp31'-`tp32')*`pp33')
      quietly replace postpP32=(`tp32'*`pp32')/(`tp31'*`pp31'+`tp32'*`pp32' + (1-`tp31'-`tp32')*`pp33')
      quietly replace postpP33=((1- `tp31' -`tp32')*`pp33')/(`tp31'*`pp31'+`tp32'*`pp32' + (1-`tp31'-`tp32')*`pp33')
      quietly replace postpP41=(`tp41'*`pp41')/(`tp41'*`pp41'+`tp42'*`pp42' + (1-`tp41'-`tp42')*`pp43')
      quietly replace postpP42=(`tp42'*`pp42')/(`tp41'*`pp41'+`tp42'*`pp42' + (1-`tp41'-`tp42')*`pp43')
      quietly replace postpP43=((1- `tp41' -`tp42')*`pp43')/(`tp41'*`pp41'+`tp42'*`pp42' + (1-`tp41'-`tp42')*`pp43')
      quietly replace postpH11=(`th11'*`ph11')/(`th11'*`ph11'+`th12'*`ph12' + (1-`th11'-`th12')*`ph13')
      quietly replace postpH12=(`th12'*`ph12')/(`th11'*`ph11'+`th12'*`ph12' + (1-`th11'-`th12')*`ph13')
      quietly replace postpH13=((1- `th11' -`th12')*`ph13')/(`th11'*`ph11'+`th12'*`ph12' + (1-`th11'-`th12')*`ph13')
      quietly replace postpH21=(`th21'*`ph21')/(`th21'*`ph21'+`th22'*`ph22' + (1-`th21'-`th22')*`ph23')
      quietly replace postpH22=(`th22'*`ph22')/(`th21'*`ph21'+`th22'*`ph22' + (1-`th21'-`th22')*`ph23')
      quietly replace postpH23=((1- `th21' -`th22')*`ph23')/(`th21'*`ph21'+`th22'*`ph22' + (1-`th21'-`th22')*`ph23')
      quietly replace postpH31=(`th31'*`ph31')/(`th31'*`ph31'+`th32'*`ph32' + (1-`th31'-`th32')*`ph33')
      quietly replace postpH32=(`th32'*`ph32')/(`th31'*`ph31'+`th32'*`ph32' + (1-`th31'-`th32')*`ph33')
      quietly replace postpH33=((1- `th31' -`th32')*`ph33')/(`th31'*`ph31'+`th32'*`ph32' + (1-`th31'-`th32')*`ph33')
      quietly replace postpH41=(`th41'*`ph41')/(`th41'*`ph41'+`th42'*`ph42' + (1-`th41'-`th42')*`ph43')
      quietly replace postpH42=(`th42'*`ph42')/(`th41'*`ph41'+`th42'*`ph42' + (1-`th41'-`th42')*`ph43')
      quietly replace postpH43=((1- `th41' -`th42')*`ph43')/(`th41'*`ph41'+`th42'*`ph42' + (1-`th41'-`th42')*`ph43')
      quietly putmata postpP11, replace
      quietly putmata postpP12, replace
      quietly putmata postpP13, replace
      quietly putmata postpP21, replace
      quietly putmata postpP22, replace
      quietly putmata postpP23, replace
      quietly putmata postpP31, replace
      quietly putmata postpP32, replace
      quietly putmata postpP33, replace
      quietly putmata postpP41, replace
      quietly putmata postpP42, replace
      quietly putmata postpP43, replace
      quietly putmata postpH11, replace
      quietly putmata postpH12, replace
      quietly putmata postpH13, replace
      quietly putmata postpH21, replace
      quietly putmata postpH22, replace
      quietly putmata postpH23, replace
      quietly putmata postpH31, replace
      quietly putmata postpH32, replace
      quietly putmata postpH33, replace
      quietly putmata postpH41, replace
      quietly putmata postpH42, replace
      quietly putmata postpH43, replace
	  
	  
end

// Prepare data
sort i t
by i: gen last = _n == _N // or period == 6?

gen postpP11=.
gen postpP12=.
gen postpP13=.
gen postpP21=.
gen postpP22=.
gen postpP23=.
gen postpP31=.
gen postpP32=.
gen postpP33=.
gen postpP41=.
gen postpP42=.
gen postpP43=.
gen postpH11=.
gen postpH12=.
gen postpH13=.
gen postpH21=.
gen postpH22=.
gen postpH23=.
gen postpH31=.
gen postpH32=.
gen postpH33=.
gen postpH41=.
gen postpH42=.
gen postpH43=.


// Model specification (unchanged)
ml model d0 fairnessCEH /tb /tsig /tp11 /tp12 /tp21 /tp22 /tp31 /tp32 /tp41 /tp42 /th11 /th12 /th21 /th22 /th31 /th32 /th41 /th42 
mat start = (30, 100, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3)
ml init start, copy
ml max

estimates store FMM_d0

***************************************************************************************************************************************
