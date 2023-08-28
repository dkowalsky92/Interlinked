//
//  AppViewModel.swift
//  Interlinked
//
//  Created by Dominik Kowalski on 23/05/2023.
//

import Foundation
import InterlinkedShared
import AppKit

class ConfigurationViewModel: ObservableObject {
    private let userDefaults: UserDefaults
    
    let formatterStyles: [Configuration.FormatterStyle] = Configuration.FormatterStyle.allCases
    let numberFormatter: NumberFormatter = NumberFormatter()
    let maxLineLengthRange = 0...300
    
    var maxLineLength: Int {
        get {
            guard let value = userDefaults.object(forKey: Configuration.Constants.maxLineLengthKey) as? Int else {
                return 0
            }
            return value
        }
        set {
            userDefaults.set(newValue, forKey: Configuration.Constants.maxLineLengthKey)
            userDefaults.synchronize()
            objectWillChange.send()
        }
    }
    var formatterStyle: Configuration.FormatterStyle {
        get {
            guard
                let value = userDefaults.object(forKey: Configuration.Constants.formatterStyleKey) as? String,
                let formatterStyle = Configuration.FormatterStyle(rawValue: value)
            else {
                return .google
            }
            return formatterStyle
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: Configuration.Constants.formatterStyleKey)
            userDefaults.synchronize()
            objectWillChange.send()
        }
    }
    var enableSorting: Bool {
        get {
            guard let value = userDefaults.object(forKey: Configuration.Constants.enableSortingKey) as? Bool else {
                return false
            }
            return value
        }
        set {
            userDefaults.set(newValue, forKey: Configuration.Constants.enableSortingKey)
            userDefaults.synchronize()
            objectWillChange.send()
        }
    }
    
    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }
    
    func terminate() {
        NSApplication.shared.terminate(nil)
    }
}
