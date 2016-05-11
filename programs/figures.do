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
	replace position = 2 if inlist(comm,"Montauban","Chalonssurmarne")
	replace position = 4 if inlist(comm,"Soissons","Evreux","Bayeux")
	replace position = 6 if inlist(comm,"Saintlo","Laval","Arras","Albertville","Clermont")
	replace position = 8 if comm=="Blois"
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
	
	graph twoway line num_lines year, yaxis(1) yscale(range(0) axis(1)) lcolor(black) ///
		ytitle("Lines Opened") graphregion(color(white)) bgcolor(white) ///
	|| line dist year, yaxis(2) yscale(range(0) axis(2)) lpattern(dash) lcolor(black) ///
		ytitle("KM of Lines Opened", axis(2)) xtitle("Year") title("Rail Lines Opened, by Year")
	
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

