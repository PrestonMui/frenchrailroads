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
	