import SwiftUI

struct BookmarksView: View {
    @ObservedObject var viewModel: WeatherViewModel

    var body: some View {
        Group {
            if viewModel.bookmarks.isEmpty {
                ContentUnavailableView(
                    "No Bookmarks Yet",
                    systemImage: "bookmark",
                    description: Text("Search for a city and tap the bookmark icon to save it.")
                )
            } else {
                List {
                    ForEach(viewModel.bookmarks) { bookmark in
                        BookmarkWeatherCard(
                            bookmark: bookmark,
                            weather: viewModel.bookmarkWeather[bookmark.id]
                        )
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                if let index = viewModel.bookmarks.firstIndex(of: bookmark) {
                                    viewModel.removeBookmarks(at: IndexSet(integer: index))
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button {
                                viewModel.setDefaultBookmark(bookmark)
                            } label: {
                                Label("Set Default", systemImage: bookmark.isDefault ? "star.fill" : "star")
                            }
                            .tint(.yellow)
                        }
                        .onTapGesture {
                            Task { await viewModel.loadBookmark(bookmark) }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Bookmarks")
        .task {
            await viewModel.refresh()
        }
    }
}

#Preview {
    NavigationStack {
        BookmarksView(viewModel: .previewLoaded)
    }
}
