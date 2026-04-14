//
//  ToolbarView.swift
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
