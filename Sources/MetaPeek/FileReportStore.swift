import Foundation
import SwiftUI

@MainActor
final class FileReportStore: ObservableObject {
    @Published var reports: [FileReport] = []
    @Published var selectedReportID: FileReport.ID?
    @Published var isProcessing = false

    var selectedReport: FileReport? {
        reports.first { $0.id == selectedReportID }
    }

    func addFiles(_ urls: [URL]) {
        guard !urls.isEmpty else { return }
        isProcessing = true
        Task {
            for url in urls {
                let report = await Task.detached(priority: .userInitiated) {
                    await MetadataService.buildReport(for: url)
                }.value
                reports.append(report)
                if selectedReportID == nil { selectedReportID = report.id }
            }
            isProcessing = false
        }
    }

    func remove(_ report: FileReport) {
        reports.removeAll { $0.id == report.id }
        if selectedReportID == report.id { selectedReportID = reports.first?.id }
    }

    func clearAll() {
        reports.removeAll()
        selectedReportID = nil
    }
}
