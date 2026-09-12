import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct MetadataDetailView: View {
    let report: FileReport
    @State private var searchText = ""
    @State private var showExporter = false

    private var exportDocument: MetadataExportDocument {
        MetadataExportDocument(report: report)
    }

    private var filteredSections: [MetadataSection] {
        guard !searchText.isEmpty else { return report.sections }
        return report.sections.compactMap { section in
            let fields = section.fields.filter {
                $0.key.localizedCaseInsensitiveContains(searchText) || $0.value.localizedCaseInsensitiveContains(searchText)
            }
            return fields.isEmpty ? nil : MetadataSection(title: section.title, fields: fields)
        }
    }

    private var sha256: String? {
        report.sections.first(where: { $0.title == "Hashes" })?.fields.first(where: { $0.key == "SHA256" })?.value
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header
                if let coordinate = report.gpsCoordinate {
                    MapPreviewView(coordinate: coordinate)
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(Theme.stroke))
                }
                if searchText.isEmpty {
                    ForEach(report.imageAnalyses) { analysis in
                        ImageAnalysisView(analysis: analysis)
                    }
                }
                ForEach(filteredSections) { section in
                    MetadataSectionView(section: section)
                }
            }
            .padding(20)
            .frame(maxWidth: 820, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .background(Theme.contentSurface)
        .searchable(text: $searchText, placement: .toolbar, prompt: L10n.searchPlaceholder)
        .navigationTitle(report.url.lastPathComponent)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    copyAllToClipboard()
                } label: {
                    Label(L10n.copy, systemImage: "doc.on.doc")
                }
                Button {
                    showExporter = true
                } label: {
                    Label(L10n.exportJSON, systemImage: "square.and.arrow.up")
                }
            }
        }
        .fileExporter(
            isPresented: $showExporter,
            document: exportDocument,
            contentType: .json,
            defaultFilename: "\(report.url.deletingPathExtension().lastPathComponent)-metadata"
        ) { _ in }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Theme.accent.opacity(0.12))
                    .frame(width: 60, height: 60)
                if let thumb = report.thumbnail {
                    Image(nsImage: thumb)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                } else {
                    Text(report.url.pathExtension.uppercased())
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(report.url.lastPathComponent)
                    .font(.system(size: 17, weight: .semibold))
                Text(report.url.path)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .truncationMode(.middle)

                HStack(spacing: 8) {
                    if let sha256 {
                        chip(icon: "number", text: String(sha256.prefix(12)) + "…")
                    }
                    chip(icon: "square.stack.3d.up", text: L10n.sections(report.sections.count))
                }
                .padding(.top, 2)
            }
            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Theme.stroke))
        .shadow(color: Theme.cardShadow, radius: 8, x: 0, y: 3)
    }

    private func chip(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 9, weight: .semibold))
            Text(text).font(.system(size: 11, design: .monospaced))
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(Color.primary.opacity(0.06)))
    }

    private func copyAllToClipboard() {
        let text = report.sections.map { section in
            "## \(section.title)\n" + section.fields.map { "\($0.key): \($0.value)" }.joined(separator: "\n")
        }.joined(separator: "\n\n")
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}
