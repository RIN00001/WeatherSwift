import CoreLocation
import SwiftUI

struct WeatherHomeView: View {
    @StateObject private var viewModel: WeatherViewModel

    init(viewModel: WeatherViewModel = WeatherViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                WeatherAnimatedBackground(condition: viewModel.weather?.condition ?? .partlyCloudy)

                ScrollView {
                    VStack(spacing: 20) {
                        content
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.vertical, 16)
                }
                .refreshable {
                    await viewModel.refresh()
                }
            }
            .navigationTitle("Weather")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        Task { await viewModel.refresh() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }

                    if viewModel.locationAuthorization != .authorizedAlways && viewModel.locationAuthorization != .authorizedWhenInUse {
                        Button {
                            viewModel.requestLocationRefresh()
                        } label: {
                            Image(systemName: "location")
                        }
                    }
                }
            }
            .searchable(text: $viewModel.searchText, prompt: "Search city")
            .overlay(alignment: .top) {
                if !viewModel.searchResults.isEmpty {
                    searchResultsOverlay
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.25), value: viewModel.searchResults)
        }
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.viewState {
        case .idle, .loading:
            ProgressView("Loading weather…")
                .padding(.top, 120)
                .transition(.opacity)
        case .error(let message):
            ContentUnavailableView("Weather Unavailable", systemImage: "wifi.exclamationmark", description: Text(message))
                .padding(.top, 80)
                .transition(.opacity)
        case .empty:
            ContentUnavailableView("No data", systemImage: "cloud")
                .padding(.top, 80)
                .transition(.opacity)
        case .loaded:
            if let weather = viewModel.weather {
                WeatherHeaderCard(snapshot: weather)
                    .scrollTransition { content, phase in
                        content
                            .scaleEffect(phase.isIdentity ? 1 : 0.96)
                            .opacity(phase.isIdentity ? 1 : 0.78)
                    }

                WeatherDetailsGrid(snapshot: weather)
                    .scrollTransition { content, phase in
                        content
                            .offset(y: phase.isIdentity ? 0 : 18)
                            .opacity(phase.isIdentity ? 1 : 0.7)
                    }
            }
        }
    }

    private var searchResultsOverlay: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.searchResults, id: \.id) { city in
                Button {
                    Task { await viewModel.selectCity(city) }
                } label: {
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundStyle(.secondary)
                        Text(city.fullName)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)

                Divider()
            }
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, horizontalPadding)
        .padding(.top, 8)
        .shadow(color: .black.opacity(0.08), radius: 10, y: 6)
    }

    private var horizontalPadding: CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad ? 80 : 20
    }
}

#Preview {
    WeatherHomeView(viewModel: .previewLoaded)
}
