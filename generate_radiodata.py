#!/usr/bin/env python3
import json

def generate_radiodata_categories():
    # Load popular genres
    with open('icecast_popular_genres.json', 'r') as f:
        genres = json.load(f)
    
    # Generate JavaScript format
    js_categories = []
    
    for genre in genres:
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