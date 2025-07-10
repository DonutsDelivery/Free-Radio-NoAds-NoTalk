#!/usr/bin/env python3
"""
Fix failed RadCap stations by mapping them to correct paths
"""

import json
import requests
import re
import time
from concurrent.futures import ThreadPoolExecutor

# Mapping of failed station paths to actual RadCap paths
PATH_MAPPINGS = {
    # Collection years
    "60collection": "60s",
    "70collection": "70s", 
    "pop80": "80s",
    "90collection": "90s",
    "00collection": "00s",
    
    # Classical music
    "classpiano": "classicalpiano",
    "chorus": "choral",
    "chants": "chant",
    
    # Blues variations
    "harpblues": "harmonicablues",
    
    # Jazz variations
    "mcreative": "moderncreative",
    "mainstreamjazz": "mainstream",
    "jazzfusion": "fusion",
    "ecmrecords": "ecm",
    "trumpetjazz": "jazztrumpet",
    
    # Pop variations
    "bardru": "bard",  # Russian stations
    "popballads": "popball",
    "frenchchanson": "frchanson",
    "cpop": "chinesepop",
    "tradpop": "oldies",
    
    # Rock variations
    "shoegazing": "shoegaze",
    "rockballads": "rockball",
    "progressiverock": "progrock",
    "indiepop": "indietweepop",
    
    # Metal variations - many need truncation
    "deathdoom": "ddm",  # death doom metal
    "gothicmetal": "gothmetal",
    "symphonicblackmetal": "symphoblack",
    "instrumentalmetal": "instrmetal",
    "avantgardemetal": "avantmetal",
    "brutaldeathmetal": "brutaldeath",
    "melodicdeath": "mdm",  # melodic death metal
    "dsbm": "depressiveblack",
    "techdeathmetal": "tdm",  # technical death metal
    "melodicblackmetal": "mbm",  # melodic black metal
    "funeraldoom": "fdm",  # funeral doom metal
    "gothdoommet": "gothicdoom",
    "progheavy": "heavyprog",
    "symphodeath": "symphodeathmet",
    "symphogoth": "symphogothmet",
    "atmosphericdoom": "atmosdoom",
    "folkdeathmet": "folkdeathmetal",
    "folkblackmet": "folkblackmetal",
    
    # Electronic/Hardcore
    "screamoemo": "emoscreamo",
    "mathcore": "chaotichardcore",
    "hardcoremetal": "hardcore",
    
    # Electronic/Techno
    "vocaltrance": "dreamtrance",  # closest match
    "dubtechno": "dubtech",
    "clubdance": "club",
    "musiqueconcrete": "concrete",
    "detroittechno": "detroittech",
    "experimentaltechno": "exptechno",
    "nightpsytrance": "nightpsy",
    "mintechno": "mintech",
    "fieldrecording": "fieldrecordings",
    "electrotechno": "electrotech",
    
    # Hip-hop/Rap
    "eastcoastrap": "eastcoast",
    "germanrap": "germanhiphop",
    "frenchrap": "frenchhiphop",
    "oldschoolhiphop": "oldschhiphop",
    
    # Misc
    "experimentalmusic": "experimental",
    "musicgame": "gamemusic",
    "soundnat": "soundsnat",
    "ballroomdance": "ballroom",
    "singersongwriter": "singer",
    
    # Ethnic/Folk variations
    "nativeamerican": "natam",
    "indianfolk": "indian",
    "salsa": "latin",
    "laika": "laiko",
    "slavonicneofolk": "slavonic",
}

