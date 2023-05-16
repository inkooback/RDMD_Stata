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

{p 4 8}{cmd:rdmd} {hline 2} 2SLS regression analysis for the evaluation of school effectiveness through the calculation and control of local propensity scores using central assignment data{p_end}


{marker syntax}{...}
{title:Syntax}

{p 4 8}{cmd:rdmd}{p_end}

{synoptset 20 tabbed}{...}
{marker subcommand}{...}
{synopthdr:subcommand}
{synoptline}
{synopt :{cmd:rename}}Rename variables{p_end}
{synopt :{cmd:check}}Conduct feasibility checks on the data loaded{p_end}
{synopt :{cmd:pscore}}Calculate propensity scores{p_end}
{synopt :{cmd:create}}Create exposure variables and intrumenal variables{p_end}
{synopt :{cmd:stack}}Stack over each year and grade{p_end}
{synopt :{cmd:analysis}}Conduct balance regression, OLS regression, and 2SLS regression{p_end}
{synoptline}
{p 4 8}Every subcommand is included and ran in the {cmd:rdmd} command, so user does not have to run each subcommand unless partial or intermediate outcome is needed.{p_end}


{marker description}{...}
{title:Description}

{p 4 8}{cmd:rdmd} utilizes identification procedures developd in Abdulkadiroglu, Angrist, Narita, and Pathak (2017, 2022) to determine the causal effects of school attendance on student outcomes. {cmd:rdmd} takes into account situations where certain schools employ randomly assigned lottery tie-breakers, while others use non-lottery tie-breakers such as test scores. Also, {cmd:rdmd} incorporates the cases where schools provide an advantage to specific groups of students by multiplying their tie-breaker values by a certain amount. {p_end}

{p 4 8}All the related Stata ado files can be found in the following website:{p_end}

