//
//  PositionableCodeBlockItem.swift
//  InterlinkedCore
//
//  Created by Dominik Kowalski on 08/06/2023.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder

struct PositionableCodeBlockItem: Hashable, Identifiable {
    private let item: CodeBlockItemSyntax
    
    let id: Int
    
    init(id: Int, item: CodeBlockItemSyntax) {
        self.id = id
        self.item = item
    }
    
    init?(rawItemWithInfo: CodeBlockItemSyntax) {
        guard
            let unexpectedBeforeItem = rawItemWithInfo.unexpectedBeforeItem,
            let token = unexpectedBeforeItem.first?.as(TokenSyntax.self),
            let id = Int(token.text)
        else {
            return nil
        }
        self.id = id
        self.item = rawItemWithInfo.with(\.unexpectedBeforeItem, nil)
    }
    
    var originalItem: CodeBlockItemSyntax {
        item.with(\.unexpectedBeforeItem, nil)
    }
    
    var rawItemWithInfo: CodeBlockItemSyntax {
        item.with(\.unexpectedBeforeItem, .init(itemsBuilder: { TokenSyntax.identifier("\(id)") }))
    }
    
    var vertex: Vertex {
        .codeBlockItem(.init(id: id))
    }
    
    func with(id: Int) -> Self {
        .init(id: id, item: item)
    }

    static func == (lhs: PositionableCodeBlockItem, rhs: PositionableCodeBlockItem) -> Bool {
        lhs.id == rhs.id
    }
}
