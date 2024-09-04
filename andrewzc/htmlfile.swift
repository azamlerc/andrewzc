//
//  htmlfile.swift
//  andrewzc
//
//  Created by Andrew Zamler-Carhart on 7/29/23.
//

import Foundation

let folderPath = "/Users/andrew/Projects/andrewzc.net/"

var pageIndex = [String:HTMLFile]()

class HTMLFile {
    var key: String
    var filename: String
    var path: String
    
    var contents = ""
    var lines = [String]()
    var name = ""
    var icon = ""
    
    var rowGroups = [[Row]]()
    var entities = [Entity]()
    
    var data = [String:Any]()
    
    init(entity: Entity, folder: String) {
        self.key = entity.key
        self.filename = "\(key).html"
        self.name = entity.name
        self.icon = entity.icon
        self.path = "\(folderPath)\(folder)/\(filename)"
    }
    
    init(key: String) {
        self.key = key
        self.filename = "\(key).html"
        self.path = folderPath + filename
        
        read()
    }
    
    func read() {
        if let someContents = try? String(contentsOfFile: path) {
            contents = someContents
            name = getTitle(html: contents)
            if name.count > 2 {
                icon = String(name.first!)
                name = name.substring(from: 1).trim()
            }
            pageIndex[key] = self
            
            lines = getBody(html: contents).components(separatedBy: "\n")
                .map { $0.trim() }
                .map { $0.remove(trailing: "<br>") }
                .filter { $0.count > 2 }
            
            if key == "mosques" {
                lines = lines.filter { $0.hasPrefix("<a class=\"english") || $0.hasPrefix("<hr>") || $0.hasPrefix("<!--") }
            } else {
                lines = lines.filter { !$0.hasPrefix("<img") && !$0.hasPrefix("<a") && !$0.hasPrefix("<div") && !$0.hasPrefix("</div") && !$0.hasSuffix(":") && !($0.hasPrefix("<!--") && $0.hasSuffix("-->")) }
                if lines.count > 0 {
                    lines.removeFirst()
                }
            }
            let lineGroups = split(array: lines, delimiter: "<hr>")
            rowGroups = lineGroups.map { group in
                group.map { Row(text:$0, key: key) }
            }
        }
    }
    
    func write() {
        let newContents = htmlString()
        if let oldContents = try? String(contentsOfFile: path) {
            if oldContents == newContents {
                return
            }
        }
        
        do {
            try newContents.write(toFile: path, atomically: true, encoding: .utf8)
            print(filename)
        } catch {
            print("Error writing string to file: \(error)")
        }
    }
    
    func link() -> String {
        return link([:])
    }
    
    func link(_ params: [String:Any]) -> String {
        var nameHtml = name
        let htmlClass:String = params["htmlClass"] as? String ?? ""
        var extraHtml:String = params["extra"] as? String ?? ""
        
        if params["single"] != nil {
            nameHtml = String(name.dropLast())
            extraHtml = ""
        }
        if params["hideMusic"] != nil && nameHtml.hasPrefix("Music ") {
            nameHtml = nameHtml.substring(after: "Music ")
        }
        return "<a name=\"\(key)\"></a> \(icon) <a href=\"../\(filename)\" class=\"\(htmlClass)\">\(nameHtml)</a>\(extraHtml)<br>\n"
    }
    
    func htmlForRows() -> String {
        return rowGroups.map { group in
            return group.map { row in
                return row.htmlString()
            }.joined(separator: "")
        }.joined(separator: "\n<hr>\n\n")
    }
    
    func htmlString() -> String {
        return htmlHeader(title: self.icon + " " + self.name) + contents + htmlFooter()
    }
    
    func dataPath() -> String {
        return folderPath + "data/" + key + ".json"
    }

    func loadData() {
        if let json = loadJSONFromFile(atPath: dataPath()) {
            self.data = json
            
            for (key, value) in self.data {
                if var dict = value as? [String: Any] {
                    if let lat = dict["lat"], let long = dict["long"] {
                        dict["coords"] = "\(lat), \(long)"
                        dict.removeValue(forKey: "lat")
                        dict.removeValue(forKey: "long")
                        self.data[key] = dict
                    }
                }
            }
        }
    }
    
    func saveData() {
        writeJSONToFile(dictionary: self.data, atPath: dataPath())
        writeCSVToFile(dictionary: self.data, atPath: folderPath + "csv/" + key + ".csv")
    }
}

func parseIndexPage(key groupKey: String) {
    let indexFile = HTMLFile(key: groupKey)
    let rows = indexFile.rowGroups[0]
    rows.forEach { row in
        if let link = row.link {
            let key = link.remove(trailing: ".html")
            if !excludedFiles.contains(key) && !(crossLinkedFiles[groupKey]?.contains(key) ?? false) {
                loadPlaces(key: key)
            }
        }
    }
}

func getTitle(html: String) -> String {
    return html.substring(start: "<title>", end: "</title>") ?? ""
}

func getBody(html: String) -> String {
    return html.substring(start: "<body>", end: "</body>") ?? ""
}

func link(href: String, text: String) -> String {
    return "<a href=\"\(href)\">\(text)</a>"
}

func dark(_ value: Int) -> String {
    return "<span class=\"dark\">\(value)</span>"
}

func write(string: String, to filePath: String) {
    do {
        try string.write(toFile: filePath, atomically: true, encoding: .utf8)
    } catch {
        print("Error writing string to file: \(error)")
    }
}

func htmlHeader(title: String) -> String {
    return "<!DOCTYPE html>\n<html>\n<head>\n  <title>\(title)</title>\n    <meta charset=\"UTF-8\">\n    <meta name=\"viewport\" content=\"width=640\" />\n    <link rel=\"stylesheet\" href=\"../styles.css\">\n</head>\n<body>\n <div class=\"headline\">\n  \(title)\n </div>\n <div class=\"caption\">\n"
    
}

func htmlFooter() -> String {
    return " </div>\n</body>\n<script src=\"../typeahead.js\">\n</script></html>"
}
