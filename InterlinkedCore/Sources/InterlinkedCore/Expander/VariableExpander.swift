//
//  VariableExpander.swift
//  InterlinkedCore
//
//  Created by Dominik Kowalski on 24/06/2023.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder

class VariableExpander {
    func expandVariableTypes(variable: VariableDeclSyntax) -> VariableDeclSyntax {
        let bindings = variable.bindings
        guard let binding = bindings.last, let index = bindings.index(of: binding) else {
            return variable
        }
        let hasNoType = binding.typeAnnotation == nil
        let hasInitializer = binding.initializer != nil
        
        guard hasNoType && !hasInitializer else {
            return variable
        }

        return variable.with(\.bindings, bindings.with(\.[index], updated(binding: binding)))
    }
    
    private func updated(binding: PatternBindingSyntax) -> PatternBindingSyntax {
        let hasBody = binding.accessorBlock != nil
        let pattern = binding.pattern.with(\.trailingTrivia, "")
        let newBinding = binding.with(\.pattern, pattern)
        let typeAnnotationName = binding.nameIdentifier.capitalized(with: Locale.autoupdatingCurrent)
        let typeAnnotation = TypeAnnotationSyntax(
            type: TypeSyntax(stringLiteral: " \(typeAnnotationName)\(hasBody ? " " : "")")
        )
        return newBinding.with(\.typeAnnotation, typeAnnotation)
    }
}
