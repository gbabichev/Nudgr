//
//  ContentView.swift
//  NudgeTestTool
//
//  Created by George Babichev on 12/17/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @ObservedObject var model: NudgeViewModel
    @Binding var isShowingFileImporter: Bool
    @Binding var shouldLoadSelectionInBuilder: Bool
    @State private var isShowingInfo: Bool = false
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        HStack(alignment: .top, spacing: 24) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Command Builder")
                    .font(.title2.weight(.semibold))
                    //.frame(maxWidth: .infinity, alignment: .center)
                
                Text("Test Nudge by building a run command, and executing with the play button in the toolbar.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                VStack(alignment: .leading, spacing: 8) {
                    
                    SettingsRow("Include simulate-date", subtitle: "Simulate the current date.") {
                        Toggle("", isOn: $model.includeSimulateDate)
                            .toggleStyle(.switch)
                            .onChange(of: model.includeSimulateDate) { _,_ in
                                model.rebuildCommandPreservingJSONURL()
                            }
                    }
                    
                    DatePicker("Date to simulate:", selection: $model.simulateDate, displayedComponents: [.date])
                        .datePickerStyle(.compact)
                        .onChange(of: model.simulateDate) { _,_ in
                            model.rebuildCommandPreservingJSONURL()
                        }
                        .disabled(!model.includeSimulateDate)
                        .opacity(model.includeSimulateDate ? 1.0 : 0.4)
                    
                    Divider()
                    
                    SettingsRow("Include simulate-os-version", subtitle: "Simulate the current OS Version.") {
                        Toggle("", isOn: $model.includeSimulateOSVersion)
                            .toggleStyle(.switch)
                            .onChange(of: model.includeSimulateOSVersion) { _,_ in
                                model.rebuildCommandPreservingJSONURL()
                            }
                    }
                    
                    TextField("OS Version", text: $model.simulateOSVersion)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 140)
                        .onChange(of: model.simulateOSVersion) { _,_ in
                            model.rebuildCommandPreservingJSONURL()
                        }
                        .disabled(!model.includeSimulateOSVersion)
                        .opacity(model.includeSimulateOSVersion ? 1.0 : 0.4)
                }
                            
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
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("JSON Info")
                        .font(.title2.weight(.semibold))
                    Spacer()
                    Button {
                        model.refreshSelectedJSON()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                    .disabled(model.selectedJSONPath.isEmpty)
                }
                
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
                        HStack(alignment: .top, spacing: 16) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("General Settings")
                                    .font(.headline)
                                if let useSOFA = config.optionalFeatures?.utilizeSOFAFeed {
                                    Text("Utilize SOFA Feed: \(useSOFA ? "true" : "false")")
                                } else {
                                    Text("Utilize SOFA Feed: not set")
                                        .foregroundStyle(.secondary)
                                }
                                if let requirement = config.osVersionRequirements.first {
                                    Text("Required Minimum OS: \(requirement.requiredMinimumOSVersion)")
                                    if let rule = requirement.targetedOSVersionsRule, !rule.isEmpty {
                                        Text("Targeted OS Rule: \(rule)")
                                    }
                                    if let aggressive = config.optionalFeatures?.aggressiveUserExperience {
                                        Text("Aggressive User Experience: \(aggressive ? "true" : "false")")
                                    } else {
                                        Text("Aggressive User Experience: not set")
                                            .foregroundStyle(.secondary)
                                    }
                                    if let fullscreen = config.optionalFeatures?.aggressiveUserFullScreenExperience {
                                        Text("Aggressive Full Screen Experience: \(fullscreen ? "true" : "false")")
                                    } else {
                                        Text("Aggressive Full Screen Experience: not set")
                                            .foregroundStyle(.secondary)
                                    }
                                    Divider()
                                    if let sla = model.slaKickoffSummary() {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("SLA Kickoff Dates (\(sla.source))")
                                                .font(.headline)
                                            Text("Release Date: \(sla.releaseDate)")
                                            Text("Standard: \(sla.standard)")
                                                .font((sla.highlight == .standard) ? .body.weight(.semibold) : .body)
                                            Text("Non-Active CVE: \(sla.nonActive)")
                                                .font((sla.highlight == .nonActive) ? .body.weight(.semibold) : .body)
                                            Text("Active CVE: \(sla.active)")
                                                .font((sla.highlight == .active) ? .body.weight(.semibold) : .body)
                                        }
                                    } else {
                                        Text("SLA Kickoff Dates: n/a")
                                            .foregroundStyle(.secondary)
                                    }
                                } else {
                                    Text("No osVersionRequirements found.")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Divider()
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Deferrals")
                                    .font(.headline)
                                if let experience = config.userExperience {
                                    if let value = experience.allowGracePeriods {
                                        Text("Allow Grace Periods: \(value ? "true" : "false")")
                                    } else {
                                        Text("Allow Grace Periods: not set")
                                            .foregroundStyle(.secondary)
                                    }
                                    if let value = experience.allowLaterDeferralButton {
                                        Text("Allow Later Deferral Button: \(value ? "true" : "false")")
                                    } else {
                                        Text("Allow Later Deferral Button: not set")
                                            .foregroundStyle(.secondary)
                                    }
                                    if let value = experience.allowUserQuitDeferrals {
                                        Text("Allow User Quit Deferrals: \(value ? "true" : "false")")
                                    } else {
                                        Text("Allow User Quit Deferrals: not set")
                                            .foregroundStyle(.secondary)
                                    }
                                    if let value = experience.allowedDeferrals {
                                        Text("Allowed Deferrals: \(value)")
                                    } else {
                                        Text("Allowed Deferrals: not set")
                                            .foregroundStyle(.secondary)
                                    }
                                    if let value = experience.allowedDeferralsUntilForcedSecondaryQuitButton {
                                        Text("Allowed Deferrals Until Forced Secondary Quit: \(value)")
                                    } else {
                                        Text("Allowed Deferrals Until Forced Secondary Quit: not set")
                                            .foregroundStyle(.secondary)
                                    }
                                    if let value = experience.calendarDeferralUnit {
                                        Text("Calendar Deferral Unit: \(value)")
                                    } else {
                                        Text("Calendar Deferral Unit: not set")
                                            .foregroundStyle(.secondary)
                                    }
                                    if let value = experience.approachingWindowTime {
                                        Text("Approaching Window Time (hrs): \(value)")
                                    } else {
                                        Text("Approaching Window Time (hrs): not set")
                                            .foregroundStyle(.secondary)
                                    }
                                    if let value = experience.imminentWindowTime {
                                        Text("Imminent Window Time (hrs): \(value)")
                                    } else {
                                        Text("Imminent Window Time (hrs): not set")
                                            .foregroundStyle(.secondary)
                                    }
                                    if let value = experience.nudgeMajorUpgradeEventLaunchDelay {
                                        Text("Major Upgrade Launch Delay (days): \(value)")
                                    } else {
                                        Text("Major Upgrade Launch Delay (days): not set")
                                            .foregroundStyle(.secondary)
                                    }
                                    if let value = experience.nudgeMinorUpdateEventLaunchDelay {
                                        Text("Minor Update Launch Delay (days): \(value)")
                                    } else {
                                        Text("Minor Update Launch Delay (days): not set")
                                            .foregroundStyle(.secondary)
                                    }
                                } else {
                                    Text("No userExperience deferral settings.")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
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
                            .font(.title2.weight(.semibold))
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

                    if !model.sofaError.isEmpty {
                        Text("SOFA warning: \(model.sofaError)")
                            .foregroundStyle(.red)
                            .font(.footnote)
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
                                if let list = majors.latest?.activelyExploitedList, !list.isEmpty {
                                    Text("List: \(list.joined(separator: ", "))")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Divider()
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Previous Major (\(majors.previous?.productVersion ?? "n/a"))")
                                    .font(.headline)
                                Text("Release Date: \(majors.previous?.releaseDate ?? "n/a")")
                                Text("Actively Exploited CVEs: \(majors.previous?.activelyExploitedCount ?? 0)")
                                if let list = majors.previous?.activelyExploitedList, !list.isEmpty {
                                    Text("List: \(list.joined(separator: ", "))")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
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
                        .font(.title2.weight(.semibold))
                        //.frame(maxWidth: .infinity, alignment: .center)
                    if model.selectedJSONPath.isEmpty {
                        Text("Select a JSON file to view requirement summaries.")
                            .foregroundStyle(.secondary)
                            .font(.footnote)
                    } else if model.isSOFAEnabled, let majors = model.sofaMajorDetails() {
                        HStack(alignment: .top, spacing: 16) {
                            if let latest = majors.latest {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Latest Major \(latest.major) (\(latest.productVersion))")
                                        .font(.headline)
                                    Text("Required Install By: \(latest.requiredInstallDate ?? "n/a")")
                                        .foregroundStyle(latest.highlight ? .red : .primary)
                                    Text("Nudge Launches On: \(latest.nudgeLaunchDate ?? "n/a")")
                                        .foregroundStyle(latest.highlight ? .red : .primary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            Divider()
                            if let previous = majors.previous {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Previous Major \(previous.major) (\(previous.productVersion))")
                                        .font(.headline)
                                    Text("Required Install By: \(previous.requiredInstallDate ?? "n/a")")
                                        .foregroundStyle(previous.highlight ? .red : .primary)
                                    Text("Nudge Launches On: \(previous.nudgeLaunchDate ?? "n/a")")
                                        .foregroundStyle(previous.highlight ? .red : .primary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    } else if let local = model.localRequirementSummary() {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Required Minimum OS: \(local.requiredMinimumOSVersion)")
                                .font(.headline)
                            Text("Required Install By: \(local.requiredInstallDate ?? "n/a")")
                                .foregroundStyle(local.highlight ? .red : .primary)
                            Text("Nudge Launches On: \(local.nudgeLaunchDate ?? "n/a")")
                                .foregroundStyle(local.highlight ? .red : .primary)
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
        .frame(minWidth: 700, minHeight: 520)
        .padding(24)
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button {
                    isShowingFileImporter = true
                } label: {
                    Label("Select JSON", systemImage: "folder")
                }
                .buttonStyle(.bordered)

                Button {
                    shouldLoadSelectionInBuilder = true
                    model.refreshSelectedJSON()
                    openWindow(id: "json-builder")
                } label: {
                    Label("Edit JSON", systemImage: "pencil")
                }
                .buttonStyle(.bordered)
                .disabled(model.selectedJSONPath.isEmpty)

                Button {
                    shouldLoadSelectionInBuilder = false
                    openWindow(id: "json-builder")
                } label: {
                    Label("New JSON", systemImage: "doc.badge.plus")
                }
                .buttonStyle(.bordered)
            }
            
            ToolbarItemGroup(placement: .status) {
                Button {
                    isShowingInfo = true
                } label: {
                    if !model.nudgeInstalled || model.isNudgeVersionMismatch {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.yellow)
                    } else {
                        Image(systemName: "info.circle")
                    }
                }
                .buttonStyle(.bordered)
                .tint((!model.nudgeInstalled || model.isNudgeVersionMismatch) ? .yellow : .accentColor)
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
                
                Button {
                    model.runCommand()
                } label: {
                    Label("Execute", systemImage: "play.fill")
                        .symbolRenderingMode(.monochrome)
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.bordered)
                .tint(.blue)
                .disabled(!model.nudgeInstalled || model.isExecuting || model.commandText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || model.selectedJSONPath.isEmpty)
                .opacity(!model.nudgeInstalled || model.isExecuting || model.commandText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || model.selectedJSONPath.isEmpty ? 0.5 : 1.0)
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
                model.appendLog("File selection failed: \(error.localizedDescription)")
            }
        }
                      .onAppear {
                          model.refreshNudgeInfo()
                          model.initializeDefaultsIfNeeded()
                          model.fetchLatestNudgeVersion()
                          model.fetchSOFAFeed()
                      }
    }
}
