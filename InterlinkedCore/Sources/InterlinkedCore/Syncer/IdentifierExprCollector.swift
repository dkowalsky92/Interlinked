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
    
    var identifiers: [DeclReferenceExprSyntax] = []
    
    init(identifierFilterers: [IdentifierFilterer] = []) {
        self.identifierFilterers = identifierFilterers
        super.init(viewMode: .sourceAccurate)
    }
    
    func collectIdentifiers(from node: SyntaxProtocol) -> [DeclReferenceExprSyntax] {
        defer {
            identifiers = []
        }
        walk(node)
        return identifiers
    }

    override func visit(_ node: DeclReferenceExprSyntax) -> SyntaxVisitorContinueKind {
        guard identifierFilterers.allSatisfy({ filterer in
            filterer.shouldInclude(identifier: node)
        }) else {
            return .visitChildren
        }
        if let memberAccessExpr = node.parent?.as(MemberAccessExprSyntax.self) {
            if let rootDecl = memberAccessExpr.rootDecl {
                identifiers.append(rootDecl)
            }
        } else {
            identifiers.append(node)
        }
        return .visitChildren
    }
}
