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

struct JSONBuilderSheet: View {
    @Binding var isPresented: Bool
    @ObservedObject var model: NudgeViewModel
    let loadFromSelection: Bool
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

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("JSON Builder")
                    .font(.title3.weight(.semibold))
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Close JSON Builder"))
            }

            Text("Build & modify Nudge JSON configurations")
                .foregroundStyle(.secondary)
            Text("Warning: This is an experimental feature")
                .foregroundStyle(.red)
                .font(.footnote)

            HStack(spacing: 8) {
                Button("Expand All") {
                    setSectionsExpanded(true)
                }
                .buttonStyle(.bordered)

                Button("Collapse All") {
                    setSectionsExpanded(false)
                }
                .buttonStyle(.bordered)

                Spacer()

                Button {
                    saveJSON()
                } label: {
                    Label("Save JSON", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(.bordered)

                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(jsonPreview, forType: .string)
                } label: {
                    Label("Copy JSON", systemImage: "doc.on.doc")
                }
                .buttonStyle(.bordered)

//                Button("Close") {
//                    dismiss()
//                }
//                .buttonStyle(.borderedProminent)
            }
            
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
                                Toggle("", isOn: $acceptableAssertionUsage)
                                    .toggleStyle(.switch)
                            }
                            SettingsRow(
                                "Acceptable Camera Usage",
                                subtitle: "Skip activation while camera is in use (ignored after deadline)."
                            ) {
                                Toggle("", isOn: $acceptableCameraUsage)
                                    .toggleStyle(.switch)
                            }
                            SettingsRow(
                                "Acceptable Update Preparing Usage",
                                subtitle: "Skip activation while updates are downloading or staging."
                            ) {
                                Toggle("", isOn: $acceptableUpdatePreparingUsage)
                                    .toggleStyle(.switch)
                            }
                            SettingsRow(
                                "Acceptable Screen Sharing Usage",
                                subtitle: "Skip activation while screen sharing is active (ignored after deadline)."
                            ) {
                                Toggle("", isOn: $acceptableScreenSharingUsage)
                                    .toggleStyle(.switch)
                            }
                            SettingsRow(
                                "Aggressive User Experience",
                                subtitle: "When off, Nudge won't hide other apps after deadline/deferrals."
                            ) {
                                Toggle("", isOn: $aggressiveUserExperience)
                                    .toggleStyle(.switch)
                            }
                            SettingsRow(
                                "Aggressive Full Screen Experience",
                                subtitle: "When off, no blurred background after deferral window."
                            ) {
                                Toggle("", isOn: $aggressiveUserFullScreenExperience)
                                    .toggleStyle(.switch)
                            }
                            SettingsRow(
                                "Asynchronous Software Update",
                                subtitle: "When off, waits for Software Update downloads before UI."
                            ) {
                                Toggle("", isOn: $asynchronousSoftwareUpdate)
                                    .toggleStyle(.switch)
                            }
                            SettingsRow(
                                "Attempt To Block Application Launches",
                                subtitle: "Blocks listed apps after deadline. Requires blocked bundle IDs."
                            ) {
                                Toggle("", isOn: $attemptToBlockApplicationLaunches)
                                    .toggleStyle(.switch)
                            }
                            SettingsRow(
                                "Attempt To Check For Supported Device",
                                subtitle: "When off, skips SOFA support check and Unsupported UI."
                            ) {
                                Toggle("", isOn: $attemptToCheckForSupportedDevice)
                                    .toggleStyle(.switch)
                            }
                            SettingsRow(
                                "Attempt To Fetch Major Upgrade",
                                subtitle: "When off, won't download major upgrades via softwareupdate."
                            ) {
                                Toggle("", isOn: $attemptToFetchMajorUpgrade)
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
                                Toggle("", isOn: $disableNudgeForStandardInstalls)
                                    .toggleStyle(.switch)
                            }
                            SettingsRow(
                                "Disable Software Update Workflow",
                                subtitle: "When on, Nudge won't download minor updates."
                            ) {
                                Toggle("", isOn: $disableSoftwareUpdateWorkflow)
                                    .toggleStyle(.switch)
                            }
                            SettingsRow(
                                "Enforce Minor Updates",
                                subtitle: "When off, minor updates are not enforced."
                            ) {
                                Toggle("", isOn: $enforceMinorUpdates)
                                    .toggleStyle(.switch)
                            }
                            SettingsRow(
                                "Honor Focus Modes",
                                subtitle: "Skip activation while in Focus/Do Not Disturb."
                            ) {
                                Toggle("", isOn: $honorFocusModes)
                                    .toggleStyle(.switch)
                            }

                            FieldBlock(
                                "Refresh SOFA Feed Time (seconds)",
                                detail: "Max cache age before SOFA refresh."
                            ) {
                                TextField("86400", text: $refreshSOFAFeedTime)
                                    .textFieldStyle(.roundedBorder)
                            }

                            SettingsRow(
                                "Terminate Applications On Launch",
                                subtitle: "Terminates blocked apps when Nudge launches."
                            ) {
                                Toggle("", isOn: $terminateApplicationsOnLaunch)
                                    .toggleStyle(.switch)
                            }
                            SettingsRow(
                                "Utilize SOFA Feed",
                                subtitle: "Use SOFA feed for update data."
                            ) {
                                Toggle("", isOn: $utilizeSOFAFeed)
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

                                    FieldBlock("Action Button Path(s)") {
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
                            SettingsRow("Allow Grace Periods") {
                                Toggle("", isOn: $allowGracePeriods)
                                    .toggleStyle(.switch)
                            }
                            SettingsRow("Allow Later Deferral Button") {
                                Toggle("", isOn: $allowLaterDeferralButton)
                                    .toggleStyle(.switch)
                            }
                            SettingsRow("Allow Movable Window") {
                                Toggle("", isOn: $allowMovableWindow)
                                    .toggleStyle(.switch)
                            }
                            SettingsRow("Allow User Quit Deferrals") {
                                Toggle("", isOn: $allowUserQuitDeferrals)
                                    .toggleStyle(.switch)
                            }

                            FieldBlock("Allowed Deferrals") {
                                TextField("1000000", text: $allowedDeferrals)
                                    .textFieldStyle(.roundedBorder)
                            }

                            FieldBlock("Allowed Deferrals Until Forced Secondary Quit") {
                                TextField("14", text: $allowedDeferralsUntilForcedSecondaryQuitButton)
                                    .textFieldStyle(.roundedBorder)
                            }

                            FieldBlock("Approaching Refresh Cycle (sec)") {
                                TextField("6000", text: $approachingRefreshCycle)
                                    .textFieldStyle(.roundedBorder)
                            }

                            FieldBlock("Approaching Window Time (hrs)") {
                                TextField("72", text: $approachingWindowTime)
                                    .textFieldStyle(.roundedBorder)
                            }

                            FieldBlock("Calendar Deferral Unit") {
                                TextField("approachingWindowTime or imminentWindowTime", text: $calendarDeferralUnit)
                                    .textFieldStyle(.roundedBorder)
                            }

                            FieldBlock("Elapsed Refresh Cycle (sec)") {
                                TextField("300", text: $elapsedRefreshCycle)
                                    .textFieldStyle(.roundedBorder)
                            }

                            FieldBlock("Grace Period Install Delay (hrs)") {
                                TextField("23", text: $gracePeriodInstallDelay)
                                    .textFieldStyle(.roundedBorder)
                            }

                            FieldBlock("Grace Period Launch Delay (hrs)") {
                                TextField("1", text: $gracePeriodLaunchDelay)
                                    .textFieldStyle(.roundedBorder)
                            }

                            FieldBlock("Grace Period Path") {
                                TextField("/private/var/db/.AppleSetupDone", text: $gracePeriodPath)
                                    .textFieldStyle(.roundedBorder)
                            }

                            FieldBlock("Imminent Refresh Cycle (sec)") {
                                TextField("600", text: $imminentRefreshCycle)
                                    .textFieldStyle(.roundedBorder)
                            }

                            FieldBlock("Imminent Window Time (hrs)") {
                                TextField("24", text: $imminentWindowTime)
                                    .textFieldStyle(.roundedBorder)
                            }

                            FieldBlock("Initial Refresh Cycle (sec)") {
                                TextField("18000", text: $initialRefreshCycle)
                                    .textFieldStyle(.roundedBorder)
                            }

                            FieldBlock("Launch Agent Identifier") {
                                TextField("com.github.macadmins.Nudge", text: $launchAgentIdentifier)
                                    .textFieldStyle(.roundedBorder)
                            }

                            SettingsRow("Load Launch Agent") {
                                Toggle("", isOn: $loadLaunchAgent)
                                    .toggleStyle(.switch)
                            }

                            FieldBlock("Max Random Delay (sec)") {
                                TextField("1200", text: $maxRandomDelayInSeconds)
                                    .textFieldStyle(.roundedBorder)
                            }

                            SettingsRow("No Timers") {
                                Toggle("", isOn: $noTimers)
                                    .toggleStyle(.switch)
                            }

                            FieldBlock("Major Upgrade Launch Delay (days)") {
                                TextField("0", text: $nudgeMajorUpgradeEventLaunchDelay)
                                    .textFieldStyle(.roundedBorder)
                            }

                            FieldBlock("Minor Update Launch Delay (days)") {
                                TextField("0", text: $nudgeMinorUpdateEventLaunchDelay)
                                    .textFieldStyle(.roundedBorder)
                            }

                            FieldBlock("Nudge Refresh Cycle (sec)") {
                                TextField("60", text: $nudgeRefreshCycle)
                                    .textFieldStyle(.roundedBorder)
                            }

                            SettingsRow("Random Delay") {
                                Toggle("", isOn: $randomDelay)
                                    .toggleStyle(.switch)
                            }
                            }
                            .padding(.top, 4)
                        }
                    }

                    DisclosureGroup("User Interface", isExpanded: $isUserInterfaceExpanded) {
                        GroupBox {
                            VStack(alignment: .leading, spacing: 12) {
                            TextField("Application Terminated Notification Image Path", text: $applicationTerminatedNotificationImagePath)
                                .textFieldStyle(.roundedBorder)
                            
                            TextField("Fallback Language", text: $fallbackLanguage)
                                .textFieldStyle(.roundedBorder)
                            
                            SettingsRow("Force Fallback Language") {
                                Toggle("", isOn: $forceFallbackLanguage)
                                    .toggleStyle(.switch)
                            }
                            SettingsRow("Force Screen Shot Icon") {
                                Toggle("", isOn: $forceScreenShotIcon)
                                    .toggleStyle(.switch)
                            }
                            
                            TextField("Icon Dark Path", text: $iconDarkPath)
                                .textFieldStyle(.roundedBorder)
                            
                            TextField("Icon Light Path", text: $iconLightPath)
                                .textFieldStyle(.roundedBorder)
                            
                            TextField("Required Installation Display Format", text: $requiredInstallationDisplayFormat)
                                .textFieldStyle(.roundedBorder)
                            
                            TextField("Screen Shot Dark Path", text: $screenShotDarkPath)
                                .textFieldStyle(.roundedBorder)
                            
                            TextField("Screen Shot Light Path", text: $screenShotLightPath)
                                .textFieldStyle(.roundedBorder)
                            
                            SettingsRow("Show Actively Exploited CVEs") {
                                Toggle("", isOn: $showActivelyExploitedCVEs)
                                    .toggleStyle(.switch)
                            }
                            SettingsRow("Show Deferral Count") {
                                Toggle("", isOn: $showDeferralCount)
                                    .toggleStyle(.switch)
                            }
                            SettingsRow("Show Days Remaining To Update", subtitle: "Disable to hide the Days Remaining To Update item in the UI.") {
                                Toggle("", isOn: $showDaysRemainingToUpdate)
                                    .toggleStyle(.switch)
                            }
                            SettingsRow("Show Required Date") {
                                Toggle("", isOn: $showRequiredDate)
                                    .toggleStyle(.switch)
                            }
                            SettingsRow("Simple Mode") {
                                Toggle("", isOn: $simpleMode)
                                    .toggleStyle(.switch)
                            }
                            SettingsRow("Single Quit Button") {
                                Toggle("", isOn: $singleQuitButton)
                                    .toggleStyle(.switch)
                            }
                            
                            TextField("Update Elements (raw JSON array)", text: $updateElements)
                                .textFieldStyle(.roundedBorder)
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
        .onAppear {
            if loadFromSelection {
                loadFromModelSelection()
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
            isPresented = false
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

    private func setRequiredDateNow(for id: UUID) {
        let now = iso8601ZuluString(from: Date())
        guard let index = osVersionRequirements.firstIndex(where: { $0.id == id }) else { return }
        osVersionRequirements[index].requiredInstallationDate = now
    }

    private func iso8601ZuluString(from date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.formatOptions = [.withInternetDateTime, .withColonSeparatorInTime, .withDashSeparatorInDate]
        return formatter.string(from: date)
    }

    private func loadFromJSON(url: URL) {
        loadError = ""
        loadStatus = ""
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
        let keyList = root.keys.sorted().joined(separator: ", ")
        loadStatus = "Loaded JSON: \(label) (keys: \(keyList))"

        if let optional = root["optionalFeatures"] as? [String: Any] {
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
        dict["acceptableApplicationBundleIDs"] = parseList(acceptableApplicationBundleIDs)
        dict["acceptableAssertionApplicationNames"] = parseList(acceptableAssertionApplicationNames)
        dict["acceptableAssertionUsage"] = acceptableAssertionUsage
        dict["acceptableCameraUsage"] = acceptableCameraUsage
        dict["acceptableUpdatePreparingUsage"] = acceptableUpdatePreparingUsage
        dict["acceptableScreenSharingUsage"] = acceptableScreenSharingUsage
        dict["aggressiveUserExperience"] = aggressiveUserExperience
        dict["aggressiveUserFullScreenExperience"] = aggressiveUserFullScreenExperience
        dict["asynchronousSoftwareUpdate"] = asynchronousSoftwareUpdate
        dict["attemptToBlockApplicationLaunches"] = attemptToBlockApplicationLaunches
        dict["attemptToCheckForSupportedDevice"] = attemptToCheckForSupportedDevice
        dict["attemptToFetchMajorUpgrade"] = attemptToFetchMajorUpgrade
        dict["blockedApplicationBundleIDs"] = parseList(blockedApplicationBundleIDs)
        if !customSOFAFeedURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            dict["customSOFAFeedURL"] = customSOFAFeedURL.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        dict["disableNudgeForStandardInstalls"] = disableNudgeForStandardInstalls
        dict["disableSoftwareUpdateWorkflow"] = disableSoftwareUpdateWorkflow
        dict["enforceMinorUpdates"] = enforceMinorUpdates
        dict["honorFocusModes"] = honorFocusModes
        if let refresh = Int(refreshSOFAFeedTime.trimmingCharacters(in: .whitespacesAndNewlines)) {
            dict["refreshSOFAFeedTime"] = refresh
        }
        dict["terminateApplicationsOnLaunch"] = terminateApplicationsOnLaunch
        dict["utilizeSOFAFeed"] = utilizeSOFAFeed
        return dict
    }

    private func buildOSVersionRequirements() -> [[String: Any]] {
        let built = osVersionRequirements.compactMap { item -> [String: Any]? in
            let required = item.requiredMinimumOSVersion.trimmingCharacters(in: .whitespacesAndNewlines)
            if required.isEmpty { return nil }
            var dict: [String: Any] = ["requiredMinimumOSVersion": required]

            let requiredDate = item.requiredInstallationDate.trimmingCharacters(in: .whitespacesAndNewlines)
            if !requiredDate.isEmpty {
                dict["requiredInstallationDate"] = requiredDate
            }

            let rule = item.targetedOSVersionsRule.trimmingCharacters(in: .whitespacesAndNewlines)
            if !rule.isEmpty {
                dict["targetedOSVersionsRule"] = rule
            }

            let aboutURL = item.aboutUpdateURL.trimmingCharacters(in: .whitespacesAndNewlines)
            if !aboutURL.isEmpty {
                dict["aboutUpdateURL"] = aboutURL
            }

            let aboutURLs = parseLangURLList(item.aboutUpdateURLs)
            if !aboutURLs.isEmpty {
                dict["aboutUpdateURLs"] = aboutURLs
            }

            let actionPaths = parseList(item.actionButtonPath)
            if !actionPaths.isEmpty {
                dict["actionButtonPath"] = actionPaths
            }

            let majorUpgradePath = item.majorUpgradeAppPath.trimmingCharacters(in: .whitespacesAndNewlines)
            if !majorUpgradePath.isEmpty {
                dict["majorUpgradeAppPath"] = majorUpgradePath
            }

            let activeMajor = item.activelyExploitedCVEsMajorUpgradeSLA.trimmingCharacters(in: .whitespacesAndNewlines)
            if let value = Int(activeMajor) {
                dict["activelyExploitedCVEsMajorUpgradeSLA"] = value
            }

            let activeMinor = item.activelyExploitedCVEsMinorUpdateSLA.trimmingCharacters(in: .whitespacesAndNewlines)
            if let value = Int(activeMinor) {
                dict["activelyExploitedCVEsMinorUpdateSLA"] = value
            }

            let nonActiveMajor = item.nonActivelyExploitedCVEsMajorUpgradeSLA.trimmingCharacters(in: .whitespacesAndNewlines)
            if let value = Int(nonActiveMajor) {
                dict["nonActivelyExploitedCVEsMajorUpgradeSLA"] = value
            }

            let nonActiveMinor = item.nonActivelyExploitedCVEsMinorUpdateSLA.trimmingCharacters(in: .whitespacesAndNewlines)
            if let value = Int(nonActiveMinor) {
                dict["nonActivelyExploitedCVEsMinorUpdateSLA"] = value
            }

            let standardMajor = item.standardMajorUpgradeSLA.trimmingCharacters(in: .whitespacesAndNewlines)
            if let value = Int(standardMajor) {
                dict["standardMajorUpgradeSLA"] = value
            }

            let standardMinor = item.standardMinorUpdateSLA.trimmingCharacters(in: .whitespacesAndNewlines)
            if let value = Int(standardMinor) {
                dict["standardMinorUpdateSLA"] = value
            }

            return dict
        }
        return built
    }

    private func buildUserExperience() -> [String: Any] {
        var dict: [String: Any] = [:]
        dict["allowGracePeriods"] = allowGracePeriods
        dict["allowLaterDeferralButton"] = allowLaterDeferralButton
        dict["allowMovableWindow"] = allowMovableWindow
        dict["allowUserQuitDeferrals"] = allowUserQuitDeferrals
        if let value = Int(allowedDeferrals.trimmingCharacters(in: .whitespacesAndNewlines)) {
            dict["allowedDeferrals"] = value
        }
        if let value = Int(allowedDeferralsUntilForcedSecondaryQuitButton.trimmingCharacters(in: .whitespacesAndNewlines)) {
            dict["allowedDeferralsUntilForcedSecondaryQuitButton"] = value
        }
        if let value = Int(approachingRefreshCycle.trimmingCharacters(in: .whitespacesAndNewlines)) {
            dict["approachingRefreshCycle"] = value
        }
        if let value = Int(approachingWindowTime.trimmingCharacters(in: .whitespacesAndNewlines)) {
            dict["approachingWindowTime"] = value
        }
        let calendarUnit = calendarDeferralUnit.trimmingCharacters(in: .whitespacesAndNewlines)
        if !calendarUnit.isEmpty {
            dict["calendarDeferralUnit"] = calendarUnit
        }
        if let value = Int(elapsedRefreshCycle.trimmingCharacters(in: .whitespacesAndNewlines)) {
            dict["elapsedRefreshCycle"] = value
        }
        if let value = Int(gracePeriodInstallDelay.trimmingCharacters(in: .whitespacesAndNewlines)) {
            dict["gracePeriodInstallDelay"] = value
        }
        if let value = Int(gracePeriodLaunchDelay.trimmingCharacters(in: .whitespacesAndNewlines)) {
            dict["gracePeriodLaunchDelay"] = value
        }
        let gracePath = gracePeriodPath.trimmingCharacters(in: .whitespacesAndNewlines)
        if !gracePath.isEmpty {
            dict["gracePeriodPath"] = gracePath
        }
        if let value = Int(imminentRefreshCycle.trimmingCharacters(in: .whitespacesAndNewlines)) {
            dict["imminentRefreshCycle"] = value
        }
        if let value = Int(imminentWindowTime.trimmingCharacters(in: .whitespacesAndNewlines)) {
            dict["imminentWindowTime"] = value
        }
        if let value = Int(initialRefreshCycle.trimmingCharacters(in: .whitespacesAndNewlines)) {
            dict["initialRefreshCycle"] = value
        }
        let identifier = launchAgentIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)
        if !identifier.isEmpty {
            dict["launchAgentIdentifier"] = identifier
        }
        dict["loadLaunchAgent"] = loadLaunchAgent
        if let value = Int(maxRandomDelayInSeconds.trimmingCharacters(in: .whitespacesAndNewlines)) {
            dict["maxRandomDelayInSeconds"] = value
        }
        dict["noTimers"] = noTimers
        if let value = Int(nudgeMajorUpgradeEventLaunchDelay.trimmingCharacters(in: .whitespacesAndNewlines)) {
            dict["nudgeMajorUpgradeEventLaunchDelay"] = value
        }
        if let value = Int(nudgeMinorUpdateEventLaunchDelay.trimmingCharacters(in: .whitespacesAndNewlines)) {
            dict["nudgeMinorUpdateEventLaunchDelay"] = value
        }
        if let value = Int(nudgeRefreshCycle.trimmingCharacters(in: .whitespacesAndNewlines)) {
            dict["nudgeRefreshCycle"] = value
        }
        dict["randomDelay"] = randomDelay
        return dict
    }
    
    private func buildUserInterface() -> [String: Any] {
        var dict: [String: Any] = [:]
        let terminatedPath = applicationTerminatedNotificationImagePath.trimmingCharacters(in: .whitespacesAndNewlines)
        if !terminatedPath.isEmpty {
            dict["applicationTerminatedNotificationImagePath"] = terminatedPath
        }
        let fallback = fallbackLanguage.trimmingCharacters(in: .whitespacesAndNewlines)
        if !fallback.isEmpty {
            dict["fallbackLanguage"] = fallback
        }
        dict["forceFallbackLanguage"] = forceFallbackLanguage
        dict["forceScreenShotIcon"] = forceScreenShotIcon
        let iconDark = iconDarkPath.trimmingCharacters(in: .whitespacesAndNewlines)
        if !iconDark.isEmpty {
            dict["iconDarkPath"] = iconDark
        }
        let iconLight = iconLightPath.trimmingCharacters(in: .whitespacesAndNewlines)
        if !iconLight.isEmpty {
            dict["iconLightPath"] = iconLight
        }
        let format = requiredInstallationDisplayFormat.trimmingCharacters(in: .whitespacesAndNewlines)
        if !format.isEmpty {
            dict["requiredInstallationDisplayFormat"] = format
        }
        let screenDark = screenShotDarkPath.trimmingCharacters(in: .whitespacesAndNewlines)
        if !screenDark.isEmpty {
            dict["screenShotDarkPath"] = screenDark
        }
        let screenLight = screenShotLightPath.trimmingCharacters(in: .whitespacesAndNewlines)
        if !screenLight.isEmpty {
            dict["screenShotLightPath"] = screenLight
        }
        dict["showActivelyExploitedCVEs"] = showActivelyExploitedCVEs
        dict["showDeferralCount"] = showDeferralCount
        dict["showDaysRemainingToUpdate"] = showDaysRemainingToUpdate
        dict["showRequiredDate"] = showRequiredDate
        dict["simpleMode"] = simpleMode
        dict["singleQuitButton"] = singleQuitButton
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
