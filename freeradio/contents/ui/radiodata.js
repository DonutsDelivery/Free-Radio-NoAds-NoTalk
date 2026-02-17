.pragma library

// SomaFM categories - these should ONLY contain SomaFM stations
var somafmCategories = [
    {
        "name": "🌙 Ambient",
        "stations": [
            { "name": "Groove Salad - Ambient, Downtempo, Chill", "host": "https://somafm.com", "path": "groovesalad", "description": "A nicely chilled plate of ambient/downtempo beats and grooves." },
            { "name": "Groove Salad Classic - Ambient, Downtempo", "host": "https://somafm.com", "path": "gsclassic", "description": "The classic Groove Salad mix." },
            { "name": "Drone Zone - Ambient, Drone, Atmospheric", "host": "https://somafm.com", "path": "dronezone", "description": "Atmospheric textures with minimal beats." },
            { "name": "Deep Space One - Space Ambient, Electronic", "host": "https://somafm.com", "path": "deepspaceone", "description": "Deep ambient electronic and space music." },
            { "name": "Mission Control - Space Ambient, NASA", "host": "https://somafm.com", "path": "missioncontrol", "description": "Celebrating NASA and Space Explorers everywhere." },
            { "name": "Fluid - Instrumental Hip-Hop, Future Soul", "host": "https://somafm.com", "path": "fluid", "description": "Dj-mixed chillout, new age and ambient." },
            { "name": "SF 10-33 - Ambient, Soundscape", "host": "https://somafm.com", "path": "sf1033", "description": "Ambient music mixed with the sounds of San Francisco public safety radio traffic." },
            { "name": "Synphaera Radio - Space Ambient, Electronic", "host": "https://somafm.com", "path": "synphaera", "description": "Ambient electronic music." },
            { "name": "The Dark Zone - Dark Ambient, Industrial", "host": "https://somafm.com", "path": "darkzone", "description": "Dark ambient and industrial." },
            { "name": "n5MD Radio - Ambient, IDM, Post-Rock", "host": "https://somafm.com", "path": "n5md", "description": "Ambient, IDM and experimental from n5MD." }
        ]
    },
    {
        "name": "⚡ Electro & Beats",
        "stations": [
            { "name": "Space Station Soma - Electronica, Space", "host": "https://somafm.com", "path": "spacestation", "description": "Tune in, turn on, space out." },
            { "name": "Beat Blender - Deep House, Downtempo", "host": "https://somafm.com", "path": "beatblender", "description": "A late night blend of deep-house and downtempo chill." },
            { "name": "Poptron - Electropop, Indie Dance", "host": "https://somafm.com", "path": "poptron", "description": "Electropop and indie dance rock with sparkle and pop." },
            { "name": "The Trip - Progressive House, Trance", "host": "https://somafm.com", "path": "thetrip", "description": "Progressive house / trance. Tip top tunes." },
            { "name": "Underground 80s - Synthpop, New Wave", "host": "https://somafm.com", "path": "u80s", "description": "Early 80s UK Synthpop and a bit of New Wave." },
            { "name": "Digitalis - Electronic, Glitch, Analog", "host": "https://somafm.com", "path": "digitalis", "description": "Digitally influenced electronic music." },
            { "name": "Cliqhop IDM - IDM, Glitch, Clicks & Cuts", "host": "https://somafm.com", "path": "cliqhop", "description": "Blips'n'beats and other clicks and cuts." },
            { "name": "Dubstep Beyond - Dubstep, Future Garage", "host": "https://somafm.com", "path": "dubstep", "description": "Dubstep, future garage and the wobbles." },
            { "name": "DEF CON Radio - Electronic, Hacker Culture", "host": "https://somafm.com", "path": "defcon", "description": "Music for Hacking. The DEF CON Year-Round Channel." }
        ]
    },
    {
        "name": "🎸 Rock & Alternative",
        "stations": [
            { "name": "Indie Pop Rocks! - Indie Pop, Alternative", "host": "https://somafm.com", "path": "indiepop", "description": "New and classic favorite indie pop tracks." },
            { "name": "Left Coast 70s - 70s Rock, Folk Rock", "host": "https://somafm.com", "path": "seventies", "description": "New and classic west coast rock and folk." },
            { "name": "Metal Detector - Metal, Doom, Thrash", "host": "https://somafm.com", "path": "metal", "description": "From the underground comes the loudest SomaFM channel." },
            { "name": "Bagel Radio - Alternative Rock, Indie", "host": "https://somafm.com", "path": "bagel", "description": "What alternative rock radio should sound like." },
            { "name": "Covers - Cover Songs, Various Genres", "host": "https://somafm.com", "path": "covers", "description": "Just covers - songs you know by artists you don't." },
            { "name": "Doomed - Dark Industrial, EBM, Goth", "host": "https://somafm.com", "path": "doomed", "description": "Dark industrial, EBM, and electronic music." }
        ]
    },
    {
        "name": "🍸 Lounge & Chill",
        "stations": [
            { "name": "Illinois Street Lounge - Exotica, Lounge, Vintage", "host": "https://somafm.com", "path": "illstreet", "description": "Classic bachelor pad, playful exotica and vintage music." },
            { "name": "Secret Agent - Spy Lounge, Cinematic", "host": "https://somafm.com", "path": "secretagent", "description": "The soundtrack for your stylish, mysterious, dangerous life." },
            { "name": "Lush - Female Vocals, Electronic, Mellow", "host": "https://somafm.com", "path": "lush", "description": "Sensuous and mellow female vocals, mostly with an electronic influence." },
            { "name": "Seven Inch Soul - Vintage Soul, R&B, 45rpm", "host": "https://somafm.com", "path": "7soul", "description": "Vintage soul tracks from the original 45 RPM vinyl." },
            { "name": "Tiki Time - Exotica, Tiki, Vintage Island", "host": "https://somafm.com", "path": "tikitime", "description": "A mix of exotica, vintage and modern." },
            { "name": "The In-Sound - 60s/70s Pop, Soul, Hipster", "host": "https://somafm.com", "path": "insound", "description": "60s and 70s pop and soul." },
            { "name": "Vaporwaves - Vaporwave, Future Funk", "host": "https://somafm.com", "path": "vaporwaves", "description": "Vaporwave and future funk." }
        ]
    },
    {
        "name": "🌍 Folk & World",
        "stations": [
            { "name": "Thistleradio - Celtic, Scottish, Irish Folk", "host": "https://somafm.com", "path": "thistle", "description": "Exploring music from Celtic roots and branches." },
            { "name": "Folk Forward - Indie Folk, Alt-Folk", "host": "https://somafm.com", "path": "folkfwd", "description": "Indie Folk, Alt-folk and the occasional folk classics." },
            { "name": "Suburbs of Goa - Asian Beats, Desi Fusion", "host": "https://somafm.com", "path": "suburbsofgoa", "description": "Desi-influenced Asian world beats and beyond." },
            { "name": "Boot Liquor - Americana, Country, Western", "host": "https://somafm.com", "path": "bootliquor", "description": "Americana Roots music for Cowhands, Cowpokes and Cowtippers." },
            { "name": "Heavyweight Reggae - Reggae, Roots, Dub", "host": "https://somafm.com", "path": "reggae", "description": "Reggae, Roots and Culture." }
        ]
    },
    {
        "name": "🎷 Jazz & Experimental",
        "stations": [
            { "name": "Sonic Universe - Jazz, Avant-Garde, World Fusion", "host": "https://somafm.com", "path": "sonicuniverse", "description": "Transcending the world of jazz with eclectic, avant-garde takes on tradition." },
            { "name": "Bossa Beyond - Bossa Nova, Brazilian Jazz", "host": "https://somafm.com", "path": "bossa", "description": "Bossa Nova and beyond." }
        ]
    },
    {
        "name": "🔥 Specials",
        "stations": [
            { "name": "Black Rock FM - Eclectic, Burning Man, Playa", "host": "https://somafm.com", "path": "brfm", "description": "From the Playa to the world, for the annual Burning Man festival." }
        ]
    }
]

