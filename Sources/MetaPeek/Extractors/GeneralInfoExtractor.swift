import Foundation
import UniformTypeIdentifiers

struct GeneralInfoExtractor: MetadataExtractor {
    func canHandle(url: URL, uti: UTType?) -> Bool { true }

    func extract(url: URL) -> [MetadataSection] {
        var sections: [MetadataSection] = []
        sections.append(MetadataSection(title: "General", fields: generalFields(url: url)))

        if let handle = try? FileHandle(forReadingFrom: url) {
            let prefix = handle.readData(ofLength: 64)
            try? handle.close()
            if let signature = FileSignature.detect(prefix: prefix) {
                sections.append(MetadataSection(title: "Signature", fields: [
                    MetadataField(key: "Detected Type", value: signature),
                ]))
            }
        }

        if let hashes = Hashing.hash(fileAt: url) {
            sections.append(MetadataSection(title: "Hashes", fields: [
                MetadataField(key: "MD5", value: hashes.md5),
                MetadataField(key: "SHA1", value: hashes.sha1),
                MetadataField(key: "SHA256", value: hashes.sha256),
            ]))
        }

        if let sample = try? readPrefix(url: url, maxBytes: 8 * 1024 * 1024), !sample.isEmpty {
            let entropy = Entropy.shannon(of: sample)
            let note = entropy > 7.5 ? " — high, possibly compressed/encrypted/packed" : ""
            sections.append(MetadataSection(title: "Entropy", fields: [
                MetadataField(key: "Shannon Entropy (0-8, sampled)", value: String(format: "%.3f%@", entropy, note)),
            ]))

            let strings = StringsExtractor.extract(from: sample.prefix(5 * 1024 * 1024))
            if !strings.isEmpty {
                let preview = strings.prefix(50).joined(separator: "\n")
                sections.append(MetadataSection(title: "Printable Strings (first \(min(50, strings.count)), min length 4)", fields: [
                    MetadataField(key: "Strings", value: preview),
                ]))
            }
        }

        if let fileBin = ProcessRunner.findExecutable("file"),
           let out = ProcessRunner.combinedOutput(fileBin, ["-b", url.path])?.trimmingCharacters(in: .whitespacesAndNewlines),
           !out.isEmpty {
            sections.append(MetadataSection(title: "file(1) Classification", fields: [
                MetadataField(key: "Description", value: out),
            ]))
        }

        return sections
    }

    private func generalFields(url: URL) -> [MetadataField] {
        var fields: [MetadataField] = []
        let fm = FileManager.default

        if let attrs = try? fm.attributesOfItem(atPath: url.path) {
            if let size = attrs[.size] as? NSNumber {
                let formatted = ByteCountFormatter.string(fromByteCount: size.int64Value, countStyle: .file)
                fields.append(MetadataField(key: "Size", value: "\(formatted) (\(size.int64Value) bytes)"))
            }
            if let created = attrs[.creationDate] as? Date {
                fields.append(MetadataField(key: "Created", value: DateFormatter.metaPeek.string(from: created)))
            }
            if let modified = attrs[.modificationDate] as? Date {
                fields.append(MetadataField(key: "Modified", value: DateFormatter.metaPeek.string(from: modified)))
            }
            if let posix = attrs[.posixPermissions] as? NSNumber {
                fields.append(MetadataField(key: "Permissions", value: String(posix.intValue, radix: 8)))
            }
            if let owner = attrs[.ownerAccountName] as? String {
                fields.append(MetadataField(key: "Owner", value: owner))
            }
        }

        if let uti = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType {
            fields.append(MetadataField(key: "Uniform Type", value: "\(uti.identifier)"))
        }

        fields.append(MetadataField(key: "Path", value: url.path))
        return fields
    }

    private func readPrefix(url: URL, maxBytes: Int) throws -> Data {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        return handle.readData(ofLength: maxBytes)
    }
}
