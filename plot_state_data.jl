#! /bin/env julia

using Gadfly
using DataFrames
using Clustering
using MultivariateStats

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

# delaware?!?
delaware = state_data[state_data[:State] .== "Delaware", :]
delaware[:Popular_Total] = 
	join(delaware, by(delaware, [:Year, :State], df -> sum(df[:Popular_Vote])), 
	     on=[:State, :Year])[:x1]
delaware[:Popular_Percent] =
	map((vote, total) -> vote / total * 100, delaware[:Popular_Vote],
	    delaware[:Popular_Total])
state_data[state_data[:State] .== "Delaware", :] = delaware

# get electoral vote percents by year
state_data[:Electoral_Total] = 
	join(state_data, by(state_data, [:Year, :State], 
	                    df -> sum(df[:Electoral_Vote])), 
	     on=[:State, :Year])[:x1]
state_data[:Electoral_Percent] = 
	map((vote, total) -> vote / total * 100, state_data[:Electoral_Vote], 
	    state_data[:Electoral_Total])


################################################################################
# assign each state to a geographic region.
################################################################################

new_england = 
	[ "Connecticut", "Maine", "Massachusetts", "New Hampshire", "Rhode Island", 
	  "Vermont" ]
mid_atlantic = 
	[ "New Jersey", "New York", "Pennsylvania" ]
east_north_central = 
	[ "Illinois", "Indiana", "Michigan", "Ohio", "Wisconsin" ]
west_north_central =
	[ "Iowa", "Kansas", "Minnesota", "Missouri", "Nebraska", "North Dakota",
	  "South Dakota" ]
south_atlantic =
	[ "Delaware", "Florida", "Georgia", "Maryland", "North Carolina", 
	  "South Carolina", "Virginia", "D. C.", "West Virginia" ]
east_south_central = 
	[ "Alabama", "Kentucky", "Mississippi", "Tennessee" ]
west_south_central = 
	[ "Arkansas", "Louisiana", "Oklahoma", "Texas" ]
mountain = 
	[ "Arizona", "Colorado", "Idaho", "Montana", "Nevada", "New Mexico", "Utah", 
	  "Wyoming"]
pacific = 
	[ "Alaska", "California", "Hawaii", "Oregon", "Washington" ]

northeast = vcat(new_england, mid_atlantic)
midwest   = vcat(east_north_central, west_north_central)
south     = vcat(south_atlantic, east_south_central, west_south_central)
west      = vcat(mountain, pacific)

#state_data[:Region] = "NA"
#for idx in 1:length(state_data[:State])
#	println(state_data[:State][idx])
#	if state_data[:State][idx] in northeast
#		state_data[:Region][idx] = "Northeast"
#	elseif state_data[:State][idx] in midwest
#		state_data[:Region][idx] = "Midwest"
#	elseif state_data[:State][idx] in south
#		state_data[:Region][idx] = "South"
#	elseif state_data[:State][idx] in west
#		state_data[:Region][idx] = "West"
#	end
#end

#state_data[:Region] = "NA"
#by(state_data, [:State, :Region]) do df
#	if !isempty(intersect(northeast, df[:State]))
#		df[:Region] = "Northeast"
#	elseif !isempty(intersect(midwest, df[:State]))
#		df[:Region] = "Midwest"
#	elseif !isempty(intersect(west, df[:State]))
#		df[:Region] = "West"
#	elseif !isempty(intersect(south, df[:State]))
#		df[:Region] = "South"
#	end
#end

state_data = 
	join(state_data, 
	     (by(state_data, [:State]) do df
	         if !isempty(intersect(northeast, df[:State]))
		         "Northeast"
         	elseif !isempty(intersect(midwest, df[:State]))
         		"Midwest"
         	elseif !isempty(intersect(west, df[:State]))
         		"West"
         	elseif !isempty(intersect(south, df[:State]))
         		"South"
         	end
         end), on=[:State])
rename!(state_data, :x1, :Region)

