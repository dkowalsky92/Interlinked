//
//  AppViewModel.swift
//  InterlinkedUI
//
//  Created by Dominik Kowalski on 24/05/2023.
//

import Foundation
import InterlinkedShared

class AppViewModel {
    let userDefaults: UserDefaults
    let configurationViewModel: ConfigurationViewModel
    
    init() {
        self.userDefaults = UserDefaults(suiteName: Constants.userDefaultsSuiteName)!
        self.configurationViewModel = ConfigurationViewModel(userDefaults: userDefaults)
    }
}
