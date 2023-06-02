{smcl}
{* *!version 1.0.0  2023-05-15}{...}
{viewerjumpto "Syntax" "rdbwselect##syntax"}{...}
{viewerjumpto "Description" "rdbwselect##description"}{...}
{viewerjumpto "Options" "rdbwselect##options"}{...}
{viewerjumpto "Examples" "rdbwselect##examples"}{...}
{viewerjumpto "Stored results" "rdbwselect##stored_results"}{...}
{viewerjumpto "References" "rdbwselect##references"}{...}
{viewerjumpto "Authors" "rdbwselect##authors"}{...}

{title:Title}

{p 4 8}{cmd:rdmd} {hline 2} 2SLS regression analysis for evaluating program effectiveness on its participants through the calculation and control of local propensity scores using central assignment data.{p_end}


{marker syntax}{...}
{title:Syntax}

{p 4 8}{cmd:rdmd }[, options]{p_end}


{marker description}{...}
{title:Description}

{p 4 8}{cmd:rdmd} utilizes causal identification procedures developd in Abdulkadiroglu, Angrist, Narita, and Pathak (2017, 2022) to determine the causal effects of school attendance on applicant outcomes. {cmd:rdmd} takes into account situations where certain schools employ randomly assigned lottery tie-breakers, while others use non-lottery tie-breakers such as test scores. Also, {cmd:rdmd} incorporates the cases where schools provide an advantage to specific groups of applicants by multiplying their tie-breaker values by a certain amount. {p_end}

{p 4 8}All the related Stata ado files and sample data can be found in the following website:{p_end}

