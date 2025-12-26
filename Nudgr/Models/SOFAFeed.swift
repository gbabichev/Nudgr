// periphery:ignore:all
import Foundation

struct SOFAFeed: Decodable {
    let version: String
    let updateHash: String
    let lastCheck: String?
    let osVersions: [SOFAOSVersion]
    let xProtectPlistConfigData: XProtectPlistConfigData?
    let xProtectPayloads: XProtectPayloads?
    let installationApps: InstallationApps?

    enum CodingKeys: String, CodingKey {
        case version = "Version"
        case updateHash = "UpdateHash"
        case lastCheck = "LastCheck"
        case osVersions = "OSVersions"
        case xProtectPlistConfigData = "XProtectPlistConfigData"
        case xProtectPayloads = "XProtectPayloads"
        case installationApps = "InstallationApps"
    }
}

struct SOFAOSVersion: Decodable {
    let osVersion: String
    let latest: SOFARelease?
    let securityReleases: [SOFARelease]?
    let supportedModels: [String]?

    enum CodingKeys: String, CodingKey {
        case osVersion = "OSVersion"
        case latest = "Latest"
        case securityReleases = "SecurityReleases"
        case supportedModels = "SupportedModels"
    }
}

struct SOFARelease: Decodable {
    let updateName: String?
    let productName: String?
    let productVersion: String?
    let build: String?
    let allBuilds: [String]?
    let releaseDate: String?
    let expirationDate: String?
    let releaseType: String?
    let securityInfo: String?
    let securityInfoContext: String?
    let supportedDevices: [String]?
    let cves: [String: SOFACVEInfo]?
    let activelyExploitedCVEs: [String]?
    let uniqueCVEsCount: Int?
    let daysSincePreviousRelease: Int?
    let updateSummary: SOFAUpdateSummary?

    enum CodingKeys: String, CodingKey {
        case updateName = "UpdateName"
        case productName = "ProductName"
        case productVersion = "ProductVersion"
        case build = "Build"
        case allBuilds = "AllBuilds"
        case releaseDate = "ReleaseDate"
        case expirationDate = "ExpirationDate"
        case releaseType = "ReleaseType"
        case securityInfo = "SecurityInfo"
        case securityInfoContext = "SecurityInfoContext"
        case supportedDevices = "SupportedDevices"
        case cves = "CVEs"
        case activelyExploitedCVEs = "ActivelyExploitedCVEs"
        case uniqueCVEsCount = "UniqueCVEsCount"
        case daysSincePreviousRelease = "DaysSincePreviousRelease"
        case updateSummary = "update_summary"
    }
}

struct SOFAUpdateSummary: Decodable {
    let priority: String?
    let summary: String?
    let recommendation: String?
    let stats: SOFAStats?
}

struct SOFAStats: Decodable {
    let exploited: Int?
    let critical: Int?
    let high: Int?
    let medium: Int?
    let low: Int?
    let remote: Int?
    let total: Int?
}

struct SOFACVEInfo: Decodable {
    let nistURL: String?
    let activelyExploited: Bool?
    let inKEV: Bool?
    let severity: String?

    enum CodingKeys: String, CodingKey {
        case nistURL = "nist_url"
        case activelyExploited = "actively_exploited"
        case inKEV = "in_kev"
        case severity
    }
}

struct XProtectPlistConfigData: Decodable {
    let comAppleXProtect: String?
    let releaseDate: String?

    enum CodingKeys: String, CodingKey {
        case comAppleXProtect = "com.apple.XProtect"
        case releaseDate = "ReleaseDate"
    }
}

struct XProtectPayloads: Decodable {
    let releaseDate: String?
    let pluginService: String?
    let xProtect: String?

    enum CodingKeys: String, CodingKey {
        case releaseDate = "ReleaseDate"
        case pluginService = "com.apple.XProtectFramework.PluginService"
        case xProtect = "com.apple.XProtectFramework.XProtect"
    }
}

struct InstallationApps: Decodable {
    let latestUMA: InstallationApp?
    let allPreviousUMA: [InstallationApp]?
    let latestMacIPSW: MacIPSW?

    enum CodingKeys: String, CodingKey {
        case latestUMA = "LatestUMA"
        case allPreviousUMA = "AllPreviousUMA"
        case latestMacIPSW = "LatestMacIPSW"
    }
}

struct InstallationApp: Decodable {
    let title: String?
    let version: String?
    let build: String?
    let appleSlug: String?
    let url: String?
    let postingDate: String?
    let size: Int?

    enum CodingKeys: String, CodingKey {
        case title
        case version
        case build
        case appleSlug = "apple_slug"
        case url
        case postingDate = "posting_date"
        case size
    }
}

struct MacIPSW: Decodable {
    let url: String?
    let build: String?
    let version: String?
    let appleSlug: String?

    enum CodingKeys: String, CodingKey {
        case url = "macos_ipsw_url"
        case build = "macos_ipsw_build"
        case version = "macos_ipsw_version"
        case appleSlug = "macos_ipsw_apple_slug"
    }
}

struct SOFAMajorSummary {
    let major: Int
    let productVersion: String
    let releaseDate: String
    let activelyExploitedCount: Int
    let activelyExploitedList: [String]
    let hasAnyCVE: Bool
    let requiredInstallDate: String?
    let nudgeLaunchDate: String?
    var highlight: Bool = false
}
