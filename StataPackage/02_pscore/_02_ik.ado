/****Bandwidth ****/

/* This program implements the IK(RESTUD 2011) algorithm for the optimal bandwidth for sharp and fuzzy RD */
/* The program also computes the bandwidth used by DesJardins and McCall (2008) */

capture program drop _02_ik

program define _02_ik, rclass
	version 16.1
	syntax anything [if] [in] [, c(real 0) ibw(real 0) fuzzy(varname) dm(real 0) ck(real 3.4375 )]

	tokenize "`anything'"
	local y `1'
	local x `2'

	/* Handle missing observations and sample restrictions */

	marksample touse
	preserve

	* sample restriction
	if "`if'" != "" {
		keep `if'
	}

	egen missing_values = rowmiss(`anything' `fuzzy')
	keep if missing_values == 0

	/*  Following are the temporary variables this program will use throughout  */
	tempvar d x1 x2 x3 dx1 lambda

	/*  Define variables  */

	gen `d' = (`x' >= `c')
	gen `x1' = (`x' - `c')
	gen `x2' = (`x' - `c')^2
	gen `x3' = (`x' - `c')^3
	gen `dx1' = `d'*`x1'


	/* Step 1: Estimation of density and variances */

	quietly: count
	local N = r(N)
	quietly: count if `x1' < 0
	local Nn = r(N)
	quietly: count if `x1' >= 0
	local Np = r(N)

	di as text "N: `N'; Nn: `Nn'; Np: `Np'"

	quietly: su `x1'
	local Sx2 = r(Var)

	di as text "Sx2: `Sx2'"

	* Set pilot bandwidth
	local h1 = 1.84*sqrt(`Sx2')*(`N')^(-1/5)

	*display in red "PILOT BW MIIKA `h1'"

	* Count number of observations within pilot bw h1 (to the left and right)
	quietly: count if (`x1' >= -`h1' & `x1' < 0)
	local N1n = r(N)
	quietly: count if (`x1' >= 0 & `x1' <= `h1')
	local N1p = r(N)

	* IK eq. 11
	local fx = (`N1n' + `N1p')/(2*`N'*`h1')

	di "h1: `h1'; N1n: `N1n'; N1p: `N1p'; fx: `fx'"
	di as text "in N1p"
	list `x' if (`x1' >= 0 & `x1' <= `h1')

	* IK eq. 12 and 13
	quietly: su `y' if (`x1' >= -`h1' & `x1' < 0)
	local Sy2n = r(Var)
	quietly: su `y' if (`x1' >= 0 & `x1' <= `h1')
	local Sy2p = r(Var)

	di "Sy2n: `Sy2n'; Sy2p: `Sy2p'"

	if ("`fuzzy'" != "") {
		quietly: su `fuzzy' if (`x1' >= -`h1' & `x1' < 0)
		local Sw2n = r(Var)
		quietly: su `fuzzy' if (`x1' >= 0 & `x1' <= `h1')
		local Sw2p = r(Var)
	}

	/* Step 2: Estimation of second derivatives */

	if (`ibw' == 0) {
		quietly: reg `y' `d' `x1' `x2' `x3'
	}

	else {
		quietly: reg `y' `d' `x1' `x2' `x3' if (-`ibw' <= `x1' & `x1' <= `ibw')
	}

	* Setting m(3)(c) as after IK eq. 14
	local m3 = 6*_b[`x3']
	di "m3: `m3'"

	* IK eq. 15
	local hy2n = 3.56*(`Sy2n'/(`fx'*(`m3')^2))^(1/7)*(`Nn')^(-1/7)
	local hy2p = 3.56*(`Sy2p'/(`fx'*(`m3')^2))^(1/7)*(`Np')^(-1/7)
	di "hy2n: `hy2n'; hy2p: `hy2p'"

	* Count number of observations within pilot bw h2 (to the left and right)
	quietly: count if (`x1' >= -`hy2n' & `x1' < 0)
	local Ny2n = r(N)
	quietly: count if (`x1' >= 0 & `x1' <= `hy2p')
	local Ny2p = r(N)
	di "Ny2n: `Ny2n'; Ny2p: `Ny2p'"

	* Estimate the second derivatives of m using local quadratic fit
	quietly: reg `y' `x1' `x2' if (`x1' >= -`hy2n' & `x1' < 0)
	local m2yn = 2*_b[`x2']
	quietly: reg `y' `x1' `x2' if (`x1' >= 0 & `x1' <= `hy2p')
	local m2yp = 2*_b[`x2']
	di "m2yn: `m2yn'; m2yp: `m2yp'"

	if ("`fuzzy'" != "") {
		if (`ibw' == 0) {
			quietly: reg `fuzzy' `d' `x1' `x2' `x3'
		}
		else {
			quietly: reg `fuzzy' `d' `x1' `x2' `x3' if (-`ibw' <= `x1' & `x1' <= `ibw')
		}
		local m3 = 6*_b[`x3']

		local hw2n = 3.56*(`Sw2n'/(`fx'*(`m3')^2))^(1/7)*(`Nn')^(-1/7)
		local hw2p = 3.56*(`Sw2p'/(`fx'*(`m3')^2))^(1/7)*(`Np')^(-1/7)

		quietly: count if (`x1' >= -`hw2n' & `x1' < 0)
		local Nw2n = r(N)
		quietly: count if (`x1' >= 0 & `x1' <= `hw2p')
		local Nw2p = r(N)
		quietly: reg `fuzzy' `x1' `x2' if (`x1' >= -`hw2n' & `x1' < 0)
		local m2wn = 2*_b[`x2']
		quietly: reg `fuzzy' `x1' `x2' if (`x1' >= 0 & `x1' <= `hw2p')
		locl m2wp = 2*_b[`x2']
	}

	/* Step 3: Calculation of regularization terms */

	* IK eq. 16
	local ryp = (2160*`Sy2p')/(`Ny2p'*(`hy2p')^4)
	local ryn = (2160*`Sy2n')/(`Ny2n'*(`hy2n')^4)
	di "ryp: `ryp'; ryn: `ryn'"

	* IK eq. 17
	local hy = `ck'*(((`Sy2n' + `Sy2p')/(`fx'*((`m2yp' - `m2yn')^2 + (`ryp' + `ryn'))))^(1/5))*((`N')^(-1/5))

	if ("`fuzzy'" ~= "") {
		local rwp = (2160*`Sw2p')/(`Nw2p'*(`hw2p')^4)
		local rwn = (2160*`Sw2n')/(`Nw2n'*(`hw2n')^4)
		local hw = `ck'*((`Sw2n' + `Sw2p')/(`fx'*((`m2wp' - `m2wn')^2 + (`rwp' + `rwn'))))^(1/5)*(`N')^(-1/5)
	}

	/* Compute the final bandwidth */

	local h_opt = `hy'

	if ("`fuzzy'" ~= "") {
		gen `lambda' = (1 - abs(`x1'/`hy'))*(abs(`x1'/`hy') <= 1)
		quietly: reg `y' `d' `x1' `dx1' [aw = `lambda']
		local rf = _b[`d']
		drop `lambda'

		gen `lmbda' = (1 - abs(`x1'/`hw'))*(abs(`x1'/`hw') <= 1)
		quietly: reg `fuzzy' `d' `x1' `dx1' [aw = `lambda']
		local fs = _b[`d']
		drop `lambda'

		quietly corr `y' `fuzzy' if (`x1' >= -`h1' & `x1' < 0), c
		local Sywn = r(cov_12)
		quietly: corr `y' `fuzzy'  if (`x1' >= 0 & `x1' <= `h1'), c
		local Sywp = r(cov_12)

		local u  (`Sy2n' + `Sy2p') + (`rf'/`fs')^2*(`Sw2n' + `Sw2p') - 2*(`rf'/`fs')*(`Sywn' + `Sywp')
		local d = `fx'*(((`m2wp' - `m2wn') - (`rf'/`fs')*(`m2wp' - `m2wn'))^2 + (`ryp' + `ryn') + (`rf'/`fs')*(`rwp' + `rwn'))
		local h_opt = `ck'*(`u'/`d')^(1/5)*(`N')^(-1/5)
	}

	* Option for DesJardins McCall (2009)
	if (`dm' ~= 0) {
		local h_opt = `ck'*((`Sy2n' + `Sy2p')/(`fx'*((`m2yp')^2 + (`m2yn')^2)))^(1/5)*(`N')^(-1/5)
	}

	/* Output */

	display "Optimal bandwidth (h_opt) = `h_opt'"
	return scalar h_opt = `h_opt'
	return scalar h_pilot = `h1'
	local sumvars = `Sy2n' + `Sy2p'

	restore


end
