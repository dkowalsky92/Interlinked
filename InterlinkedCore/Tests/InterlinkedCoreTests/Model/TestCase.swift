//
//  TestCase.swift
//  InterlinkTests
//
//  Created by Dominik Kowalski on 07/05/2023.
//

import Foundation

@testable import InterlinkedCore
@testable import InterlinkedShared

struct TestCase {
    let context: String
    let configuration: Configuration
    let input: String
    let expectedOutput: String
    
    init(
        context: String,
        configuration: Configuration = .init(spacesPerTab: 4, maxLineLength: 100),
        input: String,
        expectedOutput: String
    ) {
        self.context = context
        self.configuration = configuration
        self.input = input
        self.expectedOutput = expectedOutput
    }
}
