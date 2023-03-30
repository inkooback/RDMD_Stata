program define _01_outcome
    version 15.0
    
    syntax varlist
	
	* save user-defined variable names to a global macro user_Outcome1, user_Outcome2, ...
	global user_Outcome "`varlist'"
	
	forvalues i = 1 / `length_Outcome'{
		global user_Outcome`i' : word `i' of `varlist'
	}
	
	* rename variables
	rename (`varlist') Outcome#, addnumber
	dis "Your outcome variables are renamed as Outcome_n"
    
end

*=============================================================================



















