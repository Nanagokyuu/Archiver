//
//  ArchiveItem.swift
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

import Foundation
import UniformTypeIdentifiers

struct ArchiveItem: Identifiable, Hashable {
    let id = UUID()
    let path: String
    let fileName: String
    let fileExtension: String
    let size: UInt64
    let compressedSize: UInt64
    let isDirectory: Bool
    let modificationDate: Date?
    let depth: Int

    var icon: String {
        if isDirectory {
            return "folder.fill"
        }
        switch fileExtension.lowercased() {
        case "jpg", "jpeg", "png", "gif", "bmp", "tiff", "webp", "heic":
            return "photo.fill"
        case "mp4", "mov", "avi", "mkv", "wmv":
            return "film.fill"
        case "mp3", "aac", "wav", "flac", "m4a":
            return "music.note"
        case "pdf":
            return "doc.richtext.fill"
        case "doc", "docx", "txt", "rtf", "md":
            return "doc.text.fill"
        case "xls", "xlsx", "csv":
            return "tablecells.fill"
        case "swift", "py", "js", "ts", "java", "c", "cpp", "h", "rb", "go", "rs":
            return "chevron.left.forwardslash.chevron.right"
        case "html", "css", "xml", "json", "yaml", "yml":
            return "globe"
        case "zip", "rar", "7z", "tar", "gz", "bz2", "xz":
            return "doc.zipper"
        case "app", "exe", "dmg", "pkg":
            return "app.fill"
        default:
            return "doc.fill"
        }
    }

    var iconColor: Color {
        if isDirectory { return .blue }
        switch fileExtension.lowercased() {
        case "jpg", "jpeg", "png", "gif", "bmp", "tiff", "webp", "heic":
            return .green
        case "mp4", "mov", "avi", "mkv":
            return .purple
        case "mp3", "aac", "wav", "flac":
            return .pink
        case "pdf":
            return .red
        case "swift":
            return .orange
        case "py":
            return .yellow
        case "js", "ts":
            return .yellow
        case "zip", "rar", "7z", "tar", "gz":
            return .indigo
        default:
            return .secondary
        }
    }

    var compressionRatio: Double {
        guard size > 0 else { return 0 }
        return 1.0 - Double(compressedSize) / Double(size)
    }
}

import SwiftUI

extension ArchiveItem {
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }

    var formattedCompressedSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(compressedSize), countStyle: .file)
    }
}
