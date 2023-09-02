//
//  Syntax+Extensions.swift
//  Interlinked
//
//  Created by Dominik Kowalski on 04/05/2023.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxParser
import InterlinkedShared

extension SyntaxProtocol {
    var textWithoutTrivia: String {
        if let token = self.as(TokenSyntax.self) {
            return token.text
        } else {
            var result = ""
            for node in children(viewMode: .fixedUp) {
                if let token = node.as(TokenSyntax.self) {
                    result += token.text
                } else {
                    result += node.textWithoutTrivia
                }
            }
            return result
        }
    }
}

extension TypeSyntax {
    var unwrappedType: TypeSyntax {
        if let tuple = self.as(TupleType.self), let firstElement = tuple.elements.first {
            return firstElement.type.unwrappedType
        } else if let attributed = self.as(AttributedType.self) {
            return attributed.baseType.unwrappedType
        } else if let optional = self.as(OptionalType.self) {
            return optional.wrappedType.unwrappedType
        } else if let unwrappedOptional = self.as(ImplicitlyUnwrappedOptionalType.self) {
            return unwrappedOptional.wrappedType.unwrappedType
        } else {
            return self
        }
    }
}

extension AttributeList {
    static var escaping: AttributeList {
        AttributeList {
            .attribute(.init(attributeName: .identifier("escaping")))
        }
        .withTrailingTrivia(.space)
    }
}

extension PatternBinding {
    var nameIdentifier: String {
        pattern.textWithoutTrivia
    }
}

extension FunctionParameter {
    var nameIdentifier: String {
        secondName?.textWithoutTrivia ?? firstName?.textWithoutTrivia ?? ""
    }
    
    init(name: String, type: TypeSyntaxProtocol, isEscaping: Bool = false) {
        var resultType = type
        if isEscaping {
            resultType = AttributedType(attributes: .escaping, baseType: type)
        }
        self.init(
            attributes: nil,
            modifiers: nil,
            firstName: .identifier(name),
            secondName: nil,
            colon: .colonToken(trailingTrivia: .space),
            type: resultType,
            ellipsis: nil,
            defaultArgument: nil
        )
    }
}

extension FunctionSignature {
    func with(parameterClause: ParameterClause) -> Self {
        FunctionSignature(
            input: parameterClause,
            asyncOrReasyncKeyword: asyncOrReasyncKeyword?.withLeadingTrivia(.space).withoutTrailingTrivia(),
            throwsOrRethrowsKeyword: throwsOrRethrowsKeyword?.withLeadingTrivia(.space).withoutTrailingTrivia(),
            output: output
        )
    }
}

extension ExprSyntax {
    var asFunctionCall: FunctionCallExprSyntax? {
        if let functionCall = self.as(FunctionCallExprSyntax.self) {
            return functionCall
        } else if let tuple = self.as(TupleExprSyntax.self),
                  let firstElement = tuple.elementList.first,
                  let functionCall = firstElement.expression.as(FunctionCallExprSyntax.self) {
            return functionCall
        } else {
            return nil
        }
    }
}

extension CodeBlockItem {
    var isAssignment: Bool {
        sequenceExpr != nil
    }
    
    var sequenceExpr: SequenceExpr? {
        guard
            case .expr(let item) = item,
            let sequenceExpr = item.as(SequenceExpr.self)
        else {
            return nil
        }
        return sequenceExpr
    }

    init(name: String) {
        let memberAccessExpr = MemberAccessExpr(
            base: IdentifierExpr(identifier: .`self`),
            dot: .period,
            name: .identifier(name)
        )
        let assignmentExpr = AssignmentExpr(leadingTrivia: .space, trailingTrivia: .space)
        let identifierExpr = IdentifierExpr(identifier: .identifier(name))
        let exprList = ExprList {
            memberAccessExpr
            assignmentExpr
            identifierExpr
        }
        let sequenceExpr = SequenceExpr(elements: exprList).cast(ExprSyntax.self)
        self.init(item: .expr(sequenceExpr))
    }
    
