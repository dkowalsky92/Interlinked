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
    let binding: PatternBindingSyntax
    let type: TypeSyntax
    let isSet: Bool
    let isOptional: Bool
    let isComputed: Bool
    
    init(
        binding: PatternBindingSyntax,
        type: TypeSyntax,
        isSet: Bool,
        isOptional: Bool,
        isComputed: Bool
    ) {
        self.binding = binding
        self.type = type
        self.isSet = isSet
        self.isOptional = isOptional
        self.isComputed = isComputed
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
    
    static func == (lhs: Variable, rhs: Variable) -> Bool {
        lhs.binding.id == rhs.binding.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(binding.id)
    }
}
