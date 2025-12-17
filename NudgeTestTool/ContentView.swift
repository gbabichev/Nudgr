//
//  ContentView.swift
//  NudgeTestTool
//
//  Created by George Babichev on 12/17/25.
//

import SwiftUI

struct ContentView: View {
    @State private var commandText: String = ""
    @State private var isExecuting: Bool = false
    @State private var executionOutput: String = ""
    @State private var executionError: String = ""
    @State private var activityLog: String = ""

    var body: some View {
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
        .padding(24)
        .onAppear {
            if commandText.isEmpty {
                commandText = buildDefaultCommand()
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

    private func buildDefaultCommand() -> String {
        let jsonPath = Bundle.main.url(forResource: "patch-latest", withExtension: "json")?.path ?? "patch-latest.json"
        return #"/Applications/Utilities/Nudge.app/Contents/MacOS/Nudge -simulate-os-version "26.0" -json-url "file://\#(jsonPath)" -disable-random-delay -simulate-date "2025-12-24T08:00:00Z""#
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
}
