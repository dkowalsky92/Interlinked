//
//  DependencyRewriter.swift
//  Interlinked
//
//  Created by Dominik Kowalski on 30/04/2023.
//

import Foundation
import SwiftSyntaxBuilder
import SwiftSyntax
import InterlinkedShared
import OSLog

class DependencyRewriter: SyntaxRewriter {
    private let configuration: Configuration
    private let dependencyCollector: DependencyCollector
    private let unusedAssignmentRemover: UnusedAssignmentRemover
    private let unusedDeclarationRemover: UnusedDeclarationRemover
    private let unusedParameterRemover: UnusedParameterRemover
    private let missingParameterAndAssignmentInjector: MissingParameterAndAssignmentInjector
    private let dependencySorter: DependencySorter
    private let scopeBuilder: ScopeBuilder
    private let filterInitializerRecognizer: [InitializerRecognizer]
    private let decodableInitializerRecognizer: InitializerRecognizer
    
    var error: Error?
    
    init(
        configuration: Configuration,
        dependencyCollector: DependencyCollector,
        unusedAssignmentRemover: UnusedAssignmentRemover,
        unusedDeclarationRemover: UnusedDeclarationRemover,
        unusedParameterRemover: UnusedParameterRemover,
        missingParameterAndAssignmentInjector: MissingParameterAndAssignmentInjector,
        dependencySorter: DependencySorter,
        scopeBuilder: ScopeBuilder,
        filterInitializerRecognizer: [InitializerRecognizer],
        decodableInitializerRecognizer: InitializerRecognizer
    ) {
        self.configuration = configuration
        self.dependencyCollector = dependencyCollector
        self.unusedAssignmentRemover = unusedAssignmentRemover
        self.unusedDeclarationRemover = unusedDeclarationRemover
        self.unusedParameterRemover = unusedParameterRemover
        self.missingParameterAndAssignmentInjector = missingParameterAndAssignmentInjector
        self.dependencySorter = dependencySorter
        self.scopeBuilder = scopeBuilder
        self.filterInitializerRecognizer = filterInitializerRecognizer
        self.decodableInitializerRecognizer = decodableInitializerRecognizer
    }
    
    override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
        do {
            let memberDeclBlock = try withUpdatedMemberBlock(node.members)
            return super.visit(node.withMembers(memberDeclBlock))
        } catch {
            self.error = error
            return super.visit(node)
        }
    }

    override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
        do {
            let memberDeclBlock = try withUpdatedMemberBlock(node.members)
            return super.visit(node.withMembers(memberDeclBlock))
        } catch {
            self.error = error
            return super.visit(node)
        }
    }
    
    override func visit(_ node: ActorDeclSyntax) -> DeclSyntax {
        do {
            let memberDeclBlock = try withUpdatedMemberBlock(node.members)
            return super.visit(node.withMembers(memberDeclBlock))
        } catch {
            self.error = error
            return super.visit(node)
        }
    }
    
    private func withUpdatedMemberBlock(_ memberBlock: MemberDeclBlockSyntax) throws -> MemberDeclBlockSyntax {
        var result = memberBlock
        let cache = buildInitializerCache(members: memberBlock.members)
        var initializerCache = cache.0
        var lastVariableIdx = cache.1
        
        if shouldInsertInitializer(initializerCache: initializerCache) {
            if let lastVariableIdx {
                result.members = result.members.inserting(MemberDeclListItem(decl: InitializerDecl.empty), at: lastVariableIdx + 1)
            } else {
                result.members = result.members.appending(MemberDeclListItem(decl: InitializerDecl.empty))
            }
            let updatedCache = buildInitializerCache(members: result.members)
            initializerCache = updatedCache.0
            lastVariableIdx = updatedCache.1
        }
        for idx in initializerCache.keys {
            let initializer = makeInitializer(initializerIdx: idx, members: result.members.map { $0 })
            if !initializer.containsBody && !initializer.containsParameters {
                result.members = result.members.removing(childAt: idx)
            } else {
                result.members = result.members.replacing(
                    childAt: idx,
                    with: MemberDeclListItem(decl: initializer)
                )
            }
        }

        return result
    }
    
    private func buildInitializerCache(members: MemberDeclList) -> ([Int: InitializerDecl], Int?) {
        var initializerCache = [Int: InitializerDecl]()
        var lastVariableIdx: Int?
        for (idx, member) in members.enumerated() {
            if let initializerDecl = member.decl.as(InitializerDecl.self) {
                initializerCache[idx] = initializerDecl
            } else if member.decl.is(VariableDecl.self) {
                lastVariableIdx = idx
            }
        }
        return (initializerCache, lastVariableIdx)
    }
    
    private func shouldInsertInitializer(initializerCache: [Int: InitializerDecl]) -> Bool {
        return initializerCache.isEmpty || initializerCache.allSatisfy {
            decodableInitializerRecognizer.isOfType(initializer: $0.value)
        }
    }

    private func makeInitializer(initializerIdx: Int, members: [MemberDeclListItem]) -> InitializerDecl {
        let initializer = members[initializerIdx].decl.cast(InitializerDecl.self)
        let variables = dependencyCollector.collectVariables(fromMembers: members)
        for recognizer in filterInitializerRecognizer {
            guard !recognizer.isOfType(initializer: initializer) else {
                return initializer
            }
        }
        var definitions = DependencyDefinitions(
            scopeBuilder: scopeBuilder,
            variables: variables,
            parameters: dependencyCollector.collectParameters(fromFunctionParameters: initializer.signature.input.parameterList),
            codeBlockItems: dependencyCollector.collectCodeBlockItems(
                fromCodeBlockItems: initializer.body?.statements ?? CodeBlockItemList([])
            )
        )
        Logger.standard.debug("Initial:\n\(definitions.debugDescription)")
        definitions = unusedAssignmentRemover.removeUnusedAssignments(definitions: definitions)
        Logger.standard.debug("After assignments removal:\n\(definitions.debugDescription)")
        definitions = unusedDeclarationRemover.removeUnusedDeclarations(definitions: definitions)
        Logger.standard.debug("After declarations removal:\n\(definitions.debugDescription)")
        definitions = unusedParameterRemover.removeUnusedParameters(definitions: definitions)
        Logger.standard.debug("After parameters removal:\n\(definitions.debugDescription)")
        definitions = missingParameterAndAssignmentInjector.injectMissingParametersAndAssignments(definitions: definitions)
        Logger.standard.debug("After parameter and assignment injection:\n\(definitions.debugDescription)")
        if configuration.enableSorting {
            definitions = dependencySorter.sortDependencies(definitions: definitions)
            Logger.standard.debug("After sorting:\n\(definitions.debugDescription)")
        }
        return makeInitializer(existingInitializer: initializer, definitions: definitions)
    }
    
    private func makeInitializer(
        existingInitializer initializer: InitializerDecl,
        definitions: DependencyDefinitions
    ) -> InitializerDecl {
        var initializer = initializer.withEmptyContent
        initializer.signature.input.parameterList = FunctionParameterList(definitions.parameters.map { $0.parameter })
        initializer.body?.statements = CodeBlockItemList(definitions.codeBlockItems.map { $0.originalItem })
        return initializer
    }
}
