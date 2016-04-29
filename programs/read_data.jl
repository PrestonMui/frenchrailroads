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
