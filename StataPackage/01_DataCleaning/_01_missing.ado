program define _01_missing
    version 15.0
    
    syntax [if]
	
	drop if missing (StudentID, Year, Grade, ChoiceRank, SchoolID, Capacity, Priority, DefaultTiebreakerIndex, TiebreakerStudentGroupIndex, Advantage, DefaultTiebreaker, EffectiveTiebreaker, Assignment, Enrollment, Outcome1, Outcome2, Covariate1, Covariate2, Covariate3)
	
	dis "Dropped rows with missing data"
    
end

*=============================================================================






