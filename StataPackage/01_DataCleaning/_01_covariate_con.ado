capture program drop _01_covariate_con
program define _01_covariate_con
    version 15.0
    
    syntax varlist
	
	* save user-defined variable names to a global macro 'user_Covariate1', 'user_Covariate2', ...
	global user_Covariate_con "`varlist'"
	local length : word count `varlist'
	
	forvalues i = 1 / `length'{
		global user_Covariate_con`i' : word `i' of `varlist'
	}
	
	* rename variables
	rename (`varlist') Covariate_con#, addnumber
	dis "Your covariate variables are renamed as Covariate_con_n"
    
end

*=============================================================================



















