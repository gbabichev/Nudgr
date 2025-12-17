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
