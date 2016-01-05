#! /bin/bash

# ucsb dataset sucks - the state-level data requires a grammatical parser. 
#BASEURL="http://www.presidency.ucsb.edu/showelection.php?year="
#
#for YEAR in $(seq 1824 4 2012); do
#	torify wget "$BASEURL""$YEAR" -O raw_data/results_$YEAR.html
#	sed -i "s///g" raw_data/results_$YEAR.html
#done

BASE_URL="http://uselectionatlas.org"
for YEAR in $(seq 1824 4 2012); do
	NATIONAL_URL="${BASE_URL}/RESULTS/national.php?year=${YEAR}&off=0&f=1"
#	STATE_URL="${BASE_URL}/RESULTS/data.php?ev=1&per=1&vot=1&sort=&fips=0&search=&search_name=&datatype=national&f=0&off=0&year=${YEAR}&sort_dir=&submit=Submit"
	STATE_URL="${BASE_URL}/RESULTS/data.php?ev=1&vot=1&sort=&fips=0&search=&search_name=&datatype=national&f=0&off=0&year=${YEAR}&sort_dir=&submit=Submit"
#	curl "$NATIONAL_URL" -o raw_data/national_results_${YEAR}.html
	curl "$STATE_URL" -o raw_data/state_results_${YEAR}.html
done
