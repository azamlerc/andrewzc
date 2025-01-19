//
//  entity.swift
//  andrewzc
//
//  Created by Andrew Zamler-Carhart on 7/29/23.
//

import Foundation

class Entity: CustomStringConvertible {
    var icon: String
    var icons: [String]
    var iconModifier: String?
    var name: String
    var key: String
    var link: String?
    var prefix: String?
    var info: String?
    var reference: String?
    var strike = false
    var flags = [String:Bool]()
    var metadata = [String:String]() // wasteful to initialize this for every object?
    var score = 0
    
    init(row: Row) {
        self.icon = row.icon
        self.icons = row.icons
        self.iconModifier = row.iconModifier
        self.name = row.name
        self.key = simplify(row.name)
        self.link = row.link
        self.prefix = row.prefix
        self.info = row.info
        self.reference = row.reference
        self.strike = row.strike
    }
    
    init(icon: String, name: String) {
        self.icon = icon
        self.icons = [icon]
        self.name = name
        self.key = simplify(name)
    }
    
    var description: String {
        return "\(icon) \(name)"
    }

    var fileLink: String {
        return "\(key).html"
    }

    func htmlString(pageName: String? = nil) -> String {
        if let theLink = link {
            return "\(icon) <a href=\"\(theLink)\">\(name)</a><br>\n"
        } else {
            return "\(icon) \(name)<br>\n"
        }
    }
    
    func flag(_ key: String) -> Bool {
        return self.flags[key] ?? false
    }
    
    func setFlag(_ key: String) {
        self.flags[key] = true
        score += 1
    }
}

func simplify(_ value: String) -> String {
    return value.lowercased()
        .replacingOccurrences(of: " ", with: "-")
        .replacingOccurrences(of: "’", with: "")
        .replacingOccurrences(of: ".", with: "")
        .replacingOccurrences(of: ",", with: "")
        .replacingOccurrences(of: "*", with: "")
        .replacingOccurrences(of: "\"", with: "")
        .replacingOccurrences(of: "<", with: "")
        .replacingOccurrences(of: ">", with: "")
        .folding(options: .diacriticInsensitive, locale: .current)
        .replacingOccurrences(of: "the-", with: "")
}
