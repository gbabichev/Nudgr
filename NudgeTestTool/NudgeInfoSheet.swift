import SwiftUI
import AppKit

struct NudgeInfoSheet: View {
    @Binding var isShowingInfo: Bool
    @Binding var nudgeInstalled: Bool
    @Binding var nudgeVersion: String
    @Binding var nudgePath: String
    @Binding var latestNudgeVersion: String
    @Binding var latestNudgeError: String
    @Binding var latestSuiteURL: String
    @Binding var latestSuiteError: String
    @Binding var detectionLog: String
    @Binding var isFetchingLatestNudge: Bool

    let onRefreshStatus: () -> Void
    let onFetchLatestVersion: () -> Void
    let onFetchSuiteURL: () -> Void

    var body: some View {
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
                        onFetchSuiteURL()
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
                    onRefreshStatus()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)

                Button {
                    onFetchLatestVersion()
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
                Text(detectionLog.isEmpty ? "No log recorded." : detectionLog)
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
            onRefreshStatus()
            onFetchLatestVersion()
        }
    }
}