{p 8 8}{browse "https://github.com/inkooback/RDMD_Stata/":https://github.com/inkooback/RDMD_Stata/}{p_end}


{marker Input}{...}
{title:Input}

{dlgtab:Variables}

{synoptset 35 tabbed}{...}
{marker subcommand}{...}
{synopthdr:Variables}
{synoptline}
{synopt :{cmd:Student ID}}Nonnegative ID number of the student (Examle: 7){p_end}
{p2coldent:* {cmd:Year}}Year the student is in (Example: 2017){p_end}
{p2coldent:* {cmd:Grade}}Grade the student is in (Example: 10){p_end}
{synopt :{cmd:Choice Rank}}Choice rank of the school that the student applied to. For example, if the school is the student's first choice, choice rank is 1.{p_end}
{synopt :{cmd:Treatment}}Treatment on the school. 0 = untreated schools. 1,2,3,... for the treated schools. {p_end}
{synopt :{cmd:Capacity}}Capacity of the program (Example: 280){p_end}
{synopt :{cmd:Priority}}Priority of the student at the school (Example: 2){p_end}
{synopt :{cmd:Default Tie-breaker Index}}Tie-breaker index the student has at the school (Example: 2){p_end}
{p2coldent:* {cmd:Non Lottery}}Index for the non-lottery schools. 0 for lottery schools, 1 for non-lottery schools.{p_end}
{p2coldent:* {cmd:Tie-breaker Student Group Index}}Index for student groups. 0 for the default group. {p_end}
{p2coldent:* {cmd:Advantage}}Students' tie-breaker values will be multiplied by the advantage. For example, If advantage is 0.7, the student's tie-breaker value{p_end}
{p 41 8}will be multiplied by 0.7 at the school.{p_end}
{synopt :{cmd:Default Tie-breaker}}Conduct 2SLS regression{p_end}
{synopt :{cmd:Assignment}}0 = not assigned. 1 = assigned.{p_end}
{synopt :{cmd:Enrollment}}0 = not enrolled. 1 = enrolled.{p_end}
{synopt :{cmd:Outcomes}}Outcome variables. These should be continuous variables.{p_end}
{synopt :{cmd:Covariates}}Covariates. These can be either continuous or categorical.{p_end}
{synoptline}
{p 4 8}* These variables are optional if your data consists of constant values for these variables. In such cases, press enter when prompted to provide these variable names. The program will automatically generate a variable with a single value.{p_end}
										
{dlgtab:Bandwidth Type}

{p 4 8}{cmd:IK} Bandwidths estimation suggested by Imbens and Kalyanaraman (2012). This method minimizes the mean squared error (MSE) of the local linear regression estimator, taking into account both the bias and the variance. The bandwidths used here are computed as described by Armstrong and Kolesár (2018) and in the
RDhonest package.{p_end}

{p 4 8}{cmd:CCFT} Bandwidths estimation suggested by Calonico et al. (2017). This method calculates local quadratic estimator with regularized bandwidth selector and bias-correction.{p_end}

{p 4 8} Each method has its own advantages and disadvantages depending on the context. IK bandwidths can be sensitive to outliers and extreme values and does not account for heteroskedasticity or non-normality of the errors. The CCFT method is genrally computationally cmore intensive and complex, requiring a large sample size to perform well. User should consider characteristic of data and select the appropriate bandwidth type.

{dlgtab:Bandwidth Population Criterion}

{p 4 8} There is trade-off between the precision of the estimation and sample size. Choice of bandwidth population criterion depends on various factors such as the shape and distribution of the running variable, the functional form and smoothness of the regression function, precision of the estimated treatment effect, and the number of covariates included in the model. User should compare result for different criteria and check the sensitivity and robustness of your bandwidths.
{p_end}

    {hline}
	
{marker output}{...}
{title:Output Tables}

{dlgtab:Balance}

{p 4 8}Balance regression results.{p_end}
{p 4 8}
The values in the table represents the regression coefficients of each covariate on the dummy variable indicating assignment to treated schools.
The Left half of the table shows the results of the balance regression without including local propensity score control or local piecewise linear control for screened tie-breakers. The right half of the table shows the results of the balance regression including local propensity score control and local piecewise linear control for screened tie-breakers. For instance, if there are two types of treatment in the data, the first two columns represent uncontrolled balance regressions, while the last two columns represent controlled balance regressions.
{p_end}

{p 4 8}Output files: balance.tex, balance.csv{p_end}

{dlgtab:F-test}

{p 4 8} F-test results for each uncontrolled and controlled balance regressions.{p_end}

{p 4 8} Output files: f_test.tex, f_test.csv{p_end}

										
{dlgtab:2SLS}

{p 4 8} Results of the 2SLS regression of {cmd:Outcomes} on {cmd:Enrollment} to the treated schools using {cmd:Assignment} to the treated schools as an instrument for {cmd:Enrollment} to the treated schools. The analysis includes local propensity score control and local piecewise linear control for screened tie-breakers.{p_end}
{p 4 8} Output files: 2sls.tex, 2sls.csv {p_end}


{dlgtab:OLS}
{p 4 8} Results of the OLS regression of {cmd:Outcomes} on {cmd:Enrollment} to the treated schools {p_end}
{p 4 8} Output files: ols.tex, ols.csv {p_end}

    {hline}

	
{marker examples}{...}
{title:Example: real world data}

{p 4 8}Setup{p_end}
{p 8 8}{cmd:. use real_world.dta}{p_end}

{p 4 8}Calculate propensity scores and conduct 2SLS regression{p_end}
{p 8 8}{cmd:. rdmd}{p_end}

{marker references}{...}
{title:References}

{p 4 8}Abdulkadiroglu, A., J. D. Angrist, Y. Narita, and P. Pathak. 2022.
{browse "https://github.com/inkooback/RDMD_Stata/blob/main/references/Econometrica_2022.pdf":Breaking Ties: Regression Discontinuity Design Meets Market Design}.
{it:Econometrica} 90(1): 117-151.{p_end}

{p 4 8}Calonico, S., M. D. Cattaneo, and M. H. Farrell. 2020.
{browse "https://rdpackages.github.io/references/Calonico-Cattaneo-Farrell_2020_ECTJ.pdf":Optimal Bandwidth Choice for Robust Bias Corrected Inference in Regression Discontinuity Designs}.
{it:Econometrics Journal} 23(2): 192-210.{p_end}

{p 4 8}Calonico, S., M. D. Cattaneo, M. H. Farrell, and R. Titiunik. 2019.
{browse "https://rdpackages.github.io/references/Calonico-Cattaneo-Farrell-Titiunik_2019_RESTAT.pdf":Regression Discontinuity Designs using Covariates}.
{it:Review of Economics and Statistics}, 101(3): 442-451.{p_end}

{p 4 8}Calonico, S., M. D. Cattaneo, M. H. Farrell, and R. Titiunik. 2017.
{browse "https://rdpackages.github.io/references/Calonico-Cattaneo-Farrell-Titiunik_2017_Stata.pdf":rdrobust: Software for Regression Discontinuity Designs}.
{it:Stata Journal} 17(2): 372-404.{p_end}

{p 4 8}Imbens, G. W., and K. Kalyanaraman. 2012.
{browse "https://github.com/inkooback/RDMD_Stata/blob/main/references/IK_2012.pdf":Optimal Bandwidth Choice for the Regression Discontinuity Estimator}.
{it:Review of Economics Studies} 79(3): 933-959.{p_end}




{marker authors}{...}
{title:Authors}

{p 4 8}Atila Abdulkadiroglu, Duke University, Durham, NC.
{browse "mailto:atila.abdulkadiroglu@duke.edu":atila.abdulkadiroglu@duke.edu}.{p_end}