// RadCap categories - these should ONLY contain RadCap stations
var radcapCategories = [
{
        "name": "Ethnic / Folk / Spiritual",
        "stations": [
            { "name": "Indian Classical / Folk / Ethnic", "host": "http://79.111.14.76", "path": "indianfolk" },
            { "name": "Russian Folk", "host": "http://79.111.14.76", "path": "folkrockru" },
            { "name": "Orthodox Spiritual Music", "host": "http://79.111.14.76", "path": "orthodox" },
            { "name": "Flamenco", "host": "http://79.111.14.76", "path": "flamenco" },
            { "name": "Tango", "host": "http://79.120.39.202", "path": "tango" },
            { "name": "Middle Eastern Music", "host": "http://79.111.119.111", "path": "middleeast" },
            { "name": "Celtic Music / Celtic Fusion", "host": "http://79.111.14.76", "path": "celtic" },
            { "name": "Native American", "host": "http://79.111.119.111", "path": "nativeamerican" },
            { "name": "Traditional Latin Music", "host": "http://79.120.39.202", "path": "salsa" },
            { "name": "Far Eastern Traditional Music", "host": "http://79.111.119.111", "path": "fareast" },
            { "name": "Balkan Music", "host": "http://79.120.39.202", "path": "balkan" },
            { "name": "Jewish Music / Klezmer", "host": "http://79.120.39.202", "path": "klezmer" },
            { "name": "Laiko / Greek Music", "host": "http://79.111.119.111", "path": "laika" },
            { "name": "African Folk / Ethnic", "host": "http://79.120.39.202", "path": "africanfolk" },
            { "name": "Caucasian Music", "host": "http://213.141.131.10", "path": "caucasus" },
            { "name": "Americana", "host": "http://213.141.131.10", "path": "americana" },
            { "name": "Gospel / Spirituals Music", "host": "http://79.111.14.76", "path": "gospel" },
            { "name": "Music of Siberia / Mongolia", "host": "http://79.111.119.111", "path": "siberia" },
            { "name": "Indian Spiritual Music (Mantras)", "host": "http://213.141.131.10", "path": "mantras" },
            { "name": "Medieval Folk", "host": "http://213.141.131.10", "path": "medievalfolk" },
            { "name": "European Folk", "host": "http://213.141.131.10", "path": "europeanfolk" },
            { "name": "Fado", "host": "http://213.141.131.10", "path": "fado" },
            { "name": "Slavonic Neofolk", "host": "http://213.141.131.10", "path": "slavonicneofolk" },
            { "name": "Oceania / Australia / ...", "host": "http://213.141.131.10", "path": "oceania" },
            { "name": "Andean / South American Music", "host": "http://213.141.131.10", "path": "andean" },
            { "name": "Zydeco / Cajun / Creole Music", "host": "http://213.141.131.10", "path": "zydeco" },
            { "name": "Afrobeat / Afrobeats", "host": "http://79.120.39.202", "path": "afrobeat" },
        ]
    },
    {
        "name": "Classical Music",
        "stations": [
            { "name": "Symphony", "host": "http://79.111.14.76", "path": "symphony" },
            { "name": "Classical Piano", "host": "http://79.120.39.202", "path": "classpiano" },
            { "name": "Symphonic Music", "host": "http://79.120.39.202", "path": "symphorock" },
            { "name": "Classical Choral / Vocal Music", "host": "http://79.120.39.202", "path": "chorus" },
            { "name": "Organ Music", "host": "http://79.120.77.11", "path": "organ" },
            { "name": "Classical Baroque", "host": "http://79.111.14.76", "path": "baroque" },
            { "name": "Opera", "host": "http://79.120.39.202", "path": "opera" },
            { "name": "Strings", "host": "http://79.120.39.202", "path": "strings" },
            { "name": "Contemporary Classical", "host": "http://79.111.119.111", "path": "contclass" },
            { "name": "Renaissance Music", "host": "http://213.141.131.10", "path": "renaissance" },
            { "name": "Medieval Music", "host": "http://213.141.131.10", "path": "medieval" },
            { "name": "Chamber Music", "host": "http://213.141.131.10", "path": "chamber" },
            { "name": "Clavecin / Cembalo / Harpsichord", "host": "http://213.141.131.10", "path": "clavecin" },
            { "name": "Cello / Violoncello", "host": "http://79.120.12.130", "path": "cello" },
            { "name": "Violin", "host": "http://213.141.131.10", "path": "violin" },
            { "name": "Clarinet / Bassoon / Oboe", "host": "http://213.141.131.10", "path": "clarinet" },
            { "name": "Classical Guitar", "host": "http://213.141.131.10", "path": "classguitar" },
            { "name": "Harp", "host": "http://213.141.131.10", "path": "harp" },
            { "name": "Christian Sacred Music", "host": "http://213.141.131.10", "path": "sacred" },
            { "name": "Impressionism", "host": "http://79.120.12.130", "path": "impressionism" },
            { "name": "Sonatas", "host": "http://213.141.131.10", "path": "sonata" },
            { "name": "Chants / Gregorian Chants", "host": "http://213.141.131.10", "path": "chants" },
            { "name": "Classical Avant - Garde", "host": "http://213.141.131.10", "path": "classavant" },
            { "name": "Minimalism / Postminimalism", "host": "http://213.141.131.10", "path": "minimalism" },
            { "name": "Lute / Archlute / Theorbo", "host": "http://79.120.12.130", "path": "lute" },
            { "name": "Cantatas", "host": "http://79.120.12.130", "path": "cantata" },
            { "name": "Oratorios", "host": "http://79.120.12.130", "path": "oratorio" },
            { "name": "Classical Flute", "host": "http://79.111.14.76", "path": "fluteclass" },
        ]
    },
    {
        "name": "Blues / Funk / Soul / R & B",
        "stations": [
            { "name": "Acoustic Blues", "host": "http://79.111.14.76", "path": "acousticblues" },
            { "name": "Soul / Neo Soul", "host": "http://79.120.39.202", "path": "soul" },
            { "name": "Delta Blues", "host": "http://79.120.77.11", "path": "deltablues" },
            { "name": "Funk", "host": "http://79.111.119.111", "path": "funk" },
            { "name": "Harmonica Blues", "host": "http://79.120.39.202", "path": "harpblues" },
            { "name": "Country / Folk Blues", "host": "http://79.120.77.11", "path": "countryblues" },
            { "name": "Piano Blues / Boogie - Woogie", "host": "http://79.111.14.76", "path": "pianoblues" },
            { "name": "R'n'b", "host": "http://79.120.77.11", "path": "rnb" },
            { "name": "Chicago Blues", "host": "http://79.111.14.76", "path": "chicagoblues" },
            { "name": "Heavy / Hard Blues", "host": "http://79.120.77.11", "path": "heavyblues" },
            { "name": "Blues", "host": "http://79.120.77.11", "path": "blues" },
            { "name": "Electric / Modern Electric Blues", "host": "http://79.111.14.76", "path": "electricblues" },
            { "name": "Soul Blues", "host": "http://79.111.14.76", "path": "soulblues" },
            { "name": "Texas Blues", "host": "http://79.111.14.76", "path": "texasblues" },
            { "name": "Pop Soul", "host": "http://213.141.131.10", "path": "popsoul" },
            { "name": "Jump Blues", "host": "http://213.141.131.10", "path": "jumpblues" },
            { "name": "Louisiana / Swamp / New Orleans Blues", "host": "http://213.141.131.10", "path": "louisianablues" },
            { "name": "Slide Guitar", "host": "http://213.141.131.10", "path": "slideguitar" },
            { "name": "West Coast Blues", "host": "http://79.120.12.130", "path": "westcoastblues" },
            { "name": "Hip - Hop Soul", "host": "http://79.120.12.130", "path": "hiphopsoul" },
            { "name": "Early / Pre-War Blues", "host": "http://79.120.77.11", "path": "earlyblues" },
        ]
    },
    {
        "name": "Country",
        "stations": [
            { "name": "Alternative Country", "host": "http://79.111.119.111", "path": "altcountry" },
            { "name": "Bluegrass", "host": "http://79.111.14.76", "path": "bluegrass" },
            { "name": "Country Music", "host": "http://79.120.77.11", "path": "country" },
            { "name": "Country Pop", "host": "http://79.111.119.111", "path": "countrypop" },
            { "name": "Honky - Tonk", "host": "http://213.141.131.10", "path": "honkytonk" },
            { "name": "Western Swing", "host": "http://79.120.12.130", "path": "westernswing" },
            { "name": "Country Blues", "host": "http://79.120.77.11", "path": "countryblues" },
            { "name": "Country Rock", "host": "http://79.111.119.111", "path": "countryrock" },
            { "name": "Americana", "host": "http://213.141.131.10", "path": "americana" },
        ]
    },
    {
        "name": "Jazz",
        "stations": [
            { "name": "Smooth Jazz", "host": "http://79.120.39.202", "path": "smoothjazz" },
            { "name": "Jazz Funk", "host": "http://79.120.39.202", "path": "jazzfunk" },
            { "name": "Nu Jazz / Future Jazz", "host": "http://79.111.14.76", "path": "nujazz" },
            { "name": "Free Jazz", "host": "http://79.111.14.76", "path": "freejazz" },
            { "name": "Contemporary Jazz", "host": "http://79.111.119.111", "path": "contemporaryjazz" },
            { "name": "Soul Jazz", "host": "http://79.111.14.76", "path": "souljazz" },
            { "name": "Modern Creative", "host": "http://79.120.77.11", "path": "mcreative" },
            { "name": "Swing / Neo-Swing", "host": "http://79.120.39.202", "path": "swing" },
            { "name": "Vocal Jazz", "host": "http://79.120.39.202", "path": "vocaljazz" },
            { "name": "Hard Bop", "host": "http://79.111.14.76", "path": "hardbop" },
            { "name": "Bossa Nova", "host": "http://79.111.14.76", "path": "bossanova" },
            { "name": "Latin / Afro - Cuban Jazz", "host": "http://79.111.119.111", "path": "latinjazz" },
            { "name": "Jazz Manouche / Gypsy Jazz", "host": "http://79.120.77.11", "path": "manouche" },
            { "name": "Jazz Pop", "host": "http://79.120.39.202", "path": "jazzpop" },
            { "name": "Big Band", "host": "http://79.120.39.202", "path": "bigband" },
            { "name": "Cool / West Coast Jazz", "host": "http://79.120.39.202", "path": "cooljazz" },
            { "name": "Post Bop", "host": "http://79.111.14.76", "path": "postbop" },
            { "name": "Piano Jazz / Stride / Ragtime", "host": "http://79.111.119.111", "path": "pianojazz" },
            { "name": "Avant - Garde Jazz", "host": "http://79.111.119.111", "path": "avantgardejazz" },
            { "name": "Dark / Doom / Noir / Funeral / Ambient Jazz", "host": "http://79.120.39.202", "path": "darkjazz" },
            { "name": "Dixieland", "host": "http://79.120.39.202", "path": "dixieland" },
            { "name": "Acid Jazz", "host": "http://79.111.14.76", "path": "acidjazz" },
            { "name": "Mainstream Jazz", "host": "http://79.111.14.76", "path": "mainstreamjazz" },
            { "name": "Jazz Fusion", "host": "http://79.111.119.111", "path": "jazzfusion" },
            { "name": "Jazz", "host": "http://79.120.77.11", "path": "jazz" },
            { "name": "Guitar Jazz", "host": "http://79.120.77.11", "path": "guitarjazz" },
            { "name": "Ethno / World Jazz", "host": "http://79.120.39.202", "path": "ethnojazz" },
            { "name": "Chamber Jazz", "host": "http://79.120.39.202", "path": "chamberjazz" },
            { "name": "Bebop / Be - Bop / Bop", "host": "http://79.120.12.130", "path": "bebop" },
            { "name": "Style & Sound Ecm Records", "host": "http://213.141.131.10", "path": "ecmrecords" },
            { "name": "Third Stream", "host": "http://213.141.131.10", "path": "thirdstream" },
            { "name": "Crossover Jazz", "host": "http://213.141.131.10", "path": "crossoverjazz" },
            { "name": "Modal Jazz", "host": "http://213.141.131.10", "path": "modaljazz" },
            { "name": "Straight - Ahead Jazz", "host": "http://79.120.12.130", "path": "straightahead" },
            { "name": "Jazz Trumpet", "host": "http://213.141.131.10", "path": "trumpetjazz" },
            { "name": "Vibraphone in Jazz", "host": "http://213.141.131.10", "path": "vibraphone" },
            { "name": "Brazilian Jazz", "host": "http://79.120.12.130", "path": "brazilianjazz" },
            { "name": "Free Funk", "host": "http://79.120.12.130", "path": "freefunk" },
            { "name": "Free Improvisation", "host": "http://79.120.77.11", "path": "freeimprovisation" },
        ]
    },
    {
        "name": "Pop Music",
        "stations": [
            { "name": "Classical Crossover", "host": "http://79.120.77.11", "path": "classcross" },
            { "name": "Russian Pop Music", "host": "http://79.120.77.11", "path": "popru" },
            { "name": "Nu Disco", "host": "http://79.111.119.111", "path": "nudisco" },
            { "name": "Эстрадная Музыка Ссср", "host": "http://79.120.39.202", "path": "bardru" },
            { "name": "Pop Ballads", "host": "http://79.120.77.11", "path": "popballads" },
            { "name": "Pop Music", "host": "http://79.120.77.11", "path": "pop" },
            { "name": "Italo Disco", "host": "http://79.111.119.111", "path": "italodisco" },
            { "name": "J - Pop (Japanese Pop)", "host": "http://79.111.119.111", "path": "jpop" },
            { "name": "Chanson", "host": "http://79.111.14.76", "path": "frenchchanson" },
            { "name": "K - Pop (Korean Pop)", "host": "http://79.111.119.111", "path": "kpop" },
            { "name": "Eurodance", "host": "http://79.120.39.202", "path": "eurodance" },
            { "name": "Euro Disco", "host": "http://79.111.119.111", "path": "eurodisco" },
            { "name": "Disco", "host": "http://79.120.77.11", "path": "disco" },
            { "name": "Russian Pop Music 1980 - 1990's", "host": "http://79.120.77.11", "path": "80ru" },
            { "name": "Arabic Pop Music", "host": "http://79.120.39.202", "path": "arabicpop" },
            { "name": "Latin Pop", "host": "http://79.111.119.111", "path": "latinpop" },
            { "name": "Dance Pop", "host": "http://79.120.77.11", "path": "dancepop" },
            { "name": "Eurobeat / Hi - Nrg", "host": "http://79.120.39.202", "path": "eurobeat" },
            { "name": "Italo Pop", "host": "http://213.141.131.10", "path": "italopop" },
            { "name": "C - Pop (Chinese Pop)", "host": "http://213.141.131.10", "path": "cpop" },
            { "name": "French Pop", "host": "http://79.120.12.130", "path": "frenchpop" },
            { "name": "Schlager", "host": "http://79.111.119.111", "path": "schlager" },
            { "name": "Turkish Pop / Pop Rock", "host": "http://213.141.131.10", "path": "turkishpop" },
            { "name": "Folk Pop", "host": "http://213.141.131.10", "path": "folkpop" },
            { "name": "Reggaeton / Cubaton / Salsaton / Latino...", "host": "http://213.141.131.10", "path": "reggaeton" },
            { "name": "Manele / Romanian Pop Folk / Ethnic", "host": "http://213.141.131.10", "path": "manele" },
            { "name": "Bulgarian Pop - Folk / Ethnopop / Chalga", "host": "http://213.141.131.10", "path": "chalga" },
            { "name": "Traditional / Classic Pop", "host": "http://213.141.131.10", "path": "tradpop" },
            { "name": "Cantopop / Hk - Pop", "host": "http://79.120.12.130", "path": "cantopop" },
            { "name": "Italodance", "host": "http://79.111.14.76", "path": "italodance" },
            { "name": "Mpb (Musica Popular Brasileira)", "host": "http://79.111.14.76", "path": "mpb" },
            { "name": "Pop Music of the USSR", "host": "http://79.120.77.11", "path": "ussr" },
        ]
    },
    {
        "name": "Rock Music",
        "stations": [
            { "name": "Psychobilly", "host": "http://79.111.119.111", "path": "psychobilly" },
            { "name": "Folk Rock", "host": "http://79.111.14.76", "path": "folkrock" },
            { "name": "Rock & Roll", "host": "http://79.120.77.11", "path": "rockroll" },
            { "name": "Hard / Heavy Rock", "host": "http://79.120.77.11", "path": "hardrock" },
            { "name": "Dream Pop", "host": "http://79.111.14.76", "path": "dreampop" },
            { "name": "Jazz Rock", "host": "http://79.111.119.111", "path": "jazzrock" },
            { "name": "Noise Rock", "host": "http://79.120.39.202", "path": "noiserock" },
            { "name": "Post Rock", "host": "http://79.111.14.76", "path": "postrock" },
            { "name": "Shoegazing", "host": "http://79.111.119.111", "path": "shoegazing" },
            { "name": "Space Rock", "host": "http://79.111.119.111", "path": "spacerock" },
            { "name": "Pop Rock", "host": "http://79.120.77.11", "path": "poprock" },
            { "name": "Indie Rock", "host": "http://79.120.39.202", "path": "indierock" },
            { "name": "Krautrock", "host": "http://79.111.119.111", "path": "krautrock" },
            { "name": "Math Rock", "host": "http://79.120.39.202", "path": "mathrock" },
            { "name": "Horror Punk", "host": "http://79.120.77.11", "path": "horrorpunk" },
            { "name": "Eclectic Prog", "host": "http://79.111.14.76", "path": "eclecticprog" },
            { "name": "Dark Cabaret", "host": "http://79.111.119.111", "path": "darkcabaret" },
            { "name": "Dark Wave", "host": "http://79.111.14.76", "path": "darkwave" },
            { "name": "Celtic Rock", "host": "http://79.120.12.130", "path": "celticrock" },
            { "name": "Roots Rock", "host": "http://79.120.12.130", "path": "rootsrock" },
            { "name": "Garage Punk", "host": "http://79.120.12.130", "path": "garagepunk" },
            { "name": "Indie Folk", "host": "http://79.111.14.76", "path": "indiefolk" },
            { "name": "Surf Rock", "host": "http://79.111.119.111", "path": "surfrock" },
            { "name": "Punk Rock", "host": "http://79.120.77.11", "path": "punk" },
            { "name": "Grunge", "host": "http://79.120.39.202", "path": "grunge" },
            { "name": "New Wave / Cold Wave", "host": "http://79.120.39.202", "path": "newwave" },
            { "name": "Art Rock", "host": "http://79.120.39.202", "path": "artrock" },
            { "name": "Gothic Rock", "host": "http://79.111.14.76", "path": "gothicrock" },
            { "name": "Post Grunge", "host": "http://79.111.119.111", "path": "postgrunge" },
            { "name": "Garage Rock / Revival", "host": "http://79.111.119.111", "path": "garagerock" },
            { "name": "Rockabilly", "host": "http://79.111.14.76", "path": "rockabilly" },
            { "name": "Stoner Rock", "host": "http://79.111.119.111", "path": "stonerrock" },
            { "name": "Blues Rock", "host": "http://79.120.39.202", "path": "bluesrock" },
            { "name": "Post Punk / No Wave", "host": "http://79.120.39.202", "path": "postpunk" },
            { "name": "Pop Punk", "host": "http://79.111.14.76", "path": "poppunk" },
            { "name": "Country Rock", "host": "http://79.111.119.111", "path": "countryrock" },
            { "name": "Twist", "host": "http://79.111.119.111", "path": "twist" },
            { "name": "Acid Rock", "host": "http://213.141.131.10", "path": "acidrock" },
            { "name": "Jam Band", "host": "http://79.120.12.130", "path": "jamband" },
            { "name": "Deathrock", "host": "http://79.120.12.130", "path": "deathrock" },
            { "name": "Pub Rock", "host": "http://79.120.12.130", "path": "pubrock" },
            { "name": "Britpop / Post Britpop", "host": "http://79.120.39.202", "path": "britpop" },
            { "name": "Southern Rock / Metal", "host": "http://79.111.14.76", "path": "southernrock" },
            { "name": "Russian Rock / Bard Rock", "host": "http://79.120.77.11", "path": "rockru" },
            { "name": "Instrumental Rock", "host": "http://79.120.39.202", "path": "instrumentalrock" },
            { "name": "Aor / Melodic Hard Rock", "host": "http://79.111.14.76", "path": "aor" },
            { "name": "Rock / Metal Ballads", "host": "http://79.120.77.11", "path": "rockballads" },
            { "name": "Neo - Progressive Rock", "host": "http://79.111.119.111", "path": "neoprogrock" },
            { "name": "Russian Punk Rock", "host": "http://79.120.77.11", "path": "punkru" },
            { "name": "Classic Rock / Rock", "host": "http://79.120.77.11", "path": "rock" },
            { "name": "Russian Folk Rock", "host": "http://79.111.14.76", "path": "folkrockru" },
            { "name": "Glam Rock / Metal", "host": "http://79.120.39.202", "path": "glam" },
            { "name": "Alternative Rock", "host": "http://79.120.39.202", "path": "altrock" },
            { "name": "Progressive Rock", "host": "http://79.111.119.111", "path": "progressiverock" },
            { "name": "Psychedelic Rock", "host": "http://79.111.119.111", "path": "psychedelicrock" },
            { "name": "Chamber / Baroque / Pop / Rock", "host": "http://79.111.14.76", "path": "chamberpop" },
            { "name": "Avant - Prog / Rock in Opposition (Rio) / Canterbury Scene / Zeuhl Heavy / Hard Psychedelic", "host": "http://79.111.119.111", "path": "avantprog" },
            { "name": "Slowcore / Sadcore", "host": "http://213.141.131.10", "path": "slowcore" },
            { "name": "Progressive Folk", "host": "http://213.141.131.10", "path": "progfolk" },
            { "name": "Psychedelic Folk", "host": "http://213.141.131.10", "path": "psychfolk" },
            { "name": "J - Rock (Japanese Rock)", "host": "http://79.111.119.111", "path": "jrock" },
            { "name": "Dance / Disco / Funk Punk", "host": "http://213.141.131.10", "path": "dancepunk" },
            { "name": "Experimental / Avant Rock", "host": "http://213.141.131.10", "path": "avantrock" },
            { "name": "Folk / Celtic / Gypsy Punk", "host": "http://213.141.131.10", "path": "folkpunk" },
            { "name": "Funk Rock / Metal", "host": "http://213.141.131.10", "path": "funkrock" },
            { "name": "Visual / Nagoya / Oshare / Angura Kei", "host": "http://79.120.12.130", "path": "visualkei" },
            { "name": "Indie / Twee Pop", "host": "http://79.111.119.111", "path": "indiepop" },
            { "name": "Oi! / Street Punk", "host": "http://79.111.119.111", "path": "oistreetpunk" },
            { "name": "Piano Rock / Pop", "host": "http://79.111.14.76", "path": "pianorock" },
            { "name": "Ethereal Wave", "host": "http://213.141.131.10", "path": "ethereal" },
            { "name": "Christian Rock", "host": "http://213.141.131.10", "path": "christianrock" },
            { "name": "Crossover Prog", "host": "http://79.111.14.76", "path": "crossoverprog" },
            { "name": "Symphonic Rock", "host": "http://79.120.39.202", "path": "symphorock" },
            { "name": "Industrial Rock", "host": "http://79.120.77.11", "path": "industrialrock" },
            { "name": "Heavy / Hard Prog", "host": "http://79.111.14.76", "path": "heavyprog" },
            { "name": "Rpi (Rock Progressivo Italiano)", "host": "http://79.111.14.76", "path": "rpi" },
            { "name": "Heavy / Hard Psychedelic", "host": "http://79.120.39.202", "path": "heavypsych" },
            { "name": "Proto-Prog / Early Progressive Rock", "host": "http://79.120.77.11", "path": "protoprog" },
        ]
    },
    {
        "name": "Reggae / Ska",
        "stations": [
            { "name": "Reggae", "host": "http://79.120.39.202", "path": "reggae" },
            { "name": "Ska", "host": "http://79.111.119.111", "path": "ska" },
            { "name": "Dub", "host": "http://79.111.14.76", "path": "dub" },
            { "name": "Ska Punk / Core", "host": "http://79.111.119.111", "path": "skapunk" },
            { "name": "Dancehall / Raggamuffin", "host": "http://79.111.14.76", "path": "dancehall" },
            { "name": "Roots Reggae", "host": "http://79.111.119.111", "path": "rootsreggae" },
            { "name": "Rocksteady / Lovers Rock", "host": "http://79.120.39.202", "path": "rocksteady" },
        ]
    },
    {
        "name": "Metal",
        "stations": [
            { "name": "Groove Metal", "host": "http://79.120.39.202", "path": "groovemetal" },
            { "name": "Dark Metal", "host": "http://79.111.119.111", "path": "darkmetal" },
            { "name": "Doom Metal", "host": "http://79.120.39.202", "path": "deathdoom" },
            { "name": "Death Metal", "host": "http://79.120.77.11", "path": "deathmetal" },
            { "name": "Power Metal", "host": "http://79.120.77.11", "path": "powermetal" },
            { "name": "Gothic Metal", "host": "http://79.120.77.11", "path": "gothicmetal" },
            { "name": "Speed Metal", "host": "http://79.111.119.111", "path": "speedmetal" },
            { "name": "Folk Metal", "host": "http://79.120.39.202", "path": "folkmetal" },
            { "name": "Epic Metal", "host": "http://79.111.119.111", "path": "epicmetal" },
            { "name": "Death 'n' Roll", "host": "http://79.120.39.202", "path": "deathnroll" },
            { "name": "Post Metal", "host": "http://79.120.39.202", "path": "postmetal" },
            { "name": "Black Metal", "host": "http://79.120.77.11", "path": "blackmetal" },
            { "name": "Alt / Nu Metal", "host": "http://79.111.14.76", "path": "numetal" },
            { "name": "Sludge Metal", "host": "http://79.120.77.11", "path": "sludgemetal" },
            { "name": "Heavy Metal", "host": "http://79.111.14.76", "path": "heavymetal" },
            { "name": "Stoner / Stoner Doom Metal", "host": "http://79.120.77.11", "path": "stonermetal" },
            { "name": "Pagan Metal", "host": "http://79.111.119.111", "path": "paganmetal" },
            { "name": "Viking Metal", "host": "http://79.111.14.76", "path": "vikingmetal" },
            { "name": "Nwobhm", "host": "http://79.120.12.130", "path": "nwobhm" },
            { "name": "Speed Heavy", "host": "http://213.141.131.10", "path": "speedheavy" },
            { "name": "Celtic Metal", "host": "http://79.120.12.130", "path": "celticmetal" },
            { "name": "Symphonic Black Metal", "host": "http://79.111.119.111", "path": "symphonicblackmetal" },
            { "name": "Neoclassical Metal", "host": "http://79.111.119.111", "path": "neoclassicalmetal" },
            { "name": "Progressive Black / Post - Black / Blackgaze", "host": "http://79.111.14.76", "path": "postblack" },
            { "name": "Progressive Death Metal", "host": "http://79.111.119.111", "path": "progdeath" },
            { "name": "Black / Blackened Death", "host": "http://79.111.14.76", "path": "blackdeath" },
            { "name": "Instrumental Metal", "host": "http://79.111.119.111", "path": "instrumentalmetal" },
            { "name": "Avant - Garde Metal", "host": "http://79.111.14.76", "path": "avantgardemetal" },
            { "name": "Progressive Metal", "host": "http://79.120.77.11", "path": "progmetal" },
            { "name": "Thrash Metal", "host": "http://79.120.77.11", "path": "thrashmetal" },
            { "name": "Brutal / Slamming Brutal Death", "host": "http://79.111.119.111", "path": "brutaldeathmetal" },
            { "name": "Drone / Drone Doom Metal", "host": "http://79.120.39.202", "path": "dronemetal" },
            { "name": "Depressive Black Metal", "host": "http://79.111.119.111", "path": "dsbm" },
            { "name": "Industrial / Cyber Metal", "host": "http://79.120.39.202", "path": "industrialmetal" },
            { "name": "Melodic Death Metal", "host": "http://79.120.77.11", "path": "melodicdeath" },
            { "name": "Technical Death Metal", "host": "http://79.120.77.11", "path": "techdeathmetal" },
            { "name": "Melodic Black Metal", "host": "http://79.111.119.111", "path": "melodicblackmetal" },
            { "name": "Atmospheric / Ambient Black", "host": "http://79.120.39.202", "path": "aabmds" },
            { "name": "Math Metal / Djent", "host": "http://79.120.39.202", "path": "mathmetal" },
            { "name": "Female Vocal in Metal", "host": "http://79.111.14.76", "path": "femalemetal" },
            { "name": "Death Doom Metal", "host": "http://79.120.39.202", "path": "deathdoom" },
            { "name": "Funeral Doom Metal", "host": "http://79.120.77.11", "path": "funeraldoom" },
            { "name": "Black / Blackened Doom", "host": "http://79.120.77.11", "path": "blackdoom" },
            { "name": "Gothic Doom Metal", "host": "http://79.120.39.202", "path": "gothdoommet" },
            { "name": "Progressive Power Metal", "host": "http://79.111.119.111", "path": "progpowermetal" },
            { "name": "Heavy Power Metal", "host": "http://79.120.12.130", "path": "heavypowermetal" },
            { "name": "Melodic Heavy Metal", "host": "http://79.111.119.111", "path": "melodicheavy" },
            { "name": "Melodic Power Metal", "host": "http://79.111.119.111", "path": "melodicpower" },
            { "name": "Thrash Death Metal", "host": "http://79.120.12.130", "path": "thrashdeath" },
            { "name": "Neue Deutsche Härte", "host": "http://213.141.131.10", "path": "ndh" },
            { "name": "Symphonic Power Metal", "host": "http://213.141.131.10", "path": "symphopower" },
            { "name": "Progressive Heavy Metal", "host": "http://213.141.131.10", "path": "progheavy" },
            { "name": "Thrash Heavy Metal", "host": "http://213.141.131.10", "path": "thrashheavy" },
            { "name": "Thrash Black Metal", "host": "http://213.141.131.10", "path": "thrashblack" },
            { "name": "Symphonic Death Metal", "host": "http://213.141.131.10", "path": "symphodeath" },
            { "name": "Symphonic Gothic Metal", "host": "http://213.141.131.10", "path": "symphogoth" },
            { "name": "Crossover Thrash", "host": "http://213.141.131.10", "path": "crossoverthrash" },
            { "name": "Atmospheric Doom", "host": "http://213.141.131.10", "path": "atmosphericdoom" },
            { "name": "Jazz / Fusion Metal", "host": "http://213.141.131.10", "path": "jazzmetal" },
            { "name": "Medieval Metal / Rock", "host": "http://213.141.131.10", "path": "medievalmetal" },
            { "name": "Avant - Garde Black Metal", "host": "http://79.120.39.202", "path": "avantblackmet" },
            { "name": "Gothic Black Metal", "host": "http://79.120.39.202", "path": "gothblackmet" },
            { "name": "Gothic Death Metal", "host": "http://79.120.39.202", "path": "gothdeathmet" },
            { "name": "Symphonic Metal", "host": "http://79.120.77.11", "path": "symphometal" },
            { "name": "Oriental Metal", "host": "http://79.111.119.111", "path": "orientalmetal" },
            { "name": "Melodic Doom / Doom Death", "host": "http://79.120.12.130", "path": "melodicdoom" },
            { "name": "Folk Black Metal", "host": "http://79.120.12.130", "path": "folkblackmet" },
            { "name": "Folk Death Metal", "host": "http://79.120.12.130", "path": "folkdeathmet" },
        ]
    },
    {
        "name": "Hardcore",
        "stations": [
            { "name": "Deathcore / Melodic Deathcore", "host": "http://79.111.14.76", "path": "deathcore" },
            { "name": "Crust Punk / Stenchcore", "host": "http://79.120.39.202", "path": "crust" },
            { "name": "Rapcore / Rap Metal", "host": "http://79.111.119.111", "path": "rapcore" },
            { "name": "Metalcore", "host": "http://79.120.39.202", "path": "metalcore" },
            { "name": "Emocore / Screamo / EMO Violence", "host": "http://79.111.119.111", "path": "screamoemo" },
            { "name": "Progressive Metalcore", "host": "http://79.111.14.76", "path": "progmetalcore" },
            { "name": "Post Hardcore", "host": "http://79.111.119.111", "path": "posthardcore" },
            { "name": "Grindcore / Deathgrind", "host": "http://79.120.77.11", "path": "grindcore" },
            { "name": "Melodic Metalcore", "host": "http://79.111.14.76", "path": "melodicmetalcore" },
            { "name": "Mathcore / Chaotic Hardcore", "host": "http://79.120.39.202", "path": "mathcore" },
            { "name": "Hardcore / Melodic Hardcore", "host": "http://79.111.14.76", "path": "hardcoremetal" },
            { "name": "Electronicore / Synthcore / Trancecore", "host": "http://79.111.119.111", "path": "electronicore" },
            { "name": "Beatdown / Moshcore / Downtempo Hardcore / Metalcore", "host": "http://79.111.14.76", "path": "beatdown" },
        ]
    },
    {
        "name": "Electronic Music",
        "stations": [
            { "name": "Hardstyle", "host": "http://79.111.14.76", "path": "hardstyle" },
            { "name": "Lo - Fi", "host": "http://79.111.14.76", "path": "lo-fi" },
            { "name": "Ambient Dub", "host": "http://79.111.14.76", "path": "ambientdub" },
            { "name": "Ambient", "host": "http://79.111.119.111", "path": "ambient" },
            { "name": "Electroclash", "host": "http://79.120.39.202", "path": "electroclash" },
            { "name": "Dark Dubstep", "host": "http://79.120.39.202", "path": "darkdubstep" },
            { "name": "Trance", "host": "http://79.120.77.11", "path": "trance" },
            { "name": "Chill Out", "host": "http://79.111.14.76", "path": "chillout" },
            { "name": "Chiptune", "host": "http://79.111.119.111", "path": "chiptune" },
            { "name": "Vocal Trance", "host": "http://79.120.39.202", "path": "vocaltrance" },
            { "name": "Psybient / Psychill", "host": "http://79.111.14.76", "path": "psybient" },
            { "name": "New Age", "host": "http://79.120.77.11", "path": "newage" },
            { "name": "Lounge", "host": "http://79.111.14.76", "path": "lounge" },
            { "name": "Psytrance", "host": "http://79.111.119.111", "path": "psytrance" },
            { "name": "Deathstep / Death Dubstep", "host": "http://79.111.14.76", "path": "deathstep" },
            { "name": "Space Music", "host": "http://79.111.119.111", "path": "spacemusic" },
            { "name": "Dubstep", "host": "http://79.120.39.202", "path": "dubstep" },
            { "name": "Broken Beat", "host": "http://79.120.77.11", "path": "brokenbeat" },
            { "name": "Leftfield", "host": "http://79.120.39.202", "path": "leftfield" },
            { "name": "Tribal House", "host": "http://213.141.131.10", "path": "tribalhouse" },
            { "name": "Funky House", "host": "http://213.141.131.10", "path": "funkyhouse" },
            { "name": "Nitzhonot", "host": "http://213.141.131.10", "path": "nitzhonot" },
            { "name": "Garage House", "host": "http://79.120.12.130", "path": "garagehouse" },
            { "name": "Full on", "host": "http://79.111.14.76", "path": "fullon" },
            { "name": "Goa Trance", "host": "http://79.120.39.202", "path": "goatrance" },
            { "name": "Techno", "host": "http://79.120.77.11", "path": "techno" },
            { "name": "Electro", "host": "http://79.111.119.111", "path": "electro" },
            { "name": "Spacesynth / Synthdance", "host": "http://79.120.39.202", "path": "spacesynth" },
            { "name": "Euro House", "host": "http://79.111.119.111", "path": "eurohouse" },
            { "name": "Dub Techno", "host": "http://79.120.39.202", "path": "dubtechno" },
            { "name": "Dream Trance", "host": "http://79.120.39.202", "path": "dreamtrance" },
            { "name": "Trip - Hop", "host": "http://79.111.14.76", "path": "triphop" },
            { "name": "Industrial", "host": "http://79.111.14.76", "path": "industrial" },
            { "name": "Downtempo", "host": "http://79.120.77.11", "path": "downtempo" },
            { "name": "Grime", "host": "http://79.120.77.11", "path": "grime" },
            { "name": "Dark Techno", "host": "http://79.111.14.76", "path": "darktechno" },
            { "name": "Witch House", "host": "http://79.120.77.11", "path": "witchhouse" },
            { "name": "Club Dance", "host": "http://79.111.119.111", "path": "clubdance" },
            { "name": "Hard Trance", "host": "http://79.120.77.11", "path": "hardtrance" },
            { "name": "Drumstep", "host": "http://79.120.39.202", "path": "drumstep" },
            { "name": "House", "host": "http://79.120.77.11", "path": "house" },
            { "name": "Drum & Bass", "host": "http://79.111.14.76", "path": "drumbass" },
            { "name": "Futurepop", "host": "http://79.120.39.202", "path": "futurepop" },
            { "name": "Breakcore", "host": "http://79.111.119.111", "path": "breakcore" },
            { "name": "EDM Trap", "host": "http://213.141.131.10", "path": "edmtrap" },
            { "name": "Hard House", "host": "http://213.141.131.10", "path": "hardhouse" },
            { "name": "Illbient", "host": "http://213.141.131.10", "path": "illbient" },
            { "name": "IDM Ambient", "host": "http://213.141.131.10", "path": "idmambient" },
            { "name": "Cyberpunk", "host": "http://79.120.12.130", "path": "cyberpunk" },
            { "name": "Jumpstyle", "host": "http://79.120.12.130", "path": "jumpstyle" },
            { "name": "Makina", "host": "http://79.120.12.130", "path": "makina" },
            { "name": "New Beat", "host": "http://79.120.12.130", "path": "newbeat" },
            { "name": "Freestyle", "host": "http://79.120.12.130", "path": "freestyle" },
            { "name": "Harsh Noise", "host": "http://79.111.14.76", "path": "harshnoise" },
            { "name": "Metalstep / Brostep / Metal Dubstep", "host": "http://79.111.14.76", "path": "metalstep" },
            { "name": "Progressive Trance", "host": "http://79.120.39.202", "path": "progtrance" },
            { "name": "Russian Club Dance", "host": "http://79.120.77.11", "path": "clubru" },
            { "name": "Neurofunk / Technoid / Techstep", "host": "http://79.111.119.111", "path": "neurofunk" },
            { "name": "IDM (Intelligent Dance Music)", "host": "http://79.111.14.76", "path": "idm" },
            { "name": "Progressive Psytrance", "host": "http://79.120.39.202", "path": "progtrance" },
            { "name": "Dark Electro / Aggrotech", "host": "http://79.120.39.202", "path": "darkelectro" },
            { "name": "Breakbeat / Big Beat", "host": "http://79.120.39.202", "path": "breakbeat" },
            { "name": "Hardcore Techno / Schranz", "host": "http://79.120.39.202", "path": "hardcoretech" },
            { "name": "EBM (Electronic Body Music)", "host": "http://79.111.14.76", "path": "ebm" },
            { "name": "Dark / Neo / Apocalyptic Folk", "host": "http://79.111.119.111", "path": "darkfolk" },
            { "name": "Indie Electronic / New Rave", "host": "http://79.111.119.111", "path": "indieelectronic" },
            { "name": "Happy / UK Hardcore", "host": "http://79.120.77.11", "path": "happyhardcore" },
            { "name": "Minimal Tech House", "host": "http://79.111.119.111", "path": "mintechhouse" },
            { "name": "Retrowave / Synthwave / Dreamwave", "host": "http://79.120.39.202", "path": "retrowave" },
            { "name": "Glitch / Glitch - Hop", "host": "http://79.111.14.76", "path": "glitch" },
            { "name": "Future Garage / Chillstep / Deepstep", "host": "http://79.120.39.202", "path": "futuregarage" },
            { "name": "Industrial / Dark / Ritual Ambient", "host": "http://79.120.39.202", "path": "darkambient" },
            { "name": "Synthpop / Electropop / Technopop", "host": "http://79.120.77.11", "path": "synthpop" },
            { "name": "Progressive House", "host": "http://79.111.119.111", "path": "proghouse" },
            { "name": "Intelligent / Liquid Funk", "host": "http://79.111.119.111", "path": "liquidfunk" },
            { "name": "Electro - Industrial", "host": "http://79.111.119.111", "path": "electroindustrial" },
            { "name": "Deep / Chill House", "host": "http://79.120.39.202", "path": "deephouse" },
            { "name": "Traditional Electronic", "host": "http://79.111.14.76", "path": "tradelectronic" },
            { "name": "Ethnic Electronica", "host": "http://79.120.39.202", "path": "ethnotronica" },
            { "name": "Suomisaundi / Freeform Psytrance", "host": "http://79.120.77.11", "path": "suomisaundi" },
            { "name": "Acid House / Trance / Techno", "host": "http://79.111.119.111", "path": "acid" },
            { "name": "Ambient / Intelligent Techno / House", "host": "http://79.120.39.202", "path": "ambienttechno" },
            { "name": "Martial Industrial / Military Pop", "host": "http://79.111.14.76", "path": "martialindustrial" },
            { "name": "Power / Rhythmic Noise / Dbm (Distorted Beat Music)", "host": "http://79.120.39.202", "path": "powernoise" },
            { "name": "Musique Concrete / Acousmatic / Electroacoustic", "host": "http://213.141.131.10", "path": "musiqueconcrete" },
            { "name": "Future Bass / Chill Trap", "host": "http://213.141.131.10", "path": "futurebass" },
            { "name": "Enigmatic / Mystic Pop", "host": "http://213.141.131.10", "path": "enigmatic" },
            { "name": "Detroit Techno / Tech House", "host": "http://213.141.131.10", "path": "detroittechno" },
            { "name": "Underground Techno / Tech House", "host": "http://213.141.131.10", "path": "undergroundtechno" },
            { "name": "Forest Psytrance", "host": "http://213.141.131.10", "path": "forestpsytrance" },
            { "name": "Jungle / Ragga Jungle / Raggacore", "host": "http://213.141.131.10", "path": "jungle" },
            { "name": "Chillwave / Vaporwave", "host": "http://79.111.119.111", "path": "chillwave" },
            { "name": "Experimental Techno", "host": "http://213.141.131.10", "path": "experimentaltechno" },
            { "name": "Techno Trance / Techtrance", "host": "http://213.141.131.10", "path": "techtrance" },
            { "name": "Night Full on / Psytrance", "host": "http://213.141.131.10", "path": "nightpsytrance" },
            { "name": "Electro Swing / Swing House", "host": "http://213.141.131.10", "path": "electroswing" },
            { "name": "Gabber / Early / Mainstream Hardcore", "host": "http://213.141.131.10", "path": "gabber" },
            { "name": "Darksynth / Dark Synthwave", "host": "http://213.141.131.10", "path": "darksynth" },
            { "name": "Progressive Electronic", "host": "http://79.120.12.130", "path": "progelectronic" },
            { "name": "Twilight / Psytrance", "host": "http://79.120.12.130", "path": "twilightpsy" },
            { "name": "Dungeon Synth", "host": "http://79.120.12.130", "path": "dungeonsynth" },
            { "name": "Hi - Tech / Psytrance", "host": "http://79.120.12.130", "path": "hitechpsy" },
            { "name": "Industrial Techno", "host": "http://79.120.12.130", "path": "industrialtechno" },
            { "name": "Uplifting / Epic / Euphoric Trance", "host": "http://79.111.119.111", "path": "upliftingtrance" },
            { "name": "Drone Ambient", "host": "http://79.111.119.111", "path": "droneambient" },
            { "name": "Pumping House / Hard Bass", "host": "http://79.120.77.11", "path": "pumpinghouse" },
            { "name": "Riddim Dubstep", "host": "http://79.111.119.111", "path": "riddimdubstep" },
            { "name": "Soulful House", "host": "http://79.111.119.111", "path": "soulfulhouse" },
            { "name": "Minimal Techno", "host": "http://79.120.39.202", "path": "mintechno" },
            { "name": "Field Recordings", "host": "http://213.141.131.10", "path": "fieldrecording" },
            { "name": "Electro Techno", "host": "http://213.141.131.10", "path": "electrotechno" },
            { "name": "Electro House", "host": "http://79.111.14.76", "path": "electrohouse" },
            { "name": "Dark Psytrance", "host": "http://79.111.119.111", "path": "darkpsytrance" },
            { "name": "Balearic Beat / House | Ibiza House / Chillout", "host": "http://213.141.131.10", "path": "balearichouse" },
            { "name": "Big Room House", "host": "http://213.141.131.10", "path": "bigroomhouse" },
            { "name": "Ambient House", "host": "http://79.120.12.130", "path": "ambienthouse" },
            { "name": "Progressive / Atmospheric Breaks", "host": "http://79.120.12.130", "path": "progbreaks" },
            { "name": "Melodic House / Techno", "host": "http://79.120.12.130", "path": "melodichouse" },
            { "name": "Organic House", "host": "http://79.120.12.130", "path": "organichouse" },
            { "name": "Latin House / EDM", "host": "http://79.120.12.130", "path": "latinhouse" },
            { "name": "Ghetto / Booty / G - House", "host": "http://79.111.14.76", "path": "ghouse" },
            { "name": "Power Electronics / Death Industrial", "host": "http://79.111.14.76", "path": "powerelectronics" },
            { "name": "Progressive Psytrance / Psy-Prog", "host": "http://79.120.39.202", "path": "psyprog" },
        ]
    },
    {
        "name": "Rap / Hip - Hop",
        "stations": [
            { "name": "Hip - Hop", "host": "http://79.120.77.11", "path": "hiphop" },
            { "name": "West Coast / Gangsta / G - Funk", "host": "http://79.120.39.202", "path": "gangstarap" },
            { "name": "Instrumental Hip - Hop", "host": "http://79.120.77.11", "path": "instrumentalhiphop" },
            { "name": "Russian Rap", "host": "http://79.120.77.11", "path": "rapru" },
            { "name": "Rap", "host": "http://79.120.77.11", "path": "rap" },
            { "name": "Underground Rap", "host": "http://79.111.14.76", "path": "undergroundrap" },
            { "name": "Alternative / Abstract / Experimental Hip - Hop", "host": "http://79.111.14.76", "path": "abstracthiphop" },
            { "name": "Southern Rap / Hip - Hop / Crunk", "host": "http://79.111.119.111", "path": "southernrap" },
            { "name": "East Coast Rap", "host": "http://79.111.14.76", "path": "eastcoastrap" },
            { "name": "Jazz Rap / Jazz Hop / Jazzy Hip - Hop", "host": "http://79.120.39.202", "path": "jazzrap" },
            { "name": "Hardcore Rap / Horrorcore", "host": "http://79.120.39.202", "path": "hardcorerap" },
            { "name": "Memphis Rap", "host": "http://213.141.131.10", "path": "memphisrap" },
            { "name": "German / Deutsche Hip - Hop / Rap", "host": "http://213.141.131.10", "path": "germanrap" },
            { "name": "French Hip - Hop / Rap", "host": "http://213.141.131.10", "path": "frenchrap" },
            { "name": "UK / British Hip - Hop / Rap", "host": "http://213.141.131.10", "path": "ukhiphop" },
            { "name": "Old School Hip - Hop", "host": "http://213.141.131.10", "path": "oldschoolhiphop" },
            { "name": "Cloud Rap / Trillwave", "host": "http://213.141.131.10", "path": "cloudrap" },
            { "name": "Chicano Rap", "host": "http://213.141.131.10", "path": "chicanorap" },
            { "name": "Phonk / Drift Phonk", "host": "http://79.120.77.11", "path": "phonk" },
        ]
    },
    {
        "name": "Шансон",
        "stations": [
            { "name": "Русский Шансон", "host": "http://79.120.39.202", "path": "bardru" },
            { "name": "Русский Постшансон", "host": "http://79.120.39.202", "path": "bardru" },
            { "name": "Цыганская Песня", "host": "http://79.120.39.202", "path": "bardru" },
            { "name": "Русский / Городской / Жестокий / Романс", "host": "http://79.120.39.202", "path": "bardru" },
            { "name": "Авторская / Бардовская Песня", "host": "http://79.120.39.202", "path": "bardru" },
            { "name": "Russian Post Shanson", "host": "http://79.120.77.11", "path": "postshanson" },
            { "name": "Russian Shanson", "host": "http://79.120.77.11", "path": "shansonru" },
            { "name": "Military Songs / Marches of Russia", "host": "http://79.111.119.111", "path": "rusmilsong" },
        ]
    },
    {
        "name": "Miscellaneous Music",
        "stations": [
            { "name": "Oldies / Doo-Wop", "host": "http://79.120.77.11", "path": "oldies" },
            { "name": "Modern Classical", "host": "http://79.120.39.202", "path": "modernclassical" },
            { "name": "Vocal", "host": "http://79.120.77.11", "path": "vocal" },
            { "name": "Piano", "host": "http://79.120.77.11", "path": "piano" },
            { "name": "Experimental / Avant - Garde Music", "host": "http://79.111.119.111", "path": "experimentalmusic" },
            { "name": "Computer / Video Game Music", "host": "http://79.120.39.202", "path": "musicgame" },
            { "name": "Acoustic Guitar", "host": "http://79.120.39.202", "path": "acousticguitar" },
            { "name": "Neoclassical Music", "host": "http://79.120.39.202", "path": "neoclassical" },
            { "name": "Sounds of Nature", "host": "http://79.111.14.76", "path": "soundnat" },
            { "name": "Saxophone", "host": "http://79.120.77.11", "path": "saxophone" },
            { "name": "Misc", "host": "http://79.120.77.11", "path": "misc" },
            { "name": "Военные Песни / Марши России", "host": "http://79.120.39.202", "path": "bardru" },
            { "name": "Hammond Organ", "host": "http://79.120.39.202", "path": "hammond" },
            { "name": "Ballroom Dance", "host": "http://79.111.14.76", "path": "ballroomdance" },
            { "name": "Instrumental Music", "host": "http://79.120.77.11", "path": "instrumental" },
            { "name": "Поэзия", "host": "http://79.120.39.202", "path": "bardru" },
            { "name": "Accordion / Баян / Гармонь", "host": "http://79.111.119.111", "path": "accordion" },
            { "name": "Indian Cinema Music", "host": "http://79.120.39.202", "path": "indiancinema" },
            { "name": "Relaxation Music", "host": "http://79.120.39.202", "path": "relaxation" },
            { "name": "Flute", "host": "http://79.111.14.76", "path": "flute" },
            { "name": "Easy Listening", "host": "http://79.111.14.76", "path": "easylistening" },
            { "name": "Romantic Music Collection", "host": "http://79.120.39.202", "path": "romantic" },
            { "name": "Erotic Music", "host": "http://79.120.39.202", "path": "erotic" },
            { "name": "Meditation Music", "host": "http://79.120.77.11", "path": "meditation" },
            { "name": "Trailer Music", "host": "http://79.111.119.111", "path": "trailer" },
            { "name": "Anime Ost / Score", "host": "http://79.111.119.111", "path": "anime" },
            { "name": "Love Songs", "host": "http://213.141.131.10", "path": "lovesongs" },
            { "name": "Singer - Songwriter", "host": "http://213.141.131.10", "path": "singersongwriter" },
            { "name": "Acoustic & Unplugged", "host": "http://213.141.131.10", "path": "acoustic" },
            { "name": "Healing Music (Yoga, Reiki, Zen, ...)", "host": "http://213.141.131.10", "path": "healing" },
            { "name": "60's Collection", "host": "http://213.141.131.10", "path": "60collection" },
            { "name": "70's Collection", "host": "http://213.141.131.10", "path": "70collection" },
            { "name": "80's Collection", "host": "http://79.120.39.202", "path": "pop80" },
            { "name": "90's Collection", "host": "http://213.141.131.10", "path": "90collection" },
            { "name": "2000's Collection", "host": "http://79.120.12.130", "path": "00collection" },
            { "name": "Prog Related", "host": "http://79.111.14.76", "path": "progrelated" },
        ]
    }
]

