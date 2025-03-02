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
    var icons = [String]()
    var states = [String]()
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
        
        // handle vanity emoji with country in comment
        if comment != nil {
            while comment?.last?.isEmoji() == true {
                let icon = comment!.removeLast()
                icons.append(String(icon))
                comment = comment!.trim()
            }
        }
        
        if yearPrefix.contains(key) && text.count > 5 {
            prefix = text.substring(before: " ")
            text = text.substring(after: " ")
        }

        if key == "airports" && text.contains("airport") {
            prefix = text.substring(start: "airport\">", end: "</span>")
            text = text.substring(after: "</span> ")
        }

        if key == "projects" {
            if text.contains("<span class=\"dark\">") {
                self.reference = text.substring(start: "<span class=\"dark\">", end: "</span>")?.trim()
                text = text.replacingOccurrences(of: "<span class=\"dark\">", with: "")
                text = text.replacingOccurrences(of: "</span>", with: "")
            }
        }
        
        if text.contains("<span class=\"dark\">") || text.contains("<span class=\"airport\">") {
            self.reference = text.substring(start: "<span class=\"dark\">", end: "</span>")?.trim() ??
                text.substring(start: "<span class=\"airport\">", end: "</span>")?.trim()
            if referenceBefore.contains(key) {
                while (text.count > 1 && text.first!.isEmoji()) {
                    let emoji = String(text.first!)
                    if !icons.contains(emoji) {
                        icons.append(emoji)
                    }
                    text = text.substring(from: 1).trim()
                }
                text = text.substring(after: "</span>").trim() // removes everything after span
            } else {
                text = text.substring(before: "<span").trim() // removes everything before span
            }
        }
        
        if text.hasPrefix("<img") && text.contains("images/states/") {
            icons.append("🇺🇸")
            while text.hasPrefix("<img") && text.contains("images/states/") {
                if let state = text.substring(start: "images/states/", end: ".png\">")?.uppercased() {
                    self.states.append(state)
                    text = text.substring(after: "\">").trim()
                } else {
                    break
                }
            }
        }
        
        if key == "mosques" {
            self.icon = text.substring(start: "<span>", end: "</span>") ?? ""
            self.name = text.substring(start: "\">", end: "</a>") ?? ""
            self.link = text.substring(start: "href=\"", end: "\">") ?? ""
            icons.append(icon)
        } else if key == "deaths" && comment != nil {
            let last = comment!.last!
            if last.isEmoji() {
                self.icon = String(last)
            } else {
                self.icon = String(text.first!)
            }
            self.name = text.substring(from: 1).trim()
        } else {
            while (text.count > 1 && text.first!.isEmoji()) {
                let emoji = String(text.first!)
                if !icons.contains(emoji) {
                    icons.append(emoji)
                }
                text = text.substring(from: 1).trim()
            }
            self.icon = icons.first ?? ""
            self.name = text
        }
        
        if self.name.contains("class=\"strike\"") {
            strike = true
        }
        
        while name.count > 0 && name.last!.isEmoji() {
            iconModifier = String(name.last!) + (iconModifier ?? "")
            name = String(name.dropLast()).trim()
        }
        
        if name.contains("<img") && name.contains(".png") {
            if let _ = name.substring(start: "src=\"", end: "\"") {
                name = name.substring(after: ".png\">").trim()
            }
        }

        if name.contains("<a href") {
            link = name.substring(start: "href=\"", end: "\"")
            if let newName = name.substring(start: "\">", end: "</a>") {
                let more = name.substring(after: "</a>")
                name = newName
                if more.count > 0 {
                    info = more.replacingOccurrences(of: ",", with: "").trim()
                }
            } else {
                print("\(key) couldn't get text between \"> and </a>: \(name)")
            }
        }
        
        if name.hasSuffix("*") {
            name = name.substring(before: "*")
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
