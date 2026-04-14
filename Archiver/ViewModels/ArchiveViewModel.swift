//
//  ArchiveViewModel.swift
//
//  Created by Nanagokyuu on 2026/4/13.
//
//  Copyright © 2026 Nanagokyuu. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
//

import SwiftUI
import UniformTypeIdentifiers

@MainActor
@Observable
class ArchiveViewModel {
    var state: ExtractionState = .idle
    var archiveInfo: ArchiveInfo?
    var items: [ArchiveItem] = []
    var selectedItems: Set<ArchiveItem.ID> = []
    var searchText: String = ""
    var sortOrder: SortOrder = .name
    var showHiddenFiles: Bool = false
    var recentArchives: [URL] = []

    private let service = ArchiveService()
    private var currentArchiveURL: URL?

    enum SortOrder: String, CaseIterable {
        case name = "Name"
        case size = "Size"
        case type = "Type"
        case date = "Date"
    }

    var filteredItems: [ArchiveItem] {
        var result = items

        if !searchText.isEmpty {
            result = result.filter {
                $0.fileName.localizedCaseInsensitiveContains(searchText)
                || $0.path.localizedCaseInsensitiveContains(searchText)
            }
        }

        if !showHiddenFiles {
            result = result.filter { !$0.fileName.hasPrefix(".") }
        }

        switch sortOrder {
        case .name:
            result.sort { $0.fileName.localizedCompare($1.fileName) == .orderedAscending }
        case .size:
            result.sort { $0.size > $1.size }
        case .type:
            result.sort { $0.fileExtension < $1.fileExtension }
        case .date:
            result.sort { ($0.modificationDate ?? .distantPast) > ($1.modificationDate ?? .distantPast) }
        }

        return result
    }

    var totalFiles: Int { items.filter { !$0.isDirectory }.count }
    var totalFolders: Int { items.filter { $0.isDirectory }.count }
    var totalSize: UInt64 { items.reduce(0) { $0 + $1.size } }
    var totalCompressedSize: UInt64 { items.reduce(0) { $0 + $1.compressedSize } }

    // MARK: - File Open

    func openFilePicker() {
        let panel = NSOpenPanel()
        panel.title = "Select Archive"
        panel.allowedContentTypes = [
            UTType(filenameExtension: "zip")!,
            UTType(filenameExtension: "tar")!,
            UTType(filenameExtension: "gz")!,
            UTType(filenameExtension: "bz2")!,
            UTType(filenameExtension: "xz")!,
            UTType(filenameExtension: "7z")!,
            UTType(filenameExtension: "rar")!,
            UTType(filenameExtension: "tgz")!,
        ]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        if panel.runModal() == .OK, let url = panel.url {
            loadArchive(url: url)
        }
    }

    func loadArchive(url: URL) {
        currentArchiveURL = url
        state = .loading
        items = []
        selectedItems = []

        Task {
            do {
                let entries = try await service.readContents(of: url)
                self.items = entries

                let format = ArchiveFormat.detect(from: url)
                let fileAttrs = try? FileManager.default.attributesOfItem(atPath: url.path)
                let fileSize = fileAttrs?[.size] as? UInt64 ?? 0

                self.archiveInfo = ArchiveInfo(
                    fileName: url.lastPathComponent,
                    filePath: url,
                    format: format,
                    totalSize: entries.reduce(0) { $0 + $1.size },
                    compressedSize: fileSize,
                    fileCount: entries.filter { !$0.isDirectory }.count,
                    directoryCount: entries.filter { $0.isDirectory }.count
                )

                if !recentArchives.contains(url) {
                    recentArchives.insert(url, at: 0)
                    if recentArchives.count > 10 {
                        recentArchives = Array(recentArchives.prefix(10))
                    }
                }

                state = .ready
            } catch {
                state = .failed(error: error.localizedDescription)
            }
        }
    }

    // MARK: - Extract

    func extractAll() {
        guard let archiveURL = currentArchiveURL else { return }

        let panel = NSOpenPanel()
        panel.title = "Choose Destination"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true

        guard panel.runModal() == .OK, let destination = panel.url else { return }

        state = .extracting(progress: 0, currentFile: "Preparing…")

        Task {
            do {
                // Additional 0.5% UI-layer throttle so rapid bursts from the service
                // don't saturate the main actor even if the service emits more updates.
                let uiThrottle = ProgressThrottle(threshold: 0.005)
                try await service.extract(archiveURL: archiveURL, to: destination) { progress, file in
                    if uiThrottle.shouldReport(progress) || progress >= 1.0 {
                        Task { @MainActor in
                            self.state = .extracting(progress: progress, currentFile: file)
                        }
                    }
                }
                state = .completed(outputPath: destination.path)
            } catch {
                state = .failed(error: error.localizedDescription)
            }
        }
    }

    // MARK: - Compress

    func compressFiles() {
        let panel = NSOpenPanel()
        panel.title = "Select Files to Compress"
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true

        guard panel.runModal() == .OK, !panel.urls.isEmpty else { return }
        let sourceURLs = panel.urls

        compressFiles(droppedURLs: sourceURLs)
    }

    /// Compress already-known URLs (e.g. from drag-and-drop). Skips the NSOpenPanel.
    func compressFiles(droppedURLs: [URL]) {
        let sourceURLs = droppedURLs

        let savePanel = NSSavePanel()
        savePanel.title = "Save Archive As"
        savePanel.allowedContentTypes = [.zip]
        savePanel.nameFieldStringValue = sourceURLs.count == 1
            ? (sourceURLs[0].deletingPathExtension().lastPathComponent + ".zip")
            : "Archive.zip"

        guard savePanel.runModal() == .OK, let destination = savePanel.url else { return }

        state = .compressing(progress: 0, currentFile: "Preparing…")

        Task {
            do {
                try await service.compress(files: sourceURLs, to: destination) { progress, file in
                    Task { @MainActor in
                        self.state = .compressing(progress: progress, currentFile: file)
                    }
                }
                state = .compressCompleted(outputPath: destination.path)
            } catch {
                state = .failed(error: error.localizedDescription)
            }
        }
    }

    func removeRecentArchive(_ url: URL) {
        recentArchives.removeAll { $0 == url }
    }

    func resetState() {
        state = .idle
        archiveInfo = nil
        items = []
        selectedItems = []
        searchText = ""
        currentArchiveURL = nil
    }
}