{p 8 8}{browse "https://github.com/inkooback/RDMD_Stata/":https://github.com/inkooback/RDMD_Stata/}{p_end}


{marker options}{...}
{title:Options}

{synoptset 30 tabbed}{...}
{marker optioins}{...}
{synopthdr:Options}
{synoptline}
{synopt :{cmd:bwtype}(string)}Bandwidth type. User can select "IK" or "CCFT". Default is "IK".{p_end}
{synopt :{cmd:bwcriterion}(integer)}Bandwidth population criterion. Select a positive integer. Default is 5.{p_end}
{synoptline}

{dlgtab:Bandwidth Type}

{p 4 8}{cmd:IK} Bandwidths estimation suggested by Imbens and Kalyanaraman (2012). This method minimizes the mean squared error (MSE) of the local linear regression estimator, taking into account both the bias and the variance. The bandwidths used here are computed as described by Armstrong and Kolesár (2018) and in the {browse "https://github.com/tbarmstr/RDHonest-vStata/":rdhonest} package.{p_end}

{p 4 8}{cmd:CCFT} Bandwidths estimation suggested by Calonico et al. (2017). This method calculates local quadratic estimator with regularized bandwidth selector and bias-correction. The bandwidths used here are computed as in the {browse "https://github.com/rdpackages/rdrobust/":rdrobust} package{p_end}

{p 4 8} Each method has its own set of advantages and disadvantages, which vary depending on the specific context. For instance, {cmd:IK} bandwidths can be sensitive to outliers and extreme values, and they do not consider heteroskedasticity or non-normality of the errors. {cmd:CCFT} method is generally more computationally intensive and complex, and it tends to perform better with larger sample sizes. It is important for users to carefully consider the characteristics of their data and select the appropriate bandwidth type accordingly.

{dlgtab:Bandwidth Population Criterion}

{p 4 8}After user selects the bandwidth type, user may choose the bandwidth population criterion. For example, if user chooses 5 as the criterion, the bandwidth for non-lottery programs is set to zero when there are fewer than five in-bandwidth observations on one or the other side of the relevant cutoff. User should choose one integer. Default is 5.{p_end}

{p 4 8} There is trade-off between the precision of the estimation and sample size. Choice of bandwidth population criterion depends on various factors such as the shape and distribution of the running variable, the functional form and smoothness of the regression function, precision of the estimated treatment effect, and the number of covariates included in the model. User is recommended to compare result for different criteria and check the sensitivity and robustness of the bandwidths.
{p_end}


{marker subcommands}{...}
{title:Subcommands}

{synoptset 20 tabbed}{...}
{marker subcommand}{...}
{synopthdr:Subcommand}
{synoptline}
{synopt :{cmd:rdmd_rename}}Rename variables{p_end}
{synopt :{cmd:rdmd_check}}Conduct feasibility checks on the data loaded{p_end}
{synopt :{cmd:rdmd_pscore}}Calculate propensity scores{p_end}
{synopt :{cmd:rdmd_create}}Create exposure variables and intrumenal variables{p_end}
{synopt :{cmd:rdmd_stack}}Stack over each year and grade{p_end}
{synopt :{cmd:rdmd_analysis}}Conduct balance regression, OLS regression, and 2SLS regression{p_end}
{synoptline}
{p 4 8}Every subcommand is included and executed within the {cmd:rdmd} command, so user does not need to run each subcommand separately unless partial or intermediate outcomes are specifically required.{p_end}


{marker inputs}{...}
{title:Inputs}

{dlgtab:Bandwidth Type}
{p 4 8}If user does not provide the {cmd:bwtype} option, user will be asked to select the bandwidth type by typing either {cmd:IK} or {cmd:CCFT}. Default is {cmd:IK}. User may simply press enter to set as default.{p_end}

{dlgtab:Bandwidth Population Criterion}

{p 4 8}If user does not provide the {cmd:bwcriterion} option, user will be asked to select the bandwidth population criterion by typing either an integer. Default is {cmd:5}. User may simply press enter to set as default.{p_end}

{dlgtab:Variables}

{p 4 8} Once {cmd:rdmd} is executed and bandwidth type and criterion are selected, the user will be prompted to input their variable names corresponding to the following information. Please note that the variable names listed in the following table are provided for descriptive purposes only, and the variable names in the user's dataset do not need to be identical to these names. For instance, the program requires Applicant ID variable, and if the user's variable name for Applicant ID is {cmd:id}, user should input {cmd:id} when prompted to input their variable name that corresponds to Applicant ID.{p_end}

{synoptset 35 tabbed}{...}
{marker subcommand}{...}
{synopthdr:Variables}
{synoptline}
{synopt :{cmd:Applicant ID}}Unique identification code assigned to each applicant. This variable stores string type data.{p_end}
{p2coldent:* {cmd:Year}}Year the applicant is in. This variable stores integer type data.{p_end}
{p2coldent:* {cmd:Grade}}Grade the applicant is in. This variable stores integer type data.{p_end}
{synopt :{cmd:Choice Rank}}Choice rank of the school to which the applicant applied. For example, if the school is the applicant's first choice, choice rank would be 1. This variable stores integer type data.{p_end}
{synopt :{cmd:School ID}}Unique identification code assigned to each school. This variable stores string type data.{p_end}
{synopt :{cmd:Treatment}}Treatment on the school. 0 = untreated schools. 1,2,3,... for the treated schools. This variable stores integer type data.{p_end}
{synopt :{cmd:Capacity}}Capacity of the program of the corresponding year and grade. This variable stores integer type data.{p_end}
{synopt :{cmd:Priority}}Priority the applicant is granted at the school. A lower number corresponds to a higher priority, with 0 indicating a guaranteed acceptance. This variable stores integer type data.{p_end}
{synopt :{cmd:Default Tie-breaker Index}}Tie-breaker index the applicant has at the school. This variable stores integer type data.{p_end}
{p2coldent:* {cmd:Non-Lottery Index}}Index for the non-lottery schools. 0 for lottery schools, 1 for non-lottery schools. This variable stores binary type data.{p_end}
{p2coldent:* {cmd:Tie-breaker Applicant Group Index}}Index for applicant groups. 0 for the default group. This variable stores integer type data.{p_end}
{p2coldent:* {cmd:Advantage}}Applicants' tie-breaker values will be multiplied by the advantage. For example, If advantage is 0.7, the applicant's tie-breaker value will be multiplied by 0.7 at the school. Values should be in the range (0,1]. This variable stores float type data.{p_end}
{synopt :{cmd:Default Tie-breaker}}Tie-breaker value of the student at the program. This variable stores float type data.{p_end}
{synopt :{cmd:Assignment}}Assignment of the applicant at the school. 0 = not assigned. 1 = assigned.  This variable stores binary type data.{p_end}
{synopt :{cmd:Enrollment}}Enrollment of the applicant at the school. 0 = not enrolled. 1 = enrolled. This variable stores binary type data.{p_end}
{synopt :{cmd:Outcomes}}Outcome variables. These should be continuous variables. These variables may store float of integer type data.{p_end}
{synopt :{cmd:Covariates}}Covariates. These can be either continuous or categorical variables. User will be asked to provide the list (parsed by space) of the categorical covariates and then continuous covariates. These variables may store float, integer, string, or binary type data.{p_end}
{synoptline}
{p 4 8}* These five variables are optional if these concepts are irrelevant to the context user is working on or there is no variation in these variables. In such cases, if the user does not have these variables in the dataset, user can simply press enter when prompted to provide these variable names. The program will automatically generate a variable with a single value.{p_end}

    {hline}

	
{marker feasibility}{...}
{title:Data Feasibility Check}

{p 4 8}User's data must adhere to the proper structure. Once all variable names are provided, the program will conduct the following feasibility checks. If any issues are detected, it will raise an error or warning to notify the user.{p_end}

{synoptset 10 tabbed}{...}
{marker number}{...}
{synopthdr:Number}
{synoptline}
{synopt :{cmd:1}}Inconsistent year, grade, or outcomes within an applicant{p_end}
{synopt :{cmd:2}}Inconsistent tie-breaker values within an (applicant, tie-breaker index) pair{p_end}
{synopt :{cmd:3}}Inconsistent treatment, capacity, or advantage within a program{p_end}
{synopt :{cmd:4}}An applicant chose multiple schools for the same rank{p_end}
{synopt :{cmd:5}}An applicant chose the same school for multiple ranks{p_end}
{synopt :{cmd:6}}Inconsecutive choice ranks (e.g., 1,2,4){p_end}
{synopt :{cmd:7}}An applicant is assigned or enrolled to multiple programs{p_end}
{synopt :{cmd:8}}A program is assigned or enrolled with more applicants than its capacity and contains at least one applicant who is not guaranteed an assignment{p_end}
{synopt :{cmd:9}}An applicant is not assigned to a school although the applicant was guaranteed an assignment to that school and she was not assigned to any school she prefers to that school{p_end}
{synopt :{cmd:10}}An applicant is assigned to a school {it:s} although the applicant was guaranteed an assignment to a school {it:s'} that she prefers to {it:s} and was not assigned to {it:s'}{p_end}
{synopt :{cmd:11}}An applicant is assigned to school {it:s}, even though (1) she prefers school {it:s'} to {it:s}, (2) her applicant position at {it:s'} was better than her position at {it:s}, (3) there were still available spots at {it:s'}, (4) and she is eligible at {it:s'}{p_end}
{synopt :{cmd:12}}Abnormally large value found in a column that is unlikely to have a huge outlier{p_end}
{synopt :{cmd:13}}A school uses non-lottery tie-breaker, and correlation between Priority and Tie-breaker within the school approximates 1{p_end}
{synopt :{cmd:14}}No variation in treatment{p_end}
{synopt :{cmd:15}}Advantage not in the range (0,1]{p_end}
{synoptline}
	

{marker outputs}{...}
{title:Outputs}

{p 4 8}{cmd:rdmd} generates four tables in both LaTeX and csv formats.{p_end}

{dlgtab:Balance}

{p 4 8}Balance regression results.{p_end}
{p 4 8}
The values in the table represents the regression coefficients of each covariate on the dummy variable indicating assignment to treated schools. The Left half of the table shows the results of the balance regression without including local propensity score control or local piecewise linear control for screened tie-breakers. The right half of the table shows the results of the balance regression including local propensity score control and local piecewise linear control for screened tie-breakers. For instance, if there are two types of treatment in the data, the first two columns represent uncontrolled balance regressions, while the last two columns represent controlled balance regressions.
{p_end}

{p 4 8}Output files: balance.tex, balance.csv{p_end}

{dlgtab:F-test}

{p 4 8} F-test results for each uncontrolled and controlled balance regressions.{p_end}

{p 4 8} Output files: f_test.tex, f_test.csv{p_end}

										
{dlgtab:2SLS}

{p 4 8} Results of the 2SLS regression of {cmd:Outcomes} on {cmd:Enrollment at treated schools} dummies using {cmd:Assignment at treated schools} dummies as an instrument for {cmd:Enrollment at treated schools} dummies. The analysis controls for local propensity score control and includes local piecewise linear control for screened tie-breakers.{p_end}

{p 4 8} {cmd: Output files} {p_end}
{p 8 8}{cmd: Multi-sector analysis:} multi_sector_2SLS.tex, multi_sector_2SLS.csv  {p_end}
{p 8 8}{cmd: Analysis for each treatment dummy:} treatment_x_2SLS.tex, treatment_x_2SLS.csv {it: for each treatment value x} {p_end}


{dlgtab:OLS}
{p 4 8} Results of the OLS regression of {cmd:Outcomes} on {cmd:Enrollment at treated schools} dummies {p_end}

{p 4 8} {cmd: Output files} {p_end}
{p 8 8}{cmd: Multi-sector analysis:} multi_sector_OLS.tex, multi_sector_OLS.csv  {p_end}
{p 8 8}{cmd: Analysis for each treatment dummy:} treatment_x_OLS.tex, treatment_x_OLS.csv {it: for each treatment value x} {p_end}

    {hline}

	
{marker examples}{...}
{title:Example: sample data}

{p 4 8}Setup{p_end}
{p 8 8}{cmd:. use sample_data.dta}{p_end}

{p 4 8}Calculate propensity scores and conduct 2SLS regression analysis{p_end}
{p 8 8}{cmd:. rdmd}{p_end}


{marker references}{...}
{title:References}

{p 4 8}Abdulkadiroglu, A., J. D. Angrist, Y. Narita, and P. Pathak. 2017.
{browse "https://github.com/inkooback/RDMD_Stata/blob/main/references/Econometrica_2022.pdf":Research Design Meets Market Design: Using Centralized Assignment for Impact Evaluation}.
{it:Econometrica} 85(5): 1373-1432.{p_end}

{p 4 8}Abdulkadiroglu, A., J. D. Angrist, Y. Narita, and P. Pathak. 2022.
{browse "https://github.com/inkooback/RDMD_Stata/blob/main/references/Econometrica_2017.pdf":Breaking Ties: Regression Discontinuity Design Meets Market Design}.
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

{p 4 8}Inkoo Back, Duke University, Durham, NC.
{browse "mailto:inkoo.back@duke.edu":inkoo.back@duke.edu}.{p_end}
