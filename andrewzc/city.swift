//
//  city.swift
//  andrewzc
//
//  Created by Andrew Zamler-Carhart on 7/29/23.
//

import Foundation

var cityIndex = [String:City]()
var cityFiles = [HTMLFile]()

class City: Place {
    var placesByKey = [String:[Place]]()
    
    override init(row: Row) {
        super.init(row: row)

        var countryIcon = row.icon
        if row.comment != nil && row.comment!.count == 1 { // handle vanity emoji with country in comment
            countryIcon = row.comment!
        }

        if let someCountry = Country.getCountry(icon: countryIcon) {
            self.countries.append(someCountry)
            someCountry.cities.append(self)
            someCountry.score += 1
        } else {
            if !["🪨", "🌖", "<"].contains(row.icon) && icon != "" {
                print("Not a country: \(countryIcon) \(row.name)")
            }
        }

        if let icon = row.iconModifier {
            self.setFlag(from: icon)
        }
    }
    
    override var description: String {
        return "\(icon) \(name)"
    }
    
    func setFlag(from icon: String) {
        switch icon {
        case "🏟": self.setFlag("olympics-stadium")
        case "🗼": self.setFlag("olympics-tower")
        case "🏔": self.setFlag("olympics-slopes")
        case "🏃‍♂️🤸‍♂️🏊‍♀️🏓": self.setFlag("olympics-pingpong")
        case "*": self.setFlag("sorta")
        default: print("Unknown flag: \(icon)")
        }
    }

    func add(place: Place, key: String) {
        var places = placesByKey[key]
        if places == nil {
            places = [Place]()
        }
        places!.append(place)
        placesByKey[key] = places!
    }

    func cityFile() -> HTMLFile {
        let file = HTMLFile(entity: self, folder: "cities")
        
        var body = ""
        if been {
            body.append("✅ Visited<br>\n")
        }
        cityFiles.forEach { flagFile in
            if flag(flagFile.key) {
                // hardcoding for Brexit because it is the only struck out country flag
                var flags = [String:Any]()
                if flagFile.key == "european-union" && file.key == "united-kingdom" {
                    flags["htmlClass"] = "strike"
                }
                body.append(flagFile.link(flags))
            }
        }

        if body.count > 0 {
            body.append("<div class=\"smallSpace\"><br></div>\n")
        }

        let max = 10
        placeFiles.forEach { placeFile in
            if let places = placesByKey[placeFile.key] {
                var flags:[String:Any] = ["htmlClass": "link"]
                flags["extra"] = places.count > max ? " (\(places.count))" : ""
                let somePlaces = places.count > max ? Array(places[0..<max]) : places
                body.append(placeFile.link(flags))
                somePlaces.forEach {
                    body.append($0.htmlString(pageName: self.name))
                }
                body.append("<div class=\"smallSpace\"><br></div>\n")
            }
        }
        
        file.contents = body
        return file
    }
}

func loadCities(key: String) -> [City] {
    let citiesFile = HTMLFile(key: key)
    if (key != "cities") {
        cityFiles.append(citiesFile)
    }
    placeFiles.append(citiesFile)
    let cityGroups = citiesFile.rowGroups.map { group in
        return group.map {
            let city = City(row: $0)

            if let country = city.countries.first {
                country.add(place: city, key: key)
            }
            
            let shortName = city.name.substring(before: ",").removeAccents()
            if let parent = cityIndex[shortName] {
                if key == "twin-cities" || $0.prefix != nil {
                    parent.add(place: city, key: key)
                } else {
                    parent.setFlag(key)
                    if $0.strike {
                        parent.setFlag(key + "-x")
                    }
                }
            }
            
            city.setFlag(key)
            if $0.strike {
                city.setFlag(key + "-x")
            }
            if let prefix = $0.prefix {
                city.metadata[key + "-prefix"] = prefix
            }

            return city
        }
    }
    if cityGroups.count > 0 {
        cityGroups[0].forEach { $0.been = true }
        
        if cityGroups.count > 1 && middleSectionBeen.contains(key) {
            cityGroups[1].forEach { $0.been = true }
        }
    }
    let cities = cityGroups.flatMap { $0 }
    
    if wikiLocations && wikiLocationPages.contains(key) {
        loadWikiLocations(placesFile: citiesFile, places: cities)
    }

    return cities
}
