//
//  SourceParser.swift
//  Interlink
//
//  Created by Dominik Kowalski on 06/05/2023.
//

import Foundation
import SwiftSyntax
import SwiftParser

class SourceParser {
    func parse(source: String) throws -> SourceFile {
        Parser.parse(source: source)
    }
}
