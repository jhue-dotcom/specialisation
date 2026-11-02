global path "`c(pwd)'"
global savepath "$path\cleaneddata"

cd "$path/raw_data"



***************************************************************************************************************************************
//Create data file from main treatments.

clear


local count=1

local files : dir "$path\raw_data" files "*.xls"


foreach file in `files'{ 

	clear all 
	ztree2stata output using `file' 
	

	if `count'==1{
	save "$savepath/GAMEdata",replace
	}
	else{
	append using "$savepath/GAMEdata"
	save "$savepath/GAMEdata",replace
	}


local count = `count'+1
}

***************************************************************************************************************************************

// create temp data file for difficulty from globals table

clear

local count=1

local files : dir "$path\raw_data" files "*.xls"


foreach file in `files'{ 

	clear all 
	ztree2stata globals using `file' 
	

	if `count'==1{
	save "$savepath/Globalsdata",replace
	}
	else{
	append using "$savepath/Globalsdata"
	save "$savepath/Globalsdata",replace
	}


local count = `count'+1
}

keep if treatment == 2 & Period == 1
keep session SDif GDif
save "$savepath/temp", replace


***************************************************************************************************************************************
// create data file for questionnaire output

clear

local count=1

local files : dir "$path\raw_data" files "*.xls"


foreach file in `files'{ 
	clear all 
	ztree2stata QuestionnaireOutput using `file'
	

	if `count'==1{
	save "$savepath/Questionnairedata",replace
	}
	else{
	append using "$savepath/Questionnairedata"
	save "$savepath/Questionnairedata",replace
	}

local count = `count'+1
}



***************************************************************************************************************************************
// create data file for survey output

clear

local count=1

local files : dir "$path\raw_data" files "*.xls"


foreach file in `files'{ 
	clear all 
	ztree2stata subjects using `file'
	

	if `count'==1{
	save "$savepath/Subjectsdata",replace
	}
	else{
	append using "$savepath/Subjectsdata"
	save "$savepath/Subjectsdata",replace
	}

local count = `count'+1
}


drop if treatment == 1| treatment == 2| treatment == 3
drop if treatment == 4 & session == "230908_1421"


keep treatment tables Period session Subject CompleteFee Xrate IOS OIOSGrid OIOSLine OIOSA PGender PCourse PYear PNationality PEthnicity FirstRoundSelected SecondRoundSelected FirstRoundEarning SecondRoundEarning TotalRoundEarning TotalRoundSGD TotalPayoffSGD Q*

//drop ClientNumber LastClientNumber Group Profit TotalProfit Participate OutsideOption TimeNextInstructionsOK Display CQ1 TimeSubmitQ1PairsOK TimeNextQ1PairsOK CQ2 TimeSubmitQ2ProfessionsOK TimeNextQ2ProfessionsOK CQ3 TimeSubmitQ3ABOK TimeNextQ3ABOK TimeSubmitQ3ABLineOK TimeNextQ3ABLineOK TimeSubmitQ3ABGridOK TimeNextQ3ABGridOK CQ4A CQ4B CQ4C CQ4D TimeSubmitQ4AlcationCoincideOK TimeNextQ4AllocationCoincideOK CQ5 TimeSubmitQ5AllocationFailOK TimeNextQ5AllocationFailOK CQ6 TimeSubmitQ6DropInECUsOK TimeNextQ6DropInECUsOK LeaveStage Treatment Info Type CType LTime up r RandomizedS X Y RandomizedG onezeroorder1 onezeroorder2 onezeroorder3 onezeroorder4 TimeNextProfessionAssignmentOK TimeNextProfesentCounterpartOK TimeNextTrainintroControlLowOK TimeBeginTrainingIntroToTaskOK TScoreW w word n letter wordid input_letter TimeSubmitWarmUpWordOK Score Stage sliderid c x_position true_x_position q1 xstart ystart xmouse ymouse xobject yobject ynull s s1 TimeSubmitWarmUpSliderOK gridid p1 Y11 Y12 Y13 Y14 Y21 Y22 Y23 Y24 Y31 Y32 Y33 Y34 Y41 Y42 Y43 Y44 Y51 Y52 Y53 Y54 Y61 Y62 Y63 Y64 Y71 Y72 Y73 Y74 Y81 Y82 Y83 Y84 ganswer i temprow1 temprow2 temprow3 temprow4 temprow5 temprow6 temprow7 temprow8 ans TimeSubmitWarmUpGridOK WarmUpScore TimeBeginTraingIntroTrainingOK TimeSubmitTrainingSliderOK TimeSubmitTrainingGridOK TimeNextTrainingEndOK Drop R Rank GroupType OppType OppID BargainTime PastScoreS PastScoreG YourPastScore OppPastScore TimeStartIntroControlOK TimeSubmitGridOK TimeSubmitSliderOK OppScore PoolECU CounterpartReady TimeNextScoresReportOK nBargain Submitted NoMatch Match Status OwnClaimPercent OppClaimPercent TimeSubmitBargainingV1OK TimeNextBargainingV1OK OwnClaimECU OppClaimECU RoundEarning OppRoundEarning TimeNextResultsOK TimeSubmitQuestionnaire1OK TimeNext1IntroductionOK TimeSubmit3Section1OK TimeSubmitIOSCounterpartOK TimeSubmitOSIOGridOK TimeSubmitOSIOLineOK TimeSubmitOSIOAOK TimeSubmit4Section1OK TimeSubmit5Section2OK TimeSubmit6Section2OK TimeSubmit7Section2OK TimeSubmit2DemographicsOK

//Open ended questions to label.
rename Q1 Q1_S
rename Q2 Q2_S
rename Q3 Q3_S
rename Q4 Q4_S


drop treatment tables Period

save "$savepath/Surveydata", replace



***************************************************************************************************************************************
//Create data from training rounds


clear

local count=1

local files : dir "$path\raw_data" files "*.xls"


foreach file in `files'{ 
	clear all 
	ztree2stata clients using `file', treatment(2) 
	

	if `count'==1{
	save "$savepath/trainingdata",replace
	}
	else{
	append using "$savepath/trainingdata"
	save "$savepath/trainingdata",replace
	}


local count = `count'+1
}

keep session Subject WarmUpScore TrainingScore

save "$savepath/trainingdata",replace


***************************************************************************************************************************************
//create data from bargaining rounds


clear

local count=1

local files : dir "$path\raw_data" files "*.xls"


foreach file in `files'{ 
	clear all 
	ztree2stata contracts using `file'
	

	if `count'==1{
	save "$savepath/BARGAINdata",replace
	}
	else{
	append using "$savepath/BARGAINdata"
	save "$savepath/BARGAINdata",replace
	}


local count = `count'+1
}


keep if n==1
rename ClaimPercent InitialClaim

gen InitialAgree=0
replace InitialAgree=1 if Status==3

keep session Subject Period InitialClaim InitialAgree

save "$savepath/initialbargain",replace



***************************************************************************************************************************************
//Merge all data

use "$savepath/GAMEdata", clear
merge m:1 session using "$savepath\temp.dta" , nogen

//Join Questionnaire
merge 1:1 session Period Subject using "$savepath\Questionnairedata.dta" , nogen

//Join survey data
merge m:1 session Subject using "$savepath\Surveydata.dta" , nogen

//Join bargain data
merge 1:1 session Period Subject using "$savepath\initialbargain.dta" , nogen

//Join training data
merge m:1 session Subject using "$savepath\trainingdata.dta" , nogen


save "$savepath/MERGEDdata",replace


