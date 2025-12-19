import Foundation

enum SOFAFeedServiceError: Error {
    case invalidURL
}

enum SOFAFeedSource {
    case network
    case cache(error: Error)
}

struct SOFAFeedService {
    private static let feedURLString = "https://sofafeed.macadmins.io/v2/macos_data_feed.json"

    static func fetch() async throws -> (SOFAFeed, SOFAFeedSource) {
        guard let url = URL(string: feedURLString) else {
            throw SOFAFeedServiceError.invalidURL
        }

        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                throw NSError(domain: "SOFAFeedService", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(http.statusCode)"])
            }

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .useDefaultKeys
            return (try decoder.decode(SOFAFeed.self, from: data), .network)
        } catch {
            let cacheRequest = URLRequest(url: url)
            if let cached = URLCache.shared.cachedResponse(for: cacheRequest) {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .useDefaultKeys
                let feed = try decoder.decode(SOFAFeed.self, from: cached.data)
                return (feed, .cache(error: error))
            }
            throw error
        }
    }
}
