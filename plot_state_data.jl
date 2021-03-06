#! /usr/bin/env julia

using Gadfly
using DataFrames
using Clustering
using Distances
using StatsBase
using MultivariateStats

Gadfly.push_theme(:dark)
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

# dc?!?
dc = state_data[state_data[:State] .== "D. C.", :]
dc[:Popular_Total] =
  join(dc, by(dc, [:Year, :State], df -> sum(df[:Popular_Vote])),
       on=[:State, :Year])[:x1]
dc[:Popular_Percent] =
  map((vote, total) -> vote / total * 100, dc[:Popular_Vote],
      dc[:Popular_Total])
state_data[state_data[:State] .== "D. C.", :] = dc

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

state_data =
  join(state_data,
       (by(state_data, [:State]) do df
           if !isempty(intersect(northeast, df[:State]))
             DataFrame(Region="Northeast")
           elseif !isempty(intersect(midwest, df[:State]))
             DataFrame(Region="Midwest")
           elseif !isempty(intersect(west, df[:State]))
             DataFrame(Region="West")
           elseif !isempty(intersect(south, df[:State]))
             DataFrame(Region="South")
           end
         end), on=[:State])

state_data =
  join(state_data,
       (by(state_data, [:State]) do df
           if !isempty(intersect(west_south_central, df[:State]))
             DataFrame(Division="West South Central")
           elseif !isempty(intersect(new_england, df[:State]))
             DataFrame(Division="New England")
           elseif !isempty(intersect(mid_atlantic, df[:State]))
             DataFrame(Division="Mid-Atlantic")
           elseif !isempty(intersect(east_north_central, df[:State]))
             DataFrame(Division="East North Central")
           elseif !isempty(intersect(west_north_central, df[:State]))
             DataFrame(Division="West North Central")
           elseif !isempty(intersect(south_atlantic, df[:State]))
             DataFrame(Division="South Atlantic")
           elseif !isempty(intersect(east_south_central, df[:State]))
             DataFrame(Division="East South Central")
           elseif !isempty(intersect(mountain, df[:State]))
             DataFrame(Division="Mountain")
           elseif !isempty(intersect(pacific, df[:State]))
             DataFrame(Division="Pacific")
           end
         end), on=[:State])


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
            style(major_label_font_size=24px, key_title_font_size=24px,
                  minor_label_font_size=18px, key_label_font_size=18px,
                 line_width=2px,
                grid_line_width=1px,
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
        style(major_label_font_size=24px, key_title_font_size=24px,
            minor_label_font_size=18px, key_label_font_size=18px,
                 line_width=2px,
                 grid_line_width=1px,
                 key_position=:bottom, key_max_columns=7))
  slug = replace(replace(string(state[:State][1]), " ", "_"), ".", "")
  draw(SVG(lowercase(strip(string("plots/bi_", slug, ".svg"))), 32cm, 16cm), p)
end


################################################################################
# all states over time.
################################################################################

bi_state_data_1860 = bi_state_data[bi_state_data[:Year] .>= 1860, :]
bi_state_diff =
  by( bi_state_data_1860, [:Year, :State, :Region, :Division],
      df -> DataFrame(
               Difference =
                  (df[:Popular_Percent][df[:Party] .== "Republican"] -
                   df[:Popular_Percent][df[:Party] .== "Democratic"]),
               Total =
                  (sum(df[:Popular_Percent][df[:Party] .== "Republican"]) +
                   sum(df[:Popular_Percent][df[:Party] .== "Democratic"])) ) )

firstyear = Int(minimum(bi_state_diff[:Year]))-4
lastyear = Int(maximum(bi_state_diff[:Year]))+4
xticks = collect(firstyear:8:lastyear)
if length(xticks) > 20
  xticks = collect(firstyear:12:lastyear)
end

p = plot(bi_state_diff, x=:Year, y=:Difference, Geom.line, Geom.point,
         color=:State, Coord.Cartesian(xmin=firstyear, xmax=lastyear),
         Guide.title("Republican - Democratic Popular Vote (%) by State"),
         Guide.ylabel("Difference (%)"), Guide.xlabel("Year"),
        Guide.xticks(ticks=xticks), 
         style(major_label_font_size=24px, key_title_font_size=24px,
               minor_label_font_size=18px, key_label_font_size=18px,
              line_width=2px,
              grid_line_width=1px,
               key_position=:bottom, key_max_columns=10))
draw(SVG(string("plots/bi_diff_all_states.svg"), 32cm, 16cm), p)

