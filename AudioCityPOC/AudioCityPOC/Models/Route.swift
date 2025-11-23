//
//  Route.swift
//  AudioCityPOC
//
//  Created by JuanRa Fernandez on 23/11/25.
//


//
//  Route.swift
//  AudioCityPOC
//

import Foundation
import CoreLocation

struct Route: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let city: String
    let neighborhood: String
    let durationMinutes: Int
    let distanceKm: Double
    let difficulty: String
    let numStops: Int
    let language: String
    let isActive: Bool
    let createdAt: String
    let updatedAt: String
    let thumbnailUrl: String
    let startLocation: Location
    let endLocation: Location
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, city, neighborhood, difficulty, language
        case durationMinutes = "duration_minutes"
        case distanceKm = "distance_km"
        case numStops = "num_stops"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case thumbnailUrl = "thumbnail_url"
        case startLocation = "start_location"
        case endLocation = "end_location"
    }
    
    struct Location: Codable {
        let latitude: Double
        let longitude: Double
        let name: String
        
        var coordinate: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }
}