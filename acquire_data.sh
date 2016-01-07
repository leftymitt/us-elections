#! /bin/bash

################################################################################
# define global variables and functions.
################################################################################
BASE_URL="http://uselectionatlas.org"
START_YEAR=1824
STOP_YEAR=2012

# wait between 5 and 30 seconds.
wait_a_bit () {
	sleep $[ ( $RANDOM % 25 ) + 5 ]s
}

################################################################################
# download data.
################################################################################
for YEAR in $(seq $START_YEAR 4 $STOP_YEAR); do
	NATIONAL_URL="${BASE_URL}/RESULTS/national.php?year=${YEAR}&off=0&f=1"
	STATE_URL="${BASE_URL}/RESULTS/data.php?ev=1&vot=1&sort=&fips=0&search=&search_name=&datatype=national&f=0&off=0&year=${YEAR}&sort_dir=&submit=Submit"
	curl "$NATIONAL_URL" -o raw_data/national_results_${YEAR}.html
	wait_a_bit
	curl "$STATE_URL" -o raw_data/state_results_${YEAR}.html
	wait_a_bit
done
