//
//  apple.swift
//  andrewzc
//
//  Created by Andrew Zamler-Carhart on 1/20/25.
//

//        if placesFile.key == "apple" {
//            if let store = appleStoreIndex[place.key],
//               let coords = store["coords"] as? String {
//                placeData["coords"] = coords
//            } else {
//                print("couldn't find store: " + place.key)
//            }
//        }

var appleStoreIndex = [String:[String:Any]]()
var appleStoreList = [[String:Any]]()
var appleBeenNames = ["American Dream", "Amsterdam", "Apple Park", "Aventura", "Battersea", "Bethesda Row", "Bluewater", "Brickell City Centre", "Bridgewater", "Broadway Plaza", "Brompton Road", "Brussels", "Carnegie Library", "Carré Sénart", "Champs-Élysées", "Cherry Hill", "Christiana Mall", "Clarendon", "Confluence", "Covent Garden", "Dadeland", "Den Haag", "Downtown Brooklyn", "Dubai Mall", "Fashion Show", "Fifth Avenue", "Forum Shops", "Freie Strasse", "Fukuoka", "Georgetown", "Ginza", "Grand Central", "Holyoke", "Infinite Loop", "Kärntner Straße", "Les Quatre Temps", "Lincoln Park", "Maine Mall", "Mapleview Centre", "Marché Saint-Germain", "MarketStreet", "Michigan Avenue", "Montgomery Mall", "Omotesando", "Opéra", "Palo Alto", "Park City", "Part-Dieu", "Passeig de Gràcia", "Pentagon City", "Puerta del Sol", "Regent Street", "Rosny 2", "Rue de Rive", "Sapporo</span><br>", "Shadyside", "Shibuya", "Shinjuku", "SoHo", "South Hills Village", "Southampton", "Stanford", "Strasbourg", "Stratford City", "The Grove", "The Mall at Bay Plaza", "Third Street Promenade", "Tysons Corner", "Union Square", "Upper East Side", "Upper West Side", "Valley Fair", "Vélizy 2", "Walnut Street", "West 14th Street", "Williamsburg", "Willowbrook", "World Trade Center"]

func loadAppleData() {
    if let appleData = loadJSONFromFile(atPath: folderPath + "data/apple-stores.json"),
       let data = appleData["data"] as? [String:Any],
       let countries = data["countries"] as? [[String:Any]]
    {
        for country in countries {
            if let matchLocale = country["matchLocale"] as? [String:Any],
               let icon = matchLocale["locale"] as? String,
               let stores = matchLocale["store"] as? [[String:Any]] {
                for store in stores {
                    var newStore: [String:Any] = store
                    let name = store["name"] as! String
                    let slug = store["slug"] as! String
                    newStore["icon"] = icon
                    var countryCode = (countryCodes[icon] ?? "XX").lowercased()
                    if countryCode == "ch" { countryCode = "chfr" }
                    if countryCode == "be" { countryCode = "befr" }
                    if countryCode == "gb" { countryCode = "uk" }
                    if countryCode == "mo" { countryCode = "mo-en" }
                    if countryCode == "hk" { countryCode = "hk/en" }
                    if countryCode == "us" { countryCode = "" } else { countryCode += "/" }
                    var link = "https://www.apple.com/\(countryCode)retail/\(slug)/"
                    link = link.replacingOccurrences(of: ".com/cn/", with: ".com.cn/")
                    newStore["been"] = appleBeenNames.contains(name)
                    newStore["link"] = link
                    appleStoreIndex[simplify(name)] = newStore
                    appleStoreList.append(newStore)
                }
            }
        }
    }
}

func printAppleHTML() {
    appleStoreList.sort { ($0["name"] as! String).caseInsensitiveCompare($1["name"] as! String) == .orderedAscending }
    for store in appleStoreList {
        if (store["been"] as! Bool) == false {
            let icon = store["icon"] as! String
            let name = store["name"] as! String
            let link = store["link"] as! String
            print("\(icon) <a href=\"\(link)\">\(name)</a><br>")
        }
    }
}

