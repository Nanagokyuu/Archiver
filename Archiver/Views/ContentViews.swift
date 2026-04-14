//
//  ContentViews.swift
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

struct ContentView: View {
    @Environment(ArchiveViewModel.self) var viewModel

    var body: some View {
        ZStack {
            mainContent
            progressOverlay
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleDrop(providers: providers)
        }
        .alert("Extraction Complete ✅",
               isPresented: Binding(
                   get: { if case .completed = viewModel.state { return true } else { return false } },
                   set: { if !$0 { viewModel.state = .ready } }
               )) {
            Button("OK") { viewModel.state = .ready }
            Button("Open Folder") {
                if case .completed(let path) = viewModel.state {
                    NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: path)
                }
                viewModel.state = .ready
            }
        }
        .alert("Compression Complete ✅",
               isPresented: Binding(
                   get: { if case .compressCompleted = viewModel.state { return true } else { return false } },
                   set: { if !$0 { viewModel.state = .idle } }
               )) {
            Button("OK") { viewModel.state = .idle }
            Button("Show in Finder") {
                if case .compressCompleted(let path) = viewModel.state {
                    NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: (path as NSString).deletingLastPathComponent)
                }
                viewModel.state = .idle
            }
        }
        .alert("Error ❌",
               isPresented: Binding(
                   get: { if case .failed = viewModel.state { return true } else { return false } },
                   set: { if !$0 { viewModel.state = .ready } }
               )) {
            Button("OK") { viewModel.state = .idle }
        } message: {
            if case .failed(let error) = viewModel.state {
                Text(error)
            }
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        switch viewModel.state {
        case .idle:
            DropZoneView()
        case .loading:
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                Text("Reading archive…")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        default:
            NavigationSplitView {
                SidebarView()
                    .navigationSplitViewColumnWidth(min: 220, ideal: 250, max: 320)
            } detail: {
                ArchiveContentView()
            }
            .toolbar {
                ToolbarView(viewModel: viewModel)
            }
        }
    }

    @ViewBuilder
    private var progressOverlay: some View {
        if case .extracting = viewModel.state {
            ProgressOverlayView()
        } else if case .compressing = viewModel.state {
            ProgressOverlayView()
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
            Task { @MainActor in
                viewModel.loadArchive(url: url)
            }
        }
        return true
    }
}
