capture program drop _02_pscore
program define _02_pscore
    version 15.0
    
    syntax [anything] [if]
	
	if "`anything'" == ""{
		local bw_type "ik"
		local bw_n 5
	}
	else {
		tokenize "`anything'"
		if "`2'" == ""{
			local bw_type `1'
			local bw_n 5
		}
		else {
			local bw_type `1'
			local bw_n `2'
		}
	}
	
	* Download a package for CCFT bandwith calculation
	net install rdrobust, from(https://raw.githubusercontent.com/rdpackages/rdrobust/master/stata) replace
	
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
	format MarginalPriority %12.0g

	* 1-1. Generate marginal indicator
	gen Marginal = Priority == MarginalPriority

	* 1-2. Generate offer count by program
	bys SchoolID Priority: egen Count = sum(Assignment)

	* 2. Generate applicant position
	gen Position = Priority + EffectiveTiebreaker
	order Position, after(EffectiveTiebreaker)
	
*===============================================================================
	
	// Generate indicator for missing ranks
	gen Position_orig = Position
	gen indi_missing_rank_mod = (Position == . & NonLottery == 1)

	// Replace missing RVs with max x 1000
	sum Position
	replace Position = r(max) * 1000 if indi_missing_rank_mod == 1
	scalar scalar_missing_rank_mod = r(max) * 1000

	// Re-rank for optional robustness check (no gaps in running variables)
	preserve
	// We drop duplicates in RVs, so that we can keep the cases where there is mass at the cutoff
	keep SchoolID  Priority Position

	duplicates drop

	// sorting as we would do to simulate DA
	sort SchoolID  Priority Position

	// preserve this ranking and generate one variable that preserve the ordering
	by SchoolID  Priority: gen reranked = _n
	tempfile reranked
	sa `reranked'
	restore

	merge m:1 SchoolID Priority Position using `reranked', nogen
	sort SchoolID  Priority Position

	replace Position = reranked

	// Rescaling running variables to (0,1], as described in the paper
	// Notice that we do that within the marginal group only
	egen runvar_max =  max(Position) if NonLottery == 1 & Marginal == 1 & indi_missing_rank_mod == 0
	egen runvar_min =  min(Position) if NonLottery == 1 & Marginal == 1 & indi_missing_rank_mod == 0

	gen rank_mod_no_rescale = Position

	replace Position = (rank_mod_no_rescale - runvar_min + 1) / (runvar_max -  runvar_min + 1) if (runvar_max -  runvar_min != 0)

	replace Position = 1 if (runvar_max -  runvar_min == 0)

	replace Position = 99 if indi_missing_rank_mod == 1

	// Assert re-scaling was successful
	summarize Position if indi_missing_rank_mod == 0
	assert `r(max)' <= 1 & `r(min)' > 0
	
*===============================================================================

	* 3. Set cutoff as the last *marginal* student who gets an offer
	bys SchoolID: egen double Cutoff  = max(Assignment * Marginal * Position)

	* 4. Calculate tie-breaker cutoff
	gen TieCutoff = Cutoff - MarginalPriority
	
*======================================= 5. Calculate bandwidth ====================================================================================
	
	// Generate indicator variables for programs using rank variable to break ties
	egen NonLotteryID = group(SchoolID) if NonLottery == 1
	
	// Generate centered position variable (cutoff = 0)
	gen Centered = Position - Cutoff
	
	// Generate variable that checks for marginal applicants above the cutoff
	bys SchoolID: egen FullyRanked = max(Marginal * (Centered > 0 ) * NonLottery)
	la var FullyRanked "Flag if non-lottery program had marginal students with Centered > 0 i.e. students ranked above the cutoff"
	
	* Keep only marginal students for the bandwidths
	preserve
	keep if Marginal == 1
	
	* make a list of variables starts with "Outcome"
	ds Outcome*
	
	* Standardize all outcomes because we're comparing across bandwidths
	foreach test of varlist `r(varlist)' {
		egen mean_`test' = mean(`test')
		egen sd_`test' = sd(`test')
		gen ss_`test' = (`test' -  mean_`test') / sd_`test'
		}
	
	ds ss_Outcome*
	* Loop over standardized outcomes
	foreach test of varlist `r(varlist)' {

		* Generate (missing) bandwidth variable
		gen `bw_type'_`test' = .

		summarize NonLotteryID
		forval i = 1/`r(max)' {

			* Create bandwidth for applicants who are applying to a non-lottery program that is fully ranked and only look at the marginal applicants.

			* IK
			if "`bw_type'" == "ik" {
			noi cap: _02_rdob_mod2 `test' Centered if (NonLotteryID == `i') & (FullyRanked == 1) & (Marginal == 1), ck(5.40)
			if _rc == 0 replace ik_`test' = `r(h_opt)' if NonLotteryID == `i'
			}
			
			* CCFT
			else if "`bw_type'" == "ccft" {
			noi cap: _02_rdbwselect `test' Centered if (NonLotteryID == `i') & (FullyRanked == 1) & (Marginal == 1), kernel(uniform) c(0)
			if _rc == 0 replace ccft_`test' = `e(h_mserd)' if NonLotteryID == `i'
			}
			
			* Catch incorrect
			else {
				di "Incorrect bandwidth option (must be ik or ccft)"
				stop
			}
		}
	}
	
	* Generate minimum bandwidth across the different outcomes for each Non-lottery program
	ds `bw_type'_ss_Outcome*
	
	egen `bw_type'_bw = rowmin(`r(varlist)')
	
	* Keep program ID and bandwidths
	keep NonLotteryID SchoolID `bw_type'_bw

	* Make unique
	duplicates drop
	isid SchoolID

	* Save
	tempfile temp_bw
	save `temp_bw'
	restore
	
	* Merge bw back in
	merge m:1 SchoolID using `temp_bw', assert(1 3) nogen
	
	* Implement selected bandwidth
	gen bw = `bw_type'_bw

	// Set bw to missing if lottery school
	replace bw = . if NonLottery == 0
	
	* Generate indicators for applicants in/above/below the bandwidth
	/*	Note that we do this twice due to the fact that we limit risk to programs where at least 5 applicants are on either side of the cutoff within the bandwidth.
	    Hence, after generating the indicators, we find the number of students in the bandwidth, then set the bandwidth to missing for programs with fewer than
		5 applicants on either side of the cutoff within the bandwidth, and then recalculate whether an applicant is in the bandwidth */

	// Generate indicator for being in the bandwidth
	gen in_bw =  (Centered > -bw) &  (Centered <= bw) & (Marginal == 1) & !missing(bw) if (NonLottery == 1)

	// Generate indicator for being below the bandwidth
	gen below_bw =  (Centered <= -bw) & (Marginal == 1) & !missing(bw) if (NonLottery == 1)
	
	// Generate indicator for being above the bandwidth
	gen above_bw =  (Centered > bw) & (Marginal == 1) & !missing(bw) if (NonLottery == 1)

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
	bysort SchoolID: egen no_in_bw = total(in_bw)

	// Number of applicants in bandwidth above cutoff
	bysort SchoolID: egen no_in_bw_above = total(in_bw) if Centered > 0 & Centered != .

	// Number of applicants in bandwidth below cutoff
	bysort SchoolID: egen no_in_bw_below = total(in_bw) if Centered <= 0 & Centered != .
	
	bysort SchoolID: egen max_no_in_bw_above = max(no_in_bw_above)
	bysort SchoolID: egen max_no_in_bw_below = max(no_in_bw_below)
	
	replace no_in_bw_above =  max_no_in_bw_above
	replace no_in_bw_below =  max_no_in_bw_below

	// Generate indicator for programs with fewer than (bw_n) on either side of the
	// cutoff within the bandwidth
	bysort SchoolID: gen fewer = (no_in_bw_above < `bw_n') | (no_in_bw_below < `bw_n')

	// Replace bandwidth to missing for such programs (no new risk)
	replace bw = . if fewer == 1

	// Drop indicators
	drop max_no_in_bw_above max_no_in_bw_below no_in_bw_below no_in_bw_above
	
	*** Truncate the bandwidth when it is much larger on one side than the other (because it is close to the top or bottom of the priority)

	* First, generate minimum and maximum value (in absolute value) of rank in the bandwidth
	sort SchoolID
	by SchoolID : egen max_bw_val = max(Centered) if in_bw == 1
	assert max_bw_val >= 0
	by SchoolID : egen min_bw_val = min(Centered) if in_bw == 1
	by SchoolID : gen abs_min_bw_val = abs(min_bw_val)

	* Generate variable that takes minimum absolute value across the left-most and right-most extremes of the bw.
	gen bw_mod_temp = min(max_bw_val, abs_min_bw_val)
	by SchoolID : egen bw_mod = min(bw_mod_temp)

	* Summary stats of the scale of the difference between the two bandwidths
	egen tag = tag(SchoolID)
	count if bw != bw_mod
	gen diff_bw = bw - bw_mod
	summarize diff_bw if tag == 1

	* Replace bandwidth with the smallest side of the bandwidth
	assert !mi(bw_mod) if !mi(bw)
	replace bw = bw_mod

	* Drop irrelevant variables
	drop bw_mod_temp bw_mod max_bw_val min_bw_val abs_min_bw_val

	*** Re-do the in/above/below bandwidth indicators after implementing the count
	drop in_bw below_bw above_bw
	
	// Generate indicator for being in the bandwidth
	gen in_bw =  (Centered > -bw) &  (Centered <= bw) & (Marginal == 1) & !missing(bw) if (NonLottery == 1)

	// Generate indicator for being below the bandwidth
	gen below_bw =  (Centered <= -bw) & (Marginal == 1) & !missing(bw) if (NonLottery == 1)
	
	// Generate indicator for being above the bandwidth
	gen above_bw =  (Centered > bw) & (Marginal == 1) & !missing(bw) if (NonLottery == 1)

	// check
	egen check = rowtotal(in_bw below_bw above_bw) if (Marginal == 1) & (NonLottery == 1) & !missing(bw)
	sum check
	assert `r(max)' == 1 & `r(min)' == 1
	drop check

	// Re-tag if the program has a bandwidth (tags screened programs)
	replace has_bw = bw != .

	// Save an intermediary file before creating the relevant indicators
	save "intermediary_`bw_type'.dta", replace

end
/*	
	*** Generate variables for robustness checks
	// Duplicates, gaps and number of applicants in BW

* 	1. Computing duplicates
	duplicates tag SchoolID Priority Position, gen(rvtag_duplicats)

*	2. Compute threshold for gaps in running variable
	// Sort
	sort SchoolID Priority Position_orig
	// Generate variable for number of steps from last rank
	by prog_id_aug global_priority: gen delta_rv_marg_in_bw = Position_orig[_n] - Position_orig[_n-1] ///
		if NonLottery == 1  & Marginal == 1 & in_bw == 1

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
	*==========================================================================================================================================================================
		
	* 6. Calculate T
	
	* 7. Calculate MID
	
	* 8. Calculate n
	
	* 9. Calculate d_screen
	
	* 10. Calculate d_lottery
	
	* 11. Calculate pscore
	
end

*=============================================================================



















