import Foundation
import UniformTypeIdentifiers

struct MachOExtractor: MetadataExtractor {
    private static let machoMagics: Set<[UInt8]> = [
        [0xFE, 0xED, 0xFA, 0xCE], [0xCE, 0xFA, 0xED, 0xFE],
        [0xFE, 0xED, 0xFA, 0xCF], [0xCF, 0xFA, 0xED, 0xFE],
        [0xCA, 0xFE, 0xBA, 0xBE], [0xBE, 0xBA, 0xFE, 0xCA],
    ]
    private static let elfMagic: [UInt8] = [0x7F, 0x45, 0x4C, 0x46]
    private static let peMagic: [UInt8] = [0x4D, 0x5A]

    func canHandle(url: URL, uti: UTType?) -> Bool {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return false }
        defer { try? handle.close() }
        let prefix = [UInt8](handle.readData(ofLength: 4))
        if Self.machoMagics.contains(prefix) { return true }
        if prefix.starts(with: Self.elfMagic) { return true }
        if prefix.starts(with: Self.peMagic) { return true }
        return FileManager.default.isExecutableFile(atPath: url.path) && !url.hasDirectoryPath
    }

    func extract(url: URL) -> [MetadataSection] {
        var sections: [MetadataSection] = []

        if let lipoBin = ProcessRunner.findExecutable("lipo"),
           let out = ProcessRunner.combinedOutput(lipoBin, ["-info", url.path])?.trimmingCharacters(in: .whitespacesAndNewlines),
           !out.isEmpty {
            sections.append(MetadataSection(title: "Architectures", fields: [
                MetadataField(key: "lipo -info", value: out),
            ]))
        }

        if let otoolBin = ProcessRunner.findExecutable("otool"),
           let out = ProcessRunner.combinedOutput(otoolBin, ["-L", url.path]), !out.isEmpty {
            let lines = out.split(separator: "\n").dropFirst().map { $0.trimmingCharacters(in: .whitespaces) }
            if !lines.isEmpty {
                let fields = lines.enumerated().map { MetadataField(key: "Linked Library \($0.offset + 1)", value: $0.element) }
                sections.append(MetadataSection(title: "Linked Libraries (otool -L)", fields: fields))
            }
        }

        if let codesignBin = ProcessRunner.findExecutable("codesign"),
           let out = ProcessRunner.combinedOutput(codesignBin, ["-dvvv", url.path]), !out.isEmpty {
            let fields = out.split(separator: "\n").map { line -> MetadataField in
                let parts = line.split(separator: "=", maxSplits: 1)
                if parts.count == 2 {
                    return MetadataField(key: String(parts[0]), value: String(parts[1]))
                }
                return MetadataField(key: "Info", value: String(line))
            }
            sections.append(MetadataSection(title: "Code Signature (codesign -dvvv)", fields: fields))
        }

        if let entitlementsBin = ProcessRunner.findExecutable("codesign"),
           let out = ProcessRunner.run(entitlementsBin, ["-d", "--entitlements", ":-", url.path])?.stdout,
           out.contains("<?xml") {
            sections.append(MetadataSection(title: "Entitlements", fields: [
                MetadataField(key: "Raw plist", value: out),
            ]))
        }

        return sections
    }
}