state_data = 
	join(state_data, 
	     (by(state_data, [:State]) do df
	         if !isempty(intersect(west_south_central, df[:State]))
		         "West South Central"
         	elseif !isempty(intersect(new_england, df[:State]))
         		"New England"
         	elseif !isempty(intersect(mid_atlantic, df[:State]))
         		"Mid-Atlantic"
         	elseif !isempty(intersect(east_north_central, df[:State]))
         		"East North Central"
         	elseif !isempty(intersect(west_north_central, df[:State]))
         		"West North Central"
         	elseif !isempty(intersect(south_atlantic, df[:State]))
         		"South Atlantic"
         	elseif !isempty(intersect(east_south_central, df[:State]))
         		"East South Central"
         	elseif !isempty(intersect(mountain, df[:State]))
         		"Mountain"
         	elseif !isempty(intersect(pacific, df[:State]))
         		"Pacific"
         	end
         end), on=[:State])
rename!(state_data, :x1, :Division)


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
rename!(bi_state_diff, :x1, :Difference)

firstyear = Int(minimum(bi_state_diff[:Year]))-4
lastyear = Int(maximum(bi_state_diff[:Year]))+4
xticks = collect(firstyear:8:lastyear)
if length(xticks) > 20
	xticks = collect(firstyear:12:lastyear)
end

p = plot(bi_state_diff, x=:Year, y=:Difference, Geom.line, Geom.point, 
         color=:State, Coord.Cartesian(xmin=firstyear, xmax=lastyear), 
         Guide.title("Difference in Republican and Democratic Popular Vote"),
         Guide.ylabel("Difference (%)"), Guide.xlabel("Year"), 
	      Guide.xticks(ticks=xticks),  
         Theme(major_label_font_size=24px, key_title_font_size=24px, 
               minor_label_font_size=18px, key_label_font_size=18px,
	            line_width=2px,
	            grid_line_width=1px, grid_color=colorant"black",
               key_position=:bottom, key_max_columns=10))
draw(SVG(string("plots/bi_difference_all_states.svg"), 32cm, 16cm), p)

################################################################################
# all regions over time.
################################################################################

bi_region_diff = 
	by( bi_state_data_1860, [:Year, :Region], 
	    df -> (sum(df[:Popular_Vote][df[:Party] .== "Republican"]) -
              sum(df[:Popular_Vote][df[:Party] .== "Democratic"])) /
             sum(df[:Popular_Total]) * 100 )
rename!(bi_region_diff, :x1, :Difference)

p = plot(bi_region_diff, x=:Year, y=:Difference, Geom.point, Geom.line,
         color=:Region, Coord.Cartesian(xmin=firstyear, xmax=lastyear), 
         Guide.title("Difference in Republican and Democratic Popular Vote"),
         Guide.ylabel("Difference (%)"), Guide.xlabel("Year"), 
	      Guide.xticks(ticks=xticks),  
         Theme(major_label_font_size=24px, key_title_font_size=24px, 
               minor_label_font_size=18px, key_label_font_size=18px,
	            line_width=2px,
	            grid_line_width=1px, grid_color=colorant"black",
               key_position=:bottom, key_max_columns=10))
draw(SVG(string("plots/bi_difference_all_regions.svg"), 32cm, 16cm), p)


################################################################################
# all divisions over time.
################################################################################

bi_division_diff = 
	by( bi_state_data_1860, [:Year, :Division], 
	    df -> (sum(df[:Popular_Vote][df[:Party] .== "Republican"]) -
              sum(df[:Popular_Vote][df[:Party] .== "Democratic"])) /
             sum(df[:Popular_Total]) * 100 )
rename!(bi_division_diff, :x1, :Difference)

p = plot(bi_division_diff, x=:Year, y=:Difference, Geom.point, Geom.line,
         color=:Division, Coord.Cartesian(xmin=firstyear, xmax=lastyear), 
         Guide.title("Difference in Republican and Democratic Popular Vote"),
         Guide.ylabel("Difference (%)"), Guide.xlabel("Year"), 
	      Guide.xticks(ticks=xticks),  
         Theme(major_label_font_size=24px, key_title_font_size=24px, 
               minor_label_font_size=18px, key_label_font_size=18px,
	            line_width=2px,
	            grid_line_width=1px, grid_color=colorant"black",
               key_position=:bottom, key_max_columns=10))
draw(SVG(string("plots/bi_difference_all_divisions.svg"), 32cm, 16cm), p)


################################################################################
# cluster states by popular vote over time. 
################################################################################

