//
//  ContentView.swift
//  NudgeTestTool
//
//  Created by George Babichev on 12/17/25.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var commandText: String = ""
    @State private var isExecuting: Bool = false
    @State private var executionOutput: String = ""
    @State private var executionError: String = ""
    @State private var activityLog: String = ""
    @State private var selectedJSONPath: String = ""
    @State private var isShowingFileImporter: Bool = false
    @State private var parsedConfig: NudgeConfig?
    @State private var parseError: String = ""
    @State private var sofaFeed: SOFAFeed?
    @State private var sofaError: String = ""
    @State private var isFetchingSOFA: Bool = false
    @State private var isShowingInfo: Bool = false
    @State private var nudgeInstalled: Bool = false
    @State private var nudgeVersion: String = "Unknown"
    @State private var nudgePath: String = "Unknown"
    @State private var nudgeDetectionLog: String = ""
    @State private var latestNudgeVersion: String = "Unknown"
    @State private var isFetchingLatestNudge: Bool = false
    @State private var latestNudgeError: String = ""
    @State private var latestSuiteURL: String = ""
    @State private var latestSuiteError: String = ""
    private var isSOFAEnabled: Bool {
        parsedConfig?.optionalFeatures?.utilizeSOFAFeed ?? true
    }

    var body: some View {
        HStack(alignment: .top, spacing: 24) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Command Builder")
                    .font(.title2.weight(.semibold))

                Text("Enter a shell command and tap Execute to run it.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    TextEditor(text: $commandText)
                        .frame(minHeight: 80)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.3))
                        )
                    .font(.system(.body, design: .monospaced))
                    .padding(.horizontal, -4)
            }

                if isExecuting {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("Running…")
                            .foregroundStyle(.secondary)
                    }
                }

                if !executionOutput.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Output / Log")
                            .font(.headline)
                        ScrollView {
                            Text(executionOutput)
                                .font(.system(.body, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: 200)
                    }
                }

                if !executionError.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Error")
                            .font(.headline)
                        ScrollView {
                            Text(executionError)
                                .font(.system(.body, design: .monospaced))
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: 200)
                    }
                }
            }

                VStack(alignment: .leading, spacing: 12) {
                    Text("JSON & Settings")
                        .font(.title3.weight(.semibold))

                Text("Pick a JSON file to use for -json-url. Command updates automatically.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    if !selectedJSONPath.isEmpty {
                        Text("Selected: \(selectedJSONPath)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                            .truncationMode(.middle)
                    }
                }

                    if let config = parsedConfig {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Parsed JSON")
                                .font(.headline)
                            if let useSOFA = config.optionalFeatures?.utilizeSOFAFeed {
                                Text("Utilize SOFA Feed: \(useSOFA ? "true" : "false")")
                            } else {
                                Text("Utilize SOFA Feed: not set")
                                    .foregroundStyle(.secondary)
                            }
                            if let requirement = config.osVersionRequirements.first {
                                Text("Required Minimum OS: \(requirement.requiredMinimumOSVersion)")
                            } else {
                                Text("No osVersionRequirements found.")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } else if !parseError.isEmpty {
                    Text("Parse error: \(parseError)")
                        .foregroundStyle(.red)
                        .font(.footnote)
                }

                Divider()
                    .padding(.vertical, 4)

                if isSOFAEnabled {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("SOFA Feed")
                                .font(.title3.weight(.semibold))
                            if isFetchingSOFA {
                                ProgressView()
                                    .controlSize(.small)
                            }
                            Spacer()
                            Button {
                                fetchSOFAFeed()
                            } label: {
                                Image(systemName: "arrow.clockwise")
                            }
                            .buttonStyle(.bordered)
                            .disabled(isFetchingSOFA)
                        }

                        if let majors = sofaMajorDetails() {
                            HStack(alignment: .top, spacing: 16) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Latest Major (\(majors.latest?.productVersion ?? "n/a"))")
                                        .font(.headline)
                                    Text("Release Date: \(majors.latest?.releaseDate ?? "n/a")")
                                    Text("Actively Exploited CVEs: \(majors.latest?.activelyExploitedCount ?? 0)")
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)

                                Divider()

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Previous Major (\(majors.previous?.productVersion ?? "n/a"))")
                                        .font(.headline)
                                    Text("Release Date: \(majors.previous?.releaseDate ?? "n/a")")
                                    Text("Actively Exploited CVEs: \(majors.previous?.activelyExploitedCount ?? 0)")
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        } else if !sofaError.isEmpty {
                            Text("SOFA error: \(sofaError)")
                                .foregroundStyle(.red)
                                .font(.footnote)
                        } else {
                            Text("No SOFA data loaded.")
                                .foregroundStyle(.secondary)
                                .font(.footnote)
                        }
                    }

                    Divider()
                        .padding(.vertical, 4)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Required Install By")
                        .font(.title3.weight(.semibold))
                        .frame(maxWidth: .infinity, alignment: .center)

                    if isSOFAEnabled, let majors = sofaMajorDetails() {
                        HStack(alignment: .top, spacing: 16) {
                            if let latest = majors.latest {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Latest Major \(latest.major) (\(latest.productVersion))")
                                        .font(.headline)
                                    Text("Required Install By: \(latest.requiredInstallDate ?? "n/a")")
                                    Text("Nudge Launches On: \(latest.nudgeLaunchDate ?? "n/a")")
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            Divider()
                            if let previous = majors.previous {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Previous Major \(previous.major) (\(previous.productVersion))")
                                        .font(.headline)
                                    Text("Required Install By: \(previous.requiredInstallDate ?? "n/a")")
                                    Text("Nudge Launches On: \(previous.nudgeLaunchDate ?? "n/a")")
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    } else if let local = localRequirementSummary() {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Required Minimum OS: \(local.requiredMinimumOSVersion)")
                                .font(.headline)
                            Text("Required Install By: \(local.requiredInstallDate ?? "n/a")")
                            Text("Nudge Launches On: \(local.nudgeLaunchDate ?? "n/a")")
                        }
                    } else if !sofaError.isEmpty {
                        Text("SOFA error: \(sofaError)")
                            .foregroundStyle(.red)
                            .font(.footnote)
                    } else {
                        Text("No SOFA data loaded.")
                            .foregroundStyle(.secondary)
                            .font(.footnote)
                    }
                }

                Spacer()
            }
        }
        .padding(24)
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {

                Button {
                    isShowingFileImporter = true
                } label: {
                    Label("Select JSON", systemImage: "doc")
                }
                .buttonStyle(.bordered)
            }

            ToolbarItemGroup(placement: .status) {
                Button {
                    isShowingInfo = true
                } label: {
                    if !nudgeInstalled {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(nudgeInstalled ? .accentColor : .yellow)
                    }
                    else {
                        Image(systemName: "info.circle")
                    }

                }
            }
            
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    killNudge()
                } label: {
                    Label("Kill Nudge", systemImage: "xmark.circle.fill")
                        .symbolRenderingMode(.multicolor)
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .disabled(isExecuting)

                Button {
                    runCommand()
                } label: {
                    Label("Execute", systemImage: "play.fill")
                        .symbolRenderingMode(.monochrome)
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.bordered)
                .tint(.blue)
                .disabled(isExecuting || commandText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .sheet(isPresented: $isShowingInfo) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Nudge Status")
                    .font(.title2.weight(.semibold))
                Text("Installed: \(nudgeInstalled ? "Yes" : "No")")
                Text("Version: \(nudgeInstalled ? nudgeVersion : "n/a")")
                Text("Path: \(nudgeInstalled ? nudgePath : "n/a")")
                HStack(spacing: 8) {
                    Text("Latest available: \(latestNudgeVersion)")
                    if isFetchingLatestNudge {
                        ProgressView().controlSize(.small)
                    }
                }
                if !latestNudgeError.isEmpty {
                    Text("Latest fetch error: \(latestNudgeError)")
                        .foregroundStyle(.red)
                        .font(.footnote)
                }
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Latest Nudge_Suite pkg URL", text: $latestSuiteURL)
                        .textFieldStyle(.roundedBorder)
                        .disabled(true)
                    HStack {
                        Button {
                            fetchLatestSuiteURL()
                        } label: {
                            Label("Get Nudge_Suite pkg", systemImage: "arrow.down.circle")
                        }
                        .buttonStyle(.bordered)
                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(latestSuiteURL, forType: .string)
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                        .buttonStyle(.bordered)
                        .disabled(latestSuiteURL.isEmpty)
                    }
                    if !latestSuiteError.isEmpty {
                        Text("Suite fetch error: \(latestSuiteError)")
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }
                }
                HStack {
                    Button {
                        refreshNudgeInfo()
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                    Button {
                        fetchLatestNudgeVersion()
                    } label: {
                        Label("Check latest", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .buttonStyle(.bordered)
                    Spacer()
                }
                Divider().padding(.vertical, 4)
                Text("Detection log")
                    .font(.headline)
                ScrollView {
                    Text(nudgeDetectionLog.isEmpty ? "No log recorded." : nudgeDetectionLog)
                        .font(.system(.footnote, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 180)
                Button("Close") {
                    isShowingInfo = false
                }
                .padding(.top, 8)
            }
            .padding()
            .frame(minWidth: 320)
            .onAppear {
                refreshNudgeInfo()
                fetchLatestNudgeVersion()
            }
        }
        .fileImporter(isPresented: $isShowingFileImporter,
                      allowedContentTypes: [.json],
                      allowsMultipleSelection: false) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    handleJSONSelection(url: url)
                }
            case .failure(let error):
                executionError = error.localizedDescription
            }
        }
        .onAppear {
            if commandText.isEmpty {
                let defaultPath = defaultJSONPath()
                selectedJSONPath = defaultPath
                commandText = buildCommand(jsonPath: defaultPath)
                parseConfig(at: URL(fileURLWithPath: defaultPath))
            }
            refreshNudgeInfo()
            fetchLatestNudgeVersion()
        }
    }

    private func runCommand() {
        let command = commandText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !command.isEmpty else { return }

        isExecuting = true
        executionOutput = ""
        executionError = ""
        appendLog("Executing: \(command)")

        Task.detached(priority: .userInitiated) {
            let result = await ShellExecutor.shared.run(command: command)
            await MainActor.run {
                executionOutput = result.output
                executionError = result.error
                appendLog("Execution complete.")
                isExecuting = false
            }
        }
    }

    private func killNudge() {
        isExecuting = true
        executionOutput = ""
        executionError = ""
        appendLog("Attempting to kill Nudge by bundle id.")

        Task.detached(priority: .userInitiated) {
            let result = await NudgeProcessManager.shared.killNudge()
            await MainActor.run {
                executionOutput = result.output.isEmpty ? "Sent terminate to Nudge.app (if running)." : result.output
                executionError = result.error
                appendLog("Kill attempt finished.")
                isExecuting = false
            }
        }
    }

    private func appendLog(_ message: String) {
        let timestamp = DateFormatter.shortTime.string(from: Date())
        if activityLog.isEmpty {
            activityLog = "[\(timestamp)] \(message)"
        } else {
            activityLog.append("\n[\(timestamp)] \(message)")
        }
        executionOutput = activityLog
    }

    private func refreshNudgeInfo() {
        let result = detectNudge()
        DispatchQueue.main.async {
            nudgeInstalled = result.installed
            nudgePath = result.path
            nudgeVersion = result.version
            nudgeDetectionLog = result.log
            print(result.log)
        }
    }

    private func fetchLatestNudgeVersion() {
        isFetchingLatestNudge = true
        latestNudgeError = ""
        Task {
            do {
                let version = try await NudgeReleaseService.latestVersion()
                await MainActor.run {
                    latestNudgeVersion = version
                    isFetchingLatestNudge = false
                }
            } catch {
                await MainActor.run {
                    latestNudgeVersion = "Unavailable"
                    latestNudgeError = error.localizedDescription
                    isFetchingLatestNudge = false
                    print("Latest Nudge fetch failed: \(error.localizedDescription)")
                }
            }
        }
    }

    private func fetchLatestSuiteURL() {
        latestSuiteError = ""
        Task {
            do {
                let url = try await NudgeReleaseService.latestSuiteDownloadURL()
                await MainActor.run {
                    latestSuiteURL = url
                }
            } catch {
                await MainActor.run {
                    latestSuiteError = error.localizedDescription
                }
            }
        }
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
            if fm.fileExists(atPath: path, isDirectory: &isDir), isDir.boolValue {
                log.append("Found Nudge at \(path)")
                return URL(fileURLWithPath: path, isDirectory: true)
            }
            // Also scan directory contents in case of case differences.
            let dirURL = URL(fileURLWithPath: path).deletingLastPathComponent()
            if fm.fileExists(atPath: dirURL.path, isDirectory: &isDir), isDir.boolValue {
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

    private func handleJSONSelection(url: URL) {
        var resolvedURL = url
        if resolvedURL.startAccessingSecurityScopedResource() {
            defer { resolvedURL.stopAccessingSecurityScopedResource() }
        }

        selectedJSONPath = resolvedURL.path
        commandText = buildCommand(jsonPath: resolvedURL.path)
        appendLog("Selected JSON: \(resolvedURL.lastPathComponent)")
        parseConfig(at: resolvedURL)
    }

    private func buildCommand(jsonPath: String) -> String {
        let escapedPath = jsonPath.replacingOccurrences(of: "\"", with: "\\\"")
        return #"/Applications/Utilities/Nudge.app/Contents/MacOS/Nudge -simulate-os-version "26.0" -json-url "file://\#(escapedPath)" -disable-random-delay -simulate-date "2025-12-24T08:00:00Z""#
    }

    private func defaultJSONPath() -> String {
        Bundle.main.url(forResource: "patch-latest", withExtension: "json")?.path ?? "patch-latest.json"
    }

    private func fetchSOFAFeed() {
        isFetchingSOFA = true
        sofaError = ""
        Task {
            do {
                let feed = try await SOFAFeedService.fetch()
                await MainActor.run {
                    sofaFeed = feed
                    isFetchingSOFA = false
                    appendLog("Fetched SOFA feed.")
                }
            } catch {
                await MainActor.run {
                    sofaError = error.localizedDescription
                    isFetchingSOFA = false
                    appendLog("SOFA fetch failed: \(error.localizedDescription)")
                }
            }
        }
    }

    private func sofaMajorDetails() -> (latest: SOFAMajorSummary?, previous: SOFAMajorSummary?)? {
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

    private func localRequirementSummary() -> LocalRequirementSummary? {
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
            return (nil, nil)
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

    private func extractMajor(_ osVersion: String) -> Int? {
        // Pull the first integer found in the OSVersion string, e.g. "macOS 26" -> 26, "Sequoia 15" -> 15.
        let pattern = #"(\d+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(location: 0, length: osVersion.utf16.count)
        guard let match = regex.firstMatch(in: osVersion, options: [], range: range),
              let range1 = Range(match.range(at: 1), in: osVersion) else { return nil }
        return Int(osVersion[range1])
    }

    private func parseConfig(at url: URL) {
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
}
