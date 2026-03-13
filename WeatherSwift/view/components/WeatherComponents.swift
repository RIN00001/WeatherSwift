import SwiftUI

struct WeatherAnimatedBackground: View {
    let condition: WeatherCondition

    @State private var animate = false

    var body: some View {
        ZStack {
            condition.gradient
                .overlay {
                    LinearGradient(
                        colors: [.black.opacity(0.2), .clear, .black.opacity(0.15)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.8), value: condition)

            Circle()
                .fill(.white.opacity(0.16))
                .frame(width: 260, height: 260)
                .blur(radius: 30)
                .offset(x: animate ? 120 : -120, y: animate ? -320 : -220)

            Circle()
                .fill(.white.opacity(0.12))
                .frame(width: 220, height: 220)
                .blur(radius: 35)
                .offset(x: animate ? -140 : 130, y: animate ? 250 : 310)

            Circle()
                .fill(.white.opacity(0.1))
                .frame(width: 180, height: 180)
                .blur(radius: 24)
                .offset(x: animate ? -95 : 100, y: animate ? -40 : 60)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 7).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

struct WeatherHeaderCard: View {
    let snapshot: WeatherSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(snapshot.cityName)
                        .font(.title3.weight(.semibold))
                    Text(snapshot.condition.title)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: snapshot.condition.symbolName)
                    .font(.system(size: 36))
                    .symbolRenderingMode(.multicolor)
                    .transition(.scale.combined(with: .opacity))
            }

            HStack(alignment: .top, spacing: 2) {
                Text(snapshot.temperature, format: .number.precision(.fractionLength(0)))
                    .contentTransition(.numericText(value: snapshot.temperature))
                    .font(.system(size: 84, weight: .bold, design: .rounded))
                Text("°C")
                    .font(.title.weight(.medium))
                    .padding(.top, 18)
            }

            Text("Feels like \(snapshot.apparentTemperature, format: .number.precision(.fractionLength(0)))°C")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(snapshot.observedAt, style: .time)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
    }
}

struct WeatherMetricCard: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: systemImage)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title3.weight(.semibold))
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

struct WeatherDetailsGrid: View {
    let snapshot: WeatherSnapshot

    private var cards: [(String, String, String)] {
        [
            ("Humidity", "\(snapshot.humidity)%", "humidity.fill"),
            ("Wind", "\(snapshot.windSpeed, format: .number.precision(.fractionLength(1))) km/h", "wind"),
            ("Direction", "\(snapshot.windDirection)°", "location.north.line.fill"),
            ("Pressure", "\(snapshot.pressure, format: .number.precision(.fractionLength(0))) hPa", "gauge.medium"),
            ("Precipitation", "\(snapshot.precipitation, format: .number.precision(.fractionLength(1))) mm", "cloud.rain"),
            ("Cloud Cover", "\(snapshot.cloudCover)%", "smoke.fill")
        ]
    }

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 12)], spacing: 12) {
            ForEach(Array(cards.enumerated()), id: \.offset) { index, item in
                WeatherMetricCard(title: item.0, value: item.1, systemImage: item.2)
                    .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity), removal: .opacity))
                    .animation(.spring(response: 0.5, dampingFraction: 0.82).delay(Double(index) * 0.04), value: snapshot)
            }
        }
    }
}
