import Foundation

protocol BookmarkStorageProtocol {
    func loadBookmarks() -> [BookmarkedLocation]
    func saveBookmarks(_ bookmarks: [BookmarkedLocation])
}

struct BookmarkStorageService: BookmarkStorageProtocol {
    private let userDefaults: UserDefaults
    private let key = "bookmarked.locations"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func loadBookmarks() -> [BookmarkedLocation] {
        guard let data = userDefaults.data(forKey: key) else { return [] }

        do {
            return try JSONDecoder().decode([BookmarkedLocation].self, from: data)
        } catch {
            return []
        }
    }

    func saveBookmarks(_ bookmarks: [BookmarkedLocation]) {
        do {
            let data = try JSONEncoder().encode(bookmarks)
            userDefaults.set(data, forKey: key)
        } catch {
            print("Failed to persist bookmarks: \(error.localizedDescription)")
        }
    }
}
