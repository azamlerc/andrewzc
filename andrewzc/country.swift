//
//  country.swift
//  andrewzc
//
//  Created by Andrew Zamler-Carhart on 7/29/23.
//

import Foundation

let duplicateCountryNames = ["Transnistria", "Neutral Moresnet", "Saarland", "Saba", "Saint Helena", "British Columbia", "New Brunswick", "Nova Scotia", "Prince Edward Island", "Newfoundland"]

var countryIndex = [String:Country]()
var countryFiles = [HTMLFile]()

class Country: Place {
    var cities = [City]()
    var orderVisited: Int?
    
    var placesByKey = [String:[Place]]()
    
    override init(row: Row) {
        super.init(row: row)
        
        if let icon = row.iconModifier {
            self.setFlag(from: icon)
        }
    }

    override init(icon: String, name: String) {
        super.init(icon: icon, name: name)

    }

    class func getCountry(icon: String) -> Country? {
        if let country = countryIndex[icon] {
            return country
        } else if let name = countryNames[icon] {
            let country = Country(icon: icon, name: name)
            countryIndex[icon] = country
            return country
        } else {
            // print("Not a country: \(icon)")
            return nil
        }
    }
    
    class func getCountry(row: Row) -> Country {
        if let country = countryIndex[row.icon] {
            if country.name != row.name {
                if !duplicateCountryNames.contains(row.name) {
                    print("\(country.name) != \(row.name)")
                }
            } else {
                if country.link == nil && row.link != nil {
                    country.link = row.link
                }
                if let iconModifier = row.iconModifier {
                    country.setFlag(from: iconModifier)
                }
            }
            return country
        } else {
            let newCountry = Country(row: row)
            countryIndex[row.icon] = newCountry
            row.entity = newCountry
            return newCountry
        }
    }
    
    override var description: String {
        return "\(icon) \(name)"
    }
    
    override var fileLink: String {
        return "countries/\(super.fileLink)"
    }

