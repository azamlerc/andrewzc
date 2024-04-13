//
//  main.swift
//  andrewzc
//
//  Created by Andrew Zamler-Carhart on 7/29/23.
//

import Foundation

let indexPages = ["geography", "buildings", "infrastructure", "music", "nature", "trains", "roadtrips", "people"]
let countryLists = ["citizenship", "european-union", "eurozone", "lefthand", "left-to-right", "marriage", "microstates", "nato", "no-trains", "schengen", "similar-flags"]
let cityLists = ["capitals", "twin-cities", "culture", "divided", "homes", "money-heist", "newcastle", "olympics", "tintin", "aop", "worldsfair"]
let middleSectionBeen = ["twin-cities", "border-posts", "confluence", "ferries", "metros", "trams", "tripoints"]
let yearPrefix = ["olympics", "worldsfair", "automatic", "gauges", "projects", "left-to-right", "highest", "lowest", "europe-2003", "high-speed", "concerts", "eclipses"]
let topLevelPages = ["bucket", "unesco", "languages", "official-languages", "currency"]
let morePages = ["tv", "cars", "manuals"]
let excludedFiles = ["bingo", "train-facts", "subway", "hiroshima", "no-trains", "john-irving", "band-members", "countdown/index", "america-2022", "america-2023", "pacific-northwest", "brioude", "boundary-stones", "new-england", "eastern-shore", "million-dollars", "song-titles", "music-plants", "music-numbers", "music-colors", "music-tech", "rick-astley", "music-food", "music-animals", "transit-terms", "subway-status/index"]
let crossLinkedFiles = ["buildings": ["stations"],
                        "nature": ["canals"],
                        "geography": ["international-trams", "international-trains"],
                        "infrastructure": ["trams", "metros"],
                        "trains": ["funiculars", "rail-trails"],
                        "people": ["artists", "artist-names", "diverse", "guest-singers", "metro-people", "music-people"]]
let personThingPages = ["deaths", "artist-names", "music-origins", "concerts", "music-animals", "bi-people", "music-cars", "music-colors", "cover-songs", "diverse", "female-bassists", "guest-singers", "music-food", "love-songs", "multi-instrumentalists", "multiple-bands", "music-numbers", "music-people", "music-places", "music-plants", "producers", "trios", "singing-bassists", "singing-drummers", "solo", "songwriters", "music-space", "music-tech", "music-time", "music-trains", "music-water"]

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

