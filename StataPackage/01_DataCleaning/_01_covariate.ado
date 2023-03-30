program define _01_covariate
    version 15.0
    
    syntax varlist
	
	* save user-defined variable names to a global macro 'user_Covariate1', 'user_Covariate2', ...
	global user_Covariate "`varlist'"
	local length : word count `varlist'
	
	forvalues i = 1 / `length'{
		global user_Covariate`i' : word `i' of `varlist'
	}
	
	* rename variables
	rename (`varlist') Covariate#, addnumber
	dis "Your covariate variables are renamed as Covariate_n"
    
end

*=============================================================================



















