#!/usr/bin/env python3
import requests
import csv
from bs4 import BeautifulSoup

BASE_URL = 'https://dir.xiph.org'
OUTFILE   = 'icecast_stations.csv'

def scrape_page(page):
    url  = f'{BASE_URL}/stations/?page={page}'
    resp = requests.get(url)
    resp.raise_for_status()
    soup = BeautifulSoup(resp.text, 'html.parser')
    rows = soup.select('table.station-list tr')[1:]  # skip header
    stations = []
    for row in rows:
        cols = row.find_all('td')
        name = cols[0].get_text(strip=True)
        # href is relative, so prepend BASE_URL
        stream_url = BASE_URL + cols[1].find('a')['href']
        categories = [a.get_text(strip=True) for a in cols[2].find_all('a')]
        stations.append((name, stream_url, ",".join(categories)))
    return stations

def main():
    all_stations = []
    page = 0
    while True:
        print(f"Scraping page {page}...")
        stations = scrape_page(page)
        if not stations:
            break
        all_stations.extend(stations)
        page += 1
        if page > 100:  # Safety limit
            break

    with open(OUTFILE, 'w', newline='') as f:
        w = csv.writer(f)
        w.writerow(['name','stream_url','categories'])
        w.writerows(all_stations)
    print(f"Saved {len(all_stations)} stations to {OUTFILE}")

if __name__ == '__main__':
    main()