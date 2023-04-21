capture program drop _02_pscore
program define _02_pscore
    version 15.0
    
    syntax [anything] [if]
	
	// take bw_type and bw_n as arguments. set defaults.
	if "`anything'" == ""{
		local bw_type "IK"
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
	
	local year = $Year
	local grade = $Grade
	
	* Download a package for CCFT bandwith calculation
	net install rdrobust, from(https://raw.githubusercontent.com/rdpackages/rdrobust/master/stata) replace
	
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
	bys SchoolID TiebreakerStudentGroupIndex: egen MarginalPriority = max(Priority * Assignment)
	format MarginalPriority %12.0g

	// Generate marginal indicator
	gen Marginal = Priority == MarginalPriority

	// Generate offer count by program
	bys SchoolID Priority: egen Count = sum(Assignment)
	
	// short name for effective tie-breaker value
	gen rank = EffectiveTiebreaker
		
	// Generate indicator for missing ranks
	gen rank_orig = rank
	gen indi_missing_rank_mod = (rank == . & NonLottery == 1)

	// Replace missing RVs with max x 1000
	sum rank
	replace rank = r(max) * 1000 if indi_missing_rank_mod == 1
	scalar scalar_missing_rank_mod = r(max) * 1000

	// Re-rank for optional robustness check (no gaps in running variables)
	preserve
	// We drop duplicates in RVs, so that we can keep the cases where there is mass at the cutoff
	keep SchoolID Priority rank

	duplicates drop

	// sorting as we would do to simulate DA
	sort SchoolID Priority rank

	// preserve this ranking and generate one variable that preserve the ordering
	by SchoolID Priority: gen reranked = _n
	tempfile reranked
	save `reranked'
	restore

	merge m:1 SchoolID Priority rank using `reranked', nogen
	sort SchoolID Priority rank

	replace rank = reranked

	// Rescaling running variables to (0,1], as described in the paper
	// Notice that we do that within the marginal group only
	egen runvar_max =  max(rank) if NonLottery == 1 & Marginal == 1 & indi_missing_rank_mod == 0
	egen runvar_min =  min(rank) if NonLottery == 1 & Marginal == 1 & indi_missing_rank_mod == 0

	gen rank_mod_no_rescale = rank

	replace rank = (rank_mod_no_rescale - runvar_min + 1) / (runvar_max -  runvar_min + 1) if (runvar_max -  runvar_min != 0)

	replace rank = 1 if (runvar_max -  runvar_min == 0)

	replace rank = 99 if indi_missing_rank_mod == 1

	// Assert re-scaling was successful
	summarize rank if indi_missing_rank_mod == 0
	assert `r(max)' <= 1 & `r(min)' > 0
	
	* 2. Set cutoff as the last *marginal* student who gets an offer
	bys SchoolID: egen double Cutoff  = max(Assignment * Marginal * rank)
	gen double DefaultCutoff  = min(1, Cutoff / (1 - Advantage))
	
*======================================= 3. Calculate bandwidth ====================================================================================
	
	// Generate indicator variables for programs using rank variable to break ties
	egen NonLotteryID = group(SchoolID) if NonLottery == 1
	
	// Generate centered rank variable (cutoff = 0)
	gen Centered = rank - Cutoff
	
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
			if "`bw_type'" == "IK" {
			noi cap: _02_rdob_mod2 `test' Centered if (NonLotteryID == `i') & (FullyRanked == 1) & (Marginal == 1), ck(5.40)
			if _rc == 0 replace IK_`test' = `r(h_opt)' if NonLotteryID == `i'
			}
			
			* CCFT
			else if "`bw_type'" == "CCFT" {
			noi cap: _02_rdbwselect `test' Centered if (NonLotteryID == `i') & (FullyRanked == 1) & (Marginal == 1), kernel(uniform) c(0)
			if _rc == 0 replace CCFT_`test' = `e(h_mserd)' if NonLotteryID == `i'
			}
			
			* Catch incorrect
			else {
				di "Incorrect bandwidth option (must be IK or CCFT)"
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

	*==========================================================================================================================================================================
		
	* 4. Calculate T

	*	Always seated
		// Applicant clears marginal priority (Theta^a)
		// or is marginal but below the bandwidth at screened program or below
		// or at the cutoff at screened program where we couldn't get a bandwidth 
		gen t_a = (MarginalPriority > Priority) ///
			| (NonLottery == 1 & Marginal == 1 & below_bw == 1 ) ///
			| (NonLottery == 1 & Marginal == 1 & Centered <= 0 & missing(bw))

	*	Never seated
		// Applicant fails to clear marginal priority (Theta^n)
		// or is marginal but above the bandwidth at screened program 
		// or above the cutoff at screened program where we couldn't get a bandwidth 
		gen t_n = (MarginalPriority < Priority ) ///
			| (NonLottery == 1 & Marginal == 1 & above_bw == 1 )   ///
			| (NonLottery == 1 & Marginal == 1 & Centered > 0 & missing(bw))
			
	*	Conditionally seated
		// Applicant is marginal and in bandwidth at screened program
		// or marginal at a lottery school
		gen t_c = (NonLottery == 1 & MarginalPriority == Priority & in_bw == 1)  ///
			| (NonLottery == 0 & MarginalPriority == Priority)

	// Check that we partition the set of applicants
	egen check = rowtotal(t_?)
	summarize check
	assert `r(min)' == 1 & `r(max)' == 1
	drop check

	// Code t's for screening risk pscore. These will treat the lottery numbers as fixed.
	// Hence, an applicant can't be marginal at a lottery school, only t=a or t=n

	*	Always seated
		gen bw_t_a = (MarginalPriority > Priority) ///
			| (NonLottery == 1 & Marginal == 1 & below_bw == 1) ///
			| (NonLottery == 1 & Marginal == 1 & Centered <= 0 & missing(bw))  ///
			| (NonLottery == 0 & Marginal == 1 & rank <= Cutoff)

	*	Never seated
		gen bw_t_n = (MarginalPriority < Priority)  ///
			| (NonLottery == 1 & Marginal == 1 & above_bw == 1) ///
			| (NonLottery == 1 & Marginal == 1 & Centered > 0 & missing(bw)) ///
			| (NonLottery == 0 & Marginal == 1 & rank > Cutoff)

	* 	Conditionally seated
		gen bw_t_c =  (NonLottery == 1 & MarginalPriority == Priority & in_bw == 1)

	// Check that t's partition all applicants
	egen check = rowtotal(bw_t_?)
	summarize check
	assert `r(min)' == 1 & `r(max)' == 1
	drop check

*======================================================================================================================
	
	* 5. Calculate MID

	* 	Case 1: ever get more preferred
		// Applicant is ever in t=a at any schools above school s
		// (for screened schools you are marginal at the school but are below the window left of the bandwidth)
		sort StudentID ChoiceRank
		gen ever_seated_more_preferred = 0
		la var ever_seated_more_preferred "1 if you ever cleared marginal priority at a more preferred school"
		by StudentID: replace ever_seated_more_preferred =  max(ever_seated_more_preferred[_n-1 ], t_a[ _n-1 ]) if _n > 1  //maximum so that if its ever 1 the following chain will be 1.

	* 	Case 2: never get more preferred
		// Applicant is always in t=n at any higher ranked school
		sort StudentID ChoiceRank
		// By convention MID is 0 at first choice, because applicant can never get a better choice
		gen never_get_more_preferred = 1
		la var never_get_more_preferred "Student never clears marginal priority at more preferred schools"
		by StudentID: replace never_get_more_preferred =  min(never_get_more_preferred[_n-1 ], t_n[ _n-1 ]) if _n > 1

	* 	Case 3: conditionally get more preferred
		// Applicant is in t=c in at least one more preferred school, but never t=a

		// Check if applicant is ever marginal at a more preferred school
		sort StudentID ChoiceRank
		gen ever_marginal_more_preferred = 0
		by StudentID: replace ever_marginal_more_preferred = max(ever_marginal_more_preferred[_n-1 ], t_c[ _n-1 ]) if _n > 1

		// Check if applicant is always either t_c or t_n at more preferred schools (never t_a)
		gen either_t_cn = max(t_c, t_n)
		gen always_t_cn_more_preferred = 1
		by StudentID: replace always_t_cn_more_preferred =  min(always_t_cn_more_preferred[_n-1 ], either_t_cn[ _n-1 ]) if _n > 1

		// Check if applicant is t_a but with at least one marginal school (non-degenerate better set risk)
		gen sometimes_get_more_preferred = (always_t_cn_more_preferred == 1) & (ever_marginal_more_preferred == 1)
		la var sometimes_get_more_preferred "You aren't guaranteed a spot at a higher rank school but you are at least marginal in a more preferred school"

	// Check that these definitions partition the set of applicants
	egen check = rowtotal(sometimes_get_more_preferred   ever_seated_more_preferred   never_get_more_preferred)
	su check
	assert (`r(max)' == 1) & (`r(min)'  == 1)
	drop check

	***	MID computation
		// MID boils down to risk generated by lottery schools in the better set
		// Initialize at missing. Should not have missing for lottery applications
		gen double mid = .

	* case 1
		// set to 0 if applicant is always in t_n at more preferred lottery schools
		replace mid = 0 if (never_get_more_preferred == 1)

	* case 2
		// set to 1 if applicant is ever t_a at a more preferred lottery school
		// (explicitly restricting to lottery schools doesn't change p-score calculation since risk will be degenerate anyway)
		replace mid = 1 if (ever_seated_more_preferred == 1)

	* case 3
		// non-degenerate better set risk
		sort StudentID ChoiceRank
		// only consider the lagged cutoff if applicant is t_c at that lottery school.
		by StudentID: gen lagged_lottery_cutoff = DefaultCutoff[_n-1 ] * t_c[_n-1] * (NonLottery[_n-1] == 0)

		by StudentID: replace mid = max(mid[_n-1], lagged_lottery_cutoff)  if (sometimes_get_more_preferred == 1)
		// Replace first lottery choice to zero.
		by StudentID: replace mid = 0 if (_n == 1)

		// Fill in mid for non lottery schools, we need this to calculate the pscores
		sort StudentID ChoiceRank
		by StudentID: replace mid = 0 if (_n ==1)
		by StudentID: replace mid = mid[_n-1] if (_n > 1) & (mid == .)
	
*======================================================================================================================
	
	* 6. Calculate propensity scores (pscores)

		sort StudentID ChoiceRank

		// Local score with single non-stochastic tie-breaking
		gen double pscore_rank = 0 if (NonLottery == 1) & (t_n == 1 | ever_seated_more_preferred == 1)
		replace pscore_rank = 1 if (NonLottery == 1) & (t_a == 1 &  ever_seated_more_preferred == 0)
		replace pscore_rank = 0.5 if (NonLottery == 1) & (t_c == 1 &  ever_seated_more_preferred == 0)

		// Solve running count problem (little m)
		// We need to know how many times an applicant has pscore_rank == 0.5 at more preferred screened schools.
		// pscore_rank == 1 is already taken care of with ever_seated_more_preferred
		sort StudentID ChoiceRank
		by StudentID: gen number_of_bw = 0 if (_n == 1)
		by StudentID: replace number_of_bw = number_of_bw[_n-1] + ((pscore_rank[_n-1] == 0.5) * (NonLottery[_n-1] == 1)) if (_n > 1)

		sort StudentID ChoiceRank
		su pscore

		*** Code local general risk pscore
			gen double pscore = .

		* 	Degenerate case
			replace pscore = 0 if (t_n == 1) | (ever_seated_more_preferred == 1)

		*	Lottery number truncation
			gen double one_minus_mid = (1 - mid)
			la var one_minus_mid "Lottery number truncation"
			
		*	Product of one-minus-mid (lambda)
			bysort StudentID : gen double lambda = one_minus_mid[1]
			by StudentID : replace lambda = lambda[_n-1] * one_minus_mid if (_n > 1) & (NonLottery == 0)

		*	Better set risk only
			replace pscore = 1 if (t_a == 1) & (ever_seated_more_preferred == 0)
			replace pscore =  lambda * 0.5^(number_of_bw) ///
				if (t_a == 1) & (ever_seated_more_preferred == 0)

		*	Lottery school with risk at s
			replace pscore =  lambda * 0.5^(number_of_bw) * max(0, (Cutoff - mid) / one_minus_mid) ///
				if (t_c == 1) & (ever_seated_more_preferred == 0) & (NonLottery == 0)

		*	Screened school with risk at s
			replace pscore =  lambda * 0.5^(number_of_bw) * pscore_rank ///
				if (t_c == 1) & (ever_seated_more_preferred == 0) & (NonLottery == 1)

			count if pscore == .
			assert `r(N)' ==  0

		// Compute frequency score
		bys SchoolID mid t_a t_c t_n : egen double pscore_frequency = mean(Assignment)

		// For applicants who are in t_n, MID doesn't matter.
		bys SchoolID t_n: egen double frequency_offer_intermediate = mean(Assignment)
		replace pscore_frequency = frequency_offer_intermediate if (t_n == 1)
		drop frequency_offer_intermediate

		// Generate indicator for offer if pscore was 0
		bys StudentID : egen ever_0_got_offer = max(Assignment == 1 & pscore == 0)
		compress

		// Save
		save "pscore_`year'_`grade'.dta", replace

*=============================================================================

	* 7. Create running variable control
	preserve
		* Settings
		set trace off
		set tracedepth 1

		use "pscore_`year'_`grade'.dta", clear

		* Only compute for programs that have a bandwidth
		keep if has_bw == 1

		/*
		The RV controls are going to be
		1- applying to the program
		2- being in the bandwidth
		3- the RV in the bandwidth
		4- the RV in the bandwidth + being above the cutoff
		*/

		// RV Control 1
		gen byte rv_app_  = 1

		// RV Control 2
		gen byte rv_in_bw_ = (t_c == 1) & (rv_app_ == 1)

		// RV Control 3
		gen rv_ =  Centered * rv_in_bw_

		// RV Control 4
		gen rv_above_ = (rv_ > 0) * Centered * rv_in_bw_

		// Alternative versions of RV controls

		// Square the running variable
		gen quad_ =  Centered^2 * rv_in_bw_
		gen quad_above_ =  (rv_ > 0) * Centered^2 * rv_in_bw_

		// Keep relevant variables
		keep StudentID rv_* SchoolID quad_*

		// Reshape to make unique by applicants
		reshape wide rv_in_bw_ rv_ rv_above_ rv_app_ quad_ quad_above_, i(StudentID) j(SchoolID)
		
		keep StudentID rv_* quad_*
		duplicates drop
		isid StudentID

		compress
		save "runvar_control_`year'_`grade'.dta", replace
	restore
end



















