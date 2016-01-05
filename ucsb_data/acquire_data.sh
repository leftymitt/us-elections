#! /bin/bash

BASEURL="http://www.presidency.ucsb.edu/showelection.php?year="

for YEAR in $(seq 1824 4 2012); do
	torify wget "$BASEURL""$YEAR" -O raw_data/results_$YEAR.html
	sed -i "s/
done