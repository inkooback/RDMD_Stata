{smcl}
{* *!version 9.1.0  2022-10-28}{...}
{viewerjumpto "Syntax" "rdbwselect##syntax"}{...}
{viewerjumpto "Description" "rdbwselect##description"}{...}
{viewerjumpto "Options" "rdbwselect##options"}{...}
{viewerjumpto "Examples" "rdbwselect##examples"}{...}
{viewerjumpto "Stored results" "rdbwselect##stored_results"}{...}
{viewerjumpto "References" "rdbwselect##references"}{...}
{viewerjumpto "Authors" "rdbwselect##authors"}{...}

{title:Title}

{p 4 8}{cmd:rdmd} {hline 2} Conduct 2SLS regression by calculating propensity scores using central assignment data.{p_end}


{marker syntax}{...}
{title:Syntax}

{p 4 8}{cmd:rdmd } 
{p_end}

{synoptset 20 tabbed}{...}
{marker subcommand}{...}
{synopthdr:subcommand}
{synoptline}
{synopt :{cmd:rename}}Rename variables{p_end}
{synopt :{cmd:pscore}}Calculate propensity scores{p_end}
{synopt :{cmd:create}}Create exposure variables and intrumenal variables{p_end}
{synopt :{cmd:stack}}Stack over each year and grade{p_end}
{synopt :{cmd:analysis}}Conduct balance regression, OLS regression, and 2SLS regression{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{p 4 8}{cmd:rdmd} description{p_end}

{p 4 8}All the related Stata ado files can be found in the following website:{p_end}

{p 8 8}{browse "https://github.com/inkooback/RDMD_Stata/":https://github.com/inkooback/RDMD_Stata/}{p_end}


{marker Input}{...}
{title:Input}

{dlgtab:Variables}

{synoptset 35 tabbed}{...}
{marker subcommand}{...}
{synopthdr:Variables}
{synoptline}
{synopt :{cmd:Student ID}}ID number of a student. (Examle: 7){p_end}
{p2coldent:* {cmd:Year}}Year (Example: 2017){p_end}
{p2coldent:* {cmd:Grade}}Grade (Example: 10){p_end}
{synopt :{cmd:Choice Rank}}Rank of the school the student applied to. For example, if the school is the student's first choice, choice rank is 1.{p_end}
{synopt :{cmd:Treatment}}Treatment on the school. 0 for the untreated schools. 1,2,3,... for the treated schools. {p_end}
{synopt :{cmd:Capacity}}Capacity of the program (Example: 280){p_end}
{synopt :{cmd:Priority}}Priority of the student at the school (Example: 2){p_end}
{synopt :{cmd:Default Tie-breaker Index}}Tie-breaker index the student has at the school (Example: 2){p_end}
{p2coldent:* {cmd:Non Lottery}}Index for the non-lottery schools. 0 for lottery schools, 1 for non-lottery schools.{p_end}
{p2coldent:* {cmd:Tie-breaker Student Group Index}}Index for student groups. 0 for the default group. {p_end}
{p2coldent:* {cmd:Advantage}}If this value is 0.7, the student's tie-breaker value will be multiplied by 0.7 at the school.{p_end}
{synopt :{cmd:Default Tie-breaker}}Conduct 2SLS regression{p_end}
{synopt :{cmd:Assignment}}0 = not assigned. 1 = assigned.{p_end}
{synopt :{cmd:Enrollment}}0 = not enrolled. 1 = enrolled.{p_end}
{synopt :{cmd:Outcomes}}Outcome variables. These should be continuous variables.{p_end}
{synopt :{cmd:Covariates}}Covariates. These can be either continuous or categorical.{p_end}
{synoptline}
										
{dlgtab:Bandwidth Type}

{p 4 8}{cmd:IK} Bandwidths estimation suggested by Imbens and Kalyanaraman (2012). This method minimizes the mean squared error (MSE) of the local linear regression estimator, taking into account both the bias and the variance. The bandwidths used here are computed as described by Armstrong and Kolesár (2018) and in the
RDhonest package.{p_end}

{p 4 8}{cmd:CCFT} Bandwidths estimation suggested by Calonico et al. (2017). This method calculates local quadratic estimator with regularized bandwidth selector and bias-correction.{p_end}

{p 4 8} Each method has its own advantages and disadvantages depending on the context. IK bandwidths can be sensitive to outliers and extreme values and does not account for heteroskedasticity or non-normality of the errors. The CCFT method is genrally computationally cmore intensive and complex, requiring a large sample size to perform well. User should consider characteristic of data and select the appropriate bandwidth type.

{dlgtab:Bandwidth Population Criterion}

{p 4 8} There is trade-off between the precision of the estimation and sample size. Choice of bandwidth population criterion Depends on various factors such as the shape and distribution of the running variable, the functional form and smoothness of the regression function, precision of the estimated treatment effect, and the number of covariates included in the model. User should compare result for different criteria and check the sensitivity and robustness of your bandwidths"
{p_end}

    {hline}
	
{marker table}{...}
{title:Table}

{dlgtab:Balance}

{p 4 8} covariates {p_end}

{dlgtab:F-test}

{p 4 8} covariates {p_end}

										
{dlgtab:2SLS}

{p 4 8} description types #pscores {p_end}


{dlgtab:OLS}

{p 4 8} descrpiption {p_end}

    {hline}

	
{marker examples}{...}
{title:Example: real world data}

{p 4 8}Setup{p_end}
{p 8 8}{cmd:. use rdrobust_senate.dta}{p_end}

{p 4 8}MSE bandwidth selection procedure{p_end}
{p 8 8}{cmd:. rdbwselect vote margin}{p_end}

{p 4 8}All bandwidth bandwidth selection procedures{p_end}
{p 8 8}{cmd:. rdbwselect vote margin, all}{p_end}


{marker stored_results}{...}
{title:Stored results}

{p 4 8}{cmd:rdmd} stores the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N_l)}}number of observations to the left of the cutoff{p_end}
{synopt:{cmd:e(N_r)}}number of observations to the right of the cutoff{p_end}
{synopt:{cmd:e(c)}}cutoff value{p_end}
{synopt:{cmd:e(p)}}order of the polynomial used for estimation of the regression function{p_end}
{synopt:{cmd:e(q)}}order of the polynomial used for estimation of the bias of the regression function estimator{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(runningvar)}}name of running variable{p_end}
{synopt:{cmd:e(outcomevar)}}name of outcome variable{p_end}
{synopt:{cmd:e(clustvar)}}name of cluster variable{p_end}
{synopt:{cmd:e(covs)}}name of covariates{p_end}
{synopt:{cmd:e(vce_select)}}vcetype specified in vce(){p_end}
{synopt:{cmd:e(bwselect)}}bandwidth selection choice{p_end}
{synopt:{cmd:e(kernel)}}kernel choice{p_end}


