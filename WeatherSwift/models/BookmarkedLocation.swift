import Foundation

struct BookmarkedLocation: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let latitude: Double
    let longitude: Double
    var isDefault: Bool

    init(
        id: UUID = UUID(),
        name: String,
        latitude: Double,
        longitude: Double,
        isDefault: Bool = false
    ) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.isDefault = isDefault
    }

    func matches(city: OpenMeteoGeocodingResponse.CityResult) -> Bool {
        abs(latitude - city.latitude) < 0.001 && abs(longitude - city.longitude) < 0.001
    }
}
