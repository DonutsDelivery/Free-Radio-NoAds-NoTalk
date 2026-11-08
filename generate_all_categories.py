#!/usr/bin/env python3
import json

def organize_all_genres():
    # Load all scraped genres
    with open('icecast_genres.json', 'r') as f:
        all_genres = json.load(f)
    
    # Remove obvious duplicates and clean up
    cleaned_genres = []
    seen_names = set()
    
    for genre in all_genres:
        # Normalize name for comparison
        normalized = genre['name'].upper().strip()
        
        # Skip empty, very short, or generic names
        if (len(normalized) < 2 or 
            normalized in ['NULL', 'GENRE1', 'GENRE2', 'TOP', '40', 'OTHER', 'MUSIC', 'RADIO'] or
            normalized in seen_names):
            continue
            
        seen_names.add(normalized)
        cleaned_genres.append(genre)
    
    print(f"Cleaned from {len(all_genres)} to {len(cleaned_genres)} genres")
    
    # Group by first letter for better organization
    grouped = {}
    for genre in cleaned_genres:
        first_letter = genre['name'][0].upper()
        if first_letter.isdigit():
            first_letter = '#'  # Group numbers together
        
        if first_letter not in grouped:
            grouped[first_letter] = []
        grouped[first_letter].append(genre)
    
    # Sort within each group
    for letter in grouped:
        grouped[letter].sort(key=lambda x: x['name'])
    
    # Create organized categories
    organized_categories = []
    
    # Add letter groups in alphabetical order
    for letter in sorted(grouped.keys()):
        for genre in grouped[letter]:
            organized_categories.append(genre)
    
    # Save organized version
    with open('icecast_all_organized.json', 'w') as f:
        json.dump(organized_categories, f, indent=2)
    
    print(f"Organized {len(organized_categories)} categories by letter")
    
    # Show breakdown by letter
    print("\nBreakdown by first letter:")
    for letter in sorted(grouped.keys()):
        print(f"  {letter}: {len(grouped[letter])} categories")
    
    return organized_categories

def generate_js_categories(categories):
    """Generate JavaScript format for all categories"""
    js_categories = []
    
    for genre in categories:
        js_category = f'''    {{
        "name": "{genre['name']}",
        "stations": [
            {{ "name": "Loading...", "host": "https://dir.xiph.org", "path": "genres/{genre['url_param']}", "description": "Loading stations from Icecast Directory..." }}
        ]
    }}'''
        js_categories.append(js_category)
    
    return ',\n'.join(js_categories)

def main():
    raise SystemExit(
        "Deprecated research script: edit freeradio/catalog/radiodata.json and run "
        "python3 tools/radiodata_catalog.py generate"
    )

if __name__ == '__main__':
    main()