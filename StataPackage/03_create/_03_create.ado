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
			
	// generate D_i and C_i
	foreach t of varlist treatment*{
		gen Assign_`t' = Assignment * `t'
		gen Enroll_`t' = Enrollment * `t'
		gen pscore_`t' = pscore * `t'
 	}
	
	preserve
		collapse (sum) Assign_treatment* Enroll_treatment* pscore_treatment* treatment* (first) Year Grade Outcome* Covariate* dum_Covariate_cat*, by(StudentID)
		
		merge 1:1 StudentID using "runvar_control_`year'_`grade'.dta", nogen
		
		save "variable_`year'_`grade'.dta"
	restore
	
	erase "runvar_control_`year'_`grade'.dta"

end

