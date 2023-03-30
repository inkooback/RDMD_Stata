program define _01_outcome
    version 15.0
    
    syntax varlist
	
	* save user-defined variable names
	global user_Outcome "`varlist'"
	local length : word count `varlist'
	
	forvalues i = 1 / `length'{
		global user_Outcome`i' : word `i' of `varlist'
	}
	
	rename (`varlist') Outcome#, addnumber
	dis "Your outcome variables are renamed as Outcome_n"
    
end

*=============================================================================



















