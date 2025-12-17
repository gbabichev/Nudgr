//
//  ContentView.swift
//  NudgeTestTool
//
//  Created by George Babichev on 12/17/25.
//

import SwiftUI
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

                    HStack(spacing: 12) {
                        Button("Execute") {
                            runCommand()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isExecuting || commandText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                        Button("Kill Nudge") {
                            killNudge()
                        }
                        .buttonStyle(.bordered)

                        Text("Sends a terminate to the Nudge process (user scope).")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
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
                    Button("Select JSON…") {
                        isShowingFileImporter = true
                    }
                    .buttonStyle(.bordered)

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

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("SOFA Feed")
                            .font(.title3.weight(.semibold))
                        if isFetchingSOFA {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }

                    Button("Fetch SOFA feed") {
                        fetchSOFAFeed()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isFetchingSOFA)

                    if let majors = sofaMajorDetails() {
                        VStack(alignment: .leading, spacing: 4) {
                            if let latest = majors.latest {
                                Text("Latest Major \(latest.major) (\(latest.productVersion))")
                                    .font(.headline)
                                Text("Release Date: \(latest.releaseDate)")
                                Text("Actively Exploited CVEs: \(latest.activelyExploitedCount)")
                                if !latest.activelyExploitedList.isEmpty {
                                    Text(latest.activelyExploitedList.joined(separator: ", "))
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                        .truncationMode(.middle)
                                }
                            }
                            if let previous = majors.previous {
                                Divider().padding(.vertical, 4)
                                Text("Previous Major \(previous.major) (\(previous.productVersion))")
                                    .font(.headline)
                                Text("Release Date: \(previous.releaseDate)")
                                Text("Actively Exploited CVEs: \(previous.activelyExploitedCount)")
                                if !previous.activelyExploitedList.isEmpty {
                                    Text(previous.activelyExploitedList.joined(separator: ", "))
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                        .truncationMode(.middle)
                                }
                            }
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
            return SOFAMajorSummary(
                major: major,
                productVersion: release.productVersion ?? "n/a",
                releaseDate: release.releaseDate ?? "n/a",
                activelyExploitedCount: exploitedList.count,
                activelyExploitedList: exploitedList
            )
        }

        let latestSummary = summary(for: latestMajor)
        let previousSummary = majors.dropFirst().first.flatMap { summary(for: $0) }

        return (latest: latestSummary, previous: previousSummary)
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
