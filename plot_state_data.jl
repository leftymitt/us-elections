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
	firstyear = Int(minimum(state[:Year]))-4
	lastyear = Int(maximum(state[:Year]))+4
	xticks = collect(firstyear:8:lastyear)
	if length(xticks) > 20
		xticks = collect(firstyear:12:lastyear)
	end
	yticks = collect(0:25:100)
	p = plot(state, x=:Year, y=:Popular_Percent, color=:Party, Guide.xlabel("Year"), 
	         Guide.ylabel("Popular Vote (%)"), Geom.line, Geom.point, 
            Guide.title(string(state[:State][1])), 
	         Guide.xticks(ticks=xticks), Guide.yticks(ticks=yticks), 
	         Coord.Cartesian(xmin=firstyear, xmax=lastyear, ymin=0, ymax=100), 
            Theme(major_label_font_size=24px, key_title_font_size=24px, 
                  minor_label_font_size=18px, key_label_font_size=18px,
	               line_width=2px,
		            grid_line_width=1px, grid_color=colorant"black",
                  key_position=:bottom, key_max_columns=7))
	slug = replace(replace(string(state[:State][1]), " ", "_"), ".", "")
	draw(SVG(lowercase(strip(string("plots/all_", slug, ".svg"))), 32cm, 16cm), p)
end

################################################################################
# democrats and republicans.
################################################################################
republican_data = state_data[state_data[:Party] .== "Republican", :]
democrat_data = state_data[state_data[:Party] .== "Democratic", :]
bi_state_data = vcat(republican_data, democrat_data)

for state in groupby(bi_state_data, :State)
	firstyear = Int(minimum(state[:Year]))-4
	lastyear = Int(maximum(state[:Year]))+4
	xticks = collect(firstyear:8:lastyear)
	if length(xticks) > 20
		xticks = collect(firstyear:12:lastyear)
	end
	yticks = collect(0:25:100)
	p = plot(state, x=:Year, y=:Popular_Percent, color=:Party, Geom.line, 
	         Geom.point, Scale.discrete_color_manual("red", "blue"),
	         Guide.ylabel("Popular Vote (%)"), Guide.xlabel("Year"), 
	         Guide.title(string(state[:State][1])), 
	         Guide.xticks(ticks=xticks), Guide.yticks(ticks=yticks), 
	         Coord.Cartesian(xmin=firstyear, xmax=lastyear, ymin=0, ymax=100), 
				Theme(major_label_font_size=24px, key_title_font_size=24px, 
						minor_label_font_size=18px, key_label_font_size=18px,
	               line_width=2px,
	               grid_line_width=1px, grid_color=colorant"black",
	               key_position=:bottom, key_max_columns=7))
	slug = replace(replace(string(state[:State][1]), " ", "_"), ".", "")
	draw(SVG(lowercase(strip(string("plots/bi_", slug, ".svg"))), 32cm, 16cm), p)
end

################################################################################
# all states over time.
################################################################################
bi_state_data_1860 = bi_state_data[bi_state_data[:Year] .>= 1860, :]
bi_state_diff = by( bi_state_data_1860, [:Year, :State], 
                      df -> df[:Popular_Percent][df[:Party] .== "Republican"] - 
							       df[:Popular_Percent][df[:Party] .== "Democratic"] )

p = plot([ layer(state, x=:Year, y=:x1,  Geom.line, color=state[:State]) 
           for state in groupby(bi_state_diff, :State) ]..., 
         Coord.Cartesian(xmin=1856, xmax=2016), 
         Guide.title("Difference in Republican & Democratic Popular Vote"),
         Guide.ylabel("Popular Vote Difference (%)"), Guide.xlabel("Year"), 
         Theme(major_label_font_size=24px, key_title_font_size=24px, 
               minor_label_font_size=18px, key_label_font_size=18px,
	            line_width=2px,
	            grid_line_width=1px, grid_color=colorant"black",
               key_position=:bottom, key_max_columns=7))
draw(SVG(string("plots/bi_difference_all_states.svg"), 32cm, 16cm), p)


################################################################################
# cluster states by popular vote over time. 
################################################################################
