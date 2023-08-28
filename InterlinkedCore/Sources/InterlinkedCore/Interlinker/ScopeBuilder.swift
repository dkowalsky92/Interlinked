//
//  ScopeBuilder.swift
//  InterlinkedCore
//
//  Created by Dominik Kowalski on 12/07/2023.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxParser
import SwiftSyntaxBuilder

class ScopeBuilder: SyntaxVisitor {
    private let identifierExprCollector: IdentifierExprCollector

    private var stack: Stack<Scope> = Stack()
    private var rootItemId: Int!
    private var scope: Scope!
    
    init(identifierExprCollector: IdentifierExprCollector) {
        self.identifierExprCollector = identifierExprCollector
        super.init(viewMode: .sourceAccurate)
    }

    func buildScope(fromCodeBlockItems codeBlockItems: [PositionableCodeBlockItem]) -> Scope {
        defer {
            stack = Stack()
            rootItemId = nil
            scope = nil
        }
        walk(CodeBlockItemList(codeBlockItems.map { $0.rawItemWithInfo }))
        return scope ?? Scope()
    }
    
    // MARK: CodeBlockItem
    override func visit(_ node: CodeBlockItem) -> SyntaxVisitorContinueKind {
        if let positionableCodeBlockItem = PositionableCodeBlockItem(rawItemWithInfo: node) {
            rootItemId = positionableCodeBlockItem.id
        }
        collectUsedIdentifiers(from: node)
        return .visitChildren
    }

    // MARK: CodeBlockItemList
    override func visit(_ node: CodeBlockItemList) -> SyntaxVisitorContinueKind {
        if let parent = node.parent, let grandParent = parent.parent {
            if let ifStmt = grandParent.as(IfStmt.self) {
                pushScope()
                if let nameInParent = ifStmt.childNameInParent, nameInParent != "elseBody" {
                    collectDeclarations(from: ifStmt.conditions)
                }
            } else if let guardStmt = grandParent.as(GuardStmt.self) {
                collectDeclarations(from: guardStmt.conditions)
                pushScope()
            } else if let whileStmt = grandParent.as(WhileStmtSyntax.self) {
                pushScope()
                collectDeclarations(from: whileStmt.conditions)
            } else if let pattern = grandParent.as(ForInStmtSyntax.self)?.pattern {
                pushScope()
                collectDeclarations(from: pattern)
            } else if let functionDecl = grandParent.as(FunctionDeclSyntax.self) {
                pushScope()
                stack.addDeclarationToPreviousLast(
                    .init(
                        rootItemId: rootItemId,
                        identifier: functionDecl.identifier.text,
                        type: .function
                    )
                )
                collectDeclarations(from: functionDecl.signature.input.parameterList)
            } else if let closureParameters = parent.as(ClosureExprSyntax.self)?.signature?.input {
                pushScope()
                collectDeclarations(from: closureParameters)
            } else if let switchCase = parent.as(SwitchCaseSyntax.self)?.label.as(SwitchCaseLabelSyntax.self) {
                pushScope()
                collectDeclarations(from: switchCase)
            } else if let catchClause = grandParent.as(CatchClauseSyntax.self) {
                pushScope()
                collectDeclarations(from: catchClause)
            } else {
                pushScope()
            }
        } else {
            pushScope()
        }
        return .visitChildren
    }
    
    override func visitPost(_ node: CodeBlockItemList) {
        popAndAppend()
    }
    
    // MARK: VariableDecl
    override open func visitPost(_ node: VariableDeclSyntax) {
        if node.parent?.is(MemberDeclListItemSyntax.self) != true {
            for binding in node.bindings {
                collectDeclarations(from: binding.pattern)
            }
        }
    }

    // MARK: Typealias
    override func visit(_ node: TypealiasDecl) -> SyntaxVisitorContinueKind {
        stack.addDeclarationToLast(
            .init(
                rootItemId: rootItemId,
                identifier: node.identifier.text,
                type: .typealias
            )
        )
        
        return .visitChildren
    }
    
    // MARK: MemberDeclList
    override func visit(_ node: MemberDeclList) -> SyntaxVisitorContinueKind {
        guard let parent = node.parent, let grandParent = parent.parent else {
            return .skipChildren
        }
        
        if let classDecl = grandParent.as(ClassDecl.self) {
            stack.addDeclarationToLast(
                .init(
                    rootItemId: rootItemId,
                    identifier: classDecl.identifier.text,
                    type: .class
                )
            )
        } else if let actorDecl = grandParent.as(ActorDecl.self) {
            stack.addDeclarationToLast(
                .init(
                    rootItemId: rootItemId,
                    identifier: actorDecl.identifier.text,
                    type: .actor
                )
            )
        } else if let structDecl = grandParent.as(StructDecl.self) {
            stack.addDeclarationToLast(
                .init(
                    rootItemId: rootItemId,
                    identifier: structDecl.identifier.text,
                    type: .struct
                )
            )
        } else if let enumDecl = grandParent.as(EnumDecl.self) {
            stack.addDeclarationToLast(
                .init(
                    rootItemId: rootItemId,
                    identifier: enumDecl.identifier.text,
                    type: .enum
                )
            )
        }
        
        return .skipChildren
    }
    
    // MARK: AccessorList
    override func visit(_ node: AccessorList) -> SyntaxVisitorContinueKind {
        pushScope()

        return .visitChildren
    }

