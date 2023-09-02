//
//  Configuration.swift
//  InterlinkedShared
//
//  Created by Dominik Kowalski on 24/05/2023.
//

import Foundation

public struct Configuration {
    public enum Constants {
        public static let maxLineLengthKey = "max-line-length"
        public static let formatterStyleKey = "formatter-style"
        public static let enableSortingKey = "enable-sorting"
    }
    public enum FormatterStyle: String, CaseIterable, Identifiable {
        case google
        case airbnb
        case linkedin
        
        public var content: String {
            switch self {
            case .google:
                return """
                struct Test {
                    let value: String
                    let value2: String
                
                    init(
                        value: String,
                        value2: String
                    ) {
                        self.value = value
                        self.value2 = value2
                    }
                }
                """
            case .airbnb:
                return """
                struct Test {
                    let value: String
                    let value2: String

                    init(
                        value: String,
                        value2: String) {
                        self.value = value
                        self.value2 = value2
                    }
                }
                """
            case .linkedin:
                return """
                struct Test {
                    let value: String
                    let value2: String

                    init(value: String,
                         value2: String) {
                        self.value = value
                        self.value2 = value2
                    }
                }
                """
            }
        }
        
        public var description: String {
            switch self {
            case .google:
                return "Google style formatter"
            case .airbnb:
                return "AirBnB style formatter"
            case .linkedin:
                return "LinkedIn style formatter"
            }
        }
        
        public var id: String {
            rawValue
        }
    }
    
    public let spacesPerTab: Int
    public let maxLineLength: Int
    public let enableSorting: Bool
    public let formatterStyle: FormatterStyle
    
    public init(
        spacesPerTab: Int = 4,
        maxLineLength: Int = 160,
        enableSorting: Bool = true,
        formatterStyle: FormatterStyle = .google
    ) {
        self.spacesPerTab = spacesPerTab
        self.maxLineLength = maxLineLength
        self.enableSorting = enableSorting
        self.formatterStyle = formatterStyle
    }
}
