#!/usr/bin/env python3

import json
import requests
import re
from urllib.parse import urlparse

def extract_server_mapping():
    """Create a mapping of station paths to their RadCap servers"""
    
    # Load the named streams data
    with open('radcap channels/named_streams.json', 'r') as f:
        streams = json.load(f)
    
    # Extract unique servers
    servers = set()
    path_to_server = {}
    
    for stream in streams:
        url = stream['url']
        name = stream['name']
        
        # Parse URL to get server and path
        parsed = urlparse(url)
        server = f"{parsed.scheme}://{parsed.netloc}"
        path = parsed.path.lstrip('/')
        
        servers.add(server)
        path_to_server[path] = server
        
        print(f"{path} -> {server}")
    
    print(f"\nFound {len(servers)} unique servers:")
    for server in sorted(servers):
        print(f"  {server}")
    
    # Save the mapping
    mapping = {
        'servers': sorted(list(servers)),
        'path_to_server': path_to_server
    }
    
    with open('server_metadata_mapping.json', 'w') as f:
        json.dump(mapping, f, indent=2)
    
    print(f"\nSaved mapping for {len(path_to_server)} stations to server_metadata_mapping.json")
    return mapping

def test_server_metadata(server_url):
    """Test if a server provides metadata via its status page"""
    try:
        # Try the main server page
        response = requests.get(server_url, timeout=10)
        if response.status_code == 200:
            content = response.text.lower()
            if any(keyword in content for keyword in [
                'current song', 'now playing', 'metadata', 'track', 'artist'
            ]):
                print(f"✓ {server_url} - Contains metadata")
                return True
        
        # Try common metadata endpoints
        metadata_endpoints = [
            '/status.xsl',
            '/status-json.xsl', 
            '/admin/stats.xml',
            '/7.html'  # RadCap specific
        ]
        
        for endpoint in metadata_endpoints:
            try:
                response = requests.get(f"{server_url}{endpoint}", timeout=5)
                if response.status_code == 200:
                    content = response.text.lower()
                    if any(keyword in content for keyword in [
                        'current song', 'now playing', 'metadata', 'track', 'artist', 'title'
                    ]):
                        print(f"✓ {server_url}{endpoint} - Contains metadata")
                        return True
            except:
                continue
                
        print(f"✗ {server_url} - No metadata found")
        return False
        
    except Exception as e:
        print(f"✗ {server_url} - Error: {e}")
        return False

def main():
    print("Generating server metadata mapping...")
    print("=" * 60)
    
    mapping = extract_server_mapping()
    
    print("\nTesting server metadata availability...")
    print("=" * 60)
    
    working_servers = []
    for server in mapping['servers']:
        if test_server_metadata(server):
            working_servers.append(server)
    
    print(f"\nWorking metadata servers: {len(working_servers)}/{len(mapping['servers'])}")
    for server in working_servers:
        print(f"  ✓ {server}")

if __name__ == "__main__":
    main()