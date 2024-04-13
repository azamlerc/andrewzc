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
    
}

extension Character {
    func isEmoji() -> Bool {
        if self == "2️⃣" || self == "7️⃣" {
            return true
        }
        if self.isNumber {
            return false
        }
        guard let scalar = self.unicodeScalars.first else { return false }
        return scalar.properties.isEmoji
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

