//
//  UnusedCodeBlockItemRemover.swift
//  InterlinkedCore
//
//  Created by Dominik Kowalski on 18/08/2023.
//

import Foundation
import SwiftSyntaxBuilder
import SwiftSyntax

class UnusedAssignmentRemover: SyntaxRewriter {
    private let scopeBuilder: ScopeBuilder
    
    private var rootList: CodeBlockItemList!
    private var definitions: DependencyDefinitions!
    
    init(scopeBuilder: ScopeBuilder) {
        self.scopeBuilder = scopeBuilder
    }
    
    func removeUnusedAssignments(definitions: DependencyDefinitions) -> DependencyDefinitions {
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
    
    override func visit(_ node: CodeBlockItemList) -> CodeBlockItemList {
        var result = node.map { $0.fromRawInfoOrNew  }
        var idx = 0
        while idx < result.count {
            switch result[idx].originalItem.item {
            case .expr(let expr):
                if shouldRemoveAssignment(
                    expression: expr,
                    variables: definitions.variables,
                    index: idx,
                    list: node
                ) {
                    result.remove(at: idx)
                } else {
                    idx += 1
                }
            default:
                idx += 1
            }
        }
        
        if rootList.id == node.id {
            return super.visit(CodeBlockItemList(result.map { $0.rawItemWithInfo }))
        } else {
            return super.visit(CodeBlockItemList(result.map { $0.originalItem }))
        }
    }
    
    private func shouldRemoveAssignment(
        expression: ExprSyntax,
        variables: [Variable],
        index: Int,
        list: CodeBlockItemList
    ) -> Bool {
        if let sequence = expression.as(SequenceExpr.self), let assignmentInfo = AssignmentInfo(sequenceExpr: sequence) {
            guard definitions.scope.localAssignment(forIdentifier: assignmentInfo.assignee) == nil else {
                return false
            }
            let assignment = definitions.scope.instanceAssignment(forIdentifier: assignmentInfo.assignee)
            let containsVariableForAssignment = variables.contains {
                guard $0.isSettable else {
                    return false
                }
                return assignment?.info.assignee == $0.name
            }
            return containsVariableForAssignment == false
        }
        return false
    }
}