    var fromRawInfoOrNew: PositionableCodeBlockItem {
        PositionableCodeBlockItem(rawItemWithInfo: self) ?? PositionableCodeBlockItem(id: indexInParent, item: self)
    }
}

extension InitializerDecl {
    static var empty: Self {
        InitializerDecl(signature: FunctionSignature(input: ParameterClause(parameterList: [])), bodyBuilder: {})
    }
    
    var withEmptyContent: Self {
        let parameterList = signature.input.withParameterList(nil)
        var result = self
        result.signature.input = parameterList
        result.body = result.body?.withStatements(nil)
        return result
    }
    
    func characters(configuration: Configuration) -> Int {
        let initSize: Int
        if let firstToken {
            initSize = firstToken.indentation(configuration: configuration) + firstToken.byteSizeAfterTrimmingTrivia
        } else {
            initSize = 0
        }
        let signatureSize = signature.byteSize
        let rightBraceSize = body?.rightBrace.byteSize ?? 0
        return initSize + signatureSize + rightBraceSize
    }
    
    var containsParameters: Bool {
        signature.input.parameterList.isEmpty == false
    }
    
    var containsBody: Bool {
        body?.statements.isEmpty == false
    }

    func parameter(forName name: String, type: String? = nil) -> FunctionParameter? {
        signature.input.parameterList.first(where: {
            if let type {
                return $0.nameIdentifier == name && $0.type?.unwrappedType.textWithoutTrivia == type
            } else {
                return $0.nameIdentifier == name
            }
        })
    }
}

extension VariableDecl {
    var isSet: Bool {
        !bindings.allSatisfy({ $0.initializer == nil })
    }
    
    var isOptionalVariable: Bool {
        guard letOrVarKeyword.tokenKind == .varKeyword else {
            return false
        }
        guard let type = bindings.last?.typeAnnotation?.type else {
            return false
        }
        return type.is(OptionalType.self) || type.is(ImplicitlyUnwrappedOptionalType.self)
    }
    
    var isComputedVariable: Bool {
        if let accessor = bindings.last?.accessor {
            switch accessor {
            case .accessors(let accessorBlock):
                return accessorBlock.accessors.allSatisfy({
                    $0.accessorKind.textWithoutTrivia != "didSet" && $0.accessorKind.textWithoutTrivia != "willSet"
                })
            case .getter:
                return true
            }
        } else if let isLazy = modifiers?.contains(where: { $0.name.textWithoutTrivia == "lazy" }), isLazy {
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

extension CodeBlock {
    func format(configuration: Configuration, parentIndentation: Int) -> Self {
        self
            .withLeadingTrivia(.space)
            .withoutTrailingTrivia()
            .withRightBrace(.rightBraceToken(leadingTrivia: .newLinesAndSpaces(spaces: parentIndentation)))
    }
}

extension CodeBlockItemList {
    func format(configuration: Configuration, parentIndentation: Int) -> Self {
        var result = self
        for (idx, codeBlockItem) in enumerated() {
            if !codeBlockItem.isAssignment {
                let leadingTrivia: [TriviaPiece] = codeBlockItem.leadingTrivia?.pieces ?? TriviaPiece.newLinesAndSpaces(spaces: parentIndentation + configuration.spacesPerTab)
                result = result.replacing(
                    childAt: idx,
                    with: codeBlockItem.withLeadingTrivia(.init(pieces: leadingTrivia)).withoutTrailingTrivia()
                )
            } else {
                result = result.replacing(
                    childAt: idx,
                    with: codeBlockItem.withLeadingTrivia(.newLinesAndSpaces(spaces: parentIndentation + configuration.spacesPerTab)).withoutTrailingTrivia()
                )
            }
        }
        return result
    }
}
