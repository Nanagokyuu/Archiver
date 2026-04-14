//
//  ExtractionState.swift
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

enum ExtractionState: Equatable {
    case idle
    case loading
    case ready
    case extracting(progress: Double, currentFile: String)
    case compressing(progress: Double, currentFile: String)
    case completed(outputPath: String)
    case compressCompleted(outputPath: String)
    case failed(error: String)

    var isProcessing: Bool {
        switch self {
        case .loading, .extracting, .compressing:
            return true
        default:
            return false
        }
    }
}

struct ArchiveInfo {
    let fileName: String
    let filePath: URL
    let format: ArchiveFormat
    let totalSize: UInt64
    let compressedSize: UInt64
    let fileCount: Int
    let directoryCount: Int

    var compressionRatio: Double {
        guard totalSize > 0 else { return 0 }
        return 1.0 - Double(compressedSize) / Double(totalSize)
    }
}

enum ArchiveFormat: String, CaseIterable {
    case zip = "ZIP"
    case tar = "TAR"
    case tarGz = "TAR.GZ"
    case tarBz2 = "TAR.BZ2"
    case tarXz = "TAR.XZ"
    case sevenZip = "7Z"
    case rar = "RAR"
    case gz = "GZ"
    case unknown = "Unknown"

    var icon: String {
        switch self {
        case .zip: return "doc.zipper"
        case .tar, .tarGz, .tarBz2, .tarXz: return "shippingbox.fill"
        case .sevenZip: return "lock.doc.fill"
        case .rar: return "doc.badge.gearshape.fill"
        case .gz: return "doc.badge.arrow.down.fill"
        case .unknown: return "questionmark.folder.fill"
        }
    }

    nonisolated static func detect(from url: URL) -> ArchiveFormat {
        let ext = url.pathExtension.lowercased()
        let name = url.lastPathComponent.lowercased()

        if name.hasSuffix(".tar.gz") || name.hasSuffix(".tgz") { return .tarGz }
        if name.hasSuffix(".tar.bz2") || name.hasSuffix(".tbz2") { return .tarBz2 }
        if name.hasSuffix(".tar.xz") || name.hasSuffix(".txz") { return .tarXz }

        switch ext {
        case "zip": return .zip
        case "tar": return .tar
        case "7z": return .sevenZip
        case "rar": return .rar
        case "gz": return .gz
        default: return .unknown
        }
    }
}
