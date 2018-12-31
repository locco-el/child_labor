
version 13

/*
	____________________________________________________________________________
	Program		: 	Plots for descriptive analysis

	____________________________________________________________________________

*/

capture clear
set more off
capture log close

do "~/Google Drive/Research/Child Labor and Health/Evaluation/scripts/paths.do"

log using "$output/plots.log", replace


use "$cleandata/final/final_data", clear


cd "$output"
*_______________________________________________________________________________
* declaring local macros

local title = "Pre intervention trends in school attendance and " + ///
				"country characteristics"
local note = "School attendance is presented separately for treated and " + ///
				"control groups; red vertical line indicates policy change year"
local cty_nam `" "Burkina Faso" "Colombia" "Malawi" "'
local cty  `"  "BF" 	"CO"  "MW"  "'
local pol_yrs 2004 	2006  2000  2001 2006
local i 0

*_______________________________________________________________________________
* generate variables

gen interv_yr = cond(country == "BF", 2004, ///
				cond(country == "CO", 2006, ///
				cond(country == "MW", 2000, .)))
				
gen pst = year > interv_yr & !missing(year, interv_yr)

*_______________________________________________________________________________
* plot pre-intervention trends

foreach country of local cty {
	
	preserve

	collapse  (mean) schyr educ_yrs educ_exp gdp_grwth gdp_ppp nat_exp ///
		unemp_ilo if country == "`country'" & pst == 0, by(year treat_pre)		
	
	tsset treat_pre year
	
	tsline schyr if treat_pre==1, yaxis(1) || ///
	tsline schyr if treat_pre==0, yaxis(1) || ///
	tsline educ_exp, yaxis(2) lpattern(dash_dot) || ///
	tsline gdp_grwth, yaxis(2) lpattern(dash)|| ///
	tsline unemp_ilo, yaxis(2) lpattern(longdash) ///
		legend(label(1 "Treated") label(2 "Control") ///
			label(3 "Educ. expenditure") label(4 "GDP growth rate") ///
			label(5 "Unemployment rate") symxsize(5) symysize(2) ///
			size(vsmall) rows(1)) ///
		ytitle("Proportion in school", axis(1) size(small)) ///
		ytitle("Percent", axis(2) size(small)) ///
		xtitle("Year", size(small)) xlabel(, labsize(vsmall)) ///
		ylabel(, axis(1) labsize(vsmall)) ylabel(, axis(2) labsize(vsmall)) ///
		title("`:word `++i' of `cty_nam''", size(medium)) ///
		name(gph_schyr_`country', replace)
			
	restore
	
}


grc1leg gph_schyr_BF gph_schyr_CO  gph_schyr_MW, ycommon ///
	title("`title'", size(small))  ///
	note("`note'", size(vsmall)) ///
	saving("school_attendance.gph", replace)
	
graph export "$output/school_attendance2.png", replace

*_______________________________________________________________________________
log close
exit