    func setFlag(from icon: String) {
        switch icon {
        case "🚗": self.setFlag("drove")
        case "💍": self.setFlag("married")
        case "🛬": self.setFlag("married")
        case "🤬": self.setFlag("angry")
        case "⬅️": self.setFlag("right-to-left")
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
    
    func placesSummary() -> [String:Int] {
        var totals = [String:Int]()
        placesByKey.forEach { key, places in
            totals[key] = places.count
        }
        return totals
    }
    
    func countryFile() -> HTMLFile {
        let file = HTMLFile(entity: self, folder: "countries")
        
        var body = ""
        if flag("border-zone") {
            body.append("🛂 Border<br>\n")
        } else if been {
            body.append("✅ Visited<br>\n")
        }
        
        countryFiles.forEach { flagFile in
            if flag(flagFile.key) {
                // hardcoding this because it is the only struck out country flag
                let brexit = flagFile.key == "european-union" && file.key == "united-kingdom"
                let htmlClass = brexit ? "strike" : ""
                body.append(flagFile.link(htmlClass: htmlClass, extra: ""))
            }
        }
        if body.count > 0 {
            body.append("<div class=\"smallSpace\"><br></div>\n")
        }

        let max = 10
        placeFiles.forEach { placeFile in
            if let places = placesByKey[placeFile.key] {
                let extra = places.count > max ? " (\(places.count))" : ""
                let somePlaces = places.count > max ? Array(places[0..<max]) : places
                body.append(placeFile.link(htmlClass: "link", extra: extra))
                somePlaces.forEach {
                    body.append($0.htmlString())
                }
                body.append("<div class=\"smallSpace\"><br></div>\n")
            }
        }
        
        file.contents = body
        return file
    }
}

func loadCountries(key: String) -> [Country] {
    let countriesFile = HTMLFile(key: key)
    if (key != "countries") {
        countryFiles.append(countriesFile)
    }
    let countryGroups = countriesFile.rowGroups.map { group in
        return group.map {
            let country = Country.getCountry(row: $0)

            country.setFlag(key)
            if $0.strike {
                country.setFlag(key + "-x")
            }

            return country
        }
    }
    if (countryGroups.count > 0) {
        countryGroups[0].forEach { $0.been = true }
    }
    if (key == "countries" && countryGroups.count > 2) {
        for (order, country) in countryGroups[0].enumerated() {
            country.orderVisited = order
        }
        countryGroups[1].forEach { $0.setFlag("border-zone") }
    }
    return countryGroups.flatMap { $0 }
}

let countryNames = [
    "🇦🇩": "Andorra",
    "🇦🇪": "United Arab Emirates",
    "🇦🇫": "Afghanistan",
    "🇦🇬": "Antigua and Barbuda",
    "🇦🇮": "Anguilla",
    "🇦🇱": "Albania",
    "🇦🇲": "Armenia",
    "🇦🇴": "Angola",
    "🇦🇶": "Antarctica",
    "🇦🇷": "Argentina",
    "🇦🇸": "American Samoa",
    "🇦🇹": "Austria",
    "🇦🇺": "Australia",
    "🇦🇼": "Aruba",
    "🇦🇽": "Åland",
    "🇦🇿": "Azerbaijan",
    "🇧🇦": "Bosnia and Herzegovina",
    "🇧🇧": "Barbados",
    "🇧🇩": "Bangladesh",
    "🇧🇪": "Belgium",
    "🇧🇫": "Burkina Faso",
    "🇧🇬": "Bulgaria",
    "🇧🇭": "Bahrain",
    "🇧🇮": "Burundi",
    "🇧🇯": "Benin",
    "🇧🇱": "Saint Barthélemy",
    "🇧🇲": "Bermuda",
    "🇧🇳": "Brunei",
    "🇧🇴": "Bolivia",
    "🇧🇶": "Bonaire",
    "🇧🇷": "Brazil",
    "🇧🇸": "Bahamas",
    "🇧🇹": "Bhutan",
    "🇧🇼": "Botswana",
    "🇧🇾": "Belarus",
    "🇧🇿": "Belize",
    "🇨🇦": "Canada",
    "🇨🇨": "Cocos Islands",
    "🇨🇩": "Congo-Kinshasa",
    "🇨🇫": "Central African Republic",
    "🇨🇬": "Congo-Brazzaville",
    "🇨🇭": "Switzerland",
    "🇨🇮": "Côte d’Ivoire",
    "🇨🇰": "Cook Islands",
    "🇨🇱": "Chile",
    "🇨🇲": "Cameroon",
    "🇨🇳": "China",
    "🇨🇴": "Colombia",
    "🇨🇷": "Costa Rica",
    "🇨🇺": "Cuba",
    "🇨🇻": "Cape Verde",
    "🇨🇼": "Curaçao",
    "🇨🇽": "Christmas Island",
    "🇨🇾": "Cyprus",
    "🇨🇿": "Czechia",
    "🇩🇪": "Germany",
    "🇩🇯": "Djibouti",
    "🇩🇰": "Denmark",
    "🇩🇲": "Dominica",
    "🇩🇴": "Dominican Republic",
    "🇩🇿": "Algeria",
    "🇪🇨": "Ecuador",
    "🇪🇪": "Estonia",
    "🇪🇬": "Egypt",
    "🇪🇭": "Western Sahara",
    "🇪🇷": "Eritrea",
    "🇪🇸": "Spain",
    "🇪🇹": "Ethiopia",
    "🇫🇮": "Finland",
    "🇫🇯": "Fiji",
    "🇫🇰": "Falklands",
    "🇫🇲": "Micronesia",
    "🇫🇴": "Faroe Islands",
    "🇫🇷": "France",
    "🇬🇦": "Gabon",
    "🇬🇧": "United Kingdom",
    "🇬🇩": "Grenada",
    "🇬🇪": "Georgia",
    "🇬🇫": "French Guiana",
    "🇬🇬": "Guernsey",
    "🇬🇭": "Ghana",
    "🇬🇮": "Gibraltar",
    "🇬🇱": "Greenland",
    "🇬🇲": "Gambia",
    "🇬🇳": "Guinea",
    "🇬🇵": "Guadeloupe",
    "🇬🇶": "Equatorial Guinea",
    "🇬🇷": "Greece",
    "🇬🇸": "South Georgia",
    "🇬🇹": "Guatemala",
    "🇬🇺": "Guam",
    "🇬🇼": "Guinea-Bissau",
    "🇬🇾": "Guyana",
    "🇭🇰": "Hong Kong",
    "🇭🇳": "Honduras",
    "🇭🇷": "Croatia",
    "🇭🇹": "Haiti",
    "🇭🇺": "Hungary",
    "🇮🇩": "Indonesia",
    "🇮🇪": "Ireland",
    "🇮🇱": "Israel",
    "🇮🇲": "Isle of Man",
    "🇮🇳": "India",
    "🇮🇴": "British Indian Ocean Territory",
    "🇮🇶": "Iraq",
    "🇮🇷": "Iran",
    "🇮🇸": "Iceland",
    "🇮🇹": "Italy",
    "🇯🇪": "Jersey",
    "🇯🇲": "Jamaica",
    "🇯🇴": "Jordan",
    "🇯🇵": "Japan",
    "🇰🇪": "Kenya",
    "🇰🇬": "Kyrgyzstan",
    "🇰🇭": "Cambodia",
    "🇰🇮": "Kiribati",
    "🇰🇲": "Comoros",
    "🇰🇳": "Saint Kitts and Nevis",
    "🇰🇵": "North Korea",
    "🇰🇷": "South Korea",
    "🇰🇼": "Kuwait",
    "🇰🇾": "Cayman Islands",
    "🇰🇿": "Kazakhstan",
    "🇱🇦": "Laos",
    "🇱🇧": "Lebanon",
    "🇱🇨": "Saint Lucia",
    "🇱🇮": "Liechtenstein",
    "🇱🇰": "Sri Lanka",
    "🇱🇷": "Liberia",
    "🇱🇸": "Lesotho",
    "🇱🇹": "Lithuania",
    "🇱🇺": "Luxembourg",
    "🇱🇻": "Latvia",
    "🇱🇾": "Libya",
    "🇲🇦": "Morocco",
    "🇲🇨": "Monaco",
    "🇲🇩": "Moldova",
    "🇲🇪": "Montenegro",
    "🇲🇬": "Madagascar",
    "🇲🇭": "Marshall Islands",
    "🇲🇰": "North Macedonia",
    "🇲🇱": "Mali",
    "🇲🇲": "Myanmar",
    "🇲🇳": "Mongolia",
    "🇲🇴": "Macau",
    "🇲🇵": "Northern Mariana Islands",
    "🇲🇶": "Martinique",
    "🇲🇷": "Mauritania",
    "🇲🇸": "Montserrat",
    "🇲🇹": "Malta",
    "🇲🇺": "Mauritius",
    "🇲🇻": "Maldives",
    "🇲🇼": "Malawi",
    "🇲🇽": "Mexico",
    "🇲🇾": "Malaysia",
    "🇲🇿": "Mozambique",
    "🇳🇦": "Namibia",
    "🇳🇨": "New Caledonia",
    "🇳🇪": "Niger",
    "🇳🇫": "Norfolk Island",
    "🇳🇬": "Nigeria",
    "🇳🇮": "Nicaragua",
    "🇳🇱": "Netherlands",
    "🇳🇴": "Norway",
    "🇳🇵": "Nepal",
    "🇳🇷": "Nauru",
    "🇳🇺": "Niue",
    "🇳🇿": "New Zealand",
    "🇴🇲": "Oman",
    "🇵🇦": "Panama",
    "🇵🇪": "Peru",
    "🇵🇫": "French Polynesia",
    "🇵🇬": "Papua New Guinea",
    "🇵🇭": "Philippines",
    "🇵🇰": "Pakistan",
    "🇵🇱": "Poland",
    "🇵🇲": "Saint Pierre and Miquelon",
    "🇵🇳": "Pitcairn Islands",
    "🇵🇷": "Puerto Rico",
    "🇵🇸": "Palestine",
    "🇵🇹": "Portugal",
    "🇵🇼": "Palau",
    "🇵🇾": "Paraguay",
    "🇶🇦": "Qatar",
    "🇷🇪": "Réunion",
    "🇷🇴": "Romania",
    "🇷🇸": "Serbia",
    "🇷🇺": "Russia",
    "🇷🇼": "Rwanda",
    "🇸🇦": "Saudi Arabia",
    "🇸🇧": "Solomon Islands",
    "🇸🇨": "Seychelles",
    "🇸🇩": "Sudan",
    "🇸🇪": "Sweden",
    "🇸🇬": "Singapore",
    "🇸🇭": "Saint Helena",
    "🇸🇮": "Slovenia",
    "🇸🇰": "Slovakia",
    "🇸🇱": "Sierra Leone",
    "🇸🇲": "San Marino",
    "🇸🇳": "Senegal",
    "🇸🇴": "Somalia",
    "🇸🇷": "Suriname",
    "🇸🇸": "South Sudan",
    "🇸🇹": "São Tomé and Príncipe",
    "🇸🇻": "El Salvador",
    "🇸🇽": "Sint Maarten",
    "🇸🇾": "Syria",
    "🇸🇿": "Eswatini",
    "🇹🇨": "Turks and Caicos",
    "🇹🇩": "Chad",
    "🇹🇫": "French Southern Territories",
    "🇹🇬": "Togo",
    "🇹🇭": "Thailand",
    "🇹🇯": "Tajikistan",
    "🇹🇰": "Tokelau",
    "🇹🇱": "East Timor",
    "🇹🇲": "Turkmenistan",
    "🇹🇳": "Tunisia",
    "🇹🇴": "Tonga",
    "🇹🇷": "Turkey",
    "🇹🇹": "Trinidad and Tobago",
    "🇹🇻": "Tuvalu",
    "🇹🇼": "Taiwan",
    "🇹🇿": "Tanzania",
    "🇺🇦": "Ukraine",
    "🇺🇬": "Uganda",
    "🇺🇸": "United States",
    "🇺🇾": "Uruguay",
    "🇺🇿": "Uzbekistan",
    "🇻🇦": "Vatican City",
    "🇻🇨": "Saint Vincent and the Grenadines",
    "🇻🇪": "Venezuela",
    "🇻🇬": "Virgin Islands",
    "🇻🇮": "U.S. Virgin Islands",
    "🇻🇳": "Vietnam",
    "🇻🇺": "Vanuatu",
    "🇼🇫": "Wallis and Futuna",
    "🇼🇸": "Samoa",
    "🇾🇪": "Yemen",
    "🇾🇹": "Mayotte",
    "🇿🇦": "South Africa",
    "🇿🇲": "Zambia",
    "🇿🇼": "Zimbabwe",
    "🇪🇺": "European Union",
    "🏴󠁧󠁢󠁳󠁣󠁴󠁿": "Scotland",
    "🏴󠁧󠁢󠁷󠁬󠁳󠁿": "Wales",
    // "🏴󠁧󠁢󠁥󠁮󠁧󠁿": "England",
]

let countryEmoji = countryNames.keys
