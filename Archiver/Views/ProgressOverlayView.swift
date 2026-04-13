//
//  ProgressOverlayView.swift
//  Unzip
//
//  Created by Nanagokyuu on 2026/4/13.
//

import SwiftUI

struct ProgressOverlayView: View {
    @Environment(ArchiveViewModel.self) var viewModel

    var body: some View {
        ZStack {
            // Dim background
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            // Progress card
            VStack(spacing: 20) {
                Image(systemName: isCompressing ? "archivebox.fill" : "arrow.down.doc.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.tint)
                    .modifier(BounceEffectModifier())

                Text(isCompressing ? "Compressing…" : "Extracting…")
                    .font(.title2.bold())

                if let (progress, file) = currentProgress {
                    VStack(spacing: 12) {
                        ProgressView(value: progress)
                            .progressViewStyle(.linear)
                            .tint(.accentColor)

                        HStack {
                            Text(file)
                                .font(.caption)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(Int(progress * 100))%")
                                .font(.caption.bold().monospacedDigit())
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                }
            }
            .padding(32)
            .frame(width: 420)
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThickMaterial)
                    .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
            }
        }
    }

    private var isCompressing: Bool {
        if case .compressing = viewModel.state { return true }
        return false
    }

    private var currentProgress: (Double, String)? {
        switch viewModel.state {
        case .extracting(let progress, let file):
            return (progress, file)
        case .compressing(let progress, let file):
            return (progress, file)
        default:
            return nil
        }
    }
}

private struct BounceEffectModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 15.0, *) {
            content.symbolEffect(.bounce, options: .repeating)
        } else {
            content
        }
    }
}
