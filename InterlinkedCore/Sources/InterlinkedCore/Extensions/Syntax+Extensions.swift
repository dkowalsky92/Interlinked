//
//  Syntax+Extensions.swift
//  Interlinked
//
//  Created by Dominik Kowalski on 04/05/2023.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder

import InterlinkedShared

extension SyntaxProtocol {
    var textWithoutTrivia: String {
        trimmed.trimmedDescription
    }
    
    func withLeadingNewLines(lines: Int = 1, indentation: Int) -> Self {
        guard leadingTrivia.allSatisfy({ $0.isWhitespace }) else {
            return self
        }
        return with(\.leadingTrivia, .newLinesAndSpaces(lines: lines, spaces: indentation))
    }
    
    func withTrailingNewLines(lines: Int = 1, indentation: Int) -> Self {
        guard trailingTrivia.allSatisfy({ $0.isWhitespace }) else {
            return self
        }
        return with(\.trailingTrivia, .newLinesAndSpaces(lines: lines, spaces: indentation))
    }
    
    func indentation(configuration: Configuration) -> Int {
        var count = 0
        for piece in leadingTrivia.reversed() {
            if piece.isNewline {
                break
            } else {
                count += piece.sourceLength.utf8Length
            }
        }
        return count
    }
}

extension TokenSyntax {
    func characters(until nodeId: SyntaxIdentifier) -> Int {
        guard id != nodeId else {
            return 0
        }
        var count = totalLength.utf8Length
        var current = self
        while let next = current.nextToken(viewMode: .sourceAccurate), next.id != nodeId {
            count += next.totalLength.utf8Length
            current = next
        }
        return count
    }
}

extension TypeSyntax {
    var unwrappedType: TypeSyntax {
        if let tuple = self.as(TupleTypeSyntax.self), let firstElement = tuple.elements.first {
            return firstElement.type.unwrappedType
        } else if let attributed = self.as(AttributedTypeSyntax.self) {
            return attributed.baseType.unwrappedType
        } else if let optional = self.as(OptionalTypeSyntax.self) {
            return optional.wrappedType.unwrappedType
        } else if let unwrappedOptional = self.as(ImplicitlyUnwrappedOptionalTypeSyntax.self) {
            return unwrappedOptional.wrappedType.unwrappedType
        } else {
            return self
        }
    }
}

extension AttributeListSyntax {
    static var escaping: AttributeListSyntax {
        AttributeListSyntax {
            .attribute(AttributeSyntax(.init(stringLiteral: "escaping")))
        }
        .with(\.trailingTrivia, .space)
    }
}

extension PatternBindingSyntax {
    var nameIdentifier: String {
        pattern.textWithoutTrivia
    }
}

extension FunctionParameterSyntax {
    var nameIdentifier: String {
        secondName?.textWithoutTrivia ?? firstName.textWithoutTrivia
    }
    
    init(name: String, type: TypeSyntaxProtocol) {
        self.init(
            attributes: [],
            modifiers: [],
            firstName: .identifier(name),
            secondName: nil,
            colon: .colonToken(trailingTrivia: .space),
            type: type
        )
    }
}

extension FunctionSignatureSyntax {
    func with(parameterClause: FunctionParameterClauseSyntax) -> Self {
        let asyncSpecifier = effectSpecifiers?.asyncSpecifier?.with(\.leadingTrivia, "").with(\.trailingTrivia, .space)
        let throwsSpecifier = effectSpecifiers?.throwsSpecifier?.with(\.leadingTrivia, "").with(\.trailingTrivia, .space)
        return FunctionSignatureSyntax(
            parameterClause: parameterClause.with(\.trailingTrivia, .space),
            effectSpecifiers: .init(asyncSpecifier: asyncSpecifier, throwsSpecifier: throwsSpecifier),
            returnClause: returnClause
        )
    }
}

extension ExprSyntax {
    var asFunctionCall: FunctionCallExprSyntax? {
        if let functionCall = self.as(FunctionCallExprSyntax.self) {
            return functionCall
        } else if let tuple = self.as(TupleExprSyntax.self),
                  let firstElement = tuple.elements.first,
                  let functionCall = firstElement.expression.as(FunctionCallExprSyntax.self) {
            return functionCall
        } else {
            return nil
        }
    }
}

extension FunctionCallExprSyntax {
    var rootDecl: DeclReferenceExprSyntax? {
        calledExpression.as(DeclReferenceExprSyntax.self)
    }
}

