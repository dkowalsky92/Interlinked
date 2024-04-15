//
//  ParameterClauseFormatter.swift
//  InterlinkedCore
//
//  Created by Dominik Kowalski on 23/05/2023.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import InterlinkedShared

protocol FunctionSignatureFormatterProtocol {
    func format(
        signature: FunctionSignatureSyntax,
        configuration: Configuration,
        shouldIndent: Bool,
        parentIndentation: Int
    ) -> FunctionSignatureSyntax
}

class GoogleStyleParameterClauseFormatter: FunctionSignatureFormatterProtocol {
    func format(
        signature: FunctionSignatureSyntax,
        configuration: Configuration,
        shouldIndent: Bool,
        parentIndentation: Int
    ) -> FunctionSignatureSyntax {
        let parameterList = format(
            parameterList: signature.parameterClause.parameters,
            shouldIndent: shouldIndent,
            spacesPerTab: configuration.spacesPerTab,
            parentIndentation: parentIndentation
        )
        var parameterClause = FunctionParameterClauseSyntax(
            leftParen: signature.parameterClause.leftParen,
            parameters: parameterList,
            rightParen: signature.parameterClause.rightParen
        )
        parameterClause = format(parameterClause: parameterClause, shouldIndent: shouldIndent, parentIndentation: parentIndentation)
        return signature.with(parameterClause: parameterClause)
    }

    private func format(
        parameterList: FunctionParameterListSyntax,
        shouldIndent: Bool,
        spacesPerTab: Int,
        parentIndentation: Int
    ) -> FunctionParameterListSyntax {
        var result = parameterList
        for idx in parameterList.indices {
            let parameter = parameterList[idx]
            let updatedParameter = parameter
                .with(
                    \.leadingTrivia,
                     (shouldIndent ?
                        .newLinesAndSpaces(spaces: parentIndentation + spacesPerTab) :
                        (idx == parameterList.startIndex ? "" : .space)
                     )
                )
                .withTrailingNewLines(lines: 0, indentation: 0)
                .with(\.trailingComma, (idx == parameterList.index(before: parameterList.endIndex) ? nil : .commaToken()))
            result = result.with(\.[idx], updatedParameter)
        }
        return result
    }
    
    private func format(parameterClause: FunctionParameterClauseSyntax, shouldIndent: Bool, parentIndentation: Int) -> FunctionParameterClauseSyntax {
        parameterClause
            .withLeadingNewLines(lines: 0, indentation: 0)
            .withTrailingNewLines(lines: 0, indentation: 0)
            .with(\.rightParen, .rightParenToken(leadingTrivia: shouldIndent ? .newLinesAndSpaces(spaces: parentIndentation) : ""))
    }
}

class AirBnbStyleParameterClauseFormatter: FunctionSignatureFormatterProtocol {
    func format(
        signature: FunctionSignatureSyntax,
        configuration: Configuration,
        shouldIndent: Bool,
        parentIndentation: Int
    ) -> FunctionSignatureSyntax {
        guard 
            let declaration = signature.parent,
            let startToken = declaration.firstToken(viewMode: .sourceAccurate),
            let targetToken = signature.firstToken(viewMode: .sourceAccurate)
        else {
            return signature
        }
        let indentation = startToken.characters(until: targetToken.id) - 1
        let parameterList = format(
            parameterList: signature.parameterClause.parameters,
            shouldIndent: shouldIndent,
            spacesPerTab: configuration.spacesPerTab,
            indentation: indentation
        )
        var parameterClause = FunctionParameterClauseSyntax(
            leftParen: signature.parameterClause.leftParen,
            parameters: parameterList,
            rightParen: signature.parameterClause.rightParen
        )
        parameterClause = format(parameterClause: parameterClause, shouldIndent: shouldIndent)
        return signature.with(parameterClause: parameterClause)
    }
    
    private func format(
        parameterList: FunctionParameterListSyntax,
        shouldIndent: Bool,
        spacesPerTab: Int,
        indentation: Int
    ) -> FunctionParameterListSyntax {
        var result = parameterList
        for idx in parameterList.indices {
            let parameter = parameterList[idx]
            let isFirst = idx == parameterList.startIndex
            let updatedParameter = parameter
                .with(
                    \.leadingTrivia,
                     (shouldIndent ? (isFirst ? "" : .newLinesAndSpaces(spaces: indentation)) : (isFirst ? "" : .space))
                )
                .withTrailingNewLines(lines: 0, indentation: 0)
                .with(\.trailingComma, idx == parameterList.index(before: parameterList.endIndex) ? nil : .commaToken())
            
            result = result.with(\.[idx], updatedParameter)
        }
        return result
    }
    
    private func format(parameterClause: FunctionParameterClauseSyntax, shouldIndent: Bool) -> FunctionParameterClauseSyntax {
        parameterClause
            .withLeadingNewLines(lines: 0, indentation: 0)
            .withTrailingNewLines(lines: 0, indentation: 0)
            .with(\.rightParen, .rightParenToken())
    }
}

class LinkedInStyleParameterClauseFormatter: FunctionSignatureFormatterProtocol {
    func format(
        signature: FunctionSignatureSyntax,
        configuration: Configuration,
        shouldIndent: Bool,
        parentIndentation: Int
    ) -> FunctionSignatureSyntax {
        guard
            let declaration = signature.parent,
            let startToken = declaration.firstToken(viewMode: .sourceAccurate),
            let targetToken = signature.firstToken(viewMode: .sourceAccurate)
        else {
            return signature
        }
        let indentation = startToken.characters(until: targetToken.id) - 2
        let parameterList = format(
            parameterList: signature.parameterClause.parameters,
            shouldIndent: shouldIndent,
            spacesPerTab: configuration.spacesPerTab,
            indentation: indentation
        )
        var parameterClause = FunctionParameterClauseSyntax(
            leftParen: signature.parameterClause.leftParen,
            parameters: parameterList,
            rightParen: signature.parameterClause.rightParen
        )
        parameterClause = format(parameterClause: parameterClause, shouldIndent: shouldIndent, parentIndentation: parentIndentation)
        return signature.with(parameterClause: parameterClause)
    }
    
    private func format(
        parameterList: FunctionParameterListSyntax,
        shouldIndent: Bool,
        spacesPerTab: Int,
        indentation: Int
    ) -> FunctionParameterListSyntax {
        var result = parameterList
        for idx in parameterList.indices {
            let parameter = parameterList[idx]
            let isFirst = idx == parameterList.startIndex
            let updatedParameter = parameter
                .with(
                    \.leadingTrivia,
                     (shouldIndent ? (.newLinesAndSpaces(spaces: indentation)) : (isFirst ? "" : .space))
                )
                .withTrailingNewLines(lines: 0, indentation: 0)
                .with(\.trailingComma, idx == parameterList.index(before: parameterList.endIndex) ? nil : .commaToken())
            
            result = result.with(\.[idx], updatedParameter)
        }
        return result
    }
    
    private func format(parameterClause: FunctionParameterClauseSyntax, shouldIndent: Bool, parentIndentation: Int) -> FunctionParameterClauseSyntax {
        parameterClause
            .withLeadingNewLines(lines: 0, indentation: 0)
            .withTrailingNewLines(lines: 0, indentation: 0)
            .with(\.rightParen, .rightParenToken())
    }
}
