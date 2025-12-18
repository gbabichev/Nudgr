import SwiftUI
import AppKit
import Combine

@MainActor
class NudgeViewModel: ObservableObject {
    @Published var commandText: String = ""
    @Published var isExecuting: Bool = false
    @Published var executionOutput: String = ""
    @Published var executionError: String = ""
    @Published var activityLog: String = ""

    @Published var selectedJSONPath: String = ""
    @Published var parsedConfig: NudgeConfig?
    @Published var parseError: String = ""

    @Published var sofaFeed: SOFAFeed?
    @Published var sofaError: String = ""
    @Published var isFetchingSOFA: Bool = false

    @Published var nudgeInstalled: Bool = false
    @Published var nudgeVersion: String = "Unknown"
    @Published var nudgePath: String = "Unknown"
    @Published var nudgeDetectionLog: String = ""
    @Published var latestNudgeVersion: String = "Unknown"
    @Published var isFetchingLatestNudge: Bool = false
    @Published var latestNudgeError: String = ""
    @Published var latestSuiteDownloadURL: String = ""
    @Published var latestSuiteURL: String = ""
    @Published var latestSuiteError: String = ""
    @AppStorage("simulateDate") var simulateDate: Date = Calendar(identifier: .gregorian).startOfDay(for: Date())
    @AppStorage("simulateOSVersion") var simulateOSVersion: String = ""
    @AppStorage("includeSimulateDate") var includeSimulateDate: Bool = true
    @AppStorage("includeSimulateOSVersion") var includeSimulateOSVersion: Bool = true

    var isSOFAEnabled: Bool {
        parsedConfig?.optionalFeatures?.utilizeSOFAFeed ?? true
    }

    func initializeDefaultsIfNeeded() {
        if nudgeInstalled {
            commandText = buildCommand(jsonPath: "<your_json_url_here>")
        } else {
            commandText = "Nudge is not found. Please click the orange warning symbol in the toolbar to install Nudge."
        }
    }

    func runCommand() {
        let command = commandText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !command.isEmpty else { return }

        isExecuting = true
        executionOutput = ""
        executionError = ""
        appendLog("Executing: \(command)")

        Task.detached(priority: .userInitiated) { [command] in
            let result = await ShellExecutor.shared.run(command: command)
            await MainActor.run {
                self.executionOutput = result.output
                self.executionError = result.error
                self.appendLog("Execution complete.")
                self.isExecuting = false
            }
        }
    }

    func killNudge() {
        isExecuting = true
        executionOutput = ""
        executionError = ""
        appendLog("Attempting to kill Nudge by bundle id.")

        Task.detached(priority: .userInitiated) {
            let result = await NudgeProcessManager.shared.killNudge()
            await MainActor.run {
                self.executionOutput = result.output.isEmpty ? "Sent terminate to Nudge.app (if running)." : result.output
                self.executionError = result.error
                self.appendLog("Kill attempt finished.")
                self.isExecuting = false
            }
        }
    }

    func appendLog(_ message: String) {
        let timestamp = DateFormatter.shortTime.string(from: Date())
        if activityLog.isEmpty {
            activityLog = "[\(timestamp)] \(message)"
        } else {
            activityLog.append("\n[\(timestamp)] \(message)")
        }
        executionOutput = activityLog
    }

    func refreshNudgeInfo() {
        let result = detectNudge()
        nudgeInstalled = result.installed
        nudgePath = result.path
        nudgeVersion = result.version
        nudgeDetectionLog = result.log
        print(result.log)
    }

    func fetchLatestNudgeVersion() {
        isFetchingLatestNudge = true
        latestNudgeError = ""
        Task {
            do {
                let version = try await NudgeReleaseService.latestVersion()
                latestNudgeVersion = version
                isFetchingLatestNudge = false
            } catch {
                latestNudgeVersion = "Unavailable"
                latestNudgeError = error.localizedDescription
                isFetchingLatestNudge = false
                print("Latest Nudge fetch failed: \(error.localizedDescription)")
            }
        }
    }

