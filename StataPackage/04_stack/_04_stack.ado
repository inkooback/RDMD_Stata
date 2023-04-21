capture program drop _04_stack
program define _04_stack
    version 15.0
    
    syntax [anything] [if]
	
	clear
	set obs 1
	gen seed_for_append = .
	save "seed_for_append.dta", replace
	
	quietly{
		use "step1_finished.dta", clear
		levelsof Year, local(yearlist)
		foreach year of local yearlist {
			use "step1_finished.dta", clear
			levelsof Grade, local(gradelist)
			foreach grade of local gradelist {
				clear
				append using "seed_for_append.dta" "variable_`year'_`grade'.dta"
				save "seed_for_append.dta", replace
			}
		}
		
		drop in 1
		drop seed_for_append
		save "stacked.dta", replace
	}
end



















