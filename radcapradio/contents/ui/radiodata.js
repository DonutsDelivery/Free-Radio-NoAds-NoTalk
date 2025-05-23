// Hardcoded radio categories and stations
// This is a partial dataset for demonstration
// Each station has host and path; final URL is host:port/path.format

var categories = [
    {
        name: "ETHNIC / FOLK / SPIRITUAL",
        stations: [
            { name: "Indian Classical/Folk/Ethnic", host: "http://79.111.14.76", path: "indianfolk" },
            { name: "Russian Folk", host: "http://79.120.77.11", path: "russianfolk" },
            { name: "Orthodox Spiritual Music", host: "http://79.111.14.76", path: "orthodox" },
            { name: "Flamenco", host: "http://79.111.14.76", path: "flamenco" },
            { name: "Tango", host: "http://79.120.39.202", path: "tango" }
        ]
    },
    {
        name: "REGGAE / SKA",
        stations: [
            { name: "Reggae", host: "http://79.120.39.202", path: "reggae" },
            { name: "Ska", host: "http://79.111.119.111", path: "ska" },
            { name: "Dub", host: "http://79.111.14.76", path: "dub" }
        ]
    },
    {
        name: "POP",
        stations: [
            { name: "Russian Pop Music", host: "http://79.120.77.11", path: "popru" },
            { name: "K-Pop", host: "http://79.111.119.111", path: "kpop" },
            { name: "Dance Pop", host: "http://79.120.77.11", path: "dancepop" }
        ]
    },
    {
        name: "ROCK",
        stations: [
            { name: "Classic Rock", host: "http://79.120.77.11", path: "rock" },
            { name: "Hard Rock", host: "http://79.111.14.76", path: "hardrock" },
            { name: "Progressive Rock", host: "http://79.111.119.111", path: "progressiverock" }
        ]
    },
    {
        name: "JAZZ",
        stations: [
            { name: "Smooth Jazz", host: "http://79.120.39.202", path: "smoothjazz" },
            { name: "Bebop", host: "http://79.120.12.130", path: "bebop" },
            { name: "Jazz Fusion", host: "http://79.111.119.111", path: "jazzfusion" }
        ]
    },
    {
        name: "METAL",
        stations: [
            { name: "Heavy Metal", host: "http://79.111.14.76", path: "heavymetal" },
            { name: "Thrash Metal", host: "http://79.120.77.11", path: "thrashmetal" },
            { name: "Doom Metal", host: "http://79.111.14.76", path: "doom" }
        ]
    },
    {
        name: "HARDCORE",
        stations: [
            { name: "Deathcore", host: "http://79.111.14.76", path: "deathcore" },
            { name: "Hardcore / Melodic Hardcore", host: "http://79.120.39.202", path: "hardcoretech" },
            { name: "Grindcore", host: "http://79.120.77.11", path: "grindcore" }
        ]
    },
    {
        name: "CLASSICAL",
        stations: [
            { name: "Symphony", host: "http://79.111.14.76", path: "symphony" },
            { name: "Classical Piano", host: "http://79.120.39.202", path: "classpiano" },
            { name: "Opera", host: "http://79.120.39.202", path: "opera" }
        ]
    },
    {
        name: "HIP-HOP / RAP",
        stations: [
            { name: "Hip-Hop", host: "http://79.120.77.11", path: "hiphop" },
            { name: "West Coast Rap", host: "http://79.120.39.202", path: "gangstarap" },
            { name: "Old School Hip-Hop", host: "http://213.141.131.10", path: "oldschoolhiphop" }
        ]
    },
    {
        name: "ELECTRONIC",
        stations: [
            { name: "Techno", host: "http://79.120.77.11", path: "techno" },
            { name: "Trance", host: "http://79.120.77.11", path: "trance" },
            { name: "Ambient", host: "http://79.111.119.111", path: "ambient" }
        ]
    },
    {
        name: "MISCELLANEOUS",
        stations: [
            { name: "Oldies", host: "http://79.120.77.11", path: "oldies" },
            { name: "Anime OST", host: "http://79.111.119.111", path: "anime" },
            { name: "Sounds of Nature", host: "http://79.111.14.76", path: "soundnat" }
        ]
    },
    {
        name: "ШАНСОН",
        stations: [
            { name: "Русский Шансон", host: "http://79.120.77.11", path: "shansonru" },
            { name: "Русский Постшансон", host: "http://79.120.77.11", path: "postshanson" }
        ]
    },
    {
        name: "BLUES / FUNK / SOUL / R&B",
        stations: [
            { name: "Blues", host: "http://79.120.77.11", path: "blues" },
            { name: "Soul", host: "http://79.120.39.202", path: "soul" },
            { name: "Funk", host: "http://79.111.119.111", path: "funk" }
        ]
    },
    {
        name: "COUNTRY",
        stations: [
            { name: "Country", host: "http://79.120.77.11", path: "country" },
            { name: "Bluegrass", host: "http://79.111.14.76", path: "bluegrass" },
            { name: "Alternative Country", host: "http://79.111.119.111", path: "altcountry" }
        ]
    }
];

function getCategories() {
    return categories;
}

