program define _01_check
    version 15.0
    
    syntax [if]
    
	* 00 sort by ChoiceRank within each student
	sort StudentID ChoiceRank
	
	* 01 Inconsistency within a student (grade, outcomes, and tie-breaker)
	quietly{	
		levelsof StudentID, local(studentlist)
		foreach student of local studentlist {
			
			* grade
			levelsof Grade if StudentID == `student', local(grades)
			local numgrades : word count `grades'
			if `numgrades' > 1 {
				di as error "Inconsistent grade detected for student `student'"
			}
			
			* outcomes
			foreach outcome of varlist Outcome* {
				levelsof `outcome' if StudentID == `student', local(set_outcome)
				local num : word count `set_outcome'
				if `num' > 1 {
					di as error "Inconsistent `outcome' detected for student `student'"
				}
			}
			
			* default tie-breaker index
			levelsof DefaultTiebreakerIndex, local(defaultlist)
			foreach default of local defaultlist {
				levelsof DefaultTiebreaker if (StudentID == `student') & (DefaultTiebreakerIndex == `default'), local(breakers)
				local numbreakers : word count `breakers'
				if `numbreakers' > 1 {
					di as error "Inconsistent Default Tie breaker value detected for student `student' and Default Tie-breaker `default'"
				}
			}
		}
	}
	
	* 02 Inconsistency within a school (treatment, capacity, advantage)
	quietly{	
		levelsof Year, local(yearlist)
		foreach year of local yearlist {
			levelsof Grade, local(gradelist)
			foreach grade of local gradelist {
				levelsof SchoolID, local(schoollist)
				foreach school of local schoollist {
					
					* treatment
					levelsof Treatment if (Year == `year') & (Grade == `grade') & (SchoolID == `school'), local(treatment)
					local numtreat : word count `treatment'
					if `numtreat' > 1 {
					di as error "Inconsistent $user_Treatment detected for $user_SchoolID `school'"
					}
					
					* capacity
					levelsof Capacity if (Year == `year') & (Grade == `grade') & (SchoolID == `school'), local(capacity)
					local numcapa : word count `capacity'
					if `numcapa' > 1 {
					di as error "Inconsistent $user_Capacity detected for $user_SchoolID `school'"
					}
					
					* advantage
					levelsof Advantage if (Year == `year') & (Grade == `grade') & (SchoolID == `school'), local(advantage)
					local numadv : word count `advantage'
					if `numadv' > 2 { 
					di as error "Inconsistent $user_Advantage detected for $user_SchoolID `school'"
					}
				}
			}
		}
	}
	
	* 03 Multiple school for the same rank
	quietly{	
		levelsof StudentID, local(studentlist)
		foreach student of local studentlist {
			count if StudentID == `student'
			levelsof ChoiceRank if StudentID == `student', local(rankset)
			local numset : word count `rankset'
			if `r(N)' !=  `numset' {
				di as error "Repeated $user_ChoiceRank detected for $user_StudentID `student'"
			}
		}
	}
	
	* 04 Multiple rank for the same school
	quietly{	
		levelsof StudentID, local(studentlist)
		foreach student of local studentlist {
			count if StudentID == `student'
			levelsof SchoolID if StudentID == `student', local(schoolset)
			local numset : word count `schoolset'
			if `r(N)' !=  `numset' {
				di as error "Repeated $user_SchoolID detected for $user_StudentID `student'"
			}
		}
	}
	
	* 05 Inconsecutive choice rank (can be shortened later with getting max rank)
	quietly{	
		levelsof StudentID, local(studentlist)
		foreach student of local studentlist {
			count if StudentID == `student'
			levelsof ChoiceRank if StudentID == `student', local(rankset)
			local curr_max = 0 
			foreach rank of local rankset {
				if `rank' > `curr_max' {
					local curr_max = `rank'
					}
				}
			if `curr_max' >  `r(N)' {
				di as error "Inconsecutive $user_ChoiceRank detected for $user_StudentID `student'"
			}
		}
	}
	
	* 06 Multiple assignment / enrollment
	quietly{	
		levelsof StudentID, local(studentlist)
		foreach student of local studentlist {
			
			* assignment
			summarize Assignment if StudentID == `student' & Assignment == 1
			if `r(N)' >  1 {
				di as error "Multiple $user_Assignment for $user_StudentID `student'"
			}
			
			* enrollment
			summarize Enrollment if StudentID == `student' & Enrollment == 1
			if `r(N)' >  1 {
				di as error "Multiple $user_Enrollment for $user_StudentID `student'"
			}
		}
	}
	
	* 07 Over capacity (assignment, enrollment)
	quietly{	
		levelsof Year, local(yearlist)
		foreach year of local yearlist {
			levelsof Grade, local(gradelist)
			foreach grade of local gradelist {
				levelsof SchoolID, local(schoollist)
				foreach school of local schoollist {
					summarize Assignment if (Year == `year') & (Grade == `grade') & (SchoolID == `school') & (Assignment == 1)
					local assigned = r(N)
					summarize Enrollment if (Year == `year') & (Grade == `grade') & (SchoolID == `school') & (Enrollment == 1)
					local enrolled = r(N)
					summarize Capacity if (Year == `year') & (Grade == `grade') & (SchoolID == `school')
					local capa = r(mean)     
					summarize Priority if (Year == `year') & (Grade == `grade') & (SchoolID == `school') & (Assignment == 1)
					local max_pri = r(max)
					
					* check (1) if capacity is filled and (2) if there is someone not guaranteed an assignment
					if (`assigned' > `capa') & (`max_pri' > 0) {
					di as error "More $user_StudentID are assigned than $user_Capacity at $user_SchoolID `school'"
					}
					if (`enrolled' > `capa') & (`max_pri' > 0) {
					di as error "More $user_StudentID are enrolled than $user_Capacity at $user_SchoolID `school'"
					}
				}
			}
		}
	}
	
	* 08 Guaranteed assignment
	quietly{	
		levelsof StudentID, local(studentlist)
		foreach student of local studentlist {
			local assign_switch = 0
			local priority_switch = 0
			
			levelsof ChoiceRank if (StudentID == `student'), local(ranklist)
			foreach rank of local ranklist {
				
				summarize Priority if (StudentID == `student') & (ChoiceRank == `rank')
				local priority = r(mean)
				summarize Assignment if (StudentID == `student') & (ChoiceRank == `rank')
				local assignment = r(mean)
				
				* check: student is guaranteed an assignment at this school and not assigned to any preferred school, she is not assigned at this school.
				if (`priority' == 0) & (`assign_switch' == 0) & (`assignment' == 0) {
					di as error "$user_StudentID `student' is not assigned at the $user_SchoolID where she was guaranteed an assignment"
				}
				
				* check: student was guaranteed an assignment at a school she prefers to this school, she was not assigned at that school but is guaranteed at this school.
				if (`priority_switch' == 1) & (`assign_switch' == 0) & (`assignment' == 1) {
					di as error "$user_StudentID `student' is not assigned at the $user_SchoolID where she was guaranteed an assignment "
				}
				
				* Turn on assign_switch if the student is assigned
				if (`assignment' == 1) {
					local assign_switch = 1
				}
				
				* Turn on priority_switch if the student is guaranteed an assignment
				if (`priority' == 0) {
					local priority_switch = 1
				}
			}
		}
	}
	
	* 09 Stability
	quietly{	
		levelsof StudentID, local(studentlist)
		foreach student of local studentlist {
			local assign_switch = 0
			summarize Priority if (StudentID == `student')
			local best_position = r(max) + 1
			
			levelsof ChoiceRank if (StudentID == `student'), local(ranklist)
			foreach rank of local ranklist {
				
				* save applicant position value and assignment at this school
				summarize Priority if (StudentID == `student') & (ChoiceRank == `rank')
				local priority = r(mean)
				summarize EffectiveTiebreaker if (StudentID == `student') & (ChoiceRank == `rank')
				local tb = r(mean)
				local position = `priority' + `tb'
				summarize Assignment if (StudentID == `student') & (ChoiceRank == `rank')
				local assignment = r(mean)
				
				* check: student has better applicant position at a school she prefers to this school, she was not assigned there but is assigned here.
				if (`assign_switch' == 0) & (`position' > `best_position') & (`assignment' == 1) {
					di as error "Matching is not stable for $user_StudentID `student'"
				}
				
				* turn on assign_switch
				if (`assignment' == 1) {
						local assign_switch = 1
					}
				
				* update best position
				if (`position' < `best_position') {
					local best_position = `position'
				}
			}
		}
	}
	
	* 10 Outlier(check if an abnormally large value found in a column that is unlikely to have a huge outlier) (grade, choice rank, priority)
	quietly{
		summarize Grade
		if r(max) / r(mean) > 10{
			di as error "Abnormally large value detected in $user_Grade"
		}
		summarize ChoiceRank
		if r(max) / r(mean) > 10{
			di as error "Abnormally large value detected in $user_ChoiceRank"
		}
		summarize Priority
		if r(max) / r(mean) > 10{
			di as error "Abnormally large value detected in $user_Priority"
		}
	}
	
	* 11 Correlation (check if correlation between priority and default tie-breaker value is too big)
	quietly{	
		levelsof Year, local(yearlist)
		foreach year of local yearlist {
			levelsof Grade, local(gradelist)
			foreach grade of local gradelist {
				levelsof SchoolID, local(schoollist)
				foreach school of local schoollist {
				
					* preserve the original data
					preserve
					
					* filter data and calculate correlation
					keep if (Year == `year') & (Grade == `grade') & (SchoolID == `school')
					matrix accum R = Priority DefaultTiebreaker, noconstant deviations
					matrix R = corr(R)
					local corr = R[2,1]

					* check correlation
					if (`corr' > 0.9) {
						di as error "Correlation between $user_Priority and $user_DefaultTieBreaker is high for $user_Year `year', $user_Grade `grade', $user_SchoolID `school'"
					}
					
					* restore data 
					restore
				}
			}
		}
	}
	
end

*=============================================================================



















