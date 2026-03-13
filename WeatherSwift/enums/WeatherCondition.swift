import SwiftUI

enum WeatherCondition: Equatable {
    case clear
    case partlyCloudy
    case cloudy
    case fog
    case drizzle
    case rain
    case snow
    case thunderstorm
    case unknown

    init(code: Int) {
        switch code {
        case 0: self = .clear
        case 1, 2: self = .partlyCloudy
        case 3: self = .cloudy
        case 45, 48: self = .fog
        case 51, 53, 55, 56, 57: self = .drizzle
        case 61, 63, 65, 66, 67, 80, 81, 82: self = .rain
        case 71, 73, 75, 77, 85, 86: self = .snow
        case 95, 96, 99: self = .thunderstorm
        default: self = .unknown
        }
    }

    var title: String {
        switch self {
        case .clear: return "Clear"
        case .partlyCloudy: return "Partly Cloudy"
        case .cloudy: return "Cloudy"
        case .fog: return "Foggy"
        case .drizzle: return "Drizzle"
        case .rain: return "Rain"
        case .snow: return "Snow"
        case .thunderstorm: return "Thunderstorm"
        case .unknown: return "Unknown"
        }
    }

    var symbolName: String {
        switch self {
        case .clear: return "sun.max.fill"
        case .partlyCloudy: return "cloud.sun.fill"
        case .cloudy: return "cloud.fill"
        case .fog: return "cloud.fog.fill"
        case .drizzle: return "cloud.drizzle.fill"
        case .rain: return "cloud.rain.fill"
        case .snow: return "snow"
        case .thunderstorm: return "cloud.bolt.rain.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }

    var gradient: LinearGradient {
        let colors: [Color]

        switch self {
        case .clear:
            colors = [Color.blue.opacity(0.85), Color.cyan.opacity(0.7)]
        case .partlyCloudy:
            colors = [Color.indigo.opacity(0.8), Color.blue.opacity(0.65)]
        case .cloudy:
            colors = [Color.gray.opacity(0.85), Color.blue.opacity(0.45)]
        case .fog:
            colors = [Color.gray.opacity(0.85), Color.mint.opacity(0.35)]
        case .drizzle, .rain:
            colors = [Color.indigo.opacity(0.9), Color.blue.opacity(0.6)]
        case .snow:
            colors = [Color.cyan.opacity(0.4), Color.blue.opacity(0.7)]
        case .thunderstorm:
            colors = [Color.purple.opacity(0.85), Color.indigo.opacity(0.9)]
        case .unknown:
            colors = [Color.gray.opacity(0.75), Color.blue.opacity(0.5)]
        }

        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}
