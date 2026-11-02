global path "`c(pwd)'"
global savepath "$path\cleaneddata"

cd "$path/raw_data"


***************************************************************************************************************************************

//Cleaning and creation of Variables

use "$savepath/MERGEDdata", clear

drop treatment //This is ztree treatment variables

encode session, gen(SESSION)
gen SID=SESSION*100+Subject
gen otherSID=SESSION*100+OppID

gen PAIRID= SESSION*1000 + Period*100 + Group
by PAIRID, sort: egen TimeClear2=total(TimeClear) //fill in TimeClear for the other person which is not filled.


***************************************************************************************************************************************

//Need variable for hard and easy combination to control for.
replace SDif = SDif - 1  //whether difficult or not
replace GDif = GDif - 1

gen Difficult=0
replace Difficult=1 if SDif==1 & Type==2
replace Difficult=1 if GDif==1 & Type==1

gen DifficultyVersion=1 if SDif==1
replace DifficultyVersion=2 if GDif==1


***************************************************************************************************************************************

//Treatment dimensions
replace Info=0 if Info==. 
gen Exposure=Treatment-3 

gen TREAT=1 if Exposure==0 & Info==0
replace TREAT=2 if Exposure==0 & Info==1
replace TREAT=3 if Exposure==1 & Info==0
replace TREAT=4 if Exposure==1 & Info==1

********************************************

gen Agreed=0
replace Agreed=1 if Status==3

by SID (Period), sort: gen Score1=Score[1] 

by Period PAIRID, sort: egen U=max(InitialClaim) 
by Period PAIRID, sort: egen L=min(InitialClaim)

drop U L

gen highexchange=0
replace highexchange=1 if SESSION<=3

**************************************************** Bargaining Time ************************************************
gen treatment = 3
merge 1:1 session Period Subject treatment using "$savepath\Subjectsdata", keepusing(TimeSubmitBargainingV1OK) nogen keep(match)
gen BargainTime = 300 - TimeSubmitBargainingV1OK
replace BargainTime = 0 if BargainTime < 0
replace BargainTime = . if Agreed == 0

sort session Period Group BargainTime
by session Period Group: gen BargainTime_shifted = BargainTime[_n+1] if _n == 1
by session Period Group: replace BargainTime = BargainTime_shifted if _n == 1

drop BargainTime_shifted

********************************************
//Correct scaling of questions (was set to 0 to 7 with 7 steps in ztree instead of 1 to 7)

foreach var in Q1 Q2 Q3 Q4 Q7 Q8 Q9 Q12 Q13 Q14 Q15 Q16{
    replace `var'=round((`var'/7*6)+1)
}

foreach var in Q3_S Q4_S{
    replace `var'=round((`var'/10*9)+1)
}

**************************************************** Bargaining Time ************************************************

***************************************************************************************************************************************

label define exp 0 "Low Exposure"  1 "High Exposure"
label define info 0 "No Info"  1 "Info"

label define g 1 "Male" 2 "Female" 3 "Other"

label value Exposure exp
label values Info info
label values PGender g


label define t 1 "NoExp-NoInfo" 2 "NoExp-Info" 3 "Exp-NoInfo" 4 "Exp-Info"
label values TREAT t

label define task 1 "Grid" 2 "Slider"
label values Type task
label values OppType task

label var Type "Specialisation"
label var Subject "Subject number in session"
label var Group "Group number in session in each period"
label var OppID "Subject number of opponent in session"

drop Treatment 

label var Exposure "Exposure treatment dummies"
label var Info "Info treatment dummies"

label var OppType "Specialisation of partner" //always opposite

label var Score "Score in task for Period"
label var OppScore "Score of opponent in task for Period"

label var TimeStart "Time bargaining is started"
label var TimeClear "Time bargaining is ended" 
label var TimeClear2 "Time bargaining is ended"

label var nBargain "Number of bargains in the period"
label var TrainingScore "Score in Training round" //measure of ability
label var Score1 "Score in round 1" //2nd measure of ability

label var Agreed "Whether agreed for bargaining"

