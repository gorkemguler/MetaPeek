import SwiftUI

enum Theme {
    /// Single, deliberate brand color — used sparingly for the odd highlight
    /// (selection, links, primary buttons), not as decoration.
    static let accent = Color(red: 0.28, green: 0.45, blue: 0.82)

    static let danger = Color(red: 0.86, green: 0.32, blue: 0.30)
    static let warning = Color(red: 0.80, green: 0.58, blue: 0.16)
    static let safe = Color(red: 0.27, green: 0.62, blue: 0.42)

    /// Card surface that follows the system's light/dark appearance.
    static let panel = Color(nsColor: .controlBackgroundColor)
    static let stroke = Color(nsColor: .separatorColor)

    /// Sidebar and main content deliberately share one flat surface family —
    /// underPageBackground/windowBackground are Apple's own paired tokens for
    /// exactly this split, so the two panes read as one window, not two.
    static let sidebarSurface = Color(nsColor: .underPageBackgroundColor)
    static let contentSurface = Color(nsColor: .windowBackgroundColor)

    static let cardShadow = Color.black.opacity(0.18)

    /// All section headers share one neutral icon so the metadata list reads
    /// calmly; only the entropy gauge (a real risk signal) uses color.
    static func icon(for sectionTitle: String) -> String {
        let rules: [(prefix: String, icon: String)] = [
            ("General", "doc.text"),
            ("Signature", "checkmark.seal"),
            ("Hashes", "number"),
            ("Entropy", "waveform.path.ecg"),
            ("Printable Strings", "textformat"),
            ("file(1) Classification", "terminal"),
            ("GPS", "location"),
            ("Image", "photo"),
            ("EXIF", "camera"),
            ("TIFF", "camera"),
            ("IPTC", "camera"),
            ("PNG", "camera"),
            ("JFIF", "camera"),
            ("GIF", "camera"),
            ("HEIC", "camera"),
            ("PDF", "doc.richtext"),
            ("Core Properties", "doc.badge.gearshape"),
            ("Application Properties", "doc.badge.gearshape"),
            ("Custom Properties", "doc.badge.gearshape"),
            ("OpenDocument Metadata", "doc.badge.gearshape"),
            ("Archive Contents", "archivebox"),
            ("Media", "waveform"),
            ("Embedded Metadata", "waveform"),
            ("Architectures", "cpu"),
            ("Linked Libraries", "cpu"),
            ("Code Signature", "cpu"),
            ("Entitlements", "cpu"),
            ("Binary Type", "cpu"),
            ("ExifTool", "wand.and.stars"),
        ]
        return rules.first(where: { sectionTitle.hasPrefix($0.prefix) })?.icon ?? "info.circle"
    }

    static func entropyColor(_ value: Double) -> Color {
        switch value {
        case ..<5: return safe
        case 5..<7.2: return warning
        default: return danger
        }
    }
}
