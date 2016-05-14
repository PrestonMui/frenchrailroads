clear all
set more off
set rmsg on

***************************
* 1. Create map of communes
***************************
* Read in city coordinate data
use "../data/communes_latlon", clear
	replace comm = subinstr(comm," France","",.)
append using "../data/FRA_adm/FRA_adm0b"
replace comm = proper(comm)
gen position = 3
	replace position = 1 if inlist(comm,"Lyon","Oontlabbe","Lille","Vitre")
	replace position = 2 if inlist(comm,"Soissons","Montauban","Chalonssurmarne","Pontlabbe")
	replace position = 4 if inlist(comm,"Evreux","Bayeux","Douai")
	replace position = 5 if inlist(comm,"Clermont","Saintbrieuc")
	replace position = 6 if inlist(comm,"Saintlo","Laval","Arras","Albertville")
	replace position = 8 if inlist(comm,"Blois","Carcassonne")
	replace position = 12 if inlist(comm,"Bernay")

tw (area _Y _X, cmissing(n) fcolor(white) nodropbase) ///
	(scatter lat lon, jitter(1) msize(vsmall) mlabel(comm) mlabsize(vsmall) ///
	mlabcolor(black) mlabvposition(position)), ///
	name(simple, replace) ytitle("") legend(off) ylabel(none) xlabel(none) ///
	yscale(off) xscale(off) graphregion(color(white)) bgcolor(white)

graph export "../figures/communes_map.pdf", as(pdf) replace

***************************
* 2. Graph of number of lines, kilometers added
***************************
insheet using "../data/cheminsdefer_latlon.csv", comma clear
save "temp/cheminsdefer_latlon", replace

insheet using "../data/railopenings.csv", comma clear
	forv i = 1/2 {
		ren comm`i' comm
		merge m:1 comm using "temp/cheminsdefer_latlon", keep(master match) nogen
		ren lat lat`i'
		ren lon lon`i'
		ren comm comm`i'
	}

	foreach var of varlist lat* lon* {
		replace `var' = 3.14159 * `var' / 180
	}
	gen dlon = lon2 - lon1
	gen dlat = lat2 - lat1
	gen a = (sin(dlat/2))^2 + cos(lat1) * cos(lat2) * (sin(dlon/2))^2 
	gen dist = 6371 * 2 * atan2( sqrt(a), sqrt(1-a) ) 

	gen year = round(date/10000)
	gen num_lines = 1
	collapse (sum) dist num_lines, by(year)
	la var dist "KM of Lines"
	la var num_lines "Number of Lines"
	
	graph twoway line num_lines year, xaxis(1 2) yaxis(1) yscale(range(0) axis(1)) xline(1842 1852 1859) lcolor(black) ///
		xla(1842 "Legrand Plan, 1842"  1852 "2nd French Empire, 1852" 1859 "Nat'l Guarantee, 1859", axis(1) labsize(small) alternate) ///
		ytitle("Lines Opened") graphregion(color(white)) bgcolor(white) ///
	|| line dist year, yaxis(2) yscale(range(0) axis(2)) lpattern(dash) lcolor(black) ///
		ytitle("KM of Lines Opened", axis(2)) xtitle("Year", axis(2)) xtitle("", axis(1)) title("Rail Lines Opened, by Year")
	
graph export "../figures/lines_ts.pdf", as(pdf) replace

***************************
* 3. Create map of railroads
***************************
tempfile tmp
insheet using "../data/cheminsdefer_latlon.csv", comma clear
	save `tmp', replace
insheet using "../data/cheminsdefer_connections.csv", comma clear
	gen pairid = _n
	gen lat3 = .
	gen lon3 = .
	reshape long comm lat lon id, i(pair date) j(temp)
	replace pairid = pairid + 1
	ren lat _Y
	ren lon _X
	ren pairid _ID
append using "../data/FRA_adm/FRA_adm0b"

foreach year in 1845 1850 1855 1860 1865 1870 {
	tw (area _Y _X if _ID==1, cmissing(n) fcolor(white) lcolor(black) nodropbase) ///
		(area _Y _X if _ID > 1 & year < `year', cmissing(n) fcolor(white) ///
			lcolor(black) lpattern(dash) lwidth(0.1) nodropbase), ///
		name(simple, replace) ytitle("") legend(off) ylabel(none) xlabel(none) ///
		yscale(off) xscale(off) graphregion(color(white)) bgcolor(white) legend(off)
	graph export "../figures/railmap`year'.pdf", as(pdf) replace
}

***************************
* 4. Graph of Fixed Effects
***************************
use "../data/fixed_effects", clear
	
	la var abslogdiff_fe11 "Abs. Log Difference"
	la var sdlogdiff_fe11 "Std. Dev. Log Difference"

	* Compare to "Average" effect
	gen absavgtreat = -0.0014266
	gen sdavgtreat = -0.0006081
	la var absavgtreat "Implied Differential Effect"
	la var sdavgtreat "Implied Volatility Effect"
	
	graph twoway line abslogdiff_fe11 year, lcolor(black) ///
		|| line absavgtreat year, lcolor(gs10) ///
		|| line sdlogdiff_fe11 year, lcolor(black) lpattern(dash) ///
		|| line sdavgtreat year, lcolor(gs10) lpattern(dash) ///
		xtitle("Year") ytitle("Fixed Effect") title("Year Fixed Effects") ///
		graphregion(color(white)) bgcolor(white)

graph export "../figures/fixed_effects.pdf", as(pdf) replace

***************************
* 4. Time Series of volatility and log price differentials
***************************

use "../data/estimationdata", clear

	collapse (mean) abslogdiff sdlogdiff, by (year)
	la var abslogdiff "Mean Absolute Difference"
	la var sdlogdiff "Std. Dev. of Difference"
	sort year

	graph twoway line abslogdiff year, scheme(s1mono) yaxis(1) ylabel(0(0.005)0.03) yscale(range(0 0.03) axis(1)) lcolor(black) ///
		ytitle("Mean Absolute Difference in Log Prices") graphregion(color(white)) bgcolor(white) ///
	|| line sdlogdiff year, yaxis(2) yscale(range(0 0.015) axis(2)) ylabel(0(0.003)0.015, axis(2)) lpattern(dash) lcolor(black) ///
		ytitle("Std. Dev. of Difference in Log Prices", axis(2)) xtitle("Year") title("Price Dispersion")

graph export "../figures/tsdispersion.pdf", as(pdf) replace

use "../data/estimationdata", clear

	bys comm1 comm2: egen max_hasrail = max(hasrail)
	keep if max_hasrail==1

	collapse (mean) abslogdiff sdlogdiff, by (year)
	la var abslogdiff "Mean Absolute Difference"
	la var sdlogdiff "Std. Dev. of Difference"
	sort year

	graph twoway line abslogdiff year, scheme(s1mono) yaxis(1) ylabel(0(0.005)0.03) yscale(range(0 0.03) axis(1)) lcolor(black) ///
		ytitle("Mean Absolute Difference in Log Prices") graphregion(color(white)) bgcolor(white) ///
	|| line sdlogdiff year, yaxis(2) yscale(range(0 0.015) axis(2)) ylabel(0(0.003)0.015, axis(2)) lpattern(dash) lcolor(black) ///
		ytitle("Std. Dev. of Difference in Log Prices", axis(2)) xtitle("Year") title("Price Dispersion")

graph export "../figures/tsdispersion_onlyrail.pdf", as(pdf) replace

/*
* || lfit abslogdiff year || lfit sdlogdiff year, yaxis(2) ///	
