//
//  Vertex.swift
//  InterlinkedCore
//
//  Created by Dominik Kowalski on 06/06/2023.
//

import Foundation
import SwiftSyntaxBuilder

enum Vertex: Hashable, Codable, Identifiable {
    struct Info: Hashable, Codable, Identifiable {
        let id: Int
    }

    case parameter(Info)
    case codeBlockItem(Info)
    
    var info: Info {
        switch self {
        case .parameter(let info):
            return info
        case .codeBlockItem(let info):
            return info
        }
    }
    
    var id: String {
        switch self {
        case .parameter(let info):
            return "parameter_\(info.id)"
        case .codeBlockItem(let info):
            return "codeBlockItem_\(info.id)"
        }
    }

    func debugDescription(parameterCache: [Int: PositionableParameter], codeBlockItemCache: [Int: PositionableCodeBlockItem]) -> String {
        switch self {
        case .parameter(let info):
            let parameter = parameterCache[info.id]!
            return "parameter(name: \(parameter.name))"
        case .codeBlockItem(let info):
            let codeBlockItem = codeBlockItemCache[info.id]!
            return "customCode(content: \(codeBlockItem.originalItem.description)"
        }
    }
}
