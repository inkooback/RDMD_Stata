program define _01_rename
    version 15.0
    
    syntax varlist
	
	* save user-defined variable names
	global user_variables "`varlist'"
	global user_StudentID : word 1 of `varlist'
	global user_Year : word 2 of `varlist'
	global user_Grade : word 3 of `varlist'
	global user_ChoiceRank : word 4 of `varlist'
	global user_SchoolID : word 5 of `varlist'
	global user_Treatment : word 6 of `varlist'
	global user_Capacity : word 7 of `varlist'
	global user_Priority : word 8 of `varlist'
	global user_DefaultTiebreakerIndex : word 9 of `varlist'
	global user_TiebreakerStudentGroupIndex : word 10 of `varlist'
	global user_Advantage : word 11 of `varlist'
	global user_DefaultTiebreaker : word 12 of `varlist'
	global user_EffectiveTiebreaker : word 13 of `varlist'
	global user_Assignment : word 14 of `varlist'
	global user_Enrollment : word 15 of `varlist'
	
	rename (`varlist') (StudentID Year Grade ChoiceRank SchoolID Treatment Capacity Priority DefaultTiebreakerIndex TiebreakerStudentGroupIndex Advantage DefaultTiebreaker EffectiveTiebreaker Assignment Enrollment)
	
	dis "Your variables are renamed."
    
end

*=============================================================================



















