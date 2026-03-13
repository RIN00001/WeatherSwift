import Foundation

@MainActor
extension WeatherViewModel {
    static var previewLoaded: WeatherViewModel {
        let viewModel = WeatherViewModel(repository: WeatherRepository(service: PreviewOpenMeteoService()))
        viewModel.weather = .mock
        viewModel.viewState = .loaded
        return viewModel
    }
}

private struct PreviewOpenMeteoService: OpenMeteoServicing {
    func fetchWeather(latitude: Double, longitude: Double) async throws -> OpenMeteoWeatherResponse {
        OpenMeteoWeatherResponse(
            latitude: latitude,
            longitude: longitude,
            timezone: "America/Los_Angeles",
            current: .init(
                time: ISO8601DateFormatter().string(from: .now),
                temperature2m: 23,
                relativeHumidity2m: 55,
                apparentTemperature: 24,
                weatherCode: 1,
                windSpeed10m: 13,
                windDirection10m: 230,
                pressureMsl: 1016,
                precipitation: 0,
                cloudCover: 20
            )
        )
    }

    func searchCities(query: String) async throws -> [OpenMeteoGeocodingResponse.CityResult] {
        [
            .init(id: 1, name: "Cupertino", latitude: 37.323, longitude: -122.032, country: "United States", admin1: "California")
        ]
    }
}
