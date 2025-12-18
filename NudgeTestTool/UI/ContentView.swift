//
//  ContentView.swift
//  NudgeTestTool
//
//  Created by George Babichev on 12/17/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var model = NudgeViewModel()
    @State private var isShowingFileImporter: Bool = false
    @State private var isShowingInfo: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 24) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Command Builder")
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .center)

                Text("Test Nudge by building a run command, and executing with the play button in the toolbar.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    TextEditor(text: $model.commandText)
                        .frame(minHeight: 80)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.3))
                        )
                        .font(.system(.body, design: .monospaced))
                        .padding(.horizontal, -4)
                }

                if model.isExecuting {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("Running…")
                            .foregroundStyle(.secondary)
                    }
                }

                if !model.executionOutput.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Output / Log")
                            .font(.headline)
                        ScrollView {
                            Text(model.executionOutput)
                                .font(.system(.body, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: 200)
                    }
                }

                if !model.executionError.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Error")
                            .font(.headline)
                        ScrollView {
                            Text(model.executionError)
                                .font(.system(.body, design: .monospaced))
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: 200)
                    }
                }
            }

            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("JSON Info")
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .center)

                VStack(alignment: .leading, spacing: 8) {
                    if !model.selectedJSONPath.isEmpty {
                        Text("Selected: \(model.selectedJSONPath)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                            .truncationMode(.middle)
                    }
                    else {
                        Text("Please select a JSON file for inspection.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                            .truncationMode(.middle)
                    }
                }

                if let config = model.parsedConfig {
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
                } else if !model.parseError.isEmpty {
                    Text("Parse error: \(model.parseError)")
                        .foregroundStyle(.red)
                        .font(.footnote)
                }

                Divider()
                    .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("SOFA Feed")
                            .font(.title3.weight(.semibold))
                        if model.isFetchingSOFA {
                            ProgressView()
                                .controlSize(.small)
                        }
                        Spacer()
                        Button {
                            model.fetchSOFAFeed()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                        .buttonStyle(.bordered)
                        .disabled(model.isFetchingSOFA)
                    }
                    
                    if !model.isSOFAEnabled {
                        Text("SOFA is not enabled in the selected JSON file.")
                            .foregroundStyle(.red)
                    }

                    if let majors = model.sofaMajorDetails() {
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
                    } else if !model.sofaError.isEmpty {
                        Text("SOFA error: \(model.sofaError)")
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


                VStack(alignment: .leading, spacing: 8) {
                    Text("Required Install By")
                        .font(.title3.weight(.semibold))
                        .frame(maxWidth: .infinity, alignment: .center)

                    if model.isSOFAEnabled, let majors = model.sofaMajorDetails() {
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
                    } else if let local = model.localRequirementSummary() {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Required Minimum OS: \(local.requiredMinimumOSVersion)")
                                .font(.headline)
                            Text("Required Install By: \(local.requiredInstallDate ?? "n/a")")
                            Text("Nudge Launches On: \(local.nudgeLaunchDate ?? "n/a")")
                        }
                    } else if !model.sofaError.isEmpty {
                        Text("SOFA error: \(model.sofaError)")
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
                    if !model.nudgeInstalled {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.yellow)
                    } else {
                        Image(systemName: "info.circle")
                    }
                }
                .buttonStyle(.bordered)
                .tint(model.nudgeInstalled ? .accentColor : .yellow)
            }

            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    model.killNudge()
                } label: {
                    Label("Kill Nudge", systemImage: "xmark.circle.fill")
                        .symbolRenderingMode(.multicolor)
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .disabled(model.isExecuting)

                Button {
                    model.runCommand()
                } label: {
                    Label("Execute", systemImage: "play.fill")
                        .symbolRenderingMode(.monochrome)
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.bordered)
                .tint(.blue)
                .disabled(model.isExecuting || model.commandText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .sheet(isPresented: $isShowingInfo) {
            NudgeInfoSheet(model: model, isShowingInfo: $isShowingInfo)
        }
        .fileImporter(isPresented: $isShowingFileImporter,
                      allowedContentTypes: [.json],
                      allowsMultipleSelection: false) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    model.handleJSONSelection(url: url)
                }
            case .failure(let error):
                model.executionError = error.localizedDescription
            }
        }
        .onAppear {
            //model.initializeDefaultsIfNeeded()
            model.refreshNudgeInfo()
            model.fetchLatestNudgeVersion()
        }
    }
}
