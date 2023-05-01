capture program drop _01_rename
program define _01_rename
    version 15.0
    
    syntax varlist
	
	* save user-defined variable names so that we can use them when we report errors in _01_check
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
	global user_NonLottery : word 10 of `varlist'
	global user_TiebreakerStudentGroupIndex : word 11 of `varlist'
	global user_Advantage : word 12 of `varlist'
	global user_DefaultTiebreaker : word 13 of `varlist'
	global user_EffectiveTiebreaker : word 14 of `varlist'
	global user_Assignment : word 15 of `varlist'
	global user_Enrollment : word 16 of `varlist'
	
	* rename variables
	rename (`varlist') (StudentID Year Grade ChoiceRank SchoolID Treatment Capacity Priority DefaultTiebreakerIndex NonLottery TiebreakerStudentGroupIndex Advantage DefaultTiebreaker EffectiveTiebreaker Assignment Enrollment)
	
	dis "Your variables are renamed."
    
end

*=============================================================================



















