capture program drop _03_create
program define _03_create
    version 15.0
    
    syntax [anything] [if]
	
	local year = $Year
	local grade = $Grade
	
	use "pscore_`year'_`grade'.dta", clear
	
	tabulate Treatment, gen(treatment)
	
	// generate D_i and C_i
	foreach t of varlist treatment*{
		gen Assign_`t' = Assignment * `t'
		gen Enroll_`t' = Enrollment * `t'
		gen pscore_`t' = pscore * `t'
 	}
	
	preserve
		// Analysis of Treatment1
		collapse (sum) Assign_treatment1 Enroll_treatment1 pscore_treatment1 (mean) Year Grade Outcome* Covariate*, by(StudentID)
		
		merge 1:1 StudentID using "runvar_control_`year'_`grade'.dta", nogen
		
		save "variable_`year'_`grade'.dta", replace
	restore

end
