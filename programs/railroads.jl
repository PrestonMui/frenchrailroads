# Read in railroad data.
# Create graph. Move through time.

using DataFrames, Graphs

#####################
# 1. Define distance function
#####################

function latlondist(lat1::Float64,lon1::Float64,lat2::Float64,lon2::Float64)
	
	lat1dec = pi * lat1 / 180
	lon1dec = pi * lon1 / 180
	lat2dec = pi * lat2 / 180
	lon2dec = pi * lon2 / 180

	dlat = lat2dec - lat1dec
	dlon = lon2dec - lon1dec
	a = (sin(dlat/2)).^2 + cos(lat1dec) .* cos(lat2dec) .* (sin(dlon/2)).^2
	dist = 6371 * 2 * atan2( sqrt(a), sqrt(1-a) )
	
	return dist
end

#####################
# 2. Prepare railroad data
#####################

	# Read in data
	openings = readtable("../data/railopenings.csv")
	latlons = readtable("../data/cheminsdefer_latlon.csv")
	latlons = latlons[!isna(latlons[:lat]),:]

	# Latlons: Create ID for vertices.
	sort!(latlons, cols= [:comm])
	latlons[:id] = collect(1:size(latlons)[1])

	# temp = DataFrame(
	# 	station1 = ASCIIString[],
	# 	station2 = ASCIIString[],
	# 	dist = Float64[])
	# for i = 1:size(latlons)[1]
	# 	for j = i+1:size(latlons)[1]
	# 		dist = latlondist(latlons[i,:lat],latlons[i,:lon],latlons[j,:lat],latlons[j,:lon])
	# 		push!(temp, @data([latlons[i,:comm], latlons[j,:comm], dist]))
	# 	end
	# end

	# Join Lat/Lon to Openings
	for i in ["1","2"]
		rename!(openings,symbol(string("comm",i)),:comm)
		openings = join(openings,latlons, on = :comm)
		for var in ["comm","lat","lon","id"]
			rename!(openings,symbol(var),symbol(string(var,i)))
		end
	end
	
	# Calculate distances
	openings[:dist] = map(latlondist,openings[:lat1],openings[:lon1],openings[:lat2],openings[:lon2])

	# Create tweeks
	for var in ["year","week","tweek"]
		openings[symbol(var)] = DataArray(Int64,size(openings)[1])
	end
	for i = 1:size(openings)[1]
		datestr = string(openings[i,:Date])
		openings[i,:year] = parse(Int,datestr[1:4])
		openings[i,:week] = 2 * parse(Int,datestr[5:6]) - (parse(Int,datestr[7:8]) <= 15)
		openings[i,:tweek] = 24 * (openings[i,:year] - 1825) + openings[i,:week]
	end

#####################
# 3. Match railroad data to price communes
#####################
	pricecommunes = readtable("../data/communes_latlon.csv")
	sort!(pricecommunes, cols=[order(:comm)])
	commune_chemins = Dict{Int64,Array{Int64,1}}()
	for i = 1:size(pricecommunes)[1]
		commune_chemins[i] = Array{Int64,1}[]
		for j = 1:size(latlons)[1]
			if latlondist(pricecommunes[i,:lat],pricecommunes[i,:lon],latlons[j,:lat],latlons[j,:lon]) < 40
				push!(commune_chemins[i],j)
			end
		end
	end
	
#####################
# 4. Graph vertices
#####################

	# Create DataFrames to store results
	# collect(combinations(collect(1:maximum(latlons[:id])),2))
	snapshot_template = DataFrame(
		comm1 = map(x -> x[1], collect(combinations(collect(1:size(pricecommunes)[1]),2))),
		comm2 = map(x -> x[2], collect(combinations(collect(1:size(pricecommunes)[1]),2))),
		tweek = 0,
		dist = Inf)
	snapshot_template[:comm1name] = map(x->pricecommunes[x,:comm],snapshot_template[:comm1])
	snapshot_template[:comm2name] = map(x->pricecommunes[x,:comm],snapshot_template[:comm2])
	connections = DataFrame()
	
	# chemins stores direct routes
	chemins = fill(Inf,size(latlons)[1],size(latlons)[1])
	for i = 1:size(latlons)[1]
		chemins[i,i] = 0.0
	end

	# shortest_routes stores calculated shortest routes
	shortest_routes = fill(Inf,size(latlons)[1],size(latlons)[1])

	for w = 1:1104
		
		# If there were any openings that week, add them and recalculate shortest distances
		opened = openings[openings[:,:tweek].==w,:]
		if size(opened)[1]!=0
			for j = 1:size(opened)[1]
				chemins[opened[j,:id1],opened[j,:id2],] = opened[j,:dist]
				chemins[opened[j,:id2],opened[j,:id1],] = opened[j,:dist]
			end
			shortest_routes = floyd_warshall(chemins)
		end

		# Push shortest distances to price commune-to-commune distance
		snapshot = copy(snapshot_template)
		for p = 1:size(snapshot)[1]
			if (size(commune_chemins[snapshot[p,:comm1]])[1] > 0) & (size(commune_chemins[snapshot[p,:comm2]])[1] > 0)
				snapshot[p,:dist] = minimum(shortest_routes[commune_chemins[snapshot[p,:comm1]],commune_chemins[snapshot[p,:comm2]]])
			end
		end
		snapshot[:tweek] = w
		connections = vcat(connections,snapshot)

	end

writetable("../data/commune_connections.csv",connections)
writetable("../data/cheminsdefer_connections.csv",openings)
