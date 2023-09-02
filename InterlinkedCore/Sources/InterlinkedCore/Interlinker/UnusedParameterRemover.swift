//
//  UnusedParameterRemover.swift
//  InterlinkedCore
//
//  Created by Dominik Kowalski on 19/08/2023.
//

import Foundation
import SwiftSyntaxBuilder
import SwiftSyntax
import InterlinkedShared

class UnusedParameterRemover {
    func removeUnusedParameters(definitions: DependencyDefinitions) -> DependencyDefinitions {
        var result = [PositionableParameter]()
        for parameter in definitions.parameters {
            let isMatchingVariable = definitions.variables.contains(where: {
                $0.name == parameter.name && $0.unwrappedType.textWithoutTrivia == parameter.unwrappedType?.textWithoutTrivia
            })
            let isUsedInCodeBlockItems = definitions.scope.containsUsed(identifier: parameter.name, skipLocalDeclarations: false)
            if (isMatchingVariable && isUsedInCodeBlockItems) || isUsedInCodeBlockItems {
                result.append(parameter)
            }
        }
        definitions.replaceParameters(parameters: result)
        return definitions
    }
}
