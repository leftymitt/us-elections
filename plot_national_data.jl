#! /bin/env julia

using Gadfly
using DataFrames

# pandas saves a comma as a thousands-place separator
function fixdata(arr)
	result = DataArray(Int, length(arr))
	for i in 1:length(arr)
		result[i] = parse(Int, join(split(arr[i], ',')))
	end
	return result
end

#load data and tweak
national_data = readtable("data/national_data.txt", separator='\t');
national_data[:Popular_Vote] = fixdata(national_data[:Popular_Vote]);
rename!(national_data, :PoliticalParty, :Party)

# get popular vote percents by year
national_data[:Popular_Total] = 
	join(national_data, by(national_data, :Year, df -> sum(df[:Popular_Vote])), 
	     on=:Year)[:x1]
national_data[:Popular_Percent] = 
	map((vote, total) -> vote / total * 100, national_data[:Popular_Vote], 
	    national_data[:Popular_Total])

# get electoral vote percents by year
national_data[:Electoral_Vote] = fixdata(national_data[:Electoral_Vote]);
national_data[:Electoral_Total] = 
	join(national_data,
        by(national_data, :Year, df -> sum(df[:Electoral_Vote])), on=:Year)[:x1]
national_data[:Electoral_Percent] = 
	map((vote, total) -> vote / total * 100, national_data[:Electoral_Vote], 
	    national_data[:Electoral_Total])

#national_m = melt(national_data, :Party);

# general plots
plot(national_data, x=:Year, y=:Popular_Percent, color=:Party, Geom.line, Geom.point)
plot(national_data, x=:Year, y=:Electoral_Percent, color=:Party, Geom.line, Geom.point)
plot(national_data, x=:Popular_Percent, y=:Electoral_Percent, color=:Party, Geom.point)

# democrats and republicans
republican_data = national_data[national_data[:Party] .== "Republican", :]
democrat_data = national_data[national_data[:Party] .== "Democratic", :]
bipartisan_data = vcat(republican_data, democrat_data)

plot(bipartisan_data, x=:Year, y=:Popular_Percent, color=:Party, Geom.line, Geom.point, Scale.discrete_color_manual("red", "blue") )
plot(bipartisan_data, x=:Year, y=:Electoral_Percent, color=:Party, Geom.line, Geom.point, Scale.discrete_color_manual("red", "blue") )
plot(bipartisan_data, x=:Popular_Percent, y=:Electoral_Percent, color=:Party, Geom.point, Geom.smooth(method=:lm), Scale.discrete_color_manual("red", "blue") )
