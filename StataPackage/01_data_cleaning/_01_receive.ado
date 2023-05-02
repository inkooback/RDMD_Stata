capture program drop _01_receive
program define _01_receive
    version 15.0
    
    syntax [anything] [if]
	
	noisily{
		
		* Install commands
		ssc inst unique
		ssc install ranktest 
		ssc inst ivreg2
		
		* Download a package for CCFT bandwith calculation
		net install rdrobust, from(https://raw.githubusercontent.com/rdpackages/rdrobust/master/stata) replace
		
	* 1.1. rename variables
		
		// Student ID
		dis "Input your variable name for Student ID" _request(id)
		qui ds
		// throw warning if the input is not in the varlist
		if strpos(r(varlist), "$id") == 0{
			while strpos(r(varlist), "$id") == 0 {
				dis as error "variable $id not found"
				dis "Input your variable name for Student ID" _request(id)
				}
			}
		
		// Year
		dis "Input your variable name for Year" _request(year)
		qui ds
		// throw warning if the input is not in the varlist
		if strpos(r(varlist), "$year") == 0{
			while strpos(r(varlist), "$year") == 0 {
				dis as error "variable $year not found"
				dis "Input your variable name for Year" _request(year)
				}
			}
		
		// Non-lottery indicator
		dis "Input your variable name for NonLottery indicator." _request(nonlottery)	
		qui ds
		// throw warning if the input is not in the varlist
		if strpos(r(varlist), "$nonlottery") == 0{
			while strpos(r(varlist), "$nonlottery") == 0 {
				dis as error "variable $nonlottery not found"
				dis "Input your variable name for NonLottery indicator. Values of this variable has to be binary." _request(nonlottery)
				}
			}
		
		// pass the variable names to _01_rename as a varlist
		_01_rename $id $year grade rank school treatment capacity priority tie $nonlottery group advantage default effective assignment enrollment

	* 1.2. rename covariates
			// 1) categorical
			dis "Input a list (parsed by space) of your variable names for categorical covariates in your dataset. Press enter if you have no categorical covariate." _request(cov_cat_list)
			
			// count the number of 
			global cov_cat_length : word count $cov_cat_list
			qui ds
			
			if $cov_cat_length > 0{
				
				// throw warning if the inpud is not in the varlist
				forvalues i = 1 / $cov_cat_length{
					local cov: word `i' of $cov_cat_list
					if strpos(r(varlist), "`cov'") == 0{
						while strpos(r(varlist), "`cov'") == 0 {
							di as error "variable `cov' not found"
							dis "Input a list (parsed by space) of your variable names for categorical covariates in your dataset. Press enter if you have no categorical covariate." _request(cov_cat_list)
							local cov: word `i' of $cov_cat_list
						}
					}
				}
				
				// check once again
				forvalues i = 1 / $cov_cat_length{
					local cov: word `i' of $cov_cat_list
					if strpos(r(varlist), "`cov'") == 0{
						while strpos(r(varlist), "`cov'") == 0 {
							di as error "variable `cov' not found"
							dis "Input a list (parsed by space) of your variable names for categorical covariates in your dataset. Press enter if you have no categorical covariate." _request(cov_cat_list)
							local cov: word `i' of $cov_cat_list
							}
						}
					}
				
				// pass the variable names to _01_covariate_cat as a varlist
				_01_covariate_cat $cov_cat_list
			}
			
			// 2) countinuous
			dis "Input a list (parsed by space) of your variable names for the rest (continuous) covariates in your dataset. Press enter if you have no continuous covariate." _request(cov_con_list)
			
			// count the number of 
			global cov_con_length : word count $cov_con_list
			qui ds
			
			if $cov_con_length > 0{
				
				// throw warning if the inpud is not in the varlist
				forvalues i = 1 / $cov_con_length{
					local cov: word `i' of $cov_con_list
					if strpos(r(varlist), "`cov'") == 0{
						while strpos(r(varlist), "`cov'") == 0 {
							di as error "varaible `cov' not found"
							dis "Input a list (parsed by space) of your variable names for the rest (continuous) covariates in your dataset. Press enter if you have no continuous covariate." _request(cov_con_list)
							local cov: word `i' of $cov_con_list
							}
						}
					}
					
				// check once again
				forvalues i = 1 / $cov_con_length{
					local cov: word `i' of $cov_con_list
					if strpos(r(varlist), "`cov'") == 0{
						while strpos(r(varlist), "`cov'") == 0 {
							di as error "variable `cov' not found"
							dis "Input a list (parsed by space) of your variable names for the rest (continuous) covariates in your dataset. Press enter if you have no continuous covariate." _request(cov_con_list)
							local cov: word `i' of $cov_con_list
							}
						}
					}
				
				// pass the variable names to _01_covariate_con as a varlist
				_01_covariate_con $cov_con_list
			}
		
	* 1.3. rename outcomes
			// 1) categorical
			dis "Input a list (parsed by space) of your variable names for categorical outcome variables in your dataset. Press enter if you have no categorical outcome variables." _request(out_cat_list)
			
			// count the number of 
			global out_cat_length : word count $out_cat_list
			qui ds
			
			if $out_cat_length > 0 {
				
				// throw warning if the inpud is not in the varlist
				forvalues i = 1 / $out_cat_length{
					local out: word `i' of $out_cat_list
					if strpos(r(varlist), "`out'") == 0{
						while strpos(r(varlist), "`out'") == 0 {
							di as error "variable `out' not found"
							dis "Input a list (parsed by space) of your variable names for categorical outcome variables in your dataset. Press enter if you have no categorical outcome variables" _request(out_cat_list)
							local out: word `i' of $out_cat_list
							}
						}
					}
					
				// check once again
				forvalues i = 1 / $out_cat_length{
					local out: word `i' of $out_cat_list
					if strpos(r(varlist), "`out'") == 0{
						while strpos(r(varlist), "`out'") == 0 {
							di as error "variable `out' not found"
							dis "Input a list (parsed by space) of your variable names for categorical outcome variables in your dataset. Press enter if you have no categorical outcome variables" _request(out_cat_list)
							local out: word `i' of $out_cat_list
							}
						}
					}
				
				// pass the variable names to _01_outcome_cat as a varlist
				_01_outcome_cat $out_cat_list
			}
			
			// 2) countinuous
			dis "Input a list (parsed by space) of your variable names for the rest (continuous) outcome variables in your dataset. Press enter if you have no continuous outcome variables" _request(out_con_list)
			
			// count the number of 
			global out_con_length : word count $out_con_list
			qui ds
			
			if $out_con_length > 0 {
				// throw warning if the inpud is not in the varlist
				forvalues i = 1 / $out_con_length{
					local out: word `i' of $out_con_list
					if strpos(r(varlist), "`out'") == 0{
						while strpos(r(varlist), "`out'") == 0 {
							di as error "variable `out' not found"
							dis "Input a list (parsed by space) of your variable names for the rest (continuous) outcome variables in your dataset. Press enter if you have no continuous outcome variables" _request(out_con_list)
							local out: word `i' of $out_cat_list
							}
						}
					}
					
				// check once again
				forvalues i = 1 / $out_con_length{
					local out: word `i' of $out_con_list
					if strpos(r(varlist), "`out'") == 0{
						while strpos(r(varlist), "`out'") == 0 {
							di as error "variable `out' not found"
							dis "Input a list (parsed by space) of your variable names for the rest (continuous) outcome variables in your dataset. Press enter if you have no continuous outcome variables" _request(out_con_list)
							local out: word `i' of $out_con_list
							}
						}
					}
				
				// pass the variable names to _01_outcome_con as a varlist
				_01_outcome_con $out_con_list 
			}
			
			if ($out_cat_length == 0) & ($out_con_length == 0) {
				dis as error "You must have at least one outcome variable."
				}
	}
end



















