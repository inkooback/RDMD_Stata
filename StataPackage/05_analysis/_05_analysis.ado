capture program drop _05_analysis
program define _05_analysis
    version 15.0
    
    syntax [anything] [if]
	
	use "/Users/inkoo/Desktop/Spring 23/Atila/code/Stata/stacked.dta", clear
	
	* 1. Set pscores
		
		// 1.1 Set pscores - make dummies for each treatment
		foreach t of varlist treatment* {
			egen int pindex_`t' = group(pscore_`t')
			local pdummy_`t' i.pindex_`t'
			}
			
		// 1.2 Tag "good cells" (1 if strictly between 0 and 1) for treated schools
		foreach t of varlist treatment* {
			if "`t'" != "treatment_0"{
				gen good_`t' = !inlist(pscore_`t', 1, 0)
				}
			}
			
		// Number of sectors with risk	
		egen risk = rowtotal(good_*)
		
		// 1.3. pscore dummies
		local pdummy_multi
		
		foreach t of varlist treatment* {
			local pdummy_multi `pdummy_multi' `pdummy_`t''
			}
		
	* 2. Set controls (covariates & running variable control)
	
		// Define controls
		local controls
		local control_cov
		local control_run
		
		foreach run of varlist rv_* {
			replace `run' = 0 if missing(`run') 
			}
		
		// If more than one year, interact all controls by year
		
		unique Year
		if `r(sum)' > 1 {
			
			// Covariates (categorical)
			foreach cov of varlist dum_Covariate_cat* {
				local control_cov `control_cov' `cov'
				}
				
			// Covariates (continuous)
			foreach cov of varlist Covariate_con* {
				local control_cov `control_cov' c.`cov'
				}	
				
			// rv controls
			foreach run of varlist rv_* {
				local control_run `control_run' `run'
				}
				
			// Merge
			local controls `controls' `control_cov'
			local controls `controls' `control_run'
			
			// Interact if the `controls' local macro is non-empty
			if "`controls'" != "" {
				// Local controls Year##(`controls')
				di in red "In controls, controls are: `controls'"
				local controls_mod
				local len = wordcount("`controls'")
				forval i = 1 / `len'  {
					local var = word("`controls'", `i')
					di "`var'"
					local controls_mod `controls_mod' Year##`var'
					}
				di as text "After year interaction loop, controls are: `controls_mod'"
				local controls `controls_mod'
				}
			}
		
	* 3. Rename back (Enrollment, Covariates, Outcomes)
		
		// Outcome, Enrollment
		if $out_con_length > 0{
			rename (Outcome_con*) ($user_Outcome_con)
			}
		
		local user_outcomes $user_Outcome_con
		// Local user_enrolls $user_Enrollment*
		
		// covariate list
		local covlist
		
		// Categorical covariates (use values)
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
	
	// Set directory
	mkdir results
	cd results
	
	// 4.1. Raw balance / OLS regression
	
	// 4.1.1. Raw balance
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
		
		// Get F-statistics
		mat list r(stats)
		mat rename r(stats) raw_stats
		mat raw_stats = raw_stats[1,1...]
		mat rownames raw_stats = Uncontrolled
		
		// Get coefficients
		mat list r(coefs)
		mat rename r(coefs) raw
		mat list raw
		scalar r = rowsof(raw)

		// N
		mat A = J(r, 1, _N)
		mat colnames A = N
		mat raw = raw, A
		
		// Number of types
		qui unique rdmd_Type
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
		
		*********** Analysis for each treatment dummy ***********
			
		// Enroll_x_Treat into dummies
		levelsof Enroll_x_Treat, local(extset)
		foreach t of local extset {
			gen enroll_treatment_`t' = (Enroll_x_Treat == `t')
			}
		
		foreach t of varlist treatment_* {
			if "`t'" != "treatment_0"{
			local treat  = "`t'"
			dis "`treat'"
			foreach out of varlist `user_outcomes' {
				ivreg2 `out' enroll_`t' `covlist', robust partial(`covlist')
				estimates store `out'
				}
			
			// Output tables
			esttab `user_outcomes' using `treat'_OLS.tex, replace booktabs /*
			*/ title(OLS\label{tab1}) stats(N, fmt(a3)) style(tab) nonumbers /*
			*/ cells(b(star fmt(%9.3f)) se(par)) starlevels(* 0.1 ** 0.05 *** 0.01) nodepvars
			
			mat rename r(coefs) ols, replace
			mat list ols
			scalar r = rowsof(ols)
			
			// N
			mat D = J(r, 1, _N)
			mat colnames D = N
			mat ols = ols, D
			
			// Number of types
			qui unique rdmd_Type
			scalar t = `r(sum)'
			mat E = J(r, 1, t)
			mat colnames E = Types
			mat ols = ols, E
			
			// Number of pscores
			qui unique pscore_`treat'
			scalar t = `r(sum)'
			mat F = J(r, 1, t)
			mat colnames F = Number_of_pscores
			mat ols = ols, F

			esttab matrix(ols, transpose) using `treat'_OLS.tex, replace      // Final Table
			esttab matrix(ols, transpose) using `treat'_OLS.csv, csv replace  // Final Table
			}
		}
		
		*********** Multisector analysis ***********
		// Conduct multi-sector analysis only when there are more than two treatment values
		ds treatment*
		scalar length = `:word count `r(varlist)''
		if length > 2 {
			
			foreach out of varlist `user_outcomes' {
				ivreg2 `out' i.Enroll_x_Treat `covlist', robust partial(`covlist')
				estimates store `out'
				}
			
			// Output tables
			esttab `user_outcomes' using multi_sector_OLS.tex, replace booktabs /*
			*/ title(OLS\label{tab1}) stats(N, fmt(a3)) style(tab) nonumbers /*
			*/ cells(b(star fmt(%9.3f)) se(par)) starlevels(* 0.1 ** 0.05 *** 0.01) nodepvars
			
			mat rename r(coefs) ols, replace
			mat list ols
			scalar r = rowsof(ols)
			
			// N
			mat D = J(r, 1, _N)
			mat colnames D = N
			mat ols = ols, D
			
			// Number of types
			qui unique rdmd_Type
			scalar t = `r(sum)'
			mat E = J(r, 1, t)
			mat colnames E = Types
			mat ols = ols, E
			
			// Number of pscores
			mat F = (.)
			foreach t of varlist treatment* {
				qui unique pscore_`t'
				dis "Propensity scores for `t' have `r(sum)' unique values."
				mat F = F \ `r(sum)'
				}
			// mat F = F \ 1
			mat list F
			mat F = F[3..., 1...]
			
			mat colnames F = Number_of_pscores
			
			mat list ols
			mat list F
			
			mat ols = ols, F
			mat list ols
			// mat ols = ols[2..r-1,1...]

			esttab matrix(ols, transpose) using multi_sector_OLS.tex, replace      // Final Table
			esttab matrix(ols, transpose) using multi_sector_OLS.csv, csv replace  // Final Table
			}
		
	
	// 4.2. Controlled balance / 2SLS regression
	
	// Limit the sample to applicants with risk at at least 1 sector. 
	preserve
		keep if (risk > 0)

		// 4.2.1. Controlled balance
		foreach cov of local covlist {
			ivreg2 `cov' i.Assign_x_Treat `pdummy_multi' `control_run', robust partial(`pdummy_multi' `control_run')
			testparm i.Assign_x_Treat
			estimates store `cov'
			}
		
		// Output tables
		esttab `covlist' using balance.tex, replace booktabs /*
		*/ title(2SLS\label{tab1}) stats(F r2 N, fmt(a3)) style(tab) nonumbers /*
		*/ cells(b(star fmt(%9.3f)) se(par)) nodepvars scalar(F F_diff)
		
		// Get F-statistics
		mat list r(stats)
		mat rename r(stats) control_stats
		mat control_stats = control_stats[1,1...]
		mat rownames control_stats = Controlled
		
		// Get coefficients
		mat list r(coefs)
		mat rename r(coefs) control
		mat list control
		scalar r = rowsof(control)

		// N
		mat D = J(r, 1, _N)
		mat colnames D = N
		mat control = control, D
		
		// Number of types
		qui unique rdmd_Type
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
		
		// Print F-test
		esttab matrix(F_test) using F_test.tex, replace      // Final Table
		esttab matrix(F_test) using F_test.csv, csv replace  // Final Table
		
		// Add OLS / 2SLS header and print out
		esttab matrix(Balance, transpose) using balance.tex, replace mtitle("\textbf{Left half: Uncontrolled. Right half: Controlled}") //Final Table
		esttab matrix(Balance, transpose) using balance.csv, csv replace //Final Table
	restore
		
		// 4.2.2. 2SLS regression
		
		*********** Analysis for each treatment dummy ***********
		
		// Assign_x_Treat into dummies
		levelsof Assign_x_Treat, local(axtset)
		foreach t of local axtset {
			gen assign_treatment_`t' = (Assign_x_Treat == `t')
			}
		
		foreach t of varlist treatment_* {
			preserve
				if "`t'" != "treatment_0"{
					keep if (good_`t' == 1)
					local treat  = "`t'"
					dis "`treat'"
					foreach out of varlist `user_outcomes' {
						ivreg2 `out' (enroll_`t' = assign_`t') `pdummy_multi' `covlist' `control_run', robust partial(`pdummy_multi' `covlist' `control_run') nocollin
						estimates store `out'
						}
					
					// Output tables
					esttab `user_outcomes' using multi_sector_2SLS.tex, replace booktabs /*
					*/ title(2SLS\label{tab1}) stats(N, fmt(a3)) style(tab) nonumbers /*
					*/ cells(b(star fmt(%9.3f)) se(par)) starlevels(* 0.1 ** 0.05 *** 0.01) nodepvars
					
					mat rename r(coefs) two_sls, replace
					mat list two_sls
					scalar r = rowsof(two_sls)
					
					// N
					mat D = J(r, 1, _N)
					mat colnames D = N
					mat two_sls = two_sls, D
					
					// Number of types
					qui unique rdmd_Type
					scalar t = `r(sum)'
					mat E = J(r, 1, t)
					mat colnames E = Types
					mat two_sls = two_sls, E
					
					// Number of pscores
					qui unique pscore_`treat'
					scalar t = `r(sum)'
					mat F = J(r, 1, t)
					mat colnames F = Number_of_pscores
					mat two_sls = two_sls, F

					esttab matrix(two_sls, transpose) using `treat'_2SLS.tex, replace      // Final Table
					esttab matrix(two_sls, transpose) using `treat'_2SLS.csv, csv replace  // Final Table
					}
			restore
			}
			
			
		*********** Multisector analysis ***********
		
	// Conduct multi-sector analysis only when there are more than two treatment values
	if length > 2 {
	
		preserve
			keep if (risk > 0)
			
			foreach out of varlist `user_outcomes' {
				ivreg2 `out' (i.Enroll_x_Treat = i.Assign_x_Treat) `pdummy_multi' `covlist' `control_run', robust partial(`pdummy_multi' `covlist' `control_run')
				estimates store `out'
				}
			
			// Output tables

			esttab `user_outcomes' using multi_sector_2SLS.tex, replace booktabs /*
			*/ title(2SLS\label{tab1}) stats(N, fmt(a3)) style(tab) nonumbers /*
			*/ cells(b(star fmt(%9.3f)) se(par)) starlevels(* 0.1 ** 0.05 *** 0.01) nodepvars
			
			mat rename r(coefs) two_sls, replace
			mat list two_sls
			scalar r = rowsof(two_sls)
			
			// N
			mat D = J(r, 1, _N)
			mat colnames D = N
			mat two_sls = two_sls, D
			
			// Number of types
			qui unique rdmd_Type
			scalar t = `r(sum)'
			mat E = J(r, 1, t)
			mat colnames E = Types
			mat two_sls = two_sls, E
			
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
			mat two_sls = two_sls, F
			mat list two_sls

			esttab matrix(two_sls, transpose) using multi_sector_2SLS.tex, replace      // Final Table
			esttab matrix(two_sls, transpose) using multi_sector_2SLS.csv, csv replace  // Final Table
			
		restore
		}
	
	// Rename back to user's variable names
	rename (StudentID Year Grade) ($user_StudentID $user_Year $user_Grade)
	
	// Drop treatment dummies
	drop treatment*
	
	// Save data (only students at risk)
	save "pscore_results.dta", replace
	
end



