//
//  InterlinkError.swift
//  Interlinked
//
//  Created by Dominik Kowalski on 28/04/2023.
//

import Foundation

public enum InterlinkError: Error {
    case userDefaultsNotFound
    case multipleSelectionUnsupported
    case malformedStructure
    case unsupportedInitializerFormat(String)
    
    public var nserror: NSError {
        switch self {
        case .userDefaultsNotFound:
            let userInfo: [String: Any] = [
                NSLocalizedDescriptionKey:  NSLocalizedString(
                    "",
                    value: "Interlinking couldn't be performed. Couldn't find user defaults.",
                    comment: ""
                ),
            ]
            return NSError(domain: "", code: 41, userInfo: userInfo)
        case .malformedStructure:
            let userInfo: [String: Any] = [
                NSLocalizedDescriptionKey:  NSLocalizedString(
                    "",
                    value: "Interlinking couldn't be performed. The file structure is malformed.",
                    comment: ""
                ),
            ]
            return NSError(domain: "", code: 42, userInfo: userInfo)
        case .multipleSelectionUnsupported:
            let userInfo: [String: Any] = [
                NSLocalizedDescriptionKey:  NSLocalizedString(
                    "",
                    value: "Interlinking couldn't be performed. Multi-cursor selections are not yet supported, select each code block individually.",
                    comment: ""
                ),
            ]
            return NSError(domain: "", code: 42, userInfo: userInfo)
        case .unsupportedInitializerFormat(let info):
            let userInfo: [String: Any] = [
                NSLocalizedDescriptionKey:  NSLocalizedString(
                    "",
                    value: "Interlinking couldn't be performed. \(info)",
                    comment: ""
                ),
            ]
            return NSError(domain: "", code: 43, userInfo: userInfo)
        }
    }
}
