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
    let funFact: String?
    let imageUrl: String?
    var hasBeenVisited: Bool
    let category: String

    enum CodingKeys: String, CodingKey {
        case id, name, description, latitude, longitude, order, category
        case routeId = "route_id"
        case triggerRadiusMeters = "trigger_radius_meters"
        case audioDurationSeconds = "audio_duration_seconds"
        case scriptEs = "script_es"
        case funFact = "fun_fact"
        case imageUrl = "image_url"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        routeId = try container.decode(String.self, forKey: .routeId)
        order = try container.decode(Int.self, forKey: .order)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        triggerRadiusMeters = try container.decodeIfPresent(Double.self, forKey: .triggerRadiusMeters) ?? 25.0
        audioDurationSeconds = try container.decodeIfPresent(Int.self, forKey: .audioDurationSeconds) ?? 60
        scriptEs = try container.decode(String.self, forKey: .scriptEs)
        funFact = try container.decodeIfPresent(String.self, forKey: .funFact)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        category = try container.decodeIfPresent(String.self, forKey: .category) ?? "general"
        hasBeenVisited = false // Siempre inicia en false, no viene de Firebase
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
}
