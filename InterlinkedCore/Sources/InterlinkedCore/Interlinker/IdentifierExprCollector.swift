//
//  IdentifierExprCollector.swift
//  InterlinkedCore
//
//  Created by Dominik Kowalski on 12/07/2023.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder

class IdentifierExprCollector: SyntaxVisitor {
    private let identifierFilterers: [IdentifierFilterer]
    
    var identifiers: [IdentifierExpr] = []
    
    init(identifierFilterers: [IdentifierFilterer] = []) {
        self.identifierFilterers = identifierFilterers
        super.init(viewMode: .sourceAccurate)
    }
    
    func collectIdentifiers(from node: SyntaxProtocol) -> [IdentifierExpr] {
        defer {
            identifiers = []
        }
        walk(node)
        return identifiers
    }

    override func visit(_ node: IdentifierExprSyntax) -> SyntaxVisitorContinueKind {
        guard identifierFilterers.allSatisfy({ filterer in
            filterer.shouldInclude(identifier: node)
        }) else {
            return .visitChildren
        }
        identifiers.append(node)
        return .visitChildren
    }
}
