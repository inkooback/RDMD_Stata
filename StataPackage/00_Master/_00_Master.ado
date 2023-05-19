capture program drop _00_Master
program define _00_Master
    version 15.0
    
    syntax [, bwtype(string) bwcriterion(integer 0)]
	
	* receive bandwidth selection
	if "`bwtype'"  == ""{
		dis "Choose bandwidth type (IK / CCFT). Press enter to set as default (IK)" _request(bwtype)
		// throw an error if the input is not right
		if inlist("$bwtype", "IK", "ik", "CCFT", "ccft", "") == 0{
			while inlist("$bwtype", "IK", "ik", "CCFT", "ccft", "") == 0 {
				dis as error "Bandwidth type must be IK or CCFT"
				dis "Choose bandwidth type (IK / CCFT). Press enter to set as default (IK)" _request(bwtype)
				}
			}
		}
		
	if "`bwcriterion'"  == "0"{
		* receive bandwidth population criterion selection
		dis "Choose bandwidth population criterion (integer). Press enter to set as default (5)" _request(bwcriterion)
		// throw an error if the input is not integer
		if (mod($bwcriterion, 1) != 0){
			while mod($bwcriterion, 1) != 0 {
				dis as error "Must be integer"
				dis "Choose bandwidth population criterion (integer). Press enter to set as default (5)" _request(bwcriterion)
				}
			}
		}
	
	noisily{
		
		* Install commands
		ssc inst unique
		ssc install ranktest 
		ssc inst ivreg2
		ssc install outreg
		
		* Download a package for CCFT bandwith calculation
		net install rdrobust, from(https://raw.githubusercontent.com/rdpackages/rdrobust/master/stata) replace
		
		* initialize global variables
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
			
		* receive the user's variable names and pass them to be renamed.
		_01_rename

		* conduct feasibility check
		* _01_check
		
		* save file after step 1
		save "step1_finished.dta", replace
		
		* calculate pscores and create variables looping over years and grades
		levelsof Year, local(yearlist)
		foreach year of local yearlist {
			global Year = `year'
			use "step1_finished.dta", clear
			keep if (Year == `year')
			
			levelsof Grade, local(gradelist)
			foreach grade of local gradelist {
				global Grade = `grade'
				use "step1_finished", clear
				keep if (Year == `year') & (Grade == `grade')
				
				// consider default
				if "$bwtype" == "" | "$bwcriterion" == ""{
					_02_pscore IK 5
					}
				else if ("$bwtype" == "") | ("$bwcriterion" != ""){
					_02_pscore IK $bwcriterion
					}
				else if ("$bwtype" != "") | ("$bwcriterion" == ""){
					_02_pscore $bwtype 5
					}
				else{
					_02_pscore $bwtype $bwcriterion
					}
				_03_create
				}
			}
		
		* stack over years and grades
		_04_stack

		* do some additional preprocessing and conduct 2SLS regression
		_05_analysis
	}
end



















