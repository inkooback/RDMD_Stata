capture program drop _01_rename
program define _01_rename
    version 15.0
    
    syntax [anything] [if]
	
	noisily{
		
	* 1.1. Rename variables other than covariates and outcomes
		
	// Student ID
		dis "Input your variable name for Student ID" _request(id)
		qui ds
		// Throw warning if the input is not in the varlist
		if strpos(r(varlist), "$id") == 0{
			while strpos(r(varlist), "$id") == 0 {
				dis as error "variable $id not found"
				dis "Input your variable name for Student ID" _request(id)
				}
			}
		global user_StudentID = "$id"
		rename $id StudentID
		
	// Year
		dis "Please enter the name of your variable for year the applicant is in. If your data is only for one year and therefore does not have a year variable, simply press enter." _request(year)
		
		// If user pressed enter
		if "$year" == ""{
			gen Year = 1
			global user_Year = "Year"
		}
		
		else{
			qui ds
			// Throw warning if the input is not in the varlist
			if strpos(r(varlist), "$year") == 0{
				while strpos(r(varlist), "$year") == 0 {
					dis as error "variable $year not found"
					dis "Input your variable name for Year" _request(year)
					}
				}
				global user_Year = "$year"
				rename $year Year
			}
		
	// Grade
		dis "Please enter the name of your variable for grade the applicant is in. If your data is only for one grade and therefore does not have a grade variable, simply press enter." _request(grade)
		
		// If user pressed enter
		if "$grade" == ""{
			gen Grade = 1
			global user_Grade = "Grade"
		}
		
		else{
			qui ds
			// Throw warning if the input is not in the varlist
			if strpos(r(varlist), "$grade") == 0{
				while strpos(r(varlist), "$grade") == 0 {
					dis as error "variable $grade not found"
					dis "Input your variable name for Grade" _request(grade)
					}
				}
				global user_Grade = "$grade"
				rename $grade Grade
			}
			
	// Choice Rank
		dis "Input your variable name for Choice rank." _request(choice)
	
		qui ds
		// Throw warning if the input is not in the varlist
		if strpos(r(varlist), "$choice") == 0{
			while strpos(r(varlist), "$choice") == 0 {
				dis as error "variable $choice not found"
				dis "Input your variable name for Choice rank" _request(choice)
				}
			}
			global user_ChoiceRank = "$choice"
			rename $choice ChoiceRank
		
	// School ID
		dis "Input your variable name for School ID" _request(school)
		qui ds
		// Throw warning if the input is not in the varlist
		if strpos(r(varlist), "$school") == 0{
			while strpos(r(varlist), "$school") == 0 {
				dis as error "variable $school not found"
				dis "Input your variable name for School ID" _request(school)
				}
			}
		global user_SchoolID = "$school"
		rename $school SchoolID
		
	// Treatment
		dis "Input your variable name for Treatment" _request(treatment)
		qui ds
		// Throw warning if the input is not in the varlist
		if strpos(r(varlist), "$treatment") == 0{
			while strpos(r(varlist), "$treatment") == 0 {
				dis as error "variable $treatment not found"
				dis "Input your variable name for Treatment" _request(treatment)
				}
			}
		global user_Treatment = "$treatment"
		rename $treatment Treatment	
		
	// Capacity
		dis "Input your variable name for Capacity" _request(capacity)
		qui ds
		// Throw warning if the input is not in the varlist
		if strpos(r(varlist), "$capacity") == 0{
			while strpos(r(varlist), "$capacity") == 0 {
				dis as error "variable $capacity not found"
				dis "Input your variable name for Capacity" _request(capacity)
				}
			}
		global user_Capacity = "$capacity"
		rename $capacity Capacity	
		
	// Priority
		dis "Please enter the name of your variable for the priority. Please make sure that a lower number corresponds to a higher priority, with 0 indicating a guaranteed assignment. If your data have no priority structure and therefore does not have a priority variable, simply press enter." _request(priority)
		
		// If user pressed enter
		if "$priority" == ""{
			gen Priority = 1
			global user_Priority = "Priority"
		}
		
		else{
			qui ds
			// Throw warning if the input is not in the varlist
			if strpos(r(varlist), "$priority") == 0{
				while strpos(r(varlist), "$priority") == 0 {
					dis as error "variable $priority not found"
					dis "Input your variable name for Priority" _request(priority)
					}
				}
				global user_Priority = "$priority"
				rename $priority Priority
			}	
			
	// Default Tie-breaker Index
		dis "Input your variable name for (default) tie-breaker index" _request(default)
		qui ds
		// Throw warning if the input is not in the varlist
		if strpos(r(varlist), "$default") == 0{
			while strpos(r(varlist), "$default") == 0 {
				dis as error "variable $default not found"
				dis "Input your variable name for (default) tie-breaker index" _request(default)
				}
			}
		global user_TiebreakerIndex = "$default"
		rename $default TiebreakerIndex	
		
	// Non-lottery indicator
		dis "Input your variable name for NonLottery indicator. Values of this variable has to be binary (lottery = 0, non-lottery: 1). Press enter if your data have only lottery tie-breakers and thus don't have NonLottery indicator variable." _request(nonlottery)	
		
		// If user pressed enter
		if "$nonlottery" == ""{
			gen NonLottery = 0
			global user_NonLottery = "NonLottery"
		}
		
		else {
			qui ds
			// Throw warning if the input is not in the varlist
			if strpos(r(varlist), "$nonlottery") == 0{
				while strpos(r(varlist), "$nonlottery") == 0 {
					dis as error "variable $nonlottery not found"
					dis "Input your variable name for NonLottery indicator. Values of this variable has to be binary." _request(nonlottery)
					}
				}
				global user_NonLottery = "$nonlottery"
				rename $nonlottery NonLottery
			}
			
	// Tie-breaker student group index
		dis "Input your variable name for tie-breaker student group index. This variable is used for favoring some subset of applicants by multiplying a constant (Advantage) to their tie-breaker value. Press enter if your data don't include such favoring procedure and thus don't have a student group index variable." _request(group)	
		
		// If user pressed enter
		if "$group" == ""{
			gen TiebreakerStudentGroupIndex = 0
			global user_TiebreakerStudentGroupIndex = "group"
		}
		
		else {
			qui ds
			// Throw warning if the input is not in the varlist
			if strpos(r(varlist), "$group") == 0{
				while strpos(r(varlist), "$group") == 0 {
					dis as error "variable $group not found"
					dis "Input your variable name for tie-breaker student group index. This variable is used for favoring some subset of applicants by multiplying a constant (Advantage) to their tie-breaker value. Press enter if your data don't include such favoring procedure and thus don't have a student group index variable." _request(group)
					}
				}
				global user_TiebreakerStudentGroupIndex = "$group"
				rename $group TiebreakerStudentGroupIndex
			}
		
	// Advantage
		dis "Input your variable name for advantage. This variable is used for favoring some subset of applicants by multiplying a constant (Advantage) to their tie-breaker value. Press enter if your data don't include such favoring procedure and thus don't have an advantage variable." _request(advantage)	
		
		// If user pressed enter
		if "$advantage" == ""{
			gen Advantage = 1
			global user_Advantage = "advantage"
		}
		
		else {
			qui ds
			// Throw warning if the input is not in the varlist
			if strpos(r(varlist), "$advantage") == 0{
				while strpos(r(varlist), "$advantage") == 0 {
					dis as error "variable $advantage not found"
					dis "Input your variable name for advantage. This variable is used for favoring some subset of applicants by multiplying a constant to their tie-breaker value. Press enter if your data don't include such favoring procedure and thus don't have an advantage variable." _request(advantage)
					}
				}
				global user_Advantage = "$advantage"
				rename $advantage Advantage
			}

	// Default Tie-breaker
		dis "Input your variable name for default tie-breaker value" _request(tie)
		qui ds
		// Throw warning if the input is not in the varlist
		if strpos(r(varlist), "$tie") == 0{
			while strpos(r(varlist), "$tie") == 0 {
				dis as error "variable $tie not found"
				dis "Input your variable name for default tie-breaker value" _request(tie)
				}
			}
		global user_DefaultTiebreaker = "$tie"
		rename $tie DefaultTiebreaker
		
	// Effective Tie-breaker
		gen EffectiveTiebreaker = DefaultTiebreaker * Advantage
		order EffectiveTiebreaker, after(DefaultTiebreaker)

	// Assignment
		dis "Input your variable name for Assignment" _request(assignment)
		qui ds
		// Throw warning if the input is not in the varlist
		if strpos(r(varlist), "$assignment") == 0{
			while strpos(r(varlist), "$assignment") == 0 {
				dis as error "variable $assignment not found"
				dis "Input your variable name for Assignment" _request(assignment)
				}
			}
		global user_Assignment = "$assignment"
		rename $assignment Assignment
		
	// Enrollment
		dis "Input your variable name for Enrollment" _request(enrollment)
		qui ds
		// Throw warning if the input is not in the varlist
		if strpos(r(varlist), "$enrollment") == 0{
			while strpos(r(varlist), "$enrollment") == 0 {
				dis as error "variable $enrollment not found"
				dis "Input your variable name for Enrollment" _request(enrollment)
				}
			}
		global user_Enrollment = "$enrollment"
		rename $enrollment Enrollment

	* 1.2. Rename covariates
			// 1) Categorical
			dis "Input a list (parsed by space) of your variable names for categorical covariates in your dataset (Example: gender race). Press enter if you have no categorical covariate." _request(cov_cat_list)
			
			// Count the number of 
			global cov_cat_length : word count $cov_cat_list
			qui ds
			
			if $cov_cat_length > 0{
				
				// Throw warning if the input is not in the varlist
				forvalues i = 1 / $cov_cat_length{
					local cov: word `i' of $cov_cat_list
					if strpos(r(varlist), "`cov'") == 0{
						while strpos(r(varlist), "`cov'") == 0 {
							di as error "variable `cov' not found"
							dis "Input a list (parsed by space) of your variable names for categorical covariates in your dataset (Example: gender race). Press enter if you have no categorical covariate." _request(cov_cat_list)
							local cov: word `i' of $cov_cat_list
						}
					}
				}
				
				// Check once again
				forvalues i = 1 / $cov_cat_length{
					local cov: word `i' of $cov_cat_list
					if strpos(r(varlist), "`cov'") == 0{
						while strpos(r(varlist), "`cov'") == 0 {
							di as error "variable `cov' not found"
							dis "Input a list (parsed by space) of your variable names for categorical covariates in your dataset. (Example: gender race) Press enter if you have no categorical covariate." _request(cov_cat_list)
							local cov: word `i' of $cov_cat_list
							}
						}
					}
				
				// Pass the variable names to _01_covariate_cat as a varlist
				_01_covariate_cat $cov_cat_list
			}
			
			// 2) Countinuous
			dis "Input a list (parsed by space) of your variable names for the rest (continuous) covariates in your dataset. Press enter if you have no continuous covariate." _request(cov_con_list)
			
			// Count the number of 
			global cov_con_length : word count $cov_con_list
			qui ds
			
			if $cov_con_length > 0{
				
				// Throw warning if the input is not in the varlist
				forvalues i = 1 / $cov_con_length{
					local cov: word `i' of $cov_con_list
					if strpos(r(varlist), "`cov'") == 0{
						while strpos(r(varlist), "`cov'") == 0 {
							di as error "varaible `cov' not found"
							dis "Input a list (parsed by space) of your variable names for the rest (continuous) covariates in your dataset. Press enter if you have no continuous covariate." _request(cov_con_list)
							local cov: word `i' of $cov_con_list
							}
						}
					}
					
				// Check once again
				forvalues i = 1 / $cov_con_length{
					local cov: word `i' of $cov_con_list
					if strpos(r(varlist), "`cov'") == 0{
						while strpos(r(varlist), "`cov'") == 0 {
							di as error "variable `cov' not found"
							dis "Input a list (parsed by space) of your variable names for the rest (continuous) covariates in your dataset. Press enter if you have no continuous covariate." _request(cov_con_list)
							local cov: word `i' of $cov_con_list
							}
						}
					}
				
				// Pass the variable names to _01_covariate_con as a varlist
				_01_covariate_con $cov_con_list
			}
		
	* 1.3. Rename outcome variables
			
			/* Omit categorical outcomes
			// 1) categorical
			dis "Input a list (parsed by space) of your variable names for categorical outcome variables in your dataset. Press enter if you have no categorical outcome variables." _request(out_cat_list)
			
			// count the number of 
			global out_cat_length : word count $out_cat_list
			qui ds
			
			if $out_cat_length > 0 {
				
				// throw warning if the input is not in the varlist
				forvalues i = 1 / $out_cat_length{
					local out: word `i' of $out_cat_list
					if strpos(r(varlist), "`out'") == 0{
						while strpos(r(varlist), "`out'") == 0 {
							di as error "variable `out' not found"
							dis "Input a list (parsed by space) of your variable names for categorical outcome variables in your dataset. Press enter if you have no categorical outcome variables" _request(out_cat_list)
							local out: word `i' of $out_cat_list
							}
						}
					}
					
				// check once again
				forvalues i = 1 / $out_cat_length{
					local out: word `i' of $out_cat_list
					if strpos(r(varlist), "`out'") == 0{
						while strpos(r(varlist), "`out'") == 0 {
							di as error "variable `out' not found"
							dis "Input a list (parsed by space) of your variable names for categorical outcome variables in your dataset. Press enter if you have no categorical outcome variables" _request(out_cat_list)
							local out: word `i' of $out_cat_list
							}
						}
					}
				
				// pass the variable names to _01_outcome_cat as a varlist
				_01_outcome_cat $out_cat_list
			}
			*/
			
			// 2) Countinuous
			dis "Input a list (parsed by space) of your variable names for the outcome variables in your dataset (Example: math reading). You must have at least one outcome variable. These variables may store byte, integer, long, float or double type data. Please make sure that these variables are continuous variables, not categorical." _request(out_con_list)
			
			// Count the number of 
			global out_con_length : word count $out_con_list
			qui ds
			
			if $out_con_length > 0 {
				// Throw warning if the input is not in the varlist
				forvalues i = 1 / $out_con_length{
					local out: word `i' of $out_con_list
					if strpos(r(varlist), "`out'") == 0{
						while strpos(r(varlist), "`out'") == 0 {
							di as error "variable `out' not found"
							dis "Input a list (parsed by space) of your variable names for the rest (continuous) outcome variables in your dataset. You must have at least one outcome variable. These variables may store byte, integer, long, float or double type data. Please make sure that these variables are continuous variables, not categorical." _request(out_con_list)
							local out: word `i' of $out_cat_list
							}
						}
					}
					
				// Check once again
				forvalues i = 1 / $out_con_length{
					local out: word `i' of $out_con_list
					if strpos(r(varlist), "`out'") == 0{
						while strpos(r(varlist), "`out'") == 0 {
							di as error "variable `out' not found"
							dis "Input a list (parsed by space) of your variable names for the rest (continuous) outcome variables in your dataset. You must have at least one outcome variable. These variables may store byte, integer, long, float or double type data. Please make sure that these variables are continuous variables, not categorical." _request(out_con_list)
							local out: word `i' of $out_con_list
							}
						}
					}
				
				// Pass the variable names to _01_outcome_con as a varlist
				_01_outcome_con $out_con_list 
			}
			
			if ($out_con_length == 0) {
				dis as error "You must have at least one outcome variable."
				}
	}
end



















