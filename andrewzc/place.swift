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
    var city: City?
    var location: Location?

    override init(row: Row) {
        super.init(row: row)
        self.states = row.states
    }
    
    override init(icon: String, name: String) {
        super.init(icon: icon, name: name)
    }
    
    override func htmlString(pageName: String? = nil) -> String {
        var iconHtml = icons.joined(separator: " ")
        if !been {
            iconHtml = "<span class=\"todo\">\(iconHtml)</span>"
        }
        let classHtml = strike ? " class=\"strike\"" : ""
        let displayName = name == pageName && reference != nil ? reference! : name
        var nameHtml = link == nil ? displayName : "<a href=\"\(link!)\"\(classHtml)>\(displayName)</a>"
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
    
    func findCity(placeKey: String, cityName: String?, coords: String?) {
        if let theCityName = cityName, let city = cityIndex[theCityName.removeAccents()] {
            city.add(place: self, key: placeKey)
            self.city = city
        } else if let city = cityIndex[self.name.removeAccents()] {
            city.add(place: self, key: placeKey)
            self.city = city
        } else if let reference = self.reference, let city = cityIndex[reference.removeAccents()] {
            city.add(place: self, key: placeKey)
            self.city = city
        } else if let placeCoords = coords,
            let placeLocation = Location(coords: placeCoords),
            let city = getCityByLocation(name: name, location: placeLocation) {
            city.add(place: self, key: placeKey)
            self.city = city
        } else if ["airports"].contains(placeKey) {
            if let city = prefixCity(name: name) {
                 city.add(place: self, key: placeKey)
                 self.city = city
            }
        }
    }
    
    func updateData(placesFile: HTMLFile, type: String?) {
        let dataKey = type == nil ? self.key : "\(type!)-\(self.key)"
        var placeData: [String:Any] = placesFile.data[dataKey] as? [String:Any] ?? [String:Any]()
        if self.link != nil { placeData["link"] = self.link }
        if placeData["name"] == nil { placeData["name"] = self.name }
        if let reference = self.reference { placeData["reference"] = reference }
        if let info = self.info { placeData["info"] = info }
        if let prefix = self.prefix { placeData["prefix"] = prefix }
        if let theType = type { placeData["type"] = theType }
        placeData["icons"] = self.icons;
        if self.strike { placeData["strike"] = true }
        placeData["been"] = self.been
        if self.countries.count == 1 {
            if self.countries[0].code != "" {
                placeData["country"] = self.countries[0].code
            } else {
                print("No code: \(self.countries[0].name)")
            }
        } else if self.countries.count > 1 {
            placeData["countries"] = self.countries.map { $0.code }
        }
        if self.states.count == 1 {
            placeData["state"] = self.states[0]
        } else if self.states.count > 1 {
            placeData["states"] = self.states
        }
        if placeData["coords"] == nil {
            if self.link?.contains("geohack") == true {
                getCoordinatesFromGeohack(link: self.link!, placeData: &placeData)
            } else if self.link?.contains("confluence") == true {
                getCoordinatesFromConfluence(link: self.link!, placeData: &placeData)
            } else if loadCoords.contains(placesFile.key) {
                if self.link?.contains("wikipedia") == true {
                    if !getCoordinatesForWikiPage(link: self.link!, key: placesFile.key, placeData: &placeData) {
                        let possibleLink = wikipediaLink(for: self.name)
                        print("Falling back to \(self.name)")
                        _ = getCoordinatesForWikiPage(link: possibleLink, key: placesFile.key, placeData: &placeData)
                    }
                } else if self.link?.contains("booking.com") == true {
                    _ = getCoordinatesForBookingPage(link: self.link!, placeData: &placeData)
                } else if self.link?.contains("airbnb.com") == true {

                } else {
                    let possibleLink = wikipediaLink(for: self.name)
                    print("Trying \(self.name)")
                    if getCoordinatesForWikiPage(link: possibleLink, key: key, placeData: &placeData) {
                        if placeData["link"] == nil {
                            print("setting link: \(possibleLink)")
                            placeData["link"] = possibleLink
                        }
                    }
                }
            }
        }
        if let coords = placeData["coords"] as? String {
            if coords.contains("°") {
                if let decimal =  try? convertToDecimal(coords: coords) {
                    // print("\(coords) = \(decimal)")
                    placeData["coords"] = decimal
                } else {
                    print("couldn't convert \(coords)")
                }
            }
        }
        if type == nil {
            if let coords = placeData["coords"] as? String {
                self.location = Location(coords: coords)
            }
        } else {
            if self.location != nil {
                placeData["coords"] = self.location!.stringValue()
                if let page = pageIndex[type!] {
                    placeData["icons"] = [page.icon] // hack to clobber the icons
                }
            }
        }
        
        if !["cities", "states", "countries", "belgium", "germany", "france"].contains(placesFile.key) {
            findCity(placeKey: placesFile.key, cityName: placeData["city"] as? String, coords: placeData["coords"] as? String)
        }
        if let city = self.city { placeData["city"] = city.name }
        
        placesFile.data[dataKey] = placeData
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
            
            return place
        }
    }
    if placeGroups.count > 0 {
        placeGroups[0].forEach {
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
    
    if dataPages.contains(key) {
        placesFile.loadData()
        places.forEach {
            $0.updateData(placesFile: placesFile, type: nil)
        }
        placesFile.saveData()
    } else {
        places.forEach {
            $0.findCity(placeKey: placesFile.key, cityName: nil, coords: nil)
        }
    }
}


