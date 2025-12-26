// periphery:ignore:all

import Foundation

struct NudgeConfig: Decodable {
    let osVersionRequirements: [OSVersionRequirement]
    let optionalFeatures: OptionalFeatures?
    let userExperience: UserExperience?
}

struct OSVersionRequirement: Decodable {
    let requiredMinimumOSVersion: String
    let targetedOSVersionsRule: String?
    let requiredInstallationDate: String?
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
    let aggressiveUserExperience: Bool?
    let aggressiveUserFullScreenExperience: Bool?
}

struct UserExperience: Decodable {
    let allowGracePeriods: Bool?
    let allowLaterDeferralButton: Bool?
    let allowMovableWindow: Bool?
    let allowUserQuitDeferrals: Bool?
    let allowedDeferrals: Int?
    let allowedDeferralsUntilForcedSecondaryQuitButton: Int?
    let approachingRefreshCycle: Int?
    let approachingWindowTime: Int?
    let calendarDeferralUnit: String?
    let elapsedRefreshCycle: Int?
    let gracePeriodInstallDelay: Int?
    let gracePeriodLaunchDelay: Int?
    let gracePeriodPath: String?
    let imminentRefreshCycle: Int?
    let imminentWindowTime: Int?
    let initialRefreshCycle: Int?
    let launchAgentIdentifier: String?
    let loadLaunchAgent: Bool?
    let maxRandomDelayInSeconds: Int?
    let noTimers: Bool?
    let nudgeMajorUpgradeEventLaunchDelay: Int?
    let nudgeMinorUpdateEventLaunchDelay: Int?
    let nudgeRefreshCycle: Int?
    let randomDelay: Bool?
}
