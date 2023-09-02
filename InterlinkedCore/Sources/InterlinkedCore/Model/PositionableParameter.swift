//
//  PositionableParameter.swift
//  InterlinkedCore
//
//  Created by Dominik Kowalski on 21/05/2023.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder

struct PositionableParameter: Hashable, Identifiable {
    let id: Int
    let parameter: FunctionParameter
    
    init(id: Int, parameter: FunctionParameter) {
        self.id = id
        self.parameter = parameter
    }
    
    var name: String {
        parameter.secondName?.textWithoutTrivia ?? parameter.firstName?.textWithoutTrivia ?? ""
    }
    
    var unwrappedType: TypeSyntax? {
        parameter.type?.unwrappedType
    }
    
    var vertex: Vertex {
        .parameter(.init(id: id))
    }

    func with(id: Int) -> Self {
        .init(id: id, parameter: parameter)
    }

    static func == (lhs: PositionableParameter, rhs: PositionableParameter) -> Bool {
        lhs.id == rhs.id
    }
}
