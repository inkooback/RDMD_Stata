capture program drop _00_Master
program define _00_Master
    version 15.0
    
    syntax [anything] [if]
	
	noisily{
		
		
		* 1.1. rename variables
		dis "Input your variable name for Student ID" _request(id)
		dis "Input your variable name for Year" _request(year)
		dis "Input your variable name for NonLottery indicator. Values of this variable has to be binary." _request(nonlottery)
		
		_01_rename $id $year grade rank school treatment capacity priority tie $nonlottery group advantage default effective assignment enrollment

		* 1.2. rename covariates
			// 1) categorical
			dis "Input a list (parsed by space) of your variable names for categorical covariates in your dataset." _request(cov_cat_list)
			_01_covariate_cat $cov_cat_list
			
			// 2) countinuous
			dis "Input a list (parsed by space) of your variable names for the rest (continuous) covariates in your dataset." _request(cov_con_list)
			_01_covariate_con $cov_con_list
		
		* 1.3. rename outcomes
			// 1) categorical
			dis "Input a list (parsed by space) of your variable names for categorical outcome variables in your dataset." _request(out_cat_list)
			_01_outcome_cat $out_cat_list
			
			// 2) countinuous
			dis "Input a list (parsed by space) of your variable names for the rest (continuous) outcome variables in your dataset." _request(out_con_list)
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
		
		dis "If you have non-binary treatment, indicate which one you want to use for this analysis" _request(criterion)
		* _05_analysis
	}
end



















