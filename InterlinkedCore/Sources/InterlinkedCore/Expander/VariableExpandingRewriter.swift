//
//  VariableExpandingRewriter.swift
//  InterlinkedCore
//
//  Created by Dominik Kowalski on 07/10/2023.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder

class VariableExpandingRewriter: SyntaxRewriter {
    let variableExpander: VariableExpander

    init(variableExpander: VariableExpander) {
        self.variableExpander = variableExpander
    }
    
    override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
        super.visit(variableExpander.expandVariableTypes(variable: node))
    }
}
