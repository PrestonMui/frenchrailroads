clear all
set more off

* Read in Data

insheet using "../data/ICPSR_09777_prices_clean.csv", comma clear

	drop if year > 1870

	* We need to create our generic biweekly time series
	* Time encoding: 1 = 1825m1w1, 2 = 1825 m1.5, etc...
	gen tweek = 24 * (year - 1825) + week
	format tweek %tg

	* Sadly, the communes need to be reformated
	replace comm = "DOUAI" if comm=="DUOAI"
	replace comm = lower(comm)
	
	local i = 1
	while `i' > 0 {
		replace comm = regexr(comm, "[^a-z]","")
		count if regexm(comm,"[^a-z]")
		local i = r(N)
	}

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
	replace price = (2/3) * price[_n-1] + (12/3) * price[_n+2] if comm==comm[_n-1] & comm==comm[_n+2] & missing(price)
	replace price = (1/3) * price[_n-2] + (2/3) * price[_n+1] if comm==comm[_n-2] & comm==comm[_n+1] & missing(price)

	* Shape data into wide format
	keep tweek comm price
	reshape wide price, i(tweek) j(comm) string
	gen week = mod(tweek,24)
	replace week = 24 if week==0
	gen year = ceil(tweek/24) + 1824
	order tweek year week
	tsset tweek
	
	keep if year < 1842
	foreach var of varlist price* {
		qui count if missing(`var')
		if r(N) > 0 {
			drop `var'
		}
	}

	vecrank price*
