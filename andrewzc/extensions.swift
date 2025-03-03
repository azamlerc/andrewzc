//
//  extensions.swift
//  andrewzc
//
//  Created by Andrew Zamler-Carhart on 7/29/23.
//

import Foundation

extension String {
    
    func substring(start: String, end: String) -> String? {
        if let startRange = self.range(of: start), let endRange = self.range(of: end, range: startRange.upperBound..<self.endIndex) {
            return String(self[startRange.upperBound..<endRange.lowerBound])
        }
        return nil
    }
    
    func substring(after: String) -> String {
        if let startRange = self.range(of: after) {
            return String(self[startRange.upperBound...])
        }
        return self
    }
    
    func substring(before: String) -> String {
        if let startRange = self.range(of: before) {
            return String(self[..<startRange.lowerBound])
        }
        return self
    }
    
    func substring(from index: Int) -> String {
        let start = self.index(self.startIndex, offsetBy: index)
        let substring = self[start..<self.endIndex]
        return String(substring)
    }
    
    func trim() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
        
    }
    
    func remove(trailing: String) -> String {
        if self.hasSuffix(trailing) {
            return String(self.dropLast(trailing.count))
        } else {
            return self
        }
    }
    
    subscript(offset: Int) -> Character {
        self[index(startIndex, offsetBy: offset)]
    }
    
    func removeAccents() -> String {
        return self.folding(options: .diacriticInsensitive, locale: .current)
    }
    
    func getCoordinates() -> [String] {
        let pattern = "\\{\\{[Cc]oord\\|([^}]+)\\}\\}"
        var results: [String] = []
        
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let range = NSRange(self.startIndex..<self.endIndex, in: self)
            let matches = regex.matches(in: self, options: [], range: range)
            
            for match in matches {
                if let coordinatesRange = Range(match.range(at: 1), in: self) {
                    results.append(String(self[coordinatesRange]))
                }
            }
        }
        
        return results
    }
}

extension Character {
    func isEmoji() -> Bool {
        if "0️⃣1️⃣2️⃣3️⃣4️⃣5️⃣6️⃣7️⃣8️⃣9️⃣".contains(self) {
            return true
        }
        if self.isNumber {
            return false
        }
        guard let scalar = self.unicodeScalars.first else { return false }
        return scalar.properties.isEmoji
    }
}

extension Array where Element:Equatable {
    func removeDuplicates() -> [Element] {
        var result = [Element]()

        for value in self {
            if result.contains(value) == false {
                result.append(value)
            }
        }

        return result
    }
}

func split(array: [String], delimiter: String) -> [[String]] {
    var output = [[String]]()
    var chunk = [String]()
    
    for item in array {
        if item != delimiter {
            chunk.append(item)
        } else {
            output.append(chunk)
            chunk = [String]()
        }
    }
    
    output.append(chunk)
    return output
}

func queryStringToDict(query: String) -> [String: String] {
    var dict = [String: String]()

    let pairs = query.components(separatedBy: "&")
    for pair in pairs {
        let elements = pair.components(separatedBy: "=")
        if elements.count == 2 {
            let key = elements[0]
            let value = elements[1]
            dict[key] = value
        }
    }

    return dict
}

func convertToDecimal(coords: String) throws -> String {
    let regexPattern = #"""
    (\d{1,3})°(\d{1,2})′(\d{1,2}(?:\.\d+)?)″([NSWE])|  # DMS with direction
    (\d{1,3})°(\d{1,2}(?:\.\d+)?)′([NSWE])|           # DM with direction
    (\d{1,3})°([NSWE])|                               # D with direction
    ([+-]?\d*\.?\d+)(°?\s?)([NSWE]?)                 # Decimal with optional direction
    """#

    let regex = try NSRegularExpression(pattern: regexPattern, options: .allowCommentsAndWhitespace)
    
    let components = coords.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
    guard components.count == 2 else {
        throw NSError(domain: "InvalidCoordinate", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid coordinate format"])
    }

    let decimalCoordinates = try components.map { component -> Double in
        let range = NSRange(location: 0, length: component.utf16.count)
        guard let match = regex.firstMatch(in: component, options: [], range: range) else {
            throw NSError(domain: "InvalidCoordinate", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid coordinate format"])
        }

        var decimalDegrees: Double = 0
        var degrees: Double = 0
        var minutes: Double = 0
        var seconds: Double = 0
        var direction: String?

        if let degreesRange = Range(match.range(at: 1), in: component),
           let minutesRange = Range(match.range(at: 2), in: component),
           let secondsRange = Range(match.range(at: 3), in: component),
           let directionRange = Range(match.range(at: 4), in: component) {
            // DMS format
            degrees = Double(component[degreesRange]) ?? 0
            minutes = Double(component[minutesRange]) ?? 0
            seconds = Double(component[secondsRange]) ?? 0
            direction = String(component[directionRange])
        } else if let degreesRange = Range(match.range(at: 5), in: component),
                  let minutesRange = Range(match.range(at: 6), in: component),
                  let directionRange = Range(match.range(at: 7), in: component) {
            // DM format
            degrees = Double(component[degreesRange]) ?? 0
            minutes = Double(component[minutesRange]) ?? 0
            direction = String(component[directionRange])
        } else if let degreesRange = Range(match.range(at: 8), in: component),
                  let directionRange = Range(match.range(at: 9), in: component) {
            // D format
            degrees = Double(component[degreesRange]) ?? 0
            direction = String(component[directionRange])
        } else if let decimalRange = Range(match.range(at: 10), in: component),
                  let directionRange = Range(match.range(at: 12), in: component) {
            // Decimal format with direction
            decimalDegrees = Double(component[decimalRange]) ?? 0
            direction = String(component[directionRange])
            if direction == "S" || direction == "W" {
                decimalDegrees = -decimalDegrees
            }
            return decimalDegrees
        } else if let decimalRange = Range(match.range(at: 10), in: component) {
            // Decimal format without direction
            decimalDegrees = Double(component[decimalRange]) ?? 0
            return decimalDegrees
        }

        // Convert to decimal degrees
        decimalDegrees = degrees + (minutes / 60) + (seconds / 3600)

        // Apply direction
        if direction == "S" || direction == "W" {
            decimalDegrees = -decimalDegrees
        }

        return decimalDegrees
    }
    
    return String(format: "%.8f, %.8f", decimalCoordinates[0], decimalCoordinates[1])
}
