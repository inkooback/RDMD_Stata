program define _02_pscore
    version 15.0
    
    syntax [if]
	
	* pick one program
	keep if (Year == 2017) & (Grade == 1) & (SchoolID == 1)
	
	* 0. count number of unique types
	egen type = concat(SchoolID Priority), punct(", ")

	preserve
	bysort StudentID : replace type = type[_n-1] + ", " + type[_n+1] if inrange(_n, 2, _N-1) 
	bysort StudentID : replace type = type[_N-1] 
	bysort StudentID : keep if _n == 1
	distinct type
	global num_type = `r(N)' 
	restore
	
	* 1. Generate marginal priority (priority group with last offer)
	bys SchoolID: egen marginal_priority = max(Priority * Assignment)
	format marginal_priority %12.0g

	* 1-1. Generate marginal indicator
	gen marginal = Priority == marginal_priority

	* 1-2. Generate offer count by program
	bys SchoolID Priority: egen count = sum(Assignment)

	* 2. Generate applicant position
	gen position = Priority + EffectiveTiebreaker
	order position, after(EffectiveTiebreaker)

	* 3. Set cutoff as the last *marginal* student who gets an offer
	bys SchoolID: egen double cutoff  = max(Assignment * marginal * position)

	* 4. Calculate tie-breaker cutoff
	gen tie_cutoff = cutoff - marginal_priority
	
end

*=============================================================================



















