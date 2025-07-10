#!/usr/bin/env python3
"""
Test specific stations with their naming variations.
"""

import requests
import re

def test_with_variations(station_name, original_path, variations):
    """Test a station with its naming variations"""
    print(f"\n--- Testing: {station_name} ---")
    print(f"Original path: {original_path}")
    print(f"Variations: {variations}")
    
    # Test all variations
    for variation in variations:
        # Try station page method first
        try:
            station_url = f"http://radcap.ru/{variation}.html"
            response = requests.get(station_url, timeout=5)
            if response.status_code == 200:
                # Look for playback-html class link
                match = re.search(r'class="playback-html"[^>]*>\s*<a\s+href="([^"]+)"', response.text, re.IGNORECASE)
                if match:
                    playback_path = match.group(1)
                    playback_url = f"http://radcap.ru/{playback_path}"
                    
                    pb_response = requests.get(playback_url, timeout=5)
                    if pb_response.status_code == 200:
                        patterns = [
                            r'<td>([^<]+)<td><b>Current Song</b></td>',
                            r'<td>([^<]+)</td><td><b>Current Song</b></td>',
                            r'<td>\d{2}:\d{2}:\d{2}</td><td>([^<]+)(?:<td>|</td>)'
                        ]
                        
                        for pattern in patterns:
                            song_match = re.search(pattern, pb_response.text, re.IGNORECASE)
                            if song_match:
                                song_info = song_match.group(1).strip()
                                if song_info:
                                    print(f"  ✅ SUCCESS via station page ({variation}.html): {song_info}")
                                    return True
        except:
            pass
        
        # Try direct playback history
        for path_num in [2, 3, 4, 1, 5, 6]:
            try:
                url = f"http://radcap.ru/playback-history/{path_num}/{variation}-ph.php"
                response = requests.get(url, timeout=5)
                if response.status_code == 200:
                    patterns = [
                        r'<td>([^<]+)<td><b>Current Song</b></td>',
                        r'<td>([^<]+)</td><td><b>Current Song</b></td>',
                        r'<td>\d{2}:\d{2}:\d{2}</td><td>([^<]+)(?:<td>|</td>)'
                    ]
                    
                    for pattern in patterns:
                        match = re.search(pattern, response.text, re.IGNORECASE)
                        if match:
                            song_info = match.group(1).strip()
                            if song_info:
                                print(f"  ✅ SUCCESS via playback history ({variation}, path {path_num}): {song_info}")
                                return True
            except:
                continue
    
    print(f"  ❌ FAILED - No working variation found")
    return False

def main():
    # Test problematic stations with their variations
    test_cases = [
        ("Classical Piano", "classpiano", ["classpiano", "classicalpiano"]),
        ("Indian Folk", "indianfolk", ["indianfolk", "indian", "indianclassical"]),
        ("Native American", "nativeamerican", ["nativeamerican", "natam"]),
        ("Celtic Rock", "celticrock", ["celticrock", "celtic"]),
        ("Jazz", "jazz", ["jazz"]),
        ("Blues", "blues", ["blues"]),
        ("Classical", "classical", ["classical"]),
        ("Electronic", "electronic", ["electronic"]),
        ("Rock", "rock", ["rock"]),
        ("Pop", "pop", ["pop"]),
        ("Metal", "metal", ["metal"])
    ]
    
    print("🔍 Testing Stations with Naming Variations 🔍")
    print("=" * 50)
    
    success_count = 0
    for station_name, original_path, variations in test_cases:
        if test_with_variations(station_name, original_path, variations):
            success_count += 1
    
    print(f"\n📊 Results: {success_count}/{len(test_cases)} successful")

if __name__ == "__main__":
    main()