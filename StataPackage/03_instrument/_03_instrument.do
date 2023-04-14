capture program drop _03_instrument
program define _02_Master
    version 15.0
    
    syntax [anything] [if]
	
	quietly{	
		levelsof Year, local(yearlist)
		foreach year of local yearlist {
			levelsof Grade, local(gradelist)
			foreach grade of local gradelist {
				_02_pscore `year' `grade'
			}

end
