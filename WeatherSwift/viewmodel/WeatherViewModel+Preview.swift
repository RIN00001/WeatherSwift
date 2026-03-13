import Foundation

@MainActor
extension WeatherViewModel {
    static var previewLoaded: WeatherViewModel {
        let previewBookmark = BookmarkedLocation(
            name: "Tokyo, Japan",
            latitude: 35.6764,
            longitude: 139.6500,
            isDefault: true
        )

        let viewModel = WeatherViewModel(
            repository: WeatherRepository(service: PreviewOpenMeteoService()),
            bookmarkStorage: PreviewBookmarkStorage(initial: [previewBookmark])
        )
        viewModel.weather = .mock
        viewModel.viewState = .loaded
        viewModel.bookmarkWeather[previewBookmark.id] = .mock
        return viewModel
    }
}

private struct PreviewBookmarkStorage: BookmarkStorageProtocol {
    let initial: [BookmarkedLocation]

    func loadBookmarks() -> [BookmarkedLocation] { initial }
    func saveBookmarks(_ bookmarks: [BookmarkedLocation]) {}
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
