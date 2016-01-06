#! /bin/bash

# dave won't like this. your ip address might get blocked if you run this script. 

BASE_URL="http://uselectionatlas.org"

for YEAR in $(seq 1824 4 2012); do
	NATIONAL_URL="${BASE_URL}/RESULTS/national.php?year=${YEAR}&off=0&f=1"
	STATE_URL="${BASE_URL}/RESULTS/data.php?ev=1&vot=1&sort=&fips=0&search=&search_name=&datatype=national&f=0&off=0&year=${YEAR}&sort_dir=&submit=Submit"
	curl "$NATIONAL_URL" -o raw_data/national_results_${YEAR}.html
	curl "$STATE_URL" -o raw_data/state_results_${YEAR}.html
done
