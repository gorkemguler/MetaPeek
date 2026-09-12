import Foundation

enum ProcessRunner {
    static func findExecutable(_ name: String) -> String? {
        let candidates = [
            "/opt/homebrew/bin/\(name)",
            "/usr/local/bin/\(name)",
            "/usr/bin/\(name)",
            "/bin/\(name)",
            "/usr/sbin/\(name)",
            "/sbin/\(name)",
        ]
        return candidates.first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    /// Reads stdout to EOF before reading stderr — safe here because every caller
    /// invokes short-lived inspection tools (file, otool, codesign, tar -t, exiftool)
    /// whose stderr stays well under the pipe buffer size.
    static func run(_ executable: String, _ args: [String]) -> (stdout: String, stderr: String)? {
        guard FileManager.default.isExecutableFile(atPath: executable) else { return nil }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = args
        let outPipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errPipe

        do {
            try process.run()
        } catch {
            return nil
        }

        let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        let errData = errPipe.fileHandleForReading.readDataToEndOfFile()

        return (
            String(data: outData, encoding: .utf8) ?? "",
            String(data: errData, encoding: .utf8) ?? ""
        )
    }

    static func combinedOutput(_ executable: String, _ args: [String]) -> String? {
        guard let result = run(executable, args) else { return nil }
        return [result.stdout, result.stderr]
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }
}
