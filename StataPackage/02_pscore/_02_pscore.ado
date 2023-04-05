program define _02_pscore
    version 15.0
    
    syntax bw_type bw_n [if]
	
	* pick one year and grade
	keep if (Year == 2017) & (Grade == 1)
	
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
	bys SchoolID: egen MarginalPriority = max(Priority * Assignment)
	format marginal_priority %12.0g

	* 1-1. Generate marginal indicator
	gen Marginal = Priority == MarginalPriority

	* 1-2. Generate offer count by program
	bys SchoolID Priority: egen Count = sum(Assignment)

	* 2. Generate applicant position
	gen Position = Priority + EffectiveTiebreaker
	order Position, after(EffectiveTiebreaker)

	* 3. Set cutoff as the last *marginal* student who gets an offer
	bys SchoolID: egen double Cutoff  = max(Assignment * Marginal * Position)

	* 4. Calculate tie-breaker cutoff
	gen TieCutoff = Cutoff - MarginalPriority
	
	*======================================= 5. Calculate bandwidth ==========================================
	
	// Generate indicator variables for programs using rank variable to break ties
	egen NonLotteryID = group(SchoolID) if NonLottery == 0
	
	// Generate centered position variable (cutoff = 0)
	gen Centered = Position - Cutoff
	
	// Generate variable that checks for marginal applicants above the cutoff
	bys SchoolID: egen FullyRanked = max(Marginal * (Centered > 0 ) * NonLottery)
	la var FullyRanked "Flag if non-lottery program had marginal students with Centered > 0 i.e. students ranked above the cutoff"
	
	// Run either this program only once and use output for the other outcomes and merge back in
	
	_02_bw
	* Merge bw back in
	merge m:1 SchoolID using "'bw_type'_bw.dta", assert(1 3) nogen
	* Implement selected bandwidth
	gen bw = 'bw_type'_bw

	// Set bw to missing if lottery school
	replace bw = . if NonLottery == 0
	
	*========================= copy =========================
	
	* Generate indicators for applicants in/above/below the bandwidth
	/*	Note that we do this twice due to the fact that we limit risk to programs
		where at least 5 applicants are on either side of the cutoff within
		the bandwidth.
		Hence, after generating the indicators, we find the number of students in the
		bandwidth, then set the bandwidth to missing for programs with fewer than
		5 applicants on either side of the cutoff within the bandwidth, and then
		recalculate whether an applicant is in the bandwidth */

	// Generate indicator for being in the bandwidth
	gen in_bw =  (Centered > -bw) &  (Centered <= bw) & (Marginal == 1) & !missing(bw) if (NonLottery == 1)

	// Generate indicator for being below the bandwidth
	gen below_bw =  (Centered <= -bw) & (Marginal == 1) & !missing(bw) if (NonLottery == 1)
	
	// Generate indicator for being above the bandwidth
	gen above_bw =  (Centered > -bw) & (Marginal == 1) & !missing(bw) if (NonLottery == 1)

	// Generate check that each applicant is at max in/below/above the bandwidth
	egen check = rowtotal(in_bw below_bw above_bw) if (Marginal == 1) & (NonLottery == 1) & !missing(bw)
	sum check
	assert `r(max)' == 1 & `r(min)' == 1
	drop check

	// Tag if the program has a bandwidth. This effectively tags which programs are screened.
	gen has_bw = (bw != .)

	*** Implement bandwidth population criterion
	// Set bandwidth to missing for programs where fewer than five kids are on one or both sides of the cutoff within the bandwidth

	// Number of applicants in bandwidth
	bysort prog_id_aug: egen no_in_bw = total(in_bw)

	// Number of applicants in bandwidth above cutoff
	bysort prog_id_aug: egen no_in_bw_above = total(in_bw) if hs_rank_centered > 0 & hs_rank_centered!=.

	// Number of applicants in bandwidth below cutoff
	bysort prog_id_aug: egen no_in_bw_below = total(in_bw) if hs_rank_centered <= 0 & hs_rank_centered!=.
	bysort prog_id_aug: egen max_no_in_bw_above = max(no_in_bw_above)
	bysort prog_id_aug: egen max_no_in_bw_below = max(no_in_bw_below)
	replace no_in_bw_above =  max_no_in_bw_above
	replace no_in_bw_below =  max_no_in_bw_below

	// Generate indicator for programs with fewer than 5 on either side of the
	// cutoff within the bandwidth
	bysort prog_id_aug: gen no_in_bw_below_10 = no_in_bw_above < 5 | no_in_bw_below < 5

	// Replace bandwidth to missing for such programs (no new risk)
	replace bw = . if no_in_bw_below_10 == 1

	// Drop indicators
	drop max_no_in_bw_above max_no_in_bw_below no_in_bw_below no_in_bw_above

