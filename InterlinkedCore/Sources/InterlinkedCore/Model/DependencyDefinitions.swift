//
//  DependencyDefinitions.swift
//  InterlinkedCore
//
//  Created by Dominik Kowalski on 15/06/2023.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder

class DependencyDefinitions {
    private let scopeBuilder: ScopeBuilder
    
    let variables: [Variable]

    private(set) var parameters: [PositionableParameter]
    private(set) var codeBlockItems: [PositionableCodeBlockItem]
    private(set) var scope: Scope
    private(set) var parametersCache: [Int: PositionableParameter]
    private(set) var codeBlockItemsCache: [Int: PositionableCodeBlockItem]
    
    init(
        scopeBuilder: ScopeBuilder,
        variables: [Variable],
        parameters: [PositionableParameter],
        codeBlockItems: [PositionableCodeBlockItem]
    ) {
        self.scopeBuilder = scopeBuilder
        self.variables = variables
        self.parameters = parameters
        self.parametersCache = Dictionary(uniqueKeysWithValues: parameters.map { ($0.id, $0) })
        self.codeBlockItems = codeBlockItems
        self.codeBlockItemsCache = Dictionary(uniqueKeysWithValues: codeBlockItems.map { ($0.id, $0) })
        self.scope = scopeBuilder.buildScope(fromCodeBlockItems: codeBlockItems)
    }
    
    var rawItemWithInfoList: CodeBlockItemListSyntax {
        CodeBlockItemListSyntax(codeBlockItems.map { $0.rawItemWithInfo })
    }
    
    var lastAssignmentIndex: Int? {
        scope.lastAssignmentIndex
    }
    
    var firstAfterAssignmentsIndex: Int? {
        guard let lastAssignmentIndex else {
            return nil
        }
        return lastAssignmentIndex + 1
    }
    
    func replaceParameters(parameters: [PositionableParameter]) {
        self.parameters = parameters
        reorderParameters()
        parametersCache = Dictionary(uniqueKeysWithValues: self.parameters.map { ($0.id, $0) })
    }
    
    func insertParameter(parameter: PositionableParameter) {
        parameters.append(parameter)
        reorderParameters()
        parametersCache = Dictionary(uniqueKeysWithValues: parameters.map { ($0.id, $0) })
    }
    
    func removeParameter(atIndex index: Int) {
        parameters.remove(at: index)
        reorderParameters()
        parametersCache = Dictionary(uniqueKeysWithValues: parameters.map { ($0.id, $0) })
    }
    
    func replaceCodeBlockItems(codeBlockItems: [PositionableCodeBlockItem]) {
        self.codeBlockItems = codeBlockItems
        reorderCodeBlockItems()
        codeBlockItemsCache = Dictionary(uniqueKeysWithValues: self.codeBlockItems.map { ($0.id, $0) })
        scope = scopeBuilder.buildScope(fromCodeBlockItems: self.codeBlockItems)
    }

    func insertCodeBlockItem(codeBlockItem: PositionableCodeBlockItem) {
        if let lastAssignmentIndex, lastAssignmentIndex < codeBlockItems.count - 1 {
            codeBlockItems.insert(codeBlockItem, at: lastAssignmentIndex+1)
        } else {
            codeBlockItems.insert(codeBlockItem, at: 0)
        }
        reorderCodeBlockItems()
        codeBlockItemsCache = Dictionary(uniqueKeysWithValues: codeBlockItems.map { ($0.id, $0) })
        scope = scopeBuilder.buildScope(fromCodeBlockItems: codeBlockItems)
    }
    
    func removeCodeBlockItem(atIndex index: Int) {
        codeBlockItems.remove(at: index)
        reorderCodeBlockItems()
        codeBlockItemsCache = Dictionary(uniqueKeysWithValues: codeBlockItems.map { ($0.id, $0) })
        scope = scopeBuilder.buildScope(fromCodeBlockItems: codeBlockItems)
    }
    
    private func reorderParameters() {
        for idx in 0..<parameters.count {
            parameters[idx] = parameters[idx].with(id: idx)
        }
    }
    
    private func reorderCodeBlockItems() {
        for idx in 0..<codeBlockItems.count {
            codeBlockItems[idx] = codeBlockItems[idx].with(id: idx)
        }
    }
}

extension DependencyDefinitions: CustomDebugStringConvertible {
    var debugDescription: String {
        var result = ""
        result += "Parameters:\n"
        let paramString = parameters.map { "\tid: \($0.id), name: \($0.name)" }.joined(separator: ",\n")
        result += "\(paramString)"
        result += "\nCodeBlockItems:"
        let itemString = codeBlockItems.map { "\tid: \($0.id), name: \($0.originalItem.description)" }.joined(separator: ",\n")
        result += "\n\(itemString)"
        result += "\n\(scope.debugDescription)"
        return result
    }
}
