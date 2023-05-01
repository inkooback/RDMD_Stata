capture program drop _00_Master
program define _00_Master
    version 15.0
    
    syntax [anything] [if]
	
	noisily{
		
		* Install commands
		ssc inst unique
		ssc install ranktest 
		ssc inst ivreg2
		
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
			
		* 1.1 receive the user's variable names and pass them to be renamed.
		_01_receive

		* 1.2. missing data
		_01_missing

		* 1.3. feasibility check
		* _01_check
		
		save "step1_finished.dta", replace
		
		dis "Choose bandwidth type (IK / CCFT). Default: IK" _request(bwtype)
		// throw an error if the input is not right
		if inlist("$bwtype", "IK", "ik", "CCFT", "ccft", "") == 0{
			while inlist("$bwtype", "IK", "ik", "CCFT", "ccft", "") == 0 {
				dis as error "Bandwidth type must be IK or CCFT"
				dis "Choose bandwidth type (IK / CCFT). Default: IK" _request(bwtype)
				}
			}
		
		dis "Choose bandwidth population criterion (integer). Default: 5" _request(criterion)
		// throw an error if the input is not integer
		if (mod($criterion, 1) != 0){
			while mod($criterion, 1) != 0 {
				dis as error "Must be integer"
				dis "Choose bandwidth population criterion (integer). Default: 5" _request(criterion)
				}
			}
		
		local counter = 0
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
				if "$bwtype" == "" | "$criterion" == ""{
					_02_pscore IK 5
					}
				else if ("$bwtype" == "") | ("$criterion" != ""){
					_02_pscore IK $criterion
					}
				else if ("$bwtype" != "") | ("$criterion" == ""){
					_02_pscore $bwtype 5
					}
				else{
					_02_pscore $bwtype $criterion
					}
				_03_create
				}
			}
		_04_stack

		_05_analysis
	}
end



















