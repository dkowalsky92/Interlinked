//
//  Interlinked.swift
//  Interlinked
//
//  Created by Dominik Kowalski on 27/04/2023.
//

import SwiftUI

@main
struct AppView: App {
    private let appViewModel = AppViewModel()
    
    var body: some Scene {
        MenuBarExtra("Interlinked", systemImage: "chart.bar.doc.horizontal") {
            ConfigurationView(viewModel: appViewModel.configurationViewModel)
        }
        .windowResizability(.contentSize)
        .menuBarExtraStyle(.window)
    }
}