{marker references}{...}
{title:References}

{p 4 8}Abdulkadiroglu, A., J. D. Angrist, Y. Narita, and P. Pathak. 2022.
{browse "https://github.com/inkooback/RDMD_Stata/blob/main/references/Econometrica_2022.pdf":Breaking Ties: Regression Discontinuity Design Meets Market Design}.
{it:Econometrica} 90(1): 117-151.{p_end}

{p 4 8}Calonico, S., M. D. Cattaneo, and M. H. Farrell. 2020.
{browse "https://rdpackages.github.io/references/Calonico-Cattaneo-Farrell_2020_ECTJ.pdf":Optimal Bandwidth Choice for Robust Bias Corrected Inference in Regression Discontinuity Designs}.
{it:Econometrics Journal} 23(2): 192-210.{p_end}

{p 4 8}Calonico, S., M. D. Cattaneo, and M. H. Farrell. 2020.
{browse "https://rdpackages.github.io/references/Calonico-Cattaneo-Farrell_2020_ECTJ.pdf":Optimal Bandwidth Choice for Robust Bias Corrected Inference in Regression Discontinuity Designs}.
{it:Econometrics Journal} 23(2): 192-210.{p_end}

{p 4 8}Calonico, S., M. D. Cattaneo, and M. H. Farrell. 2018.
{browse "https://rdpackages.github.io/references/Calonico-Cattaneo-Farrell_2018_JASA.pdf":On the Effect of Bias Estimation on Coverage Accuracy in Nonparametric Inference}.
{it:Journal of the American Statistical Association} 113(522): 767-779.{p_end}

