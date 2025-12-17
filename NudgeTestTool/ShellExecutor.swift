import Foundation

actor ShellExecutor {
    static let shared = ShellExecutor()

    func run(command: String) -> (output: String, error: String) {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/zsh")
        task.arguments = ["-lc", command]

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        task.standardOutput = outputPipe
        task.standardError = errorPipe

        do {
            try task.run()
            task.waitUntilExit()
        } catch {
            return ("", "Failed to start: \(error.localizedDescription)")
        }

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

        let outputString = String(data: outputData, encoding: .utf8) ?? ""
        var errorString = String(data: errorData, encoding: .utf8) ?? ""

        if task.terminationStatus != 0 && errorString.isEmpty {
            errorString = "Exited with code \(task.terminationStatus)"
        }

        return (outputString.trimmingCharacters(in: .whitespacesAndNewlines),
                errorString.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}
