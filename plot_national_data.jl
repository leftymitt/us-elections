#! /usr/bin/env julia

using Gadfly
using DataFrames

include("utils.jl")
Gadfly.push_theme(:dark)

################################################################################
# load data.
################################################################################

national_data = readtable("data/national_data.txt", separator='\t');
national_data[:Popular_Vote] = fixdata(national_data[:Popular_Vote]);
rename!(national_data, :PoliticalParty, :Party)
national_data = national_data[national_data[:PresidentialCandidate] .!= "Unpledged Republican", :]
national_data = national_data[national_data[:PresidentialCandidate] .!= "Unpledged Electors", :]
national_data = national_data[national_data[:Party] .!= "-", :]


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

firstyear = minimum(national_data[:Year]) - 4
lastyear = maximum(national_data[:Year]) + 4
ticks = collect(firstyear:8:lastyear)
if length(ticks) > 20
  ticks = collect(firstyear:12:lastyear)
end

melty_frame = melt(national_data, [:Party, :Year])
electoral_frame = melty_frame[melty_frame[:variable] .== :Electoral_Percent, :]
popular_frame = melty_frame[melty_frame[:variable] .== :Popular_Percent, :]
electoral_frame[:Category] = "Electoral"
popular_frame[:Category] = "Popular"
joined_frame = vcat(electoral_frame, popular_frame)
rename!(joined_frame, :value, :Percent)

p = plot(joined_frame, x=:Year, y=:Percent, ygroup=:Category, color=:Party,
         Geom.subplot_grid(Geom.point, Geom.line, Guide.xticks(ticks=ticks),
                           Coord.Cartesian(xmin=firstyear, xmax=lastyear)),
         style(major_label_font_size=24px, key_title_font_size=24px,
               minor_label_font_size=18px, key_label_font_size=18px,
               grid_line_width=1px,
               line_width=2px, key_position=:bottom, key_max_columns=7))
draw(SVG("plots/all_national.svg", 32cm, 16cm), p)

ticks = collect(0:25:100)
p = plot(national_data, x=:Popular_Percent, y=:Electoral_Percent, color=:Party,
         Guide.xlabel("Popular Vote (%)"), Guide.ylabel("Electoral Vote (%)"),
         Guide.xticks(ticks=ticks), Guide.yticks(ticks=ticks),
         Geom.point, Coord.Cartesian(ymin=0,ymax=100, xmin=0),
         style(major_label_font_size=24px, key_title_font_size=24px,
               minor_label_font_size=18px, key_label_font_size=18px,
               grid_line_width=1px,
               key_position=:bottom, key_max_columns=7,
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
ticks = collect(firstyear:8:lastyear)
if length(ticks) > 20
  ticks = collect(firstyear:12:lastyear)
end

melty_frame = melt(bi_nation_data, [:Party, :Year])
electoral_frame = melty_frame[melty_frame[:variable] .== :Electoral_Percent, :]
popular_frame = melty_frame[melty_frame[:variable] .== :Popular_Percent, :]
electoral_frame[:Category] = "Electoral"
popular_frame[:Category] = "Popular"
joined_frame = vcat(electoral_frame, popular_frame)
rename!(joined_frame, :value, :Percent)

# plot both popular and electoral vote over time.
p = plot(joined_frame, x=:Year, y=:Percent, ygroup=:Category, color=:Party,
         Geom.subplot_grid(Geom.point, Geom.line, Guide.xticks(ticks=ticks),
                           Coord.Cartesian(xmin=firstyear, xmax=lastyear)),
         Scale.discrete_color_manual("red", "blue"),
         style(major_label_font_size=24px, key_title_font_size=24px,
               minor_label_font_size=18px, key_label_font_size=18px,
               grid_line_width=1px,
               line_width=2px, key_position=:bottom, key_max_columns=7))
draw(SVG("plots/bi_national.svg", 32cm, 16cm), p)

# combined popular and electoral vote over time. (after 1860)
total_joined_frame = by(joined_frame, [:Category, :Year],
                        df -> DataFrame(Percent = sum(df[:Percent])))
total_joined_frame = total_joined_frame[total_joined_frame[:Year] .>= 1860, :]
p = plot(total_joined_frame, x=:Year, y=:Percent, ygroup=:Category, 
         Geom.subplot_grid(Geom.point, Geom.line, Guide.xticks(ticks=ticks),
                           Guide.yticks(ticks=collect(0:25:100)),
                           Coord.Cartesian(xmin=1856, xmax=lastyear,
                                           ymin=0, ymax=100)),
         Scale.discrete_color_manual("red", "blue"),
         style(major_label_font_size=24px, key_title_font_size=24px,
               minor_label_font_size=18px, key_label_font_size=18px,
               grid_line_width=1px,
               line_width=2px, key_position=:bottom, key_max_columns=7))
draw(SVG("plots/bi_total_national.svg", 32cm, 16cm), p)


# plot electoral percent against popular vote percent.
ticks = collect(0:25:100)
p = plot(bi_nation_data, x=:Popular_Percent, y=:Electoral_Percent,
         color=:Party, Geom.point, Geom.smooth(method=:lm),
         Guide.xlabel("Popular Vote (%)"), Guide.ylabel("Electoral Vote (%)"),
         Scale.discrete_color_manual("red", "blue"),
         Guide.xticks(ticks=ticks), Guide.yticks(ticks=ticks),
         Coord.Cartesian(ymin=0,ymax=100, xmin=0),
         style(major_label_font_size=24px, key_title_font_size=24px,
               minor_label_font_size=18px, key_label_font_size=18px,
               grid_line_width=1px,
               key_position=:bottom, key_max_columns=7,
               default_point_size=5px))
draw(SVG("plots/bi_popular_v_electoral_national.svg", 32cm, 16cm), p)

# plot difference in republican and democrate electoral and popular vote %
# against each other.
bi_nation_data_1860 = bi_nation_data[bi_nation_data[:Year] .>= 1860, :]
bi_nation_diff = by( bi_nation_data_1860, [:Year],
                     df -> df[:Popular_Percent][df[:Party] .== "Republican"] -
                           df[:Popular_Percent][df[:Party] .== "Democratic"] )
rename!(bi_nation_diff, :x1, :Popular_Diff)
bi_nation_diff =
  join(bi_nation_diff,
       by(bi_nation_data_1860, [:Year],
       df -> df[:Electoral_Percent][df[:Party] .== "Republican"] -
             df[:Electoral_Percent][df[:Party] .== "Democratic"]), on=:Year)
rename!(bi_nation_diff, :x1, :Electoral_Diff)

p = plot(bi_nation_diff, x=:Popular_Diff, y=:Electoral_Diff,
         Geom.point, Geom.smooth(method=:lm),
         label=[ string(year) for year in bi_nation_diff[:Year] ],
         Geom.label(position=:dynamic, hide_overlaps=false),
         Guide.xlabel("Popular Difference (%)"),
         Guide.ylabel("Electoral Difference (%)"),
         Coord.Cartesian(ymin=-100,ymax=100),
         style(major_label_font_size=20px, key_title_font_size=20px,
               minor_label_font_size=16px, key_label_font_size=16px,
               point_label_font_size=13px,
               grid_line_width=1px,
               key_position=:none, key_max_columns=7,
               default_point_size=5px))
draw(SVG("plots/bi_popular_v_electoral_national_diff.svg", 20cm, 16cm), p)
