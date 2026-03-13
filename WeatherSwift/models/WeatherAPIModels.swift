import Foundation

struct OpenMeteoWeatherResponse: Decodable {
    let latitude: Double
    let longitude: Double
    let timezone: String
    let current: CurrentWeather

    struct CurrentWeather: Decodable {
        let time: String
        let temperature2m: Double
        let relativeHumidity2m: Int
        let apparentTemperature: Double
        let weatherCode: Int
        let windSpeed10m: Double
        let windDirection10m: Int
        let pressureMsl: Double
        let precipitation: Double
        let cloudCover: Int

        enum CodingKeys: String, CodingKey {
            case time
            case temperature2m = "temperature_2m"
            case relativeHumidity2m = "relative_humidity_2m"
            case apparentTemperature = "apparent_temperature"
            case weatherCode = "weather_code"
            case windSpeed10m = "wind_speed_10m"
            case windDirection10m = "wind_direction_10m"
            case pressureMsl = "pressure_msl"
            case precipitation
            case cloudCover = "cloud_cover"
        }
    }
}

struct OpenMeteoGeocodingResponse: Decodable {
    let results: [CityResult]?

    struct CityResult: Decodable, Identifiable, Hashable {
        let id: Int
        let name: String
        let latitude: Double
        let longitude: Double
        let country: String
        let admin1: String?

        var fullName: String {
            [name, admin1, country]
                .compactMap { $0 }
                .joined(separator: ", ")
        }
    }
}

struct WeatherSnapshot: Equatable {
    let cityName: String
    let latitude: Double
    let longitude: Double
    let observedAt: Date
    let temperature: Double
    let apparentTemperature: Double
    let humidity: Int
    let windSpeed: Double
    let windDirection: Int
    let pressure: Double
    let precipitation: Double
    let cloudCover: Int
    let weatherCode: Int

    var condition: WeatherCondition {
        WeatherCondition(code: weatherCode)
    }
}

enum WeatherDataSource: Equatable {
    case currentLocation
    case city(OpenMeteoGeocodingResponse.CityResult)
}

extension WeatherSnapshot {
    static let mock = WeatherSnapshot(
        cityName: "Cupertino, CA",
        latitude: 37.323,
        longitude: -122.032,
        observedAt: .now,
        temperature: 23.4,
        apparentTemperature: 24.1,
        humidity: 58,
        windSpeed: 11.8,
        windDirection: 240,
        pressure: 1015,
        precipitation: 0.0,
        cloudCover: 23,
        weatherCode: 1
    )
}
