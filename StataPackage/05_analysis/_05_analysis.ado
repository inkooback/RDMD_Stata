capture program drop _05_analysis
program define _05_analysis
    version 15.0
    
    syntax [anything] [if]
	
	use "stacked.dta", clear
	
	* 1. Set pscores
		
		// 1.1 Set pscores - make dummies for each treatment
		foreach t of varlist treatment* {
			egen int pindex_`t' = group(pscore_`t')
			local pdummy_`t' i.pindex_`t'
		}
			
		// 1.2 Tag "good cells" (not 0 or 1 --> 1)
		foreach t of varlist treatment* {
			gen good_`t' = !inlist(pscore_`t', 1, 0)
		}
		
		// 1.3. dummies
		local pdummy_multi
		
		foreach t of varlist treatment* {
			local pdummy_multi `pdummy_multi' `pdummy_`t''
		}
		
	* 2. Set controls (covariates & running variable control)
	
		// Define controls
		local controls
		local control_cov
		local control_run

		// Covariates and running variable controls
		// local controls `controls' Covariate_*
		// local controls `controls' rv_*
		
		foreach run of varlist rv_* {
			replace `run' = 0 if missing(`run') 
			}
		
		// If more than one year, interact all controls by year
		
		unique Year
		if `r(sum)' > 1 {
			
			// covariates (categorical)
			foreach cov of varlist dum_Covariate_cat* {
				local control_cov `control_cov' `cov'
				}
				
			// covariates (continuous)
			foreach cov of varlist Covariate_con* {
				local control_cov `control_cov' c.`cov'
				}	
				
			// rv controls (categorical)
			foreach run of varlist rv_app* {
				local control_run `control_run' `run'
				}
				
			// merge
			local controls `controls' `control_cov'
			local controls `controls' `control_run'
			
			// Interact if controls local is non-empty
			if "`controls'" != "" {
				//local controls Year##(`controls')
					di in red "In controls, controls are: `controls'"
					local controls_mod
					local len = wordcount("`controls'")
					forval i = 1 / `len'  {
						local var = word("`controls'", `i')
						dis "`var'"
						local controls_mod `controls_mod' Year##`var'
					}
					dis as text "After year interaction loop, controls are: `controls_mod'"
				local controls `controls_mod'
			}
		}
	
	// 3. Set endogenous variables and instruments
		
		/*
		foreach enroll of varlist Enroll_t* {
				local enrolls `enrolls' `enroll'
				}
		
		foreach assign of varlist Assign_t* {
				local assigns `assigns' `assign'
				local raw_col "`raw_col'" "raw_`assign' "
				local control_col "`control_col'" "control_`assign' "
				}
		*/
		
	// 3. Rename back
		
		/*
		if $out_cat_length > 0 {
			rename (Outcome_cat*) ($user_Outcome_cat)	
		}
		*/
		
		// Outcome, Enrollment
		if $out_con_length > 0{
			rename (Outcome_con*) ($user_Outcome_con)
		}
		
		local user_outcomes $user_Outcome_con
		// local user_enrolls $user_Enrollment*
		
		// Categorical covariates (use values)
		
		local covlist
		if $cov_cat_length > 0{
			rename (Covariate_cat*) ($user_Covariate_cat)
			rename (*dum_Covariate_cat*) (cc**)
			forvalues i = 1 / $cov_cat_length{
				local cov: word `i' of $cov_cat_list
				rename (*cc`i'*) (`cov'**), r
				local covlist `covlist' `r(newnames)'
				}
			}
		
		// Continuous covariates 
		if $cov_con_length > 0{
			rename (Covariate_con*) ($user_Covariate_con), r
			local covlist `covlist' `r(newnames)'
			}
			
		dis "`covlist'"
	
	// erase "stacked.dta"
	
	* 4. Analysis
	
	// 4.1. Raw balance / OLS regression
	
	// 4.1.1. raw balance
		// 1. raw
		foreach cov of local covlist {
			ivreg2 `cov' i.Assign_x_Treat
 			testparm i.Assign_x_Treat
			estimates store `cov'
			}
		
		// Output tables
		matrix drop _all
		esttab `covlist' using balance.tex, replace booktabs /*
		*/ title(2SLS\label{tab1}) stats(F r2 N, fmt(a3)) style(tab) nonumbers /*
		*/ cells(b(star fmt(%9.3f)) se(par)) nodepvars
		
		// get F-statistics
		mat list r(stats)
		mat rename r(stats) raw_stats
		mat raw_stats = raw_stats[1,1...]
		mat rownames raw_stats = Uncontrolled
		
		// get coefficients
		mat list r(coefs)
		mat rename r(coefs) raw
		mat list raw
		scalar r = rowsof(raw)

		// N
		mat A = J(r, 1, _N)
		mat colnames A = N
		mat raw = raw, A
		
		// Number of types
		qui unique Type
		scalar t = `r(sum)'
		mat B = J(r, 1, t)
		mat colnames B = Types
		mat raw = raw, B
		
		// Number of pscores
		mat C = (.)
		foreach t of varlist treatment* {
			qui unique pscore_`t'
			dis "Propensity scores for `t' have `r(sum)' unique values."
			mat C = C \ `r(sum)'
			}
		mat C = C \ 1
		mat C = C[2..r+1,1...]
		
		mat colnames C = Number_of_pscores
		mat raw = raw, C
		
		mat raw = raw[2..r-1,1...]
		mat list raw
		
	// 4.1.2. OLS
		
		foreach out of varlist `user_outcomes' {
			ivreg2 `out' i.Enroll_x_Treat
			estimates store `out'
			}
		/*
		foreach out of varlist `user_outcomes' {
			ivreg2 `out' `user_enrolls'
			estimates store `out'
			}
		*/
		
		// Output tables
		esttab `user_outcomes' using OLS.tex, replace booktabs /*
		*/ title(OLS\label{tab1}) stats(N, fmt(a3)) style(tab) nonumbers /*
		*/ cells(b(star fmt(%9.3f)) se(par)) starlevels(* 0.1 ** 0.05 *** 0.01) nodepvars
		
		mat rename r(coefs) ols
		mat list ols
		scalar r = rowsof(ols)
		mat ols = ols[2..r-1,1...]
		
		mat G = (6001 \ 6001)
		mat colnames G = N
		mat ols = ols, G

		esttab matrix(ols, transpose) using ols.tex, replace //Final Table
		esttab matrix(ols, transpose) using ols.csv, csv replace //Final Table
		
	
	// 4.2. control balance / 2SLS regression
	
	// limit the sample to applicants with risk at at least 1 sector. 
	preserve
		egen risk = rowtotal(good_*)
		keep if (risk > 0)

		// 5.2.1. control balance
		foreach cov of local covlist {
			ivreg2 `cov' i.Assign_x_Treat `pdummy_multi' `control_run', robust partial(`pdummy_multi' `control_run')
			testparm i.Assign_x_Treat
			estimates store `cov'
		}
		
		// Output tables
		esttab `covlist' using balance.tex, replace booktabs /*
		*/ title(2SLS\label{tab1}) stats(F r2 N, fmt(a3)) style(tab) nonumbers /*
		*/ cells(b(star fmt(%9.3f)) se(par)) nodepvars scalar(F F_diff)
		
		// get F-statistics
		mat list r(stats)
		mat rename r(stats) control_stats
		mat control_stats = control_stats[1,1...]
		mat rownames control_stats = Controlled
		
		// get coefficients
		mat list r(coefs)
		mat rename r(coefs) control
		mat list control
		scalar r = rowsof(control)

		// N
		mat D = J(r, 1, _N)
		mat colnames D = N
		mat control = control, D
		
		// Number of types
		qui unique Type
		scalar t = `r(sum)'
		mat E = J(r, 1, t)
		mat colnames E = Types
		mat control = control, E
		
		// Number of pscores
		mat F = (.)
		foreach t of varlist treatment* {
			qui unique pscore_`t'
			dis "Propensity scores for `t' have `r(sum)' unique values."
			mat F = F \ `r(sum)'
			}
		mat F = F \ 1
		mat F = F[2..r+1,1...]
		
		mat colnames F = Number_of_pscores
		mat control = control, F
		mat list control
		
		// Merge with raw balance
		mat Balance = raw\control
		mat F_test = raw_stats\control_stats
		
		// print out_cat_length
		esttab matrix(F_test) using f_test.tex, replace  //Final Table
		esttab matrix(F_test) using f_test.csv, csv replace //Final Table
		
		// add OLS / 2SLS header and print out
		esttab matrix(Balance, transpose) using balance.tex, replace mtitle("\textbf{Left half: Uncontrolled. Right half: Controlled}") //Final Table
		esttab matrix(Balance, transpose) using balance.csv, csv replace //Final Table
		
		// 4.2.2. 2SLS regression
	
		foreach out of varlist `user_outcomes' {
			ivreg2 `out' (i.Enroll_x_Treat = i.Assign_x_Treat) `pdummy_multi' `covlist' `control_run', robust partial(`pdummy_multi' `covlist' `control_run')
			estimates store `out'
		}
		
		// Output tables

		esttab `user_outcomes' using 2SLS.tex, replace booktabs /*
		*/ title(2SLS\label{tab1}) stats(N, fmt(a3)) style(tab) nonumbers /*
		*/ cells(b(star fmt(%9.3f)) se(par)) starlevels(* 0.1 ** 0.05 *** 0.01) nodepvars
		
		mat rename r(coefs) two_sls
		mat list two_sls
		scalar r = rowsof(two_sls)
		
		mat H = (75 \ 75)
		mat colnames H = N
		mat two_sls = two_sls, H

		esttab matrix(two_sls, transpose) using 2sls.tex, replace //Final Table
		esttab matrix(two_sls, transpose) using 2sls.csv, csv replace //Final Table
		
	restore
	
	// rename back to user's variable names
	rename (StudentID Year Grade) ($user_StudentID $user_Year $user_Grade)
	
	// drop treatment dummies
	drop treatment*
	
	// save data (only students at risk)
	save "pscore_results.dta", replace
	
end



