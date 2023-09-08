//
//  main.swift
//  andrewzc
//
//  Created by Andrew Zamler-Carhart on 7/29/23.
//

import Foundation

let indexPages = ["geography", "buildings", "infrastructure", "nature", "trains", "people"]
let countryLists = ["citizenship", "european-union", "eurozone", "lefthand", "left-to-right", "marriage", "microstates", "no-trains", "schengen"]
let cityLists = ["twin-cities", "culture", "homes", "newcastle", "olympics", "aop", "worldsfair"]
let middleSectionBeen = ["twin-cities", "border-posts", "confluence", "ferries", "metros", "trams", "tripoints"]
let yearPrefix = ["olympics", "worldsfair", "automatic", "gauges", "projects", "left-to-right"]
let topLevelPages = ["bucket", "heritage", "languages", "currency", "disputed"]
let morePages = ["music-origins", "music-people", "music-places", "tv", "cars", "manuals"]
let excludedFiles = ["train-facts", "subway", "hiroshima", "no-trains", "john-irving", "band-members", "countdown/index"]
let crossLinkedFiles = ["buildings": ["stations"], "nature": ["canals"],
                        "geography": ["international-trams", "international-trains"],
                        "infrastructure": ["trams", "metros"],
                        "trains": ["funiculars", "rail-trails"],
                        "people": ["music-people"]]

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