extension SubscriptCallExprSyntax {
    var rootDecl: DeclReferenceExprSyntax? {
        calledExpression.as(DeclReferenceExprSyntax.self)
    }
}

extension MemberAccessExprSyntax {
    var rootDecl: DeclReferenceExprSyntax? {
        if let memberAccessExpr = base?.as(MemberAccessExprSyntax.self) {
            return memberAccessExpr.rootDecl
        } else if let functionCallExpr = base?.as(FunctionCallExprSyntax.self) {
            return functionCallExpr.rootDecl
        } else if let subscriptCallExpr = base?.as(SubscriptCallExprSyntax.self) {
            return subscriptCallExpr.rootDecl
        } else if let declReference = base?.as(DeclReferenceExprSyntax.self) {
            return declReference
        }
        return nil
    }
}

extension CodeBlockItemSyntax {
    var isAssignment: Bool {
        sequenceExprSyntax != nil
    }
    
    var sequenceExprSyntax: SequenceExprSyntax? {
        guard
            case .expr(let item) = item,
            let sequenceExprSyntax = item.as(SequenceExprSyntax.self)
        else {
            return nil
        }
        return sequenceExprSyntax
    }

    init(assignee: String, assigner: String) {
        let memberAccessExpr = MemberAccessExprSyntax(
            base: DeclReferenceExprSyntax(baseName: .keyword(.`self`)),
            declName: DeclReferenceExprSyntax(baseName: .identifier(assignee))
        )
        let assignmentExprSyntax = AssignmentExprSyntax(leadingTrivia: .space, trailingTrivia: .space)
        let identifierExpr = DeclReferenceExprSyntax(baseName: .identifier(assigner))
        let exprList = ExprListSyntax {
            memberAccessExpr
            assignmentExprSyntax
            identifierExpr
        }
        let sequenceExprSyntax = SequenceExprSyntax(elements: exprList).cast(ExprSyntax.self)
        self.init(item: .expr(sequenceExprSyntax))
    }
    
    var fromRawInfoOrNew: PositionableCodeBlockItem {
        if let item = PositionableCodeBlockItem(rawItemWithInfo: self) {
            return item
        } else {
            guard
                let list = item.parent?.as(CodeBlockItemListSyntax.self),
                let index = list.firstIndex(of: self)
            else {
                return PositionableCodeBlockItem(id: 0, item: self)
            }
            return PositionableCodeBlockItem(id: list.distance(from: list.startIndex, to: index), item: self)
        }
    }
}

extension InitializerDeclSyntax {
    static var empty: Self {
        InitializerDeclSyntax(signature: .init(parameterClause: .init(parameters: .init(itemsBuilder: {}))))
    }
    
    var withEmptyContent: Self {
        let parameterList = signature.parameterClause.with(\.parameters, [])
        var result = self
        result.signature.parameterClause = parameterList
        result.body = result.body?.with(\.statements, [])
        return result
    }
    
    func characters(configuration: Configuration) -> Int {
        let initSize: Int
        if let firstToken = firstToken(viewMode: .sourceAccurate) {
            initSize = firstToken.indentation(configuration: configuration) + firstToken.trimmedLength.utf8Length
        } else {
            initSize = 0
        }
        let signatureSize = signature.totalLength.utf8Length
        let rightBraceSize = body?.rightBrace.totalLength.utf8Length ?? 0
        return initSize + signatureSize + rightBraceSize
    }
    
    var containsParameters: Bool {
        signature.parameterClause.parameters.isEmpty == false
    }
    
    var containsBody: Bool {
        body?.statements.isEmpty == false
    }

    func parameter(forName name: String, type: String? = nil) -> FunctionParameterSyntax? {
        signature.parameterClause.parameters.first(where: {
            if let type {
                return $0.nameIdentifier == name && $0.type.unwrappedType.textWithoutTrivia == type
            } else {
                return $0.nameIdentifier == name
            }
        })
    }
}

extension FunctionDeclSyntax {
    func characters(configuration: Configuration) -> Int {
        let funcSize: Int
        if let firstToken = firstToken(viewMode: .sourceAccurate) {
            funcSize = firstToken.indentation(configuration: configuration) + firstToken.trimmedLength.utf8Length
        } else {
            funcSize = 0
        }
        let signatureSize = signature.totalLength.utf8Length
        let rightBraceSize = body?.rightBrace.totalLength.utf8Length ?? 0
        return funcSize + signatureSize + rightBraceSize
    }
}

