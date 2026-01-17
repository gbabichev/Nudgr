import SwiftUI
import Foundation
import AppKit
import UniformTypeIdentifiers

struct OSVersionRequirementDraft: Identifiable {
    let id = UUID()
    var requiredMinimumOSVersion: String = "latest"
    var requiredInstallationDate: String = ""
    var targetedOSVersionsRule: String = "default"
    var aboutUpdateURL: String = ""
    var aboutUpdateURLs: String = ""
    var actionButtonPath: String = ""
    var majorUpgradeAppPath: String = ""
    var activelyExploitedCVEsMajorUpgradeSLA: String = ""
    var activelyExploitedCVEsMinorUpdateSLA: String = ""
    var nonActivelyExploitedCVEsMajorUpgradeSLA: String = ""
    var nonActivelyExploitedCVEsMinorUpdateSLA: String = ""
    var standardMajorUpgradeSLA: String = ""
    var standardMinorUpdateSLA: String = ""
    var presentKeys: Set<String> = []
}

struct FieldBlock<Content: View>: View {
    let title: String
    let detail: String?
    @ViewBuilder let content: Content

    init(_ title: String, detail: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.detail = detail
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            if let detail, !detail.isEmpty {
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            content
        }
    }
}

struct JSONBuilder: View {
    @Environment(\.dismiss) private var dismissView
    @ObservedObject var model: NudgeViewModel
    @Binding var loadFromSelection: Bool
    @State private var acceptableApplicationBundleIDs: String = ""
    @State private var acceptableAssertionApplicationNames: String = ""
    @State private var acceptableAssertionUsage: Bool = false
    @State private var acceptableCameraUsage: Bool = false
    @State private var acceptableUpdatePreparingUsage: Bool = true
    @State private var acceptableScreenSharingUsage: Bool = false
    @State private var aggressiveUserExperience: Bool = true
    @State private var aggressiveUserFullScreenExperience: Bool = true
    @State private var asynchronousSoftwareUpdate: Bool = true
    @State private var attemptToBlockApplicationLaunches: Bool = false
    @State private var attemptToCheckForSupportedDevice: Bool = true
    @State private var attemptToFetchMajorUpgrade: Bool = true
    @State private var blockedApplicationBundleIDs: String = ""
    @State private var customSOFAFeedURL: String = ""
    @State private var disableNudgeForStandardInstalls: Bool = false
    @State private var disableSoftwareUpdateWorkflow: Bool = false
    @State private var enforceMinorUpdates: Bool = true
    @State private var honorFocusModes: Bool = false
    @State private var refreshSOFAFeedTime: String = "86400"
    @State private var terminateApplicationsOnLaunch: Bool = false
    @State private var utilizeSOFAFeed: Bool = true
    @State private var osVersionRequirements: [OSVersionRequirementDraft] = [OSVersionRequirementDraft()]
    @State private var allowGracePeriods: Bool = false
    @State private var allowLaterDeferralButton: Bool = true
    @State private var allowMovableWindow: Bool = false
    @State private var allowUserQuitDeferrals: Bool = true
    @State private var allowedDeferrals: String = ""
    @State private var allowedDeferralsUntilForcedSecondaryQuitButton: String = ""
    @State private var approachingRefreshCycle: String = ""
    @State private var approachingWindowTime: String = ""
    @State private var calendarDeferralUnit: String = ""
    @State private var elapsedRefreshCycle: String = ""
    @State private var gracePeriodInstallDelay: String = ""
    @State private var gracePeriodLaunchDelay: String = ""
    @State private var gracePeriodPath: String = ""
    @State private var imminentRefreshCycle: String = ""
    @State private var imminentWindowTime: String = ""
    @State private var initialRefreshCycle: String = ""
    @State private var launchAgentIdentifier: String = ""
    @State private var loadLaunchAgent: Bool = false
    @State private var maxRandomDelayInSeconds: String = ""
    @State private var noTimers: Bool = false
    @State private var nudgeMajorUpgradeEventLaunchDelay: String = ""
    @State private var nudgeMinorUpdateEventLaunchDelay: String = ""
    @State private var nudgeRefreshCycle: String = ""
    @State private var randomDelay: Bool = true
    @State private var applicationTerminatedNotificationImagePath: String = ""
    @State private var fallbackLanguage: String = "en"
    @State private var forceFallbackLanguage: Bool = false
    @State private var forceScreenShotIcon: Bool = false
    @State private var iconDarkPath: String = ""
    @State private var iconLightPath: String = ""
    @State private var requiredInstallationDisplayFormat: String = ""
    @State private var screenShotDarkPath: String = ""
    @State private var screenShotLightPath: String = ""
    @State private var showActivelyExploitedCVEs: Bool = true
    @State private var showDeferralCount: Bool = true
    @State private var showDaysRemainingToUpdate: Bool = true
    @State private var showRequiredDate: Bool = false
    @State private var simpleMode: Bool = false
    @State private var singleQuitButton: Bool = false
    @State private var updateElements: String = ""
    @State private var isOptionalFeaturesExpanded: Bool = false
    @State private var isOSRequirementsExpanded: Bool = false
    @State private var isUserExperienceExpanded: Bool = false
    @State private var isUserInterfaceExpanded: Bool = false
    @State private var isGeneratedJSONExpanded: Bool = false
    @State private var saveError: String = ""
    @State private var loadError: String = ""
    @State private var loadStatus: String = ""
    @State private var isLoadedFromJSON: Bool = false
    @State private var loadedJSONURL: URL?
    @State private var showCopyToast: Bool = false
    @State private var optionalFeaturesKeys: Set<String> = []
    @State private var userExperienceKeys: Set<String> = []
    @State private var userInterfaceKeys: Set<String> = []
    @State private var optionalFeaturesTouched: Set<String> = []
    @State private var userExperienceTouched: Set<String> = []
    @State private var userInterfaceTouched: Set<String> = []

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("JSON Builder")
                    .font(.title3.weight(.semibold))
                Spacer()
            }

            Text("Build & modify Nudge JSON configurations")
                .foregroundStyle(.secondary)
            Text("Warning: This is an experimental feature")
                .foregroundStyle(.red)
                .font(.footnote)

            
            if !saveError.isEmpty {
                Text(saveError)
                    .foregroundStyle(.red)
                    .font(.footnote)
            }
            if !loadError.isEmpty {
                Text(loadError)
                    .foregroundStyle(.red)
                    .font(.footnote)
            }
            if !loadStatus.isEmpty {
                Text(loadStatus)
                    .foregroundStyle(.secondary)
                    .font(.footnote)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    DisclosureGroup("Optional Features", isExpanded: $isOptionalFeaturesExpanded) {
                        GroupBox {
                            VStack(alignment: .leading, spacing: 12) {
                            FieldBlock(
                                "Acceptable Application Bundle IDs",
                                detail: "Bundle IDs allowed without re-activation. Foremost apps listed won't be interrupted."
                            ) {
                                TextField("com.example.App, com.example.Helper", text: $acceptableApplicationBundleIDs)
                                    .textFieldStyle(.roundedBorder)
                            }

                            FieldBlock(
                                "Acceptable Assertion Application Names",
                                detail: "App names from `pmset -g assertions`. Requires Acceptable Assertion Usage."
                            ) {
                                TextField("zoom.us, Meeting Center", text: $acceptableAssertionApplicationNames)
                                    .textFieldStyle(.roundedBorder)
                            }

                            SettingsRow(
                                "Acceptable Assertion Usage",
                                subtitle: "Skip activation while listed apps hold power assertions."
                            ) {
                                Toggle("", isOn: trackedBoolBinding($acceptableAssertionUsage, key: "acceptableAssertionUsage", touched: $optionalFeaturesTouched))
                                    .toggleStyle(.switch)
                            }
                            SettingsRow(
                                "Acceptable Camera Usage",
                                subtitle: "Skip activation while camera is in use (ignored after deadline)."
                            ) {
                                Toggle("", isOn: trackedBoolBinding($acceptableCameraUsage, key: "acceptableCameraUsage", touched: $optionalFeaturesTouched))
                                    .toggleStyle(.switch)
                            }
                            SettingsRow(
                                "Acceptable Update Preparing Usage",
                                subtitle: "Skip activation while updates are downloading or staging."
                            ) {
                                Toggle("", isOn: trackedBoolBinding($acceptableUpdatePreparingUsage, key: "acceptableUpdatePreparingUsage", touched: $optionalFeaturesTouched))
                                    .toggleStyle(.switch)
                            }
                            SettingsRow(
                                "Acceptable Screen Sharing Usage",
                                subtitle: "Skip activation while screen sharing is active (ignored after deadline)."
                            ) {
                                Toggle("", isOn: trackedBoolBinding($acceptableScreenSharingUsage, key: "acceptableScreenSharingUsage", touched: $optionalFeaturesTouched))
                                    .toggleStyle(.switch)
                            }
                            SettingsRow(
                                "Aggressive User Experience",
                                subtitle: "When off, Nudge won't hide other apps after deadline/deferrals."
                            ) {
                                Toggle("", isOn: trackedBoolBinding($aggressiveUserExperience, key: "aggressiveUserExperience", touched: $optionalFeaturesTouched))
                                    .toggleStyle(.switch)
                            }
                            SettingsRow(
                                "Aggressive Full Screen Experience",
                                subtitle: "When off, no blurred background after deferral window."
                            ) {
                                Toggle("", isOn: trackedBoolBinding($aggressiveUserFullScreenExperience, key: "aggressiveUserFullScreenExperience", touched: $optionalFeaturesTouched))
                                    .toggleStyle(.switch)
                            }
                            SettingsRow(
                                "Asynchronous Software Update",
                                subtitle: "When off, waits for Software Update downloads before UI."
                            ) {
                                Toggle("", isOn: trackedBoolBinding($asynchronousSoftwareUpdate, key: "asynchronousSoftwareUpdate", touched: $optionalFeaturesTouched))
                                    .toggleStyle(.switch)
                            }
                            SettingsRow(
                                "Attempt To Block Application Launches",
                                subtitle: "Blocks listed apps after deadline. Requires blocked bundle IDs."
                            ) {
                                Toggle("", isOn: trackedBoolBinding($attemptToBlockApplicationLaunches, key: "attemptToBlockApplicationLaunches", touched: $optionalFeaturesTouched))
                                    .toggleStyle(.switch)
                            }
                            SettingsRow(
                                "Attempt To Check For Supported Device",
                                subtitle: "When off, skips SOFA support check and Unsupported UI."
                            ) {
                                Toggle("", isOn: trackedBoolBinding($attemptToCheckForSupportedDevice, key: "attemptToCheckForSupportedDevice", touched: $optionalFeaturesTouched))
                                    .toggleStyle(.switch)
                            }
                            SettingsRow(
                                "Attempt To Fetch Major Upgrade",
                                subtitle: "When off, won't download major upgrades via softwareupdate."
                            ) {
                                Toggle("", isOn: trackedBoolBinding($attemptToFetchMajorUpgrade, key: "attemptToFetchMajorUpgrade", touched: $optionalFeaturesTouched))
                                    .toggleStyle(.switch)
                            }

                            FieldBlock(
                                "Blocked Application Bundle IDs",
                                detail: "Apps blocked from launching after the deadline."
                            ) {
                                TextField("us.zoom.xos, com.microsoft.Word", text: $blockedApplicationBundleIDs)
                                    .textFieldStyle(.roundedBorder)
                            }

                            FieldBlock(
                                "Custom SOFA Feed URL",
                                detail: "Use a custom SOFA feed URL."
                            ) {
                                TextField("https://example.com/sofa.json", text: $customSOFAFeedURL)
                                    .textFieldStyle(.roundedBorder)
                            }

                            SettingsRow(
                                "Disable Nudge For Standard Installs",
                                subtitle: "With SOFA, only enforce releases that have CVEs."
                            ) {
                                Toggle("", isOn: trackedBoolBinding($disableNudgeForStandardInstalls, key: "disableNudgeForStandardInstalls", touched: $optionalFeaturesTouched))
                                    .toggleStyle(.switch)
                            }
                            SettingsRow(
                                "Disable Software Update Workflow",
                                subtitle: "When on, Nudge won't download minor updates."
                            ) {
                                Toggle("", isOn: trackedBoolBinding($disableSoftwareUpdateWorkflow, key: "disableSoftwareUpdateWorkflow", touched: $optionalFeaturesTouched))
                                    .toggleStyle(.switch)
                            }
                            SettingsRow(
                                "Enforce Minor Updates",
                                subtitle: "When off, minor updates are not enforced."
                            ) {
                                Toggle("", isOn: trackedBoolBinding($enforceMinorUpdates, key: "enforceMinorUpdates", touched: $optionalFeaturesTouched))
                                    .toggleStyle(.switch)
                            }
                            SettingsRow(
                                "Honor Focus Modes",
                                subtitle: "Skip activation while in Focus/Do Not Disturb."
                            ) {
                                Toggle("", isOn: trackedBoolBinding($honorFocusModes, key: "honorFocusModes", touched: $optionalFeaturesTouched))
                                    .toggleStyle(.switch)
                            }

            FieldBlock(
                "Refresh SOFA Feed Time (seconds)",
                detail: "Max cache age before SOFA refresh."
            ) {
                TextField("86400", text: trackedTextBinding($refreshSOFAFeedTime, key: "refreshSOFAFeedTime", touched: $optionalFeaturesTouched))
                    .textFieldStyle(.roundedBorder)
            }

                            SettingsRow(
                                "Terminate Applications On Launch",
                                subtitle: "Terminates blocked apps when Nudge launches."
                            ) {
                                Toggle("", isOn: trackedBoolBinding($terminateApplicationsOnLaunch, key: "terminateApplicationsOnLaunch", touched: $optionalFeaturesTouched))
                                    .toggleStyle(.switch)
                            }
                            SettingsRow(
                                "Utilize SOFA Feed",
                                subtitle: "Use SOFA feed for update data."
                            ) {
                                Toggle("", isOn: trackedBoolBinding($utilizeSOFAFeed, key: "utilizeSOFAFeed", touched: $optionalFeaturesTouched))
                                    .toggleStyle(.switch)
                            }
                            }
                            .padding(.top, 4)
                        }
                    }

                    DisclosureGroup("OS Version Requirements", isExpanded: $isOSRequirementsExpanded) {
                        GroupBox {
                            VStack(alignment: .leading, spacing: 16) {
                            ForEach(osVersionRequirements) { requirement in
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Text("Requirement")
                                            .font(.subheadline.weight(.semibold))
                                        Spacer()
                                        if osVersionRequirements.count > 1 {
                                            Button {
                                                removeRequirement(requirement.id)
                                            } label: {
                                                Image(systemName: "trash")
                                                    .foregroundStyle(.red)
                                            }
                                            .buttonStyle(.plain)
                                            .accessibilityLabel(Text("Remove requirement"))
                                        }
                                    }

                                    FieldBlock("Required Minimum OS Version", detail: "Supports latest, latest-supported, and latest-minor (SOFA required).") {
                                        TextField("Required Minimum OS Version (e.g. 14.4)", text: binding(for: requirement.id, keyPath: \.requiredMinimumOSVersion))
                                            .textFieldStyle(.roundedBorder)
                                    }

                                    FieldBlock("Required Installation Date") {
                                        HStack(spacing: 8) {
                                            TextField("Required Installation Date (YYYY-MM-DDTHH:MM:SSZ or local)", text: binding(for: requirement.id, keyPath: \.requiredInstallationDate))
                                                .textFieldStyle(.roundedBorder)
                                            Button("Now (UTC)") {
                                                setRequiredDateNow(for: requirement.id)
                                            }
                                            .buttonStyle(.bordered)
                                            Button("Today (00:00)") {
                                                setRequiredDateToday(for: requirement.id)
                                            }
                                            .buttonStyle(.bordered)
                                        }
                                    }

                                    FieldBlock("Targeted OS Versions Rule") {
                                        TextField("Targeted OS Versions Rule (e.g. default, 14, 14.4.1)", text: binding(for: requirement.id, keyPath: \.targetedOSVersionsRule))
                                            .textFieldStyle(.roundedBorder)
                                    }

                                    FieldBlock("About Update URL") {
                                        TextField("About Update URL", text: binding(for: requirement.id, keyPath: \.aboutUpdateURL))
                                            .textFieldStyle(.roundedBorder)
                                    }

                                    FieldBlock("About Update URLs") {
                                        TextField("About Update URLs (lang=url, comma or line separated)", text: binding(for: requirement.id, keyPath: \.aboutUpdateURLs))
                                            .textFieldStyle(.roundedBorder)
                                    }

                                    FieldBlock(
                                        "Action Button Path(s)",
                                        detail: "URI for custom actions (v1.1.6+). Avoid empty strings; using this disables built-in updateDevice logic."
                                    ) {
                                        TextField("Action Button Path(s) (comma or line separated)", text: binding(for: requirement.id, keyPath: \.actionButtonPath))
                                            .textFieldStyle(.roundedBorder)
                                    }

                                    FieldBlock("Major Upgrade App Path") {
                                        TextField("Major Upgrade App Path", text: binding(for: requirement.id, keyPath: \.majorUpgradeAppPath))
                                            .textFieldStyle(.roundedBorder)
                                    }

                                    FieldBlock("Actively Exploited CVEs Major Upgrade SLA (days)") {
                                        TextField("Defaults to 14", text: binding(for: requirement.id, keyPath: \.activelyExploitedCVEsMajorUpgradeSLA))
                                            .textFieldStyle(.roundedBorder)
                                    }

                                    FieldBlock("Actively Exploited CVEs Minor Update SLA (days)") {
                                        TextField("Defaults to 14", text: binding(for: requirement.id, keyPath: \.activelyExploitedCVEsMinorUpdateSLA))
                                            .textFieldStyle(.roundedBorder)
                                    }

                                    FieldBlock("Non-Actively Exploited CVEs Major Upgrade SLA (days)") {
                                        TextField("Defaults to 21", text: binding(for: requirement.id, keyPath: \.nonActivelyExploitedCVEsMajorUpgradeSLA))
                                            .textFieldStyle(.roundedBorder)
                                    }

                                    FieldBlock("Non-Actively Exploited CVEs Minor Update SLA (days)") {
                                        TextField("Defaults to 21", text: binding(for: requirement.id, keyPath: \.nonActivelyExploitedCVEsMinorUpdateSLA))
                                            .textFieldStyle(.roundedBorder)
                                    }

                                    FieldBlock("Standard Major Upgrade SLA (days)") {
                                        TextField("Defaults to 28", text: binding(for: requirement.id, keyPath: \.standardMajorUpgradeSLA))
                                            .textFieldStyle(.roundedBorder)
                                    }

                                    FieldBlock("Standard Minor Update SLA (days)") {
                                        TextField("Defaults to 28", text: binding(for: requirement.id, keyPath: \.standardMinorUpdateSLA))
                                            .textFieldStyle(.roundedBorder)
                                    }
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.secondary.opacity(0.08))
                                )
                            }

                            Button {
                                osVersionRequirements.append(OSVersionRequirementDraft())
                            } label: {
                                Label("Add Requirement", systemImage: "plus.circle")
                            }
                            .buttonStyle(.bordered)
                            
                            Text("Nudge will then utilize two date integers to automatically calculate the requiredInstallationDate.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Text("SLA defaults: active 14 days, non-active 21 days, standard 28 days.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Text("These dates are calculated against the ReleaseDate key in the SOFA feed (UTC). Local timezones are not supported unless you use a custom feed and ISO-8601 dates.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Text("To delay SOFA nudge events, adjust nudgeMajorUpgradeEventLaunchDelay and nudgeMinorUpdateEventLaunchDelay.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Text("To suppress non-CVE nudges, set optionalFeatures.disableNudgeForStandardInstalls to true.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            }
                            .padding(.top, 4)
                        }
                    }

                    DisclosureGroup("User Experience", isExpanded: $isUserExperienceExpanded) {
                        GroupBox {
                            VStack(alignment: .leading, spacing: 12) {
                            SettingsRow("Allow Grace Periods", subtitle: "Extend requiredInstallationDate for new devices (v1.1.6+).") {
                                Toggle("", isOn: trackedBoolBinding($allowGracePeriods, key: "allowGracePeriods", touched: $userExperienceTouched))
                                    .toggleStyle(.switch)
                            }
                            SettingsRow("Allow Later Deferral Button", subtitle: "Enable Later button in custom deferrals UI (v1.1.10+).") {
                                Toggle("", isOn: trackedBoolBinding($allowLaterDeferralButton, key: "allowLaterDeferralButton", touched: $userExperienceTouched))
                                    .toggleStyle(.switch)
                            }
                            SettingsRow("Allow Movable Window", subtitle: "Allow users to move the Nudge window (v2.0+).") {
                                Toggle("", isOn: trackedBoolBinding($allowMovableWindow, key: "allowMovableWindow", touched: $userExperienceTouched))
                                    .toggleStyle(.switch)
                            }
                            SettingsRow("Allow User Quit Deferrals", subtitle: "Use deferRunUntil logic with LaunchAgent checks (v1.1.0+).") {
                                Toggle("", isOn: trackedBoolBinding($allowUserQuitDeferrals, key: "allowUserQuitDeferrals", touched: $userExperienceTouched))
                                    .toggleStyle(.switch)
                            }

                            FieldBlock("Allowed Deferrals", detail: "Deferrals before aggressive UX (v1.1.0+).") {
                                TextField("1000000", text: $allowedDeferrals)
                                    .textFieldStyle(.roundedBorder)
                            }

                            FieldBlock("Allowed Deferrals Until Forced Secondary Quit", detail: "Deferrals before requiring both quit buttons (v1.1.0+).") {
                                TextField("14", text: $allowedDeferralsUntilForcedSecondaryQuitButton)
                                    .textFieldStyle(.roundedBorder)
                            }

                            FieldBlock("Approaching Refresh Cycle (sec)", detail: "UI refresh timer before approachingWindowTime (v1.1.0+).") {
                                TextField("6000", text: $approachingRefreshCycle)
                                    .textFieldStyle(.roundedBorder)
                            }

                            FieldBlock("Approaching Window Time (hrs)", detail: "Hours before requiredInstallationDate is approaching (v1.1.0+).") {
                                TextField("72", text: $approachingWindowTime)
                                    .textFieldStyle(.roundedBorder)
                            }

                            FieldBlock("Calendar Deferral Unit", detail: "Use approachingWindowTime or imminentWindowTime (v1.1.12+).") {
                                TextField("approachingWindowTime or imminentWindowTime", text: $calendarDeferralUnit)
                                    .textFieldStyle(.roundedBorder)
                            }

                            FieldBlock("Elapsed Refresh Cycle (sec)", detail: "UI refresh timer after requiredInstallationDate expires (v1.1.0+).") {
                                TextField("300", text: $elapsedRefreshCycle)
                                    .textFieldStyle(.roundedBorder)
                            }

                            FieldBlock("Grace Period Install Delay (hrs)", detail: "Extend requiredInstallationDate for new devices (v1.1.6+).") {
                                TextField("23", text: $gracePeriodInstallDelay)
                                    .textFieldStyle(.roundedBorder)
                            }

                            FieldBlock("Grace Period Launch Delay (hrs)", detail: "Bypass launch for new devices (v1.1.6+).") {
                                TextField("1", text: $gracePeriodLaunchDelay)
                                    .textFieldStyle(.roundedBorder)
                            }

                            FieldBlock("Grace Period Path", detail: "File used to determine grace period start (v1.1.6+).") {
                                TextField("/private/var/db/.AppleSetupDone", text: $gracePeriodPath)
                                    .textFieldStyle(.roundedBorder)
                            }

                            FieldBlock("Imminent Refresh Cycle (sec)", detail: "UI refresh timer before imminentWindowTime (v1.1.0+).") {
                                TextField("600", text: $imminentRefreshCycle)
                                    .textFieldStyle(.roundedBorder)
                            }

                            FieldBlock("Imminent Window Time (hrs)", detail: "Hours before requiredInstallationDate is imminent (v1.1.0+).") {
                                TextField("24", text: $imminentWindowTime)
                                    .textFieldStyle(.roundedBorder)
                            }

                            FieldBlock("Initial Refresh Cycle (sec)", detail: "UI refresh timer before approachingWindowTime (v1.1.0+).") {
                                TextField("18000", text: $initialRefreshCycle)
                                    .textFieldStyle(.roundedBorder)
                            }

                            FieldBlock("Launch Agent Identifier", detail: "Only set if using a custom LaunchAgent ID (v1.1.13+).") {
                                TextField("com.github.macadmins.Nudge", text: $launchAgentIdentifier)
                                    .textFieldStyle(.roundedBorder)
                            }

                            SettingsRow("Load Launch Agent", subtitle: "Use SMAppService to load LaunchAgent (macOS 13+, experimental).") {
                                Toggle("", isOn: trackedBoolBinding($loadLaunchAgent, key: "loadLaunchAgent", touched: $userExperienceTouched))
                                    .toggleStyle(.switch)
                            }

                            FieldBlock("Max Random Delay (sec)", detail: "Max launch delay when randomDelay is true (v1.1.0+).") {
                                TextField("1200", text: $maxRandomDelayInSeconds)
                                    .textFieldStyle(.roundedBorder)
                            }

                            SettingsRow("No Timers", subtitle: "Disable userExperience timers (v1.1.0+).") {
                                Toggle("", isOn: trackedBoolBinding($noTimers, key: "noTimers", touched: $userExperienceTouched))
                                    .toggleStyle(.switch)
                            }

                            FieldBlock("Major Upgrade Launch Delay (days)", detail: "Delay SOFA major upgrade nudges (v2.0+).") {
                                TextField("0", text: $nudgeMajorUpgradeEventLaunchDelay)
                                    .textFieldStyle(.roundedBorder)
                            }

                            FieldBlock("Minor Update Launch Delay (days)", detail: "Delay SOFA minor update nudges (v2.0+).") {
                                TextField("0", text: $nudgeMinorUpdateEventLaunchDelay)
                                    .textFieldStyle(.roundedBorder)
                            }

                            FieldBlock("Nudge Refresh Cycle (sec)", detail: "Core refresh timer; too low can be aggressive (v1.1.0+).") {
                                TextField("60", text: $nudgeRefreshCycle)
                                    .textFieldStyle(.roundedBorder)
                            }

                            SettingsRow("Random Delay", subtitle: "Enable initial delay before UI (v1.1.0+).") {
                                Toggle("", isOn: trackedBoolBinding($randomDelay, key: "randomDelay", touched: $userExperienceTouched))
                                    .toggleStyle(.switch)
                            }
                            }
                            .padding(.top, 4)
                        }
                    }

                    DisclosureGroup("User Interface", isExpanded: $isUserInterfaceExpanded) {
                        GroupBox {
                            VStack(alignment: .leading, spacing: 12) {
                            FieldBlock(
                                "Application Terminated Notification Image Path",
                                detail: "Local image path for the terminate notification (v2.0+)."
                            ) {
                                TextField("Application Terminated Notification Image Path", text: $applicationTerminatedNotificationImagePath)
                                    .textFieldStyle(.roundedBorder)
                            }
                            
                            FieldBlock(
                                "Fallback Language",
                                detail: "Fallback locale if device language is not available (v1.1.0+)."
                            ) {
                                TextField("Fallback Language", text: trackedTextBinding($fallbackLanguage, key: "fallbackLanguage", touched: $userInterfaceTouched))
                                    .textFieldStyle(.roundedBorder)
                            }
                            
                            SettingsRow("Force Fallback Language", subtitle: "Force localizations to fallbackLanguage (v1.1.0+).") {
                                Toggle("", isOn: trackedBoolBinding($forceFallbackLanguage, key: "forceFallbackLanguage", touched: $userInterfaceTouched))
                                    .toggleStyle(.switch)
                            }
                            SettingsRow("Force Screen Shot Icon", subtitle: "Render built-in ScreenShot icon if no image path (v1.1.0+).") {
                                Toggle("", isOn: trackedBoolBinding($forceScreenShotIcon, key: "forceScreenShotIcon", touched: $userInterfaceTouched))
                                    .toggleStyle(.switch)
                            }
                            
                            FieldBlock(
                                "Icon Dark Path",
                                detail: "Remote/local image for dark mode. Base64 allowed (v1.1.12+)."
                            ) {
                                TextField("Icon Dark Path", text: $iconDarkPath)
                                    .textFieldStyle(.roundedBorder)
                            }
                            
                            FieldBlock(
                                "Icon Light Path",
                                detail: "Remote/local image for light mode. Base64 allowed (v1.1.12+)."
                            ) {
                                TextField("Icon Light Path", text: $iconLightPath)
                                    .textFieldStyle(.roundedBorder)
                            }
                            
                            FieldBlock(
                                "Required Installation Display Format",
                                detail: "Custom format for showRequiredDate, e.g. MM/dd/yyyy (v2.0+)."
                            ) {
                                TextField("Required Installation Display Format", text: $requiredInstallationDisplayFormat)
                                    .textFieldStyle(.roundedBorder)
                            }
                            
                            FieldBlock(
                                "Screen Shot Dark Path",
                                detail: "Remote/local screenshot for dark mode. Base64 allowed (v1.1.12+)."
                            ) {
                                TextField("Screen Shot Dark Path", text: $screenShotDarkPath)
                                    .textFieldStyle(.roundedBorder)
                            }
                            
                            FieldBlock(
                                "Screen Shot Light Path",
                                detail: "Remote/local screenshot for light mode. Base64 allowed (v1.1.12+)."
                            ) {
                                TextField("Screen Shot Light Path", text: $screenShotLightPath)
                                    .textFieldStyle(.roundedBorder)
                            }
                            
                            SettingsRow("Show Actively Exploited CVEs", subtitle: "Toggle CVEs list in sidebar (v2.0+).") {
                                Toggle("", isOn: trackedBoolBinding($showActivelyExploitedCVEs, key: "showActivelyExploitedCVEs", touched: $userInterfaceTouched))
                                    .toggleStyle(.switch)
                            }
                            SettingsRow("Show Deferral Count", subtitle: "Hide only the UI label; deferral logic still applies (v1.1.0+).") {
                                Toggle("", isOn: trackedBoolBinding($showDeferralCount, key: "showDeferralCount", touched: $userInterfaceTouched))
                                    .toggleStyle(.switch)
                            }
                            SettingsRow("Show Days Remaining To Update", subtitle: "Toggle Days Remaining item in UI (v2.0+).") {
                                Toggle("", isOn: trackedBoolBinding($showDaysRemainingToUpdate, key: "showDaysRemainingToUpdate", touched: $userInterfaceTouched))
                                    .toggleStyle(.switch)
                            }
                            SettingsRow("Show Required Date", subtitle: "Show requiredInstallationDate when enabled (v2.0+).") {
                                Toggle("", isOn: trackedBoolBinding($showRequiredDate, key: "showRequiredDate", touched: $userInterfaceTouched))
                                    .toggleStyle(.switch)
                            }
                            SettingsRow("Simple Mode", subtitle: "Enable simplified user experience (v1.1.0+).") {
                                Toggle("", isOn: trackedBoolBinding($simpleMode, key: "simpleMode", touched: $userInterfaceTouched))
                                    .toggleStyle(.switch)
                            }
                            SettingsRow("Single Quit Button", subtitle: "Always show one quit button (v1.1.0+).") {
                                Toggle("", isOn: trackedBoolBinding($singleQuitButton, key: "singleQuitButton", touched: $userInterfaceTouched))
                                    .toggleStyle(.switch)
                            }
                            
                            FieldBlock(
                                "Update Elements (raw JSON array)",
                                detail: "List of dictionaries for UI customization (v2.0+)."
                            ) {
                                TextField("Update Elements (raw JSON array)", text: $updateElements)
                                    .textFieldStyle(.roundedBorder)
                            }
                            }
                            .padding(.top, 4)
                        }
                    }

                    DisclosureGroup("Generated JSON", isExpanded: $isGeneratedJSONExpanded) {
                        GroupBox {
                            TextEditor(text: .constant(jsonPreview))
                                .font(.system(.body, design: .monospaced))
                                .frame(minHeight: 220)
                        }
                    }
                }
                .padding(.vertical, 4)
            }

        }
        .padding(24)
        .frame(minWidth: 640, minHeight: 520)
        .overlay(alignment: .top) {
            if showCopyToast {
                Text("JSON Copied to Clipboard")
                    .font(.footnote.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.regularMaterial, in: Capsule())
                    .transition(.opacity)
                    .padding(.top, 8)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button("Expand All") {
                    setSectionsExpanded(true)
                }
                Button("Collapse All") {
                    setSectionsExpanded(false)
                }
            }
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    saveLoadedJSON()
                } label: {
                    Label("Save JSON", systemImage: "square.and.arrow.down")
                }
                .disabled(loadedJSONURL == nil)
                
                Button {
                    saveJSON()
                } label: {
                    Label("Save As", systemImage: "square.and.arrow.down.on.square")
                }

                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(jsonPreview, forType: .string)
                    showCopyToastMessage()
                } label: {
                    Label("Copy JSON", systemImage: "doc.on.doc")
                }
            }
        }
        .onAppear {
            if loadFromSelection {
                loadFromModelSelection()
            } else {
                resetLoadTracking()
            }
        }
        .onChange(of: loadFromSelection) { _, newValue in
            if newValue {
                loadFromModelSelection()
            } else {
                resetLoadTracking()
            }
        }
        .onChange(of: model.selectedJSONPath) { _, _ in
            if loadFromSelection {
                loadFromModelSelection()
            }
        }
    }

    private func dismiss() {
        withAnimation(.easeInOut(duration: 0.2)) {
            dismissView()
        }
    }

    private func setSectionsExpanded(_ isExpanded: Bool) {
        withAnimation(.easeInOut(duration: 0.2)) {
            isOptionalFeaturesExpanded = isExpanded
            isOSRequirementsExpanded = isExpanded
            isUserExperienceExpanded = isExpanded
            isUserInterfaceExpanded = isExpanded
            isGeneratedJSONExpanded = isExpanded
        }
    }

    private func showCopyToastMessage() {
        withAnimation(.easeInOut(duration: 0.2)) {
            showCopyToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(.easeInOut(duration: 0.2)) {
                showCopyToast = false
            }
        }
    }

    private func setRequiredDateNow(for id: UUID) {
        let now = iso8601ZuluString(from: Date())
        guard let index = osVersionRequirements.firstIndex(where: { $0.id == id }) else { return }
        osVersionRequirements[index].requiredInstallationDate = now
    }

    private func setRequiredDateToday(for id: UUID) {
        let calendar = Calendar(identifier: .gregorian)
        var utcCalendar = calendar
        utcCalendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        let now = Date()
        let startOfDay = utcCalendar.startOfDay(for: now)
        let formatted = iso8601ZuluString(from: startOfDay)
        guard let index = osVersionRequirements.firstIndex(where: { $0.id == id }) else { return }
        osVersionRequirements[index].requiredInstallationDate = formatted
    }

    private func iso8601ZuluString(from date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.formatOptions = [.withInternetDateTime, .withColonSeparatorInTime, .withDashSeparatorInDate]
        return formatter.string(from: date)
    }

    private func resetLoadTracking() {
        isLoadedFromJSON = false
        loadedJSONURL = nil
        optionalFeaturesKeys = []
        userExperienceKeys = []
        userInterfaceKeys = []
        optionalFeaturesTouched = []
        userExperienceTouched = []
        userInterfaceTouched = []
    }

    private func shouldIncludeKey(_ key: String, keys: Set<String>, touched: Set<String>) -> Bool {
        return keys.contains(key) || touched.contains(key)
    }

    private func trackedBoolBinding(_ binding: Binding<Bool>, key: String, touched: Binding<Set<String>>) -> Binding<Bool> {
        Binding(
            get: { binding.wrappedValue },
            set: { newValue in
                binding.wrappedValue = newValue
                touched.wrappedValue.insert(key)
            }
        )
    }

    private func trackedTextBinding(_ binding: Binding<String>, key: String, touched: Binding<Set<String>>) -> Binding<String> {
        Binding(
            get: { binding.wrappedValue },
            set: { newValue in
                binding.wrappedValue = newValue
                touched.wrappedValue.insert(key)
            }
        )
    }

    private func loadFromJSON(url: URL) {
        loadError = ""
        loadStatus = ""
        loadedJSONURL = url
        let scoped = url.startAccessingSecurityScopedResource()
        defer {
            if scoped {
                url.stopAccessingSecurityScopedResource()
            }
        }
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            loadError = "Load failed: \(error.localizedDescription)"
            return
        }
        loadFromJSONData(data, label: url.lastPathComponent)
    }

    private func loadFromJSONData(_ data: Data, label: String) {
        let object: Any
        do {
            object = try JSONSerialization.jsonObject(with: data)
        } catch {
            loadError = "Load failed: \(error.localizedDescription)"
            return
        }
        guard let root = object as? [String: Any] else {
            loadError = "Load failed: Root JSON must be an object."
            return
        }
        isLoadedFromJSON = true
        optionalFeaturesTouched = []
        userExperienceTouched = []
        userInterfaceTouched = []
        optionalFeaturesKeys = []
        userExperienceKeys = []
        userInterfaceKeys = []
        let keyList = root.keys.sorted().joined(separator: ", ")
        loadStatus = "Loaded JSON: \(label) (keys: \(keyList))"

        if let optional = root["optionalFeatures"] as? [String: Any] {
            optionalFeaturesKeys = Set(optional.keys)
            acceptableApplicationBundleIDs = joinList(optional["acceptableApplicationBundleIDs"])
            acceptableAssertionApplicationNames = joinList(optional["acceptableAssertionApplicationNames"])
            acceptableAssertionUsage = optional["acceptableAssertionUsage"] as? Bool ?? acceptableAssertionUsage
            acceptableCameraUsage = optional["acceptableCameraUsage"] as? Bool ?? acceptableCameraUsage
            acceptableUpdatePreparingUsage = optional["acceptableUpdatePreparingUsage"] as? Bool ?? acceptableUpdatePreparingUsage
            acceptableScreenSharingUsage = optional["acceptableScreenSharingUsage"] as? Bool ?? acceptableScreenSharingUsage
            aggressiveUserExperience = optional["aggressiveUserExperience"] as? Bool ?? aggressiveUserExperience
            aggressiveUserFullScreenExperience = optional["aggressiveUserFullScreenExperience"] as? Bool ?? aggressiveUserFullScreenExperience
            asynchronousSoftwareUpdate = optional["asynchronousSoftwareUpdate"] as? Bool ?? asynchronousSoftwareUpdate
            attemptToBlockApplicationLaunches = optional["attemptToBlockApplicationLaunches"] as? Bool ?? attemptToBlockApplicationLaunches
            attemptToCheckForSupportedDevice = optional["attemptToCheckForSupportedDevice"] as? Bool ?? attemptToCheckForSupportedDevice
            attemptToFetchMajorUpgrade = optional["attemptToFetchMajorUpgrade"] as? Bool ?? attemptToFetchMajorUpgrade
            blockedApplicationBundleIDs = joinList(optional["blockedApplicationBundleIDs"])
            customSOFAFeedURL = optional["customSOFAFeedURL"] as? String ?? customSOFAFeedURL
            disableNudgeForStandardInstalls = optional["disableNudgeForStandardInstalls"] as? Bool ?? disableNudgeForStandardInstalls
            disableSoftwareUpdateWorkflow = optional["disableSoftwareUpdateWorkflow"] as? Bool ?? disableSoftwareUpdateWorkflow
            enforceMinorUpdates = optional["enforceMinorUpdates"] as? Bool ?? enforceMinorUpdates
            honorFocusModes = optional["honorFocusModes"] as? Bool ?? honorFocusModes
            refreshSOFAFeedTime = numberString(optional["refreshSOFAFeedTime"]) ?? refreshSOFAFeedTime
            terminateApplicationsOnLaunch = optional["terminateApplicationsOnLaunch"] as? Bool ?? terminateApplicationsOnLaunch
            utilizeSOFAFeed = optional["utilizeSOFAFeed"] as? Bool ?? utilizeSOFAFeed
        }

        if let requirements = root["osVersionRequirements"] as? [[String: Any]] {
            let drafts = requirements.map { item -> OSVersionRequirementDraft in
                var draft = OSVersionRequirementDraft()
                draft.presentKeys = Set(item.keys)
                if let value = item["requiredMinimumOSVersion"] as? String {
                    draft.requiredMinimumOSVersion = value
                }
                if let value = item["requiredInstallationDate"] as? String {
                    draft.requiredInstallationDate = value
                }
                if let value = item["targetedOSVersionsRule"] as? String {
                    draft.targetedOSVersionsRule = value
                }
                if let value = item["aboutUpdateURL"] as? String {
                    draft.aboutUpdateURL = value
                }
                if let value = item["aboutUpdateURLs"] as? [[String: Any]] {
                    draft.aboutUpdateURLs = value.compactMap { entry in
                        guard let lang = entry["_language"] as? String,
                              let url = entry["aboutUpdateURL"] as? String else { return nil }
                        return "\(lang)=\(url)"
                    }.joined(separator: ", ")
                }
                if let value = item["actionButtonPath"] {
                    draft.actionButtonPath = joinList(value)
                }
                if let value = item["majorUpgradeAppPath"] as? String {
                    draft.majorUpgradeAppPath = value
                }
                if let value = numberString(item["activelyExploitedCVEsMajorUpgradeSLA"]) {
                    draft.activelyExploitedCVEsMajorUpgradeSLA = value
                }
                if let value = numberString(item["activelyExploitedCVEsMinorUpdateSLA"]) {
                    draft.activelyExploitedCVEsMinorUpdateSLA = value
                }
                if let value = numberString(item["nonActivelyExploitedCVEsMajorUpgradeSLA"]) {
                    draft.nonActivelyExploitedCVEsMajorUpgradeSLA = value
                }
                if let value = numberString(item["nonActivelyExploitedCVEsMinorUpdateSLA"]) {
                    draft.nonActivelyExploitedCVEsMinorUpdateSLA = value
                }
                if let value = numberString(item["standardMajorUpgradeSLA"]) {
                    draft.standardMajorUpgradeSLA = value
                }
                if let value = numberString(item["standardMinorUpdateSLA"]) {
                    draft.standardMinorUpdateSLA = value
                }
                return draft
            }
            if !drafts.isEmpty {
                osVersionRequirements = drafts
            }
        }

        if let experience = root["userExperience"] as? [String: Any] {
            userExperienceKeys = Set(experience.keys)
            allowGracePeriods = experience["allowGracePeriods"] as? Bool ?? allowGracePeriods
            allowLaterDeferralButton = experience["allowLaterDeferralButton"] as? Bool ?? allowLaterDeferralButton
            allowMovableWindow = experience["allowMovableWindow"] as? Bool ?? allowMovableWindow
            allowUserQuitDeferrals = experience["allowUserQuitDeferrals"] as? Bool ?? allowUserQuitDeferrals
            allowedDeferrals = numberString(experience["allowedDeferrals"]) ?? allowedDeferrals
            allowedDeferralsUntilForcedSecondaryQuitButton = numberString(experience["allowedDeferralsUntilForcedSecondaryQuitButton"]) ?? allowedDeferralsUntilForcedSecondaryQuitButton
            approachingRefreshCycle = numberString(experience["approachingRefreshCycle"]) ?? approachingRefreshCycle
            approachingWindowTime = numberString(experience["approachingWindowTime"]) ?? approachingWindowTime
            calendarDeferralUnit = experience["calendarDeferralUnit"] as? String ?? calendarDeferralUnit
            elapsedRefreshCycle = numberString(experience["elapsedRefreshCycle"]) ?? elapsedRefreshCycle
            gracePeriodInstallDelay = numberString(experience["gracePeriodInstallDelay"]) ?? gracePeriodInstallDelay
            gracePeriodLaunchDelay = numberString(experience["gracePeriodLaunchDelay"]) ?? gracePeriodLaunchDelay
            gracePeriodPath = experience["gracePeriodPath"] as? String ?? gracePeriodPath
            imminentRefreshCycle = numberString(experience["imminentRefreshCycle"]) ?? imminentRefreshCycle
            imminentWindowTime = numberString(experience["imminentWindowTime"]) ?? imminentWindowTime
            initialRefreshCycle = numberString(experience["initialRefreshCycle"]) ?? initialRefreshCycle
            launchAgentIdentifier = experience["launchAgentIdentifier"] as? String ?? launchAgentIdentifier
            loadLaunchAgent = experience["loadLaunchAgent"] as? Bool ?? loadLaunchAgent
            maxRandomDelayInSeconds = numberString(experience["maxRandomDelayInSeconds"]) ?? maxRandomDelayInSeconds
            noTimers = experience["noTimers"] as? Bool ?? noTimers
            nudgeMajorUpgradeEventLaunchDelay = numberString(experience["nudgeMajorUpgradeEventLaunchDelay"]) ?? nudgeMajorUpgradeEventLaunchDelay
            nudgeMinorUpdateEventLaunchDelay = numberString(experience["nudgeMinorUpdateEventLaunchDelay"]) ?? nudgeMinorUpdateEventLaunchDelay
            nudgeRefreshCycle = numberString(experience["nudgeRefreshCycle"]) ?? nudgeRefreshCycle
            randomDelay = experience["randomDelay"] as? Bool ?? randomDelay
        }

        if let ui = root["userInterface"] as? [String: Any] {
            userInterfaceKeys = Set(ui.keys)
            applicationTerminatedNotificationImagePath = ui["applicationTerminatedNotificationImagePath"] as? String ?? applicationTerminatedNotificationImagePath
            fallbackLanguage = ui["fallbackLanguage"] as? String ?? fallbackLanguage
            forceFallbackLanguage = ui["forceFallbackLanguage"] as? Bool ?? forceFallbackLanguage
            forceScreenShotIcon = ui["forceScreenShotIcon"] as? Bool ?? forceScreenShotIcon
            iconDarkPath = ui["iconDarkPath"] as? String ?? iconDarkPath
            iconLightPath = ui["iconLightPath"] as? String ?? iconLightPath
            requiredInstallationDisplayFormat = ui["requiredInstallationDisplayFormat"] as? String ?? requiredInstallationDisplayFormat
            screenShotDarkPath = ui["screenShotDarkPath"] as? String ?? screenShotDarkPath
            screenShotLightPath = ui["screenShotLightPath"] as? String ?? screenShotLightPath
            showActivelyExploitedCVEs = ui["showActivelyExploitedCVEs"] as? Bool ?? showActivelyExploitedCVEs
            showDeferralCount = ui["showDeferralCount"] as? Bool ?? showDeferralCount
            showDaysRemainingToUpdate = ui["showDaysRemainingToUpdate"] as? Bool ?? showDaysRemainingToUpdate
            showRequiredDate = ui["showRequiredDate"] as? Bool ?? showRequiredDate
            simpleMode = ui["simpleMode"] as? Bool ?? simpleMode
            singleQuitButton = ui["singleQuitButton"] as? Bool ?? singleQuitButton
            if let elements = ui["updateElements"],
               let data = try? JSONSerialization.data(withJSONObject: elements, options: [.prettyPrinted, .sortedKeys]),
               let text = String(data: data, encoding: .utf8) {
                updateElements = text
            }
        }

    }

    private func loadFromModelSelection() {
        if let data = model.selectedJSONData {
            loadFromJSONData(data, label: model.selectedJSONPath.isEmpty ? "Selected JSON" : model.selectedJSONPath)
            loadedJSONURL = model.secureSelectedJSONURL()
            return
        }
        if let url = model.secureSelectedJSONURL() {
            loadFromJSON(url: url)
            return
        }
        if !model.selectedJSONPath.isEmpty {
            loadFromJSON(url: URL(fileURLWithPath: model.selectedJSONPath))
            return
        }
        loadStatus = "No JSON selected."
    }

    private func joinList(_ value: Any?) -> String {
        if let array = value as? [String] {
            return array.joined(separator: ", ")
        }
        if let string = value as? String {
            return string
        }
        if let array = value as? [Any] {
            return array.compactMap { $0 as? String }.joined(separator: ", ")
        }
        return ""
    }

    private func numberString(_ value: Any?) -> String? {
        if let number = value as? Int {
            return String(number)
        }
        if let number = value as? Double {
            if number.rounded() == number {
                return String(Int(number))
            }
            return String(number)
        }
        if let string = value as? String {
            return string
        }
        return nil
    }

    private func saveJSON() {
        saveError = ""
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "nudge.json"
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false
        panel.title = ""
        panel.message = ""
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true
        panel.prompt = "Save"

        if let window = NSApplication.shared.keyWindow {
            panel.beginSheetModal(for: window) { response in
                handleSavePanelResponse(response, panel: panel)
            }
        } else {
            let response = panel.runModal()
            handleSavePanelResponse(response, panel: panel)
        }
    }

    private func handleSavePanelResponse(_ response: NSApplication.ModalResponse, panel: NSSavePanel) {
        guard response == .OK, let url = panel.url else { return }
        do {
            try jsonPreview.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            saveError = "Save failed: \(error.localizedDescription)"
        }
    }

    private func saveLoadedJSON() {
        saveError = ""
        guard let url = loadedJSONURL else {
            saveError = "Save failed: No source file to replace."
            return
        }
        let scoped = url.startAccessingSecurityScopedResource()
        defer {
            if scoped {
                url.stopAccessingSecurityScopedResource()
            }
        }
        do {
            try jsonPreview.write(to: url, atomically: true, encoding: .utf8)
            loadStatus = "Saved JSON: \(url.lastPathComponent)"
        } catch {
            saveError = "Save failed: \(error.localizedDescription)"
        }
    }

    private var jsonPreview: String {
        let payload: [String: Any] = [
            "optionalFeatures": buildOptionalFeatures(),
            "osVersionRequirements": buildOSVersionRequirements(),
            "userExperience": buildUserExperience(),
            "userInterface": buildUserInterface()
        ]
        guard JSONSerialization.isValidJSONObject(payload),
              let data = try? JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys]),
              let string = String(data: data, encoding: .utf8) else {
            return "{\n  \"optionalFeatures\": {}\n}"
        }
        return string
    }

    private func buildOptionalFeatures() -> [String: Any] {
        var dict: [String: Any] = [:]
        let includeOptional: (String) -> Bool = { key in
            shouldIncludeKey(key, keys: optionalFeaturesKeys, touched: optionalFeaturesTouched)
        }

        let acceptableBundleIDs = parseList(acceptableApplicationBundleIDs)
        if includeOptional("acceptableApplicationBundleIDs") || !acceptableBundleIDs.isEmpty {
            dict["acceptableApplicationBundleIDs"] = acceptableBundleIDs
        }
        let acceptableAssertionNames = parseList(acceptableAssertionApplicationNames)
        if includeOptional("acceptableAssertionApplicationNames") || !acceptableAssertionNames.isEmpty {
            dict["acceptableAssertionApplicationNames"] = acceptableAssertionNames
        }
        if !isLoadedFromJSON || includeOptional("acceptableAssertionUsage") {
            dict["acceptableAssertionUsage"] = acceptableAssertionUsage
        }
        if !isLoadedFromJSON || includeOptional("acceptableCameraUsage") {
            dict["acceptableCameraUsage"] = acceptableCameraUsage
        }
        if !isLoadedFromJSON || includeOptional("acceptableUpdatePreparingUsage") {
            dict["acceptableUpdatePreparingUsage"] = acceptableUpdatePreparingUsage
        }
        if !isLoadedFromJSON || includeOptional("acceptableScreenSharingUsage") {
            dict["acceptableScreenSharingUsage"] = acceptableScreenSharingUsage
        }
        if !isLoadedFromJSON || includeOptional("aggressiveUserExperience") {
            dict["aggressiveUserExperience"] = aggressiveUserExperience
        }
        if !isLoadedFromJSON || includeOptional("aggressiveUserFullScreenExperience") {
            dict["aggressiveUserFullScreenExperience"] = aggressiveUserFullScreenExperience
        }
        if !isLoadedFromJSON || includeOptional("asynchronousSoftwareUpdate") {
            dict["asynchronousSoftwareUpdate"] = asynchronousSoftwareUpdate
        }
        if !isLoadedFromJSON || includeOptional("attemptToBlockApplicationLaunches") {
            dict["attemptToBlockApplicationLaunches"] = attemptToBlockApplicationLaunches
        }
        if !isLoadedFromJSON || includeOptional("attemptToCheckForSupportedDevice") {
            dict["attemptToCheckForSupportedDevice"] = attemptToCheckForSupportedDevice
        }
        if !isLoadedFromJSON || includeOptional("attemptToFetchMajorUpgrade") {
            dict["attemptToFetchMajorUpgrade"] = attemptToFetchMajorUpgrade
        }
        let blockedBundleIDs = parseList(blockedApplicationBundleIDs)
        if !isLoadedFromJSON || includeOptional("blockedApplicationBundleIDs") || !blockedBundleIDs.isEmpty {
            dict["blockedApplicationBundleIDs"] = blockedBundleIDs
        }
        let customSOFA = customSOFAFeedURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if !customSOFA.isEmpty || (isLoadedFromJSON && includeOptional("customSOFAFeedURL")) {
            dict["customSOFAFeedURL"] = customSOFA
        }
        if !isLoadedFromJSON || includeOptional("disableNudgeForStandardInstalls") {
            dict["disableNudgeForStandardInstalls"] = disableNudgeForStandardInstalls
        }
        if !isLoadedFromJSON || includeOptional("disableSoftwareUpdateWorkflow") {
            dict["disableSoftwareUpdateWorkflow"] = disableSoftwareUpdateWorkflow
        }
        if !isLoadedFromJSON || includeOptional("enforceMinorUpdates") {
            dict["enforceMinorUpdates"] = enforceMinorUpdates
        }
        if !isLoadedFromJSON || includeOptional("honorFocusModes") {
            dict["honorFocusModes"] = honorFocusModes
        }
        let refresh = refreshSOFAFeedTime.trimmingCharacters(in: .whitespacesAndNewlines)
        if !isLoadedFromJSON || includeOptional("refreshSOFAFeedTime") {
            if let refreshValue = Int(refresh) {
                dict["refreshSOFAFeedTime"] = refreshValue
            }
        }
        if !isLoadedFromJSON || includeOptional("terminateApplicationsOnLaunch") {
            dict["terminateApplicationsOnLaunch"] = terminateApplicationsOnLaunch
        }
        if !isLoadedFromJSON || includeOptional("utilizeSOFAFeed") {
            dict["utilizeSOFAFeed"] = utilizeSOFAFeed
        }
        return dict
    }

    private func buildOSVersionRequirements() -> [[String: Any]] {
        let built = osVersionRequirements.compactMap { item -> [String: Any]? in
            let required = item.requiredMinimumOSVersion.trimmingCharacters(in: .whitespacesAndNewlines)
            if required.isEmpty { return nil }
            var dict: [String: Any] = ["requiredMinimumOSVersion": required]
            let presentKeys = item.presentKeys

            let requiredDate = item.requiredInstallationDate.trimmingCharacters(in: .whitespacesAndNewlines)
            if !requiredDate.isEmpty || presentKeys.contains("requiredInstallationDate") {
                dict["requiredInstallationDate"] = requiredDate
            }

            let rule = item.targetedOSVersionsRule.trimmingCharacters(in: .whitespacesAndNewlines)
            if (!isLoadedFromJSON && !rule.isEmpty) || presentKeys.contains("targetedOSVersionsRule") || rule != "default" {
                dict["targetedOSVersionsRule"] = rule
            }

            let aboutURL = item.aboutUpdateURL.trimmingCharacters(in: .whitespacesAndNewlines)
            if !aboutURL.isEmpty || presentKeys.contains("aboutUpdateURL") {
                dict["aboutUpdateURL"] = aboutURL
            }

            let aboutURLs = parseLangURLList(item.aboutUpdateURLs)
            if !aboutURLs.isEmpty || presentKeys.contains("aboutUpdateURLs") {
                dict["aboutUpdateURLs"] = aboutURLs
            }

            let actionPaths = parseList(item.actionButtonPath)
            if !actionPaths.isEmpty || presentKeys.contains("actionButtonPath") {
                dict["actionButtonPath"] = actionPaths
            }

            let majorUpgradePath = item.majorUpgradeAppPath.trimmingCharacters(in: .whitespacesAndNewlines)
            if !majorUpgradePath.isEmpty || presentKeys.contains("majorUpgradeAppPath") {
                dict["majorUpgradeAppPath"] = majorUpgradePath
            }

            let activeMajor = item.activelyExploitedCVEsMajorUpgradeSLA.trimmingCharacters(in: .whitespacesAndNewlines)
            if let value = Int(activeMajor), (!activeMajor.isEmpty || presentKeys.contains("activelyExploitedCVEsMajorUpgradeSLA")) {
                dict["activelyExploitedCVEsMajorUpgradeSLA"] = value
            }

            let activeMinor = item.activelyExploitedCVEsMinorUpdateSLA.trimmingCharacters(in: .whitespacesAndNewlines)
            if let value = Int(activeMinor), (!activeMinor.isEmpty || presentKeys.contains("activelyExploitedCVEsMinorUpdateSLA")) {
                dict["activelyExploitedCVEsMinorUpdateSLA"] = value
            }

            let nonActiveMajor = item.nonActivelyExploitedCVEsMajorUpgradeSLA.trimmingCharacters(in: .whitespacesAndNewlines)
            if let value = Int(nonActiveMajor), (!nonActiveMajor.isEmpty || presentKeys.contains("nonActivelyExploitedCVEsMajorUpgradeSLA")) {
                dict["nonActivelyExploitedCVEsMajorUpgradeSLA"] = value
            }

            let nonActiveMinor = item.nonActivelyExploitedCVEsMinorUpdateSLA.trimmingCharacters(in: .whitespacesAndNewlines)
            if let value = Int(nonActiveMinor), (!nonActiveMinor.isEmpty || presentKeys.contains("nonActivelyExploitedCVEsMinorUpdateSLA")) {
                dict["nonActivelyExploitedCVEsMinorUpdateSLA"] = value
            }

            let standardMajor = item.standardMajorUpgradeSLA.trimmingCharacters(in: .whitespacesAndNewlines)
            if let value = Int(standardMajor), (!standardMajor.isEmpty || presentKeys.contains("standardMajorUpgradeSLA")) {
                dict["standardMajorUpgradeSLA"] = value
            }

            let standardMinor = item.standardMinorUpdateSLA.trimmingCharacters(in: .whitespacesAndNewlines)
            if let value = Int(standardMinor), (!standardMinor.isEmpty || presentKeys.contains("standardMinorUpdateSLA")) {
                dict["standardMinorUpdateSLA"] = value
            }

            return dict
        }
        return built
    }

    private func buildUserExperience() -> [String: Any] {
        var dict: [String: Any] = [:]
        let includeExperience: (String) -> Bool = { key in
            shouldIncludeKey(key, keys: userExperienceKeys, touched: userExperienceTouched)
        }

        if !isLoadedFromJSON || includeExperience("allowGracePeriods") {
            dict["allowGracePeriods"] = allowGracePeriods
        }
        if !isLoadedFromJSON || includeExperience("allowLaterDeferralButton") {
            dict["allowLaterDeferralButton"] = allowLaterDeferralButton
        }
        if !isLoadedFromJSON || includeExperience("allowMovableWindow") {
            dict["allowMovableWindow"] = allowMovableWindow
        }
        if !isLoadedFromJSON || includeExperience("allowUserQuitDeferrals") {
            dict["allowUserQuitDeferrals"] = allowUserQuitDeferrals
        }
        let allowedDeferralsValue = allowedDeferrals.trimmingCharacters(in: .whitespacesAndNewlines)
        if let value = Int(allowedDeferralsValue),
           !allowedDeferralsValue.isEmpty || (isLoadedFromJSON && includeExperience("allowedDeferrals")) || !isLoadedFromJSON {
            dict["allowedDeferrals"] = value
        }
        let allowedDeferralsSecondaryValue = allowedDeferralsUntilForcedSecondaryQuitButton.trimmingCharacters(in: .whitespacesAndNewlines)
        if let value = Int(allowedDeferralsSecondaryValue),
           !allowedDeferralsSecondaryValue.isEmpty || (isLoadedFromJSON && includeExperience("allowedDeferralsUntilForcedSecondaryQuitButton")) || !isLoadedFromJSON {
            dict["allowedDeferralsUntilForcedSecondaryQuitButton"] = value
        }
        let approachingRefreshValue = approachingRefreshCycle.trimmingCharacters(in: .whitespacesAndNewlines)
        if let value = Int(approachingRefreshValue),
           !approachingRefreshValue.isEmpty || (isLoadedFromJSON && includeExperience("approachingRefreshCycle")) || !isLoadedFromJSON {
            dict["approachingRefreshCycle"] = value
        }
        let approachingWindowValue = approachingWindowTime.trimmingCharacters(in: .whitespacesAndNewlines)
        if let value = Int(approachingWindowValue),
           !approachingWindowValue.isEmpty || (isLoadedFromJSON && includeExperience("approachingWindowTime")) || !isLoadedFromJSON {
            dict["approachingWindowTime"] = value
        }
        let calendarUnit = calendarDeferralUnit.trimmingCharacters(in: .whitespacesAndNewlines)
        if !calendarUnit.isEmpty || (isLoadedFromJSON && includeExperience("calendarDeferralUnit")) {
            dict["calendarDeferralUnit"] = calendarUnit
        }
        let elapsedRefreshValue = elapsedRefreshCycle.trimmingCharacters(in: .whitespacesAndNewlines)
        if let value = Int(elapsedRefreshValue),
           !elapsedRefreshValue.isEmpty || (isLoadedFromJSON && includeExperience("elapsedRefreshCycle")) || !isLoadedFromJSON {
            dict["elapsedRefreshCycle"] = value
        }
        let graceInstallValue = gracePeriodInstallDelay.trimmingCharacters(in: .whitespacesAndNewlines)
        if let value = Int(graceInstallValue),
           !graceInstallValue.isEmpty || (isLoadedFromJSON && includeExperience("gracePeriodInstallDelay")) || !isLoadedFromJSON {
            dict["gracePeriodInstallDelay"] = value
        }
        let graceLaunchValue = gracePeriodLaunchDelay.trimmingCharacters(in: .whitespacesAndNewlines)
        if let value = Int(graceLaunchValue),
           !graceLaunchValue.isEmpty || (isLoadedFromJSON && includeExperience("gracePeriodLaunchDelay")) || !isLoadedFromJSON {
            dict["gracePeriodLaunchDelay"] = value
        }
        let gracePath = gracePeriodPath.trimmingCharacters(in: .whitespacesAndNewlines)
        if !gracePath.isEmpty || (isLoadedFromJSON && includeExperience("gracePeriodPath")) {
            dict["gracePeriodPath"] = gracePath
        }
        let imminentRefreshValue = imminentRefreshCycle.trimmingCharacters(in: .whitespacesAndNewlines)
        if let value = Int(imminentRefreshValue),
           !imminentRefreshValue.isEmpty || (isLoadedFromJSON && includeExperience("imminentRefreshCycle")) || !isLoadedFromJSON {
            dict["imminentRefreshCycle"] = value
        }
        let imminentWindowValue = imminentWindowTime.trimmingCharacters(in: .whitespacesAndNewlines)
        if let value = Int(imminentWindowValue),
           !imminentWindowValue.isEmpty || (isLoadedFromJSON && includeExperience("imminentWindowTime")) || !isLoadedFromJSON {
            dict["imminentWindowTime"] = value
        }
        let initialRefreshValue = initialRefreshCycle.trimmingCharacters(in: .whitespacesAndNewlines)
        if let value = Int(initialRefreshValue),
           !initialRefreshValue.isEmpty || (isLoadedFromJSON && includeExperience("initialRefreshCycle")) || !isLoadedFromJSON {
            dict["initialRefreshCycle"] = value
        }
        let identifier = launchAgentIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)
        if !identifier.isEmpty || (isLoadedFromJSON && includeExperience("launchAgentIdentifier")) {
            dict["launchAgentIdentifier"] = identifier
        }
        if !isLoadedFromJSON || includeExperience("loadLaunchAgent") {
            dict["loadLaunchAgent"] = loadLaunchAgent
        }
        let maxRandomDelayValue = maxRandomDelayInSeconds.trimmingCharacters(in: .whitespacesAndNewlines)
        if let value = Int(maxRandomDelayValue),
           !maxRandomDelayValue.isEmpty || (isLoadedFromJSON && includeExperience("maxRandomDelayInSeconds")) || !isLoadedFromJSON {
            dict["maxRandomDelayInSeconds"] = value
        }
        if !isLoadedFromJSON || includeExperience("noTimers") {
            dict["noTimers"] = noTimers
        }
        let majorDelayValue = nudgeMajorUpgradeEventLaunchDelay.trimmingCharacters(in: .whitespacesAndNewlines)
        if let value = Int(majorDelayValue),
           !majorDelayValue.isEmpty || (isLoadedFromJSON && includeExperience("nudgeMajorUpgradeEventLaunchDelay")) || !isLoadedFromJSON {
            dict["nudgeMajorUpgradeEventLaunchDelay"] = value
        }
        let minorDelayValue = nudgeMinorUpdateEventLaunchDelay.trimmingCharacters(in: .whitespacesAndNewlines)
        if let value = Int(minorDelayValue),
           !minorDelayValue.isEmpty || (isLoadedFromJSON && includeExperience("nudgeMinorUpdateEventLaunchDelay")) || !isLoadedFromJSON {
            dict["nudgeMinorUpdateEventLaunchDelay"] = value
        }
        let refreshCycleValue = nudgeRefreshCycle.trimmingCharacters(in: .whitespacesAndNewlines)
        if let value = Int(refreshCycleValue),
           !refreshCycleValue.isEmpty || (isLoadedFromJSON && includeExperience("nudgeRefreshCycle")) || !isLoadedFromJSON {
            dict["nudgeRefreshCycle"] = value
        }
        if !isLoadedFromJSON || includeExperience("randomDelay") {
            dict["randomDelay"] = randomDelay
        }
        return dict
    }
    
    private func buildUserInterface() -> [String: Any] {
        var dict: [String: Any] = [:]
        let includeInterface: (String) -> Bool = { key in
            shouldIncludeKey(key, keys: userInterfaceKeys, touched: userInterfaceTouched)
        }
        let terminatedPath = applicationTerminatedNotificationImagePath.trimmingCharacters(in: .whitespacesAndNewlines)
        if !terminatedPath.isEmpty || (isLoadedFromJSON && includeInterface("applicationTerminatedNotificationImagePath")) {
            dict["applicationTerminatedNotificationImagePath"] = terminatedPath
        }
        let fallback = fallbackLanguage.trimmingCharacters(in: .whitespacesAndNewlines)
        if includeInterface("fallbackLanguage") || (!fallback.isEmpty && !isLoadedFromJSON) {
            dict["fallbackLanguage"] = fallback
        }
        if !isLoadedFromJSON || includeInterface("forceFallbackLanguage") {
            dict["forceFallbackLanguage"] = forceFallbackLanguage
        }
        if !isLoadedFromJSON || includeInterface("forceScreenShotIcon") {
            dict["forceScreenShotIcon"] = forceScreenShotIcon
        }
        let iconDark = iconDarkPath.trimmingCharacters(in: .whitespacesAndNewlines)
        if !iconDark.isEmpty || (isLoadedFromJSON && includeInterface("iconDarkPath")) {
            dict["iconDarkPath"] = iconDark
        }
        let iconLight = iconLightPath.trimmingCharacters(in: .whitespacesAndNewlines)
        if !iconLight.isEmpty || (isLoadedFromJSON && includeInterface("iconLightPath")) {
            dict["iconLightPath"] = iconLight
        }
        let format = requiredInstallationDisplayFormat.trimmingCharacters(in: .whitespacesAndNewlines)
        if !format.isEmpty || (isLoadedFromJSON && includeInterface("requiredInstallationDisplayFormat")) {
            dict["requiredInstallationDisplayFormat"] = format
        }
        let screenDark = screenShotDarkPath.trimmingCharacters(in: .whitespacesAndNewlines)
        if !screenDark.isEmpty || (isLoadedFromJSON && includeInterface("screenShotDarkPath")) {
            dict["screenShotDarkPath"] = screenDark
        }
        let screenLight = screenShotLightPath.trimmingCharacters(in: .whitespacesAndNewlines)
        if !screenLight.isEmpty || (isLoadedFromJSON && includeInterface("screenShotLightPath")) {
            dict["screenShotLightPath"] = screenLight
        }
        if !isLoadedFromJSON || includeInterface("showActivelyExploitedCVEs") {
            dict["showActivelyExploitedCVEs"] = showActivelyExploitedCVEs
        }
        if !isLoadedFromJSON || includeInterface("showDeferralCount") {
            dict["showDeferralCount"] = showDeferralCount
        }
        if !isLoadedFromJSON || includeInterface("showDaysRemainingToUpdate") {
            dict["showDaysRemainingToUpdate"] = showDaysRemainingToUpdate
        }
        if !isLoadedFromJSON || includeInterface("showRequiredDate") {
            dict["showRequiredDate"] = showRequiredDate
        }
        if !isLoadedFromJSON || includeInterface("simpleMode") {
            dict["simpleMode"] = simpleMode
        }
        if !isLoadedFromJSON || includeInterface("singleQuitButton") {
            dict["singleQuitButton"] = singleQuitButton
        }
        let updateElementsValue = updateElements.trimmingCharacters(in: .whitespacesAndNewlines)
        if !updateElementsValue.isEmpty,
           let data = updateElementsValue.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data),
           let array = json as? [[String: Any]] {
            dict["updateElements"] = array
        }
        return dict
    }

    private func parseList(_ text: String) -> [String] {
        let separators = CharacterSet(charactersIn: ",\n")
        return text
            .components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func parseLangURLList(_ text: String) -> [[String: String]] {
        let separators = CharacterSet(charactersIn: ",\n")
        let entries = text
            .components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return entries.compactMap { entry in
            let parts = entry.split(separator: "=", maxSplits: 1).map(String.init)
            if parts.count == 2 {
                return ["_language": parts[0], "aboutUpdateURL": parts[1]]
            }
            let colonParts = entry.split(separator: ":", maxSplits: 1).map(String.init)
            if colonParts.count == 2 {
                return ["_language": colonParts[0], "aboutUpdateURL": colonParts[1]]
            }
            return nil
        }
    }

    private func binding(for id: UUID, keyPath: WritableKeyPath<OSVersionRequirementDraft, String>) -> Binding<String> {
        Binding<String>(
            get: {
                osVersionRequirements.first(where: { $0.id == id })?[keyPath: keyPath] ?? ""
            },
            set: { newValue in
                guard let index = osVersionRequirements.firstIndex(where: { $0.id == id }) else { return }
                osVersionRequirements[index][keyPath: keyPath] = newValue
            }
        )
    }

    private func removeRequirement(_ id: UUID) {
        osVersionRequirements.removeAll { $0.id == id }
        if osVersionRequirements.isEmpty {
            osVersionRequirements = [OSVersionRequirementDraft()]
        }
    }
}