p = plot(bi_state_diff, x=:Year, y=:Total, Geom.line, Geom.point,
         color=:State, Coord.Cartesian(xmin=firstyear, xmax=lastyear, ymax=100),
         Guide.title("Total Republican and Democratic Popular Vote (%) by State"),
         Guide.ylabel("Total (%)"), Guide.xlabel("Year"),
        Guide.xticks(ticks=xticks), 
         style(major_label_font_size=24px, key_title_font_size=24px,
               minor_label_font_size=18px, key_label_font_size=18px,
              line_width=2px,
              grid_line_width=1px,
               key_position=:bottom, key_max_columns=10))
draw(SVG(string("plots/bi_total_all_states.svg"), 32cm, 16cm), p)


################################################################################
# all regions over time.
################################################################################

bi_region_diff =
  by( bi_state_data_1860, [:Year, :Region],
      df -> DataFrame(
               Difference =
                  (sum(df[:Popular_Vote][df[:Party] .== "Republican"]) -
                   sum(df[:Popular_Vote][df[:Party] .== "Democratic"])) /
                   sum(df[:Popular_Total])*100,
               Error =
                  std((df[:Popular_Vote][df[:Party] .== "Republican"] -
                       df[:Popular_Vote][df[:Party] .== "Democratic"]) ./
                      (df[:Popular_Total][df[:Party] .== "Republican"] +
                       df[:Popular_Total][df[:Party] .== "Democratic"]),
                      weights(
                          df[:Popular_Total][df[:Party] .== "Republican"] +
                          df[:Popular_Total][df[:Party] .== "Democratic"])
                      ).* 100 ) )

p = plot(bi_region_diff, x=:Year, y=:Difference, Geom.point, Geom.line,
         color=:Region, Coord.Cartesian(xmin=firstyear, xmax=lastyear),
         Guide.title("Republican - Democratic Popular Vote (%) by Region"),
         Guide.ylabel("Difference (%)"), Guide.xlabel("Year"),
        Guide.xticks(ticks=xticks), 
      Geom.ribbon, 
      ymin=bi_region_diff[:Difference] - bi_region_diff[:Error],
      ymax=bi_region_diff[:Difference] + bi_region_diff[:Error],
         style(major_label_font_size=24px, key_title_font_size=24px,
               minor_label_font_size=18px, key_label_font_size=18px,
              line_width=2px,
              grid_line_width=1px,
               key_position=:bottom, key_max_columns=10))
draw(SVG(string("plots/bi_diff_all_regions.svg"), 32cm, 16cm), p)


################################################################################
# all divisions over time.
################################################################################

bi_division_diff =
  by( bi_state_data_1860, [:Year, :Division],
      df -> DataFrame(
               Difference =
                  (sum(df[:Popular_Vote][df[:Party] .== "Republican"]) -
                   sum(df[:Popular_Vote][df[:Party] .== "Democratic"])) /
                  sum(df[:Popular_Total])*100,
               Error =
                  std((df[:Popular_Vote][df[:Party] .== "Republican"] -
                       df[:Popular_Vote][df[:Party] .== "Democratic"]) ./
                      (df[:Popular_Total][df[:Party] .== "Republican"] +
                       df[:Popular_Total][df[:Party] .== "Democratic"]),
                  weights(
                     df[:Popular_Total][df[:Party] .== "Republican"] +
                     df[:Popular_Total][df[:Party] .== "Democratic"])
               ).* 100 ) )

p = plot(bi_division_diff, x=:Year, y=:Difference, Geom.point, Geom.line,
         color=:Division, Coord.Cartesian(xmin=firstyear, xmax=lastyear),
         Guide.title("Republican - Democratic Popular Vote (%) by Division"),
         Guide.ylabel("Difference (%)"), Guide.xlabel("Year"),
      Geom.ribbon, 
      ymin=bi_division_diff[:Difference] - bi_division_diff[:Error],
      ymax=bi_division_diff[:Difference] + bi_division_diff[:Error],
        Guide.xticks(ticks=xticks), 
         style(major_label_font_size=24px, key_title_font_size=24px,
               minor_label_font_size=18px, key_label_font_size=18px,
              line_width=2px,
              grid_line_width=1px,
               key_position=:bottom, key_max_columns=10))
draw(SVG(string("plots/bi_diff_all_divisions.svg"), 32cm, 16cm), p)


################################################################################
# cluster all states by popular vote over time.
################################################################################

#pca_frame = unstack(stack(bi_state_diff, :Year), :value, :State, :Difference)
#bi_state_diff = by( bi_state_diff, [:State, :Region, :Division],
#                df -> DataFrame(Difference = df[:Difference] - mean(df[:Difference])) )

pca_frame = DataFrame()
pca_frame[:Year] = collect(1860:4:2012)
for state in groupby(bi_state_diff, :State)
  pca_frame = join(pca_frame, state[:, [:Year, :Difference]], on=:Year, kind=:inner)
  rename!(pca_frame, :Difference, symbol(state[:State][1]))
