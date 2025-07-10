#!/usr/bin/env python3
"""
Create a comprehensive mapping of station paths to HTML file names.
"""

import json
import os
import re
from difflib import get_close_matches

def load_stations():
    """Load all station paths from the JSON data"""
    try:
        with open('/home/user/Documents/Free-Radio-NoAds-NoTalk/radcap channels/full_named_streams.json', 'r') as f:
            stations_data = json.load(f)
            
        station_paths = []
        for station in stations_data:
            if 'url' in station:
                url = station['url']
                parts = url.split('/')
                if len(parts) >= 4:
                    path = parts[3]  # Extract station path
                    station_paths.append(path)
        
        return list(set(station_paths))  # Remove duplicates
    except Exception as e:
        print(f"Error loading stations: {e}")
        return []

def get_html_files():
    """Get all HTML files from the radcap.ru directory"""
    try:
        html_dir = "/home/user/Documents/Free-Radio-NoAds-NoTalk/radcap channels/radcap.ru/"
        files = os.listdir(html_dir)
        
        # Filter .html files (exclude -m.html mobile versions)
        html_files = []
        for f in files:
            if f.endswith('.html') and not f.endswith('-m.html') and not f.endswith('-d.html'):
                html_files.append(f.replace('.html', ''))
        
        return html_files
    except Exception as e:
        print(f"Error loading HTML files: {e}")
        return []

def create_smart_mapping(station_paths, html_files):
    """Create smart mapping between station paths and HTML files"""
    mapping = {}
    
    for path in station_paths:
        # Direct match first
        if path in html_files:
            mapping[path] = [path]
            continue
        
        # Find close matches
        close_matches = get_close_matches(path, html_files, n=3, cutoff=0.6)
        
        # Manual patterns for known mappings
        variations = []
        
        # Known specific mappings
        known_mappings = {
            'classpiano': ['classicalpiano'],
            'indianfolk': ['indian'],
            'nativeamerican': ['natam'],
            'symphorock': ['symphonic'],
            'folkrockru': ['folkrockru'],
            'laika': ['laiko'],  # Fix for laiko/Greek music
            'salsa': ['latin'],
            'freestyle': ['fareast'],
        }
        
        if path in known_mappings:
            variations.extend(known_mappings[path])
        
        # Add close matches
        variations.extend(close_matches)
        
        # Pattern-based variations
        if path.endswith('folk'):
            base = path.replace('folk', '')
            if base and base in html_files:
                variations.append(base)
        
        if path.endswith('rock'):
            base = path.replace('rock', '')
            if base and base in html_files:
                variations.append(base)
                
        if path.endswith('jazz'):
            base = path.replace('jazz', '')
            if base and base in html_files:
                variations.append(base)
        
        if path.endswith('metal'):
            base = path.replace('metal', '')
            if base and base in html_files:
                variations.append(base)
        
        # Try with -d suffix
        if path + '-d' in html_files:
            variations.append(path + '-d')
        
        # Remove duplicates and original path
        variations = list(set(variations))
        if path in variations:
            variations.remove(path)
        
        # Add original path first
        mapping[path] = [path] + variations
    
    return mapping

def generate_qml_code(mapping):
    """Generate QML code for the mapping"""
    qml_conditions = []
    
    for path, variations in mapping.items():
        if len(variations) > 1:  # Only include if there are variations
            variations_str = ', '.join([f'"{v}"' for v in variations[1:]])  # Skip first (original)
            qml_conditions.append(f'        }} else if (stationPath === "{path}") {{')
            qml_conditions.append(f'            possibleNames.push({variations_str})')
    
    return '\n'.join(qml_conditions)

def main():
    print("🗺️  Creating comprehensive station to HTML mapping")
    print("=" * 60)
    
    # Load data
    station_paths = load_stations()
    html_files = get_html_files()
    
    print(f"Found {len(station_paths)} station paths")
    print(f"Found {len(html_files)} HTML files")
    
    # Create mapping
    mapping = create_smart_mapping(station_paths, html_files)
    
    # Show results
    print("\n📋 Station to HTML Mapping:")
    print("-" * 40)
    
    for path, variations in sorted(mapping.items()):
        if len(variations) > 1:
            print(f"{path} → {variations[1:]}")
    
    # Generate QML code
    print("\n🔧 QML Code to add to widget:")
    print("-" * 40)
    print(generate_qml_code(mapping))
    
    # Save mapping
    with open('station_html_mapping.json', 'w') as f:
        json.dump(mapping, f, indent=2)
    
    print(f"\n💾 Full mapping saved to: station_html_mapping.json")
    
    # Count statistics
    total_with_variations = sum(1 for v in mapping.values() if len(v) > 1)
    print(f"\n📊 Statistics:")
    print(f"Stations with HTML variations: {total_with_variations}/{len(station_paths)}")
    print(f"Coverage improvement: {(total_with_variations/len(station_paths))*100:.1f}%")

if __name__ == "__main__":
    main()