extension VariableDeclSyntax {
    var isSet: Bool {
        !bindings.allSatisfy({ $0.initializer == nil })
    }
    
    var isOptionalVariable: Bool {
        guard bindingSpecifier.tokenKind == .keyword(.var) else {
            return false
        }
        guard let type = bindings.last?.typeAnnotation?.type else {
            return false
        }
        return type.is(OptionalTypeSyntax.self) || type.is(ImplicitlyUnwrappedOptionalTypeSyntax.self)
    }
    
    var isComputedVariable: Bool {
        if let accessor = bindings.last?.accessorBlock?.accessors {
            switch accessor {
            case .accessors(let accessorBlock):
                return accessorBlock.allSatisfy({
                    $0.accessorSpecifier.textWithoutTrivia != "didSet" && $0.accessorSpecifier.textWithoutTrivia != "willSet"
                })
            case .getter:
                return true
            }
        } else if modifiers.contains(where: { $0.name.textWithoutTrivia == "lazy" }) {
            return true
        } else if attributes.contains(where: {
            guard case .`attribute`(let attribute) = $0 else {
                return false
            }
            let name = attribute.attributeName.textWithoutTrivia
            return name == "EnvironmentObject" || name == "StateObject" || name == "Environment" || name == "Query"
        }) {
            return true
        } else {
            return false
        }
    }
}

extension Trivia {
    static func newLinesAndSpaces(lines: Int = 1, spaces: Int) -> Trivia {
        .init(pieces: TriviaPiece.newLinesAndSpaces(lines: lines, spaces: spaces))
    }
}

extension TriviaPiece {
    var isSpaces: Bool {
        guard case .spaces = self else {
            return false
        }
        return true
    }
    
    var isTabs: Bool {
        guard case .tabs = self else {
            return false
        }
        return true
    }
    
    static func newLinesAndSpaces(lines: Int = 1, spaces: Int) -> [TriviaPiece] {
        [.newlines(lines), .spaces(spaces)]
    }
}

extension CodeBlockItemListSyntax {
    func format(indentation: Int) -> Self {
        var result = self
        for idx in indices {
            let codeBlockItem = self[idx]
            result = result.with(
                \.[idx],
                codeBlockItem
                    .withLeadingNewLines(lines: 1, indentation: indentation)
                    .withTrailingNewLines(lines: 0, indentation: 0)
            )
        }
        return result
    }
    
    func isLast(item: CodeBlockItemSyntax) -> Bool {
        index(of: item) == index(before: endIndex)
    }
    
    func isFirst(item: CodeBlockItemSyntax) -> Bool {
        index(of: item) == startIndex
    }
}

extension CodeBlockSyntax {
    func format(indentation: Int, childIndentation: Int) -> Self {
        func commonFormat(node: CodeBlockSyntax, indentation: Int, lines: Int) -> CodeBlockSyntax {
            node
                .withLeadingNewLines(lines: 0, indentation: 0)
                .with(\.trailingTrivia, "")
                .with(
                    \.rightBrace,
                    .rightBraceToken(leadingTrivia: .newLinesAndSpaces(lines: lines, spaces: indentation))
                )
        }
        guard !statements.isEmpty else {
            return commonFormat(node: self, indentation: indentation, lines: 2)
        }
        return commonFormat(node: self, indentation: indentation, lines: 1)
            .with(
                \.statements,
                 statements.format(indentation: childIndentation)
            )
    }
}

extension MemberBlockItemListSyntax {
    func isLast(item: MemberBlockItemSyntax) -> Bool {
        index(of: item) == index(before: endIndex)
    }
    
    func isFirst(item: MemberBlockItemSyntax) -> Bool {
        index(of: item) == startIndex
    }
}

extension MemberBlockSyntax {
    func format(indentation: Int) -> Self {
        func commonFormat(node: MemberBlockSyntax, indentation: Int, lines: Int) -> MemberBlockSyntax {
            node
                .withLeadingNewLines(lines: 0, indentation: 0)
                .withTrailingNewLines(lines: 0, indentation: 0)
                .with(
                    \.rightBrace,
                     node.rightBrace.withLeadingNewLines(lines: lines, indentation: indentation)
                )
        }
        guard !members.isEmpty else {
            return commonFormat(node: self, indentation: indentation, lines: 2)
        }
        return commonFormat(node: self, indentation: indentation, lines: 1)
    }
}
