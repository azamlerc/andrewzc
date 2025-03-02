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
    var code = ""
    var cities = [City]()
    var people = [Person]()
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
        if let code = countryCodes[icon] {
            self.code = code
        }
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
        case "✈️": self.setFlag("airport")
        case "⬅️": self.setFlag("right-to-left")
        default: print("Unknown flag: \(icon)")
        }
        
    }
    
    func add(place: Place, key: String) {
        add(place: place, key: key, avoidDuplicates: false)
    }
    
    func add(place: Place, key: String, avoidDuplicates: Bool) {
        var places = placesByKey[key]
        if places == nil {
            places = [Place]()
        }
        if !avoidDuplicates || places!.contains(where: { $0.name == place.name && $0.reference == place.reference }) == false {
            places!.append(place)
            placesByKey[key] = places!
        }
    }
    
    let excludePlaces = ["Chihuahua", "Pacific Standard Time", "Mountain Standard Time", "Nogales", "Gulf of Mexico", "Guzmán Basin", "Rio Grande", "Colorado", "Guadalajara Line 3", "Mexikoplatz", "Mexikói út", "Frida Kahlo", "Zoe Saldaña", "Woman arrested with 130 poisonous frogs in luggage", "Aeromexico passenger opens plane door and walks on wing"]
    let allowDuplicates = ["castles", "currency"]
    
    func addPlaces(from countries: [String]) {
        for icon in countries {
            if let country = countryIndex[icon] {
                add(place: country, key: "countries")
                for (key, places) in country.placesByKey {
                    for place in places {
                        if place.been {
                            if !excludePlaces.contains(place.name) {
                                add(place: place, key: key,
                                    avoidDuplicates: !allowDuplicates.contains(key))
                            }
                        }
                    }
                }
            }
        }
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

        if let countries = placesByKey["countries"] as? [Country] {
            countries.forEach {
                body.append($0.htmlString(pageName: "countries"))
            }
        }
        
        if flag("border-zone") {
            body.append("🛂 Border<br>\n")
        } else if been {
            body.append("✅ Visited<br>\n")
        }
        
        countryFiles.forEach { flagFile in
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
                if ["highest", "lowest", "capitals", "official-languages"].contains(placeFile.key) && somePlaces.count == 1 {
                    flags["single"] = true
                }
                body.append(placeFile.link(flags))
                somePlaces.forEach {
                    body.append($0.htmlString(pageName: placeFile.key))
                }
                body.append("<div class=\"smallSpace\"><br></div>\n")
            }
        }
        
        file.contents = body
        return file
    }
}

func metaCountry(icon: String, name: String, countries: [String]) {
    let latam = Country(icon: icon, name: name)
    latam.addPlaces(from: countries)
    latam.countryFile().write()
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
        if (key != "similar-flags") {
            countryGroups[0].forEach { $0.been = true }
        }
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
    "🇽🇰": "Kosovo",
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
    "🇮🇨": "Canary Islands",
    "🏴󠁧󠁢󠁥󠁮󠁧󠁿": "England",
]

