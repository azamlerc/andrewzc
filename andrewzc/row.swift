//
//  row.swift
//  andrewzc
//
//  Created by Andrew Zamler-Carhart on 9/6/23.
//

import Foundation

class Row {
    var name: String
    var icon: String
    var iconModifier: String?
    var link: String?
    var comment: String?
    var reference: String?
    var strike = false
    var prefix: String?
    var info: String?
    
    var entity: Entity?
    
    init(text theText: String, key: String) {
        var text = theText
        
        if key == "currency" {
            text = text.substring(start: "<td>", end: "</td>") ?? ""
        }
        
        if text.hasPrefix("<!--") && text.contains("-->") {
            self.comment = text.substring(start: "<!--", end: "-->")?.trim()
            text = text.substring(after: "-->").trim()
        }
        
        if text.contains("<!--") && text.hasSuffix("-->") {
            self.comment = text.substring(start: "<!--", end: "-->")?.trim()
            text = text.substring(before: "-->").trim()
        }
        
        if yearPrefix.contains(key) && text.count > 5 {
            prefix = text.substring(before: " ")
            text = text.substring(after: " ")
        }

        if key == "airports" && text.contains("airport") {
            prefix = text.substring(start: "airport\">", end: "</span>")
            text = text.substring(after: "</span> ")
        }
            
        if text.contains("<span class=\"dark\">") {
            reference = text.substring(start: "<span class=\"dark\">", end: "</span>")?.trim()
            text = text.substring(before: "<span class=\"dark\">").trim() // removes everything after span
        }
        
        if key == "mosques" {
            self.icon = text.substring(start: "<span>", end: "</span>") ?? ""
            self.name = text.substring(start: "\">", end: "</a>") ?? ""
            self.link = text.substring(start: "href=\"", end: "\">") ?? ""
        } else if key == "metros" && comment != nil {
            let last = comment!.last!
            if last.isEmoji() {
                self.icon = String(last)
                if text.contains(".png\"> ") {
                    text = text.substring(after: ".png\"> ")
                }
                self.name = text
            } else {
                self.icon = String(text.first!)
                if text.contains(".png\"> ") {
                    text = text.substring(after: ".png\"> ")
                }
                self.name = text.substring(from: 1).trim()
            }
        } else if key == "deaths" && comment != nil {
            let last = comment!.last!
            if last.isEmoji() {
                self.icon = String(last)
            } else {
                self.icon = String(text.first!)
            }
            self.name = text.substring(from: 1).trim()
        } else if text.count > 2 {
            self.icon = String(text.first!)
            self.name = text.substring(from: 1).trim()
        } else {
            self.icon = ""
            self.name = text
        }
        
        if self.name.contains("class=\"strike\"") {
            strike = true
        }
        
        if key == "worldsfair" && name.contains(", ") {
            let parts = name.components(separatedBy: ", ")
            if (parts.count == 2) {
                name = parts[0]
                info = ", " + parts[1] // handle this
            }
        }
        
        while name.count > 0 && name.last!.isEmoji() {
            iconModifier = String(name.last!) + (iconModifier ?? "")
            name = String(name.dropLast()).trim()
        }
        
        if name.hasPrefix("<a href") {
            link = name.substring(start: "href=\"", end: "\"")
            if let newName = name.substring(start: "\">", end: "</a>") {
                let more = name.substring(after: "</a>")
                name = newName
                if more.count > 0 {
                    info = more
                }
            }
        }

        if name.hasPrefix("<span class=\"strike\">") {
            if let newName = name.substring(start: "<span class=\"strike\">", end: "</span>") {
                name = newName
                // throws away stuff after the link
            }
        }
    }
    
    func htmlString() -> String {
        guard entity != nil else {
            return ""
        }
        return "\(icon) <a href=\"\(entity!.fileLink)\">\(name)</a><br>\n"
    }
}