//Q1: I could have done better than my counterpart at his/her task
//Q2: I put in more effort into my task than my counterpart put into his/her task.
//Q3: The amount of ECUs I received for this round was fair.
//Q4: What percentage of the ECU pool do you think you deserved?

rename Q1 Self_Better
rename Q2 Self_MoreEffort
rename Q3 Outcome_isFair
rename Q4 Self_FairPercent

label var Self_Better "I could have done better than my counterpart at his task."
label var Self_MoreEffort "I put in more effort into my task than my counterpart put into his task."
label var Outcome_isFair "The amount of ECUs I received for this round was fair."
label var Self_FairPercent "What percentage of the ECU pool do you think you deserved?"


label var OwnClaimPercent "Final claim percent for self"
label var OppClaimPercent "Final claim percent for opponent"
label var PoolECU "Total ECU earned for a pair"
label var OwnECU "ECU earned from bargaining"
label var OppECU "ECU earned from bargaining for opponent"

rename Q1_S Unclear 
rename Q2_S Factors
rename Q3_S Satisfied_Production 
rename Q4_S Cooperation_Needed 
rename Q5 Average_Effort
rename Q7 Harder_Task
rename Q8 Understand_Other
rename Q9 Earn_More
rename Q12 Satisfied_Earnings
rename Q13 Affected_Past
rename Q14 Hard_Agreement
rename Q15 Tryout
rename Q16 Prefer_Working
rename Q17 Third_Party

label var Unclear "Was there anything unclear about the instructions?"
label var Factors "When deciding on the percentage of the pool to demand, what were the factors most important to you?"
label var Satisfied_Production "Overall, how satisfied are you with your outcomes in the production?"
label var Cooperation_Needed "In production, to what extent did you feel that cooperation was needed between you and your counterpart to maximise your earnings?"
label var Average_Effort "When working on your profession's task, on average, how much effort did you feel you were putting into it?"
label var Harder_Task "My task in the __ Profession is harder than my counterpart's task in the ____ Profession."
label var Understand_Other "I did not understand what my counterpart's task is about."
label var Earn_More "People in my ___ Profession should earn more than people in the Slider profession."
label var Satisfied_Earnings "I was satisfied with my allocation of earnings in production."
label var Affected_Past "When working on my profession's task, I was affected by what happened in past allocations."
label var Hard_Agreement "I found it hard to come to an agreement on the allocation of earnings with my counterparts in production."
label var Tryout "In the future, if I am working in a firm that requires two or more different jobs, I would want to try out my colleages' jobs."
label var Prefer_Working "I prefer to be working with someone who knows what my work is about."
label var Third_Party "Suppose you could have a third party decide on the allocation of the pool of ECUs, would you want him to be in the Grid profession, Slider profession, or have experience in both professions?"

label define professionlabel 1 "Grid" 2 "Slider" 3 "Both"
label values Third_Party professionlabel
 
*********************** Score Diff and Score Ratio  ****************************************************

by PAIRID (Difficult), sort: gen SCOREDIFF=Score[1]-Score[2] 
label var SCOREDIFF "Score Difference"

egen zSCOREDIFF = std(SCOREDIFF)
label var zSCOREDIFF "Score Difference"

gen SCORERATIO = Score/OppScore

replace SCORERATIO = 1/SCORERATIO if Difficult == 1
egen zSCORERATIO_easy = std(SCORERATIO) if Difficult == 0
egen zSCORERATIO_hard = std(SCORERATIO) if Difficult == 1
gen zSCORERATIO = zSCORERATIO_easy if Difficult == 0
replace zSCORERATIO = zSCORERATIO_hard if Difficult == 1

drop zSCORERATIO_easy zSCORERATIO_hard

xtile q_SCORERATIO=SCORERATIO , nquantiles(7) 

label var zSCORERATIO "Score Ratio (STD)"
label var InitialClaim "Initial Demand"
label var Exposure "Exposure"
label var Info "Information"

label define Exposurelabel 0 "No Exposure" 1 "Exposure"
label define Infolabel 0 "No Info" 1 "Info"

label values Exposure Exposurelabel
label values Info Infolabel

label define DIFF 0 "Easy Task" 1 "Hard Task" 
label values Difficult DIFF

