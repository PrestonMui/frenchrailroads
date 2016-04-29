# Read in price data

using DataFrames

# Initialize dataframe
data = DataFrame(
	dept = ASCIIString[],
	comm = ASCIIString[],
	year = Int64[],
	week = Int64[],
	price = Int64[]
	)

pricefile = open("../data/ICPSR_09777_prices/09777-0002-Data.txt")

lines = readlines(pricefile)

loc = "Initialize"
year = 1

for l = collect([28:3260;3282:9058])
	
	# Strip away whitespace and newline character
	line = strip(chomp(lines[l]))

	# Alphabetic characters signal new location
	# Numeric characters signal prices.
	# 13 separate integers = year, then prices
	# 12 separate integers = prices
	
	if isalpha(line[1])
		loc = split(line, r"\s{2,}")
		if size(loc)[1] > 2
			error("Uh oh")
		end
	else
		parsedline = map(x->parse(Int,x),split(line))
		if size(parsedline)[1]==13
			year = parsedline[1]
			for i = 1:12
				push!(data, @data([loc[1], loc[2], year, i, parsedline[i+1]]))
			end
		elseif size(parsedline)[1]==12
			for i = 1:12
				push!(data, @data([loc[1], loc[2], year, i+12, parsedline[i]]))
			end
		else
			print("line ", l, " has an error \n")
		end
	end

end

# Manually fix data for DOUAI
for i = 1:size(data)[1]
	if (data[i,:comm]=="DOUAI") & (data[i,:year]==1886) & (data[i,:week]>12)
		data[i,:year] = 1887
	end
end

# Line 7379:
temp = parsedline = map(x->parse(Int,x),split(strip(chomp(lines[7379]))))
for i = 1:3
	push!(data,@data(["NORD", "DOUAI", 1886, i+12, temp[i]]))
end
for i = 4:11
	push!(data,@data(["NORD","DOUAI",1886,i+13,temp[i]]))
end

# Line 7380:
temp = parsedline = map(x->parse(Int,x),split(strip(chomp(lines[7380]))))
for i = 1:6
	push!(data,@data(["NORD","DOUAI",1887,i,temp[i+1]]))
end

# Zeros are missing data
for i = 1:size(data)[1]
	if data[i,:price]==0
		data[i,:price] = NA
	end
end

close(pricefile)

# Export data to csv
writetable("../data/ICPSR_09777_prices_clean.csv",data[!isna(data[:price]),:])

# Read in Quantity Data
qdata = DataFrame(
	comm = ASCIIString[],
	year = Int64[],
	month = Int64[],
	quantity = Int64[]
	)
qfile = open("../data/ICPSR_09777_quantities/DS0001/09777-0001-Data.txt")
lines = readlines(qfile)

# First part: 1825 - 1850
for l = collect([25:394;402:489])
	comm = strip(lines[l][5:14])
	if l<=394
		head = 23
	elseif l>=402
		head = 400
	end
	for i in collect(16:5:51)
		year = parse(Int,lines[head][i:i+3])
		if lines[head+1][i+1:i+2]=="MR"
			month = 3
		elseif lines[head+1][i+1:i+2]=="JA"
			month = 1
		elseif lines[head+1][i+1:i+2]=="OC"
			month = 10
		end
		if lines[l][i:i+3]=="    "
			quantity = 0
		else
			quantity = parse(Int,lines[l][i:i+3])
		end

		push!(qdata,@data([comm,year,month,quantity]))
	end
end

for i = 1:size(qdata)[1]
	if qdata[i,:quantity]==0
		qdata[i,:quantity] = NA
	end
end

close(qfile)
writetable("../data/ICPSR_09777_quantities_clean.csv",qdata[!isna(qdata[:quantity]),:])