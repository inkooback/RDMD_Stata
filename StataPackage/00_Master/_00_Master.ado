capture program drop _00_Master
program define _00_Master
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
		dis "Input your variable name for Student ID" _request(id)
		
		qui ds
		// throw warning if the inpud is not in the varlist
		if strpos(r(varlist), "$id") == 0{
			while strpos(r(varlist), "$id") == 0 {
				di as error "variable $id not found"
				dis "Input your variable name for Student ID" _request(id)
				}
			}

		dis "Input your variable name for Year" _request(year)
		dis "Input your variable name for NonLottery indicator. Values of this variable has to be binary." _request(nonlottery)
		
		_01_rename $id $year grade rank school treatment capacity priority tie $nonlottery group advantage default effective assignment enrollment

		* 1.2. rename covariates
			// 1) categorical
			dis "Input a list (parsed by space) of your variable names for categorical covariates in your dataset" _request(cov_cat_list)
			
			// count the number of 
			local length : word count $cov_cat_list
			qui ds
			
			// throw warning if the inpud is not in the varlist
			forvalues i = 1 / `length'{
				local cov: word `i' of $cov_cat_list
				if strpos(r(varlist), "`cov'") == 0{
					while strpos(r(varlist), "`cov'") == 0 {
						di as error "variable `cov' not found"
						dis "Input a list (parsed by space) of your variable names for categorical covariates in your dataset" _request(cov_cat_list)
						local cov: word `i' of $cov_cat_list
						}
					}
				}
				
			// check once again
			forvalues i = 1 / `length'{
				local cov: word `i' of $cov_cat_list
				if strpos(r(varlist), "`cov'") == 0{
					while strpos(r(varlist), "`cov'") == 0 {
						di as error "variable `cov' not found"
						dis "Input a list (parsed by space) of your variable names for categorical covariates in your dataset" _request(cov_cat_list)
						local cov: word `i' of $cov_cat_list
						}
					}
				}
			
			_01_covariate_cat $cov_cat_list
			
			// 2) countinuous
			dis "Input a list (parsed by space) of your variable names for the rest (continuous) covariates in your dataset" _request(cov_con_list)
			
			// count the number of 
			local length : word count $cov_con_list
			qui ds
			// throw warning if the inpud is not in the varlist
			forvalues i = 1 / `length'{
				local cov: word `i' of $cov_con_list
				if strpos(r(varlist), "`cov'") == 0{
					while strpos(r(varlist), "`cov'") == 0 {
						di as error "varaible `cov' not found"
						dis "Input a list (parsed by space) of your variable names for the rest (continuous) covariates in your dataset" _request(cov_con_list)
						local cov: word `i' of $cov_con_list
						}
					}
				}
				
			// check once again
			forvalues i = 1 / `length'{
				local cov: word `i' of $cov_con_list
				if strpos(r(varlist), "`cov'") == 0{
					while strpos(r(varlist), "`cov'") == 0 {
						di as error "variable `cov' not found"
						dis "Input a list (parsed by space) of your variable names for the rest (continuous) covariates in your dataset" _request(cov_con_list)
						local cov: word `i' of $cov_con_list
						}
					}
				}
				
			_01_covariate_con $cov_con_list
		
		* 1.3. rename outcomes
			// 1) categorical
			dis "Input a list (parsed by space) of your variable names for categorical outcome variables in your dataset." _request(out_cat_list)
			
			// count the number of 
			local length : word count $out_cat_list
			qui ds
			
			// throw warning if the inpud is not in the varlist
			forvalues i = 1 / `length'{
				local out: word `i' of $out_cat_list
				if strpos(r(varlist), "`out'") == 0{
					while strpos(r(varlist), "`out'") == 0 {
						di as error "variable `out' not found"
						dis "Input a list (parsed by space) of your variable names for categorical outcome variables in your dataset" _request(out_cat_list)
						local out: word `i' of $out_cat_list
						}
					}
				}
				
			// check once again
			forvalues i = 1 / `length'{
				local out: word `i' of $out_cat_list
				if strpos(r(varlist), "`out'") == 0{
					while strpos(r(varlist), "`out'") == 0 {
						di as error "variable `out' not found"
						dis "Input a list (parsed by space) of your variable names for categorical outcome variables in your dataset" _request(out_cat_list)
						local out: word `i' of $out_cat_list
						}
					}
				}
			
			_01_outcome_cat $out_cat_list
			
			// 2) countinuous
			dis "Input a list (parsed by space) of your variable names for the rest (continuous) outcome variables in your dataset" _request(out_con_list)
			
			// count the number of 
			local length : word count $out_con_list
			qui ds
			
			// throw warning if the inpud is not in the varlist
			forvalues i = 1 / `length'{
				local out: word `i' of $out_con_list
				if strpos(r(varlist), "`out'") == 0{
					while strpos(r(varlist), "`out'") == 0 {
						di as error "variable `out' not found"
						dis "Input a list (parsed by space) of your variable names for the rest (continuous) outcome variables in your dataset" _request(out_con_list)
						local out: word `i' of $out_cat_list
						}
					}
				}
				
			// check once again
			forvalues i = 1 / `length'{
				local out: word `i' of $out_con_list
				if strpos(r(varlist), "`out'") == 0{
					while strpos(r(varlist), "`out'") == 0 {
						di as error "variable `out' not found"
						dis "Input a list (parsed by space) of your variable names for the rest (continuous) outcome variables in your dataset" _request(out_con_list)
						local out: word `i' of $out_con_list
						}
					}
				}
			
			_01_outcome_con $out_con_list 

		* 1.4. missing data
		_01_missing

		* 1.5. feasibility check
		* _01_check
		
		save "step1_finished.dta", replace
		
		dis "Choose bandwidth type (IK / CCFT). Default: IK" _request(type)
		dis "Choose bandwidth population criterion (integer). Default: 5" _request(criterion)
		
		local counter = 0
		levelsof Year, local(yearlist)
		foreach year of local yearlist {
			global Year = `year'
			use "step1_finished.dta", clear
			keep if (Year == `year')
			
			levelsof Grade, local(gradelist)
			foreach grade of local gradelist {
				global Grade = `grade'
				use "step1_finished.dta", clear
				keep if (Year == `year') & (Grade == `grade')

				_02_pscore $type $criterion
				_03_create
			}
		}
		_04_stack

		* _05_analysis
	}
end



















