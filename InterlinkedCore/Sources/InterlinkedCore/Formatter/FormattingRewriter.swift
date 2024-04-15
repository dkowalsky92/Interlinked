//
//  FormattingRewriter.swift
//  Interlinked
//
//  Created by Dominik Kowalski on 04/05/2023.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import InterlinkedShared

class FormattingRewriter: SyntaxRewriter {
    private let configuration: Configuration
    private var indentations: [SyntaxIdentifier: Int] = [:]
    private let signatureFormatter: FunctionSignatureFormatterProtocol
    
    init(configuration: Configuration, signatureFormatter: FunctionSignatureFormatterProtocol) {
        self.configuration = configuration
        self.signatureFormatter = signatureFormatter
    }

    override func visit(_ node: InitializerDeclSyntax) -> DeclSyntax {
        let indentations = indentations(node: node)
        let parentIndentation = indentations.0
        let childIndentation = indentations.1
        let shouldIndent = configuration.maxLineLength < node.characters(configuration: configuration)
        let signature = signatureFormatter.format(
            signature: node.signature,
            configuration: configuration,
            shouldIndent: shouldIndent,
            parentIndentation: parentIndentation
        )
        let result = node
            .with(\.signature, signature)
            .with(\.body, node.body?.format(indentation: parentIndentation, childIndentation: childIndentation))
        return super.visit(result)
    }
    
    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        let indentations = indentations(node: node)
        let parentIndentation = indentations.0
        let childIndentation = indentations.1
        let shouldIndent = configuration.maxLineLength < node.characters(configuration: configuration)
        let signature = signatureFormatter.format(
            signature: node.signature,
            configuration: configuration,
            shouldIndent: shouldIndent,
            parentIndentation: parentIndentation
        )
        let result = node
            .with(\.signature, signature)
            .with(\.body, node.body?.format(indentation: parentIndentation, childIndentation: childIndentation))
        return super.visit(result)
    }
    
    override func visit(_ node: MemberBlockItemSyntax) -> MemberBlockItemSyntax {
        guard
            node.decl.is(FunctionDeclSyntax.self) || node.decl.is(InitializerDeclSyntax.self),
            shouldChangeTrivia(node: node),
            let list = node.parent?.as(MemberBlockItemListSyntax.self)
        else {
            return super.visit(node)
        }
        let indentations = indentations(node: node.decl)
        let result = node
            .withLeadingNewLines(lines: list.isFirst(item: node) ? 1 : 2, indentation: indentations.0)
            .withTrailingNewLines(lines: 0, indentation: 0)
        return super.visit(result)
    }
    
    override func visit(_ node: MemberBlockSyntax) -> MemberBlockSyntax {
        let indentation = (node.parent?.firstToken(viewMode: .sourceAccurate)?.indentation(configuration: configuration) ?? 0)
        return super.visit(node.format(indentation: indentation))
    }
    
    private func shouldChangeTrivia(node: SyntaxProtocol) -> Bool {
        guard
            let declaration = node.parent?.parent?.parent
        else {
            return false
        }
        return declaration.is(StructDeclSyntax.self) || declaration.is(ActorDeclSyntax.self) || declaration.is(ClassDeclSyntax.self)
    }

    private func indentations(node: SyntaxProtocol) -> (Int, Int) {
        if let memberBlockParent = memberBlockParent(node: node) {
            let list = memberBlockParent.1
            let indentation = (list.parent?.parent?.firstToken(viewMode: .sourceAccurate)?.indentation(configuration: configuration) ?? 0) + configuration.spacesPerTab
            let childIndentation = indentation + configuration.spacesPerTab
            return (indentation, childIndentation)
        } else if let codeBlockParent = codeBlockParent(node: node) {
            let list = codeBlockParent.1
            if list.parent?.is(SourceFileSyntax.self) == true {
                let indentation = (list.parent?.firstToken(viewMode: .sourceAccurate)?.indentation(configuration: configuration) ?? 0)
                let childIndentation = indentation + configuration.spacesPerTab
                return (indentation, childIndentation)
            } else {
                let indentation = (list.parent?.parent?.firstToken(viewMode: .sourceAccurate)?.indentation(configuration: configuration) ?? 0) + configuration.spacesPerTab
                let childIndentation = indentation + configuration.spacesPerTab
                return (indentation, childIndentation)
            }
        } else {
            return (0, 0)
        }
    }
    
    private func memberBlockParent(node: SyntaxProtocol) -> (MemberBlockItemSyntax, MemberBlockItemListSyntax)? {
        guard
            let memberBlockItem = node.parent?.as(MemberBlockItemSyntax.self),
            let memberBlockList = memberBlockItem.parent?.as(MemberBlockItemListSyntax.self)
        else {
            return nil
        }
        return (memberBlockItem, memberBlockList)
    }
    
    private func codeBlockParent(node: SyntaxProtocol) -> (CodeBlockItemSyntax, CodeBlockItemListSyntax)? {
        guard
            let codeBlockItem = node.parent?.as(CodeBlockItemSyntax.self),
            let codeBlockList = codeBlockItem.parent?.as(CodeBlockItemListSyntax.self)
        else {
            return nil
        }
        return (codeBlockItem, codeBlockList)
    }
}
