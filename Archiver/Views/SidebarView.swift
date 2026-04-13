//
//  SidebarView.swift
//  Unzip
//
//  Created by Nanagokyuu on 2026/4/13.
//

import SwiftUI

struct SidebarView: View {
    @Environment(ArchiveViewModel.self) var viewModel

    var body: some View {
        List {
            if let info = viewModel.archiveInfo {
                // Archive Info Card
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 10) {
                            Image(systemName: info.format.icon)
                                .font(.title)
                                .foregroundStyle(.tint)
                                .frame(width: 40, height: 40)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.accentColor.opacity(0.12))
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(info.fileName)
                                    .font(.headline)
                                    .lineLimit(2)
                                Text(info.format.rawValue)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(.secondary.opacity(0.15)))
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                // Stats
                Section("Statistics") {
                    StatRow(icon: "doc.fill", label: "Files", value: "\(info.fileCount)")
                    StatRow(icon: "folder.fill", label: "Folders", value: "\(info.directoryCount)")
                    StatRow(icon: "arrow.up.left.and.arrow.down.right",
                            label: "Uncompressed",
                            value: ByteCountFormatter.string(fromByteCount: Int64(info.totalSize), countStyle: .file))
                    StatRow(icon: "arrow.down.right.and.arrow.up.left",
                            label: "Compressed",
                            value: ByteCountFormatter.string(fromByteCount: Int64(info.compressedSize), countStyle: .file))

                    // Compression ratio bar
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Compression")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(Int(info.compressionRatio * 100))%")
                                .font(.caption.bold())
                                .foregroundStyle(Color.accentColor)
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(.quaternary)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        LinearGradient(
                                            colors: [.green, .blue],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geo.size.width * info.compressionRatio)
                            }
                        }
                        .frame(height: 8)
                    }
                    .padding(.vertical, 4)
                }

                // File type breakdown
                Section("File Types") {
                    ForEach(topFileTypes, id: \.ext) { entry in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(entry.color)
                                .frame(width: 8, height: 8)
                            Text(entry.ext.isEmpty ? "No Extension" : ".\(entry.ext)")
                                .font(.callout)
                            Spacer()
                            Text("\(entry.count)")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Actions
                Section {
                    Button {
                        viewModel.extractAll()
                    } label: {
                        Label("Extract All…", systemImage: "arrow.down.to.line.compact")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Button(role: .destructive) {
                        viewModel.resetState()
                    } label: {
                        Label("Close Archive", systemImage: "xmark.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                }
            }
        }
        .listStyle(.sidebar)
    }

    struct FileTypeEntry {
        let ext: String
        let count: Int
        let color: Color
    }

    private var topFileTypes: [FileTypeEntry] {
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .red, .yellow, .indigo]
        let files = viewModel.items.filter { !$0.isDirectory }
        var dict: [String: Int] = [:]
        for file in files {
            dict[file.fileExtension.lowercased(), default: 0] += 1
        }

        let sorted = dict.sorted { $0.value > $1.value }.prefix(8)
        return sorted.enumerated().map { idx, entry in
            FileTypeEntry(ext: entry.key, count: entry.value, color: colors[idx % colors.count])
        }
    }
}

struct StatRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 20)
            Text(label)
                .font(.callout)
            Spacer()
            Text(value)
                .font(.callout.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }
}
