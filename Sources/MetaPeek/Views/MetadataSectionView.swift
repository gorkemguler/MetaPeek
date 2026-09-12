import AppKit
import SwiftUI

struct MetadataSectionView: View {
    let section: MetadataSection
    @State private var isExpanded = true

    private var iconName: String { Theme.icon(for: section.title) }

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.15)) { isExpanded.toggle() }
            } label: {
                header
            }
            .buttonStyle(.plain)

            if isExpanded {
                if section.title == "Entropy", let field = section.fields.first, let value = Double(field.value.split(separator: " ").first ?? "") {
                    EntropyGaugeView(value: value)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 14)
                } else {
                    VStack(spacing: 0) {
                        ForEach(section.fields) { field in
                            FieldRow(field: field)
                            if field.id != section.fields.last?.id {
                                Divider()
                            }
                        }
                    }
                    .padding(.bottom, 6)
                }
            }
        }
        .background(Theme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(Theme.stroke))
        .shadow(color: Theme.cardShadow, radius: 6, x: 0, y: 2)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 20)
            Text(section.title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)
            Text("\(section.fields.count)")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.tertiary)
                .rotationEffect(.degrees(isExpanded ? 90 : 0))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .contentShape(Rectangle())
    }
}

private struct FieldRow: View {
    let field: MetadataField
    @State private var isHovering = false
    @State private var didCopy = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(field.key)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 200, alignment: .leading)
            Text(field.value)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.primary)
                .textSelection(.enabled)
            Spacer(minLength: 8)
            if isHovering {
                Button {
                    copy()
                } label: {
                    Image(systemName: didCopy ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 11))
                        .foregroundStyle(didCopy ? Theme.safe : .secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(isHovering ? Color.primary.opacity(0.03) : .clear)
        .onHover { isHovering = $0 }
    }

    private func copy() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(field.value, forType: .string)
        didCopy = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { didCopy = false }
    }
}

private struct EntropyGaugeView: View {
    let value: Double

    private var fraction: Double { min(max(value / 8, 0), 1) }
    private var color: Color { Theme.entropyColor(value) }
    private var label: String {
        switch value {
        case ..<5: return L10n.entropyLow
        case 5..<7.2: return L10n.entropyMedium
        default: return L10n.entropyHigh
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(format: "%.2f / 8.0", value))
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(color)
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.primary.opacity(0.08))
                    Capsule()
                        .fill(color)
                        .frame(width: proxy.size.width * fraction)
                }
            }
            .frame(height: 6)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