label define QSCORE 1 "Score Ratio (Quantile 1)" 2 "Score Ratio (Quantile 2)" 3 "Score Ratio (Quantile 3)" 4 "Score Ratio (Quantile 4)" 5 "Score Ratio (Quantile 5)" 6 "Score Ratio (Quantile 6)" 7 "Score Ratio (Quantile 7)"
label values q_SCORERATIO QSCORE

//Added this in to avoid mistakes
replace OwnClaimPercent=. if Agreed==0
replace OppClaimPercent=. if Agreed==0



by Period PAIRID (Difficult), sort: gen easyID=SID[1]
by Period PAIRID (Difficult), sort: gen diffID=SID[2]

//Effectively, we want both the easy and hard tasker in the pair to be classified to have the same (X,Y) so that it captures dependence.
//If we use (SID, otherSID), for example, easy tasker will be (X,Y) while hard tasker will be (Y,X) which does not capture the dependence.

drop FirstRoundSelected SecondRoundSelected FirstRoundEarning SecondRoundEarning TotalRoundEarning TotalRoundSGD

label var Score "Individual Score"
label var InitialClaim "Initial Claim"
label var OwnClaimPercent "Final Share"
label var Harder_Task "Own task is harder"
label var Self_MoreEffort "Put in more effort than counterpart"
label var RoundEarning "Earnings"



//==============================================================================
// Clean PCourse into broad academic fields
//==============================================================================
capture drop course_clean PCourseField

gen strL course_clean = lower(itrim(strtrim(PCourse)))
gen byte PCourseField = .

// 1. Business and Accountancy
replace PCourseField = 1 if regexm(course_clean, ///
    "account|business|marketing|^acc$|^acbs$|^adm$|^bus$|^nbs$")

// 2. Engineering
replace PCourseField = 2 if missing(PCourseField) & regexm(course_clean, ///
    "engineering|aerospace|chemical eng|civil eng|electr|environmental eng|" + ///
    "mechanical eng|materials eng|common engineering|^cbe$|^cee$|^eee$|" + ///
    "^iem$|^meec$|^mse$|^ene$|^mae$|^eeda$")

// 3. Computer Science and Data Science
replace PCourseField = 3 if missing(PCourseField) & regexm(course_clean, ///
    "computer science|computer scienece|computing|data science|artificial intelligence|" + ///
    "^csc$|^scse$|^dsai$|^ecds$|business & computing")

// 4. Mathematics and Natural Sciences
replace PCourseField = 4 if missing(PCourseField) & regexm(course_clean, ///
    "bioengineering|biological|biology|chemistry|physics|mathematical|" + ///
    "mathematics|math science|^bio$|^bs$|^cbc$|^math$|^maeo$|^sbs$|^phms$|^phqt$")

// 5. Economics and Social Sciences
replace PCourseField = 5 if missing(PCourseField) & regexm(course_clean, ///
    "economics|econs|psychology|sociology|public policy|philosophy|history|" + ///
    "^ecbu$|^ecpp$|^el h$|^espp$|^ppga$")

// 6. Humanities, Languages, and Communication
replace PCourseField = 6 if missing(PCourseField) & regexm(course_clean, ///
    "chinese|english|linguistics|language|communication|wkw|^chn$|^lms$")

// 7. Maritime / other professional programmes
replace PCourseField = 7 if missing(PCourseField) & regexm(course_clean, ///
    "maritime|^ms$|^ssm$")
	
	

label define PCourseField_lbl ///
    1 "Business and Accountancy" ///
    2 "Engineering" ///
    3 "Computer Science and Data Science" ///
    4 "Mathematics and Natural Sciences" ///
    5 "Economics and Social Sciences" ///
    6 "Humanities, Languages and Communication" ///
    7 "Maritime / Other Professional"

label values PCourseField PCourseField_lbl
label variable PCourseField "Field of study"

// Manual classifications for previously unclassified courses

// Humanities, Languages & Communication
replace PCourseField = 6 if course_clean == "elh"

// Maritime / Other Professional
replace PCourseField = 7 if course_clean == "maritim studies"

