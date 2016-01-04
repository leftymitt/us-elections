#! /bin/env julia

using Gadfly
using DataFrames

function fixdata(arr)
	result = DataArray(Int, length(arr))
	for i in 1:length(arr)
		result[i] = parse(Int, join(split(arr[i], ',')))
	end
	return result
end

national_data = readtable("data/national_data.txt", separator='\t');
national_data[:Popular_Vote] = fixdata(national_data[:Popular_Vote]);
national_data[:Popular_Total] = join(national_data, by(national_data, :Year, df -> sum(df[:Popular_Vote])), on=:Year)[:x1]
national_data[:Popular_Percent] = map((vote, total) -> vote / total * 100, national_data[:Popular_Vote], national_data[:Popular_Total])

national_data[:Electoral_Vote] = fixdata(national_data[:Electoral_Vote]);
national_data[:Electoral_Total] = join(national_data, by(national_data, :Year, df -> sum(df[:Electoral_Vote])), on=:Year)[:x1]
national_data[:Electoral_Percent] = map((vote, total) -> vote / total * 100, national_data[:Electoral_Vote], national_data[:Electoral_Total])


national_m = melt(national_data, :Party);

#plot(national_data, x=:Year, y=:Popular_Vote, color=:Party, Geom.point)
plot(national_data, x=:Year, y=:Popular_Percent, color=:Party, Geom.line, Geom.point)
#plot(national_data, x=:Year, y=:Electoral_Vote, color=:Party, Geom.point)
plot(national_data, x=:Year, y=:Electoral_Percent, color=:Party, Geom.line, Geom.point)
