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
    
    func collectVariables(fromMembers members: [MemberDeclListItem]) -> [Variable] {
        let declarations = members.compactMap { $0.decl.as(VariableDecl.self) }
        var result = [Variable]()
        for declaration in declarations {
            let bindings = declaration.bindings
            let type = bindings.last?.typeAnnotation?.type ?? Constants.defaultType
            
            for binding in bindings {
                let variable = Variable(
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
    
    func collectParameters(fromFunctionParameters parameters: FunctionParameterList) -> [PositionableParameter] {
        parameters.map { PositionableParameter(id: $0.indexInParent, parameter: $0) }
    }
    
    func collectCodeBlockItems(fromCodeBlockItems codeBlockItemList: CodeBlockItemList) -> [PositionableCodeBlockItem] {
        codeBlockItemList.map { PositionableCodeBlockItem(id: $0.indexInParent, item: $0) }
    }
}
