//
//  IndentationReader.swift
//  Interlinked
//
//  Created by Dominik Kowalski on 04/05/2023.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import InterlinkedShared

protocol IndentationReaderProtocol {
    func indentation(configuration: Configuration) -> Int
}

extension TokenSyntax: IndentationReaderProtocol {
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

extension MemberDeclListItem: IndentationReaderProtocol {
    func indentation(configuration: Configuration) -> Int {
        firstToken?.indentation(configuration: configuration) ?? configuration.spacesPerTab
    }
}
