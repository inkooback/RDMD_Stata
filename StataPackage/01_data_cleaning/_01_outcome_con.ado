capture program drop _01_outcome_con
program define _01_outcome_con
    version 15.0
    
    syntax varlist
	
	* save user-defined variable names to a global macro user_Outcome1, user_Outcome2, ...
	global user_Outcome_con "`varlist'"
	local length : word count `varlist'
	
	forvalues i = 1 / `length'{
		global user_Outcome_con`i' : word `i' of `varlist'
	}
	
	* rename variables
	rename (`varlist') Outcome_con#, addnumber
	dis "Your outcome variables are renamed as Outcome_con_n"
    
end

*=============================================================================



