let countryCodes: [String: String] = [
    "🇦🇩": "AD",
    "🇦🇪": "AE",
    "🇦🇫": "AF",
    "🇦🇬": "AG",
    "🇦🇮": "AI",
    "🇦🇱": "AL",
    "🇦🇲": "AM",
    "🇦🇴": "AO",
    "🇦🇶": "AQ",
    "🇦🇷": "AR",
    "🇦🇸": "AS",
    "🇦🇹": "AT",
    "🇦🇺": "AU",
    "🇦🇼": "AW",
    "🇦🇽": "AX",
    "🇦🇿": "AZ",
    "🇧🇦": "BA",
    "🇧🇧": "BB",
    "🇧🇩": "BD",
    "🇧🇪": "BE",
    "🇧🇫": "BF",
    "🇧🇬": "BG",
    "🇧🇭": "BH",
    "🇧🇮": "BI",
    "🇧🇯": "BJ",
    "🇧🇱": "BL",
    "🇧🇲": "BM",
    "🇧🇳": "BN",
    "🇧🇴": "BO",
    "🇧🇶": "BQ",
    "🇧🇷": "BR",
    "🇧🇸": "BS",
    "🇧🇹": "BT",
    "🇧🇼": "BW",
    "🇧🇾": "BY",
    "🇧🇿": "BZ",
    "🇨🇦": "CA",
    "🇨🇨": "CC",
    "🇨🇩": "CD",
    "🇨🇫": "CF",
    "🇨🇬": "CG",
    "🇨🇭": "CH",
    "🇨🇮": "CI",
    "🇨🇰": "CK",
    "🇨🇱": "CL",
    "🇨🇲": "CM",
    "🇨🇳": "CN",
    "🇨🇴": "CO",
    "🇨🇷": "CR",
    "🇨🇺": "CU",
    "🇨🇻": "CV",
    "🇨🇼": "CW",
    "🇨🇽": "CX",
    "🇨🇾": "CY",
    "🇨🇿": "CZ",
    "🇩🇪": "DE",
    "🇩🇯": "DJ",
    "🇩🇰": "DK",
    "🇩🇲": "DM",
    "🇩🇴": "DO",
    "🇩🇿": "DZ",
    "🇪🇨": "EC",
    "🇪🇪": "EE",
    "🇪🇬": "EG",
    "🇪🇭": "EH",
    "🇪🇷": "ER",
    "🇪🇸": "ES",
    "🇪🇹": "ET",
    "🇫🇮": "FI",
    "🇫🇯": "FJ",
    "🇫🇰": "FK",
    "🇫🇲": "FM",
    "🇫🇴": "FO",
    "🇫🇷": "FR",
    "🇬🇦": "GA",
    "🇬🇧": "GB",
    "🇬🇩": "GD",
    "🇬🇪": "GE",
    "🇬🇫": "GF",
    "🇬🇬": "GG",
    "🇬🇭": "GH",
    "🇬🇮": "GI",
    "🇬🇱": "GL",
    "🇬🇲": "GM",
    "🇬🇳": "GN",
    "🇬🇵": "GP",
    "🇬🇶": "GQ",
    "🇬🇷": "GR",
    "🇬🇸": "GS",
    "🇬🇹": "GT",
    "🇬🇺": "GU",
    "🇬🇼": "GW",
    "🇬🇾": "GY",
    "🇭🇰": "HK",
    "🇭🇳": "HN",
    "🇭🇷": "HR",
    "🇭🇹": "HT",
    "🇭🇺": "HU",
    "🇮🇩": "ID",
    "🇮🇪": "IE",
    "🇮🇱": "IL",
    "🇮🇲": "IM",
    "🇮🇳": "IN",
    "🇮🇴": "IO",
    "🇮🇶": "IQ",
    "🇮🇷": "IR",
    "🇮🇸": "IS",
    "🇮🇹": "IT",
    "🇯🇪": "JE",
    "🇯🇲": "JM",
    "🇯🇴": "JO",
    "🇯🇵": "JP",
    "🇰🇪": "KE",
    "🇰🇬": "KG",
    "🇰🇭": "KH",
    "🇰🇮": "KI",
    "🇰🇲": "KM",
    "🇰🇳": "KN",
    "🇰🇵": "KP",
    "🇰🇷": "KR",
    "🇽🇰": "XK",
    "🇰🇼": "KW",
    "🇰🇾": "KY",
    "🇰🇿": "KZ",
    "🇱🇦": "LA",
    "🇱🇧": "LB",
    "🇱🇨": "LC",
    "🇱🇮": "LI",
    "🇱🇰": "LK",
    "🇱🇷": "LR",
    "🇱🇸": "LS",
    "🇱🇹": "LT",
    "🇱🇺": "LU",
    "🇱🇻": "LV",
    "🇱🇾": "LY",
    "🇲🇦": "MA",
    "🇲🇨": "MC",
    "🇲🇩": "MD",
    "🇲🇪": "ME",
    "🇲🇬": "MG",
    "🇲🇭": "MH",
    "🇲🇰": "MK",
    "🇲🇱": "ML",
    "🇲🇲": "MM",
    "🇲🇳": "MN",
    "🇲🇴": "MO",
    "🇲🇵": "MP",
    "🇲🇶": "MQ",
    "🇲🇷": "MR",
    "🇲🇸": "MS",
    "🇲🇹": "MT",
    "🇲🇺": "MU",
    "🇲🇻": "MV",
    "🇲🇼": "MW",
    "🇲🇽": "MX",
    "🇲🇾": "MY",
    "🇲🇿": "MZ",
    "🇳🇦": "NA",
    "🇳🇨": "NC",
    "🇳🇪": "NE",
    "🇳🇫": "NF",
    "🇳🇬": "NG",
    "🇳🇮": "NI",
    "🇳🇱": "NL",
    "🇳🇴": "NO",
    "🇳🇵": "NP",
    "🇳🇷": "NR",
    "🇳🇺": "NU",
    "🇳🇿": "NZ",
    "🇴🇲": "OM",
    "🇵🇦": "PA",
    "🇵🇪": "PE",
    "🇵🇫": "PF",
    "🇵🇬": "PG",
    "🇵🇭": "PH",
    "🇵🇰": "PK",
    "🇵🇱": "PL",
    "🇵🇲": "PM",
    "🇵🇳": "PN",
    "🇵🇷": "PR",
    "🇵🇸": "PS",
    "🇵🇹": "PT",
    "🇵🇼": "PW",
    "🇵🇾": "PY",
    "🇶🇦": "QA",
    "🇷🇪": "RE",
    "🇷🇴": "RO",
    "🇷🇸": "RS",
    "🇷🇺": "RU",
    "🇷🇼": "RW",
    "🇸🇦": "SA",
    "🇸🇧": "SB",
    "🇸🇨": "SC",
    "🇸🇩": "SD",
    "🇸🇪": "SE",
    "🇸🇬": "SG",
    "🇸🇭": "SH",
    "🇸🇮": "SI",
    "🇸🇰": "SK",
    "🇸🇱": "SL",
    "🇸🇲": "SM",
    "🇸🇳": "SN",
    "🇸🇴": "SO",
    "🇸🇷": "SR",
    "🇸🇸": "SS",
    "🇸🇹": "ST",
    "🇸🇻": "SV",
    "🇸🇽": "SX",
    "🇸🇾": "SY",
    "🇸🇿": "SZ",
    "🇹🇨": "TC",
    "🇹🇩": "TD",
    "🇹🇫": "TF",
    "🇹🇬": "TG",
    "🇹🇭": "TH",
    "🇹🇯": "TJ",
    "🇹🇰": "TK",
    "🇹🇱": "TL",
    "🇹🇲": "TM",
    "🇹🇳": "TN",
    "🇹🇴": "TO",
    "🇹🇷": "TR",
    "🇹🇹": "TT",
    "🇹🇻": "TV",
    "🇹🇼": "TW",
    "🇹🇿": "TZ",
    "🇺🇦": "UA",
    "🇺🇬": "UG",
    "🇺🇸": "US",
    "🇺🇾": "UY",
    "🇺🇿": "UZ",
    "🇻🇦": "VA",
    "🇻🇨": "VC",
    "🇻🇪": "VE",
    "🇻🇬": "VG",
    "🇻🇮": "VI",
    "🇻🇳": "VN",
    "🇻🇺": "VU",
    "🇼🇫": "WF",
    "🇼🇸": "WS",
    "🇾🇪": "YE",
    "🇾🇹": "YT",
    "🇿🇦": "ZA",
    "🇿🇲": "ZM",
    "🇿🇼": "ZW",
    "🇪🇺": "EU",
    "🇮🇨": "ES-CN",
    "🏴󠁧󠁢󠁥󠁮󠁧󠁿": "GB-ENG",
    "🏴󠁧󠁢󠁳󠁣󠁴󠁿": "GB-SCT",
    "🏴󠁧󠁢󠁷󠁬󠁳󠁿": "GB-WLS"
]

let countryEmoji = countryNames.keys
