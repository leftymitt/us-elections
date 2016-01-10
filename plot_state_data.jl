#! /bin/env julia

using Gadfly
using DataFrames

include("utils.jl")

################################################################################
# load data.
################################################################################
state_data = readtable("data/state_data.txt", separator='\t');
state_data[:Popular_Vote] = fixdata(state_data[:Popular_Vote]);
rename!(state_data, :PoliticalParty, :Party)

################################################################################
# calculate popular and electoral vote totals and percents.
################################################################################

# get popular vote percents by year
state_data[:Popular_Total] = 
	join(state_data, by(state_data, [:Year, :State], 
	                    df -> sum(df[:Popular_Vote])), 
	     on=[:State, :Year])[:x1]
state_data[:Popular_Percent] = 
	map((vote, total) -> vote / total * 100, state_data[:Popular_Vote], 
	    state_data[:Popular_Total])

# get electoral vote percents by year
state_data[:Electoral_Total] = 
	join(state_data, by(state_data, [:Year, :State], 
	                    df -> sum(df[:Electoral_Vote])), 
	     on=[:State, :Year])[:x1]
state_data[:Electoral_Percent] = 
	map((vote, total) -> vote / total * 100, state_data[:Electoral_Vote], 
	    state_data[:Electoral_Total])

################################################################################
# general plots.
################################################################################
for state in groupby(state_data, :State)
	p = plot(state, x=:Year, y=:Popular_Percent, color=:Party, Geom.line, Geom.point)
	slug = replace(replace(string(state[:State][1]), " ", "_"), ".", "")
	draw(SVG(lowercase(strip(string("plots/all_", slug, ".svg"))), 27cm, 9cm), p)
end

################################################################################
# democrats and republicans.
################################################################################
republican_data = state_data[state_data[:Party] .== "Republican", :]
democrat_data = state_data[state_data[:Party] .== "Democratic", :]
bipartisan_data = vcat(republican_data, democrat_data)

for state in groupby(bipartisan_data, :State)
	p = plot(state, x=:Year, y=:Popular_Percent, color=:Party, Geom.line, 
	         Geom.point, Scale.discrete_color_manual("red", "blue"))
	slug = replace(replace(string(state[:State][1]), " ", "_"), ".", "")
	draw(SVG(lowercase(strip(string("plots/bi_", slug, ".svg"))), 27cm, 9cm), p)
end

################################################################################
# all states over time.
################################################################################
bipartisan_data_1860 = bipartisan_data[bipartisan_data[:Year] .>= 1860, :]
bipartisan_diff = by( bipartisan_data_1860, [:Year, :State], 
                      df -> df[:Popular_Percent][df[:Party] .== "Republican"] - 
							       df[:Popular_Percent][df[:Party] .== "Democratic"] )

p = plot([ layer(state, x=:Year, y=:x1,  Geom.line, color=state[:State]) 
           for state in groupby(bipartisan_diff, :State) ]..., 
         Theme(key_position=:none))
draw(SVG(string("plots/bi_all_states.svg"), 32cm, 9cm), p)
