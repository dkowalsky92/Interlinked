//
//  ScopeBuilder.swift
//  InterlinkedCore
//
//  Created by Dominik Kowalski on 12/07/2023.
//

import Foundation
import SwiftSyntax
//import SwiftSyntaxParser
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
        walk(CodeBlockItemListSyntax(codeBlockItems.map { $0.rawItemWithInfo }))
        return scope ?? Scope()
    }
    
    // MARK: CodeBlockItemSyntax
    override func visit(_ node: CodeBlockItemSyntax) -> SyntaxVisitorContinueKind {
        if let positionableCodeBlockItem = PositionableCodeBlockItem(rawItemWithInfo: node) {
            rootItemId = positionableCodeBlockItem.id
        }
        collectUsedIdentifiers(from: node)
        return .visitChildren
    }

    // MARK: CodeBlockItemListSyntax
    override func visit(_ node: CodeBlockItemListSyntax) -> SyntaxVisitorContinueKind {
        if let parent = node.parent, let grandParent = parent.parent {
            if let ifStmt = grandParent.as(IfExprSyntax.self) {
                pushScope()
                collectDeclarations(from: ifStmt.conditions)
            } else if let guardStmt = grandParent.as(GuardStmtSyntax.self) {
                collectDeclarations(from: guardStmt.conditions)
                pushScope()
            } else if let whileStmt = grandParent.as(WhileStmtSyntax.self) {
                pushScope()
                collectDeclarations(from: whileStmt.conditions)
            } else if let pattern = grandParent.as(ForStmtSyntax.self)?.pattern {
                pushScope()
                collectDeclarations(from: pattern)
            } else if let functionDecl = grandParent.as(FunctionDeclSyntax.self) {
                pushScope()
                stack.addDeclarationToPreviousLast(
                    .init(
                        rootItemId: rootItemId,
                        identifier: functionDecl.name.text,
                        type: .function
                    )
                )
                collectDeclarations(from: functionDecl.signature.parameterClause.parameters)
            } else if let closureParameters = parent.as(ClosureExprSyntax.self)?.signature?.parameterClause {
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
    
    override func visitPost(_ node: CodeBlockItemListSyntax) {
        popAndAppend()
    }
    
    // MARK: VariableDeclSyntax
    override open func visitPost(_ node: VariableDeclSyntax) {
        if node.parent?.is(MemberBlockItemSyntax.self) != true {
            for binding in node.bindings {
                collectDeclarations(from: binding.pattern)
            }
        }
    }

    // MARK: Typealias
    override func visit(_ node: TypeAliasDeclSyntax) -> SyntaxVisitorContinueKind {
        stack.addDeclarationToLast(
            .init(
                rootItemId: rootItemId,
                identifier: node.name.text,
                type: .typealias
            )
        )
        
        return .visitChildren
    }
    
    // MARK: MemberBlockItemListSyntax
    override func visit(_ node: MemberBlockItemListSyntax) -> SyntaxVisitorContinueKind {
        guard let parent = node.parent, let grandParent = parent.parent else {
            return .skipChildren
        }
        
        if let classDecl = grandParent.as(ClassDeclSyntax.self) {
            stack.addDeclarationToLast(
                .init(
                    rootItemId: rootItemId,
                    identifier: classDecl.name.text,
                    type: .class
                )
            )
        } else if let actorDecl = grandParent.as(ActorDeclSyntax.self) {
            stack.addDeclarationToLast(
                .init(
                    rootItemId: rootItemId,
                    identifier: actorDecl.name.text,
                    type: .actor
                )
            )
        } else if let structDecl = grandParent.as(StructDeclSyntax.self) {
            stack.addDeclarationToLast(
                .init(
                    rootItemId: rootItemId,
                    identifier: structDecl.name.text,
                    type: .struct
                )
            )
        } else if let enumDecl = grandParent.as(EnumDeclSyntax.self) {
            stack.addDeclarationToLast(
                .init(
                    rootItemId: rootItemId,
                    identifier: enumDecl.name.text,
                    type: .enum
                )
            )
        }
        
        return .skipChildren
    }
    
    // MARK: AccessorListSyntax
    override func visit(_ node: AccessorDeclListSyntax) -> SyntaxVisitorContinueKind {
        pushScope()

        return .visitChildren
    }

    override func visitPost(_ node: AccessorDeclListSyntax) {
        popAndAppend()
    }

    // MARK: AccessorDeclSyntax
    override func visit(_ node: AccessorDeclSyntax) -> SyntaxVisitorContinueKind {
        pushScope()

        return .visitChildren
    }

    override func visitPost(_ node: AccessorDeclSyntax) {
        popAndAppend()
    }
    
    // MARK: SequenceExprSyntax
    override func visit(_ node: SequenceExprSyntax) -> SyntaxVisitorContinueKind {
        collectAssignments(from: node)
        return .visitChildren
    }
    
    // MARK: Used Identifier helpers
    private func collectUsedIdentifiers(from codeBlockItem: CodeBlockItemSyntax) {
        let usedIdentifiers = identifierExprCollector.collectIdentifiers(from: codeBlockItem).map {
            Scope.IdentifierUsage(
                rootItemId: rootItemId,
                identifier: $0.baseName.text
            )
        }
        stack.addUsedToLast(Set(usedIdentifiers))
    }

    // MARK: Assignment helpers
    private func collectAssignments(from sequenceExprSyntax: SequenceExprSyntax) {
        guard let assignmentInfo = AssignmentInfo(sequenceExpr: sequenceExprSyntax) else {
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

    private func collectDeclarations(from closureParameters: ClosureSignatureSyntax.ParameterClause) {
        switch closureParameters {
        case let .parameterClause(parameters):
            parameters.parameters.forEach {
                stack.addDeclarationToLast(
                    .init(
                        rootItemId: rootItemId,
                        identifier: $0.secondName?.textWithoutTrivia ?? $0.firstName.textWithoutTrivia,
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
            .compactMap { $0.pattern.as(ValueBindingPatternSyntax.self)?.pattern ?? $0.pattern }
            .compactMap { $0.as(ExpressionPatternSyntax.self)?.expression.asFunctionCall }
            .compactMap { $0.arguments.as(LabeledExprListSyntax.self) }
            .flatMap { $0 }
        return valueBindings
            .compactMap { $0.expression.as(PatternExprSyntax.self) }
            .compactMap { $0.pattern.as(ValueBindingPatternSyntax.self)?.pattern ?? $0.pattern }
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
        if catchClause.catchItems.isEmpty {
            catchClause.catchItems
                .compactMap { $0.pattern?.as(ValueBindingPatternSyntax.self)?.pattern }
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
