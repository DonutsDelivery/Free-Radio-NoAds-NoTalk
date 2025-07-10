#!/usr/bin/env python3
import requests
import json
from bs4 import BeautifulSoup
import urllib.parse

BASE_URL = 'https://dir.xiph.org'
OUTFILE = 'icecast_genres.json'

def scrape_genres():
    """Scrape all genre categories from the genres page"""
    url = f'{BASE_URL}/genres'
    resp = requests.get(url)
    resp.raise_for_status()
    soup = BeautifulSoup(resp.text, 'html.parser')
    
    # Find all genre links
    genre_links = soup.find_all('a', href=lambda x: x and x.startswith('/genres/'))
    
    genres = []
    seen_genres = set()  # To avoid duplicates
    
    for link in genre_links:
        genre_name = link.get_text(strip=True)
        genre_url = link.get('href')
        
        # Skip empty or duplicate genres
        if not genre_name or genre_name in seen_genres:
            continue
            
        seen_genres.add(genre_name)
        
        # Extract the genre parameter from URL like /genres/Rock
        genre_param = genre_url.split('/genres/')[-1]
        
        genres.append({
            "name": genre_name.upper(),
            "url_param": genre_param,
            "stations": [
                {
                    "name": "Loading...",
                    "host": "https://dir.xiph.org",
                    "path": f"genres/{genre_param}",
                    "description": f"Loading stations from Icecast Directory..."
                }
            ]
        })
    
    return genres

def main():
    print("Scraping Icecast genres...")
    genres = scrape_genres()
    
    print(f"Found {len(genres)} unique genres")
    
    # Save to JSON file
    with open(OUTFILE, 'w') as f:
        json.dump(genres, f, indent=2)
    
    print(f"Saved genres to {OUTFILE}")
    
    # Also print the first few for verification
    print("\nFirst 10 genres:")
    for i, genre in enumerate(genres[:10]):
        print(f"  {i+1}. {genre['name']} -> {genre['url_param']}")

if __name__ == '__main__':
    main()