end

# subtract means
for idx in 2:ncol(pca_frame)
  pca_frame[:,idx] = (pca_frame[:,idx] - mean(pca_frame[:,idx])) / 100
end

features = convert(Array, pca_frame[:, 2:end])
pc = fit(PCA, features; maxoutdim=3)
pca_reduced = transform(pc, features)

# plot pc1 loadings
firstyear = Int(minimum(pca_frame[:Year]))-4
lastyear = Int(maximum(pca_frame[:Year]))+4
xticks = collect(firstyear:8:lastyear)
if length(xticks) > 20
  xticks = collect(firstyear:12:lastyear)
end

p = plot(x=pca_frame[:Year], y=projection(pc)[:,1], Geom.bar,
         Guide.xlabel("Year"), Guide.ylabel("PC1 Loadings"),
         Guide.xticks(ticks=xticks),
         style(major_label_font_size=20px, key_title_font_size=20px,
               minor_label_font_size=14px, key_label_font_size=14px,
               line_width=2px,
               grid_line_width=1px,
               key_position=:bottom, key_max_columns=10))
draw(SVG("plots/bi_diff_pca_pc1_state.svg", 12cm, 8cm), p)

# plot pc1 v pc2
p = plot(bi_state_diff, x=pca_reduced[1,:], y=pca_reduced[2,:],
         color=bi_state_diff[:Region][bi_state_diff[:Year] .== 2000],
         Geom.point,
         label=bi_state_diff[:State][bi_state_diff[:Year] .== 2000],
         Geom.label(position=:dynamic, hide_overlaps=true),
         Guide.xlabel("PC1"), Guide.ylabel("PC2"),
         Guide.title("PCA of States"),
         style(major_label_font_size=24px, key_title_font_size=24px,
               minor_label_font_size=18px, key_label_font_size=18px,
          point_label_font_size=13px,
               line_width=2px,
               grid_line_width=1px,
               key_position=:bottom, key_max_columns=10))
draw(SVG("plots/bi_diff_pca_state.svg", 20cm, 16cm), p)

# k-means
pc_kmeans = kmeans(pca_reduced, 4)
p = plot(bi_state_diff, x=pca_reduced[1,:], y=pca_reduced[2,:],
         color=[ string(group) for group in  pc_kmeans.assignments ],
         Geom.point,
         label=bi_state_diff[:Region][bi_state_diff[:Year] .== 2000],
         Geom.label(position=:dynamic,hide_overlaps=true),
         Guide.xlabel("PC1"), Guide.ylabel("PC2"),
         Guide.title("k-means Clustering of State PCA"),
         style(major_label_font_size=24px, key_title_font_size=24px,
               minor_label_font_size=18px, key_label_font_size=18px,
          point_label_font_size=13px,
               line_width=2px,
               grid_line_width=1px,
               key_position=:bottom, key_max_columns=10))
draw(SVG("plots/bi_diff_pca_kmeans_state.svg", 20cm, 16cm), p)

# dbscan
pc_dbscan = dbscan(pairwise(SqEuclidean(), pca_reduced), 150, 2)
p = plot(bi_state_diff, x=pca_reduced[1,:], y=pca_reduced[2,:],
         color=pc_dbscan.assignments,
         color=[ string(group) for group in  pc_dbscan.assignments ],
         Geom.point,
         label=bi_state_diff[:Region][bi_state_diff[:Year] .== 2000],
         Geom.label(position=:dynamic,hide_overlaps=true),
         Guide.xlabel("PC1"), Guide.ylabel("PC2"),
         Guide.title("DBSCAN Clustering of State PCA"),
         style(major_label_font_size=24px, key_title_font_size=24px,
               minor_label_font_size=18px, key_label_font_size=18px,
               line_width=2px,
               grid_line_width=1px,
               key_max_columns=10))


################################################################################
# cluster most states by popular vote over time.
################################################################################

bi_some_diff = bi_state_diff

# drop some states
bi_some_diff = bi_some_diff[bi_some_diff[:State] .!= "D. C.", :]
bi_some_diff = bi_some_diff[bi_some_diff[:State] .!= "Hawaii", :]
bi_some_diff = bi_some_diff[bi_some_diff[:State] .!= "Alaska", :]

#pca_frame = unstack(stack(bi_some_diff, :Year), :value, :State, :Difference)
#bi_some_diff = by( bi_some_diff, [:State, :Region, :Division],
#                df -> DataFrame(Difference = df[:Difference] - mean(df[:Difference])) )

