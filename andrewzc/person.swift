//
//  person.swift
//  andrewzc
//
//  Created by Andrew Zamler-Carhart on 10/15/23.
//

import Foundation

var personIndex = [String:Person]()
var personFiles = [HTMLFile]()

class Person: Entity {
    var country: Country?
    var favorite = false
    var timeline: String?
    
    var thingsByKey = [String:[Thing]]()
    
    override init(row: Row) {
        super.init(row: row)
    }
    
    override init(icon: String, name: String) {
        super.init(icon: icon, name: name)
    }
    
    func add(thing: Thing, key: String) {
        var things = thingsByKey[key]
        if things == nil {
            things = [Thing]()
        }
        things!.append(thing)
        thingsByKey[key] = things!
        score += 1
    }
    
    override func htmlString(pageName: String? = nil) -> String {
        let iconHtml = icons.joined(separator: " ")
        let classHtml = strike ? " class=\"strike\"" : ""
        var nameHtml = link == nil ? name : "<a href=\"\(link!)\"\(classHtml)>\(name)</a>"
        if let horns = iconModifier {
            nameHtml = "\(nameHtml) \(horns)"
        }
        var line = "\(iconHtml) \(nameHtml)\(info ?? "")<br>\n"
        if prefix != nil {
            line = "\(prefix!) \(line)"
        }
        if country != nil && country!.icon != icon {
            line = "<!--\(country!.icon)-->\(line)"
        }
        return line
    }
    
    class func getPerson(row: Row) -> Person {
        if let person = personIndex[row.name] {
            return person
        } else {
            let person = Person(row: row)
            personIndex[row.name] = person
            
            if person.link == nil && row.link != nil {
                person.link = row.link
            }
            
            var icon = row.icon
            if row.comment != nil && row.comment!.count == 1 { // handle vanity emoji with country in comment
                icon = row.comment!
            }
            
            if let country = countryIndex[icon] {
                person.country = country
                country.people.append(person)
            } else {
                print("Not a country: \(icon)")
            }
            
            return person
        }
    }
    
    class func getPerson(icon: String?, name: String) -> Person {
        if let person = personIndex[name] {
            if person.icon == "" && icon != nil {
                person.icon = icon!
            }
            return person
        } else {
            let person = Person(icon: icon ?? "", name: name)
            personIndex[name] = person
            return person
        }
    }
    
    func artistFile() -> HTMLFile {
        let file = HTMLFile(entity: self, folder: "artists")
        
        var body = ""
        
        personFiles.forEach { personFile in
            if flag(personFile.key) {
                body.append(personFile.link())
            }
        }
        
        if body.count > 0 {
            body.append("<div class=\"smallSpace\"><br></div>\n")
        }

        let max = 10
        
        personFiles.forEach { personFile in
            if let things = thingsByKey[personFile.key] {
                var flags:[String:Any] = ["htmlClass": "link", "hideMusic": true]
                flags["extra"] = things.count > max ? " (\(things.count))" : ""
                let someThings = things.count > max ? Array(things[0..<max]) : things
                if ["artist-names", "music-origins"].contains(personFile.key) && someThings.count == 1 {
                    flags["single"] = true
                }
                body.append(personFile.link(flags))
                someThings.forEach {
                    body.append($0.htmlString(pageName: self.name))
                }
                body.append("<div class=\"smallSpace\"><br></div>\n")
            }
        }
        
        if let timeline = self.timeline {
            body.append("🎸 <a href=\"../band-members.html\" class=\"link\">Band Members</a><br>\n")
            body.append("<img src=\"\(timeline)\"><br>\n")
        }
        
        file.contents = body
        return file
    }
}

func loadPeople(key: String) -> [Person] {
    let favorite = key == "artists"
    guard !key.hasPrefix("http") else {
        return [Person]()
    }
    let peopleFile = HTMLFile(key: key)
    personFiles.append(peopleFile)
    let personGroups = peopleFile.rowGroups.map { group in
        return group.map { row in
            let person = Person.getPerson(row: row)
            person.favorite = favorite
            return person
        }
    }
    let people = personGroups.flatMap { $0 }
    peopleFile.entities = people
    return people
}