// Radio Paradise - High quality, human-curated eclectic radio (ad-free)
var radioParadiseCategories = [
    {
        "name": "🎧 Radio Paradise Mixes",
        "stations": [
            { "name": "Main Mix - Eclectic Blend", "host": "https://stream.radioparadise.com", "path": "aac-320", "description": "RP's steep selection of steep tracks - Music from all genres expertly blended" },
            { "name": "Mellow Mix - Relaxed Vibes", "host": "https://stream.radioparadise.com", "path": "mellow-320", "description": "A mellower mix for relaxation and focus" },
            { "name": "Rock Mix - Guitar-Driven", "host": "https://stream.radioparadise.com", "path": "rock-320", "description": "Classic and modern rock selections" },
            { "name": "Global Mix - World & Eclectic", "host": "https://stream.radioparadise.com", "path": "eclectic-320", "description": "World music and eclectic global sounds" }
        ]
    }
]

// FIP (Radio France) - French public radio with diverse genre channels (ad-free)
var fipCategories = [
    {
        "name": "🇫🇷 FIP Radio Channels",
        "stations": [
            { "name": "FIP Main - Eclectic Mix", "host": "https://icecast.radiofrance.fr", "path": "fip-midfi.mp3", "description": "FIP's signature eclectic blend of jazz, rock, world, and electronic" },
            { "name": "FIP Rock", "host": "https://icecast.radiofrance.fr", "path": "fiprock-midfi.mp3", "description": "Rock music from classics to contemporary" },
            { "name": "FIP Jazz", "host": "https://icecast.radiofrance.fr", "path": "fipjazz-midfi.mp3", "description": "Jazz from swing to fusion to contemporary" },
            { "name": "FIP Groove - Funk & Soul", "host": "https://icecast.radiofrance.fr", "path": "fipgroove-midfi.mp3", "description": "Funk, soul, R&B and groove" },
            { "name": "FIP Monde - World Music", "host": "https://icecast.radiofrance.fr", "path": "fipworld-hifi.aac", "description": "World music from across the globe" },
            { "name": "FIP Electro", "host": "https://icecast.radiofrance.fr", "path": "fipelectro-midfi.mp3", "description": "Electronic music and beats" },
            { "name": "FIP Pop", "host": "https://icecast.radiofrance.fr", "path": "fippop-midfi.mp3", "description": "Pop music selections" },
            { "name": "FIP Reggae", "host": "https://icecast.radiofrance.fr", "path": "fipreggae-midfi.mp3", "description": "Reggae, dub, and Caribbean sounds" },
            { "name": "FIP Hip-Hop", "host": "https://icecast.radiofrance.fr", "path": "fiphiphop-midfi.mp3", "description": "Hip-hop and rap selections" },
            { "name": "FIP Metal", "host": "https://icecast.radiofrance.fr", "path": "fipmetal-midfi.mp3", "description": "Metal and heavy music" },
            { "name": "FIP Nouveautés - New Releases", "host": "https://icecast.radiofrance.fr", "path": "fipnouveautes-midfi.mp3", "description": "Fresh new music releases" },
            { "name": "FIP Sacré Français", "host": "https://icecast.radiofrance.fr", "path": "fipsacrefrancais-midfi.mp3", "description": "French music classics and contemporary" }
        ]
    }
]

