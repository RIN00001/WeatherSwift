import SwiftUI

struct BookmarkWeatherCard: View {
    let bookmark: BookmarkedLocation
    let weather: WeatherSnapshot?

    @State private var shimmer = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(bookmark.name)
                        .font(.headline)
                        .lineLimit(2)
                    if let weather {
                        Text(weather.condition.title)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Loading weather")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if bookmark.isDefault {
                    Label("Default", systemImage: "star.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.yellow)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.thinMaterial, in: Capsule())
                }
            }

            if let weather {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(weather.temperature, format: .number.precision(.fractionLength(0)))
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .contentTransition(.numericText(value: weather.temperature))
                    Text("°C")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 14) {
                    miniMetric(systemImage: "humidity.fill", value: "\(weather.humidity)%")
                    miniMetric(systemImage: "wind", value: "\(weather.windSpeed, format: .number.precision(.fractionLength(1))) km/h")
                    miniMetric(systemImage: weather.condition.symbolName, value: weather.condition.title)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            } else {
                ProgressView()
                    .tint(.white)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    .white.opacity(shimmer ? 0.17 : 0.08),
                                    .clear,
                                    .white.opacity(shimmer ? 0.06 : 0.02)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .animation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true), value: shimmer)
                }
        }
        .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
        .onAppear { shimmer = true }
    }

    private func miniMetric(systemImage: String, value: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
            Text(value)
        }
    }
}
