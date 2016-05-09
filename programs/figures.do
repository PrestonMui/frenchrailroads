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
