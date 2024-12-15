//
//  json.swift
//  andrewzc
//
//  Created by Andrew Zamler-Carhart on 5/12/24.
//

import Foundation

func loadJSONFromFile(atPath path: String) -> [String: Any]? {
    if FileManager.default.fileExists(atPath: path) {
        if let data = FileManager.default.contents(atPath: path) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    return json
                } else {
                    print("Failed to parse JSON.")
                }
            } catch {
                print("Error decoding JSON: \(error.localizedDescription) \(path)")
            }
        } else {
            print("Failed to read data from file.")
        }
    }
    return nil
}

func writeJSONToFile(dictionary: [String: Any], atPath path: String) {
    do {
        // let jsonData = try JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted)
        if let jsonData = dictionary.jsonDataWithSortedKeys() {
            try jsonData.write(to: URL(fileURLWithPath: path), options: .atomic)
        } else {
            print("Error writing JSON data to file")
        }
    } catch {
        print("Error writing JSON data to file:", error.localizedDescription)
    }
}

func writeCSVToFile(dictionary: [String: Any], atPath path: String) {
    var rows = [String]()
    for (_, foo) in dictionary {
        if let dict = foo as? [String:Any], let coords = dict["coords"] as? String {
            let latlong = coords.components(separatedBy: ",").map { $0.trim() }
            let been = dict["been"] != nil && (dict["been"] as! Bool) ? "been" : "todo"
            if latlong.count == 2 {
                let values = [dict["name"] ?? "", latlong[0], latlong[1], been]
                rows.append(values.map { "\"\($0)\"" }.joined(separator: ","))
            }
        }
    }
    let output = "\"name\",\"latitude\",\"longitude\",\"been\"\n" + rows.sorted().joined(separator: "\n")
    do {
        try output.write(to: URL(fileURLWithPath: path), atomically: true, encoding: String.Encoding.utf8)
    } catch {
        print("Error writing JSON data to file:", error.localizedDescription)
    }
}

func loadJSONFromURL(url: URL, apiKey: String?) -> [String: Any]? {
    var jsonData: [String: Any]?
    let semaphore = DispatchSemaphore(value: 0)
    
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    if let key = apiKey {
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
    }
    
    let urlSession = URLSession(configuration: .ephemeral)
    let task = urlSession.dataTask(with: request) { data, response, error in
        defer { semaphore.signal() }
        
        guard let data = data, error == nil else {
            print("Error: \(error?.localizedDescription ?? "Unknown error")")
            return
        }
        
        do {
            // Try to decode JSON data into a dictionary
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                jsonData = json
            } else {
                print("Failed to parse JSON.")
            }
        } catch {
            print("Error decoding JSON: \(error.localizedDescription)")
        }
    }
    
    task.resume()
    semaphore.wait()
    
    return jsonData
}

extension Dictionary where Key == String, Value: Any {
    func jsonDataWithSortedKeys() -> Data? {
        func sortAndSerialize(_ dict: [String: Any], indentLevel: Int) -> String {
            let indent = String(repeating: "  ", count: indentLevel)
            var jsonString = "{\n"
            
            for (index, key) in dict.keys.sorted().enumerated() {
                jsonString += indent + "  \"\(key)\": "
                
                if let nestedDict = dict[key] as? [String: Any] {
                    jsonString += sortAndSerialize(nestedDict, indentLevel: indentLevel + 1)
                } else if let boolValue = dict[key] as? Bool {
                    jsonString += boolValue ? "true" : "false"
                } else if let stringValue = dict[key] as? String {
                    jsonString += "\"\(stringValue.replacingOccurrences(of: "\"", with: "\\\""))\""
                } else if let numberValue = dict[key] as? NSNumber {
                    jsonString += "\(numberValue)"
                } else if let arrayValue = dict[key] as? [Any] {
                    jsonString += serializeArray(arrayValue, indentLevel: indentLevel + 1)
                } else if dict[key] is NSNull {
                    jsonString += "null"
                }
                
                if index < dict.keys.count - 1 {
                    jsonString += ",\n"
                }
            }
            
            jsonString += "\n\(indent)}"
            return jsonString
        }
        
        func serializeArray(_ array: [Any], indentLevel: Int) -> String {
            var jsonString = "["
            
            for (index, value) in array.enumerated() {
                if index > 0 {
                    jsonString += ", "
                }
                
                if let stringValue = value as? String {
                    jsonString += "\"\(stringValue.replacingOccurrences(of: "\"", with: "\\\""))\""
                } else if let boolValue = value as? Bool {
                    jsonString += boolValue ? "true" : "false"
                } else if let numberValue = value as? NSNumber {
                    jsonString += "\(numberValue)"
                } else if let dictValue = value as? [String: Any] {
                    jsonString += sortAndSerialize(dictValue, indentLevel: indentLevel + 1)
                } else if let arrayValue = value as? [Any] {
                    jsonString += serializeArray(arrayValue, indentLevel: indentLevel + 1)
                } else if value is NSNull {
                    jsonString += "null"
                }
            }
            
            jsonString += "]"
            return jsonString
        }
        
        let jsonString = sortAndSerialize(self, indentLevel: 0)
        return jsonString.data(using: .utf8)
    }
}
