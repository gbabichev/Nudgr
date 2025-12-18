import SwiftUI
import AppKit

struct NudgeInfoSheet: View {
    @ObservedObject var model: NudgeViewModel
    @Binding var isShowingInfo: Bool
    @State private var showCopyToast: Bool = false
    @State private var toastMessage: String = "Copied to clipboard"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // Title & Version
            Text("Nudge Info")
                .font(.title2.weight(.semibold))
            
            Text("Nudge Local Status")
                .bold()
            
            Text("Installed: \(model.nudgeInstalled ? "Yes" : "No")")
            Text("Version: \(model.nudgeInstalled ? model.nudgeVersion : "n/a")")
            Text("Path: \(model.nudgeInstalled ? model.nudgePath : "n/a")")
            
            // GitHub data
            Divider()
            
            Text("Latest Release on GitHub")
                .bold()
            
            HStack(spacing: 8) {
                Text(model.latestNudgeVersion)
                if model.isFetchingLatestNudge {
                    ProgressView().controlSize(.small)
                }
            }
            if !model.latestNudgeError.isEmpty {
                Text("Latest fetch error: \(model.latestNudgeError)")
                    .foregroundStyle(.red)
                    .font(.footnote)
            }
            
            // Action Buttons
            Divider()
            
            Text("Actions")
                .bold()
            // Refresh install & GH Version
            HStack {
                
                Button {
                    model.refreshNudgeInfo()
                } label: {
                    Label("Refresh Install Status", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                
                
                Button {
                    model.fetchLatestNudgeVersion()
                } label: {
                    Label("Refresh GitHub Version", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
            }
            
            // Copy Install & Uninstall cmd
            HStack {
                
                Button {
                    Task {
                        do {
                            let cmd = try await model.ensureSuiteURLAndInstallerCommand()
                            model.latestSuiteURL = cmd
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(cmd, forType: .string)
                            triggerToast("Copied install command")
                        } catch {
                            model.latestSuiteError = error.localizedDescription
                        }
                    }
                } label: {
                    Label("Copy Install Command", systemImage: "terminal")
                }
                .buttonStyle(.bordered)
                
                Button {
                    let cmd = model.buildUninstallCommand()
                    model.latestSuiteURL = cmd
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(cmd, forType: .string)
                    triggerToast("Copied uninstall command")
                } label: {
                    Label("Copy Uninstall Command", systemImage: "trash")
                }
                .buttonStyle(.bordered)
                
            }
            
            Divider()
            
            Text("Logging")
                .bold()
            // Logging Info
            Link("Nudge logging documentation", destination: URL(string: "https://github.com/macadmins/nudge/wiki/Logging")!)
                .font(.footnote)
            
            HStack(spacing: 8) {
                Button("Default Logging") {
                    let cmd = #"log stream --predicate 'subsystem == "com.github.macadmins.Nudge"' --style syslog --color none"#
                    model.commandText = cmd
                    model.latestSuiteURL = cmd
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(cmd, forType: .string)
                    triggerToast("Copied logging command")
                }
                .buttonStyle(.bordered)
                
                Button("More Logging") {
                    let cmd = #"log stream --predicate 'subsystem == "com.github.macadmins.Nudge"' --info --style syslog --color none"#
                    model.commandText = cmd
                    model.latestSuiteURL = cmd
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(cmd, forType: .string)
                    triggerToast("Copied logging command")
                }
                .buttonStyle(.bordered)
                
                Button("JSON Logging") {
                    let cmd = #"log show --predicate 'subsystem == "com.github.macadmins.Nudge"' --info --style json --debug"#
                    model.commandText = cmd
                    model.latestSuiteURL = cmd
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(cmd, forType: .string)
                    triggerToast("Copied logging command")
                }
                .buttonStyle(.bordered)
                
            }

Divider()

            // Command Line Text Box
            TextField("Terminal Commands Shown Here", text: $model.latestSuiteURL)
                .textFieldStyle(.roundedBorder)
            
//            if !model.latestSuiteError.isEmpty {
//                Text("Suite fetch error: \(model.latestSuiteError)")
//                    .foregroundStyle(.red)
//                    .font(.footnote)
//            }
            

            
            Divider()
            
            Button("Close") {
                isShowingInfo = false
            }
            .padding(.top, 8)
        }
        .padding()
        .frame(minWidth: 320)
        .onAppear {
            model.refreshNudgeInfo()
            model.fetchLatestNudgeVersion()
        }
        .overlay(alignment: .top) {
            if showCopyToast {
                Text(toastMessage)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.75))
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                    .transition(.opacity)
                    .padding(.top, 8)
            }
        }
    }
    
    private func triggerToast(_ message: String) {
        toastMessage = message
        withAnimation {
            showCopyToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showCopyToast = false
            }
        }
    }
}
