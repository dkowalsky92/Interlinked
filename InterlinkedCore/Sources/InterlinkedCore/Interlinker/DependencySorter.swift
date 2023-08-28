//
//  DependencySorter.swift
//  InterlinkedCore
//
//  Created by Dominik Kowalski on 20/08/2023.
//

import Foundation
import SwiftSyntaxBuilder
import SwiftSyntax
import SwiftGraph

class DependencySorter {
    private let scopeBuilder: ScopeBuilder
    private let codeBlockItemRelationshipFinder: CodeBlockItemRelationshipFinder
    
    init(
        scopeBuilder: ScopeBuilder,
        codeBlockItemRelationshipFinder: CodeBlockItemRelationshipFinder
    ) {
        self.scopeBuilder = scopeBuilder
        self.codeBlockItemRelationshipFinder = codeBlockItemRelationshipFinder
    }
    
    func sortDependencies(definitions: DependencyDefinitions) -> DependencyDefinitions {
        var remainingItemsCache = definitions.codeBlockItemsCache
        
        let graph = buildExistingGraph(
            parameters: definitions.parameters,
            codeBlockItems: definitions.codeBlockItems
        )
        let reversedGraph = graph.reversed()
        
        var resultParameters = [PositionableParameter]()
        var resultCodeBlockItems = [PositionableCodeBlockItem]()
        
        for variable in definitions.variables {
            guard variable.isSettable else {
                continue
            }
            guard
                let assignment = definitions.scope.instanceAssignment(forIdentifier: variable.name),
                let item = definitions.codeBlockItemsCache[assignment.rootItemId]
            else {
                continue
            }
            let paths = reversedGraph.findAllDfs(from: item.vertex) { vertex in
                reversedGraph.edgesForVertex(vertex)?.isEmpty ?? true
            }
            var pathVertices = [[Vertex]]()
            for path in paths {
                var vertices = [Vertex]()
                for (idx, edge) in path.enumerated() {
                    if idx == 0 {
                        vertices.append(reversedGraph.vertexAtIndex(edge.u))
                        vertices.append(reversedGraph.vertexAtIndex(edge.v))
                    } else {
                        vertices.append(reversedGraph.vertexAtIndex(edge.v))
                    }
                }
                vertices = vertices.reversed()
                pathVertices.append(vertices)
            }
            let uniqued = pathVertices.flatMap { $0 }.uniqued()
            var parameterInfo = uniqued.compactMap { (vertex: Vertex) -> Vertex.Info? in
                guard case .parameter(let info) = vertex else {
                    return nil
                }
                return info
            }
            if parameterInfo.count > 1 {
                parameterInfo.sort(by: { lhs, rhs in
                    lhs.id < rhs.id
                })
            }
            for info in parameterInfo {
                resultParameters.append(definitions.parametersCache[info.id]!)
            }
            
            var codeBlockItemInfo = uniqued.compactMap { (vertex: Vertex) -> Vertex.Info? in
                guard case .codeBlockItem(let info) = vertex else {
                    return nil
                }
                return info
            }
            codeBlockItemInfo.sort(by: { lhs, rhs in
                lhs.id < rhs.id
            })
            for info in codeBlockItemInfo {
                resultCodeBlockItems.append(definitions.codeBlockItemsCache[info.id]!)
                remainingItemsCache.removeValue(forKey: info.id)
            }
        }
        
        let remainingItems = Array(remainingItemsCache.values).sorted { lhs, rhs in
            lhs.id < rhs.id
        }
        for remainingItem in remainingItems {
            if remainingItem.id == 0 {
                resultCodeBlockItems.insert(remainingItem, at: 0)
                continue
            } else if let firstAfterAssignmentsIndex = definitions.firstAfterAssignmentsIndex, remainingItem.id == firstAfterAssignmentsIndex {
                resultCodeBlockItems.append(remainingItem)
            } else if let previousItemIdx = resultCodeBlockItems.firstIndex(
                where: { $0.id == remainingItem.id-1 }
            ) {
                resultCodeBlockItems.insert(remainingItem, at: previousItemIdx+1)
            }
        }
        definitions.replaceParameters(parameters: resultParameters.uniqued())
        definitions.replaceCodeBlockItems(codeBlockItems: resultCodeBlockItems.uniqued())
        return definitions
    }
    
    private func buildExistingGraph(
        parameters: [PositionableParameter],
        codeBlockItems: [PositionableCodeBlockItem]
    ) -> UnweightedGraph<Vertex> {
        var vertices = [Vertex]()
        parameters.forEach {
            vertices.append($0.vertex)
        }
        codeBlockItems.forEach {
            vertices.append($0.vertex)
        }
        let graph = UnweightedGraph<Vertex>(vertices: vertices)
        for parameter in parameters {
            let relatedCodeBlocks = codeBlockItemRelationshipFinder.relatedCodeBlockItems(
                withName: parameter.name,
                codeBlockItems: codeBlockItems
            )
            for relatedCodeBlock in relatedCodeBlocks {
                graph.addEdge(
                    from: parameter.vertex,
                    to: relatedCodeBlock.vertex,
                    directed: true
                )
            }
        }
        for (idx, codeBlockItem) in codeBlockItems.enumerated() {
            let currentItemScope = scopeBuilder.buildScope(fromCodeBlockItems: [codeBlockItem])
            let remainingCodeBlocks = codeBlockItems.dropFirst(idx+1).map { $0 }
            for declaration in currentItemScope.declarations {
                let relatedCodeBlockItems = codeBlockItemRelationshipFinder.relatedCodeBlockItems(
                    withName: declaration.identifier,
                    codeBlockItems: remainingCodeBlocks
                )
                for relatedCodeBlock in relatedCodeBlockItems {
                    graph.addEdge(
                        from: codeBlockItem.vertex,
                        to: relatedCodeBlock.vertex,
                        directed: true
                    )
                }
            }
        }
        return graph
    }
}
