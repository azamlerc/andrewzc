//
//  wiki.swift
//  andrewzc
//
//  Created by Andrew Zamler-Carhart on 5/12/24.
//

import Foundation

func loadWikiLocations(placesFile: HTMLFile, places: [Place]) {
    placesFile.loadData()
    print("updating \(placesFile.name)")
    places.forEach { place in
        var placeData: [String:Any] = placesFile.data[place.key] as? [String:Any] ?? [String:Any]()
        if place.link != nil { placeData["link"] = place.link }
        if placeData["name"] == nil { placeData["name"] = place.name }
        if let reference = place.reference { placeData["reference"] = reference }
        if let info = place.info { placeData["info"] = info }
        if place.strike { placeData["strike"] = true }
        placeData["been"] = place.been
        if place.countries.count == 1 {
            if place.countries[0].code != "" {
                placeData["country"] = place.countries[0].code
            } else {
                print("No code: \(place.countries[0].name)")
            }
        } else if place.countries.count > 1 {
            placeData["countries"] = place.countries.map { $0.code }
        }
        if place.states.count == 1 {
            placeData["state"] = place.states[0]
        } else if place.states.count > 1 {
            placeData["states"] = place.states
        }
        if placeData["coords"] == nil {
            if place.link?.contains("geohack") == true {
                getCoordinatesFromGeohack(link: place.link!, placeData: &placeData)
            } else if place.link?.contains("confluence") == true {
                getCoordinatesFromConfluence(link: place.link!, placeData: &placeData)
            } else if loadCoords {
                if place.link?.contains("wikipedia") == true {
                    if !getCoordinatesForWikiPage(link: place.link!, placeData: &placeData) {
                        let possibleLink = wikipediaLink(for: place.name)
                        print("Falling back to \(place.name)")
                        _ = getCoordinatesForWikiPage(link: possibleLink, placeData: &placeData)
                    }
                } else {
                    let possibleLink = wikipediaLink(for: place.name)
                    print("Trying \(place.name)")
                    if getCoordinatesForWikiPage(link: possibleLink, placeData: &placeData) {
                        if placeData["link"] == nil {
                            print("setting link: \(possibleLink)")
                            placeData["link"] = possibleLink
                        }
                    }
                }
            }
        }

        placesFile.data[place.key] = placeData
    }
    placesFile.saveData()
}

func wikipediaLink(for name: String) -> String {
    return "https://en.wikipedia.org/wiki/" + name
        .replacingOccurrences(of: " ", with: "_")
        .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
}

func getCoordinatesForWikiPage(link: String, placeData: inout [String:Any]) -> Bool {
//    if !link.contains("Pontchartrain") {
//        return false
//    }

    if let content = loadWikipediaContent(link: link) {
        // print(content)

        if let newName = content.substring(start: "#REDIRECT [[", end: "]]") ?? content.substring(start: "#Redirect [[", end: "]]") {
            print("redirect: \(newName)")
            let redirect = wikipediaLink(for: newName)
            return getCoordinatesForWikiPage(link: redirect, placeData: &placeData)
        }
        
        if let coordinates = content.substring(start: "{{Coord|", end: "}}") ?? content.substring(start: "{{coord|", end: "}}") {
            if let coords = parseCoordinates(coordinates, separator: "|") {
                print(coords)
                placeData["coords"] = coords
                return true
            } else {
                print("couldn't parse: \(coordinates)")
            }
        }
        
        if placeData["wikidata"] == nil { // if we haven't already called the API
            if let dataKey = (content.substring(start: "{{Wikidatacoord|", end: "|") ??
                             content.substring(start: "{{WikidataCoord|", end: "|") ??
                             content.substring(start: "{{wikidatacoord|", end: "|"))?.replacingOccurrences(of: "Q=Q", with: "Q") ??
                             loadWikidataSeach(link: link) {
                if dataKey.hasPrefix("Q") {
                    print("wikidata key \(dataKey)")
                    placeData["wikidata"] = dataKey
                    if let coords = fetchCoordinates(for: dataKey) {
                        print("wikidata \(coords)")
                        placeData["coords"] = coords
                        return true
                    }
                }
            }
        }
        
        var fields = [String:String]()
        content.components(separatedBy: "\n")
            .filter { $0.trim().hasPrefix("|") && $0.contains("=") }
            .map { $0.substring(after: "|") }
            .map { $0.components(separatedBy: "=") }
            .filter { $0.count == 2 }
            .forEach {
                let key = $0[0].lowercased().trim()
                let value = $0[1].trim()
                fields[key] = value
            }
//        if fields.count > 0 {
//            print("fields: \(fields)")
//        }
        
        if let lat = fields["latitude"], let long = fields["longitude"] {
            let coordinates = "\(lat)/\(long)"
            if let coords = parseCoordinates(coordinates, separator: "/") {
                print("fields \(coords)")
                placeData["coords"] = coords
                return true
            }
        }

        if let lat = fields["breitengrad"], let long = fields["längengrad"] {
            let coordinates = "\(lat)/\(long)"
            if let coords = parseCoordinates(coordinates, separator: "/") {
                print("german \(coords)")
                placeData["coords"] = coords
                return true
            }
        }
        
        if let latDeg = fields["lat_deg"], let latMin = fields["lat_min"], let latSec = fields["lat_sec"], let lonDeg = fields["lon_deg"], let lonMin = fields["lon_min"], let lonSec = fields["lon_sec"] {
            let ns = !latDeg.hasPrefix("-") ? "N" : "S"
            let ew = !lonDeg.hasPrefix("-") ? "E" : "W"
            let coords = "\(latDeg)°\(latMin)′\(latSec)″\(ns), \(lonDeg)°\(lonMin)′\(lonSec)″\(ew)"
            print("tedious \(coords)")
            placeData["coords"] = coords
            return true
        }
        
        print("No coordinates: \(link)")
    } else {
        print("No data for \(link)")
        
        if !link.contains("%") {
            let urlSafe = link.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
            if link != urlSafe {
                print("Trying \(urlSafe)")
                return getCoordinatesForWikiPage(link: urlSafe, placeData: &placeData)
            }
        }
    }
    return false
}
    
