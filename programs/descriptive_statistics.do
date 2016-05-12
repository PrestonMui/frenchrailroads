clear all
set more off
set rmsg on

* Rails
insheet using "../data/cheminsdefer_connections.csv", comma clear
	
	* Average distance of route
	sum dist, d

	* Total by year
	sort tweek
	gen temp = 1
	gen km = sum(dist)
	gen num = sum(temp)
	collapse (max) km num, by(year)
	list if inlist(year,1845,1850,1855,1860,1865,1870)

* Communes: Number of communes which are not connected
use "../data/estimationdata", clear
	foreach i in 1 2 {
		preserve
		bys comm`i': egen temp = max(hasrail)
		gen neverrail`i' = temp==0
		drop temp
		keep comm`i' neverrail`i'
		keep if neverrail`i'==1
		duplicates drop
		list
		restore
	}
