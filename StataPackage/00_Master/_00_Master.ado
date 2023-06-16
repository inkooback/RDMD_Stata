capture program drop _00_Master
program define _00_Master
    version 15.0
    
    syntax [, bwtype(string) bwcriterion(integer 0)]
	
	* Set bandwidth type if included in the option
	if "`bwtype'"  != ""{
		global bwtype = "`bwtype'"
	}
	
	* Set bandwidth criterion if included in the option
	if "`bwcriterion'"  != "0"{
		global bwcriterion = "`bwcriterion'"
	}
	
	* Ask bandwidth type if not included in the option
	if "`bwtype'"  == ""{
		dis "Choose bandwidth type (IK / CCFT). Press enter to set as default (IK)" _request(bwtype)
		// Throw an error if the input is not right
		if inlist("$bwtype", "IK", "ik", "CCFT", "ccft", "") == 0{
			while inlist("$bwtype", "IK", "ik", "CCFT", "ccft", "") == 0 {
				dis as error "Bandwidth type must be IK or CCFT"
				dis "Choose bandwidth type (IK / CCFT). Press enter to set as default (IK)" _request(bwtype)
				}
			}
		}
	
	* Ask bandwidth criterion if not included in the option
	if "`bwcriterion'"  == "0"{
		// Receive bandwidth population criterion selection
		dis "Choose bandwidth population criterion (integer). Press enter to set as default (5)" _request(bwcriterion)
		
		// User presses enter
		if ("$bwcriterion" == ""){
			dis "Bandwidths criterion set as 5"
		}
		
		// User doesn't press enter but puts non-integer
		else{
			if (mod($bwcriterion, 1) != 0) {
				while (mod($bwcriterion, 1) != 0) {
					dis as error "Bandwidth population criterion must be an integer"
					dis "Choose bandwidth population criterion (integer)" _request(bwcriterion)
					}
				}
			}
		}
		
		
		// Throw an error if the input is not an integer
		
	
	* At this point, global macros $bwtype and $bwcriterion are created (might be empty).
	
	noisily{
		
		* Install required commands
		ssc install unique		// Calculate unique values of types and pscores
		ssc install ranktest 	// F-test
		ssc install ivreg2 		// 2SLS regression
		ssc install outreg		// Output regression results
		
		* Download a package for CCFT bandwith calculation
		net install rdrobust, from(https://raw.githubusercontent.com/rdpackages/rdrobust/master/stata) replace
		
		* Initialize all the global macros
		global Year = ""
		global Grade = ""
		global cov_cat_length = ""
		global cov_con_length = ""
		global out_cat_length = ""
		global out_con_length = ""
		global user_variables = ""
		global user_StudentID = ""
		global user_Year = ""
		global user_Grade = ""
		global user_ChoiceRank = ""
		global user_SchoolID = ""
		global user_Treatment = ""
		global user_Capacity = ""
		global user_Priority = ""
		global user_DefaultTiebreakerIndex = ""
		global user_NonLottery = ""
		global user_TiebreakerStudentGroupIndex = ""
		global user_Advantage = ""
		global user_DefaultTiebreaker = ""
		global user_EffectiveTiebreaker = ""
		global user_Assignment = ""
		global user_Enrollment = ""
		global user_Covariate_cat = ""
		global user_Covariate_con = ""
		global user_Outcome_cat = ""
		global user_Outcome_con = ""
		global num_type = ""
			
		* Receive the user's variable names and rename them
		_01_rename

		* Conduct feasibility check
		* _01_check
		
		* Save file after step 1. This will be erased at the end of the step 4.
		save "step1_finished.dta", replace
		
		* Calculate pscores and create variables looping over years and grades
		levelsof Year, local(yearlist)
		
		// Loop over years
		foreach year of local yearlist {
			global Year = `year'
			use "step1_finished.dta", clear
			keep if (Year == `year')
			
			// Loop over grades
			levelsof Grade, local(gradelist)
			foreach grade of local gradelist {
				global Grade = `grade'
				use "step1_finished", clear
				keep if (Year == `year') & (Grade == `grade')
				
				// Run _02_pscore considering default
				if ("$bwtype" == "") & ("$bwcriterion" == "") {
					_02_pscore IK 5
					}
				else if ("$bwtype" == "") & ("$bwcriterion" != "") {
					_02_pscore IK $bwcriterion
					}
				else if ("$bwtype" != "") & ("$bwcriterion" == "") {
					_02_pscore $bwtype 5
					}
				else{
					_02_pscore $bwtype $bwcriterion
					}
				
				// Create variables we need for analysis
				_03_create
				}
			}
		
		* Stack the result files of step 3 over every year and grade
		_04_stack

		* Conduct additional preprocessing and conduct Balance / OLS / 2SLS regressions
		_05_analysis
	}
end



