class FailedStationFixer:
    def __init__(self):
        self.results = {"fixed": [], "still_failed": []}
    
    def test_station_with_mapping(self, station_name, original_path, mapped_path):
        """Test a station with the corrected path mapping"""
        print(f"\n🔧 Fixing: {station_name}")
        print(f"   Original path: {original_path}")
        print(f"   Mapped path: {mapped_path}")
        
        try:
            # Try all possible path numbers with the mapped path
            for path_num in [1, 2, 3, 4, 5, 6]:
                try:
                    playback_url = f"http://radcap.ru/playback-history/{path_num}/{mapped_path}-ph.php"
                    response = requests.get(playback_url, timeout=15)
                    
                    if response.status_code == 200:
                        if len(response.text) > 100 and '<table' in response.text.lower():
                            # Enhanced patterns to find current song information
                            patterns = [
                                r'<td[^>]*>([^<]+)</td>\s*<td[^>]*><b>Current Song</b></td>',
                                r'<td[^>]*>\d{2}:\d{2}:\d{2}</td>\s*<td[^>]*>([^<]+)</td>',
                                r'<tr[^>]*>\s*<td[^>]*>\d{2}:\d{2}:\d{2}</td>\s*<td[^>]*>([^<]+)</td>',
                                r'<td[^>]*>([^<]{10,})</td>',
                            ]
                            
                            for pattern in patterns:
                                matches = re.findall(pattern, response.text, re.IGNORECASE | re.DOTALL)
                                if matches:
                                    for match in matches:
                                        song_info = match.strip()
                                        song_info = re.sub(r'^\s*\d{2}:\d{2}:\d{2}\s*', '', song_info)
                                        song_info = re.sub(r'<[^>]+>', '', song_info)
                                        song_info = re.sub(r'\s+', ' ', song_info)
                                        
                                        if (song_info and 
                                            len(song_info) > 5 and 
                                            song_info.lower() not in ['unknown', 'current song', 'time', 'song'] and
                                            not re.match(r'^\d+$', song_info) and
                                            not song_info.startswith('http')):
                                            
                                            print(f"   ✅ FIXED! Song: {song_info}")
                                            return {
                                                'station': station_name,
                                                'original_path': original_path,
                                                'fixed_path': mapped_path,
                                                'status': 'fixed',
                                                'metadata': song_info,
                                                'method': f'fixed_path_{path_num}'
                                            }
                
                except requests.RequestException:
                    continue
            
            # Try the station HTML page with mapped path
            try:
                station_url = f"http://radcap.ru/{mapped_path}.html"
                response = requests.get(station_url, timeout=15)
                
                if response.status_code == 200:
                    playback_matches = re.findall(r'href="([^"]*playback[^"]*\.php[^"]*)"', response.text, re.IGNORECASE)
                    
                    for playback_link in playback_matches:
                        try:
                            full_playback_url = f"http://radcap.ru/{playback_link}" if not playback_link.startswith('http') else playback_link
                            playback_response = requests.get(full_playback_url, timeout=15)
                            
                            if playback_response.status_code == 200 and len(playback_response.text) > 100:
                                patterns = [
                                    r'<td[^>]*>([^<]+)</td>\s*<td[^>]*><b>Current Song</b></td>',
                                    r'<td[^>]*>\d{2}:\d{2}:\d{2}</td>\s*<td[^>]*>([^<]+)</td>',
                                ]
                                
                                for pattern in patterns:
                                    matches = re.findall(pattern, playback_response.text, re.IGNORECASE | re.DOTALL)
                                    if matches:
                                        for match in matches:
                                            song_info = match.strip()
                                            song_info = re.sub(r'<[^>]+>', '', song_info)
                                            song_info = re.sub(r'\s+', ' ', song_info)
                                            
                                            if (song_info and 
                                                len(song_info) > 5 and 
                                                song_info.lower() not in ['unknown', 'current song'] and
                                                not re.match(r'^\d+$', song_info)):
                                                
                                                print(f"   ✅ FIXED! Song: {song_info}")
                                                return {
                                                    'station': station_name,
                                                    'original_path': original_path,
                                                    'fixed_path': mapped_path,
                                                    'status': 'fixed',
                                                    'metadata': song_info,
                                                    'method': 'fixed_station_page'
                                                }
                        except requests.RequestException:
                            continue
                            
            except requests.RequestException:
                pass
            
            print(f"   ❌ Still failed with mapped path")
            return {
                'station': station_name,
                'original_path': original_path,
                'fixed_path': mapped_path,
                'status': 'still_failed',
                'metadata': 'Mapped path also failed',
                'method': 'none'
            }
            
        except Exception as e:
            print(f"   💥 Error: {e}")
            return {
                'station': station_name,
                'original_path': original_path,
                'fixed_path': mapped_path,
                'status': 'still_failed',
                'metadata': f'Error: {str(e)}',
                'method': 'error'
            }
    
    def fix_failed_stations(self):
        """Fix all failed stations using path mappings"""
        
        # Load original failed results
        with open('station_metadata_test_results.json', 'r') as f:
            original_data = json.load(f)
        
        failed_radcap = [s for s in original_data['failed'] if not s['method'].startswith('somafm')]
        
        print(f"🔧 FIXING {len(failed_radcap)} FAILED RADCAP STATIONS")
        print("=" * 60)
        
        for station in failed_radcap:
            station_name = station['station']
            original_path = station['path']
            
            # Check if we have a mapping for this path
            if original_path in PATH_MAPPINGS:
                mapped_path = PATH_MAPPINGS[original_path]
                result = self.test_station_with_mapping(station_name, original_path, mapped_path)
                
                if result['status'] == 'fixed':
                    self.results['fixed'].append(result)
                else:
                    self.results['still_failed'].append(result)
            else:
                print(f"\n⚠️  No mapping for: {station_name} ({original_path})")
                self.results['still_failed'].append({
                    'station': station_name,
                    'original_path': original_path,
                    'fixed_path': 'no_mapping',
                    'status': 'still_failed',
                    'metadata': 'No path mapping available',
                    'method': 'no_mapping'
                })
            
            time.sleep(0.5)  # Be nice to the server
    
    def print_results(self):
        """Print results of the fix attempt"""
        total_attempted = len(self.results['fixed']) + len(self.results['still_failed'])
        
        print(f"\n{'='*60}")
        print("🔧 STATION FIXING RESULTS")
        print(f"{'='*60}")
        print(f"Total stations attempted: {total_attempted}")
        print(f"✅ Successfully fixed: {len(self.results['fixed'])}")
        print(f"❌ Still failed: {len(self.results['still_failed'])}")
        
        if self.results['fixed']:
            print(f"\n✅ SUCCESSFULLY FIXED STATIONS:")
            print("-" * 40)
            for result in self.results['fixed']:
                print(f"📻 {result['station']}")
                print(f"   {result['original_path']} → {result['fixed_path']}")
                print(f"   Current song: {result['metadata']}")
                print()
        
        if self.results['still_failed']:
            print(f"\n❌ STILL FAILED STATIONS:")
            print("-" * 40)
            for result in self.results['still_failed']:
                print(f"📻 {result['station']} ({result['original_path']})")
                print(f"   Issue: {result['metadata']}")
    
    def save_results(self):
        """Save fixing results to file"""
        with open('station_fixing_results.json', 'w') as f:
            json.dump(self.results, f, indent=2)
        print(f"\nResults saved to station_fixing_results.json")

def main():
    fixer = FailedStationFixer()
    fixer.fix_failed_stations()
    fixer.print_results()
    fixer.save_results()

if __name__ == "__main__":
    main()