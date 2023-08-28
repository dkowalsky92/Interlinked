//
//  EmptyCodeBlockItemListRewriter.swift
//  InterlinkedCore
//
//  Created by Dominik Kowalski on 22/08/2023.
//

import Foundation
import SwiftSyntaxBuilder
import SwiftSyntax

class EmptyCodeBlockItemListRemover: SyntaxRewriter {
    func removeEmptyCodeBlockItemLists(fromCodeBlockItems codeBlockItems: [PositionableCodeBlockItem]) -> [PositionableCodeBlockItem] {
        let rootList = CodeBlockItemList(codeBlockItems.map { $0.rawItemWithInfo })
        return visit(rootList).compactMap { PositionableCodeBlockItem(rawItemWithInfo: $0) }
    }
    
    override func visit(_ node: CodeBlockItemList) -> CodeBlockItemList {
        let items = node.map { $0.fromRawInfoOrNew  }
        var result = items
        for (idx, item) in items.enumerated() {
            if let ifStmt = item.originalItem.as(IfStmt.self) {
                if let elseBody = ifStmt.elseBody {
                    switch elseBody {
                    case .ifStmt(let ifElseStmt):
                        if ifElseStmt.body.statements.isEmpty {
                            //result = result
                        }
                    case .codeBlock(let elseStmt):
                        if elseStmt.statements.isEmpty {
                            //result = true
                        }
                    }
                } else {
                    
                }
            }
        }
        return super.visit(CodeBlockItemList(result.map { $0.rawItemWithInfo }))
    }
}
