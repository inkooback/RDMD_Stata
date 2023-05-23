capture program drop _04_stack
program define _04_stack
    version 15.0
    
    syntax [anything] [if]
	
	// Initialize
	clear
	set obs 1				
	gen seed_for_append = .	
	tempfile seed_for_append
	save `seed_for_append'
	
	// Stack "variable_`year'_`grade'.dta" made at the end of the step 3 over all years and grades
	quietly{
		use "step1_finished.dta", clear
		
		// Loop over years
		levelsof Year, local(yearlist)
		foreach year of local yearlist {
			use "step1_finished.dta", clear
			
			// Loop over grades
			levelsof Grade, local(gradelist)
			foreach grade of local gradelist {
				clear
				append using `seed_for_append' "variable_`year'_`grade'.dta"
				save `seed_for_append', replace
				erase "variable_`year'_`grade'.dta"
			}
		}
		
		// Erase the initial row and column
		drop in 1		
		drop seed_for_append
		
		save "stacked.dta", replace
	}
	erase "step1_finished.dta"
end



















