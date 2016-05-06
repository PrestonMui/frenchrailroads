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
* 2. Comm Lat-Lon Data
*********************


*********************
* 3. Price data
*********************
insheet using "../data/ICPSR_09777_prices_clean.csv", comma clear

	drop if year > 1870
	drop dept

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

	* Interpolate
	replace price = (1/2) * price[_n-1] + (1/2) * price[_n+1] if comm==comm[_n-1] & comm==comm[_n+1] & missing(price)
	replace price = (2/3) * price[_n-1] + (1/3) * price[_n+2] if comm==comm[_n-1] & comm==comm[_n+2] & missing(price)
	replace price = (1/3) * price[_n-2] + (2/3) * price[_n+1] if comm==comm[_n-2] & comm==comm[_n+1] & missing(price)

	replace week = mod(tweek,24) if missing(week)
	replace week = 24 if week==0
	replace year = (tweek - week)/24 + 1825 if missing(year)
	drop _fillin

	* Create bilateral panel
	save "temp/pricedata", replace
	ren comm comm1
	ren price price1
	joinby year week tweek using "temp/pricedata"
	ren comm comm2
	ren price price2

	* Drop duplicate observations
	drop if comm2 <= comm1

	sort comm1 comm2 tweek
	egen id = group(comm1 comm2)

	* Merge in coordinate data, calculate distances
	forv i = 1/2 {
		ren comm`i' comm
		merge m:1 comm using "../data/communes_latlon", keep(match) nogen
		ren lat lat`i'
		ren lon lon`i'
		ren comm comm`i'
	}

	* Calculate distances
	foreach var of varlist lat* lon* {
		replace `var' = 3.14159 * `var' / 180
	}
	gen dlon = lon2 - lon1
	gen dlat = lat2 - lat1
	gen a = (sin(dlat/2))^2 + cos(lat1) * cos(lat2) * (sin(dlon/2))^2 
	gen dist = 6371 * 2 * atan2( sqrt(a), sqrt(1-a) ) 
	gen logdist = log(dist)

	drop lat* lon* dlon dlat a

	* Seasonal dummies
	gen q1 = inrange(week,1,6)
	gen q2 = inrange(week,7,12)
	gen q3 = inrange(week,13,18)

*********************
* 4. Create dependent variables
*********************

* Absolute log difference
	gen abslogdiff = abs(log(price1) - log(price2))

compress
save "../data/estimationdata", replace
