//
//  InitializerFormatter.swift
//  Interlinked
//
//  Created by Dominik Kowalski on 04/05/2023.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import InterlinkedShared

class InitializerFormatter {
    private let parameterClauseFormatter: ParameterClauseFormatterProtocol
    
    init(parameterClauseFormatter: ParameterClauseFormatterProtocol) {
        self.parameterClauseFormatter = parameterClauseFormatter
    }
    
    func format(initializer: InitializerDecl, configuration: Configuration, parentIndentation: Int) -> InitializerDecl {
        guard
            let memberDeclListItem = initializer.parent?.as(MemberDeclListItem.self),
            let memberDeclList = memberDeclListItem.parent?.as(MemberDeclList.self)
        else {
            return initializer
        }
        
        var result = InitializerDecl(
            leadingTrivia: initializer.leadingTrivia,
            attributes: initializer.attributes,
            modifiers:initializer.modifiers,
            initKeyword: initializer.initKeyword,
            optionalMark: initializer.optionalMark,
            genericParameterClause: initializer.genericParameterClause,
            signature: initializer.signature,
            genericWhereClause: initializer.genericWhereClause,
            bodyBuilder: {},
            trailingTrivia: initializer.trailingTrivia
        )
        
        let isLast = memberDeclList.last?.id == memberDeclListItem.id
        let newLineTrailingTriviaPieces: [TriviaPiece] = TriviaPiece.newLinesAndSpaces(lines: isLast ? 1 : 2, spaces: parentIndentation)
        let newLineLeadingTriviaPieces: [TriviaPiece] = TriviaPiece.newLinesAndSpaces(lines: 2, spaces: parentIndentation)
        if let currentLeadingPieces = initializer.leadingTrivia?.pieces {
            if !currentLeadingPieces.contains(where: { $0.isNewline }) {
                result = result.withLeadingTrivia(.init(pieces: currentLeadingPieces + newLineLeadingTriviaPieces))
            }
        } else {
            result = result.withLeadingTrivia(.init(pieces: newLineLeadingTriviaPieces))
        }
        if let currentTrailingPieces = initializer.trailingTrivia?.pieces {
            if !currentTrailingPieces.contains(where: { $0.isNewline }) {
                result = result.withTrailingTrivia(.init(pieces: currentTrailingPieces + newLineTrailingTriviaPieces))
            }
        } else {
            result = result.withTrailingTrivia(.init(pieces: newLineTrailingTriviaPieces))
        }
        
        let shouldIndent = configuration.maxLineLength < initializer.characters(configuration: configuration)
        let parameterClause = parameterClauseFormatter.format(
            parameterClause: result.signature.input,
            configuration: configuration,
            shouldIndent: shouldIndent,
            parentIndentation: parentIndentation
        )
        result.signature = result.signature.with(parameterClause: parameterClause)
        
        if let body = initializer.body {
            let codeBlockItemList = body.statements.format(configuration: configuration, parentIndentation: parentIndentation)
            let codeBlock = CodeBlock(statements: codeBlockItemList).format(configuration: configuration, parentIndentation: parentIndentation)
            result.body = codeBlock
        }
        return result
    }
}
