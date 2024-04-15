//
//  CodeBlockItemRelationshipFinder.swift
//  InterlinkedCore
//
//  Created by Dominik Kowalski on 13/06/2023.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder

class CodeBlockItemRelationshipFinder {
    private let identifierFilterers: [IdentifierFilterer]
    private let initializerScopeBuilder: ScopeBuilder
    
    init(
        identifierFilterers: [IdentifierFilterer],
        initializerScopeBuilder: ScopeBuilder
    ) {
        self.identifierFilterers = identifierFilterers
        self.initializerScopeBuilder = initializerScopeBuilder
    }
    
    func relatedCodeBlockItems(withName name: String, codeBlockItems: [PositionableCodeBlockItem]) -> [PositionableCodeBlockItem] {
        codeBlockItems.compactMap { codeBlockItem -> PositionableCodeBlockItem? in
            contains(identifier: name, item: codeBlockItem) ? codeBlockItem : nil
        }
    }
    
    private func contains(identifier: String, item: PositionableCodeBlockItem) -> Bool {
        let scope = initializerScopeBuilder.buildScope(fromCodeBlockItems: [item])
        return scope.containsUsed(identifier: identifier, skipLocalDeclarations: true)
    }
}
