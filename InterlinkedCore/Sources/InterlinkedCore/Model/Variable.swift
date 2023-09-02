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
    let binding: PatternBinding
    let type: TypeSyntax
    let isSet: Bool
    let isOptional: Bool
    let isComputed: Bool
    
    init(
        binding: PatternBinding,
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
        type.is(FunctionType.self)
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
}
