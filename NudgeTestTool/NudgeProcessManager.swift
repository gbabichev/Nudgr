import AppKit
import Foundation

actor NudgeProcessManager {
    static let shared = NudgeProcessManager()

    func killNudge() async -> (output: String, error: String) {
        var lines: [String] = []

        let apps = NSRunningApplication.runningApplications(withBundleIdentifier: "com.github.macadmins.Nudge")
        if apps.isEmpty {
            // Fallback: try matching the binary path via pkill to handle renamed bundles.
            let fallback = await ShellExecutor.shared.run(command: #"pkill -f "/Applications/Utilities/Nudge\.app/Contents/MacOS/Nudge" || pkill -9 -f "/Applications/Utilities/Nudge\.app/Contents/MacOS/Nudge""#)
            if fallback.output.isEmpty && fallback.error.isEmpty {
                return ("No running Nudge app found.", "")
            }
            return (fallback.output, fallback.error)
        }

        for app in apps {
            let pid = app.processIdentifier
            let terminated = app.terminate()
            lines.append("Terminate requested for pid \(pid) \(terminated ? "" : "(request may have failed)")")
        }

        try? await Task.sleep(nanoseconds: 300_000_000)

        let stillRunning = NSRunningApplication.runningApplications(withBundleIdentifier: "com.github.macadmins.Nudge")
        for app in stillRunning where !app.isTerminated {
            let pid = app.processIdentifier
            let forced = app.forceTerminate()
            lines.append("Force terminate for pid \(pid) \(forced ? "" : "(force may have failed)")")
        }

        if lines.isEmpty {
            return ("No running Nudge app found.", "")
        } else {
            return (lines.joined(separator: "\n"), "")
        }
    }
}
