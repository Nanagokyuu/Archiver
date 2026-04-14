//
//  ArchiveContentView.swift
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

struct ArchiveContentView: View {
    @Environment(ArchiveViewModel.self) var viewModel

    var body: some View {
        @Bindable var viewModel = viewModel
        VStack(spacing: 0) {
            // Header bar
            headerBar

            Divider()

            if viewModel.filteredItems.isEmpty {
                EmptyStateView(
                    icon: "magnifyingglass",
                    title: "No Results",
                    subtitle: "No files match your search criteria."
                )
            } else {
                // File table
                Table(viewModel.filteredItems, selection: $viewModel.selectedItems) {
                    TableColumn("") { item in
                        Image(systemName: item.icon)
                            .foregroundStyle(item.iconColor)
                            .font(.callout)
                    }
                    .width(24)

                    TableColumn("Name") { item in
                        VStack(alignment: .leading, spacing: 1) {
                            Text(item.fileName)
                                .font(.callout)
                                .lineLimit(1)
                            if item.depth > 0 {
                                Text(item.path)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .width(min: 200, ideal: 350)

                    TableColumn("Size") { item in
                        Text(item.isDirectory ? "—" : item.formattedSize)
                            .font(.callout.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    .width(min: 70, ideal: 90)

                    TableColumn("Compressed") { item in
                        Text(item.isDirectory ? "—" : item.formattedCompressedSize)
                            .font(.callout.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    .width(min: 70, ideal: 100)

                    TableColumn("Ratio") { item in
                        if !item.isDirectory && item.size > 0 {
                            HStack(spacing: 4) {
                                Text("\(Int(item.compressionRatio * 100))%")
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)

                                ProgressView(value: item.compressionRatio)
                                    .tint(ratioColor(item.compressionRatio))
                                    .frame(width: 40)
                            }
                        } else {
                            Text("—")
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .width(min: 80, ideal: 100)

                    TableColumn("Date") { item in
                        if let date = item.modificationDate {
                            Text(date, style: .date)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("—")
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .width(min: 80, ideal: 100)
                }
                .tableStyle(.bordered(alternatesRowBackgrounds: true))
            }

            Divider()

            // Status bar
            statusBar
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        @Bindable var viewModel = viewModel
        return HStack(spacing: 12) {
            // Search
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search files…", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(6)
            .background(RoundedRectangle(cornerRadius: 8).fill(.quaternary))
            .frame(maxWidth: 280)

            Spacer()

            // Sort
            Picker("Sort", selection: $viewModel.sortOrder) {
                ForEach(ArchiveViewModel.SortOrder.allCases, id: \.self) { order in
                    Text(order.rawValue).tag(order)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 240)

            Toggle(isOn: $viewModel.showHiddenFiles) {
                Image(systemName: "eye.slash")
            }
            .toggleStyle(.checkbox)
            .help("Show hidden files")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Status Bar

    private var statusBar: some View {
        HStack(spacing: 16) {
            Label("\(viewModel.totalFiles) files", systemImage: "doc.fill")
            Label("\(viewModel.totalFolders) folders", systemImage: "folder.fill")

            Spacer()

            if !viewModel.selectedItems.isEmpty {
                Text("\(viewModel.selectedItems.count) selected")
                    .foregroundStyle(Color.accentColor)
            }

            Text("Total: \(ByteCountFormatter.string(fromByteCount: Int64(viewModel.totalSize), countStyle: .file))")
                .foregroundStyle(.secondary)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(.bar)
    }

    private func ratioColor(_ ratio: Double) -> Color {
        if ratio > 0.7 { return .green }
        if ratio > 0.4 { return .blue }
        if ratio > 0.1 { return .orange }
        return .red
    }
}
