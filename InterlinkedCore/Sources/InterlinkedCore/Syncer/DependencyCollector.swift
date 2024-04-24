//
//  DependencyCollector.swift
//  InterlinkedCore
//
//  Created by Dominik Kowalski on 25/08/2023.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder

class DependencyCollector {
    private enum Constants {
        static let defaultType: TypeSyntax = .init(stringLiteral: "<#Type#>")
    }
    
    func collectVariables(fromMembers members: MemberBlockItemListSyntax) -> [Variable] {
        let declarations = members.compactMap { $0.decl.as(VariableDeclSyntax.self) }
        var result = [Variable]()
        for declaration in declarations {
            let bindings = declaration.bindings
            let type = bindings.last?.typeAnnotation?.type ?? Constants.defaultType
            let attributes = declaration.attributes.compactMap { $0 }
            for binding in bindings {
                let variable = Variable(
                    attributes: attributes,
                    binding: binding,
                    type: type,
                    isSet: declaration.isSet,
                    isOptional: declaration.isOptionalVariable,
                    isComputed: declaration.isComputedVariable
                )
                result.append(variable)
            }
        }
        return result
    }
    
    func collectParameters(fromFunctionParameters parameters: FunctionParameterListSyntax) -> [PositionableParameter] {
        var result = [PositionableParameter]()
        for (idx, parameter) in parameters.enumerated() {
            result.append(PositionableParameter(id: idx, parameter: parameter))
        }
        return result
    }
    
    func collectCodeBlockItems(fromCodeBlockItems codeBlockItemList: CodeBlockItemListSyntax) -> [PositionableCodeBlockItem] {
        var result = [PositionableCodeBlockItem]()
        for (idx, item) in codeBlockItemList.enumerated() {
            result.append(PositionableCodeBlockItem(id: idx, item: item))
        }
        return result
    }
}
