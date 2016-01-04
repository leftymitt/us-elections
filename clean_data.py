#! /bin/env python

# you need to install beautifulsoup, numpy, and pandas
from bs4 import BeautifulSoup
import numpy as np
import pandas as pd


def get_national_data(data):
    header = [ td.get_text().strip('\xa0') for td in data.find_all("tr")[0].find_all("td") ]

    header[header.index('Nominees'):header.index('Nominees')+1] = [ td.get_text().strip('\xa0') for td in data.find_all("tr")[1].find_all("td") ]
    header.append("Year")
    while True:
        try:
            header.remove("")
        except ValueError:
            break
    frame = pd.DataFrame(columns=header)
    for row in range(2, len(data.find_all("tr"))):
        content = [ td.get_text().strip('\xa0') for td in data.find_all("tr")[row].find_all("td") ]
        content.pop(-1)
        content.pop(-2)
        content.append(year)
        # cleanup
        while True:
            try:
                content.remove("")
            except ValueError:
                break
        frame = frame.append(pd.Series(content, header), ignore_index=True)
    return frame


national_frame = pd.DataFrame;
for year in range(1824, 2016, 4):
#    print(year)
    file = open("raw_data/results_" + str(year) + ".html", "r")
    soup = BeautifulSoup(file, 'html.parser')
#    [national_html, states_html] = soup.find_all("table", attrs={"class":"elections_states"})
#    if len(soup.find_all("table", attrs={"class":"elections_states"})) == 1:
#        print("bad year: ", year)
#    else:
#        national_html = soup.find_all("table", attrs={"class":"elections_states"})[0]
    national_html = soup.find_all("table", attrs={"class":"elections_states"})[0]

    if national_html.find_all("table", attrs={"class":"elections_states"}): 
        national_html = national_html.find_all("table", attrs={"class":"elections_states"})[0]

    file.close()

    if national_frame.empty:
        national_frame = get_national_data(national_html)
    else:
        try:
            national_frame = national_frame.append(get_national_data(national_html), ignore_index=True)
        except ValueError:
            print("Error: ", year)

print(national_frame)

#########################
#year = 1820
#file = open("raw_data/results_" + str(year) + ".html", "r")
#soup = BeautifulSoup(file, 'html.parser')
#national_html = soup.find_all("table", attrs={"class":"elections_states"})[0]
#file.close()