// Economics & Social Sciences
replace PCourseField = 5 if course_clean == "master of arts (research) nie"

// Mathematics & Natural Sciences
replace PCourseField = 4 if course_clean == "sbs bs"
replace PCourseField = 4 if course_clean == "maths"

// Audit entries that the rules did not classify
tab PCourse if missing(PCourseField), missing

// Check final distribution
tab PCourseField, missing

//==============================================================================
// Clean PCourse into current NTU schools / colleges
// Joint programmes are assigned to their primary / first-named school.
//==============================================================================

capture drop course_clean 
capture drop PCourseSchool

gen strL course_clean = lower(itrim(strtrim(PCourse)))
gen byte PCourseSchool = .


// -----------------------------------------------------------------------------
// 1. Nanyang Business School
// Includes Business & Computing because Business is the primary programme.
// -----------------------------------------------------------------------------

replace PCourseSchool = 1 if regexm(course_clean, ///
    "account|business|marketing|^acbs$|^acc$|^bus$|^nbs$")

// -----------------------------------------------------------------------------
// 3. School of Chemistry, Chemical Engineering and Biotechnology
// Current school: CCEB. Includes Chemistry, Chemical Engineering,
// Chemistry & Biological Chemistry, and Bioengineering.
// -----------------------------------------------------------------------------

replace PCourseSchool = 3 if missing(PCourseSchool) & regexm(course_clean, ///
    "chemical|chemistry|bioengineering|^cbe$|^cbc$")


// -----------------------------------------------------------------------------
// 4. School of Civil and Environmental Engineering
// Includes Civil Engineering, Environmental Engineering, Maritime Studies.
// -----------------------------------------------------------------------------

replace PCourseSchool = 4 if missing(PCourseSchool) & regexm(course_clean, ///
    "civil eng|environmental eng|maritim|^cee$|^ene$|^ms$")


// -----------------------------------------------------------------------------
// 5. School of Electrical and Electronic Engineering
// Includes Information Engineering and Media.
// -----------------------------------------------------------------------------

replace PCourseSchool = 5 if missing(PCourseSchool) & regexm(course_clean, ///
    "electr|^eee$|informat(i)?on.*engineering and media|iem")


// -----------------------------------------------------------------------------
// 6. School of Mechanical and Aerospace Engineering
// -----------------------------------------------------------------------------

replace PCourseSchool = 6 if missing(PCourseSchool) & regexm(course_clean, ///
    "aerospace|mechanical eng|^mae$|^meec$|common engineering|^engineering$")


// -----------------------------------------------------------------------------
// 7. School of Materials Science and Engineering
// -----------------------------------------------------------------------------

replace PCourseSchool = 7 if missing(PCourseSchool) & regexm(course_clean, ///
    "materials|^mse$")


// -----------------------------------------------------------------------------
// 8. College of Computing and Data Science
// Current home of Computer Science, Computer Engineering, and DSAI.
// Computer Science & Economics is assigned here because CS is primary.
// -----------------------------------------------------------------------------

replace PCourseSchool = 8 if missing(PCourseSchool) & regexm(course_clean, ///
    "computer science|computer scienece|computer engineering|computing|" + ///
    "data science|artificial intelligence|^csc$|^scse$|^dsai$")


// -----------------------------------------------------------------------------
// 9. School of Biological Sciences
// Bioengineering has already been assigned to CCEB above.
// -----------------------------------------------------------------------------

replace PCourseSchool = 9 if missing(PCourseSchool) & regexm(course_clean, ///
    "biological|^bio$|^bs$|^sbs$|^sbs bs$")


// -----------------------------------------------------------------------------
// 10. School of Physical and Mathematical Sciences
// Mathematics & Economics / Mathematical & Computer Sciences are assigned
// here because Mathematics is the primary / first-named programme.
// -----------------------------------------------------------------------------

replace PCourseSchool = 10 if missing(PCourseSchool) & regexm(course_clean, ///
    "applied physics|physics|math|mathematical|" + ///
    "^phms$|^phqt$|^maeo$")


