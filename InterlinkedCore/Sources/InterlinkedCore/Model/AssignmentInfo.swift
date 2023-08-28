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
    let assigner: ExprList
    let isInstance: Bool
    
    init(assignee: String, assigner: ExprList, isInstance: Bool) {
        self.assignee = assignee
        self.assigner = assigner
        self.isInstance = isInstance
    }
    
    init?(sequenceExpr: SequenceExpr) {
        let assignmentExpr = sequenceExpr.elements.map { $0 }.split(whereSeparator: { $0.is(AssignmentExpr.self) })
        guard assignmentExpr.count == 2 else {
            return nil
        }
        self.assigner = ExprList(Array(assignmentExpr[1]))
        if
            let memberAccessExpr = assignmentExpr[0].first?.as(MemberAccessExpr.self),
            let identifierExpr = memberAccessExpr.base?.as(IdentifierExpr.self),
            identifierExpr.identifier.tokenKind == TokenKind.selfKeyword
        {
            self.isInstance = true
            self.assignee = memberAccessExpr.name.text
        } else if let identifierExpr = assignmentExpr[0].first?.as(IdentifierExpr.self) {
            self.isInstance = false
            self.assignee = identifierExpr.identifier.text
        } else {
            return nil
        }
    }
}
