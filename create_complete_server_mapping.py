#!/usr/bin/env python3

import json

# Load the complete server mapping
with open('server_metadata_mapping.json', 'r') as f:
    mapping = json.load(f)

# Generate QML object notation for the server mapping
print("Complete server mapping for QML:")
print("var serverMapping = {")

for i, (path, server) in enumerate(mapping['path_to_server'].items()):
    comma = "," if i < len(mapping['path_to_server']) - 1 else ""
    print(f'    "{path}": "{server}"{comma}')

print("}")

print(f"\nTotal stations mapped: {len(mapping['path_to_server'])}")

# Count stations per server
server_counts = {}
for server in mapping['path_to_server'].values():
    server_counts[server] = server_counts.get(server, 0) + 1

print("\nStations per server:")
for server, count in sorted(server_counts.items()):
    print(f"  {server}: {count} stations")

# Count stations that will use server-based metadata (79.111.119.111:8000)
metadata_server_count = sum(1 for server in mapping['path_to_server'].values() 
                          if "79.111.119.111" in server)
print(f"\nStations that can use server-based metadata: {metadata_server_count}")
print(f"Stations that will use fallback method: {len(mapping['path_to_server']) - metadata_server_count}")