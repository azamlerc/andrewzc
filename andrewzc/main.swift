//
//  main.swift
//  andrewzc
//
//  Created by Andrew Zamler-Carhart on 7/29/23.
//

import Foundation

let indexPages = ["geography", "buildings", "infrastructure", "music", "nature", "trains", "roadtrips", "people"]
let countryLists = ["citizenship", "european-union", "eurozone", "landlocked", "lefthand", "left-to-right", "marriage", "microstates", "nato", "no-trains", "non-binary", "schengen", "short-coastline", "similar-flags"]
let cityLists = ["capitals", "twin-cities", "congestion", "culture", "divided", "homes", "money-heist", "newcastle", "olympics", "tintin", "aop", "worldsfair", "eurovision", "planned", "spa-towns", "belfries", "tv-places", "germany", "belgium", "states"]
let middleSectionBeen = ["twin-cities", "border-posts", "confluence", "ferries", "tripoints", "awa", "states"]
let yearPrefix = ["olympics", "worldsfair", "automatic", "gauges", "projects", "left-to-right", "highest", "lowest", "europe-2003", "high-speed", "concerts", "eclipses", "people-movers", "eurovision", "timezones", "independence", "founded", "unification", "fare-free", "open-gangways"]
let topLevelPages = ["bucket", "unesco", "languages", "official-languages", "currency", "tv-places", "founded", "independence", "territories", "unification"]
let cityFlags = ["capitals", "culture", "tintin"]
let morePages = ["tv", "cars", "manuals"]
let excludedFiles = ["bingo", "train-facts", "subway", "hiroshima", "no-trains", "john-irving", "band-members", "countdown/index", "america-2022", "america-2023", "pacific-northwest", "brioude", "new-england", "eastern-shore", "million-dollars", "song-titles", "music-plants", "music-numbers", "music-colors", "music-tech", "rick-astley", "music-food", "music-animals", "transit-terms", "subway-status/index", "vulkaneifel", "florida"]
let personThingPages = ["deaths", "artist-names", "music-origins", "anton-corbijn", "concerts", "music-animals", "backing-bands", "bi-people", "music-cars", "music-colors", "cover-songs", "diverse", "featuring", "female-bassists", "guest-singers", "music-food", "love-songs", "multi-instrumentalists", "multiple-bands", "music-numbers", "music-people", "music-places", "music-plants", "producers", "trios", "singing-bassists", "singing-drummers", "solo", "songwriters", "music-space", "music-tech", "music-time", "music-trains", "music-water"]
let referenceBefore = ["circle-lines", "confluence", "depots", "express", "fare-cards", "forks", "grand-unions", "head-on", "highway-medians", "international-trams", "loops", "offset", "one-way", "open-gangways", "renamed", "rolling-stock", "short-turn", "shuttles", "single-platform", "single-track", "skip-stop", "split-platform", "tram-roundabouts", "worldsfair", "wyes"]
let dataPages = ["abandoned", "airbnb", "airports", "aop", "apple", "arches", "automatic", "awa", "beaches", "belfries", "belgium", "border-posts", "boundary-stones", "bridges", "brt", "bucket", "cable-cars", "capitals", "casinos", "castles", "cathedrals", "cities", "confluence", "congestion", "cross-platform", "culture", "curved", "disputed", "elevator-stations", "elevators", "enclaves", "endoheric", "europe-2003", "europe-2022", "europe-2023", "eurovision", "express", "extremities", "featuring", "ferries", "flood", "forts", "france", "funiculars", "germany", "grand-unions", "greenhouses", "ground-zero", "head-on", "heritage", "highest", "hotels", "housing", "infill", "lakes", "left-right", "lighthouses", "loops", "lowest", "luna-park", "malls", "metro-places", "metros", "microstates", "mines", "mosques", "mountains", "moving-walkways", "museums", "music-places", "national-parks", "newcastle", "offset", "olympics", "part-time", "people-movers", "planned", "pools", "ports", "power-stations", "premetros", "pyramids", "racetracks", "rack", "rail-trails", "reclaimed", "records", "reservations", "rivers", "roundabouts", "rubber", "salients", "short-platform", "short-turn", "single-platform", "skip-stop", "sloped", "spa-towns", "spaceports", "spanish", "spas", "split-platform", "springs", "stadiums", "stairs", "states", "stations", "statues", "struve", "suspension", "swimming", "temples", "tintin", "toilets", "towers", "tram-interchange", "tram-roundabouts", "trams", "transfer", "transporter", "tri-states", "tripoints", "trolleybuses", "tunnels", "turntables", "tv-places", "twin-stations", "unesco", "useless", "walls", "waterfalls", "worldsfair", "wyes", "circular"]
let crossLinkedFiles = ["buildings": ["stations"],
                        "nature": ["canals"],
                        "geography": ["international-trams", "international-trains"],
                        "infrastructure": ["trams", "metros"],
                        "trains": ["funiculars", "music-trains", "rail-trails", "useless"],
                        "people": ["artists", "artist-names", "diverse", "guest-singers", "metro-people", "music-people"]]
let loadCoords: [String] = []

// loadAppleData()
var allCities = [City]()
var allCountries = countryEmoji.map { Country.getCountry(icon: $0)! }
var visitedCountries = loadCountries(key: "countries")
countryLists.forEach { _ = loadCountries(key: $0) }
topLevelPages.forEach { loadPlaces(key: $0) }
allCities = loadCities(key: "cities")
allCities.forEach { cityIndex[$0.name.removeAccents()] = $0 }
cityLists.forEach { _ = loadCities(key: $0) }
indexPages.forEach { parseIndexPage(key: $0) }
morePages.forEach { loadPlaces(key: $0) }
allCountries.sort { $0.name < $1.name }
allCountries.forEach { $0.countryFile().write() }
// allCities.forEach { print("\($0.name): \($0.coords ?? "--")") }
allCities.forEach { $0.writeCityFiles() }

metaCountry(icon: "🌎", name: "Latin America", countries: ["🇲🇽", "🇨🇷", "🇨🇴", "🇩🇴"])

var artists = loadPeople(key: "artists")
personThingPages.forEach { loadPersonThings(key: $0) }
loadBandMembers()
var allPeople = personIndex.values.sorted { $1.score > $0.score }
artists.forEach { $0.artistFile().write() }
writeFlagsFile()

func writeFlagsFile() {
    var flagsFile = [String:Any]()
    flagsFile["totalCount"] = totalPlaceCount
    var flagsData = [String:[Int]]()
    let sortedCountries = allCountries.sorted { $0.placeCount > $1.placeCount }
    let sortedPages = pageIndex.values
        .sorted { $0.name < $1.name }
        .sorted { $0.placeCount > $1.placeCount }
        .filter { $0.placeCount > 1 }
        .filter { !excludedFiles.contains($0.key) }
    for (key, page) in pageIndex { flagsData[key] = page.iconCounts(for: sortedCountries) }
    flagsFile["data"] = flagsData
    flagsFile["pages"] = sortedPages.map { ["key": $0.key, "icon": $0.icon, "name": $0.name, "count": $0.placeCount] }
    flagsFile["countries"] = sortedCountries.map { ["icon": $0.icon, "name": $0.name, "count": $0.placeCount] }
    writeJSONToFile(dictionary: flagsFile, atPath: "\(folderPath)data/flags.json")
}