pca_frame = DataFrame()
pca_frame[:Year] = collect(1860:4:2012)
for state in groupby(bi_some_diff, :State)
  pca_frame = join(pca_frame, state[:, [:Year, :Difference]], on=:Year, kind=:inner)
  rename!(pca_frame, :Difference, symbol(state[:State][1]))
end

# subtract means
for idx in 2:ncol(pca_frame)
  pca_frame[:,idx] = (pca_frame[:,idx] - mean(pca_frame[:,idx])) / 100
end

features = convert(Array, pca_frame[:, 2:end])
pc = fit(PCA, features; maxoutdim=3)
pca_reduced = transform(pc, features)

# plot pc1 loadings
firstyear = Int(minimum(pca_frame[:Year]))-4
lastyear = Int(maximum(pca_frame[:Year]))+4
xticks = collect(firstyear:8:lastyear)
if length(xticks) > 20
  xticks = collect(firstyear:12:lastyear)
end

p = plot(x=pca_frame[:Year], y=projection(pc)[:,1], Geom.bar,
         Guide.xlabel("Year"), Guide.ylabel("PC1 Loadings"),
         Guide.xticks(ticks=xticks),
         style(major_label_font_size=20px, key_title_font_size=20px,
               minor_label_font_size=14px, key_label_font_size=14px,
               line_width=2px,
               grid_line_width=1px,
               key_position=:bottom, key_max_columns=10))
draw(SVG("plots/bi_diff_pca_pc1_some_state.svg", 12cm, 8cm), p)

# plot pc1 v pc2
p = plot(bi_some_diff, x=pca_reduced[1,:], y=pca_reduced[2,:],
         color=bi_some_diff[:Region][bi_some_diff[:Year] .== 2000],
         Geom.point,
         label=bi_some_diff[:State][bi_some_diff[:Year] .== 2000],
         Geom.label(position=:dynamic, hide_overlaps=true),
         Guide.xlabel("PC1"), Guide.ylabel("PC2"),
         Guide.title("PCA of States"),
         style(major_label_font_size=24px, key_title_font_size=24px,
               minor_label_font_size=18px, key_label_font_size=18px,
          point_label_font_size=13px,
               line_width=2px,
               grid_line_width=1px,
               key_position=:bottom, key_max_columns=10))
draw(SVG("plots/bi_diff_pca_some_state.svg", 20cm, 16cm), p)

# k-means
pc_kmeans = kmeans(pca_reduced, 4)
p = plot(bi_some_diff, x=pca_reduced[1,:], y=pca_reduced[2,:],
         color=[ string(group) for group in  pc_kmeans.assignments ],
         Geom.point,
         label=bi_some_diff[:Region][bi_some_diff[:Year] .== 2000],
         Geom.label(position=:dynamic,hide_overlaps=true),
         Guide.xlabel("PC1"), Guide.ylabel("PC2"),
         Guide.title("k-means Clustering of State PCA"),
         style(major_label_font_size=24px, key_title_font_size=24px,
               minor_label_font_size=18px, key_label_font_size=18px,
          point_label_font_size=13px,
               line_width=2px,
               grid_line_width=1px,
               key_position=:bottom, key_max_columns=10))
draw(SVG("plots/bi_diff_pca_kmeans_some_state.svg", 20cm, 16cm), p)

# dbscan
pc_dbscan = dbscan(pairwise(SqEuclidean(), pca_reduced), .1, 2)
p = plot(bi_some_diff, x=pca_reduced[1,:], y=pca_reduced[2,:],
         color=pc_dbscan.assignments,
         color=[ string(group) for group in  pc_dbscan.assignments ],
         Geom.point,
         label=bi_some_diff[:Region][bi_some_diff[:Year] .== 2000],
         Geom.label(position=:dynamic,hide_overlaps=true),
         Guide.xlabel("PC1"), Guide.ylabel("PC2"),
         Guide.title("DBSCAN Clustering of State PCA"),
         style(major_label_font_size=24px, key_title_font_size=24px,
               minor_label_font_size=18px, key_label_font_size=18px,
               line_width=2px,
               grid_line_width=1px,
               key_max_columns=10))


################################################################################
# cluster each election.
################################################################################

#pc2 = fit(PCA, features'; maxoutdim=3)
#pca_reduced2 = transform(pc2, features')

#p = plot(bi_state_diff, x=pca_reduced2[1,:], y=pca_reduced2[2,:],
#         color=[ string(year) for year in pca_frame[:Year] ], Geom.point,
#         label=[ string(year) for year in pca_frame[:Year] ],
#         Geom.label(position=:dynamic, hide_overlaps=false),
#         style(major_label_font_size=24px, key_title_font_size=24px,
#               minor_label_font_size=18px, key_label_font_size=18px,
#              line_width=2px,
#              grid_line_width=1px,
#          key_position=:none, key_max_columns=10))
