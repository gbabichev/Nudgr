import Foundation

struct NudgeConfig: Decodable {
    let osVersionRequirements: [OSVersionRequirement]
    let optionalFeatures: OptionalFeatures?
    let userExperience: UserExperience?
}

struct OSVersionRequirement: Decodable {
    let requiredMinimumOSVersion: String
    let targetedOSVersionsRule: String?
    let activelyExploitedCVEsMajorUpgradeSLA: Int?
    let activelyExploitedCVEsMinorUpdateSLA: Int?
    let nonActivelyExploitedCVEsMajorUpgradeSLA: Int?
    let nonActivelyExploitedCVEsMinorUpdateSLA: Int?
    let standardMajorUpgradeSLA: Int?
    let standardMinorUpdateSLA: Int?
}

struct OptionalFeatures: Decodable {
    let utilizeSOFAFeed: Bool?
    let disableNudgeForStandardInstalls: Bool?
}

struct UserExperience: Decodable {
    let nudgeMajorUpgradeEventLaunchDelay: Int?
    let nudgeMinorUpdateEventLaunchDelay: Int?
}
