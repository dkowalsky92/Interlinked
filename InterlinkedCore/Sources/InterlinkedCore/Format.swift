//
//  Format.swift
//  Interlink
//
//  Created by Dominik Kowalski on 14/10/2023.
//

import Foundation
import InterlinkedShared
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public class Format {
    private let configuration: Configuration
    private let sourceParser: SourceParser
    private let formattingRewriter: FormattingRewriter
    
    public init(configuration: Configuration) {
        self.configuration = configuration
        self.sourceParser = SourceParser()
        let signatureFormatter: FunctionSignatureFormatterProtocol
        switch configuration.formatterStyle {
        case .google:
            signatureFormatter = GoogleStyleParameterClauseFormatter()
        case .airbnb:
            signatureFormatter = AirBnbStyleParameterClauseFormatter()
        case .linkedin:
            signatureFormatter = LinkedInStyleParameterClauseFormatter()
        }
        self.formattingRewriter = FormattingRewriter(configuration: configuration, signatureFormatter: signatureFormatter)
    }
    
    public func format(input: String) throws -> String {
        let sourceFile = try sourceParser.parse(source: input)
        return formattingRewriter.visit(sourceFile).description
    }
}
