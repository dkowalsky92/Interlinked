//
//  Array+Extensions.swift
//  InterlinkedCore
//
//  Created by Dominik Kowalski on 26/06/2023.
//

import Foundation

extension Sequence {
    subscript(safe index: Int) -> Element? {
        var iterator = makeIterator()
        var currentIndex = 0
        while let element = iterator.next() {
            if currentIndex == index {
                return element
            }
            currentIndex += 1
        }
        return nil
    }
}

extension Sequence where Element: Hashable {
    func uniqued() -> [Element] {
        var set = Set<Element>()
        return filter { set.insert($0).inserted }
    }
}
