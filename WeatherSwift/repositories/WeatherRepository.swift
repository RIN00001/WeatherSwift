import Foundation

protocol WeatherRepositoryProtocol {
    func fetchWeather(latitude: Double, longitude: Double, cityName: String) async throws -> WeatherSnapshot
    func searchCities(query: String) async throws -> [OpenMeteoGeocodingResponse.CityResult]
}

struct WeatherRepository: WeatherRepositoryProtocol {
    private let service: OpenMeteoServicing

    init(service: OpenMeteoServicing = OpenMeteoService()) {
        self.service = service
    }

    func fetchWeather(latitude: Double, longitude: Double, cityName: String) async throws -> WeatherSnapshot {
        let response = try await service.fetchWeather(latitude: latitude, longitude: longitude)
        return mapResponse(response, cityName: cityName)
    }

    func searchCities(query: String) async throws -> [OpenMeteoGeocodingResponse.CityResult] {
        try await service.searchCities(query: query)
    }

    private func mapResponse(_ response: OpenMeteoWeatherResponse, cityName: String) -> WeatherSnapshot {
        let current = response.current
        return WeatherSnapshot(
            cityName: cityName,
            latitude: response.latitude,
            longitude: response.longitude,
            observedAt: ISO8601DateFormatter().date(from: current.time) ?? .now,
            temperature: current.temperature2m,
            apparentTemperature: current.apparentTemperature,
            humidity: current.relativeHumidity2m,
            windSpeed: current.windSpeed10m,
            windDirection: current.windDirection10m,
            pressure: current.pressureMsl,
            precipitation: current.precipitation,
            cloudCover: current.cloudCover,
            weatherCode: current.weatherCode
        )
    }
}
