program define _02_pscore
    version 15.0
    
    syntax [if]
    
	* pick one program
	preserve
	keep if (Year == 2017) & (Grade == 1) & (SchoolID == 1)

	* Generate marginal priority (priority group with last offer)
	bys SchoolID: egen marginal_priority = max(Priority * Assignment)
	format marginal_priority %12.0g

	* Generate marginal indicator
	gen marginal = Priority == marginal_priority

	* Generate offer count by program
	bys SchoolID Priority: egen count = sum(Assignment)

	* Generate applicant position
	gen position = Priority + EffectiveTiebreaker
	order position, after(EffectiveTiebreaker)

	* Set cutoff as the last *marginal* student who gets an offer
	bys SchoolID: egen double cutoff  = max(Assignment * marginal * position)

	* Calculate tie-breaker cutoff
	gen tie_cutoff = cutoff - marginal_priority
	
end

*=============================================================================



















