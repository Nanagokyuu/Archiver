//
//  ArchiveService.swift
//  Unzip
//
//  Created by Nanagokyuu on 2026/4/13.
//

import Foundation
import ZIPFoundation

actor ArchiveService {

    // MARK: - Read Archive Contents

    func readContents(of url: URL) async throws -> [ArchiveItem] {
        let ext = ArchiveFormat.detect(from: url)

        switch ext {
        case .zip:
            return try readZipContents(at: url)
        case .tar, .tarGz, .tarBz2, .tarXz:
            return try readTarContents(at: url)
        default:
            // Fallback: try ZIP first, then tar
            if let items = try? readZipContents(at: url), !items.isEmpty {
                return items
            }
            return try readTarContents(at: url)
        }
    }

    // MARK: - ZIP Reading

    private func readZipContents(at url: URL) throws -> [ArchiveItem] {
        guard let archive = Archive(url: url, accessMode: .read) else {
            throw ArchiveError.cannotOpenArchive
        }

        return archive.compactMap { entry in
            let rawPath = entry.path
            // Re-decode path for CJK support: if the path contains replacement chars,
            // try re-interpreting from raw bytes with CJK encodings
            let path = decodeCJKPath(rawPath)
            let components = path.split(separator: "/")
            let isDirectory = entry.type == .directory
            let fileName = isDirectory
                ? String(components.last ?? Substring(path))
                : (path as NSString).lastPathComponent

            return ArchiveItem(
                path: path,
                fileName: fileName,
                fileExtension: (path as NSString).pathExtension,
                size: entry.uncompressedSize,
                compressedSize: entry.compressedSize,
                isDirectory: isDirectory,
                modificationDate: entry.fileAttributes[.modificationDate] as? Date,
                depth: components.count - (isDirectory ? 1 : 0)
            )
        }
    }

    /// Attempt to fix garbled filenames from ZIP entries.
    /// ZIPFoundation decodes non-UTF-8-flagged filenames as CP437, which garbles both
    /// UTF-8 content (e.g. Greek Λ, ×) and CJK-encoded content (e.g. GBK Chinese/Japanese).
    /// We reverse the CP437 decoding to recover the original bytes, then try the correct encoding.
    private func decodeCJKPath(_ path: String) -> String {
        // If path is pure ASCII, no encoding issue
        if path.allSatisfy({ $0.isASCII }) { return path }
        // If path already contains valid CJK / common Unicode chars and no CP437 artifacts, it's fine
        if path.unicodeScalars.contains(where: { isCJKScalar($0) })
            && !path.unicodeScalars.contains(where: { isCP437Artifact($0) }) {
            return path
        }

        // Re-encode back to CP437 to recover the original raw bytes
        let cp437 = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(
            CFStringEncoding(CFStringEncodings.dosLatinUS.rawValue)))
        guard let rawBytes = path.data(using: cp437) else { return path }

        // Try UTF-8 first — many modern tools write UTF-8 without setting the flag
        if let utf8Decoded = String(data: rawBytes, encoding: .utf8) {
            return utf8Decoded
        }

        // Then try CJK encodings on the raw bytes
        let cjkEncodings: [String.Encoding] = [
            .init(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue))),
            .init(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.big5.rawValue))),
            .shiftJIS,
            .japaneseEUC,
        ]
        for encoding in cjkEncodings {
            if let decoded = String(data: rawBytes, encoding: encoding),
               decoded.unicodeScalars.contains(where: { isCJKScalar($0) }) {
                return decoded
            }
        }
        return path
    }

    /// Characters typical of CP437 box-drawing / block elements that indicate garbled text
    private func isCP437Artifact(_ scalar: Unicode.Scalar) -> Bool {
        let v = scalar.value
        return (0x2500...0x257F).contains(v)  // Box Drawing
            || (0x2580...0x259F).contains(v)  // Block Elements
            || (0x25A0...0x25FF).contains(v)  // Geometric Shapes (partial)
    }

    private func isCJKScalar(_ scalar: Unicode.Scalar) -> Bool {
        let v = scalar.value
        // CJK Unified Ideographs + Extension A/B, Hiragana, Katakana, Hangul
        return (0x4E00...0x9FFF).contains(v)   // CJK Unified Ideographs
            || (0x3400...0x4DBF).contains(v)    // CJK Extension A
            || (0x20000...0x2A6DF).contains(v)  // CJK Extension B
            || (0x3040...0x309F).contains(v)    // Hiragana
            || (0x30A0...0x30FF).contains(v)    // Katakana
            || (0xAC00...0xD7AF).contains(v)    // Hangul Syllables
            || (0xF900...0xFAFF).contains(v)    // CJK Compatibility Ideographs
    }

    // MARK: - TAR Reading (via Process)

    private func readTarContents(at url: URL) throws -> [ArchiveItem] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
        process.arguments = ["-tvf", url.path]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = decodeStringWithFallback(data)

        return output.components(separatedBy: "\n").compactMap { line in
            parseTarLine(line)
        }
    }

    /// Decode data trying multiple encodings for CJK filename support
    private func decodeStringWithFallback(_ data: Data) -> String {
        let encodings: [String.Encoding] = [
            .utf8,
            .shiftJIS,           // Japanese (Shift_JIS)
            .japaneseEUC,        // Japanese (EUC-JP)
            .init(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue))),  // Chinese (GB18030)
            .init(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.big5.rawValue))),           // Chinese Traditional (Big5)
            .isoLatin1
        ]
        for encoding in encodings {
            if let str = String(data: data, encoding: encoding) {
                return str
            }
        }
        return String(data: data, encoding: .utf8) ?? ""
    }

    private func parseTarLine(_ line: String) -> ArchiveItem? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        // Typical tar -tv output: drwxr-xr-x  0 user group    0 Jan  1 00:00 path/
        let parts = trimmed.split(separator: " ", maxSplits: 8, omittingEmptySubsequences: true)
        guard parts.count >= 6 else { return nil }

        let permissions = String(parts[0])
        let isDirectory = permissions.hasPrefix("d")
        let sizeStr = parts.count > 4 ? String(parts[2]) : "0"
        let size = UInt64(sizeStr) ?? 0
        let path = String(parts.last ?? "")

        let components = path.split(separator: "/")
        let fileName = String(components.last ?? Substring(path))

        return ArchiveItem(
            path: path,
            fileName: fileName,
            fileExtension: URL(fileURLWithPath: path).pathExtension,
            size: size,
            compressedSize: size,
            isDirectory: isDirectory,
            modificationDate: nil,
            depth: components.count - (isDirectory ? 1 : 0)
        )
    }

    // MARK: - Extraction

    func extract(
        archiveURL: URL,
        to destination: URL,
        progressHandler: @escaping @Sendable (Double, String) -> Void
    ) async throws {
        let format = ArchiveFormat.detect(from: archiveURL)

        switch format {
        case .zip:
            try await extractZip(archiveURL: archiveURL, to: destination, progressHandler: progressHandler)
        default:
            try await extractWithTar(archiveURL: archiveURL, to: destination, progressHandler: progressHandler)
        }
    }

    private func extractZip(
        archiveURL: URL,
        to destination: URL,
        progressHandler: @escaping @Sendable (Double, String) -> Void
    ) async throws {
        guard let archive = Archive(url: archiveURL, accessMode: .read) else {
            throw ArchiveError.cannotOpenArchive
        }

        let entries = Array(archive)
        let totalEntries = entries.count
        var processedEntries = 0

        let fileManager = FileManager.default

        for entry in entries {
            let entryPath = decodeCJKPath(entry.path)
            let fullPath = destination.appendingPathComponent(entryPath)

            if entry.type == .directory {
                try fileManager.createDirectory(at: fullPath, withIntermediateDirectories: true)
            } else {
                let parentDir = fullPath.deletingLastPathComponent()
                if !fileManager.fileExists(atPath: parentDir.path) {
                    try fileManager.createDirectory(at: parentDir, withIntermediateDirectories: true)
                }
                _ = try archive.extract(entry, to: fullPath)
            }

            processedEntries += 1
            let progress = Double(processedEntries) / Double(totalEntries)
            progressHandler(progress, entryPath)
        }
    }

    private func extractWithTar(
        archiveURL: URL,
        to destination: URL,
        progressHandler: @escaping @Sendable (Double, String) -> Void
    ) async throws {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: destination.path) {
            try fileManager.createDirectory(at: destination, withIntermediateDirectories: true)
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
        process.arguments = ["-xvf", archiveURL.path, "-C", destination.path]
        process.currentDirectoryURL = destination

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        try process.run()

        // Read output for progress
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        let files = output.components(separatedBy: "\n").filter { !$0.isEmpty }
        let total = max(files.count, 1)

        for (index, file) in files.enumerated() {
            let progress = Double(index + 1) / Double(total)
            progressHandler(progress, file)
        }

        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw ArchiveError.extractionFailed("tar exited with code \(process.terminationStatus)")
        }
    }

    // MARK: - Compression

    func compress(
        files: [URL],
        to destination: URL,
        progressHandler: @escaping @Sendable (Double, String) -> Void
    ) async throws {
        guard let archive = Archive(url: destination, accessMode: .create) else {
            throw ArchiveError.cannotCreateArchive
        }

        let allFiles = try collectFiles(from: files)
        let totalFiles = allFiles.count
        guard totalFiles > 0 else { throw ArchiveError.noFilesToCompress }

        // Determine the common base directory for relative paths
        let baseURL: URL
        if files.count == 1, files[0].hasDirectoryPath {
            baseURL = files[0]
        } else {
            baseURL = files[0].deletingLastPathComponent()
        }

        for (index, fileURL) in allFiles.enumerated() {
            let relativePath = fileURL.path.replacingOccurrences(of: baseURL.path + "/", with: "")

            var isDir: ObjCBool = false
            FileManager.default.fileExists(atPath: fileURL.path, isDirectory: &isDir)

            if isDir.boolValue {
                try archive.addEntry(
                    with: relativePath + "/",
                    type: .directory,
                    uncompressedSize: 0,
                    compressionMethod: .none,
                    provider: { (position: Int64, size: Int) -> Data in
                        return Data()
                    }
                )
            } else {
                try archive.addEntry(
                    with: relativePath,
                    fileURL: fileURL,
                    compressionMethod: .deflate
                )
            }

            let progress = Double(index + 1) / Double(totalFiles)
            progressHandler(progress, relativePath)
        }
    }

    private func collectFiles(from urls: [URL]) throws -> [URL] {
        let fileManager = FileManager.default
        var result: [URL] = []

        for url in urls {
            var isDir: ObjCBool = false
            guard fileManager.fileExists(atPath: url.path, isDirectory: &isDir) else { continue }

            if isDir.boolValue {
                if let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: nil) {
                    for case let fileURL as URL in enumerator {
                        result.append(fileURL)
                    }
                }
            } else {
                result.append(url)
            }
        }
        return result
    }
}

enum ArchiveError: LocalizedError {
    case cannotOpenArchive
    case cannotCreateArchive
    case unsupportedFormat
    case extractionFailed(String)
    case noFilesToCompress
    case cancelled

    var errorDescription: String? {
        switch self {
        case .cannotOpenArchive:
            return "Cannot open the archive file."
        case .cannotCreateArchive:
            return "Cannot create the archive file."
        case .unsupportedFormat:
            return "The archive format is not supported."
        case .extractionFailed(let msg):
            return "Extraction failed: \(msg)"
        case .noFilesToCompress:
            return "No files to compress."
        case .cancelled:
            return "Operation was cancelled."
        }
    }
}
