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
    
    init(configuration: Configuration) {
        self.configuration = configuration
    }
    
    override func visit(_ node: InitializerDecl) -> DeclSyntax {
        var indentation: Int = configuration.spacesPerTab
        if let memberId = node.parent?.parent?.parent?.parent?.id {
            indentation = indentations[memberId] ?? configuration.spacesPerTab
        }
        let formatter = makeFormatter(fromConfiguration: configuration, inInitializer: node)
        let updatedNode = formatter.format(initializer: node, configuration: configuration, parentIndentation: indentation)
        return super.visit(updatedNode)
    }
    
    override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
        indentations[node.id] = (node.firstToken?.indentation(configuration: configuration) ?? 0) + configuration.spacesPerTab
        return super.visit(node)
    }

    override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
        indentations[node.id] = (node.firstToken?.indentation(configuration: configuration) ?? 0) + configuration.spacesPerTab
        return super.visit(node)
    }
    
    override func visit(_ node: ActorDeclSyntax) -> DeclSyntax {
        indentations[node.id] = (node.firstToken?.indentation(configuration: configuration) ?? 0) + configuration.spacesPerTab
        return super.visit(node)
    }
    
    private func makeFormatter(
        fromConfiguration configuration: Configuration,
        inInitializer initializer: InitializerDecl
    ) -> InitializerFormatter {
        switch configuration.formatterStyle {
        case .google:
            return InitializerFormatter(parameterClauseFormatter: GoogleStyleParameterClauseFormatter())
        case .airbnb:
            return InitializerFormatter(parameterClauseFormatter: AirBnbStyleParameterClauseFormatter())
        case .linkedin:
            return InitializerFormatter(parameterClauseFormatter: LinkedInStyleParameterClauseFormatter())
        }
    }
}
