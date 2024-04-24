//
//  Variable.swift
//  InterlinkedCore
//
//  Created by Dominik Kowalski on 18/05/2023.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder

struct Variable: Equatable, Hashable {
    let attributes: [AttributeListSyntax.Element]
    let binding: PatternBindingSyntax
    let type: TypeSyntax
    let isSet: Bool
    let isOptional: Bool
    let isComputed: Bool

    init(
        attributes: [AttributeListSyntax.Element],
        binding: PatternBindingSyntax,
        type: TypeSyntax,
        isSet: Bool,
        isOptional: Bool,
        isComputed: Bool
    ) {
        self.attributes = attributes
        self.binding = binding
        self.type = type
        self.isSet = isSet
        self.isOptional = isOptional
        self.isComputed = isComputed
    }
    
    var isSwiftUIBinding: Bool {
        let isAttributeBinding = attributes.contains(where: {
            switch $0 {
            case .attribute(let attr):
                return attr.attributeName.textWithoutTrivia == "Binding"
            default:
                return false
            }
        })
        let identifierType = binding.as(IdentifierTypeSyntax.self)
        let isTypeBinding = identifierType?.name == "Binding"
        return isAttributeBinding || isTypeBinding
    }
    
    var isEscaping: Bool {
        type.is(FunctionTypeSyntax.self)
    }
    
    var isSettable: Bool {
        !isComputed
    }

    var name: String {
        binding.nameIdentifier
    }
    
    var unwrappedType: TypeSyntax {
        type.unwrappedType
    }
    
    var parameter: PositionableParameter {
        var resultType: TypeSyntaxProtocol = type
        if isEscaping {
            resultType = AttributedTypeSyntax(attributes: .escaping, baseType: type)
        } else if isSwiftUIBinding {
            resultType = IdentifierTypeSyntax(name: "Binding", genericArgumentClause: .init(argumentsBuilder: {
                .init(argument: type)
            }))
        }
        
        return PositionableParameter(
            id: 0,
            parameter: .init(name: name, type: resultType)
        )
    }
    
    var assignment: PositionableCodeBlockItem {
        let assignee: String = if isSwiftUIBinding {
            "_\(name)"
        } else {
            name
        }
        return PositionableCodeBlockItem(
            id: 0,
            item: .init(assignee: assignee, assigner: name)
        )
    }

    static func == (lhs: Variable, rhs: Variable) -> Bool {
        lhs.binding.id == rhs.binding.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(binding.id)
    }
}
