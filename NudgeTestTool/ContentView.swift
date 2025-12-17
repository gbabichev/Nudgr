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

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Command Builder")
                .font(.title2.weight(.semibold))

            Text("Enter a shell command and tap Execute to run it.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                TextField("e.g. ls -la", text: $commandText)
                    .textFieldStyle(.roundedBorder)

                Button("Execute") {
                    runCommand()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isExecuting || commandText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
                    Text("Output")
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

        Task.detached(priority: .userInitiated) {
            let result = await ShellExecutor.shared.run(command: command)
            await MainActor.run {
                executionOutput = result.output
                executionError = result.error
                isExecuting = false
            }
        }
    }

    private func buildDefaultCommand() -> String {
        let jsonPath = Bundle.main.url(forResource: "patch-latest", withExtension: "json")?.path ?? "patch-latest.json"
        return #"/Applications/Utilities/Nudge.app/Contents/MacOS/Nudge -simulate-os-version "26.0" -json-url "\#(jsonPath)" -disable-random-delay"#
    }
}
