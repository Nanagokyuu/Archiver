//
//  ContentViews.swift
//  Unzip
//
//  Created by Nanagokyuu on 2026/4/13.
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
