//
//  FormatSpec.swift
//  InterlinkTests
//
//  Created by Dominik Kowalski on 06/05/2023.
//

import XCTest

import InterlinkedCore
import InterlinkedShared

final class FormatSpec: XCTestCase {
    func testFormat() {
        let testCases: [TestCase] = [
            .init(
                context: "has one function defined at root with correct formatting",
                input: """
                func test(value: String, value2: String) {
                
                }
                """,
                expectedOutput: """
                func test(value: String, value2: String) {
                
                }
                """
            ),
            .init(
                context: "has three functions defined in declaration, incorrect formatting",
                input: """
                struct Test {
                    func test1(value: String, value2: String) {
                    
                    
                    
                    
                    }
                    func test2(value: String, value2: String) {
                    
                    }
                    
                    
                        func test3(value: String, value2: String) {}
                
                
                
                
                }
                """,
                expectedOutput: """
                struct Test {
                    func test1(value: String, value2: String) {
                
                    }
                
                    func test2(value: String, value2: String) {
                
                    }
                
                    func test3(value: String, value2: String) {
                
                    }
                }
                """
            ),
            .init(
                context: "has two functions defined in declaration, with incorrect formatting",
                input: """
                struct Test {
                    func test(value: String, value2: String) {
                    
                    }
                    func test2(value: String, value2: @escaping () -> Void, veryLongParameterNameThatCertainlyOverFlows: @escaping () -> Void) {
                    
                    }
                }
                """,
                expectedOutput: """
                struct Test {
                    func test(value: String, value2: String) {

                    }
                
                    func test2(
                        value: String,
                        value2: @escaping () -> Void,
                        veryLongParameterNameThatCertainlyOverFlows: @escaping () -> Void
                    ) {

                    }
                }
                """
            ),
        ]
        for testCase in testCases {
            let sut = Format(configuration: testCase.configuration)
            do {
                let output = try sut.format(input: testCase.input)
                XCTAssertEqual(output, testCase.expectedOutput, testCase.context)
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
    }
}
