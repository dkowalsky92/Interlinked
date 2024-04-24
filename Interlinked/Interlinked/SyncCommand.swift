//
//  InterlinkCommand.swift
//  Interlinked
//
//  Created by Dominik Kowalski on 28/08/2023.
//

import Foundation
import XcodeKit
import InterlinkedCore
import InterlinkedShared

class SyncCommand: NSObject, XCSourceEditorCommand {
    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void) {
        guard let userDefaults = UserDefaults(suiteName: Constants.userDefaultsSuiteName) else {
            completionHandler(InterlinkError.userDefaultsNotFound.nserror)
            return
        }
        let maxLineLength = userDefaults.integer(forKey: Configuration.Constants.maxLineLengthKey)
        let formatterStyle = userDefaults.string(forKey: Configuration.Constants.formatterStyleKey).flatMap {
            Configuration.FormatterStyle(rawValue: $0)
        }
        let enableSorting = userDefaults.bool(forKey: Configuration.Constants.enableSortingKey)
        let configuration = Configuration(
            spacesPerTab: invocation.buffer.tabWidth,
            maxLineLength: maxLineLength,
            enableSorting: enableSorting,
            formatterStyle: formatterStyle ?? .google
        )
        let sync = Sync(configuration: configuration)
        let format = Format(configuration: configuration)
        
        do {
            let buffer = invocation.buffer
            guard buffer.selections.count < 2 else {
                throw InterlinkError.multipleSelectionUnsupported
            }
            let selection = buffer.selections.firstObject as! XCSourceTextRange
            if !selection.isSingleCharacter {
                let lines = invocation.buffer.lines as! [String]
                let startLine = selection.start.line
                let endLine = selection.end.line == buffer.lines.count ? selection.end.line - 1 : selection.end.line
                let startColumn = 0
                let endColumn = selection.end.line == buffer.lines.count ? lines[selection.end.line - 1].count - 1 : selection.end.column
                
                var selectedText = ""
                for i in startLine...endLine {
                    let line = lines[i]
                    if i == startLine && i == endLine {
                        selectedText += String(line[line.index(line.startIndex, offsetBy: startColumn)..<line.index(line.startIndex, offsetBy: endColumn)])
                    } else if i == startLine {
                        selectedText += String(line[line.index(line.startIndex, offsetBy: startColumn)...])
                    } else if i == endLine {
                        selectedText += String(line[..<line.index(line.startIndex, offsetBy: endColumn)])
                    } else {
                        selectedText += line
                    }
                }

                let modifiedText = try sync.sync(input: selectedText)
                let modifiedLines = modifiedText.components(separatedBy: .newlines)
                buffer.lines.replaceObjects(in: NSRange(location: startLine, length: endLine - startLine + 1), withObjectsFrom: modifiedLines)
            } else {
                invocation.buffer.completeBuffer = try sync.sync(input: invocation.buffer.completeBuffer)
            }
            
            invocation.buffer.completeBuffer = try format.format(input: invocation.buffer.completeBuffer)
            invocation.buffer.selections.setArray([selection])
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

extension XCSourceTextRange {
    var isSingleCharacter: Bool {
        start.column == end.column && start.line == end.line
    }
}
