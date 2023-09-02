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

protocol ParameterClauseFormatterProtocol {
    func format(
        parameterClause: ParameterClause,
        configuration: Configuration,
        shouldIndent: Bool,
        parentIndentation: Int
    ) -> ParameterClause
}

class GoogleStyleParameterClauseFormatter: ParameterClauseFormatterProtocol {
    func format(
        parameterClause: ParameterClause,
        configuration: Configuration,
        shouldIndent: Bool,
        parentIndentation: Int
    ) -> ParameterClause {
        let parameterList = format(
            parameterList: parameterClause.parameterList,
            shouldIndent: shouldIndent,
            spacesPerTab: configuration.spacesPerTab,
            parentIndentation: parentIndentation
        )
        let parameterClause = ParameterClause(
            leftParen: parameterClause.leftParen,
            rightParen: parameterClause.rightParen,
            parameterListBuilder: {
                parameterList
            }
        )
        return format(parameterClause: parameterClause, shouldIndent: shouldIndent, parentIndentation: parentIndentation)
    }
    
    private func format(
        parameterList: FunctionParameterList,
        shouldIndent: Bool,
        spacesPerTab: Int,
        parentIndentation: Int
    ) -> FunctionParameterList {
        var result = parameterList
        for (idx, parameter) in parameterList.enumerated() {
            result = result.replacing(
                childAt: idx,
                with: parameter
                    .withLeadingTrivia(shouldIndent ? .newLinesAndSpaces(spaces: parentIndentation + spacesPerTab) : (idx == 0 ? .zero : .space))
                    .withoutTrailingTrivia()
                    .withTrailingComma(idx == parameterList.count - 1 ? nil : .comma)
            )
        }
        return result
    }
    
    private func format(parameterClause: ParameterClause, shouldIndent: Bool, parentIndentation: Int) -> ParameterClause {
        parameterClause
            .withoutLeadingTrivia()
            .withoutTrailingTrivia()
            .withRightParen(.rightParenToken(leadingTrivia: shouldIndent ? .newLinesAndSpaces(spaces: parentIndentation) : .zero))
    }
}

class AirBnbStyleParameterClauseFormatter: ParameterClauseFormatterProtocol {
    func format(
        parameterClause: ParameterClause,
        configuration: Configuration,
        shouldIndent: Bool,
        parentIndentation: Int
    ) -> ParameterClause {
        let parameterList = format(
            parameterList: parameterClause.parameterList,
            shouldIndent: shouldIndent,
            spacesPerTab: configuration.spacesPerTab,
            parentIndentation: parentIndentation
        )
        let parameterClause = ParameterClause(
            leftParen: parameterClause.leftParen,
            rightParen: parameterClause.rightParen,
            parameterListBuilder: {
                parameterList
            }
        )
        return format(parameterClause: parameterClause, shouldIndent: shouldIndent, parentIndentation: parentIndentation)
    }
    
    private func format(
        parameterList: FunctionParameterList,
        shouldIndent: Bool,
        spacesPerTab: Int,
        parentIndentation: Int
    ) -> FunctionParameterList {
        var result = parameterList
        for (idx, parameter) in parameterList.enumerated() {
            result = result.replacing(
                childAt: idx,
                with: parameter
                    .withLeadingTrivia(shouldIndent ? .newLinesAndSpaces(spaces: parentIndentation + spacesPerTab) : (idx == 0 ? .zero : .space))
                    .withoutTrailingTrivia()
                    .withTrailingComma(idx == parameterList.count - 1 ? nil : .comma)
            )
        }
        return result
    }
    
    private func format(parameterClause: ParameterClause, shouldIndent: Bool, parentIndentation: Int) -> ParameterClause {
        parameterClause
            .withoutLeadingTrivia()
            .withoutTrailingTrivia()
            .withRightParen(.rightParen)
    }
}

class LinkedInStyleParameterClauseFormatter: ParameterClauseFormatterProtocol {
    func format(
        parameterClause: ParameterClause,
        configuration: Configuration,
        shouldIndent: Bool,
        parentIndentation: Int
    ) -> ParameterClause {
        let parameterList = format(
            parameterList: parameterClause.parameterList,
            shouldIndent: shouldIndent,
            spacesPerTab: configuration.spacesPerTab,
            parentIndentation: parentIndentation
        )
        let parameterClause = ParameterClause(
            leftParen: parameterClause.leftParen,
            rightParen: parameterClause.rightParen,
            parameterListBuilder: {
                parameterList
            }
        )
        return format(parameterClause: parameterClause, shouldIndent: shouldIndent, parentIndentation: parentIndentation)
    }
    
    private func format(
        parameterList: FunctionParameterList,
        shouldIndent: Bool,
        spacesPerTab: Int,
        parentIndentation: Int
    ) -> FunctionParameterList {
        var result = parameterList
        for (idx, parameter) in parameterList.enumerated() {
            result = result.replacing(
                childAt: idx,
                with: parameter
                    .withLeadingTrivia(idx == 0 ? .zero : (shouldIndent ? .newLinesAndSpaces(spaces: parentIndentation + spacesPerTab + 1) : .space))
                    .withoutTrailingTrivia()
                    .withTrailingComma(idx == parameterList.count - 1 ? nil : .comma)
            )
        }
        return result
    }
    
    private func format(parameterClause: ParameterClause, shouldIndent: Bool, parentIndentation: Int) -> ParameterClause {
        parameterClause
            .withoutLeadingTrivia()
            .withoutTrailingTrivia()
            .withRightParen(.rightParen)
    }
}
