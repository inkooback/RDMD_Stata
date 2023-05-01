* Helper program to print results
capture program drop print_results
program define print_results
	syntax varlist ,  model_names( str  ) stat_names(str) stat_labs(str) [outfile(str )  hidevars_print(real 0 ) ]

	if "`outfile'" == "" & `hidevars_print' == 0  {

		#d ;
			esttab `model_names' ,
			style(tab)  nonumbers star(* 0.10 ** 0.05 *** 0.01 )
			cells(b(star fmt(%9.3f)) se(par))  collabels(none) depvar
			stats(`stat_names', fmt(a3) labels("`stat_labs'" ))
			drop(o.*, relax) keep(`varlist' , relax) append;
		#d cr
	}
	else if "`outfile'" == "" & `hidevars_print' == 1 {
		#d ;
			esttab `model_names' ,
			style(tab) nonumbers star(* 0.10 ** 0.05 *** 0.01 )
			cells(b(star fmt(%9.3f)) se(par))  collabels(none) depvar
			stats(`stat_names', fmt(a3) labels("`stat_labs'" ))
			drop(o.*, relax) keep( , relax) append;
		#d cr
	}
	else if "`outfile'" != "" & `hidevars_print' == 0 {
		#d ;
			esttab `model_names' using "`outfile'",
			style(tab) nonumbers  star(* 0.10 ** 0.05 *** 0.01 )
			cells(b(star fmt(%9.3f)) se(par))  collabels(none) depvar
			stats(`stat_names', fmt(a3)  labels("`stat_labs'" ))
			drop(o.*, relax) keep(`varlist' , relax) replace;
		#d cr
	}
	else if "`outfile'" != "" & `hidevars_print' == 1 {
		#d ;
			esttab `model_names' using "`outfile'",
			style(tab) nonumbers  star(* 0.10 ** 0.05 *** 0.01 )
			cells(b(star fmt(%9.3f)) se(par))  collabels(none) depvar
			stats(`stat_names', fmt(a3)  labels("`stat_labs'" ))
			drop(o.*, relax) keep( , relax) replace;
		#d cr
	}

end

capture program drop _05_analysis
program define _05_analysis
    version 15.0
    
    syntax [anything] [if]
	
	use "stacked.dta", clear
	
	* 1. Set pscores
	
		// 1.1 Provide information about the number of unique values of pscore and types
		foreach t of varlist treatment* {
			unique pscore_`t'
			dis "Propensity scores for `t' have `r(sum)' unique values."
		}
		dis "Applicants in your data have $num_type types."
		
		// 1.2 Set pscores - make dummies for each treatment
		foreach t of varlist treatment* {
			egen int pindex_`t' = group(pscore_`t')
			local pdummy_`t' i.pindex_`t'
		}
			
		// 1.3 Tag "good cells" (not 0 or 1 --> 1)
		foreach t of varlist treatment* {
			gen good_`t' = !inlist(pscore_`t', 1, 0)
		}
		
	* 2. Set controls (covariates & running variable control)
	
		// Define controls
		local controls

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
				local controls `controls' `cov'
				}
				
			// covariates (continuous)
			foreach cov of varlist Covariate_con* {
				local controls `controls' c.`cov'
				}	
				
			// rv controls (categorical)
			foreach run of varlist rv_app* {
				local controls `controls' `run'
				}
			
			// Interact if controls local is non-empty
			if "`controls'" != "" {
				//local controls Year##(`controls')
					di in red "In controls, controls are: `controls'"
					local controls_mod
					local len = wordcount("`controls'")
					forval i = 1/`len'  {
						local var = word("`controls'", `i')
						dis "`var'"
						local controls_mod `controls_mod' Year##`var'
					}
					di in red "After year interaction loop, controls are: `controls_mod'"
				local controls `controls_mod'
			}
		}
	
	// save an intermediate file
	erase "stacked.dta"
	save "pscore_results.dta", replace
	
	use "pscore_results.dta", clear
	
	* 3. Run 2SLS regression
	
	// limit the sample to applicants with risk at at least 1 sector. 
		egen risk = rowtotal(good_*)
		keep if (risk > 0)
	
	// 3.1 Multi-sector analysis
	
		// endogenous variables and instruments
		
		foreach enroll of varlist Enroll_* {
				local enrolls `enrolls' `enroll'
				}
		
		foreach assign of varlist Assign_* {
				local assigns `assigns' `assign'
				}
		
		// pscores
		foreach t of varlist treatment* {
			local pdummy_multi `pdummy_multi' `pdummy_`t''
		}
		
		// rename back
		
		if $out_cat_length > 0 {
			rename (Outcome_cat*) ($user_Outcome_cat)	
		}
		
		if $out_con_length > 0{
			rename (Outcome_con*) ($user_Outcome_con)
		}
		
		rename (Enroll_*) ($user_Enrollment*)
		
		local user_outcomes $user_Outcome_cat $user_Outcome_con
		local user_enrolls $user_Enrollment*
		
		// Analysis
		
		foreach out of varlist `user_outcomes' {
			ivreg2 `out' (`user_enrolls' = `assigns') `pdummy_multi' `controls', robust partial(`pdummy_multi' `controls')
			estimates store `out'
		}
		
		// Output tables
		
		esttab `user_outcomes' using multi.tex, replace booktabs /*
		*/ title(2SLS\label{tab1}) stats(r2 N) style(fixed) cells(b(star) se(par)) starlevels(* 0.1 ** 0.05 *** 0.01) nodepvars
		
		/*

	// 3.2 Individual analysis
		foreach t of varlist treatment* {
			foreach out of varlist Outcome* {
				ivreg2 `out' (Enroll_treatment1 = Assign_`t') `pdummy_`t'' `controls', robust  partial(`pdummy_`t'' `controls')
				}
			}
		*/
	// rename back to user's variable names
	rename (StudentID Assign_treatment* Year Grade) ($user_StudentID $user_Assignment* $user_Year $user_Grade)
	
	if $cov_cat_length > 0{
		rename (Covariate_cat*) ($user_Covariate_cat)
	}
	
	if $cov_con_length > 0{
		rename (Covariate_con*) ($user_Covariate_con)
	}
	
	
end


















