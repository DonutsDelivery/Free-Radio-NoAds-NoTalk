#!/usr/bin/env python3
import json

# Most popular music genres to include
POPULAR_GENRES = [
    "ROCK", "POP", "JAZZ", "COUNTRY", "ELECTRONIC", "DANCE", "HIP HOP", "R&B", 
    "CLASSICAL", "METAL", "ALTERNATIVE", "REGGAE", "BLUES", "FUNK", "TECHNO", 
    "HOUSE", "TRANCE", "AMBIENT", "FOLK", "LATIN", "OLDIES", "PUNK", "INDIE", 
    "SOUL", "GOSPEL", "DISCO", "NEW WAVE", "CHILLOUT", "EXPERIMENTAL", "WORLD",
    "CHRISTIAN", "CHRISTMAS", "INSTRUMENTAL", "ACOUSTIC", "NEWS", "TALK", 
    "80S", "90S", "70S", "60S", "2000S", "ADULT CONTEMPORARY", "CLASSIC ROCK",
    "SMOOTH JAZZ", "EASY LISTENING", "LOUNGE", "EDM", "CLUB", "BREAKBEAT",
    "HARDSTYLE", "ELECTRONICA", "PROGRESSIVE", "CHILL", "LO-FI", "BOLLYWOOD",
    "FILIPINO", "GREEK", "WORSHIP", "VARIETY", "MIX"
]

def filter_genres():
    # Load the scraped genres
    with open('icecast_genres.json', 'r') as f:
        all_genres = json.load(f)
    
    # Filter to popular ones
    popular_genres = []
    found_names = set()
    
    for genre in all_genres:
        # Normalize genre name for comparison
        genre_name = genre['name'].upper().strip()
        
        # Check if it's in our popular list and not already added
        if genre_name in POPULAR_GENRES and genre_name not in found_names:
            popular_genres.append(genre)
            found_names.add(genre_name)
    
    print(f"Filtered from {len(all_genres)} to {len(popular_genres)} popular genres")
    
    # Save filtered version
    with open('icecast_popular_genres.json', 'w') as f:
        json.dump(popular_genres, f, indent=2)
    
    print("Popular genres:")
    for i, genre in enumerate(popular_genres):
        print(f"  {i+1:2d}. {genre['name']}")

if __name__ == '__main__':
    filter_genres()