// -----------------------------------------------------------------------------
// 11. School of Social Sciences
// Economics & Data Science, Economics & Business, etc. are assigned here
// because Economics is the primary / first-named programme.
// -----------------------------------------------------------------------------

replace PCourseSchool = 11 if missing(PCourseSchool) & regexm(course_clean, ///
    "economics|econs|psychology|sociology|public policy|" + ///
    "^ecbu$|^ecds$|^ecpp$|^eeda$|^espp$|^ppga$")


// -----------------------------------------------------------------------------
// 12. School of Humanities
// -----------------------------------------------------------------------------

replace PCourseSchool = 12 if missing(PCourseSchool) & regexm(course_clean, ///
    "chinese|english|linguistics|language|history|philosophy|" + ///
    "^chn$|^elh$|^lms$")

// -----------------------------------------------------------------------------
// 13. ADM
// -----------------------------------------------------------------------------

replace PCourseSchool = 13 if missing(PCourseSchool) & regexm(course_clean, ///
    "^adm$")

// -----------------------------------------------------------------------------
// 14. WKW
// -----------------------------------------------------------------------------

replace PCourseSchool = 14 if missing(PCourseSchool) & regexm(course_clean, ///
    "^communication|wkw")


// -----------------------------------------------------------------------------
// 15. Other
// Includes NIE, Sport Science and Management, and generic /
// unassigned College of Engineering programmes.
// -----------------------------------------------------------------------------

replace PCourseSchool = 15 if missing(PCourseSchool) & regexm(course_clean, ///
    "nie|^ssm$|")

	
	
// -----------------------------------------------------------------------------
// Labels
// -----------------------------------------------------------------------------

label define PCourseSchool_lbl ///
    1  "Nanyang Business School" ///
    3  "School of Chemistry, Chemical Engineering and Biotechnology" ///
    4  "School of Civil and Environmental Engineering" ///
    5  "School of Electrical and Electronic Engineering" ///
    6  "School of Mechanical and Aerospace Engineering" ///
    7  "School of Materials Science and Engineering" ///
    8  "College of Computing and Data Science" ///
    9  "School of Biological Sciences" ///
    10 "School of Physical and Mathematical Sciences" ///
    11 "School of Social Sciences" ///
    12 "School of Humanities" ///
	13 "Art, Design, and Media" ///
	14 "School of Communications" ///
    15 "National Institute of Education", replace

label values PCourseSchool PCourseSchool_lbl
label variable PCourseSchool "NTU school / college"


// -----------------------------------------------------------------------------
// Audit and final distribution
// -----------------------------------------------------------------------------

tab PCourse if missing(PCourseSchool), missing
tab PCourseSchool, missing

// Put unmatched and missing course responses into Other
replace PCourseSchool = 13 if missing(PCourseSchool)

preserve

// Turn the numeric school code into its readable value label
decode PCourseSchool, gen(PCourseSchool_label)

// Keep one row per observed Course × School assignment
contract PCourse PCourseSchool_label, freq(Frequency)

rename PCourse Course
rename PCourseSchool_label School

order School Course Frequency
sort School Course

restore


//==============================================================================
// Clean PNationality into regional categories
//==============================================================================

capture drop nationality_clean PNationalityGroup

gen strL nationality_clean = lower(itrim(strtrim(PNationality)))
gen byte PNationalityGroup = .


// 1. Singaporean
replace PNationalityGroup = 1 if regexm(nationality_clean, "singap") | ///
    inlist(nationality_clean, "sg", "sgp", "sg citizen", "sinagporean")


// 2. Malaysian
// This deliberately includes "Malaysian (SGPR)" and "SG PR (Malaysian)".
replace PNationalityGroup = 2 if regexm(nationality_clean, "malays|sg pr")


// 3. Other Southeast Asian
// Indonesia, Philippines, Myanmar, Thailand, Vietnam
replace PNationalityGroup = 3 if missing(PNationalityGroup) & regexm( ///
    nationality_clean, "indones|filip|myanmar|thai|vietnam")


// 4. South Asian
// India and Nepal
replace PNationalityGroup = 4 if missing(PNationalityGroup) & regexm( ///
    nationality_clean, "indian|^india$|nepal")