{p 4 8}Calonico, S., M. D. Cattaneo, M. H. Farrell, and R. Titiunik. 2019.
{browse "https://rdpackages.github.io/references/Calonico-Cattaneo-Farrell-Titiunik_2019_RESTAT.pdf":Regression Discontinuity Designs using Covariates}.
{it:Review of Economics and Statistics}, 101(3): 442-451.{p_end}

{p 4 8}Calonico, S., M. D. Cattaneo, M. H. Farrell, and R. Titiunik. 2017.
{browse "https://rdpackages.github.io/references/Calonico-Cattaneo-Farrell-Titiunik_2017_Stata.pdf":rdrobust: Software for Regression Discontinuity Designs}.
{it:Stata Journal} 17(2): 372-404.{p_end}

{p 4 8}Calonico, S., M. D. Cattaneo, and R. Titiunik. 2014a.
{browse "https://rdpackages.github.io/references/Calonico-Cattaneo-Titiunik_2014_ECMA.pdf":Robust Nonparametric Confidence Intervals for Regression-Discontinuity Designs}.
{it:Econometrica} 82(6): 2295-2326.{p_end}

{p 4 8}Calonico, S., M. D. Cattaneo, and R. Titiunik. 2014b.
{browse "https://rdpackages.github.io/references/Calonico-Cattaneo-Titiunik_2014_Stata.pdf":Robust Data-Driven Inference in the Regression-Discontinuity Design}.
{it:Stata Journal} 14(4): 909-946.{p_end}

{p 4 8}Calonico, S., M. D. Cattaneo, and R. Titiunik. 2015a.
{browse "https://rdpackages.github.io/references/Calonico-Cattaneo-Titiunik_2015_JASA.pdf":Optimal Data-Driven Regression Discontinuity Plots}.
{it:Journal of the American Statistical Association} 110(512): 1753-1769.{p_end}

{p 4 8}Calonico, S., M. D. Cattaneo, and R. Titiunik. 2015b.
{browse "https://rdpackages.github.io/references/Calonico-Cattaneo-Titiunik_2015_R.pdf":rdrobust: An R Package for Robust Nonparametric Inference in Regression-Discontinuity Designs}.
{it:R Journal} 7(1): 38-51.{p_end}

{p 4 8}Cattaneo, M. D., B. Frandsen, and R. Titiunik. 2015.
{browse "https://rdpackages.github.io/references/Cattaneo-Frandsen-Titiunik_2015_JCI.pdf":Randomization Inference in the Regression Discontinuity Design: An Application to Party Advantages in the U.S. Senate}.
{it:Journal of Causal Inference} 3(1): 1-24.{p_end}

{p 4 8}Imbens, G. W., and K. Kalyanaraman. 2012.
{browse "https://github.com/inkooback/RDMD_Stata/blob/main/references/Econometrica_2022.pdf":Optimal Bandwidth Choice for the Regression Discontinuity Estimator}.
{it:Review of Economics Studies} 79(3): 933-959.{p_end}




{marker authors}{...}
{title:Authors}

{p 4 8}Atila Abdulkadiroglu, Duke University, Durham, NC.
{browse "mailto:atila.abdulkadiroglu@duke.edu":atila.abdulkadiroglu@duke.edu}.{p_end}
