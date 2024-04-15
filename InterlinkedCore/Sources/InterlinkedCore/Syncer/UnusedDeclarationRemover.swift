//
//  UnusedDeclarationRemover.swift
//  InterlinkedCore
//
//  Created by Dominik Kowalski on 26/08/2023.
//

import Foundation
import SwiftSyntaxBuilder
import SwiftSyntax

class UnusedDeclarationRemover: SyntaxRewriter {
    private let scopeBuilder: ScopeBuilder
    
    private var rootList: CodeBlockItemListSyntax!
    private var definitions: DependencyDefinitions!
    
    init(scopeBuilder: ScopeBuilder) {
        self.scopeBuilder = scopeBuilder
    }
    
    func removeUnusedDeclarations(definitions: DependencyDefinitions) -> DependencyDefinitions {
        defer {
            self.definitions = nil
            self.rootList = nil
        }
        self.definitions = definitions
        self.rootList = definitions.rawItemWithInfoList
        let result = visit(rootList).map { $0.fromRawInfoOrNew }
        definitions.replaceCodeBlockItems(codeBlockItems: result)
        return definitions
    }
    
    override func visit(_ node: CodeBlockItemListSyntax) -> CodeBlockItemListSyntax {
        var result = node.map { $0.fromRawInfoOrNew  }
        var idx = 0
        while idx < result.count {
            switch result[idx].originalItem.item {
            case .decl(let decl):
                if shouldRemoveDeclaration(declaration: decl, index: idx, list: node) {
                    result.remove(at: idx)
                } else {
                    idx += 1
                }
            default:
                idx += 1
            }
        }
        
        if rootList.id == node.id {
            return super.visit(CodeBlockItemListSyntax(result.map { $0.rawItemWithInfo }))
        } else {
            return super.visit(CodeBlockItemListSyntax(result.map { $0.originalItem }))
        }
    }
    
    private func shouldRemoveDeclaration(
        declaration: DeclSyntax,
        index: Int,
        list: CodeBlockItemListSyntax
    ) -> Bool {
        let allItems = list.map { $0.fromRawInfoOrNew }
        if let function = declaration.as(FunctionDeclSyntax.self) {
            let scope = scopeBuilder.buildScope(fromCodeBlockItems: allItems)
            return !scope.containsUsed(identifier: function.name.text, skipLocalDeclarations: true)
        } else if let variable = declaration.as(VariableDeclSyntax.self) {
            let remainingItems = list.dropFirst(index+1).map { $0.fromRawInfoOrNew }
            let scope = scopeBuilder.buildScope(fromCodeBlockItems: remainingItems)
            let names = variable.bindings.map { $0.nameIdentifier }
            return names.allSatisfy {
                !scope.containsUsed(identifier: $0, skipLocalDeclarations: true)
            }
        } else if let `struct` = declaration.as(StructDeclSyntax.self) {
            let scope = scopeBuilder.buildScope(fromCodeBlockItems: allItems)
            return !scope.containsUsed(identifier: `struct`.name.text, skipLocalDeclarations: true)
        } else if let `actor` = declaration.as(ActorDeclSyntax.self) {
            let scope = scopeBuilder.buildScope(fromCodeBlockItems: allItems)
            return !scope.containsUsed(identifier: `actor`.name.text, skipLocalDeclarations: true)
        } else if let `class` = declaration.as(ClassDeclSyntax.self) {
            let scope = scopeBuilder.buildScope(fromCodeBlockItems: allItems)
            return !scope.containsUsed(identifier: `class`.name.text, skipLocalDeclarations: true)
        } else if let `enum` = declaration.as(EnumDeclSyntax.self) {
            let scope = scopeBuilder.buildScope(fromCodeBlockItems: allItems)
            return !scope.containsUsed(identifier: `enum`.name.text, skipLocalDeclarations: true)
        }
        return false
    }
}
