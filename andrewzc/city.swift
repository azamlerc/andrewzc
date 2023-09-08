//
//  city.swift
//  andrewzc
//
//  Created by Andrew Zamler-Carhart on 7/29/23.
//

import Foundation

var cityIndex = [String:City]()

class City: Place {
    override init(row: Row) {
        super.init(row: row)

        var countryIcon = row.icon
        if row.comment != nil && row.comment!.count == 1 { // handle vanity emoji with country in comment
            countryIcon = row.comment!
        }

        if let someCountry = Country.getCountry(icon: countryIcon) {
            country = someCountry
            someCountry.cities.append(self)
            someCountry.score += 1
        } else {
            print("\(row.name)")
        }

        if let icon = row.iconModifier {
            self.setFlag(from: icon)
        }
    }
    
    class func getCity(row: Row) -> City {
        if let city = cityIndex[row.name] {
            if city.link == nil && row.link != nil {
                city.link = row.link
            }
            if let iconModifier = row.iconModifier {
                city.setFlag(from: iconModifier)
            }
            return city
        } else {
            let newCity = City(row: row)
            cityIndex[row.name] = newCity
            return newCity
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
        case "🏓": self.setFlag("olympics-pingpong")
        case "*": self.setFlag("sorta")
        default: print("Unknown flag: \(icon)")
        }
    }

}

func loadCities(key: String) -> [City] {
    let citiesFile = HTMLFile(key: key)
    placeFiles.append(citiesFile)
    let cityGroups = citiesFile.rowGroups.map { group in
        return group.map {
            let city = City(row: $0) // City.getCity(row: $0)

            if let country = city.country {
                country.add(place: city, key: key)
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
    return cityGroups.flatMap { $0 }
}
