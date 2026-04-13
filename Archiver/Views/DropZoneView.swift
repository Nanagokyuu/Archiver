//
//  DropZoneView.swift
//  Unzip
//
//  Created by Nanagokyuu on 2026/4/13.
//

import SwiftUI
import UniformTypeIdentifiers

struct DropZoneView: View {
    @Environment(ArchiveViewModel.self) var viewModel
    @State private var isDragging = false
    @State private var isHovering = false
    @State private var animationPhase: CGFloat = 0

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
                .foregroundStyle(Color.accentColor.opacity(isDragging ? 0.8 : 0))
                .padding(20)
        }
        .background(.background)
        .onDrop(of: [.fileURL], isTargeted: $isDragging) { _ in false }
        .onChange(of: isDragging) { _, newValue in
            if newValue {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    animationPhase = 40
                }
            } else {
                animationPhase = 0
            }
        }
        .animation(.spring(response: 0.4), value: isDragging)
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

            Image(systemName: isDragging ? "arrow.down.doc.fill" : "doc.zipper")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(
                    isDragging
                        ? AnyShapeStyle(Color.accentColor)
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

    private var titleSection: some View {
        VStack(spacing: 8) {
            Text("Archiver")
                .font(.system(size: 28, weight: .bold, design: .rounded))

            Text("Drag & drop an archive file here")
                .font(.title3)
                .foregroundStyle(.secondary)

            Text("Supports ZIP, TAR, GZ, BZ2, XZ, 7Z, RAR")
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