*** Truncate the bandwidth when it is much larger on one side than the other
	* (because it is close to the top or bottom of the priority)

	* First, generate minimum and maximum value (in absolute value) of rank in the
	* bandwidth
	sort prog_id_augmented
	by prog_id_augmented : egen max_bw_val = max(hs_rank_centered) if in_bw == 1
	assert max_bw_val >= 0
	by prog_id_augmented : egen min_bw_val = min(hs_rank_centered) if in_bw == 1
	by prog_id_augmented : gen abs_min_bw_val = abs(min_bw_val)

	* Generate variable that takes minimum absolute value across the left-most
	* and right-most extremes of the bw.
	gen bw_mod_temp = min(max_bw_val, abs_min_bw_val)
	by prog_id_augmented : egen bw_mod = min(bw_mod_temp)

	* Summary stats of the scale of the difference between the two bandwidths
	/*egen tag = tag(prog_id_augmented)
	count if bw != bw_mod
	gen diff_bw = bw - bw_mod
	su diff_bw if tag == 1 */

	* Replace bandwidth with the smallest side of the bandwidth
	assert !mi(bw_mod) if !mi(bw)
	replace bw = bw_mod

	* Drop irrelevant variables
	drop bw_mod_temp bw_mod max_bw_val min_bw_val abs_min_bw_val

*** Re-do the in/above/below bandwidth indicators after implementing the count
	drop in_bw below_bw above_bw

	gen in_bw =   hs_rank_centered > -bw &  hs_rank_centered <= bw & (marginal == 1) & !missing(bw)  ///
		if lottery_flag_mod == 0  & edopt == 0
	replace in_bw = hs_rank_centered > -bw &  hs_rank_centered <= bw  & (marginal == 1) & !missing(bw) & indi_min_cutoff_dist == 1 if lottery_flag_mod == 0  & edopt == 1

	gen below_bw = hs_rank_centered <= -bw 		& (marginal == 1) & !missing(bw) if lottery_flag_mod == 0 & edopt == 0
	replace below_bw = hs_rank_centered <= 0	  	& (marginal == 1) & !missing(bw) if lottery_flag_mod == 0 & edopt == 1 & in_bw == 0

	gen above_bw = hs_rank_centered >  bw 		& (marginal == 1) & !missing(bw) if lottery_flag_mod == 0 & edopt == 0
	replace above_bw = hs_rank_centered >  0 	 	& (marginal == 1) & !missing(bw) if lottery_flag_mod == 0 & edopt == 1 & in_bw == 0

	egen check = rowtotal(in_bw below_bw above_bw) if marginal == 1 & lottery_flag_mod == 0 & !missing(bw)
	sum check
	assert `r(max)' == 1 & `r(min)' == 1
	drop check

// Re-tag if the program has a bandwidth (tags screened programs)
replace has_bw = bw != .

// Save an intermediary file before creating the relevant indicators
save "${data_working}program_pscore`modification_str'`suffix'_`year'_before_theta`grad_flag'_`bw_type'.dta", replace

*** Generate variables for robustness checks
	// Duplicates, gaps and number of applicants in BW

* 	1. Computing duplicates
	duplicates tag prog_id_aug global_priority rank_mod, gen(rvtag_duplicats)