// Misc Categories - Curated internet radio stations (mix of independent and commercial)
var miscCategories = [
    {
        "name": "🌙 Ambient / Drone",
        "stations": [
            { "name": "Ambient Sleeping Pill - Deep Ambient", "host": "https://radio.stereoscenic.com", "path": "asp-h", "description": "Beat-free ambient for sleep and relaxation - 256kbps" },
            { "name": "Echoes of Bluemars - Cryosleep", "host": "http://streams.echoesofbluemars.org:8000", "path": "cryosleep", "description": "Zero-beat space ambient for the space traveler" },
            { "name": "Echoes of Bluemars - Bluemars", "host": "http://streams.echoesofbluemars.org:8000", "path": "bluemars", "description": "Atmospheric ambient electronic music" },
            { "name": "Planet Ambi HD", "host": "http://philae.shoutca.st:9019", "path": "stream", "description": "High-definition ambient and drone music - 320kbps" },
            { "name": "Drone Radio (MRG.fm)", "host": "http://listen.mrg.fm:8070", "path": "stream", "description": "Drone and deep ambient - experimental electronic - 128kbps" },
            { "name": "Intergalactic FM - Dream Machine", "host": "http://radio.intergalactic.fm", "path": "3", "description": "Ambient, soundtracks, exotica - 256kbps" }
        ]
    },
    {
        "name": "🎧 ASMR",
        "stations": [
            { "name": "Radio ASMR", "host": "https://live.lofiradio.ru", "path": "asmr_mp3_320", "description": "24/7 ASMR streaming - 320kbps" },
            { "name": "Chris TDL Radio ASMR", "host": "https://stream.zeno.fm", "path": "mwpb4ea6qs8uv", "description": "ASMR radio channel - 128kbps" },
            { "name": "Radio Whisper ASMR", "host": "https://stream.zeno.fm", "path": "309e0b84p48uv", "description": "Whispered ASMR content - 128kbps" },
            { "name": "Positively ASMR Crackling Fire", "host": "https://drive.uber.radio", "path": "uber/asmrmix/icecast.audio", "description": "No DJs, no interruptions - crackling fire sounds" },
            { "name": "Positively ASMR Mouth Sounds", "host": "https://drive.uber.radio", "path": "uber/asmrmouthsounds/icecast.audio", "description": "No DJs, no interruptions - mouth sounds ASMR" },
            { "name": "Positively ASMR Sleep", "host": "https://drive.uber.radio", "path": "uber/asmrsleep/icecast.audio", "description": "No DJs, no interruptions - sleep ASMR triggers" }
        ]
    },
    {
        "name": "🎹 Synthwave / Retrowave",
        "stations": [
            { "name": "Nightride FM - Synthwave", "host": "https://stream.nightride.fm", "path": "nightride.mp3", "description": "24/7 synthwave and retrowave - 320kbps" },
            { "name": "Nightride FM - Chillsynth", "host": "https://stream.nightride.fm", "path": "chillsynth.mp3", "description": "Chillsynth and chillwave instrumental - 320kbps" },
            { "name": "Nightride FM - Darksynth", "host": "https://stream.nightride.fm", "path": "darksynth.mp3", "description": "Dark cyberpunk synthwave - 320kbps" },
            { "name": "Nightride FM - Spacesynth", "host": "https://stream.nightride.fm", "path": "spacesynth.mp3", "description": "Spacesynth, space-disco, vocoder music - 320kbps" },
            { "name": "Retrowave.One Radio", "host": "http://77.108.192.88:8000", "path": "stream", "description": "80s, chillsynth, cyberpunk, darksynth, outrun - 192kbps" }
        ]
    },
    {
        "name": "🌊 Vaporwave / Future Funk",
        "stations": [
            { "name": "Nightwave Plaza - Vaporwave", "host": "https://radio.plaza.one", "path": "mp3", "description": "24/7 vaporwave and future funk radio" },
            { "name": "Yumi Co. Radio", "host": "https://yumicoradio.net", "path": "stream", "description": "Future funk, city pop, nu disco, vaporwave - 256kbps" }
        ]
    },
    {
        "name": "🔊 Techno / House",
        "stations": [
            { "name": "Techno.FM - Pure Techno", "host": "http://stream.techno.fm", "path": "radio1-320k.mp3", "description": "Pure techno radio - 320kbps" },
            { "name": "Technolovers - Deep House", "host": "https://stream.technolovers.fm", "path": "deep-house", "description": "Underground deep house from Germany - 192kbps" },
            { "name": "1.FM - Deep House Radio", "host": "http://strm112.1.fm", "path": "deephouse_mobile_mp3", "description": "Curated deep house from Switzerland - 192kbps" },
            { "name": "Party Vibe Radio - House", "host": "http://www.partyviberadio.com:8046", "path": "stream/2/", "description": "UK community house music radio - 320kbps" },
            { "name": "Technolocos - Deep Web Radio", "host": "https://technolocos.net", "path": "listen/technolocos/radio.mp3", "description": "Underground techno, tech house, minimal - 320kbps" },
            { "name": "Radio Schizoid - Dub Techno", "host": "http://94.130.113.214:8000", "path": "dubtechno", "description": "24/7 dub techno from Mumbai - 128kbps" },
            { "name": "Anima Amoris - Dub Techno", "host": "http://amoris.sknt.ru", "path": "dubtechno", "description": "Dub techno from Saint-Petersburg since 2002 - 256kbps AAC" },
            { "name": "Rautemusik - Techno", "host": "https://streams.rautemusik.fm", "path": "techno/mp3-192/", "description": "German techno network with dub and minimal - 192kbps" },
            { "name": "Party Vibe Radio - Techno", "host": "http://www.partyviberadio.com:8046", "path": "stream/1/", "description": "UK community techno radio - 320kbps" },
            { "name": "CYBERStacja - Electronic", "host": "https://sc.cyberstacja.pl", "path": "listen/cyberstacja/radio.mp3", "description": "Polish electronic, house, techno - 192kbps" },
            { "name": "Intergalactic FM - Electro", "host": "http://radio.intergalactic.fm", "path": "1", "description": "Cult techno and electro from The Hague" },
            { "name": "Intergalactic FM - Disco Fetish", "host": "http://radio.intergalactic.fm", "path": "2", "description": "Disco, Italo disco, nu-disco" },
            { "name": "Deep Radio", "host": "http://stream.deep.radio", "path": "hd", "description": "Deep house, progressive house, tech house - 320kbps" },
            { "name": "ISEKOI Radio", "host": "https://public.isekoi-radio.com", "path": "listen/chill/radio.mp3", "description": "Electronic - house, liquid funk, phonk" },
            { "name": "Cashmere Radio - Berlin Underground", "host": "https://cashmereradio.out.airtime.pro", "path": "cashmereradio_a", "description": "Berlin community radio - underground electronic" }
        ]
    },
    {
        "name": "🌀 Trance / Hard Dance",
        "stations": [
            { "name": "Party Vibe Radio - Trance", "host": "http://www.partyviberadio.com:8046", "path": "stream/3/", "description": "Classic and progressive trance - 320kbps" },
            { "name": "Rautemusik - Trance", "host": "https://trance-high.rautemusik.fm", "path": "", "description": "German trance radio - progressive, vocal, psy - 192kbps" },
            { "name": "Trance-Energy Radio", "host": "http://radio.trance-energy.org:8000", "path": "trance192", "description": "Dedicated trance station - 192kbps" },
            { "name": "Intense Radio - Hard Dance", "host": "https://intenseradio.live-streams.nl:18000", "path": "live", "description": "Amsterdam hard dance, trance, progressive - 192kbps" }
        ]
    },
    {
        "name": "🍄 Psytrance / Goa",
        "stations": [
            { "name": "Psyndora Psytrance - Goa, Full-On, Progressive", "host": "https://cast.magicstreams.gr:9111", "path": "stream/1/", "description": "Greek psytrance station - Goa, full-on, and progressive psy 24/7" },
            { "name": "PsyStream - Hi-Fi Psytrance", "host": "https://radio.psymusic.co.uk", "path": "listen/psystream/hifi.mp3", "description": "UK psytrance station - High quality 320kbps stream" },
            { "name": "PsyRadio.fm Progressive", "host": "http://komplex2.psyradio.org:8010", "path": "stream/1/", "description": "Progressive psytrance and psychedelic electronic music" },
            { "name": "Psychedelic Freaks Radio", "host": "https://radio.psyfreaks.com", "path": "listen/psyfreaks/radio.mp3", "description": "Community-driven psytrance radio" },
            { "name": "DMT-FM - All Psy Genres", "host": "https://dc1.serverse.com", "path": "proxy/ywycfrxn/stream", "description": "Psytrance, Goa, Full-On, Dark, Forest, Hi-Tech, Chillout and more" },
            { "name": "DiceRadio - Goa/Psytrance", "host": "https://s2.radio.co", "path": "s4648f1c61/listen", "description": "Full-on Goa psytrance DJ sets from Greece - 128kbps" },
            { "name": "RadiOzora Chill", "host": "http://chill.out.airtime.pro:8000", "path": "chill_a", "description": "Psychill from the Ozora Festival community - 192kbps" },
            { "name": "1.FM - Psychill", "host": "http://strm112.1.fm", "path": "ambientpsy_mobile_mp3", "description": "Psychedelic chillout and slow trance - 320kbps" },
            { "name": "Psyndora - Psychill", "host": "http://cast.magicstreams.gr:9125", "path": "stream", "description": "Psychill, psybient, ethnic from Greece - 128kbps" }
        ]
    },
    {
        "name": "🥁 Drum & Bass / UK Bass",
        "stations": [
            { "name": "Bassdrive - Drum & Bass", "host": "http://ice.bassdrive.net", "path": "stream", "description": "Worldwide drum and bass since 2001 - 192kbps" },
            { "name": "DNBRadio", "host": "http://ildnb1.dnbradio.com:8000", "path": "dnbradio_main.mp3", "description": "24/7 drum & bass since 2003 - neurofunk, jungle, liquid - 320kbps" },
            { "name": "Brokenbeats", "host": "https://stream.brokenbeats.net", "path": "tune", "description": "Atmospheric DnB, liquid funk, acid jazz, jungle - 320kbps AAC" },
            { "name": "Energy 1058", "host": "http://tachyon.shoutca.st:8590", "path": "stream", "description": "DnB, oldskool, jungle - ex-pirate radio - 320kbps" },
            { "name": "Partyvibe DnB", "host": "https://www.partyviberadio.com:8061", "path": ";", "description": "Commercial-free drum and bass, jungle - 320kbps" },
            { "name": "Breaking Bass Air", "host": "https://aircast.breaking-bass.ru:8443", "path": "air", "description": "Underground DnB - liquid, neurofunk, darkstep - 320kbps" },
            { "name": "Jungle Planet Radio", "host": "https://phoebe.streamerr.co:3650", "path": ";", "description": "Jungle, drum & bass, bass music - 320kbps" },
            { "name": "Chunt FM", "host": "https://fm.chunt.org", "path": "stream", "description": "DnB, house, jungle, soul, techno, UK garage - 320kbps" },
            { "name": "Kniteforce Radio", "host": "https://kniteforce.out.airtime.pro", "path": "kniteforce_a", "description": "From Kniteforce Records - DnB, hardcore, jungle - 192kbps" },
            { "name": "Sub FM", "host": "https://fmsub.radioca.st", "path": "stream?type=http&nocache=140", "description": "Bass music - dubstep, garage, grime, juke - 192kbps" },
            { "name": "UK Bass Radio", "host": "https://www.ukbassradio.com", "path": "stream", "description": "Full UK bass spectrum - DnB, garage, dubstep - 192kbps" },
            { "name": "Kool FM", "host": "https://admin.stream.rinse.fm", "path": "proxy/kool/stream", "description": "Legendary London pirate - DnB, jungle, ragga - 128kbps" },
            { "name": "Algorythme UK Garage", "host": "https://ukg.algorythmeradio.com", "path": "stream", "description": "Dedicated UK garage and garage house - 128kbps" },
            { "name": "Rinse FM - UK Garage & Bass", "host": "https://admin.stream.rinse.fm", "path": "proxy/rinse_uk/stream", "description": "London community radio - UK garage, grime, bass music" },
            { "name": "I Like It Oldskool", "host": "https://ilikeitoldskool.radioca.st", "path": "stream", "description": "Oldskool dance - hardcore, house, jungle - 320kbps" }
        ]
    },
    {
        "name": "🎸 Rock / Alternative",
        "stations": [
            { "name": "KEXP Seattle", "host": "https://kexp.streamguys1.com", "path": "kexp160.aac", "description": "Indie rock with live sessions - 160kbps" },
            { "name": "181.FM The Buzz - Alternative", "host": "http://listen.181fm.com", "path": "181-buzz_128k.mp3?noPreRoll=true", "description": "Alternative rock hits 90s to today" },
            { "name": "WFMU - Freeform Radio", "host": "http://stream0.wfmu.org", "path": "freeform-128k", "description": "America's longest-running freeform station" },
            { "name": "NTS Radio", "host": "https://stream-relay-geo.ntslive.net", "path": "stream", "description": "Freeform radio from 50+ cities - eclectic underground" },
            { "name": "Resonance FM", "host": "https://stream.resonance.fm", "path": "resonance", "description": "London arts radio - experimental, avant-garde" },
            { "name": "Rockabilly Radio", "host": "http://lin3.ash.fast-serv.com:6026", "path": "stream_96", "description": "Classic 50s rockabilly and rock'n'roll 24/7 - 128kbps" },
            { "name": "Surf Rock Radio", "host": "http://139.162.89.191:8020", "path": "radio.mp3", "description": "World's No.1 surf music station - 128kbps" },
            { "name": "XRaydio 3", "host": "https://xraydio.ddns.net", "path": "xraydio3", "description": "Garage rock, psychobilly, surf, glam, sludge - 160kbps" },
            { "name": "Mixabilly Radio", "host": "http://mars.streamerr.co:8142", "path": "stream", "description": "Rockabilly, psychobilly, punkabilly, garage punk - 192kbps" }
        ]
    },
    {
        "name": "🎵 Pop / Indie / Shoegaze",
        "stations": [
            { "name": "The Current MPR - Minnesota Indie", "host": "http://current.stream.publicradio.org", "path": "kcmp.mp3", "description": "Minnesota Public Radio indie rock/pop" },
            { "name": "BAGeL Radio - Alternative", "host": "http://ais-sa3.cdnstream1.com", "path": "2606_128.mp3", "description": "Underground alternative since 2003" },
            { "name": "Birch Street Radio - Adult Alt", "host": "https://jenny.torontocast.com:8172", "path": "stream", "description": "Adult album alternative and indie" },
            { "name": "dublab LA - Progressive", "host": "https://dublab.out.airtime.pro", "path": "dublab_a", "description": "LA non-profit progressive music collective" },
            { "name": "IndieXL Amsterdam", "host": "http://server-23.stream-server.nl:8438", "path": "stream/1/", "description": "24/7 indie music - 320kbps" },
            { "name": "The Zone Dublin - New Music", "host": "https://uk1.internet-radio.com", "path": "proxy/thezone?mp=/stream", "description": "Dublin's new music alternative" },
            { "name": "DKFM Classic - Shoegaze", "host": "https://radio.streemlion.com:4245", "path": "stream", "description": "MBV, Slowdive, Cocteau Twins - first wave shoegaze - 128kbps" },
            { "name": "Laut.FM Shoegaze", "host": "https://shoegaze.stream.laut.fm", "path": "shoegaze", "description": "Shoegaze, dream pop, ambient, post-punk - 128kbps" },
            { "name": "6forty Radio", "host": "http://radio.6forty.com:8000", "path": "6forty", "description": "Deep indie, post-rock, post-metal, shoegaze - 192kbps" },
            { "name": "XRaydio 1", "host": "https://xraydio.ddns.net", "path": "live", "description": "Dream pop, shoegaze, psychedelic, post punk - 160kbps" },
            { "name": "Bristol Sound Webradio", "host": "https://thebristolsoundwebradio.stream.laut.fm", "path": "thebristolsoundwebradio", "description": "Trip-hop - Massive Attack, Portishead vibes - 128kbps" }
        ]
    },
    {
        "name": "✊ Punk / Hardcore",
        "stations": [
            { "name": "Anarchy Factory", "host": "http://cheetah.streemlion.com:2820", "path": "stream", "description": "24hr punk/hardcore/ska/crust/sludge/grunge - 320kbps" },
            { "name": "Punkrockers Radio", "host": "http://stream.punkrockers-radio.de:8000", "path": "mp3", "description": "Germany's DIY punk radio since 2002 - 192kbps" },
            { "name": "PunkRockRadio.ca", "host": "https://stream.radio.co", "path": "s904013bb1/listen", "description": "Canadian punk and post-punk from Quebec - 192kbps" },
            { "name": "Punk Irratia", "host": "https://punkirratia.net:8443", "path": "punk", "description": "Basque Country punk and hardcore - 192kbps" },
            { "name": "Real Punk Radio", "host": "http://149.56.155.73:8080", "path": "stream", "description": "Brooklyn punk rock'n'roll, garage, surf - 128kbps" },
            { "name": "Rock Antenne Punkrock", "host": "https://s3-webradio.rockantenne.de", "path": "punkrock/stream/mp3", "description": "Dedicated punk rock channel - 128kbps" },
            { "name": "Athens Noise Rocks", "host": "https://radio.athensnoise.rocks", "path": "listen/athensnoise.rocks/radio.mp3", "description": "Crust, hardcore, post-hardcore, punk, ska punk - 128kbps" }
        ]
    },
    {
        "name": "🤘 Metal / Hard Rock",
        "stations": [
            { "name": "Rock Antenne Heavy Metal", "host": "https://stream.rockantenne.de", "path": "heavy-metal/stream/mp3", "description": "German 24/7 heavy metal radio" },
            { "name": "La Grosse Radio Metal", "host": "http://hd.lagrosseradio.info:8000", "path": "lagrosseradio-metal-192.mp3", "description": "French metal - death, black, thrash - 192kbps" },
            { "name": "Violent Forces Radio - Thrash", "host": "http://www.tuneintoradio1.com:8000", "path": "128kbps.mp3", "description": "Dedicated thrash metal specialists" },
            { "name": "Tangra Mega Rock - Bulgarian Metal", "host": "http://restreamer.radiotangra.com:80", "path": "Tangra-high", "description": "Bulgaria's first rock/metal station" },
            { "name": "Port Rock Radio - High Quality", "host": "http://65.109.84.248:8100", "path": "portrock-320.mp3", "description": "Hard rock and metal - 320kbps" },
            { "name": "Metal Devastation Radio", "host": "http://c13.radioboss.fm:8099", "path": "autodj", "description": "Underground death, black, thrash, doom" },
            { "name": "TotalRock UK", "host": "http://s3.citrus3.com:8056", "path": "stream", "description": "UK rock and metal since 1997" },
            { "name": "Megarock Radio", "host": "http://stream6.megarockradio.net:8000", "path": "stream", "description": "24/7 rock and metal" },
            { "name": "The Voice of Doom", "host": "https://streaming.galaxywebsolutions.com:9046", "path": "stream", "description": "Pure doom metal - studio quality - 320kbps AAC" },
            { "name": "Gritty Rock Radio", "host": "https://listen.radioking.com", "path": "radio/10713/stream/224413", "description": "Curated stoner/desert/garage rock - 192kbps" },
            { "name": "Heavy Music Atmospheric", "host": "http://stream.heavy-music.net:8176", "path": "stream", "description": "Atmospheric doom, gothic, post-rock since 2004 - 320kbps" },
            { "name": "Exclusive Radio - Black Sabbath", "host": "https://streaming.exclusive.radio", "path": "er/blacksabbath/icecast.audio", "description": "24/7 Black Sabbath - the godfathers of doom" }
        ]
    },
    {
        "name": "🦇 Goth / Darkwave / Industrial",
        "stations": [
            { "name": "Radio Arcane", "host": "https://quincy.torontocast.com:1100", "path": "stream", "description": "Goth, darkwave, post-punk, coldwave, deathrock - 320kbps" },
            { "name": "Bloodlit Radio", "host": "https://usa5.fastcast4u.com", "path": "proxy/wwwblood?mp=/1", "description": "Very dark alternative - industrial, goth, darkwave - 320kbps" },
            { "name": "Nightride FM - EBSM", "host": "https://stream.nightride.fm", "path": "ebsm.mp3", "description": "EBM, industrial, synthwave, darksynth - 320kbps" },
            { "name": "SoundWorks Radio", "host": "https://soundworks.live:8000", "path": "radio.mp3", "description": "Industrial, EBM, witch house, dark ambient, neofolk - 320kbps" },
            { "name": "Cabaret del Diavolo", "host": "https://stream.zeno.fm", "path": "qrbdvnz0qa0uv", "description": "EBM, industrial, dark electro, aggrotech - est. 2005 - 320kbps" },
            { "name": "HEXX 9 Radio", "host": "http://46.105.124.120:8604", "path": "stream", "description": "Ambient, electronic, experimental, goth, witchhouse - 256kbps" },
            { "name": "Detroit Industrial Underground", "host": "http://138.197.0.4:8000", "path": "stream", "description": "Industrial, EBM, synthpop from Detroit - 256kbps" },
            { "name": "Iceradio Germany", "host": "https://www.iceradio.net", "path": "listen", "description": "Dark scene - darkwave, EBM, industrial, futurepop - 192kbps" },
            { "name": "Witch House on WaveRadio", "host": "https://station.waveradio.org", "path": "witch", "description": "Dedicated witch house / experimental - 192kbps AAC" },
            { "name": "Esoterica Radio - Dark Electro", "host": "https://esoterica.servemp3.com:444", "path": "listen/darkclubbing_darkelectro/radio.mp3", "description": "Dark clubbing, dark electro channel - 192kbps" },
            { "name": "GothVille Radio", "host": "https://streams.radio.co", "path": "s62583474c/listen", "description": "24/7 gothic, new wave, EBM, dark folk - 128kbps" },
            { "name": "Dark Asylum Radio", "host": "https://443-1.autopo.st", "path": "196", "description": "Synthpop, futurepop, goth, industrial - since 2000 - 128kbps" },
            { "name": "Dark Wave Radomir Radio", "host": "https://dwrstream.eu", "path": "", "description": "Darkwave, post-punk, experimental, noise, avant-garde - 192kbps" }
        ]
    },
    {
        "name": "🎺 Blues / Funk / Soul",
        "stations": [
            { "name": "TopBlues - Nothin But The Blues", "host": "https://us3.internet-radio.com", "path": "proxy/topblues?mp=/stream", "description": "24/7 blues from Tucson since 1977 - 320kbps" },
            { "name": "A Mississippi Blues - Delta Heritage", "host": "https://radiosuitenetwork.torontocast.stream", "path": "amississippiblues/", "description": "Blues history from 1900 to present - 320kbps" },
            { "name": "XRDS.fm - The Crossroads", "host": "https://us1.internet-radio.com", "path": "proxy/xrds?mp=/stream", "description": "Blues from Clarksdale, Mississippi - birthplace of the blues" },
            { "name": "BluesMusicFan Radio", "host": "https://orbit.citrus3.com:8052", "path": "stream", "description": "Commercial-free blues since 2014 - 320kbps" },
            { "name": "WWOZ New Orleans - Jazz & Heritage", "host": "http://wwoz-sc.streamguys.com", "path": "wwoz-hi.mp3", "description": "New Orleans jazz, funk, soul, brass band, zydeco" },
            { "name": "Funky Radio Italy - Classic Funk", "host": "http://funkyradio.streamingmedia.it:8001", "path": "play.mp3", "description": "Classic funk 1963-1982 vinyl rarities - 320kbps" },
            { "name": "Soul Radio Classics - Vintage Soul", "host": "http://listen.soulradioclassics.com:8200", "path": "play", "description": "Motown, Chicago, Philadelphia soul - 192kbps" },
            { "name": "The Disco Palace - Disco & Funk", "host": "http://54.36.165.156:8410", "path": "stream/1/", "description": "Complete disco collection with rare promos - 320kbps" },
            { "name": "The BocX", "host": "https://radio.streemlion.com:4820", "path": "stream", "description": "Jazzy, funky, soulful chill-out - blues, funk, neo-soul - 256kbps" },
            { "name": "Funky Corner Radio", "host": "https://ais-sa2.cdnstream1.com", "path": "2447_192.mp3", "description": "Funk, soul, R&B, disco from 70s and 80s - 192kbps" },
            { "name": "SOUL RADIO Classics", "host": "https://listen.soulradio.uk", "path": "uk", "description": "Golden era classic soul 50s/60s/70s - 192kbps" },
            { "name": "NPO Soul & Jazz", "host": "http://icecast.omroep.nl", "path": "radio6-bb-mp3", "description": "Dutch public radio - soul, jazz, R&B, neo-soul - 192kbps" },
            { "name": "1.FM - Slow Jamz Radio", "host": "http://strm112.1.fm", "path": "slowjamz_mobile_mp3", "description": "R&B slow jams, neo-soul, smooth grooves - 192kbps" }
        ]
    },
    {
        "name": "🎷 Jazz",
        "stations": [
            { "name": "Jazz24 KNKX - World-Class Jazz", "host": "https://knkx-live-a.edge.audiocdn.com", "path": "6285_256k", "description": "Pacific Northwest jazz radio - 256kbps" },
            { "name": "WBGO Jazz 88.3 - America's Jazz", "host": "https://ais-sa8.cdnstream1.com", "path": "3629_128.mp3", "description": "New York/Newark premier jazz since 1979" },
            { "name": "TSF Jazz Paris", "host": "https://tsfjazz.ice.infomaniak.ch", "path": "tsfjazz-high.mp3", "description": "100% jazz 24 hours from Paris" },
            { "name": "Naim Jazz - Audiophile", "host": "https://mscp3.live-streams.nl:8342", "path": "jazz-high.aac", "description": "British audiophile jazz - 320kbps" },
            { "name": "Concertzender Jazz", "host": "https://streams.greenhost.nl:8006", "path": "jazz", "description": "Dutch public radio jazz - 256kbps" }
        ]
    },
    {
        "name": "🎤 Hip-Hop / Rap",
        "stations": [
            { "name": "181.FM Old School Hip-Hop", "host": "http://listen.181fm.com", "path": "181-oldschool_128k.mp3?noPreRoll=true", "description": "Classic 90s hip-hop and R&B" },
            { "name": "Party Vibe Radio Hip-Hop", "host": "http://www.partyviberadio.com:8016", "path": "stream/2/", "description": "Hip-hop, trap, urban - 320kbps" },
            { "name": "Memphis Rap Radio", "host": "http://142.4.216.144:8089", "path": "stream/1/", "description": "Memphis rap and Southern hip-hop" },
            { "name": "Urban Radio Italy", "host": "http://nr3.newradio.it:8100", "path": "stream", "description": "Urban, hip-hop, R&B - 192kbps" },
            { "name": "FunkaGroove - Funk & Hip-Hop", "host": "http://94.23.57.5:9063", "path": "stream/1/", "description": "Funk and hip-hop fusion - 192kbps" },
            { "name": "REYFM Lo-Fi Hip Hop", "host": "https://listen.reyfm.de", "path": "lofi_320kbps.mp3", "description": "Lo-fi hip hop beats - 320kbps" },
            { "name": "I Love Chillhop", "host": "https://ilm.stream35.radiohost.de", "path": "ilm_ilovechillhop_mp3-192", "description": "Lo-fi hip hop and chillhop for study - 192kbps" },
            { "name": "b3cks-radio - Chillhop", "host": "https://radio.b3ck.com", "path": "listen/b3cks-radio/radio.mp3", "description": "Lo-fi hip hop beats from Minnesota - 192kbps" },
            { "name": "0nlineradio Lo-Fi Hip Hop", "host": "https://stream.0nlineradio.com", "path": "lo-fi", "description": "Lo-fi hip hop beats - 192kbps" }
        ]
    },
    {
        "name": "🌴 Reggae / Ska / Dub",
        "stations": [
            { "name": "La Grosse Radio Reggae", "host": "http://hd.lagrosseradio.info:8000", "path": "lagrosseradio-reggae-192.mp3", "description": "French reggae station since 2009 - 192kbps" },
            { "name": "181.FM Reggae Roots", "host": "http://relay.181.fm:8096", "path": "?noPreRoll=true", "description": "Roots reggae and classic Jamaican sounds" },
            { "name": "Party Vibe Radio Reggae", "host": "http://www.partyvibe.com:8000", "path": "pvr-reggae-mp3", "description": "Dancehall, dub, roots - 320kbps" },
            { "name": "Roots Legacy Radio - Dub", "host": "https://l.rootslegacy.fr", "path": "", "description": "French dub and reggae specialist - 224kbps" },
            { "name": "Bob's Ska Radio", "host": "http://51.255.235.165:5528", "path": "stream", "description": "Ska, punk, reggae, rocksteady from Tacoma WA - 128kbps" },
            { "name": "Jah Music Mansion - Roots & World", "host": "http://94.23.67.172:9209", "path": "stream/1/", "description": "Reggae, dub, world roots - 320kbps" }
        ]
    },
    {
        "name": "🌍 African Music",
        "stations": [
            { "name": "Afropulse FM - African Pop", "host": "https://cp12.serverse.com", "path": "proxy/densma/stream", "description": "Contemporary African music and afrobeats from Atlanta" },
            { "name": "Radio Thiossane - West African", "host": "http://listen.senemultimedia.net:8110", "path": "stream/1/", "description": "Senegalese and West African music - 192kbps" },
            { "name": "Technolovers - Afro House", "host": "https://stream.technolovers.fm", "path": "afro-house", "description": "24/7 Afro house, soulful house, Afro vocal - 192kbps" },
            { "name": "WDR COSMO Afrobeats", "host": "https://wdr-cosmo-afrobeat.icecastssl.wdr.de", "path": "wdr/cosmo/afrobeat/mp3/128/stream.mp3", "description": "German public radio Afrobeats channel - 128kbps" },
            { "name": "Africa N.1 Rumba", "host": "https://webradio1.ice.infomaniak.ch", "path": "webradio4-128.mp3", "description": "Rumba Congolaise, soukous, ndombolo - 128kbps" },
            { "name": "Dakar Musique", "host": "http://listen.senemultimedia.net:8090", "path": "stream", "description": "Mbalax, zouk, reggae from Dakar, Senegal - 128kbps" }
        ]
    },
    {
        "name": "🕌 Middle Eastern / Arabic",
        "stations": [
            { "name": "RauteMusik Oriental", "host": "https://oriental-high.rautemusik.fm", "path": "", "description": "Arabic hits, Oriental, Middle Eastern variety - 192kbps" },
            { "name": "Djam Radio Paris", "host": "https://stream9.xdevel.com", "path": "audio1s976748-1515/stream/icecast.audio", "description": "Paris world music - Oriental, Afrobeat, funk, soul - 192kbps AAC" },
            { "name": "Epic Lounge - Shisha Lounge", "host": "https://stream.epic-lounge.com", "path": "shisha-lounge", "description": "Oriental lounge, Middle Eastern chill, Arabic downtempo - 192kbps" },
            { "name": "lbi Radio - Lebanese", "host": "http://andromeda.shoutca.st:8192", "path": ";stream.mp3", "description": "Arabic, Middle Eastern, Lebanese music - 128kbps" },
            { "name": "SumerFm Iraq", "host": "https://l3.itworkscdn.net", "path": "itwaudio/9012/stream", "description": "Iraqi Arabic music from Baghdad - 128kbps" }
        ]
    },
    {
        "name": "🏮 Asian Pop / City Pop",
        "stations": [
            { "name": "BOX: Japan City Pop", "host": "https://play.streamafrica.net", "path": "japancitypop", "description": "Japanese City Pop classics 70s/80s/90s" },
            { "name": "Jazz Sakura - Asia DREAM Radio", "host": "http://kathy.torontocast.com:3330", "path": "stream/1/", "description": "Japanese jazz and J-jazz fusion - 128kbps" },
            { "name": "LISTEN.moe K-Pop", "host": "https://listen.moe", "path": "kpop/stream", "description": "Community K-Pop radio - 256kbps OGG" },
            { "name": "Big B Radio - KPOP", "host": "https://antares.dribbcast.com", "path": "proxy/kpop?mp=/s", "description": "Curated K-Pop since 2004 - 192kbps" },
            { "name": "Big B Radio - JPOP", "host": "https://antares.dribbcast.com", "path": "proxy/jpop?mp=/s", "description": "Japanese pop and J-Pop hits - 192kbps" },
            { "name": "Ronin Radio", "host": "https://s3.radio.co", "path": "sff133d65b/listen", "description": "Anime music, city pop, eurobeat, J-Rock - 128kbps" }
        ]
    },
    {
        "name": "💃 Latin / Bossa / World",
        "stations": [
            { "name": "Concertzender World Music", "host": "https://streams.greenhost.nl:8006", "path": "wereldmuziek", "description": "Dutch public radio world music - 160kbps" },
            { "name": "liveIreland - Celtic Traditional", "host": "http://192.111.140.11:8058", "path": "stream/1/", "description": "24/7 Celtic music from Ireland, Scotland, Wales" },
            { "name": "Hawaiian Radio - Pacific Sounds", "host": "http://198.178.123.17:10108", "path": "stream/1/", "description": "Traditional and contemporary Hawaiian - 192kbps" },
            { "name": "Ella Radio - Bossa", "host": "https://stream.ella-radio.de", "path": "ella-bossa/mp3-192/", "description": "24/7 Bossa Nova and jazz from Berlin - 192kbps" },
            { "name": "Ella Radio - Latin Jazz", "host": "https://stream.ella-radio.de", "path": "ella-latin-jazz/mp3-192/", "description": "Afro-Cuban rhythms and tropical jazz - 192kbps" },
            { "name": "Radio Chalaca Callao", "host": "https://conectperu.com", "path": "8084/stream", "description": "Pure salsa and merengue from Peru - 320kbps" },
            { "name": "Tropicalisima Salsa", "host": "http://23.237.150.178:8020", "path": "stream/1/", "description": "Classic salsa and tropical rhythms 24/7 - 128kbps" }
        ]
    },
    {
        "name": "🎻 Classical",
        "stations": [
            { "name": "WCPE - The Classical Station", "host": "http://playerservices.streamtheworld.com", "path": "api/livestream-redirect/WCPE_FM.mp3", "description": "Listener-supported classical since 1982 - North Carolina" },
            { "name": "WQXR - New York Classical", "host": "https://stream.wqxr.org", "path": "wqxr", "description": "New York's premier classical music station" },
            { "name": "WQXR Q2 - Contemporary Classical", "host": "https://q2stream.wqxr.org", "path": "q2", "description": "Classical music by living composers" },
            { "name": "Concertzender Classical", "host": "https://streams.greenhost.nl:8006", "path": "klassiek", "description": "Dutch public radio classical - 256kbps HiFi" },
            { "name": "Concertzender Early Music", "host": "https://streams.greenhost.nl:8006", "path": "oudemuziek", "description": "Medieval and Renaissance music" },
            { "name": "Concertzender Baroque", "host": "https://streams.greenhost.nl:8006", "path": "barok", "description": "Bach, Handel, Vivaldi and baroque masters" },
            { "name": "Ancient FM - Medieval & Renaissance", "host": "http://stream.ancientfm.com:8058", "path": "stream", "description": "Medieval and Renaissance music 24/7" }
        ]
    },
    {
        "name": "🤠 Country / Americana",
        "stations": [
            { "name": "Southern Branch Bluegrass", "host": "http://s7.voscast.com:10664", "path": "stream/1/", "description": "Bluegrass, Americana, Gospel from Tennessee" }
        ]
    },
    {
        "name": "📻 Talk Radio (English)",
        "stations": [
            { "name": "BBC World Service", "host": "http://stream.live.vc.bbcmedia.co.uk", "path": "bbc_world_service", "description": "Global news and current affairs 24/7" },
            { "name": "RNZ National - New Zealand", "host": "https://stream-ice.radionz.co.nz", "path": "National_aac128", "description": "New Zealand public radio news and culture - 128kbps AAC" },
            { "name": "Vermont Public Radio", "host": "https://vpr.streamguys1.com", "path": "vpr96.mp3", "description": "Vermont NPR programming and local news" }
        ]
    }
]

