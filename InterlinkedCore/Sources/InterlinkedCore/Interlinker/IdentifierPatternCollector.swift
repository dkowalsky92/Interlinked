//
//  IdentifierPatternCollector.swift
//  InterlinkedCore
//
//  Created by Dominik Kowalski on 18/06/2023.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder

class IdentifierPatternCollector: SyntaxVisitor {
    var identifiers: [IdentifierPattern] = []
    
    init() {
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: IdentifierPattern) -> SyntaxVisitorContinueKind {
        identifiers.append(node)
        return .visitChildren
    }
}
