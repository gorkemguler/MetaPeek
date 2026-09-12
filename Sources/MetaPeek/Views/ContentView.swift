import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject private var store: FileReportStore
    @State private var showFileImporter = false
    @State private var isTargeted = false

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            if let report = store.selectedReport {
                MetadataDetailView(report: report)
                    .id(report.id)
            } else {
                emptyDetailState
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    showFileImporter = true
                } label: {
                    Label(L10n.open, systemImage: "plus")
                }
                Button(role: .destructive) {
                    withAnimation { store.clearAll() }
                } label: {
                    Label(L10n.clear, systemImage: "trash")
                }
                .disabled(store.reports.isEmpty)
            }
        }
        .toolbarBackground(Theme.panel, for: .windowToolbar)
        .toolbarBackgroundVisibility(.visible, for: .windowToolbar)
        .task {
            if !LaunchFiles.initial.isEmpty {
                store.addFiles(LaunchFiles.initial)
                LaunchFiles.initial = []
            }
        }
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            handleDrop(providers: providers)
            return true
        }
        .overlay {
            if isTargeted {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Theme.accent, lineWidth: 3)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Theme.accent.opacity(0.06)))
                    .padding(8)
                    .allowsHitTesting(false)
            }
        }
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.item], allowsMultipleSelection: true) { result in
            if case .success(let urls) = result {
                store.addFiles(urls)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .metaPeekOpenFile)) { _ in
            showFileImporter = true
        }
    }

    private var emptyDetailState: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(Theme.accent.opacity(0.10)).frame(width: 64, height: 64)
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 24, weight: .regular))
                    .foregroundStyle(Theme.accent)
            }
            Text(L10n.selectFileTitle)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
            Text(L10n.selectFileSubtitle)
                .font(.callout)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.contentSurface)
    }

    private var sidebar: some View {
        List(store.reports, selection: $store.selectedReportID) { report in
            SidebarRow(report: report)
                .tag(report.id)
                .contextMenu {
                    Button(L10n.remove, role: .destructive) { store.remove(report) }
                }
        }
        .listStyle(.sidebar)
        .navigationTitle("MetaPeek")
        .overlay {
            if store.reports.isEmpty {
                emptySidebarState
            } else if store.isProcessing {
                VStack {
                    Spacer()
                    HStack(spacing: 6) {
                        ProgressView().controlSize(.small)
                        Text(L10n.processing).font(.caption).foregroundStyle(.secondary)
                    }
                }
                .padding(.bottom, 10)
            }
        }
    }

    private var emptySidebarState: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle().fill(Theme.accent.opacity(0.10)).frame(width: 52, height: 52)
                Image(systemName: "tray")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(Theme.accent)
            }
            Text(L10n.dropOrOpenTitle)
                .multilineTextAlignment(.center)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
            Text(L10n.dropOrOpenSubtitle)
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
    }

    private func handleDrop(providers: [NSItemProvider]) {
        for provider in providers {
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                guard let url else { return }
                Task { @MainActor in
                    withAnimation { store.addFiles([url]) }
                }
            }
        }
    }
}

private struct SidebarRow: View {
    let report: FileReport

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Theme.accent.opacity(0.14))
                    .frame(width: 30, height: 30)
                if let thumb = report.thumbnail {
                    Image(nsImage: thumb)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 30, height: 30)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                } else {
                    Text(badgeText)
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                }
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(report.url.lastPathComponent).lineLimit(1)
                Text(report.url.deletingLastPathComponent().path)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
    }

    private var badgeText: String {
        let ext = report.url.pathExtension.uppercased()
        return ext.isEmpty ? "?" : String(ext.prefix(4))
    }
}
