program define _01_covariate
    version 15.0
    
    syntax varlist
	
	* save user-defined variable names
	global user_covariate "`varlist'"
	local length : word count `varlist'
	
	forvalues i = 1 / `length'{
		global user_Covariate`i' : word `i' of `varlist'
	}
	
	rename (`varlist') Covariate#, addnumber
	dis "Your covariate variables are renamed as Covariate_n"
    
end

*=============================================================================



















