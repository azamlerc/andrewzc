//
//  thing.swift
//  andrewzc
//
//  Created by Andrew Zamler-Carhart on 10/15/23.
//

import Foundation

class Thing: Entity {
    var people = [Person]()
    
    func htmlString(person: Person) -> String {
        let iconHtml = icons.joined(separator: " ")
        let classHtml = strike ? " class=\"strike\"" : ""
        var nameHtml = name
        var iconOrderHack = false
        if nameHtml.count == 0 && reference == person.name {
            nameHtml = person.name
            iconOrderHack = true
        }
        nameHtml = link == nil ? nameHtml : "<a href=\"\(link!)\"\(classHtml)>\(nameHtml)</a>"
        if reference != nil && reference != person.name {
            nameHtml += " <span class=\"dark\">\(reference!)</span>"
        }
        if let modifier = iconModifier {
            if iconOrderHack {
                nameHtml = "\(modifier) \(nameHtml)"
            } else {
                nameHtml = "\(nameHtml) \(modifier)"
            }
        }
        var line = "\(iconHtml) \(nameHtml)\(info ?? "")<br>\n"
        if prefix != nil {
            line = "\(prefix!) \(line)"
        }
        return line
    }

    class func getThing(row: Row) -> Thing {
        let thing = Thing(row: row)
        if let reference = row.reference {
            let country = countryIndex[row.icon]
            thing.people.append(Person.getPerson(icon: country?.icon, name: reference))
            
            if row.comment != nil {
                if let band = personIndex[row.comment!] {
                    thing.people.append(band)
                }
            }
        }
        if let band = personIndex[row.name] { // will this always work?
            thing.people.append(band)
        }
        return thing
    }
}

func loadPersonThings(key: String) {
    let file = HTMLFile(key: key)
    personFiles.append(file)
    let things = file.rowGroups.map { group in
        return group.map { row in
            let thing = Thing.getThing(row: row)
            thing.people.forEach { person in
                person.add(thing: thing, key: key)
            }
            return thing
        }
    }.flatMap { $0 }
    file.entities = things
}

func loadBandMembers() {
    let file = HTMLFile(key: "band-members")
    file.lines.forEach { line in
        let name = line.substring(before: "<br>")
        let timeline = line.substring(start: "src=\"", end: "\">")
        if let person = personIndex[name] {
            person.timeline = timeline
        }
    }
}

