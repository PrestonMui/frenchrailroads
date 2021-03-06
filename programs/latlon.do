* Get coordinates for railroads and communes

clear all
set more off
set rmsg on
cap log close

local rails = 1
local communes = 0

tempfile tmp

* Read in Data
if `rails'==1 {

	insheet using "../data/railopenings.csv", clear

	preserve
		keep comm1
		ren comm1 comm
		save "temp/comm1", replace
	restore

	keep comm2
	ren comm2 comm
	append using "temp/comm1"
	duplicates drop
	replace comm = comm + " France" if regexm(comm,"Canal")==0
		
	* Geocode stuff
	gen lat = ""
	gen lon = ""
	local numobs = _N
	forv i = 1/`numobs' {
		local addr = comm[`i']
		local addr = subinstr("`addr'"," ","+",.)

		cap copy "https://maps.googleapis.com/maps/api/geocode/json?address=`addr'&key=AIzaSyCsDf3MMiLHZTtj1xMEs1PTcRua9p6831s" `tmp', replace
		
		if _rc!=0 {
			exit
		}

		preserve
			insheet using `tmp', clear
			local numrows = _N
			if `numrows'==4 {
				local lat = "."
				local lon = "."
			}
			else {
				forv j = 1/`numrows' {
					if regexm(v1[`j'],"location")==1 {
						local lat = substr(v1[`j'+1],7,.)
						local lon = substr(v1[`j'+2],7,.)
						exit
					}
				}
			}
		restore
		qui replace lat = "`lat'" in `i'
		qui replace lon = "`lon'" in `i'
		local lat
		local lon
		sleep 500
	}

replace lat = substr(lat,1,length(lat) - 1)
destring lat lon, replace
replace comm = subinstr(comm," France","",.)

* Some will need manual fixing
replace lat = 48.8566 if comm=="Paris"
replace lon = 2.3522 if comm=="Paris"
replace lat = 45.207044 if comm=="Pique-pierre"
replace lon = 5.708411 if comm=="Pique-pierre"

* Not really sure where this one is
drop if comm=="Fournaux"

outsheet using "../data/cheminsdefer_latlon.csv", comma replace

}

* Communes data
if `communes'==1 {

	insheet using "../data/ICPSR_09777_prices_clean.csv", comma clear

	keep comm
	duplicates drop
	replace comm = comm + " France"

	gen lat = ""
	gen lon = ""

	local numobs = _N
	forv i = 1/`numobs' {
		local addr = comm[`i']
		local addr = subinstr("`addr'"," ","+",.)

		cap copy "https://maps.googleapis.com/maps/api/geocode/json?address=`addr'" `tmp', replace
		
		preserve
			insheet using `tmp', clear
			local numrows = _N
			forv j = 1/`numrows' {
				if regexm(v1[`j'],"location")==1 {
					local lat = substr(v1[`j'+1],7,.)
					local lon = substr(v1[`j'+2],7,.)
					exit
				}
			}
		restore
		qui replace lat = "`lat'" in `i'
		qui replace lon = "`lon'" in `i'
		local lat
		local lon
		sleep 1000
	}

	qui replace lat = substr(lat,1,length(lat) - 1)
	qui destring lat lon, replace

	replace comm = lower(subinstr(comm, " France","",.))
	local i = 1
	while `i' > 0 {
		replace comm = regexr(comm, "[^a-z]","")
		count if regexm(comm,"[^a-z]")
		local i = r(N)
	}

	outsheet using "../data/communes_latlon", comma replace
}
