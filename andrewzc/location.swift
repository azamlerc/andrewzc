//
//  location.swift
//  andrewzc
//
//  Created by Andrew Zamler-Carhart on 1/23/25.
//

import Foundation

class Location {
    var latitude: Double
    var longitude: Double
    
    // Constructor to parse latitude and longitude from a string
    init?(coords: String) {
        let components = coords.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        
        guard components.count == 2,
              let lat = Double(components[0]),
              let lon = Double(components[1]) else {
            return nil
        }
        
        self.latitude = lat
        self.longitude = lon
    }
    
    // Method to calculate the "distance" to another Location
    func distance(to other: Location) -> Double {
        let latitudeDifference = abs(self.latitude - other.latitude)
        let longitudeDifference = abs(self.longitude - other.longitude)
        return latitudeDifference + longitudeDifference
    }
    
    func stringValue() -> String {
        return String(format: "%.8f, %.8f", latitude, longitude)
    }
}
