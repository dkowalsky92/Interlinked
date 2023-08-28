//
//  SourceEditorCommand.swift
//  InterlinkedExtension
//
//  Created by Dominik Kowalski on 28/08/2023.
//

import Foundation
import XcodeKit
import InterlinkedCore
import InterlinkedShared

class InterlinkCommand: NSObject, XCSourceEditorCommand {
    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void) {
        guard let userDefaults = UserDefaults(suiteName: Constants.userDefaultsSuiteName) else {
            completionHandler(InterlinkError.userDefaultsNotFound.nserror)
            return
        }
        let maxLineLength = userDefaults.integer(forKey: Configuration.Constants.maxLineLengthKey)
        let formatterStyle = userDefaults.string(forKey: Configuration.Constants.formatterStyleKey).flatMap { Configuration.FormatterStyle(rawValue: $0) }
        let enableSorting = userDefaults.bool(forKey: Configuration.Constants.enableSortingKey)
        let configuration = Configuration(
            spacesPerTab: invocation.buffer.tabWidth,
            maxLineLength: maxLineLength,
            enableSorting: enableSorting,
            formatterStyle: formatterStyle ?? .google
        )
        let align = Interlink(configuration: configuration)
        
        do {
            invocation.buffer.completeBuffer = try align.interlink(input: invocation.buffer.completeBuffer)
            invocation.buffer.selections.setArray([])
            completionHandler(nil)
        } catch {
            if let alignError = error as? InterlinkError {
                completionHandler(alignError.nserror)
            } else {
                completionHandler(error)
            }
        }
    }
}
