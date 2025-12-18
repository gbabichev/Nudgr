import SwiftUI
import AppKit

struct NudgeInfoSheet: View {
    @ObservedObject var model: NudgeViewModel
    @Binding var isShowingInfo: Bool
    @State private var showCopyToast: Bool = false
    @State private var toastMessage: String = "Copied to clipboard"

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nudge Status")
                .font(.title2.weight(.semibold))
            Text("Installed: \(model.nudgeInstalled ? "Yes" : "No")")
            Text("Version: \(model.nudgeInstalled ? model.nudgeVersion : "n/a")")
            Text("Path: \(model.nudgeInstalled ? model.nudgePath : "n/a")")
            if model.nudgeInstalled {
                Button {
                    let cmd = model.buildUninstallCommand()
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(cmd, forType: .string)
                    triggerToast("Copied uninstall command")
                } label: {
                    Label("Copy Uninstall Command", systemImage: "trash")
                }
                .buttonStyle(.bordered)
            }
            
            Button {
                model.refreshNudgeInfo()
            } label: {
                Label("Refresh Install Status", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            
            Divider()
            
            Text("Latest Release on GitHub")
            
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

            VStack(alignment: .leading, spacing: 4) {
                TextField("", text: $model.latestSuiteURL)
                    .textFieldStyle(.roundedBorder)
                    .disabled(true)
                HStack {
                    Button {
                        model.fetchLatestSuiteURL()
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(model.latestSuiteURL, forType: .string)
                        triggerToast("Copied to clipboard")
                    } label: {
                        Label("Get Nudge_Suite pkg", systemImage: "arrow.down.circle")
                    }
                    .buttonStyle(.bordered)
                    
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
                }
                if !model.latestSuiteError.isEmpty {
                    Text("Suite fetch error: \(model.latestSuiteError)")
                        .foregroundStyle(.red)
                        .font(.footnote)
                }
            }

            HStack {


                Button {
                    model.fetchLatestNudgeVersion()
                } label: {
                    Label("Check latest", systemImage: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(.bordered)

                Spacer()
            }

//            Divider().padding(.vertical, 4)
//            Text("Detection log")
//                .font(.headline)
//            ScrollView {
//                Text(model.nudgeDetectionLog.isEmpty ? "No log recorded." : model.nudgeDetectionLog)
//                    .font(.system(.footnote, design: .monospaced))
//                    .frame(maxWidth: .infinity, alignment: .leading)
//            }
//            .frame(maxHeight: 180)

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
