* Organize data from other programs into one file to be used in estimation.do

clear all
set more off
set rmsg on

*********************
* 1. Quantity data
*********************
insheet using "../data/ICPSR_09777_quantities_clean.csv", comma clear
	replace comm = lower(comm)
	local i = 1
	while `i' > 0 {
		replace comm = regexr(comm, "[^a-z]","")
		count if regexm(comm,"[^a-z]")
		local i = r(N)
	}
	keep if year<=1842
	collapse (mean) quantity, by(comm)
save "temp/quantities", replace

*********************
* 2. Price data
*********************
insheet using "../data/ICPSR_09777_prices_clean.csv", comma clear

	drop if year > 1870
	replace comm = lower(comm)
	local i = 1
	while `i' > 0 {
		replace comm = regexr(comm, "[^a-z]","")
		count if regexm(comm,"[^a-z]")
		local i = r(N)
	}
	
	* We need to create our generic biweekly time series
	* Time encoding: 1 = 1825m1w1, 2 = 1825 m1.5, etc...
	gen tweek = 24 * (year - 1825) + week
	format tweek %tg

	* Adjustments to price data
	replace price = log(price)
	fillin year week
	drop _fillin
	replace tweek = 24 * (year - 1825) + week if missing(tweek)
	fillin tweek comm
	drop if missing(comm)
	sort comm tweek

	if `limited_sample'==1 {
		keep if inlist(comm,"bordeaux","montbrison","arrac","barleduc","saintlo","toulouse","nantes","beaugency")
	}
	else {
		merge m:1 comm using "temp/quantities", keep(master match) nogen
		drop if quantity < 500 | inlist(comm,"albertville","peyrehorade","pontlabbe","saintbrieuc")
		drop quantity
	}

	* Interpolate
	replace price = (1/2) * price[_n-1] + (1/2) * price[_n+1] if comm==comm[_n-1] & comm==comm[_n+1] & missing(price)
	replace price = (2/3) * price[_n-1] + (1/3) * price[_n+2] if comm==comm[_n-1] & comm==comm[_n+2] & missing(price)
	replace price = (1/3) * price[_n-2] + (2/3) * price[_n+1] if comm==comm[_n-2] & comm==comm[_n+1] & missing(price)

	