// Genre groups for Misc Stations - provides intermediate navigation level
var miscGenreGroups = [
    { "name": "🌙 Ambient & ASMR", "categories": ["🌙 Ambient / Drone", "🎧 ASMR"] },
    { "name": "🎧 Electronic & Dance", "categories": ["🎹 Synthwave / Retrowave", "🌊 Vaporwave / Future Funk", "🔊 Techno / House", "🌀 Trance / Hard Dance", "🍄 Psytrance / Goa", "🥁 Drum & Bass / UK Bass"] },
    { "name": "🎸 Rock & Alternative", "categories": ["🎸 Rock / Alternative", "🎵 Pop / Indie / Shoegaze", "✊ Punk / Hardcore"] },
    { "name": "🤘 Heavy & Dark", "categories": ["🤘 Metal / Hard Rock", "🦇 Goth / Darkwave / Industrial"] },
    { "name": "🎺 Soul, Jazz & Blues", "categories": ["🎺 Blues / Funk / Soul", "🎷 Jazz", "🎤 Hip-Hop / Rap"] },
    { "name": "🌴 Roots & Reggae", "categories": ["🌴 Reggae / Ska / Dub", "🤠 Country / Americana"] },
    { "name": "🌍 World Music", "categories": ["🌍 African Music", "🕌 Middle Eastern / Arabic", "🏮 Asian Pop / City Pop", "💃 Latin / Bossa / World"] },
    { "name": "🎻 Classical & Talk", "categories": ["🎻 Classical", "📻 Talk Radio (English)"] }
]

// No longer exporting combined categories - use somafmCategories, radcapCategories, radioParadiseCategories, fipCategories, and miscCategories separately