    override func visitPost(_ node: AccessorList) {
        popAndAppend()
    }

    // MARK: AccessorDecl
    override func visit(_ node: AccessorDecl) -> SyntaxVisitorContinueKind {
        pushScope()

        return .visitChildren
    }

    override func visitPost(_ node: AccessorDecl) {
        popAndAppend()
    }
    
    // MARK: SequenceExpr
    override func visit(_ node: SequenceExpr) -> SyntaxVisitorContinueKind {
        collectAssignments(from: node)
        return .visitChildren
    }
    
    // MARK: Used Identifier helpers
    private func collectUsedIdentifiers(from codeBlockItem: CodeBlockItem) {
        let usedIdentifiers = identifierExprCollector.collectIdentifiers(from: codeBlockItem).map {
            Scope.IdentifierUsage(
                rootItemId: rootItemId,
                identifier: $0.identifier.text
            )
        }
        stack.addUsedToLast(Set(usedIdentifiers))
    }

    // MARK: Assignment helpers
    private func collectAssignments(from sequenceExpr: SequenceExpr) {
        guard let assignmentInfo = AssignmentInfo(sequenceExpr: sequenceExpr) else {
            return
        }
        stack.addAssignmentToLast(
            .init(
                rootItemId: rootItemId,
                info: assignmentInfo
            )
        )
    }
    
    // MARK: Declaration helpers
    private func collectDeclarations(from parameters: FunctionParameterListSyntax) {
        parameters.forEach {
            stack.addDeclarationToLast(
                .init(
                    rootItemId: rootItemId,
                    identifier: $0.nameIdentifier,
                    type: .variable
                )
            )
        }
    }

    private func collectDeclarations(from closureParameters: ClosureSignatureSyntax.Input) {
        switch closureParameters {
        case let .input(parameters):
            parameters.parameterList.forEach {
                stack.addDeclarationToLast(
                    .init(
                        rootItemId: rootItemId,
                        identifier: $0.nameIdentifier,
                        type: .variable
                    )
                )
            }
        case let .simpleInput(parameters):
            parameters.forEach {
                stack.addDeclarationToLast(
                    .init(
                        rootItemId: rootItemId,
                        identifier: $0.name.text,
                        type: .variable
                    )
                )
            }
        }
    }
    
    private func collectDeclarations(from switchCase: SwitchCaseLabelSyntax) {
        let valueBindings = switchCase.caseItems
            .compactMap { $0.pattern.as(ValueBindingPatternSyntax.self)?.valuePattern ?? $0.pattern }
            .compactMap { $0.as(ExpressionPatternSyntax.self)?.expression.asFunctionCall }
            .compactMap { $0.argumentList.as(TupleExprElementListSyntax.self) }
            .flatMap { $0 }
        return valueBindings
            .compactMap { $0.expression.as(UnresolvedPatternExprSyntax.self) }
            .compactMap { $0.pattern.as(ValueBindingPatternSyntax.self)?.valuePattern ?? $0.pattern }
            .compactMap { $0.as(IdentifierPatternSyntax.self)?.identifier.text }
            .forEach {
                stack.addDeclarationToLast(
                    .init(
                        rootItemId: rootItemId,
                        identifier: $0,
                        type: .variable
                    )
                )
            }
    }

    private func collectDeclarations(from catchClause: CatchClauseSyntax) {
        if let items = catchClause.catchItems {
            items
                .compactMap { $0.pattern?.as(ValueBindingPatternSyntax.self)?.valuePattern }
                .forEach(collectDeclarations(from:))
        } else {
            stack.addDeclarationToLast(
                .init(
                    rootItemId: rootItemId,
                    identifier: "error",
                    type: .variable
                )
            )
        }
    }

    private func collectDeclarations(from conditions: ConditionElementListSyntax) {
        conditions
            .compactMap { $0.condition.as(OptionalBindingConditionSyntax.self)?.pattern }
            .forEach { collectDeclarations(from: $0) }
    }

    private func collectDeclarations(from pattern: PatternSyntax) {
        if let name = pattern.as(IdentifierPatternSyntax.self)?.identifier.text {
            stack.addDeclarationToLast(
                .init(
                    rootItemId: rootItemId,
                    identifier: name,
                    type: .variable
                )
            )
        }
    }
    
    // MARK: Stack helpers
    private func pushScope() {
        stack.addChildScope()
    }

    private func popAndAppend() {
        if let scope = stack.pop() {
            if let outerScope = stack.peek() {
                outerScope.children.append(scope)
            } else {
                self.scope = scope
            }
        }
    }
}

private extension Stack where Element == Scope {
    mutating func addDeclarationToPreviousLast(_ declaration: Scope.Declaration) {
        modifyPreviousToLast { $0.insert(declaration: declaration) }
    }
    
    mutating func addDeclarationToLast(_ declaration: Scope.Declaration) {
        modifyLast { $0.insert(declaration: declaration) }
    }
    
    mutating func addAssignmentToLast(_ assignment: Scope.Assignment) {
        modifyLast { $0.insert(assignment: assignment) }
    }
    
    mutating func addUsedToLast(_ identifiers: Set<Scope.IdentifierUsage>) {
        modifyLast { $0.insert(usedIdentifiers: identifiers) }
    }
    
    mutating func addChildScope() {
        push(Scope())
    }
}
