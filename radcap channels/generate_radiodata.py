import json
from urllib.parse import urlparse
import difflib
import re

# Load named streams
with open("named_streams.json", "r", encoding="utf-8") as f:
    named_streams = json.load(f)

# Load optional alias map
try:
    with open("aliases.json", "r", encoding="utf-8") as f:
        aliases = json.load(f)
except FileNotFoundError:
    aliases = {}

# Build a map for quick lookups
stream_map = {
    stream["name"].strip().upper(): stream["url"]
    for stream in named_streams
    if "name" in stream and "url" in stream
}

# Normalize a string (remove non-alphanumerics)
def normalize(name):
    return re.sub(r'[^A-Z0-9]', '', name.upper())

# Improved fuzzy match function with alias support
def find_url(name):
    name_clean = name.strip()

    # Check alias
    if name_clean in aliases:
        alias_name = aliases[name_clean]
    else:
        alias_name = name_clean

    name_upper = alias_name.upper()
    name_norm = normalize(alias_name)

    # Exact match
    if name_upper in stream_map:
        return stream_map[name_upper]

    # Normalized match
    for key in stream_map:
        if normalize(key) == name_norm:
            return stream_map[key]

    # Fuzzy match
    matches = difflib.get_close_matches(name_upper, stream_map.keys(), n=1, cutoff=0.6)
    if matches:
        return stream_map[matches[0]]

    return None

# Parse categories.txt
categories = []
current_category = None
category_stations = []

with open("categories.txt", "r", encoding="utf-8") as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        if line.endswith(":"):
            # Save the previous category
            if current_category is not None:
                categories.append({
                    "name": current_category,
                    "stations": category_stations
                })
            current_category = line[:-1]
            category_stations = []
        else:
            station_name = line.strip()
            url = find_url(station_name)
            if url:
                u = urlparse(url)
                category_stations.append({
                    "name": station_name,
                    "host": f"{u.scheme}://{u.hostname}",
                    "path": u.path.lstrip("/")
                })
            else:
                print(f"[WARN] Station not found: {station_name}")

# Don't forget the last category
if current_category is not None:
    categories.append({
        "name": current_category,
        "stations": category_stations
    })

# Write the output in QML-style JavaScript format
with open("radiodata.js", "w", encoding="utf-8") as f:
    f.write(".pragma library\n\n")
    f.write("var categories = [\n")
    for cat in categories:
        f.write(f'    {{\n        "name": "{cat["name"]}",\n        "stations": [\n')
        for station in cat["stations"]:
            f.write(f'            {{ "name": "{station["name"]}", "host": "{station["host"]}", "path": "{station["path"]}" }},\n')
        f.write("        ]\n    },\n")
    f.write("]\n")
