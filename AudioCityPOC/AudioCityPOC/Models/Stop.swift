//
//  Stop.swift
//  AudioCityPOC
//

import Foundation
import CoreLocation

struct Stop: Identifiable, Codable {
    let id: String
    let routeId: String
    let order: Int
    let name: String
    let description: String
    let latitude: Double
    let longitude: Double
    let triggerRadiusMeters: Double
    let audioDurationSeconds: Int
    let scriptEs: String
    let funFact: String
    let imageUrl: String
    var hasBeenVisited: Bool  // Ahora es var normal, no @Published
    let category: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, latitude, longitude, order, category
        case routeId = "route_id"
        case triggerRadiusMeters = "trigger_radius_meters"
        case audioDurationSeconds = "audio_duration_seconds"
        case scriptEs = "script_es"
        case funFact = "fun_fact"
        case imageUrl = "image_url"
        case hasBeenVisited = "has_been_visited"
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
}
