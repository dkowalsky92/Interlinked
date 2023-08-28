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
    func shouldInclude(identifier: IdentifierExpr) -> Bool
}

struct FunctionCallExprIdentifierFilterer: IdentifierFilterer {
    func shouldInclude(identifier: IdentifierExpr) -> Bool {
        guard let parent = identifier.parent else {
            return true
        }
        return !parent.is(FunctionCallExpr.self)
    }
}

struct SelfIdentifierFilterer: IdentifierFilterer {
    func shouldInclude(identifier: IdentifierExpr) -> Bool {
        identifier.identifier.tokenKind != .selfKeyword
    }
}
