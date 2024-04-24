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

class SyncingRewriter: SyntaxRewriter {
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
    
    private var formattingStack: Stack<SyntaxIdentifier> = Stack()
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
            formattingStack.push(node.id)
            let memberDeclBlock = try withUpdatedMemberBlock(node.memberBlock)
            return super.visit(node.with(\.memberBlock, memberDeclBlock))
        } catch {
            self.error = error
            return super.visit(node)
        }
    }

    override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
        do {
            formattingStack.push(node.id)
            let memberDeclBlock = try withUpdatedMemberBlock(node.memberBlock)
            return super.visit(node.with(\.memberBlock, memberDeclBlock))
        } catch {
            self.error = error
            return super.visit(node)
        }
    }
    
    override func visit(_ node: ActorDeclSyntax) -> DeclSyntax {
        do {
            formattingStack.push(node.id)
            let memberDeclBlock = try withUpdatedMemberBlock(node.memberBlock)
            return super.visit(node.with(\.memberBlock, memberDeclBlock))
        } catch {
            self.error = error
            return super.visit(node)
        }
    }
    
    override func visitPost(_ node: Syntax) {
        if node.is(ClassDeclSyntax.self) || node.is(StructDeclSyntax.self) || node.is(ActorDeclSyntax.self) {
            formattingStack.pop()
        }
    }
    
    private func withUpdatedMemberBlock(_ memberBlock: MemberBlockSyntax) throws -> MemberBlockSyntax {
        guard formattingStack.count > 0 else {
            return memberBlock
        }
        var result = memberBlock
        let cache = buildInitializerCache(members: memberBlock.members)
        var initializerCache = cache.0
        var lastVariableIdx = cache.1
        
        if shouldInsertInitializer(initializerCache: initializerCache) {
            var updatedMembers = result.members
            if let lastVariableIdx {
                updatedMembers.insert(MemberBlockItemSyntax(decl: InitializerDeclSyntax.empty), at: result.members.index(lastVariableIdx, offsetBy: 1))
            } else {
                updatedMembers.append(MemberBlockItemSyntax(decl: InitializerDeclSyntax.empty))
            }
            result.members = updatedMembers
            let updatedCache = buildInitializerCache(members: result.members)
            initializerCache = updatedCache.0
            lastVariableIdx = updatedCache.1
        }
        for idx in initializerCache.keys {
            let initializer = makeInitializer(initializerIdx: idx, members: result.members)
            var updatedMembers = result.members
            if !initializer.containsBody && !initializer.containsParameters {
                updatedMembers.remove(at: idx)
                result.members = updatedMembers
            } else {
                updatedMembers[idx] = MemberBlockItemSyntax(decl: initializer)
                result.members = updatedMembers
            }
        }

        return result
    }
    
    private func buildInitializerCache(members: MemberBlockItemListSyntax) -> ([SyntaxChildrenIndex: InitializerDeclSyntax], SyntaxChildrenIndex?) {
        var initializerCache = [SyntaxChildrenIndex: InitializerDeclSyntax]()
        var lastVariableIdx: SyntaxChildrenIndex?
        for idx in members.indices {
            let member = members[idx]
            if let initializerDecl = member.decl.as(InitializerDeclSyntax.self) {
                initializerCache[idx] = initializerDecl
            } else if member.decl.is(VariableDeclSyntax.self) {
                lastVariableIdx = idx
            }
        }
        return (initializerCache, lastVariableIdx)
    }
    
    private func shouldInsertInitializer(initializerCache: [SyntaxChildrenIndex: InitializerDeclSyntax]) -> Bool {
        return initializerCache.isEmpty || initializerCache.allSatisfy {
            decodableInitializerRecognizer.isOfType(initializer: $0.value)
        }
    }

    private func makeInitializer(initializerIdx: SyntaxChildrenIndex, members: MemberBlockItemListSyntax) -> InitializerDeclSyntax {
        let initializer = members[initializerIdx].decl.cast(InitializerDeclSyntax.self)
        let variables = dependencyCollector.collectVariables(fromMembers: members)
        for recognizer in filterInitializerRecognizer {
            guard !recognizer.isOfType(initializer: initializer) else {
                return initializer
            }
        }
        var definitions = DependencyDefinitions(
            scopeBuilder: scopeBuilder,
            variables: variables,
            parameters: dependencyCollector.collectParameters(fromFunctionParameters: initializer.signature.parameterClause.parameters),
            codeBlockItems: dependencyCollector.collectCodeBlockItems(
                fromCodeBlockItems: initializer.body?.statements ?? CodeBlockItemListSyntax([])
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
        existingInitializer initializer: InitializerDeclSyntax,
        definitions: DependencyDefinitions
    ) -> InitializerDeclSyntax {
        var initializer = initializer.withEmptyContent
        initializer.signature.parameterClause.parameters = FunctionParameterListSyntax(definitions.parameters.map { $0.parameter })
        initializer.body = CodeBlockSyntax(statements: CodeBlockItemListSyntax(definitions.codeBlockItems.map { $0.originalItem }))
        return initializer
    }
}
