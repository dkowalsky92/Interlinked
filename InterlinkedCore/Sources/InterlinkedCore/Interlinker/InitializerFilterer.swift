//
//  InitializerFilterer.swift
//  InterlinkedCore
//
//  Created by Dominik Kowalski on 18/05/2023.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder

protocol InitializerFilterer {
    func shouldFilter(initializer: InitializerDecl, variables: [Variable]) -> InterlinkError?
}

class ViewControllerCoderInitializerFilterer: InitializerFilterer {
    private enum Constants {
        static let coderParameterName = "coder"
        static let coderParameterType = "NSCoder"
        static let errorInfo = "ViewController's NSCoder initializers are unsupported at the moment."
    }
    
    init() {}
    
    func shouldFilter(initializer: InitializerDecl, variables: [Variable]) -> InterlinkError? {
        initializer.parameter(
            forName: Constants.coderParameterName,
            type: Constants.coderParameterType
        ) != nil ? .unsupportedInitializerFormat(Constants.errorInfo) : nil
    }
}

class DecodableInitializerFilterer: InitializerFilterer {
    private enum Constants {
        static let decodableParameterName = "decoder"
        static let decodableParameterType = "Decoder"
        static let errorInfo = "Decodable initializers are unsupported at the moment."
    }
    
    init() {}
    
    func shouldFilter(initializer: InitializerDecl, variables: [Variable]) -> InterlinkError? {
        initializer.parameter(
            forName: Constants.decodableParameterName, type: Constants.decodableParameterType
        ) != nil ? .unsupportedInitializerFormat(Constants.errorInfo) : nil
    }
}

class ConvenienceInitializerFilterer: InitializerFilterer {
    private enum Constants {
        static let convenienceKeyword = "convenience"
        static let errorInfo = "Convenience initializers are unsupported at the moment."
    }
    
    init() {}
    
    func shouldFilter(initializer: InitializerDecl, variables: [Variable]) -> InterlinkError? {
        (initializer.modifiers?.contains(where: {
            $0.name == .contextualKeyword(Constants.convenienceKeyword)
        }) ?? false) ? .unsupportedInitializerFormat(Constants.errorInfo) : nil
    }
}
