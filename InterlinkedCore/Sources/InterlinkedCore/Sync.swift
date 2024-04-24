//
//  Interlink.swift
//  Interlink
//
//  Created by Dominik Kowalski on 06/05/2023.
//

import Foundation
import InterlinkedShared
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public class Sync {
    private let configuration: Configuration
    private let sourceParser: SourceParser
    private let dependencySyntaxRewriter: SyncingRewriter
    private let formattingRewriter: FormattingRewriter
    
    public init(configuration: Configuration) {
        self.configuration = configuration
        let dependencyCollector = DependencyCollector()
        let identifierFilterers: [IdentifierFilterer] = [
            SelfIdentifierFilterer()
        ]
        let decodableInitializerRecognizer = DecodableInitializerRecognizer()
        let filterInitializerRecognizers: [InitializerRecognizer] = [
            decodableInitializerRecognizer,
            ViewControllerCoderInitializerRecognizer(),
            ConvenienceInitializerRecognizer(),
            OverrideInitializerRecognizer()
        ]
        
        let identifierExprCollector = IdentifierExprCollector(identifierFilterers: identifierFilterers)
        let scopeBuilder = ScopeBuilder(identifierExprCollector: identifierExprCollector)
        let codeBlockItemRelationshipFinder = CodeBlockItemRelationshipFinder(
            identifierFilterers: identifierFilterers,
            initializerScopeBuilder: scopeBuilder
        )
        let unusedParameterRemover = UnusedParameterRemover()
        let unusedDeclarationRemover = UnusedDeclarationRemover(scopeBuilder: scopeBuilder)
        let unusedAssignmentRemover = UnusedAssignmentRemover(scopeBuilder: scopeBuilder)
        let missingParameterAndAssignmentInjector = MissingParameterAndAssignmentInjector(
            scopeBuilder: scopeBuilder,
            codeBlockItemRelationshipFinder: codeBlockItemRelationshipFinder
        )
        let dependencySorter = DependencySorter(
            scopeBuilder: scopeBuilder,
            codeBlockItemRelationshipFinder: codeBlockItemRelationshipFinder
        )
        self.sourceParser = SourceParser()
        self.dependencySyntaxRewriter = SyncingRewriter(
            configuration: configuration,
            dependencyCollector: dependencyCollector,
            unusedAssignmentRemover: unusedAssignmentRemover,
            unusedDeclarationRemover: unusedDeclarationRemover,
            unusedParameterRemover: unusedParameterRemover,
            missingParameterAndAssignmentInjector: missingParameterAndAssignmentInjector,
            dependencySorter: dependencySorter,
            scopeBuilder: scopeBuilder,
            filterInitializerRecognizer: filterInitializerRecognizers,
            decodableInitializerRecognizer: decodableInitializerRecognizer
        )
        let signatureFormatter: FunctionSignatureFormatterProtocol
        switch configuration.formatterStyle {
        case .google:
            signatureFormatter = GoogleStyleParameterClauseFormatter()
        case .airbnb:
            signatureFormatter = AirBnbStyleParameterClauseFormatter()
        case .linkedin:
            signatureFormatter = LinkedInStyleParameterClauseFormatter()
        }
        self.formattingRewriter = FormattingRewriter(configuration: configuration, signatureFormatter: signatureFormatter)
    }
    
    public func sync(input: String) throws -> String {
        let content = try sourceParser.parse(source: input)
        var updatedContent = dependencySyntaxRewriter.visit(content)
        if let err = dependencySyntaxRewriter.error {
            throw err
        }
        updatedContent = formattingRewriter.visit(updatedContent)
        return updatedContent.description
    }
}
