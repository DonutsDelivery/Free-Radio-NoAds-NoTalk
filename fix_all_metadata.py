#!/usr/bin/env python3

import json
import requests
import time
import re
from concurrent.futures import ThreadPoolExecutor, as_completed

def test_metadata_url(url, timeout=8):
    """Test if a URL returns valid metadata"""
    try:
        response = requests.get(url, timeout=timeout, headers={
            'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36'
        })
        if response.status_code == 200:
            content = response.text.lower()
            
            # Skip 404 pages even if they return 200 status
            if any(error_text in content for error_text in [
                'запрашиваемая страница на сайте отсутствует', 
                '404', 'not found', 'page not found'
            ]):
                return False, "404 page"
            
            # Check for actual playback history content
            if any(keyword in content for keyword in [
                '<td>', 'playback', 'history', 'current song', 'artist', 'title',
                'radcap', 'channel:', 'now playing'
            ]) and 'html' in content:
                return True, response.text[:200]
                
        return False, f"Status: {response.status_code}"
    except Exception as e:
        return False, str(e)

def generate_path_variations(original_path):
    """Generate possible path variations for a station"""
    variations = [original_path]
    
    # Common path transformations based on working stations
    transformations = {
        'musicgame': 'gamemusic',
        'indianfolk': 'indian',
        'nativeamerican': 'natam',
        'slavonicneofolk': 'slavonic',
        'popballads': 'popball',
        'classpiano': 'classicalpiano',
        'mainstreamjazz': 'jazz',
        'jazzfusion': 'fusion',
        'mcreative': 'moderncreative',
        'ecmrecords': 'ecm',
        'trumpetjazz': 'trumpet',
        'bardru': 'bard',
        'frenchchanson': 'chanson',
        'tradpop': 'pop',
        'cantopop': 'cpop',
        'experimentalmusic': 'experimental',
        'soundnat': 'soundsnat',
        'femalemetal': 'female',
        'harpblues': 'harp',
        'louisianablues': 'louisiana',
        'memphisrap': 'memphis',
        'undergroundrap': 'underground',
        'ukhiphop': 'uk',
        'westcoastblues': 'westcoast',
        'westernswing': 'swing',
        'visualkei': 'visual'
    }
    
    # Add specific transformation if available
    if original_path in transformations:
        variations.append(transformations[original_path])
    
    # Add shortened versions
    if len(original_path) > 8:
        variations.append(original_path[:8])
        variations.append(original_path[:6])
    
    # Add common suffixes/prefixes
    if 'music' in original_path:
        variations.append(original_path.replace('music', ''))
    if 'jazz' in original_path and original_path != 'jazz':
        variations.append(original_path.replace('jazz', ''))
    if 'rock' in original_path and original_path != 'rock':
        variations.append(original_path.replace('rock', ''))
    if 'pop' in original_path and original_path != 'pop':
        variations.append(original_path.replace('pop', ''))
    
    # Remove duplicates while preserving order
    unique_variations = []
    for var in variations:
        if var and var not in unique_variations:
            unique_variations.append(var)
    
    return unique_variations

def test_station_thoroughly(station_name, station_path):
    """Test all possible metadata URLs for a station"""
    print(f"\nTesting: {station_name} (path: {station_path})")
    
    path_variations = generate_path_variations(station_path)
    path_numbers = [1, 2, 3, 4, 5, 6, 7]
    
    for variation in path_variations:
        if variation != station_path:
            print(f"  Trying variation: {variation}")
        
        for path_num in path_numbers:
            url = f"http://radcap.ru/playback-history/{path_num}/{variation}-ph.php"
            success, content = test_metadata_url(url)
            
            if success:
                print(f"  ✓ SUCCESS: Path {path_num}, variation '{variation}'")
                print(f"    URL: {url}")
                return True, {
                    'url': url,
                    'path_number': path_num,
                    'variation': variation,
                    'content_preview': content
                }
            
            time.sleep(0.2)  # Rate limiting
    
    print(f"  ✗ FAILED: No working metadata URL found")
    return False, None

def get_failed_stations():
    """Load failed stations from test results"""
    with open('station_metadata_test_results.json', 'r') as f:
        data = json.load(f)
    
    failed_stations = []
    for station in data.get('failed', []):
        if station.get('status') == 'failed':
            failed_stations.append(station)
    
    return failed_stations

def main():
    print("Loading failed stations...")
    failed_stations = get_failed_stations()
    
    if not failed_stations:
        print("No failed stations found!")
        return
    
    print(f"Found {len(failed_stations)} failed stations")
    print("Starting comprehensive metadata URL testing...")
    print("=" * 80)
    
    fixes = []
    still_failed = []
    
    # Test each failed station
    for i, station in enumerate(failed_stations):
        station_name = station.get('station', 'Unknown')
        station_path = station.get('path', '')
        
        print(f"\n[{i+1}/{len(failed_stations)}] Progress: {(i+1)/len(failed_stations)*100:.1f}%")
        
        if station_path:
            success, result = test_station_thoroughly(station_name, station_path)
            
            if success:
                fix = {
                    'station': station_name,
                    'path': station_path,
                    'category': station.get('category'),
                    'working_url': result['url'],
                    'path_number': result['path_number'],
                    'variation': result['variation'],
                    'content_preview': result['content_preview']
                }
                fixes.append(fix)
            else:
                still_failed.append(station)
        else:
            print(f"  ✗ No path available for {station_name}")
            still_failed.append(station)
    
    # Save results
    print("\n" + "=" * 80)
    print("COMPREHENSIVE TEST RESULTS")
    print("=" * 80)
    
    if fixes:
        with open('comprehensive_metadata_fixes.json', 'w') as f:
            json.dump(fixes, f, indent=2)
        
        print(f"\n✅ FIXED STATIONS ({len(fixes)}):")
        for fix in fixes:
            variation_note = f" (using '{fix['variation']}')" if fix['variation'] != fix['path'] else ""
            print(f"  • {fix['station']}: Path {fix['path_number']}{variation_note}")
    
    if still_failed:
        print(f"\n❌ STILL FAILED ({len(still_failed)}):")
        for station in still_failed:
            print(f"  • {station.get('station', 'Unknown')} (path: {station.get('path', 'Unknown')})")
    
    print(f"\n📊 SUMMARY:")
    print(f"  • Fixed: {len(fixes)}")
    print(f"  • Still failing: {len(still_failed)}")
    print(f"  • Success rate: {len(fixes)}/{len(failed_stations)} ({len(fixes)/len(failed_stations)*100:.1f}%)")
    
    if fixes:
        print(f"\n💾 Fixes saved to: comprehensive_metadata_fixes.json")

if __name__ == "__main__":
    main()