// 5. East Asian
// China, Japan, and Korea
replace PNationalityGroup = 5 if missing(PNationalityGroup) & regexm( ///
    nationality_clean, "china|chinese|japan|korea")


// 6. Other nationality
// Includes SG PR without a Malaysian designation and any other unmatched answer.
replace PNationalityGroup = 6 if missing(PNationalityGroup) & ///
    !missing(nationality_clean)


// Labels
label define PNationalityGroup_lbl ///
    1 "Singaporean" ///
    2 "Malaysian" ///
    3 "Other Southeast Asian" ///
    4 "South Asian" ///
    5 "East Asian" ///
    6 "Other Nationality", replace

label values PNationalityGroup PNationalityGroup_lbl
label variable PNationalityGroup "Nationality"


// Audit: inspect any nonmissing raw response still not classified
tab PNationality if missing(PNationalityGroup), missing

// Full check of the new grouping
tab PNationalityGroup, missing

// Optional: audit every raw response against its assigned group
tab PNationality PNationalityGroup, missing

//==============================================================================
// Clean PEthnicity into broad categories for the demographics table
//==============================================================================

capture drop ethnicity_clean PEthnicityGroup

gen strL ethnicity_clean = lower(itrim(strtrim(PEthnicity)))

gen byte PEthnicityGroup = .

// Chinese, including "Chinese, Singaporean" and "Filipino Chinese"
replace PEthnicityGroup = 1 if regexm(ethnicity_clean, ///
    "chinese|china")

// Malay
replace PEthnicityGroup = 2 if regexm(ethnicity_clean, ///
    "^malay$")

// Indian / South Asian
// Treat Hindu and Sikh responses as Indian for this demographics grouping.
replace PEthnicityGroup = 3 if missing(PEthnicityGroup) & regexm( ///
    ethnicity_clean, "indian|south asian|hindu|sikh")
	
// Includes religion responses (Buddhist, Hindu, Catholic, Sikh),
// other ethnicities, nationality answers, jokes, NA, nil, "-", and no response
replace PEthnicityGroup = 4 if missing(PEthnicityGroup) & ///
    !missing(ethnicity_clean)

label define PEthnicityGroup_lbl ///
    1 "Chinese" ///
    2 "Malay" ///
    3 "Indian / South Asian" ///
    4 "Other / Not Reported", replace

label values PEthnicityGroup PEthnicityGroup_lbl
label variable PEthnicityGroup "Ethnicity"

// Audit: inspect any nonmissing raw response still not classified
tab PEthnicity if missing(PEthnicityGroup), missing

// Full check of the new grouping
tab PEthnicityGroup, missing

// Optional: audit every raw response against its assigned group
tab PEthnicity PEthnicityGroup, missing



save "$savepath/data_full",replace


***************************************************************************************************************************************
//Append additional variables for analysis in bargaining data

use "$savepath/BARGAINdata",replace

encode session, gen(SESSION)
gen RID=SESSION*1000 + Period * 100 + Subject //Unique ID for subject in each round
gen ID=SESSION*100 + Subject // Unique subject ID

sort RID n

//Keep important individual round variables in main dataset
merge m:m session Subject Period using "$savepath/data_full", keepusing(SID Exposure Info Difficult PoolECU easyID diffID Type highexchange q_SCORERATIO SCORERATIO PAIRID Agreed) nogen

gen disagree_percent = ClaimPercent + OppClaimPercent - 100

gen claimcompare=.
replace claimcompare=1 if ClaimPercent>OppClaimPercent
replace claimcompare=2 if ClaimPercent==OppClaimPercent
replace claimcompare=3 if ClaimPercent<OppClaimPercent

xtset RID n

gen adjustdown = 0
replace adjustdown = 1 if ClaimPercent<l.ClaimPercent

gen adjustup = 1-adjustdown


label var n "Bargaining Round"
label define C 1 "Claimed Less" 2 "Claimed Equal" 3 "Claimed More"
label values claimcompare C
label var adjustdown "Claim strictly decreased"
label var adjustup "Claim weakly increased"


save "$savepath/BARGAINdata_full",replace

***************************************************************************************************************************************
