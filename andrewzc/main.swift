//
//  main.swift
//  andrewzc
//
//  Created by Andrew Zamler-Carhart on 7/29/23.
//

import Foundation

let indexPages = ["geography", "buildings", "infrastructure", "music", "nature", "trains", "roadtrips", "people"]
let countryLists = ["citizenship", "european-union", "eurozone", "lefthand", "left-to-right", "marriage", "microstates", "nato", "no-trains", "schengen", "similar-flags"]
let cityLists = ["capitals", "twin-cities", "culture", "divided", "homes", "money-heist", "newcastle", "olympics", "tintin", "aop", "worldsfair", "eurovision", "planned"]
let middleSectionBeen = ["twin-cities", "border-posts", "confluence", "ferries", "metros", "trams", "tripoints"]
let yearPrefix = ["olympics", "worldsfair", "automatic", "gauges", "projects", "left-to-right", "highest", "lowest", "europe-2003", "high-speed", "concerts", "eclipses", "people-movers", "eurovision"]
let topLevelPages = ["bucket", "unesco", "languages", "official-languages", "currency"]
let morePages = ["tv", "cars", "manuals"]
let excludedFiles = ["bingo", "train-facts", "subway", "hiroshima", "no-trains", "john-irving", "band-members", "countdown/index", "america-2022", "america-2023", "pacific-northwest", "brioude", "boundary-stones", "new-england", "eastern-shore", "million-dollars", "song-titles", "music-plants", "music-numbers", "music-colors", "music-tech", "rick-astley", "music-food", "music-animals", "transit-terms", "subway-status/index", "vulkaneifel", "florida"]
let crossLinkedFiles = ["buildings": ["stations"],
                        "nature": ["canals"],
                        "geography": ["international-trams", "international-trains"],
                        "infrastructure": ["trams", "metros"],
                        "trains": ["funiculars", "rail-trails", "useless"],
                        "people": ["artists", "artist-names", "diverse", "guest-singers", "metro-people", "music-people"]]
let personThingPages = ["deaths", "artist-names", "music-origins", "concerts", "music-animals", "backing-bands", "bi-people", "music-cars", "music-colors", "cover-songs", "diverse", "female-bassists", "guest-singers", "music-food", "love-songs", "multi-instrumentalists", "multiple-bands", "music-numbers", "music-people", "music-places", "music-plants", "producers", "trios", "singing-bassists", "singing-drummers", "solo", "songwriters", "music-space", "music-tech", "music-time", "music-trains", "music-water"]
let wikiLocationPages = [
//    "salients",
    "extremities",
//    "trams",
//    "music-places",
//    "olympics",
//    "grand-unions",
//    "tram-roundabouts",
//    "unesco", // check unmatched ones
//    "europe-2003",
//    "aop",
//    "abandoned",
//    "airports",
//    "arches",
//    "automatic",
//    "beaches",
//    "bridges",
//    "cable-cars",
//    "capitals",
//    "castles",
//    "cathedrals",
//    "cities",
//    "cross-platform",
//    "culture",
//    "curved",
//    "disputed",
//    "elevator-stations",
//    "elevators",
//    "enclaves",
//    "endoheric",
//    "europe-2022",
//    "europe-2023",
//    "eurovision",
//    "ferries",
//    "flood",
//    "forts",
//    "france",
//    "funiculars",
//    "greenhouses",
//    "ground-zero",
//    "head-on",
//    "heritage",
//    "highest",
//    "housing",
//    "infill",
//    "lakes",
//    "left-right",
//    "lighthouses",
//    "lowest",
//    "malls",
//    "metro-places",
//    "metros",
//    "microstates",
//    "mines",
//    "mountains",
//    "museums",
//    "national-parks",
//    "newcastle",
//    "people-movers",
//    "ports",
//    "power-stations",
//    "pyramids",
//    "racetracks",
//    "rack",
//    "rail-trails",
//    "reclaimed",
//    "records",
//    "reservations",
//    "roundabouts",
//    "rubber",
//    "spaceports",
//    "spanish",
//    "stadiums",
//    "stairs",
//    "stations",
//    "statues",
//    "temples",
//    "towers",
//    "transfer",
//    "transporter",
//    "tripoints",
//    "trolleybuses",
//    "tunnels",
//    "twin-stations",
//    "useless",
//    "walls",
//    "waterfalls",
//    "worldsfair"

    // requires work
//    "apple", // manual
//    "loops", // totally manual
//    "swimming", // totally manual
//    "border-posts", // add links first
//    "mosques", // handle formatting
]
let wikiLocations = true

var allCountries = countryEmoji.map { Country.getCountry(icon: $0)! }
var visitedCountries = loadCountries(key: "countries")
countryLists.forEach { _ = loadCountries(key: $0) }
topLevelPages.forEach { loadPlaces(key: $0) }
let allCities = loadCities(key: "cities")
cityLists.forEach { _ = loadCities(key: $0) }
indexPages.forEach { parseIndexPage(key: $0) }
morePages.forEach { loadPlaces(key: $0) }
allCountries.sort { $0.name < $1.name }
allCountries.forEach { $0.countryFile().write() }

/* allCountries.forEach {
    $0.been = true
    $0.link = $0.fileLink
    print($0.htmlString().trim())
} */

var artists = loadPeople(key: "artists")
personThingPages.forEach { loadPersonThings(key: $0) }
loadBandMembers()
var allPeople = personIndex.values.sorted { $1.score > $0.score }
artists.forEach { artist in
    artist.artistFile().write()
    // print("  \"\(artist.name)\": \"\(artist.key)\",")
}

