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

* Affect on "average" and "maximal" communes
local avg = 345
local max = 900

use "../data/coefficients", clear
	
	foreach thing in abs sd {
		preserve
		quietly {
			keep `thing'*
			ren *1 *
			gen variable = _n
			reshape long `thing'logdiff_b, i(variable) j(threshold)
				ren `thing'logdiff_b b
			reshape wide b, i(threshold) j(variable)

			gen avg_effect = b2 + b3 * (log(`avg') - log(threshold))
			gen avg_effect_relative = (b2 + b3 * (log(`avg') - log(threshold))) / (b1 * log(`avg'))
			gen max_effect = b2 + b3 * (log(`max') - log(threshold))
			gen max_effect_relative = (b2 + b3 * (log(`max') - log(threshold))) / (b1 * log(`max'))
		}

		list *effect*
		restore	
	}
