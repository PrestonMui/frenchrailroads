clear all
set more off
set rmsg on
cap log close
log using estimation.log, replace

local cluster = 0
local limited_sample = 0
local vecbilateral = 1
local vecmultilateral = 0
local varianceregressions = 1

if `cluster'==1 {
	set processors 4
	set matsize 11000
}
else{
	set matsize 800
}

*********************
* 1. Read in data
*********************

use "../data/estimationdata", clear

	eststo clear
	* Absolute log difference equations
	eststo: reg abslogdiff logdist hasrail hasrail_logdist i.year i.comm1group i.comm2group, robust
		mat temp = e(b)'
		mat abslogdiff_fe1 = temp["1825b.year".."1870.year","y1"]
	* eststo: reg abslogdiff logdist i.year i.comm1group i.comm2group
	foreach d in 100 150 200 {
		ren logdistm`d' logdistm
		ren hasrail_logdistm`d' hasrail_logdistm
		ren hasrail_dummy_logdistm`d' hasrail_dummy_logdistm

		eststo: reg abslogdiff logdist hasrail_dummy_logdistm hasrail_logdistm i.year i.comm1group i.comm2group, robust
		mat temp = e(b)'
		mat abslogdiff_fe`d' = temp["1825b.year".."1870.year","y1"]
		
		ren logdistm logdistm`d'
		ren hasrail_logdistm hasrail_logdistm`d'
		ren hasrail_dummy_logdistm hasrail_dummy_logdistm`d'
	}
	ren logdistm100 logdistm
	ren hasrail_logdistm100 hasrail_logdistm
	ren hasrail_dummy_logdistm100 hasrail_dummy_logdistm

	esttab using "../figures/abslogdiffreg.tex", replace label ar2 ///
		cells(b(fmt(5) star) se(fmt(5) par)) ///
		keep(logdist hasrail hasrail_dummy_logdistm hasrail_logdist logdist hasrail_logdistm _cons) ///
		booktabs collabels(none) ///
		mtitle("" "\shortstack{Min Dist\\100KM}" "\shortstack{Min Dist\\150KM}" "\shortstack{Min Dist\\200KM}") ///
		title(Dependent Variable: Average Absolute Log Price Difference\label{tab:reg1}) ///
		note("All regressions use Year and Commune Fixed Effects")

use "../data/estimationdata", clear

	eststo clear
	* Variance regressions
	eststo: reg sdlogdiff logdist hasrail hasrail_logdist i.year i.comm1group i.comm2group, robust
		mat temp = e(b)'
		mat sdlogdiff_fe1 = temp["1825b.year".."1870.year","y1"]
	* eststo: reg sdlogdiff logdist i.year i.comm1group i.comm2group, robust
	foreach d in 100 150 200 {
		ren logdistm`d' logdistm
		ren hasrail_logdistm`d' hasrail_logdistm
		ren hasrail_dummy_logdistm`d' hasrail_dummy_logdistm

		eststo: reg sdlogdiff logdist hasrail_dummy_logdistm hasrail_logdistm i.year i.comm1group i.comm2group, robust
		mat temp = e(b)'
		mat sdlogdiff_fe`d' = temp["1825b.year".."1870.year","y1"]
		
		ren logdistm logdistm`d'
		ren hasrail_logdistm hasrail_logdistm`d'
		ren hasrail_dummy_logdistm hasrail_dummy_logdistm`d'
	}
	ren logdistm100 logdistm
	ren hasrail_logdistm100 hasrail_logdistm
	ren hasrail_dummy_logdistm100 hasrail_dummy_logdistm
	
	esttab using "../figures/sdlogdiffreg.tex", replace label ar2 ///
		cells(b(fmt(5) star) se(fmt(5) par)) ///
		keep(logdist hasrail hasrail_logdist logdist hasrail_dummy_logdistm hasrail_logdistm _cons) ///
		booktabs collabels(none) ///
		mtitle("" "\shortstack{Min Dist\\100KM}" "\shortstack{Min Dist\\150KM}" "\shortstack{Min Dist\\200KM}") ///
		title(Dependent Variable: Std. Deviation of Absolute Log Price Difference\label{tab:reg2}) ///
		note("All regressions use Year and Commune Fixed Effects")

	* Fixed effects stuff
	preserve
		keep year
		duplicates drop
		sort year
		svmat abslogdiff_fe1
		svmat abslogdiff_fe100
		svmat abslogdiff_fe150
		svmat abslogdiff_fe200
		svmat sdlogdiff_fe1
		svmat sdlogdiff_fe100
		svmat sdlogdiff_fe150
		svmat sdlogdiff_fe200
		save "../data/fixed_effects", replace
	restore


*********************
* 1. Regression 1:
*********************


	* if `vecbilateral'==1 {
	* 	tempfile results
	* 	local numcommsminusone = `numcomms' - 1

	* 	forv i = 1/`numcommsminusone' {
	* 		local iplusone = `i' + 1
	* 		forv j = `iplusone'/`numcomms' {
	* 			forv year = 1825(2)1870 {

	* 				local yearp1 = `year' + 1

	* 				qui count if (missing(price`i') | missing(price`j')) & (year==`year' | year==`yearp1')
	* 				if r(N)!=0 exit

	* 				qui gen p = price`i' - price`j'
	* 				qui gen lag1_p = l1.p
	* 				qui gen dp = p - lag1_p
	* 				forv l = 1/2 {
	* 					qui gen lag`l'_dp = l`l'.dp
	* 				}

	* 				qui reg dp lag1_p lag*_dp if year==`year' | year==`yearp1'
	* 				mat results = (`i',`j',`year',_b[lag1_p],_se[lag1_p])
					
	* 				preserve
	* 					clear
	* 					qui svmat results
	* 					cap append using "`results'"
	* 					qui save "`results'", replace
	* 				restore

	* 				drop p lag1_p dp lag*_dp
	* 			}
	* 		}
	* 	}

	* 	use "`results'", clear

	* 	ren results1 comm1
	* 	ren results2 comm2
	* 	ren results3 year
	* 	ren results4 beta
	* 	ren results5 se_beta

	* 	gen ce1 = beta - 1.96 * se_beta
	* 	gen ce2 = beta + 1.96 * se_beta

	* 	gen significant = 0 < ce1 | 0 > ce2		
	* }
	* if `vecmultilateral'==1 {

	* }
	