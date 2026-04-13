//
//  ToolbarView.swift
//  Unzip
//
//  Created by Nanagokyuu on 2026/4/13.
//


import SwiftUI

struct ToolbarView: ToolbarContent {
    var viewModel: ArchiveViewModel

    var body: some ToolbarContent {
        ToolbarItem(placement: .navigation) {
            Button(action: {
                viewModel.openFilePicker()
            }) {
                Label("Open", systemImage: "plus")
            }
        }

        ToolbarItem(placement: .automatic) {
            Button(action: {
                viewModel.extractAll()
            }) {
                Label("Extract All", systemImage: "square.and.arrow.up")
            }
        }

        ToolbarItem(placement: .automatic) {
            Button(action: {
                viewModel.compressFiles()
            }) {
                Label("Compress", systemImage: "archivebox.fill")
            }
        }
    }
}
