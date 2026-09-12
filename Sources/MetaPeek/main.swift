import Foundation
import SwiftUI

/// `--json` with one or more file paths: dump metadata as JSON to stdout and
/// exit, skipping the GUI (for Terminal / CTF-OSINT scripting).
/// Plain file paths with no flag: standard macOS "open with" convention —
/// launch the GUI with those files already loaded, matching double-click /
/// drag-onto-Dock-icon behavior.
let jsonMode = CommandLine.arguments.contains("--json")
let fileArguments = CommandLine.arguments.dropFirst().filter { !$0.hasPrefix("-") }

if jsonMode, !fileArguments.isEmpty {
    let semaphore = DispatchSemaphore(value: 0)
    Task {
        for path in fileArguments {
            let url = URL(fileURLWithPath: path)
            let report = await MetadataService.buildReport(for: url)
            let sections: [[String: Any]] = report.sections.map { section in
                var fields: [String: String] = [:]
                for field in section.fields { fields[field.key] = field.value }
                return ["title": section.title, "fields": fields]
            }
            let dict: [String: Any] = ["file": report.url.path, "sections": sections]
            if let data = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys]),
               let json = String(data: data, encoding: .utf8) {
                print(json)
            }
        }
        semaphore.signal()
    }
    semaphore.wait()
} else {
    LaunchFiles.initial = fileArguments.map { URL(fileURLWithPath: $0) }
    MetaPeekApp.main()
}
