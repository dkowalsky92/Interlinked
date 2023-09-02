//
//  Interlink.swift
//  Interlink
//
//  Created by Dominik Kowalski on 06/05/2023.
//

import Foundation
import InterlinkedShared

public class Interlink {
    private let configuration: Configuration
    private let sourceParser: SourceParser
    private let dependencySyntaxRewriter: DependencyRewriter
    private let formatterSyntaxRewriter: FormattingRewriter
    
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
            ConvenienceInitializerRecognizer()
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
        self.dependencySyntaxRewriter = DependencyRewriter(
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
        self.formatterSyntaxRewriter = FormattingRewriter(configuration: configuration)
    }
    
    public func interlink(input: String) throws -> String {
        let sourceFile = try sourceParser.parse(source: input)
        let updated = dependencySyntaxRewriter.visit(sourceFile)
        if let err = dependencySyntaxRewriter.error {
            throw err
        }
        let formatted = formatterSyntaxRewriter.visit(updated)
        return formatted.description
    }
}
