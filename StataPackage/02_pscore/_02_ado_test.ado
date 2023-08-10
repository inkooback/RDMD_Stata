capture program drop _02_anything
program define _02_anything
    version 15.0
    
    syntax anything [if]
	
	tokenize "`anything'"
	local x `1'
	local y `2'
	
	if "`x'" == "ik" {
		dis "success"
	}
	
end

*=============================================================================



















