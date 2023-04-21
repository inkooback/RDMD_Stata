capture program drop _01_outcome_cat
program define _01_outcome_cat
    version 15.0
    
    syntax varlist
	
	* save user-defined variable names to a global macro user_Outcome1, user_Outcome2, ...
	global user_Outcome_cat "`varlist'"
	local length : word count `varlist'
	
	forvalues i = 1 / `length'{
		global user_Outcome_cat`i' : word `i' of `varlist'
	}
	
	* rename variables
	rename (`varlist') Outcome_cat#, addnumber
	dis "Your outcome variables are renamed as Outcome_cat_n"
    
end

*=============================================================================



















