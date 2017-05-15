#! /bin/env python

# you need to install beautifulsoup and pandas
from bs4 import BeautifulSoup
import pandas as pd
import re


def get_national_data(data, year):
    header = [ th.get_text().strip('\xa0')for th in data[0].find_all("th") ][1:6]
    header.append("Year")
    frame = pd.DataFrame(columns=header)
    for row in range(0, len(data[1].find_all("tr"))-1):
        content = [ td.get_text().strip('\xa0') for td in data[1].find_all("tr")[row].find_all("td") ][1:8]
        content.pop(-1)
        content.pop(-2)
        content.append(year)
        frame = frame.append(pd.Series(content, header), ignore_index=True)
    return frame


def get_state_data(data, year):
    fields = [ 'State', 'PresidentialCandidate', 'Electoral Vote', 'Popular Vote', 'Year' ]
    frame = pd.DataFrame(columns=fields)
    header = [ td.get_text() for td in data[0].find_all("td") ][1:]
    header_midpoint = header.index('Total\xa0Vote')+1
    num_candidates = len(header[header_midpoint:])
    candidates = header[header_midpoint:]
    num_ev = len(header[1:header_midpoint-1])
    for row in range(0, len(data[1].find_all("tr"))):
        row = [ td.get_text().strip('\xa0') for td in data[1].find_all("tr")[row].find_all("td") ][1:]
        for idx, candidate in enumerate(candidates):
            if idx < num_ev:
                content = [ row[0], candidate, row[1+idx], row[2+num_ev+idx], year]
            else:
                content = [ row[0], candidate, '0', row[2+num_ev+idx], year]
            frame = frame.append(pd.Series(content, fields), ignore_index=True)
    return frame


# add full candidate name and the political party
def fix_data(national, state):
    candidate = []
    party = []
    years = sorted(set(state['Year']))
    for year in years:
        for name in state['PresidentialCandidate'][state['Year'] == year]:
            full_names = national['PresidentialCandidate'][national['Year'] == year]
            test = [ full_name for full_name in full_names if re.search(name, full_name) ]
            if test:
                candidate.append(test[0])
                party.append(national['PoliticalParty'][full_names[full_names == test[0]].index[0]])
            else:
                candidate.append(name)
                party.append('-')
    state['PresidentialCandidate'] = pd.Series(candidate)
    state['PoliticalParty'] = pd.Series(party)

# clean up data
national_frame = pd.DataFrame;
state_frame = pd.DataFrame;
for year in range(1824, 2016, 4):
    print("processing election:", year)
    file = open("raw_data/national_results_" + str(year) + ".html", "r")
    soup = BeautifulSoup(file, 'html.parser')
    national_html = [ soup.find_all("thead")[0], soup.find_all("tbody")[0] ]
    file.close()
    file = open("raw_data/state_results_" + str(year) + ".html", "r")
    soup = BeautifulSoup(file, 'html.parser')
    state_html = [ soup.find_all("thead")[0], soup.find_all("tbody")[0] ]
    file.close()
    if national_frame.empty:
        national_frame = get_national_data(national_html, year)
    else:
        try:
            national_frame = national_frame.append(get_national_data(national_html, year), ignore_index=True)
        except ValueError:
            print("Error: ", year)
    if state_frame.empty:
        state_frame = get_state_data(state_html, year)
    else:
        try:
            state_frame = state_frame.append(get_state_data(state_html, year), ignore_index=True)
        except ValueError:
            print("Error: ", year)

print("cleaning up...")
fix_data(national_frame, state_frame)

#print(national_frame)
#print(state_frame)
national_frame.to_csv('data/national_data.txt', sep='\t', index=False)
state_frame.to_csv('data/state_data.txt', sep='\t', index=False)
