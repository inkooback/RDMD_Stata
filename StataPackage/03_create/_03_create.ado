capture program drop _03_create
program define _03_create
    version 15.0
    
    syntax [anything] [if]
	
	local year = $Year
	local grade = $Grade
	
	// Treatment into dummies
	levelsof Treatment, local(treatset)
	foreach t of local treatset {
		gen treatment_`t' = (Treatment == `t')
		}
		
	// Categorical covariates into dummies
	foreach cat of varlist Covariate_cat* {
		tostring `cat', replace
		levelsof `cat', local(catset)
		foreach c of local catset {
			gen dum_`cat'_`c' = (`cat' == "`c'")
			}
		}
			
	// pscore to each treated schools 
	foreach t of varlist treatment*{
		gen pscore_`t' = pscore * `t'
		}
	
	// Generate D_i and C_i
	gen Assign_x_Treat = Assignment * Treatment
	gen Enroll_x_Treat = Enrollment * Treatment
	
	// Remain only relevant variables
	preserve
		collapse (sum) Assign_x_Treat Enroll_x_Treat pscore_treatment* treatment* (first) Year Grade Outcome* Covariate* dum_Covariate_cat* Type, by(StudentID)
		
		// Merge running variable controls
		merge 1:1 StudentID using "runvar_control_`year'_`grade'.dta", nogen
		
		save "variable_`year'_`grade'.dta", replace
	restore
	
	erase "runvar_control_`year'_`grade'.dta"

end

