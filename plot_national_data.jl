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
national_data = national_data[national_data[:PresidentialCandidate] .!= "Unpledged Republican", :]
national_data = national_data[national_data[:PresidentialCandidate] .!= "Unpledged Electors", :]

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
         Guide.xlabel("Year"), Guide.ylabel("Popular Vote (%)"), 
         Geom.line, Geom.point, Coord.Cartesian(ymin=0,ymax=100),
         Theme(major_label_font_size=24px, key_title_font_size=24px, 
               minor_label_font_size=18px, key_label_font_size=18px,
               grid_line_width=1px, grid_color=colorant"black",
               line_width=2px))
draw(SVG("plots/all_popular_national.svg", 32cm, 16cm), p)

p = plot(national_data, x=:Year, y=:Electoral_Percent, color=:Party, 
         Guide.xlabel("Year"), Guide.ylabel("Popular Vote (%)"), 
         Geom.line, Geom.point, Coord.Cartesian(ymin=0,ymax=100),
         Theme(major_label_font_size=24px, key_title_font_size=24px, 
               minor_label_font_size=18px, key_label_font_size=18px,
               grid_line_width=1px, grid_color=colorant"black",
               line_width=2px))
draw(SVG("plots/all_electoral_national.svg", 32cm, 16cm), p)

p = plot(national_data, x=:Popular_Percent, y=:Electoral_Percent, color=:Party, 
         Guide.xlabel("Popular Vote (%)"), Guide.ylabel("Electoral Vote (%)"), 
         Geom.point, Coord.Cartesian(ymin=0,ymax=100),
         Theme(major_label_font_size=24px, key_title_font_size=24px, 
               minor_label_font_size=18px, key_label_font_size=18px,
               grid_line_width=1px, grid_color=colorant"black",
               default_point_size=5px))
draw(SVG("plots/all_popular_v_electoral_national.svg", 32cm, 16cm), p)

################################################################################
# democrats and republicans.
################################################################################
republican_data = national_data[national_data[:Party] .== "Republican", :]
democrat_data = national_data[national_data[:Party] .== "Democratic", :]
bi_nation_data = vcat(republican_data, democrat_data)

firstyear = minimum(bi_nation_data[:Year]) - 4
lastyear = maximum(bi_nation_data[:Year]) + 4

p = plot(bi_nation_data, x=:Year, y=:Popular_Percent, 
         color=:Party, Geom.line, Geom.point, 
         Guide.xlabel("Year"), Guide.ylabel("Popular Vote (%)"), 
         Scale.discrete_color_manual("red", "blue"),
         Coord.Cartesian(xmin=firstyear, xmax=lastyear),
         Theme(major_label_font_size=24px, key_title_font_size=24px, 
               minor_label_font_size=18px, key_label_font_size=18px,
               grid_line_width=1px, grid_color=colorant"black",
               line_width=2px))
draw(SVG("plots/bi_popular_national.svg", 32cm, 16cm), p)

p = plot(bi_nation_data, x=:Year, y=:Electoral_Percent, 
         color=:Party, Geom.line, Geom.point, 
         Guide.xlabel("Year"), Guide.ylabel("Popular Vote (%)"), 
         Scale.discrete_color_manual("red", "blue"),
         Coord.Cartesian(xmin=firstyear, xmax=lastyear),
         Theme(major_label_font_size=24px, key_title_font_size=24px, 
               minor_label_font_size=18px, key_label_font_size=18px,
               grid_line_width=1px, grid_color=colorant"black",
               line_width=2px))
draw(SVG("plots/bi_electoral_national.svg", 32cm, 16cm), p)

p = plot(bi_nation_data, x=:Popular_Percent, y=:Electoral_Percent, 
         color=:Party, Geom.point, Geom.smooth(method=:lm), 
         Guide.xlabel("Popular Vote (%)"), Guide.ylabel("Electoral Vote (%)"), 
         Scale.discrete_color_manual("red", "blue"),
         Coord.Cartesian(ymin=0, ymax=100),
         Theme(major_label_font_size=24px, key_title_font_size=24px, 
               minor_label_font_size=18px, key_label_font_size=18px,
               grid_line_width=1px, grid_color=colorant"black",
               default_point_size=5px))
draw(SVG("plots/bi_popular_v_electoral_national.svg", 32cm, 16cm), p)
