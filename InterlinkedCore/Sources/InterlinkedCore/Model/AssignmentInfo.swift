//
//  AssignmentInfo.swift
//  InterlinkedCore
//
//  Created by Dominik Kowalski on 21/05/2023.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder

struct AssignmentInfo: Hashable {
    let assignee: String
    let assigner: ExprListSyntax
    let isInstance: Bool
    
    init(assignee: String, assigner: ExprListSyntax, isInstance: Bool) {
        self.assignee = assignee
        self.assigner = assigner
        self.isInstance = isInstance
    }
    
    init?(sequenceExpr: SequenceExprSyntax) {
        let assignmentExprSyntax = sequenceExpr.elements.map { $0 }.split(whereSeparator: { $0.is(AssignmentExprSyntax.self) })
        guard assignmentExprSyntax.count == 2 else {
            return nil
        }
        self.assigner = ExprListSyntax(Array(assignmentExprSyntax[1]))
        if
            let memberAccessExpr = assignmentExprSyntax[0].first?.as(MemberAccessExprSyntax.self),
            let identifierExpr = memberAccessExpr.base?.as(DeclReferenceExprSyntax.self),
            identifierExpr.baseName.tokenKind == .keyword(.`self`)
        {
            self.isInstance = true
            self.assignee = memberAccessExpr.declName.baseName.text
        } else if let identifierExpr = assignmentExprSyntax[0].first?.as(DeclReferenceExprSyntax.self) {
            self.isInstance = false
            self.assignee = identifierExpr.baseName.text
        } else {
            return nil
        }
    }
    
    var rawAssignee: String {
        assignee.first == "_" ? String(assignee.dropFirst()) : assignee
    }
    
    var rootAssignerIdentifier: String {
        if
            let memberAccessExpr = assigner.first?.as(MemberAccessExprSyntax.self),
            let identifierExpr = memberAccessExpr.base?.as(DeclReferenceExprSyntax.self)
        {
            return identifierExpr.baseName.text
        } else if let identifierExpr = assigner.first?.as(DeclReferenceExprSyntax.self) {
            return identifierExpr.baseName.text
        } else {
            preconditionFailure()
        }
    }
}
