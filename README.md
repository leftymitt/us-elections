# u.s. elections

scripts for acquiring, aggregating, and analyizing us election data.  

requires: 

 1. python3 - pandas, beautifulsoup4 
 2. julia - gadfly, dataframes, clustering, distances, statsbase,
    multivariatestats
 3. curl  


```
$ ./acquire_data.sh
$ ./clean_data.py
$ ./plot_national_data.jl
$ ./plot_state_data.jl
```

raw data in `raw_data/`, cleaned data in `data/`, and plots in `plots/`. enjoy. 
 
