//
//  MissingParameterAndAssignmentInjector.swift
//  InterlinkedCore
//
//  Created by Dominik Kowalski on 19/08/2023.
//

import Foundation
import SwiftSyntaxBuilder
import SwiftSyntax
import InterlinkedShared

class MissingParameterAndAssignmentInjector {
    private let scopeBuilder: ScopeBuilder
    private let codeBlockItemRelationshipFinder: CodeBlockItemRelationshipFinder
    
    init(
        scopeBuilder: ScopeBuilder,
        codeBlockItemRelationshipFinder: CodeBlockItemRelationshipFinder
    ) {
        self.scopeBuilder = scopeBuilder
        self.codeBlockItemRelationshipFinder = codeBlockItemRelationshipFinder
    }
    
    func injectMissingParametersAndAssignments(definitions: DependencyDefinitions) -> DependencyDefinitions {
        for variable in definitions.variables {
            guard variable.isSettable else {
                continue
            }
            let parameter = parameter(forVariable: variable, parameters: definitions.parameters)
            let assignment = definitions.scope.instanceAssignment(forIdentifier: variable.name)
            guard parameter == nil || assignment == nil else {
                continue
            }
            if parameter != nil {
                definitions.insertCodeBlockItem(codeBlockItem: makeAssignment(forVariable: variable))
            } else if let assignment {
                var containsDeclaration = false
                let previousItemIndex = assignment.rootItemId - 1
                if previousItemIndex > 0 {
                    let previousItemsScope = scopeBuilder.buildScope(fromCodeBlockItems: definitions.codeBlockItems.dropLast(definitions.codeBlockItems.count - previousItemIndex))
                    containsDeclaration = previousItemsScope.containsDeclaration(forIdentifier: variable.name, type: .variable)
                }
                if assignment.info.assignee == assignment.info.assigner.description && !containsDeclaration {
                    definitions.insertParameter(parameter: makeParameter(forVariable: variable))
                }
            } else {
                guard !variable.isOptional && !variable.isSet else {
                    continue
                }
                definitions.insertParameter(parameter: makeParameter(forVariable: variable))
                definitions.insertCodeBlockItem(codeBlockItem: makeAssignment(forVariable: variable))
            }
        }
 
        return definitions
    }

    private func parameter(
        forVariable variable: Variable,
        parameters: [PositionableParameter]
    ) -> PositionableParameter? {
        parameters.first(where: {
            variable.binding.nameIdentifier == $0.parameter.nameIdentifier && variable.unwrappedType.textWithoutTrivia == $0.unwrappedType?.textWithoutTrivia
        })
    }
    
    private func makeParameter(forVariable variable: Variable) -> PositionableParameter {
        PositionableParameter(
            id: 0,
            parameter: FunctionParameter(name: variable.name, type: variable.type, isEscaping: variable.isEscaping)
        )
    }
    
    private func makeAssignment(forVariable variable: Variable) -> PositionableCodeBlockItem {
        PositionableCodeBlockItem(
            id: 0,
            item: CodeBlockItem(name: variable.binding.nameIdentifier)
        )
    }
}
