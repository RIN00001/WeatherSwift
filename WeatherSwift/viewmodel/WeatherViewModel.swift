import Combine
import CoreLocation
import Foundation

@MainActor
final class WeatherViewModel: ObservableObject {
    enum ViewState: Equatable {
        case idle
        case loading
        case loaded
        case empty
        case error(String)
    }

    @Published var viewState: ViewState = .idle
    @Published var weather: WeatherSnapshot?
    @Published var searchText: String = ""
    @Published private(set) var searchResults: [OpenMeteoGeocodingResponse.CityResult] = []
    @Published private(set) var isSearching = false
    @Published private(set) var bookmarks: [BookmarkedLocation] = []
    @Published private(set) var bookmarkWeather: [UUID: WeatherSnapshot] = [:]

    private let repository: WeatherRepositoryProtocol
    private let locationService: LocationService
    private let bookmarkStorage: BookmarkStorageProtocol
    private var autoRefreshTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    private var selectedCity: OpenMeteoGeocodingResponse.CityResult?

    init(
        repository: WeatherRepositoryProtocol = WeatherRepository(),
        locationService: LocationService = LocationService(),
        bookmarkStorage: BookmarkStorageProtocol = BookmarkStorageService()
    ) {
        self.repository = repository
        self.locationService = locationService
        self.bookmarkStorage = bookmarkStorage
        self.bookmarks = bookmarkStorage.loadBookmarks()

        bindLocation()
        bindSearch()
    }

    var locationAuthorization: CLAuthorizationStatus {
        locationService.authorizationStatus
    }

    var defaultBookmark: BookmarkedLocation? {
        bookmarks.first(where: { $0.isDefault })
    }

    func onAppear() {
        locationService.requestPermissionIfNeeded()
        if locationService.canUseLocation {
            locationService.requestLocation()
        }

        startAutoRefresh()
        Task { await refreshBookmarkedWeather() }

        guard weather == nil else { return }

        if let defaultBookmark {
            Task { await loadBookmark(defaultBookmark) }
        } else {
            Task { await loadDefaultCityWeather() }
        }
    }

    func onDisappear() {
        autoRefreshTask?.cancel()
        autoRefreshTask = nil
    }

    func refresh() async {
        if let location = locationService.lastKnownLocation, locationService.canUseLocation {
            await loadWeather(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                cityName: "Current Location"
            )
        } else if let city = selectedCity {
            await loadWeather(latitude: city.latitude, longitude: city.longitude, cityName: city.fullName)
        } else if let weather {
            await loadWeather(latitude: weather.latitude, longitude: weather.longitude, cityName: weather.cityName)
        } else if let defaultBookmark {
            await loadBookmark(defaultBookmark)
        } else {
            await loadDefaultCityWeather()
        }

        await refreshBookmarkedWeather()
    }

    func requestLocationRefresh() {
        locationService.requestPermissionIfNeeded()
        locationService.requestLocation()
    }

    func selectCity(_ city: OpenMeteoGeocodingResponse.CityResult) async {
        selectedCity = city
        await loadWeather(latitude: city.latitude, longitude: city.longitude, cityName: city.fullName)
        searchText = ""
        searchResults = []
    }

    func addBookmark(for city: OpenMeteoGeocodingResponse.CityResult) async {
        guard !isBookmarked(city) else { return }

        let item = BookmarkedLocation(
            name: city.fullName,
            latitude: city.latitude,
            longitude: city.longitude,
            isDefault: bookmarks.isEmpty
        )
        bookmarks.append(item)
        persistBookmarks()
        await fetchWeatherForBookmark(item)
    }

    func removeBookmarks(at offsets: IndexSet) {
        let removedDefault = offsets.contains { bookmarks[$0].isDefault }
        let ids = offsets.map { bookmarks[$0].id }

        bookmarks.remove(atOffsets: offsets)
        ids.forEach { bookmarkWeather[$0] = nil }

        if removedDefault, let first = bookmarks.first {
            setDefaultBookmark(first)
        } else {
            persistBookmarks()
        }
    }

    func setDefaultBookmark(_ bookmark: BookmarkedLocation) {
        bookmarks = bookmarks.map {
            var mutable = $0
            mutable.isDefault = mutable.id == bookmark.id
            return mutable
        }
        persistBookmarks()
    }

    func loadBookmark(_ bookmark: BookmarkedLocation) async {
        selectedCity = OpenMeteoGeocodingResponse.CityResult(
            id: Int(abs(bookmark.latitude * 1000 + bookmark.longitude * 1000)),
            name: bookmark.name,
            latitude: bookmark.latitude,
            longitude: bookmark.longitude,
            country: "",
            admin1: nil
        )
        await loadWeather(latitude: bookmark.latitude, longitude: bookmark.longitude, cityName: bookmark.name)
    }

    func isBookmarked(_ city: OpenMeteoGeocodingResponse.CityResult) -> Bool {
        bookmarks.contains(where: { $0.matches(city: city) })
    }

    private func bindLocation() {
        locationService.$lastKnownLocation
            .compactMap { $0 }
            .sink { [weak self] location in
                guard let self else { return }
                Task {
                    if self.defaultBookmark == nil {
                        self.selectedCity = nil
                        await self.loadWeather(
                            latitude: location.coordinate.latitude,
                            longitude: location.coordinate.longitude,
                            cityName: "Current Location"
                        )
                    }
                }
            }
            .store(in: &cancellables)
    }

    private func bindSearch() {
        $searchText
            .debounce(for: .milliseconds(350), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                guard let self else { return }
                Task { await self.performSearch(query: query) }
            }
            .store(in: &cancellables)
    }

    private func performSearch(query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            searchResults = []
            return
        }

        isSearching = true
        defer { isSearching = false }

        do {
            searchResults = try await repository.searchCities(query: trimmed)
        } catch {
            searchResults = []
        }
    }

    private func loadDefaultCityWeather() async {
        let defaultCity = OpenMeteoGeocodingResponse.CityResult(
            id: 1,
            name: "San Francisco",
            latitude: 37.7749,
            longitude: -122.4194,
            country: "United States",
            admin1: "California"
        )
        await selectCity(defaultCity)
    }

    private func loadWeather(latitude: Double, longitude: Double, cityName: String) async {
        if weather == nil {
            viewState = .loading
        }

        do {
            let snapshot = try await repository.fetchWeather(latitude: latitude, longitude: longitude, cityName: cityName)
            withAnimation(.easeInOut(duration: 0.3)) {
                weather = snapshot
                viewState = .loaded
            }
        } catch {
            viewState = .error("Could not fetch weather right now. Pull to refresh or try searching for another city.")
        }
    }

    private func refreshBookmarkedWeather() async {
        for bookmark in bookmarks {
            await fetchWeatherForBookmark(bookmark)
        }
    }

    private func fetchWeatherForBookmark(_ bookmark: BookmarkedLocation) async {
        do {
            let snapshot = try await repository.fetchWeather(
                latitude: bookmark.latitude,
                longitude: bookmark.longitude,
                cityName: bookmark.name
            )
            bookmarkWeather[bookmark.id] = snapshot
        } catch {
            bookmarkWeather[bookmark.id] = nil
        }
    }

    private func persistBookmarks() {
        bookmarkStorage.saveBookmarks(bookmarks)
    }

    private func startAutoRefresh() {
        guard autoRefreshTask == nil else { return }
        autoRefreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(3600))
                guard !Task.isCancelled, let self else { return }
                await self.refresh()
            }
        }
    }
}