func loadWikipediaContent(link: String) -> String? {
    if let apiUrl = wikiApiUrl(link: link) {
        if let json = loadJSONFromURL(url: apiUrl, apiKey: wikipediaApiKey) {
            if let source = json["source"] as? String {
                return source.replacingOccurrences(of: "{{coord|qid=", with: "{{xxxxx|qid=")
            } else {
                // print("couldn't get source: \(apiUrl) \(json["errorKey"] ?? "unknown error")")
            }
        } else {
            print("couldn't load json: \(apiUrl)")
        }
    } else {
        print("couldn't make apiUrl: \(link)")
    }
    return nil
}

func wikiApiUrl(link: String) -> URL? {
    let components = link.substring(after: "//").components(separatedBy: "/")
    if components.count < 2 {
        print("url problem? \(link)")
        return nil
    }
    let host = components.first!
    var page = components.last!
    let language = host.components(separatedBy: ".").first!
    
    if let url = URL(string: "https://api.wikimedia.org/core/v1/wikipedia/\(language)/page/\(page)") {
        return url
    } else {
        page = page.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!
        print("url encoding: \(page)")
        return URL(string: "https://api.wikimedia.org/core/v1/wikipedia/\(language)/page/\(page)")
    }
}

func loadWikidataSeach(link: String) -> String? {
    if let apiUrl = wikidataSearchUrl(link: link) {
        if let json = loadJSONFromURL(url: apiUrl, apiKey: nil /* wikidataApiKey */) {
            if let results = json["search"] as? [[String:Any]] {
                if let result = results.first, let id = result["id"] as? String {
                    return id
                }
            } else {
                print("couldn't get results: \(apiUrl) \(json)")
            }
        } else {
            print("couldn't load json: \(apiUrl)")
        }
    } else {
        print("couldn't make dataSearchUrl: \(link)")
    }
    return nil
}

func wikidataSearchUrl(link: String) -> URL? {
    let components = link.substring(after: "//").components(separatedBy: "/")
    if components.count < 2 {
        print("url problem? \(link)")
        return nil
    }
    let host = components.first!
    var page = components.last!.substring(before: "#")
    let language = host.components(separatedBy: ".").first!
    
    if let url = URL(string: "https://www.wikidata.org/w/api.php?action=wbsearchentities&format=json&search=\(page)&language=\(language)") {
        return url
    } else {
        page = page.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!
        print("url encoding: \(page)")
        return URL(string: "https://www.wikidata.org/w/api.php?action=wbsearchentities&format=json&search=\(page)&language=\(language)")
    }
}

