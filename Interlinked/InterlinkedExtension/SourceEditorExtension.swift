//
//  SourceEditorExtension.swift
//  InterlinkedExtension
//
//  Created by Dominik Kowalski on 28/08/2023.
//

import Foundation
import XcodeKit

class SourceEditorExtension: NSObject, XCSourceEditorExtension {
    func extensionDidFinishLaunching() {
        print("extensionDidFinishLaunching")
    }
}
