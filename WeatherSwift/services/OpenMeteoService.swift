import Foundation

protocol OpenMeteoServicing {
    func fetchWeather(latitude: Double, longitude: Double) async throws -> OpenMeteoWeatherResponse
    func searchCities(query: String) async throws -> [OpenMeteoGeocodingResponse.CityResult]
}

final class OpenMeteoService: OpenMeteoServicing {
    private let session: URLSession
    private let weatherBaseURL = "https://api.open-meteo.com"
    private let geocodingBaseURL = "https://geocoding-api.open-meteo.com"

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchWeather(latitude: Double, longitude: Double) async throws -> OpenMeteoWeatherResponse {
        let currentFields = [
            "temperature_2m",
            "relative_humidity_2m",
            "apparent_temperature",
            "weather_code",
            "wind_speed_10m",
            "wind_direction_10m",
            "pressure_msl",
            "precipitation",
            "cloud_cover"
        ].joined(separator: ",")

        let url = try URLRequestBuilder.makeURL(
            base: weatherBaseURL,
            path: "/v1/forecast",
            queryItems: [
                .init(name: "latitude", value: String(latitude)),
                .init(name: "longitude", value: String(longitude)),
                .init(name: "current", value: currentFields),
                .init(name: "timezone", value: "auto")
            ]
        )

        let (data, response) = try await session.data(from: url)
        try validateHTTP(response)

        let decoder = JSONDecoder()
        return try decoder.decode(OpenMeteoWeatherResponse.self, from: data)
    }

    func searchCities(query: String) async throws -> [OpenMeteoGeocodingResponse.CityResult] {
        let url = try URLRequestBuilder.makeURL(
            base: geocodingBaseURL,
            path: "/v1/search",
            queryItems: [
                .init(name: "name", value: query),
                .init(name: "count", value: "10"),
                .init(name: "language", value: "en"),
                .init(name: "format", value: "json")
            ]
        )

        let (data, response) = try await session.data(from: url)
        try validateHTTP(response)

        let decoded = try JSONDecoder().decode(OpenMeteoGeocodingResponse.self, from: data)
        return decoded.results ?? []
    }

    private func validateHTTP(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
}
