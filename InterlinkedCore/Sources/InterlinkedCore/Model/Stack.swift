//
//  Stack.swift
//  InterlinkedCore
//
//  Created by Dominik Kowalski on 08/07/2023.
//

import Foundation

struct Stack<Element> {
    private var elements = [Element]()

    init() {}

    var count: Int {
        elements.count
    }

    mutating func push(_ element: Element) {
        elements.append(element)
    }

    @discardableResult mutating func pop() -> Element? {
        elements.popLast()
    }

    func peek() -> Element? {
        elements.last
    }

    func contains(where predicate: (Element) -> Bool) -> Bool {
        elements.contains(where: predicate)
    }

    mutating func modifyLast(by modifier: (inout Element) -> Void) {
        if !elements.isEmpty {
            modifier(&elements[count - 1])
        }
    }

    mutating func modifyPreviousToLast(by modifier: (inout Element) -> Void) {
        if elements.count > 1 {
            modifier(&elements[count - 2])
        }
    }
}

extension Stack: CustomDebugStringConvertible where Element == CustomDebugStringConvertible {
    var debugDescription: String {
        let intermediateElements = count > 1 ? elements[1 ..< count - 1] : []
        return """
            Stack with \(count) elements:
                first: \(elements.first?.debugDescription ?? "")
                intermediate: \(intermediateElements.map(\.debugDescription).joined(separator: ", "))
                last: \(peek()?.debugDescription ?? "")
            """
    }
}
