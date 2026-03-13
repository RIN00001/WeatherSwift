import Foundation

enum URLRequestBuilder {
    static func makeURL(base: String, path: String, queryItems: [URLQueryItem]) throws -> URL {
        guard var components = URLComponents(string: base) else {
            throw URLError(.badURL)
        }
        components.path = path
        components.queryItems = queryItems

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        return url
    }
}