*	2. Compute threshold for gaps in running variable
	// Sort
	sort prog_id_aug global_priority rank_mod_orig
	// Generate variable for number of steps from last rank
	by prog_id_aug global_priority: gen delta_rv_marg_in_bw = rank_mod_orig[_n] - rank_mod_orig[_n-1] ///
		if lottery_flag_mod == 0  & marginal == 1 & in_bw == 1

	local modification_str
	if "`dup_threshold'" != "" {
		// Indicator for duplicates in bandwidth larger than threshold
		bys prog_id: egen dup_problem = max((rvtag_duplicats > (`dup_threshold' - 1) ) & (in_bw == 1) & lottery_flag_mod == 0 & marginal == 1)
		local modification_str "`modification_str'_`dup_threshold'dup"
		local modification_vars "dup_problem"
	}
	if "`delta_threshold'" != "" {
		// Indicator for gap larger than the threshold
		bys prog_id: egen delta_problem = max(delta_rv_marg_in_bw >  `delta_threshold' & delta_rv_marg_in_bw != . )
		local modification_str "`modification_str'_`delta_threshold'delta"
	}

local modification_vars

*	3. Flag these cases
	if "`dup_threshold'" != "" &  "`delta_threshold'" == ""  {
		local modification_vars "dup_problem"
	}
	else if "`dup_threshold'" == "" &  "`delta_threshold'" != "" {
		local modification_vars "delta_problem"
	}
	else if "`dup_threshold'" != "" &  "`delta_threshold'" != "" {
		local modification_vars "dup_problem | delta_problem"
	}

*	4. Modify bandwidths

	if "`dup_threshold'" != "" | "`delta_threshold'" != "" | `double_bw' == 1 | `half_bw' == 1  {

		// Final dummy for Either Delta or Duplicate Issue
		if "`dup_threshold'" != "" | "`delta_threshold'" != "" {
			bys prog_id: egen cont_problem = max(`modification_vars')
			** replacing thebandwidth
			replace bw = . if cont_problem == 1
		}

		if `double_bw' == 1 {
			gen double_bw = bw * 2
			replace bw = double_bw
			local modification_str "_doublebw"
		}

		if `half_bw' == 1 {
			gen half_bw = bw / 2
			replace bw = half_bw
			local modification_str "_halfbw"
		}

	// Replacing the in/below/above bandwidth indicators after modifying
	drop in_bw below_bw above_bw
	gen in_bw =   hs_rank_centered > -bw &  hs_rank_centered <= bw & (marginal == 1) & !missing(bw)  ///
		if lottery_flag_mod == 0  & edopt == 0
	replace in_bw = hs_rank_centered > -bw &  hs_rank_centered <= bw  & (marginal == 1) & !missing(bw) & indi_min_cutoff_dist == 1 if lottery_flag_mod == 0  & edopt == 1

	gen below_bw = hs_rank_centered <= -bw 		& (marginal == 1) & !missing(bw) if lottery_flag_mod == 0 & edopt == 0
	replace below_bw = hs_rank_centered <= 0	  	& (marginal == 1) & !missing(bw) if lottery_flag_mod == 0 & edopt == 1 & in_bw == 0

	gen above_bw = hs_rank_centered >  bw 		& (marginal == 1) & !missing(bw) if lottery_flag_mod == 0 & edopt == 0
	replace above_bw = hs_rank_centered >  0 	 	& (marginal == 1) & !missing(bw) if lottery_flag_mod == 0 & edopt == 1 & in_bw == 0

	egen check = rowtotal(in_bw below_bw above_bw) if marginal == 1 & lottery_flag_mod == 0 & !missing(bw)
	sum check
	assert `r(max)' == 1 & `r(min)' == 1
	drop check

	// Re-tag if the program has a bandwidth (tags which programs are screened)
	replace has_bw = bw != .
}
		
	*========================= copy =========================
	
	* 6. Calculate T
	
	* 7. Calculate MID
	
	* 8. Calculate n
	
	* 9. Calculate d_screen
	
	* 10. Calculate d_lottery
	
	* 11. Calculate pscore
	
end

*=============================================================================



















