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
    icecast_categories = generate_radiodata_categories()
    
    # Read current radiodata.js to find where to insert
    with open('radcapradio/contents/ui/radiodata.js', 'r') as f:
        content = f.read()
    
    # Find the section to replace - from first ICECAST to last ICECAST category
    start_marker = '    {\n        "name": "ROCK",'
    end_marker = '    },\n    {\n        "name": "ETHNIC / FOLK / SPIRITUAL",'
    
    start_idx = content.find(start_marker)
    end_idx = content.find(end_marker)
    
    if start_idx != -1 and end_idx != -1:
        # Replace the section
        new_content = (
            content[:start_idx] + 
            icecast_categories + 
            ',\n    {\n        "name": "ETHNIC / FOLK / SPIRITUAL",' +
            content[end_idx + len('    },\n    {\n        "name": "ETHNIC / FOLK / SPIRITUAL",'):]
        )
        
        # Write back to file
        with open('radcapradio/contents/ui/radiodata.js', 'w') as f:
            f.write(new_content)
        
        print(f"Updated radiodata.js with {len(json.load(open('icecast_popular_genres.json')))} Icecast categories")
    else:
        print("Could not find insertion point in radiodata.js")

if __name__ == '__main__':
    main()