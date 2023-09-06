//
//  InitializerFilterer.swift
//  InterlinkedCore
//
//  Created by Dominik Kowalski on 18/05/2023.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder

protocol InitializerRecognizer {
    func isOfType(initializer: InitializerDecl) -> Bool
}

class ViewControllerCoderInitializerRecognizer: InitializerRecognizer {
    private enum Constants {
        static let coderParameterName = "coder"
        static let coderParameterType = "NSCoder"
    }
    
    init() {}
    
    func isOfType(initializer: InitializerDecl) -> Bool {
        initializer.parameter(
            forName: Constants.coderParameterName,
            type: Constants.coderParameterType
        ) != nil && initializer.signature.input.parameterList.count == 1
    }
}

class DecodableInitializerRecognizer: InitializerRecognizer {
    private enum Constants {
        static let decodableParameterName = "decoder"
        static let decodableParameterType = "Decoder"
    }
    
    init() {}
    
    func isOfType(initializer: InitializerDecl) -> Bool {
        initializer.parameter(
            forName: Constants.decodableParameterName, type: Constants.decodableParameterType
        ) != nil && initializer.signature.input.parameterList.count == 1
    }
}

class ConvenienceInitializerRecognizer: InitializerRecognizer {
    private enum Constants {
        static let convenienceKeyword = "convenience"
    }
    
    init() {}
    
    func isOfType(initializer: InitializerDecl) -> Bool {
        (initializer.modifiers?.contains(where: {
            $0.name.textWithoutTrivia == Constants.convenienceKeyword
        }) ?? false)
    }
}

class OverrideInitializerRecognizer: InitializerRecognizer {
    private enum Constants {
        static let overrideKeyword = "override"
    }
    
    init() {}
    
    func isOfType(initializer: InitializerDecl) -> Bool {
        (initializer.modifiers?.contains(where: {
            $0.name.textWithoutTrivia == Constants.overrideKeyword
        }) ?? false)
    }
}
