//
//  File.swift
//  
//
//  Created by Dominik Kowalski on 29/08/2023.
//

import Foundation
import OSLog

extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier!

    static let standard = Logger(subsystem: subsystem, category: "standard")
}