    func fetchLatestSuiteURL() {
        latestSuiteError = ""
        Task {
            do {
                let url = try await NudgeReleaseService.latestSuiteDownloadURL()
                latestSuiteDownloadURL = url
                latestSuiteURL = url
            } catch {
                latestSuiteError = error.localizedDescription
            }
        }
    }

    func handleJSONSelection(url: URL) {
        let resolvedURL = url
        if resolvedURL.startAccessingSecurityScopedResource() {
            do { resolvedURL.stopAccessingSecurityScopedResource() }
        }

        selectedJSONPath = resolvedURL.path
        commandText = buildCommand(jsonPath: resolvedURL.path)
        appendLog("Selected JSON: \(resolvedURL.lastPathComponent)")
        parseConfig(at: resolvedURL)
    }

    func buildCommand(jsonPath: String) -> String {
        var normalizedPath = jsonPath
        if normalizedPath.lowercased().hasPrefix("file://") {
            normalizedPath.removeFirst("file://".count)
        }
        let escapedPath = normalizedPath.replacingOccurrences(of: "\"", with: "\\\"")
        var parts: [String] = [#"/Applications/Utilities/Nudge.app/Contents/MacOS/Nudge"#]
        parts.append(#"-json-url "file://\#(escapedPath)""#)
        parts.append("-disable-random-delay")
        if includeSimulateDate {
            let midnightUTC = Calendar(identifier: .gregorian).date(bySettingHour: 0, minute: 0, second: 0, of: simulateDate) ?? simulateDate
            let dateString = iso8601ZuluString(from: midnightUTC)
            parts.append(#"-simulate-date "\#(dateString)""#)
        }
        if includeSimulateOSVersion {
            parts.append(#"-simulate-os-version "\#(simulateOSVersion)""#)
        }
        return parts.joined(separator: " ")
    }

    func rebuildCommandPreservingJSONURL(fallback: String = "<your_json_url_here>") {
        let jsonPath = extractJSONURL(from: commandText) ?? fallback
        commandText = buildCommand(jsonPath: jsonPath)
    }

    func extractJSONURL(from command: String) -> String? {
        guard let range = command.range(of: #"-json-url ""#) else { return nil }
        let remainder = command[range.upperBound...]
        guard let endQuote = remainder.firstIndex(of: "\"") else { return nil }
        var urlString = String(remainder[..<endQuote])
        if urlString.lowercased().hasPrefix("file://") {
            urlString.removeFirst("file://".count)
        }
        return urlString
    }

    func buildInstallerCommand(for pkgURL: String? = nil) -> String {
        let candidate = pkgURL?.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSource = (candidate?.isEmpty == false ? candidate! : latestSuiteDownloadURL)
        let trimmed = trimmedSource.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return #"curl -L "<pkg_url>" -o /tmp/Nudge_Suite.pkg && sudo installer -pkg /tmp/Nudge_Suite.pkg -target /"#
        }
        return #"curl -L "\#(trimmed)" -o /tmp/Nudge_Suite.pkg && sudo installer -pkg /tmp/Nudge_Suite.pkg -target /"#
    }

    func ensureSuiteURLAndInstallerCommand() async throws -> String {
        if latestSuiteDownloadURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let url = try await NudgeReleaseService.latestSuiteDownloadURL()
            latestSuiteDownloadURL = url
            latestSuiteURL = url
        }
        return buildInstallerCommand()
    }

    func buildUninstallCommand() -> String {
        return #"sudo rm -rf "/Applications/Utilities/Nudge.app" && launchctl unload /Library/LaunchAgents/com.github.macadmins.Nudge.plist 2>/dev/null && sudo pkgutil --forget com.github.macadmins.Nudge.Suite && sudo pkgutil --forget com.github.macadmins.Nudge"#
    }

    func defaultJSONPath() -> String {
        Bundle.main.url(forResource: "patch-latest", withExtension: "json")?.path ?? "patch-latest.json"
    }

    func fetchSOFAFeed() {
        isFetchingSOFA = true
        sofaError = ""
        Task {
            do {
                let feed = try await SOFAFeedService.fetch()
                sofaFeed = feed
                isFetchingSOFA = false
                appendLog("Fetched SOFA feed.")
            } catch {
                sofaError = error.localizedDescription
                isFetchingSOFA = false
                appendLog("SOFA fetch failed: \(error.localizedDescription)")
            }
        }
    }

    func sofaMajorDetails() -> (latest: SOFAMajorSummary?, previous: SOFAMajorSummary?)? {
        guard let feed = sofaFeed else { return nil }
        var grouped: [Int: [SOFAOSVersion]] = [:]

        for os in feed.osVersions {
            guard let major = extractMajor(os.osVersion) else { continue }
            grouped[major, default: []].append(os)
        }

        let majors = grouped.keys.sorted(by: >)
        guard let latestMajor = majors.first else { return nil }

        func summary(for major: Int) -> SOFAMajorSummary? {
            guard let entries = grouped[major] else { return nil }
            guard let entry = entries.first(where: { $0.latest != nil }) else { return nil }
            guard let release = entry.latest else { return nil }
            let exploitedList = release.activelyExploitedCVEs ?? []
            let dates = computeDates(for: release)
            return SOFAMajorSummary(
                major: major,
                productVersion: release.productVersion ?? "n/a",
                releaseDate: release.releaseDate ?? "n/a",
                activelyExploitedCount: exploitedList.count,
                activelyExploitedList: exploitedList,
                requiredInstallDate: dates.requiredInstallDate,
                nudgeLaunchDate: dates.nudgeLaunchDate
            )
        }

        let latestSummary = summary(for: latestMajor)
        let previousSummary = majors.dropFirst().first.flatMap { summary(for: $0) }

        return (latest: latestSummary, previous: previousSummary)
    }

    func localRequirementSummary() -> LocalRequirementSummary? {
        guard let requirement = parsedConfig?.osVersionRequirements.first else { return nil }
        let requiredDate = requirement.requiredInstallationDate.flatMap { parseISODate($0) }
        let requiredString = requiredDate.flatMap { isoLocalString(from: $0) }

        let launchDate = computeLocalNudgeLaunchDate(requirement: requirement, requiredDate: requiredDate)
        let launchString = launchDate.flatMap { isoLocalString(from: $0) }

        return LocalRequirementSummary(
            requiredMinimumOSVersion: requirement.requiredMinimumOSVersion,
            requiredInstallDate: requiredString,
            nudgeLaunchDate: launchString
        )
    }

    private func detectNudge() -> (installed: Bool, path: String, version: String, log: String) {
        var log: [String] = []
        let searchPaths = [
            "/Applications/Utilities/Nudge.app",
            "/Applications/Nudge.app",
            "/System/Applications/Utilities/Nudge.app"
        ]

        log.append("Searching for Nudge.app…")
        if let bundleURL = findNudgeBundle(in: searchPaths, log: &log) {
            let path = bundleURL.path
            let version = readVersion(from: bundleURL, log: &log)
            let joined = log.joined(separator: "\n")
            return (true, path, version, joined.isEmpty ? "No log entries." : joined)
        } else {
            log.append("Nudge not found.")
            let joined = log.joined(separator: "\n")
            return (false, "Not found", "n/a", joined.isEmpty ? "No log entries." : joined)
        }
    }

    private func findNudgeBundle(in paths: [String], log: inout [String]) -> URL? {
        let fm = FileManager.default
        for path in paths {
            var isDir: ObjCBool = false
            if unsafe fm.fileExists(atPath: path, isDirectory: &isDir), isDir.boolValue {
                log.append("Found Nudge at \(path)")
                return URL(fileURLWithPath: path, isDirectory: true)
            }
            // Also scan directory contents in case of case differences.
            let dirURL = URL(fileURLWithPath: path).deletingLastPathComponent()
            if unsafe fm.fileExists(atPath: dirURL.path, isDirectory: &isDir), isDir.boolValue {
                if let contents = try? fm.contentsOfDirectory(atPath: dirURL.path) {
                    if contents.contains(where: { $0.lowercased() == "nudge.app" }) {
                        log.append("Found Nudge in directory scan at \(dirURL.path)/Nudge.app")
                        return dirURL.appendingPathComponent("Nudge.app", isDirectory: true)
                    } else {
                        let list = contents.joined(separator: ", ")
                        log.append("Directory scan at \(dirURL.path) contents: \(list)")
                    }
                }
            }
            log.append("No bundle at \(path)")
        }
        // Deep search within /Applications and /Applications/Utilities in case of unusual casing/locations.
        let searchDirs = ["/Applications/Utilities", "/Applications"]
        for dir in searchDirs {
            if let url = deepSearch(appName: "nudge.app", in: dir, log: &log) {
                return url
            }
        }
        if let found = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.github.macadmins.Nudge") {
            log.append("Found via bundle id: \(found.path)")
            return found
        }
        log.append("Bundle id lookup failed.")
        return nil
    }

    private func readVersion(from bundleURL: URL, log: inout [String]) -> String {
        if let bundle = Bundle(url: bundleURL),
           let version = bundle.infoDictionary?["CFBundleShortVersionString"] as? String {
            log.append("Version from bundle: \(version)")
            return version
        }
        let infoURL = bundleURL.appendingPathComponent("Contents/Info.plist")
        if let dict = NSDictionary(contentsOf: infoURL),
           let version = dict["CFBundleShortVersionString"] as? String {
            log.append("Version from Info.plist: \(version)")
            return version
        }
        log.append("Could not read version from \(infoURL.path)")
        return "Unknown"
    }

    private func deepSearch(appName: String, in directory: String, log: inout [String]) -> URL? {
        let fm = FileManager.default
        let dirURL = URL(fileURLWithPath: directory, isDirectory: true)
        guard let enumerator = fm.enumerator(at: dirURL, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) else {
            log.append("Enumerator failed for \(directory)")
            return nil
        }
        for case let url as URL in enumerator {
            if url.lastPathComponent.lowercased() == appName {
                log.append("Deep search found \(url.path)")
                return url
            }
        }
        log.append("Deep search in \(directory) found nothing.")
        return nil
    }

    func parseConfig(at url: URL) {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let config = try decoder.decode(NudgeConfig.self, from: data)
            parsedConfig = config
            parseError = ""
        } catch {
            parsedConfig = nil
            parseError = error.localizedDescription
        }
    }

    private func computeDates(for release: SOFARelease) -> (requiredInstallDate: String?, nudgeLaunchDate: String?) {
        guard let releaseDateString = release.releaseDate,
              let releaseDate = parseISODate(releaseDateString) else {
            return (requiredInstallDate: nil, nudgeLaunchDate: nil)
        }

        let requirement = parsedConfig?.osVersionRequirements.first
        let optional = parsedConfig?.optionalFeatures
        let userExperience = parsedConfig?.userExperience

        let hasActive = !(release.activelyExploitedCVEs ?? []).isEmpty
        let hasAnyCVE = (release.uniqueCVEsCount ?? 0) > 0 || !(release.cves ?? [:]).isEmpty

        let isMajor = isMajorRelease(release.productVersion ?? "")

        // Defaults per spec.
        let defaultActive = 14
        let defaultNonActive = 21
        let defaultStandard = 28

        let slaDays: Int
        if hasActive {
            slaDays = isMajor
            ? (requirement?.activelyExploitedCVEsMajorUpgradeSLA ?? defaultActive)
            : (requirement?.activelyExploitedCVEsMinorUpdateSLA ?? defaultActive)
        } else if hasAnyCVE {
            slaDays = isMajor
            ? (requirement?.nonActivelyExploitedCVEsMajorUpgradeSLA ?? defaultNonActive)
            : (requirement?.nonActivelyExploitedCVEsMinorUpdateSLA ?? defaultNonActive)
        } else {
            if optional?.disableNudgeForStandardInstalls == true {
                return (requiredInstallDate: nil, nudgeLaunchDate: nil)
            }
            slaDays = isMajor
            ? (requirement?.standardMajorUpgradeSLA ?? defaultStandard)
            : (requirement?.standardMinorUpdateSLA ?? defaultStandard)
        }

        let calendar = Calendar(identifier: .gregorian)

        guard let targetDate = calendar.date(byAdding: .day, value: slaDays, to: releaseDate) else {
            return (requiredInstallDate: nil, nudgeLaunchDate: nil)
        }

        let launchDelayDays = isMajor
        ? (userExperience?.nudgeMajorUpgradeEventLaunchDelay ?? 0)
        : (userExperience?.nudgeMinorUpdateEventLaunchDelay ?? 0)

        let launchDate = calendar.date(byAdding: .day, value: launchDelayDays, to: releaseDate)

        let required = isoLocalString(from: targetDate)
        let launch = launchDate.flatMap { isoLocalString(from: $0) }
        return (required, launch)
    }

    private func computeLocalNudgeLaunchDate(requirement: OSVersionRequirement, requiredDate: Date?) -> Date? {
        guard let requiredDate else { return nil }
        let isMajor = isMajorRelease(requirement.requiredMinimumOSVersion)

        // SLA values invert the required date back to an approximate release date.
        let defaultStandard = 28
        let slaDays = isMajor
        ? (requirement.standardMajorUpgradeSLA ?? defaultStandard)
        : (requirement.standardMinorUpdateSLA ?? defaultStandard)

        let calendar = Calendar(identifier: .gregorian)
        guard let releaseDate = calendar.date(byAdding: .day, value: -slaDays, to: requiredDate) else { return nil }

        let launchDelayDays = isMajor
        ? (parsedConfig?.userExperience?.nudgeMajorUpgradeEventLaunchDelay ?? 0)
        : (parsedConfig?.userExperience?.nudgeMinorUpdateEventLaunchDelay ?? 0)

        return calendar.date(byAdding: .day, value: launchDelayDays, to: releaseDate)
    }

    private func isMajorRelease(_ version: String) -> Bool {
        let components = version.split(separator: ".").compactMap { Int($0) }
        if components.count <= 1 { return true }
        return (components.dropFirst().first ?? 0) == 0
    }

    private func parseISODate(_ string: String) -> Date? {
        let iso = ISO8601DateFormatter()
        iso.timeZone = TimeZone(secondsFromGMT: 0)
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso.date(from: string) { return date }
        iso.formatOptions = [.withInternetDateTime]
        if let date = iso.date(from: string) { return date }

        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        df.timeZone = TimeZone(secondsFromGMT: 0)
        return df.date(from: string)
    }

    private func isoLocalString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd, HH:mm"
        return formatter.string(from: date)
    }

    private func iso8601ZuluString(from date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.formatOptions = [.withInternetDateTime, .withColonSeparatorInTime, .withDashSeparatorInDate]
        return formatter.string(from: date)
    }

    private func extractMajor(_ osVersion: String) -> Int? {
        let pattern = #"(\d+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(location: 0, length: osVersion.utf16.count)
        guard let match = regex.firstMatch(in: osVersion, options: [], range: range),
              let range1 = Range(match.range(at: 1), in: osVersion) else { return nil }
        return Int(osVersion[range1])
    }
}
