//
//  IdentifierFilterer.swift
//  InterlinkedCore
//
//  Created by Dominik Kowalski on 29/05/2023.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder

protocol IdentifierFilterer {
    func shouldInclude(identifier: DeclReferenceExprSyntax) -> Bool
}

struct SelfIdentifierFilterer: IdentifierFilterer {
    func shouldInclude(identifier: DeclReferenceExprSyntax) -> Bool {
        identifier.baseName.tokenKind != .keyword(.`self`)
    }
}
