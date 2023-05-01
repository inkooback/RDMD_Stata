capture program drop _01_missing
program define _01_missing
    version 15.0
    
    syntax [if]
	
	* drop rows with missing values 
	foreach v of var * { 
	drop if missing(`v') 
	}
	
	dis "Dropped rows with missing data"
    
end

*=============================================================================






