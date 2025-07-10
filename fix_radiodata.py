#!/usr/bin/env python3
"""
Script to properly separate SomaFM and RadCap categories in radiodata.js
"""

# SomaFM categories (should only contain SomaFM stations)
somafm_categories = [
    {
        "name": "🌙 AMBIENT",
        "stations": [
            { "name": "Groove Salad", "host": "https://somafm.com", "path": "groovesalad", "description": "A nicely chilled plate of ambient/downtempo beats and grooves." },
            { "name": "Drone Zone", "host": "https://somafm.com", "path": "dronezone", "description": "Atmospheric textures with minimal beats." },
            { "name": "Deep Space One", "host": "https://somafm.com", "path": "deepspaceone", "description": "Deep ambient electronic and space music." },
            { "name": "Mission Control", "host": "https://somafm.com", "path": "missioncontrol", "description": "Celebrating NASA and Space Explorers everywhere." },
            { "name": "Fluid", "host": "https://somafm.com", "path": "fluid", "description": "Dj-mixed chillout, new age and ambient." },
            { "name": "SF 10-33", "host": "https://somafm.com", "path": "sf1033", "description": "Ambient music mixed with the sounds of San Francisco public safety radio traffic." }
        ]
    },
    {
        "name": "⚡ ELECTRO & BEATS",
        "stations": [
            { "name": "Space Station Soma", "host": "https://somafm.com", "path": "spacestation", "description": "Tune in, turn on, space out." },
            { "name": "Beat Blender", "host": "https://somafm.com", "path": "beatblender", "description": "A late night blend of deep-house and downtempo chill." },
            { "name": "PopTron", "host": "https://somafm.com", "path": "poptron", "description": "Electropop and indie dance rock with sparkle and pop." },
            { "name": "The Trip", "host": "https://somafm.com", "path": "thetrip", "description": "Progressive house / trance. Tip top tunes." },
            { "name": "Underground 80s", "host": "https://somafm.com", "path": "u80s", "description": "Early 80s UK Synthpop and a bit of New Wave." },
            { "name": "Digitalis", "host": "https://somafm.com", "path": "digitalis", "description": "Digitally influenced electronic music." },
            { "name": "Cliqhop idm", "host": "https://somafm.com", "path": "cliqhop", "description": "Blips'n'beats and other clicks and cuts." },
            { "name": "Earwaves", "host": "https://somafm.com", "path": "earwaves", "description": "Spanning the electronic spectrum." },
            { "name": "Dubstep Beyond", "host": "https://somafm.com", "path": "dubstep", "description": "Dubstep, future garage and the wobbles." },
            { "name": "DEF CON Radio", "host": "https://somafm.com", "path": "defcon", "description": "Music for Hacking. The DEF CON Year-Round Channel." }
        ]
    },
    {
        "name": "🎸 ROCK & ALTERNATIVE",
        "stations": [
            { "name": "Indie Pop Rocks!", "host": "https://somafm.com", "path": "indiepop", "description": "New and classic favorite indie pop tracks." },
            { "name": "Left Coast 70s", "host": "https://somafm.com", "path": "leftcoast70s", "description": "New and classic west coast rock and folk." },
            { "name": "Metal Detector", "host": "https://somafm.com", "path": "metal", "description": "From the underground comes the loudest SomaFM channel." },
            { "name": "BAGeL Radio", "host": "https://somafm.com", "path": "bagel", "description": "What alternative rock radio should sound like." }
        ]
    },
    {
        "name": "🍸 LOUNGE & CHILL",
        "stations": [
            { "name": "Illinois Street Lounge", "host": "https://somafm.com", "path": "illstreet", "description": "Classic bachelor pad, playful exotica and vintage music." },
            { "name": "Secret Agent", "host": "https://somafm.com", "path": "secretagent", "description": "The soundtrack for your stylish, mysterious, dangerous life." },
            { "name": "Lush", "host": "https://somafm.com", "path": "lush", "description": "Sensuous and mellow female vocals, mostly with an electronic influence." },
            { "name": "Seven Inch Soul", "host": "https://somafm.com", "path": "7soul", "description": "Vintage soul tracks from the original 45 RPM vinyl." }
        ]
    },
    {
        "name": "🌍 FOLK & WORLD",
        "stations": [
            { "name": "ThistleRadio", "host": "https://somafm.com", "path": "thistle", "description": "Exploring music from Celtic roots and branches." },
            { "name": "Folk Forward", "host": "https://somafm.com", "path": "folkfwd", "description": "Indie Folk, Alt-folk and the occasional folk classics." },
            { "name": "Suburbs of Goa", "host": "https://somafm.com", "path": "suburbsofgoa", "description": "Desi-influenced Asian world beats and beyond." },
            { "name": "Boot Liquor", "host": "https://somafm.com", "path": "bootliquor", "description": "Americana Roots music for Cowhands, Cowpokes and Cowtippers." }
        ]
    },
    {
        "name": "🎷 JAZZ & EXPERIMENTAL",
        "stations": [
            { "name": "Sonic Universe", "host": "https://somafm.com", "path": "sonicuniverse", "description": "Transcending the world of jazz with eclectic, avant-garde takes on tradition." }
        ]
    },
    {
        "name": "🔥 SPECIALS",
        "stations": [
            { "name": "Black Rock FM", "host": "https://somafm.com", "path": "brfm", "description": "From the Playa to the world, for the annual Burning Man festival." }
        ]
    }
]

# Now write the properly formatted radiodata.js
output = """.pragma library

// SomaFM categories - these should ONLY contain SomaFM stations
var somafmCategories = [
"""

# Add SomaFM categories
for i, cat in enumerate(somafm_categories):
    output += "    {\n"
    output += f'        "name": "{cat["name"]}",\n'
    output += '        "stations": [\n'
    
    for j, station in enumerate(cat["stations"]):
        output += f'            {{ "name": "{station["name"]}", "host": "{station["host"]}", "path": "{station["path"]}", "description": "{station["description"]}" }}'
        if j < len(cat["stations"]) - 1:
            output += ","
        output += "\n"
    
    output += "        ]\n"
    output += "    }"
    if i < len(somafm_categories) - 1:
        output += ","
    output += "\n"

output += """]

// RadCap categories - these should ONLY contain RadCap stations
var radcapCategories = [
"""

# Read the complete RadCap categories from the backup file
with open('/home/user/Documents/Free-Radio-NoAds-NoTalk/radcapradio/contents/ui/radiodata_radcap.js', 'r') as f:
    content = f.read()
    # Extract just the categories array content
    start = content.find('var categories = [') + len('var categories = [')
    end = content.rfind(']')
    radcap_content = content[start:end].strip()
    output += radcap_content

output += """]

// Combined categories for backward compatibility
var categories = somafmCategories.concat(radcapCategories)
"""

print("Writing new radiodata.js...")
with open('/home/user/Documents/Free-Radio-NoAds-NoTalk/radcapradio/contents/ui/radiodata.js', 'w') as f:
    f.write(output)

print("Done! The radiodata.js now has proper separation between SomaFM and RadCap categories.")
print("- somafmCategories: contains only SomaFM stations")
print("- radcapCategories: contains only RadCap stations")
print("- categories: combined array for backward compatibility")