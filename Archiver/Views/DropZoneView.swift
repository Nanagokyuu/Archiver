//
//  DropZoneView.swift
//  Unzip
//
//  Created by Nanagokyuu on 2026/4/13.
//

import SwiftUI
import UniformTypeIdentifiers

/// Represents the inferred action that will happen when the dragged items are dropped.
private enum DropIntent {
    case unknown
    case openArchive   // dragged item looks like an archive
    case compress      // dragged item(s) are regular files/folders
}

struct DropZoneView: View {
    @Environment(ArchiveViewModel.self) var viewModel
    @State private var isDragging = false
    @State private var isHovering = false
    @State private var animationPhase: CGFloat = 0
    @State private var dropIntent: DropIntent = .unknown

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                animatedIcon
                titleSection
                openButton
                recentArchivesSection
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(
                    style: StrokeStyle(lineWidth: 3, dash: [12, 8], dashPhase: animationPhase)
                )
                .foregroundStyle(intentColor.opacity(isDragging ? 0.8 : 0))
                .padding(20)
        }
        .background(.background)
        .onDrop(of: [.fileURL], delegate: ArchiveDropDelegate(
            isDragging: $isDragging,
            dropIntent: $dropIntent,
            onDrop: { urls in
                handleDrop(urls: urls)
            }
        ))
        .onChange(of: isDragging) { _, newValue in
            if newValue {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    animationPhase = 40
                }
            } else {
                animationPhase = 0
                dropIntent = .unknown
            }
        }
        .animation(.spring(response: 0.4), value: isDragging)
        .animation(.spring(response: 0.3), value: dropIntent == .openArchive)
    }

    private var intentColor: Color {
        switch dropIntent {
        case .compress: return .orange
        default: return .accentColor
        }
    }

    private func handleDrop(urls: [URL]) {
        guard !urls.isEmpty else { return }
        // If exactly one file is dropped and it's an archive, open it.
        // Otherwise, compress all dropped files/folders.
        if urls.count == 1, ArchiveFormat.detect(from: urls[0]) != .unknown {
            viewModel.loadArchive(url: urls[0])
        } else {
            viewModel.compressFiles(droppedURLs: urls)
        }
    }

    private var animatedIcon: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            .accentColor.opacity(isDragging ? 0.3 : 0.1),
                            .clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .scaleEffect(isDragging ? 1.2 : 1.0)

            Image(systemName: dragIconName)
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(
                    isDragging
                        ? AnyShapeStyle(intentColor)
                        : AnyShapeStyle(
                            .linearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .symbolEffect(.pulse, options: .repeating, value: isDragging)
        }
    }

    private var dragIconName: String {
        switch dropIntent {
        case .openArchive: return "arrow.down.doc.fill"
        case .compress:    return "archivebox.fill"
        case .unknown:     return isDragging ? "arrow.down.doc.fill" : "doc.zipper"
        }
    }

    private var titleSection: some View {
        VStack(spacing: 8) {
            Text("Archiver")
                .font(.system(size: 28, weight: .bold, design: .rounded))

            Group {
                switch dropIntent {
                case .openArchive:
                    Text("Release to open archive")
                        .foregroundStyle(Color.accentColor)
                case .compress:
                    Text("Release to compress files")
                        .foregroundStyle(.orange)
                case .unknown:
                    Text(isDragging ? "Drop here" : "Drag & drop files or archives here")
                        .foregroundStyle(.secondary)
                }
            }
            .font(.title3)
            .animation(.easeInOut(duration: 0.2), value: dropIntent == .openArchive)

            Text("Archives open automatically · Other files get compressed")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.top, 2)
        }
    }

    private var openButton: some View {
        HStack(spacing: 12) {
            Button {
                viewModel.openFilePicker()
            } label: {
                Label("Open Archive", systemImage: "folder.badge.plus")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.accentColor)

            Button {
                viewModel.compressFiles()
            } label: {
                Label("Compress Files", systemImage: "archivebox.fill")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
    }

    @ViewBuilder
    private var recentArchivesSection: some View {
        if !viewModel.recentArchives.isEmpty {
            VStack(spacing: 8) {
                Text("Recent Archives")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .textCase(.uppercase)

                VStack(spacing: 4) {
                    ForEach(viewModel.recentArchives.prefix(5), id: \.self) { url in
                        HStack(spacing: 0) {
                            Button {
                                viewModel.loadArchive(url: url)
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "doc.zipper")
                                        .foregroundStyle(.secondary)
                                        .font(.caption)
                                    Text(url.lastPathComponent)
                                        .font(.callout)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                    Spacer()
                                }
                            }
                            .buttonStyle(.plain)

                            Button {
                                withAnimation {
                                    viewModel.removeRecentArchive(url)
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.tertiary)
                                    .font(.caption)
                            }
                            .buttonStyle(.plain)
                            .help("Remove from history")
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(.quaternary.opacity(0.5))
                        )
                    }
                }
                .frame(maxWidth: 320)
            }
            .padding(.top, 8)
        }
    }
}

// MARK: - Drop Delegate

/// Handles drag-and-drop onto the drop zone.
/// Uses registered UTI type identifiers to infer intent *during hover*,
/// then loads the actual URLs asynchronously on drop.
private struct ArchiveDropDelegate: DropDelegate {
    @Binding var isDragging: Bool
    @Binding var dropIntent: DropIntent
    let onDrop: ([URL]) -> Void

    // UTIs that indicate an archive file (synchronous peek, no URL load needed)
    private static let archiveUTIs: Set<String> = [
        "public.zip-archive",           // .zip
        "org.gnu.gnu-tar-archive",      // .tar
        "org.7-zip.7-zip-archive",      // .7z
        "com.rarlab.rar-archive",       // .rar
        "org.gnu.gnu-zip-archive",      // .gz
        "public.bzip2-archive",         // .bz2
        "public.xz-archive",            // .xz
        "com.apple.binhex-archive",
    ]

    private func inferIntent(from providers: [NSItemProvider]) -> DropIntent {
        guard let provider = providers.first else { return .unknown }
        let types = Set(provider.registeredTypeIdentifiers)
        if !types.isDisjoint(with: Self.archiveUTIs) { return .openArchive }
        // Check by suggested filename extension as a fallback
        if let name = provider.suggestedName {
            let url = URL(fileURLWithPath: name)
            if ArchiveFormat.detect(from: url) != .unknown { return .openArchive }
        }
        return .compress
    }

    func validateDrop(info: DropInfo) -> Bool { true }

    func dropEntered(info: DropInfo) {
        isDragging = true
        dropIntent = inferIntent(from: info.itemProviders(for: [.fileURL]))
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        dropIntent = inferIntent(from: info.itemProviders(for: [.fileURL]))
        return DropProposal(operation: .copy)
    }

    func dropExited(info: DropInfo) {
        isDragging = false
        dropIntent = .unknown
    }

    func performDrop(info: DropInfo) -> Bool {
        isDragging = false
        let providers = info.itemProviders(for: [.fileURL])
        guard !providers.isEmpty else { return false }

        // Collect all URLs then dispatch
        var urls: [URL] = []
        let group = DispatchGroup()

        for provider in providers {
            group.enter()
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                if let url { urls.append(url) }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            guard !urls.isEmpty else { return }
            onDrop(urls)
        }
        return true
    }
}
