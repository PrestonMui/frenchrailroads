clear all
set more off
set rmsg on

* Read in city coordinate data
use "../data/communes_latlon", clear
	replace comm = subinstr(comm," France","",.)
append using "../data/FRA_adm/FRA_adm2b"

tw (area _Y _X, cmissing(n) fcolor(white) nodropbase) ///
	(scatter lat lon, jitter(1) msize(vsmall) mlabel(comm)), name(simple, replace)
