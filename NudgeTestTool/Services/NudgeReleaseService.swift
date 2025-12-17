import Foundation

enum NudgeReleaseError: Error {
    case invalidResponse
}

struct NudgeReleaseService {
    struct GitHubRelease: Decodable {
        let tag_name: String
    }

    static func latestVersion() async throws -> String {
        guard let url = URL(string: "https://api.github.com/repos/macadmins/nudge/releases/latest") else {
            throw NudgeReleaseError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("CodexNudgeTool", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            let body = String(data: data, encoding: .utf8) ?? ""
            let err = "HTTP \(http.statusCode): \(body)"
            throw NSError(domain: "NudgeReleaseService", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: err])
        }

        let decoder = JSONDecoder()
        let release = try decoder.decode(GitHubRelease.self, from: data)
        return release.tag_name
    }
}
