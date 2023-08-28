//
//  Scope.swift
//  InterlinkedCore
//
//  Created by Dominik Kowalski on 15/08/2023.
//

import Foundation
import SwiftSyntaxBuilder

class Scope: CustomDebugStringConvertible {
    enum DeclarationType: String, Hashable {
        case variable
        case function
        case `typealias`
        case `actor`
        case `class`
        case `struct`
        case `enum`
    }
    struct Declaration: Hashable, CustomDebugStringConvertible {
        let rootItemId: Int
        let identifier: String
        let type: DeclarationType
        
        var debugDescription: String {
            "declaration(identifier: \(identifier), type: \(type.rawValue), itemId: \(rootItemId)"
        }
    }
    struct Assignment: Hashable, CustomDebugStringConvertible {
        let rootItemId: Int
        let info: AssignmentInfo
        
        var debugDescription: String {
            "assignment(assignee: \(info.assignee), assigner: \(info.assigner.description), isSelf: \(info.isInstance), itemId: \(rootItemId)"
        }
    }
    struct IdentifierUsage: Hashable, CustomDebugStringConvertible {
        let rootItemId: Int
        let identifier: String
        
        var debugDescription: String {
            "used(identifier: \(identifier), itemId: \(rootItemId)"
        }
    }

    var declarations: Set<Declaration> = Set()
    var assignments: Set<Assignment> = Set()
    var usedIdentifiers: Set<IdentifierUsage> = Set()
    var children: [Scope] = []
    
    init() {}
    
    var lastAssignmentIndex: Int? {
        assignments.sorted(by: {
            $0.rootItemId < $1.rootItemId
        }).last?.rootItemId
    }
    
    func insert(declaration: Declaration) {
        self.declarations.insert(declaration)
    }
    
    func insert(declarations: Set<Declaration>) {
        self.declarations = self.declarations.union(declarations)
    }
    
    func insert(usedIdentifier: IdentifierUsage) {
        self.usedIdentifiers.insert(usedIdentifier)
    }
    
    func insert(usedIdentifiers: Set<IdentifierUsage>) {
        self.usedIdentifiers = self.usedIdentifiers.union(usedIdentifiers)
    }
    
    func insert(assignment: Assignment) {
        self.assignments.insert(assignment)
    }
    
    func insert(assignments: Set<Assignment>) {
        self.assignments = self.assignments.union(assignments)
    }
    
    func containsDeclaration(forIdentifier identifier: String, type: DeclarationType) -> Bool {
        bfsWithContains { scope in
            scope.declarations.contains(where: { $0.identifier == identifier && $0.type == type})
        }
    }
    
    func containsUsed(identifier: String, skipLocalDeclarations: Bool = true) -> Bool {
        if skipLocalDeclarations {
            return bfsWithContains { scope in
                scope.usedIdentifiers.contains(where: { $0.identifier == identifier })
            }
        } else {
            var declarations = Set<String>()
            return bfsWithContains { scope in
                declarations = declarations.union(scope.declarations.map { $0.identifier })
                return scope.usedIdentifiers.contains(where: { $0.identifier == identifier }) && !declarations.contains(identifier)
            }
        }
    }
    
    func instanceAssignment(forIdentifier identifier: String) -> Assignment? {
        var declarations = Set<Declaration>()
        return bfsWithResult { scope -> Assignment? in
            declarations = declarations.union(scope.declarations)
            let selfAssignmentCheck = scope.assignments.first(where: { $0.info.assignee == identifier && $0.info.isInstance })
            let directAssignmentCheck = scope.assignments.first(where: { `assignment` in
                `assignment`.info.assignee == identifier && !`assignment`.info.isInstance && !declarations.contains(where: { delcaration in
                    delcaration.identifier == identifier && delcaration.type == .variable
                })
            })
            return selfAssignmentCheck ?? directAssignmentCheck
        }
    }
    
    func localAssignment(forIdentifier identifier: String) -> Assignment? {
        var declarations = Set<Declaration>()
        return bfsWithResult { scope -> Assignment? in
            declarations = declarations.union(scope.declarations)
            return scope.assignments.first(where: { $0.info.assignee == identifier && !$0.info.isInstance })
        }
    }
    
    var debugDescription: String {
        var result = "Scope:\n"
        var indentation = "\t"
        _ = bfsWithContains { scope in
            result += """
            \(indentation)declarations(\n\(scope.declarations.map { "\(indentation)\(indentation)\($0.debugDescription)" }.joined(separator: ",\n"))\(indentation)\n),
            \(indentation)assignments(\n\(scope.assignments.map { "\(indentation)\(indentation)\($0.debugDescription)" }.joined(separator: ",\n"))\(indentation)\n),
            \(indentation)used(\n\(scope.usedIdentifiers.map { "\(indentation)\(indentation)\($0.debugDescription)" }.joined(separator: ",\n"))\(indentation)\n)
            
            """
            indentation += "\t"
            return false
        }
        return result
    }

    private func bfsWithResult<OptionalResult>(perform: (Scope) -> OptionalResult?) -> OptionalResult? {
        var stack = Stack<Scope>()
        stack.push(self)
        while let next = stack.pop() {
            let result = perform(next)
            if let result {
                return result
            }
            for child in next.children.reversed() {
                stack.push(child)
            }
        }
        return nil
    }
    
    private func bfsWithContains(perform: (Scope) -> Bool) -> Bool {
        var stack = Stack<Scope>()
        stack.push(self)
        while let next = stack.pop() {
            let contains = perform(next)
            if contains {
                return true
            }
            for child in next.children.reversed() {
                stack.push(child)
            }
        }
        return false
    }
}
