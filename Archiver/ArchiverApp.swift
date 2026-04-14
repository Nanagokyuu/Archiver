//
//  ArchiverApp.swift
//  Unzip
//
//  Created by Nanagokyuu on 2026/4/13.
//

import SwiftUI

@main
struct ArchiverApp: App {
    @State private var viewModel = ArchiveViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(viewModel)
                .frame(minWidth: 800, minHeight: 560)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open Archive…") {
                    viewModel.openFilePicker()
                }
                .keyboardShortcut("o", modifiers: .command)

                Button("Compress Files…") {
                    viewModel.compressFiles()
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(ArchiveViewModel())
    }
}


//      |\      _,,,---,,_
//ZZZzz /,`.-'`'    -.  ;-;;,_
//     |,4-  ) )-,_. ,\ (  `'-'
//    '---''(_/--'  `-'\_)
//     ねこちゃん寝てるから、起こさないであげて


