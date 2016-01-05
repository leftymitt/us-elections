#! /bin/env python

# you need to install beautifulsoup and pandas
from bs4 import BeautifulSoup
import pandas as pd


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
    header = [ 'State', 'PresidentialCandidate', 'Electoral Vote', 'Popular Vote', 'Year' ]
    frame = pd.DataFrame(columns=header)
    num_candidates = (len([ td.get_text() for td in data[0].find_all("td") ][1:])-3)//2
    candidates = [ td.get_text() for td in data[0].find_all("td") ][1+num_candidates+2:]
    for row in range(0, len(data[1].find_all("tr"))-1):
        row = [ td.get_text().strip('\xa0') for td in data[1].find_all("tr")[row].find_all("td") ][1:]
        for idx in range(0, num_candidates):
            content = [ row[0], candidates[idx], row[1+idx], row[2+num_candidates+idx], year]
            frame = frame.append(pd.Series(content, header), ignore_index=True)
        content = [ row[0], candidates[num_candidates], '0', row[len(row)-1], year ]
        frame = frame.append(pd.Series(content, header), ignore_index=True)
    return frame


national_frame = pd.DataFrame;
state_frame = pd.DataFrame;
for year in range(1824, 2016, 4):
#    print(year)
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

#print(national_frame)
#print(state_frame)
national_frame.to_csv('data/national_data.txt', sep='\t', index=False)
state_frame.to_csv('data/state_data.txt', sep='\t', index=False)

#########################

#year = 1824
#file = open("raw_data/national_results_" + str(year) + ".html", "r")
#file = open("raw_data/state_results_" + str(year) + ".html", "r")
#soup = BeautifulSoup(file, 'html.parser')
#national_html = [ soup.find_all("thead")[0], soup.find_all("tbody")[0] ]
#get_national_data(national_html, year)
#state_html = soup.find_all("table", attrs={"class":"elections_states"})[1]
#file.close()
