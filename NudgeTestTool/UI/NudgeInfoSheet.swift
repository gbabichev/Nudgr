import SwiftUI
import AppKit

struct NudgeInfoSheet: View {
    @ObservedObject var model: NudgeViewModel
    @Binding var isShowingInfo: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nudge Status")
                .font(.title2.weight(.semibold))
            Text("Installed: \(model.nudgeInstalled ? "Yes" : "No")")
            Text("Version: \(model.nudgeInstalled ? model.nudgeVersion : "n/a")")
            Text("Path: \(model.nudgeInstalled ? model.nudgePath : "n/a")")
            HStack(spacing: 8) {
                Text("Latest available: \(model.latestNudgeVersion)")
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
                TextField("Latest Nudge_Suite pkg URL", text: $model.latestSuiteURL)
                    .textFieldStyle(.roundedBorder)
                    .disabled(true)
                HStack {
                    Button {
                        model.fetchLatestSuiteURL()
                    } label: {
                        Label("Get Nudge_Suite pkg", systemImage: "arrow.down.circle")
                    }
                    .buttonStyle(.bordered)
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(model.latestSuiteURL, forType: .string)
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.bordered)
                    .disabled(model.latestSuiteURL.isEmpty)
                }
                if !model.latestSuiteError.isEmpty {
                    Text("Suite fetch error: \(model.latestSuiteError)")
                        .foregroundStyle(.red)
                        .font(.footnote)
                }
            }

            HStack {
                Button {
                    model.refreshNudgeInfo()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)

                Button {
                    model.fetchLatestNudgeVersion()
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
                Text(model.nudgeDetectionLog.isEmpty ? "No log recorded." : model.nudgeDetectionLog)
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
            model.refreshNudgeInfo()
            model.fetchLatestNudgeVersion()
        }
    }
}
