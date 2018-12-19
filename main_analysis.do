

/*	____________________________________________________________________________
	Program		: 	Difference in difference models for evaluation of impact
					of child labor laws on school attendance
					
	Author		: 	ONO
	____________________________________________________________________________
*/

*_______________________________________________________________________________
* initialize global settings
version 13
set more off
capture clear

* initialize paths
do ///
 "~/Google Drive/Research/Child Labor and Health/Evaluation/scripts/paths.do"

* initialize logs
capture log close
log using "$logs/new_analysis.log", replace

*_______________________________________________________________________________

* load and prep data
use "$cleandata/final/final_data_wealth2"


* svyset data
svyset psu [pweight=weight]

** countries
local cty `"  "BF" "CO" "MW" "'


* tempfile to store results
tempfile res
save `res', replace

* set up dataset for collecting model results
postutil clear
postfile results str15 anal_type str15 country str15 outcome ///
	b_main 		var_main ///
	b_male		var_male ///
	b_fem		var_fem	 ///
	b_wlth_1 	var_wlth_1 ///
	b_wlth_2 	var_wlth_2 ///
	b_wlth_3 	var_wlth_3 	///
		using `res', replace
*_______________________________________________________________________________
* main analyses

foreach country of local cty {
	di _n(3) "`country'" _n(2)
	*___________________________________________________________________________
	
	* effect of policy on school attendance (adjusted for wealth and gender)
	svy: regress schyr i.treat_dd i.age i.year  i.sex i.wealth_tert ///
		if country == "`country'"
	
	matrix b = e(b)
	matrix var = e(V)
	
	matrix b_main  = b["y1", "1.treat_dd"]
	matrix var_main = var["1.treat_dd", "1.treat_dd"]
	
	
	*___________________________________________________________________________
	
	* effect of policy on school attendance (varying by gender)
	svy: regress schyr i.sex##(i.treat_dd i.year i.age i.wealth_tert)  ///
		if country == "`country'"
	
	margins r.treat_dd, over(sex) post
	
	matrix b = e(b)
	matrix var = e(V)
	
	matrix b_male = b["y1", "r1vs0.1.treat_dd@1.sex"]
	matrix var_male = ///
		var["r1vs0.1.treat_dd@1.sex", "r1vs0.1.treat_dd@1.sex"]
	
	matrix b_fem = b["y1", "r1vs0.1.treat_dd@0.sex"]
	matrix var_fem = ///
		var["r1vs0.1.treat_dd@0.sex", "r1vs0.1.treat_dd@0.sex"]
	
	
	*___________________________________________________________________________
	
	* effect of policy on school attendance (varying by wealth)
	svy: regress schyr i.wealth_tert##(i.treat_dd i.year i.age i.sex)  ///
		if country == "`country'"
	
	margins r.treat_dd, over(wealth_tert) post
	
	matrix b = e(b)
	matrix var = e(V)
	
	matrix b_wealth_1 = b["y1", "r1vs0.1.treat_dd@1.wealth_tert"]
	matrix var_wealth_1 = ///
		var["r1vs0.1.treat_dd@1.wealth_tert", "r1vs0.1.treat_dd@1.wealth_tert"]
	
	matrix b_wealth_2 = b["y1", "r1vs0.1.treat_dd@2.wealth_tert"]
	matrix var_wealth_2 = ///
		var["r1vs0.1.treat_dd@2.wealth_tert", "r1vs0.1.treat_dd@2.wealth_tert"]
		
	matrix b_wealth_3 = b["y1", "r1vs0.1.treat_dd@3.wealth_tert"]
	matrix var_wealth_3 = ///
		var["r1vs0.1.treat_dd@3.wealth_tert", "r1vs0.1.treat_dd@3.wealth_tert"]
	
	*___________________________________________________________________________
	* posting results
	post results 	("main") ("`country'") ("schyr") ///				
					(b_main[1,1]) 		(var_main[1,1]) ///
					(b_male[1,1]) 		(var_male[1,1]) ///
					(b_fem[1,1]) 		(var_fem[1,1]) ///
					(b_wealth_1[1,1])	(var_wealth_1[1,1]) ///
					(b_wealth_2[1,1])	(var_wealth_2[1,1]) ///
					(b_wealth_3[1,1])	(var_wealth_3[1,1])

	
}


postclose results

use `res', clear

* calculating confidence intervals
foreach suffix in main male fem wlth_1 wlth_2 wlth_3 {
	gen ll_`suffix' = b_`suffix' - 1.96*sqrt(var_`suffix')
	gen ul_`suffix' = b_`suffix' + 1.96*sqrt(var_`suffix')
}

* save results to new dataset
save "$cleandata/final/new_analysis_results.dta", replace

*_______________________________________________________________________________

log close
exit
