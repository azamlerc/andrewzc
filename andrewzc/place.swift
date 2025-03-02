//
//  place.swift
//  andrewzc
//
//  Created by Andrew Zamler-Carhart on 7/29/23.
//

import Foundation

// var placeIndex = [String:Place]()
var placeFiles = [HTMLFile]()

class Place: Entity {
    var been = false
    var countries = [Country]()
    var states = [String]()
    
    override init(row: Row) {
        super.init(row: row)
        self.states = row.states
    }
    
    override init(icon: String, name: String) {
        super.init(icon: icon, name: name)
    }
    
    override func htmlString(pageName: String? = nil) -> String {
        var iconsDisplay = icons
        if pageName == "timezones" && icons.count > 1 {
            iconsDisplay = [icons.last!]
        }
        var iconHtml = iconsDisplay.joined(separator: " ")
        if !been {
            iconHtml = "<span class=\"todo\">\(iconHtml)</span>"
        }
        let classHtml = strike ? " class=\"strike\"" : ""
        let displayName = name == pageName && reference != nil ? reference! : name
        let folder = pageName == "countries" ? "../" : ""
        var nameHtml = link == nil ? displayName : "<a href=\"\(folder)\(link!)\"\(classHtml)>\(displayName)</a>"
        if reference != nil && reference != name && reference != pageName && name != pageName {
            nameHtml += " <span class=\"dark\">\(reference!)</span>"
        }
        if info != nil {
            nameHtml += " " + info!
        }
        var line = "\(iconHtml) \(nameHtml)<br>\n"
        if prefix != nil {
            line = "\(prefix!) \(line)"
        }
        return line
    }
}

func loadPlaces(key: String) {
    guard !key.hasPrefix("http") else {
        return
    }
    
    let placesFile = HTMLFile(key: key)
    placeFiles.append(placesFile)
    let placeGroups = placesFile.rowGroups.map { group in
        return group.map { row in
            let place = Place(row: row) // Place.getPlace(row: row)
            
            place.icons.forEach { icon in
                if let country = Country.getCountry(icon: icon) {
                    place.countries.append(country)
                    country.add(place: place, key: key)
                }
            }
            
            if key != "states" {
                if let city = cityIndex[place.name.removeAccents()] {
                    city.add(place: place, key: key)
                } else if let reference = place.reference, let city = cityIndex[reference.removeAccents()] {
                    city.add(place: place, key: key)
                }
            }
            
            return place
        }
    }
    if placeGroups.count > 0 {
        placeGroups[0].forEach {
            if ($0.name == "Lian") {
                print("Been to Lian")
            }
            $0.been = true
        }
        
        if placeGroups.count > 1 && middleSectionBeen.contains(key) {
            placeGroups[1].forEach { $0.been = true }
        }
    } else {
        print("No row groups: \(key)")
    }
    let places = placeGroups.flatMap { $0 }
    placesFile.entities = places

    if wikiLocations && wikiLocationPages.contains(key) {
        loadWikiLocations(placesFile: placesFile, places: places)
    }
}


