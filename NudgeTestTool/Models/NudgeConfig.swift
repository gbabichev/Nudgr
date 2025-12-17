import Foundation

struct NudgeConfig: Decodable {
    let osVersionRequirements: [OSVersionRequirement]
    let optionalFeatures: OptionalFeatures?
}

struct OSVersionRequirement: Decodable {
    let requiredMinimumOSVersion: String
    let targetedOSVersionsRule: String?
}

struct OptionalFeatures: Decodable {
    let utilizeSOFAFeed: Bool?
}
