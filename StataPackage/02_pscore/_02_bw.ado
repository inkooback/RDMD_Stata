program define _02_bw
    version 15.0
    
    syntax bw_type [if]
	
	preserve

	* Keep only marginal students for the bandwidths
	keep if Marginal == 1
	
	* make a list of variables starts with "Outcome"

	* Standardize all outcomes because we're comparing across bandwidths
	foreach test of Outcomes {
		egen mean_`test' = mean(`test')
		egen sd_`test' = sd(`test')
		gen ss_`test' = (`test' -  mean_`test') / sd_`test'
	}

	* Loop over outcomes
	foreach test of varlist `tests'  {

		* Generate (missing) bandwidth variable
		gen ik_`test' = .

		summarize NonLotteryID
		forval i = 1/`r(max)' {

			* Create bandwidth for applicants who are applying to a non-lottery program that is fully ranked and only look at the marginal applicants.

			* IK
			if `bw_type' == "ik" {
			noi cap: _02_ik `test' Centered if (NonLotteryID == `i') & (FullyRanked == 1) & (Marginal == 1), ck(5.40)
			if _rc == 0 replace ik_`test' = `r(h_opt)' if NonLotteryID == `i'
			}
			
			* CCFT
			else if `bw_type' == "ccft" {
			noi cap: _02_ccft `test' Centered if (NonLotteryID == `i') & (FullyRanked == 1) & (Marginal == 1), kernel(uniform) c(0)
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
	egen `bw_type'_bw = rowmin(list of `bw_type'_`test')

	* Keep program ID and bandwidths
	keep NonLotteryID SchoolID `bw_type'_bw

	* Make unique
	duplicates drop
	isid SchoolID

	* Save
	save "`bw_type'_bw.dta", replace
	
	restore
