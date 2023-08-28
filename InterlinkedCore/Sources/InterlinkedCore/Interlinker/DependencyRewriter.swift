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

class DependencyRewriter: SyntaxRewriter {
    private let configuration: Configuration
    private let dependencyCollector: DependencyCollector
    private let unusedAssignmentRemover: UnusedAssignmentRemover
    private let unusedDeclarationRemover: UnusedDeclarationRemover
    private let unusedParameterRemover: UnusedParameterRemover
    private let missingParameterAndAssignmentInjector: MissingParameterAndAssignmentInjector
    private let dependencySorter: DependencySorter
    private let scopeBuilder: ScopeBuilder
    private let initializerFilterers: [InitializerFilterer]
    
    var error: Error?
    
    init(
        configuration: Configuration,
        dependencyCollector: DependencyCollector,
        unusedAssignmentRemover: UnusedAssignmentRemover,
        unusedDeclarationRemover: UnusedDeclarationRemover,
        unusedParameterRemover: UnusedParameterRemover,
        missingParameterAndAssignmentInjector: MissingParameterAndAssignmentInjector,
        dependencySorter: DependencySorter,
        initializerFilterers: [InitializerFilterer],
        scopeBuilder: ScopeBuilder
    ) {
        self.configuration = configuration
        self.dependencyCollector = dependencyCollector
        self.unusedAssignmentRemover = unusedAssignmentRemover
        self.unusedDeclarationRemover = unusedDeclarationRemover
        self.unusedParameterRemover = unusedParameterRemover
        self.missingParameterAndAssignmentInjector = missingParameterAndAssignmentInjector
        self.dependencySorter = dependencySorter
        self.initializerFilterers = initializerFilterers
        self.scopeBuilder = scopeBuilder
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
        var initializerIndices: Set<Int> = Set()
        var lastVariableIdx: Int?
        for (idx, member) in memberBlock.members.enumerated() {
            if member.decl.is(InitializerDecl.self) {
                initializerIndices.insert(idx)
            } else if let variable = member.decl.as(VariableDecl.self) {
                guard !variable.isComputedVariable else {
                    continue
                }
                lastVariableIdx = idx
            }
        }
        
        switch (initializerIndices, lastVariableIdx) {
        case (let indices, .some) where !indices.isEmpty:
            for initializerIdx in indices {
                let initializer = try makeInitializer(initializerIdx: initializerIdx, members: result.members.map { $0 })
                if !initializer.containsBody && !initializer.containsParameters {
                    result.members = result.members.removing(childAt: initializerIdx)
                } else {
                    result.members = result.members.replacing(
                        childAt: initializerIdx,
                        with: MemberDeclListItem(decl: initializer)
                    )
                }
            }
        case (let indices, let lastVarIdx?) where indices.isEmpty:
            let initializerIdx = lastVarIdx + 1
            result.members = result.members.inserting(MemberDeclListItem(decl: InitializerDecl.empty), at: initializerIdx)
            let initializer = try makeInitializer(initializerIdx: initializerIdx, members: result.members.map { $0 })
            if !initializer.containsBody && !initializer.containsParameters {
                result.members = result.members.removing(childAt: initializerIdx)
            } else {
                result.members = result.members.replacing(
                    childAt: initializerIdx,
                    with: MemberDeclListItem(decl: initializer)
                )
            }
        case (let indices, nil) where !indices.isEmpty:
            for initializerIdx in indices {
                let initializer = try makeInitializer(initializerIdx: initializerIdx, members: result.members.map { $0 })
                if !initializer.containsBody && !initializer.containsParameters {
                    result.members = result.members.removing(childAt: initializerIdx)
                } else {
                    result.members = result.members.replacing(
                        childAt: initializerIdx,
                        with: MemberDeclListItem(decl: initializer)
                    )
                }
            }
        default:
            break
        }
        
        return result
    }

    private func makeInitializer(initializerIdx: Int, members: [MemberDeclListItem]) throws -> InitializerDecl {
        let initializer = members[initializerIdx].decl.cast(InitializerDecl.self)
        let variables = dependencyCollector.collectVariables(fromMembers: members)
        for filterer in initializerFilterers {
            if let filterError = filterer.shouldFilter(initializer: initializer, variables: variables) {
                throw filterError
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
        definitions = unusedParameterRemover.removeUnusedParameters(definitions: definitions)
        definitions = unusedAssignmentRemover.removeUnusedAssignments(definitions: definitions)
        definitions = unusedDeclarationRemover.removeUnusedDeclarations(definitions: definitions)
        definitions = missingParameterAndAssignmentInjector.injectMissingParametersAndAssignments(definitions: definitions)
        if configuration.enableSorting {
            definitions = dependencySorter.sortDependencies(definitions: definitions)
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
