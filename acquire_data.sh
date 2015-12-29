#! /bin/bash

BASEURL="http://www.presidency.ucsb.edu/showelection.php?year="

for YEAR in $(seq 1796 4 2012); do
	torify wget "$BASEURL""$YEAR" -O raw_data/results_$YEAR.html
	sed -i "s///g" raw_data/results_$YEAR.html
done