func getCoordinatesFromGeohack(link: String, placeData: inout [String:Any]) {
    let coordinates = link.substring(after: "params=")
    if let coords = parseCoordinates(coordinates, separator: "_") {
        print(coords)
        placeData["coords"] = coords
    }
}

func getCoordinatesFromConfluence(link: String, placeData: inout [String:Any]) {
    let params = queryStringToDict(query: link.substring(after: "?"))
    let coords = "\(params["lat"] ?? "0").0, \(params["lon"] ?? "0").0"
    print(coords)
    placeData["coords"] = coords
}

func parseCoordinates(_ coordinates: String, separator: String) -> String? {
    var components = coordinates.components(separatedBy: separator).map { $0.trim() }
    
    if components.count > 2 && components[0] == "display=title" {
        components.removeFirst()
    }
    
    // Ensure the input string has the expected number of components
    guard components.count >= 2 else {
        print("Invalid input format: \(coordinates)")
        return nil
    }
    
    // Check if latitude and longitude are in decimal format or DMS format
    let latIndex = components.firstIndex(of: "N") ?? components.firstIndex(of: "S")
    let longIndex = components.firstIndex(of: "E") ?? components.firstIndex(of: "W")
    
    // Extract latitude and longitude components
    var latitude = ""
    var longitude = ""
    
    if latIndex == nil && longIndex == nil {
        guard let lat = Double(components[0]), let long = Double(components[1]) else {
            print("Invalid decimal format: \(coordinates)")
            return nil
        }
        latitude = lat >= 0 ? "\(lat)°N" : "\(-lat)°S"
        longitude = long >= 0 ? "\(long)°E" : "\(-long)°W"
    } else if latIndex == 1 && longIndex == 3 {
        latitude = components[0] + "°" + components[1]
        longitude = components[2] + "°" + components[3]
    } else if latIndex == 2 && longIndex == 5 {
        let latDegrees = components[0]
        let latMinutes = components[1]
        let latDirection = components[2]
        
        let longDegrees = components[3]
        let longMinutes = components[4]
        let longDirection = components[5]

        latitude = "\(latDegrees)°\(latMinutes)′\(latDirection)"
        longitude = "\(longDegrees)°\(longMinutes)′\(longDirection)"
    } else if latIndex == 3 && longIndex == 7 {
        let latDegrees = components[0]
        let latMinutes = components[1]
        let latSeconds = components[2]
        let latDirection = components[3]
        
        let longDegrees = components[4]
        let longMinutes = components[5]
        let longSeconds = components[6]
        let longDirection = components[7]

        latitude = "\(latDegrees)°\(latMinutes)′\(latSeconds)″\(latDirection)"
        longitude = "\(longDegrees)°\(longMinutes)′\(longSeconds)″\(longDirection)"
    } else {
        print("What happened? \(coordinates)")
        return nil
    }
    
    return "\(latitude), \(longitude)"
}

func fetchCoordinates(for entityId: String) -> String? {
    let urlString = "https://www.wikidata.org/w/api.php?action=wbgetclaims&format=json&props=claims&entity=\(entityId)"
        guard let url = URL(string: urlString) else {
        print("Invalid URL")
        return nil
    }
    
    let semaphore = DispatchSemaphore(value: 0)
    var result: String? = nil
    
    let task = URLSession.shared.dataTask(with: url) { data, response, error in
        if let error = error {
            print("Error: \(error.localizedDescription)")
            semaphore.signal()
            return
        }
        guard let data = data else {
            print("No data")
            semaphore.signal()
            return
        }
        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
               if let claims = json["claims"] as? [String: Any] {
                   if let coords = claims["P625"] as? [[String: Any]],
                      let coord = coords.first,
                      let value = coord["mainsnak"] as? [String: Any],
                      let datavalue = value["datavalue"] as? [String: Any],
                      let valueDict = datavalue["value"] as? [String: Any],
                      let latitude = valueDict["latitude"] as? Double,
                      let longitude = valueDict["longitude"] as? Double {
                       result = "\(latitude), \(longitude)"
                   } else {
                       print("Coordinates not found")
                   }
               } else {
                   print("Claims not found")
               }
            } else {
                print("Couldn't parse JSON")
            }
        } catch {
            print("JSON parsing error: \(error.localizedDescription)")
        }

        semaphore.signal()
    }
    task.resume()
    _ = semaphore.wait(timeout: .distantFuture)
    return result
}
