import Foundation

enum SOFAFeedServiceError: Error {
    case invalidURL
}

struct SOFAFeedService {
    private static let feedURLString = "https://sofafeed.macadmins.io/v2/macos_data_feed.json"

    static func fetch() async throws -> SOFAFeed {
        guard let url = URL(string: feedURLString) else {
            throw SOFAFeedServiceError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw NSError(domain: "SOFAFeedService", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(http.statusCode)"])
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        return try decoder.decode(SOFAFeed.self, from: data)
    }
}
