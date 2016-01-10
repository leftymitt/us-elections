#! /bin/env julia

using Gadfly
using DataFrames

include("utils.jl")

################################################################################
# load data.
################################################################################
national_data = readtable("data/national_data.txt", separator='\t');
national_data[:Popular_Vote] = fixdata(national_data[:Popular_Vote]);
#national_data[:Electoral_Vote] = fixdata(national_data[:Electoral_Vote]);
rename!(national_data, :PoliticalParty, :Party)

################################################################################
# calculate popular and electoral vote totals and percents.
################################################################################

# get popular vote percents by year
national_data[:Popular_Total] = 
	join(national_data, by(national_data, :Year, df -> sum(df[:Popular_Vote])), 
	     on=:Year)[:x1]
national_data[:Popular_Percent] = 
	map((vote, total) -> vote / total * 100, national_data[:Popular_Vote], 
	    national_data[:Popular_Total])

# get electoral vote percents by year
national_data[:Electoral_Total] = 
	join(national_data,
        by(national_data, :Year, df -> sum(df[:Electoral_Vote])), on=:Year)[:x1]
national_data[:Electoral_Percent] = 
	map((vote, total) -> vote / total * 100, national_data[:Electoral_Vote], 
	    national_data[:Electoral_Total])

################################################################################
# general plots.
################################################################################
p = plot(national_data, x=:Year, y=:Popular_Percent, color=:Party, 
         Geom.line, Geom.point)
draw(SVG("plots/all_popular_national.svg", 27cm, 9cm), p)
p = plot(national_data, x=:Year, y=:Electoral_Percent, color=:Party, 
         Geom.line, Geom.point)
draw(SVG("plots/all_electoral_national.svg", 27cm, 9cm), p)
p = plot(national_data, x=:Popular_Percent, y=:Electoral_Percent, color=:Party, 
         Geom.point)
draw(SVG("plots/all_popular_v_electoral_national.svg", 27cm, 9cm), p)

################################################################################
# democrats and republicans.
################################################################################
republican_data = national_data[national_data[:Party] .== "Republican", :]
democrat_data = national_data[national_data[:Party] .== "Democratic", :]
bipartisan_data = vcat(republican_data, democrat_data)

p = plot(bipartisan_data, x=:Year, y=:Popular_Percent, 
         color=:Party, Geom.line, Geom.point, 
         Scale.discrete_color_manual("red", "blue"))
draw(SVG("plots/bi_popular_national.svg", 27cm, 9cm), p)
p = plot(bipartisan_data, x=:Year, y=:Electoral_Percent, 
         color=:Party, Geom.line, Geom.point, 
         Scale.discrete_color_manual("red", "blue"))
draw(SVG("plots/bi_electoral_national.svg", 27cm, 9cm), p)
p = plot(bipartisan_data, x=:Popular_Percent, y=:Electoral_Percent, 
         color=:Party, Geom.point, Geom.smooth(method=:lm), 
         Scale.discrete_color_manual("red", "blue"))
draw(SVG("plots/bi_popular_v_electoral_national.svg", 27cm, 9cm), p)
