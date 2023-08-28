//
//  Graph+Extensions.swift
//  InterlinkedCore
//
//  Created by Dominik Kowalski on 24/06/2023.
//

import Foundation
import SwiftSyntaxBuilder
import SwiftGraph

extension UnweightedGraph where UnweightedGraph.Element == Vertex {
    func debugDescription(paramtersCache: [Int: PositionableParameter], codeBlockItemsCache: [Int: PositionableCodeBlockItem]) -> String {
        var result = ""
        for i in 0..<vertices.count {
            let vertex = vertices[i]
            var related = "null"
            let neighbors = neighborsForIndex(i)
            if !neighbors.isEmpty {
                related = neighbors.map { "- \($0.debugDescription(parameterCache: paramtersCache, codeBlockItemCache: codeBlockItemsCache))" }.joined(separator: "\n")
            }
            result += "\(i+1). \(vertex.debugDescription(parameterCache: paramtersCache, codeBlockItemCache: codeBlockItemsCache)) -> \n\(related)\n\n"
        }
        return result
    }
}
