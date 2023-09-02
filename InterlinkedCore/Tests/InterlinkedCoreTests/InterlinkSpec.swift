//
//  InterlinkSpec.swift
//  InterlinkTests
//
//  Created by Dominik Kowalski on 06/05/2023.
//

import XCTest

import InterlinkedCore
import InterlinkedShared

final class InterlinkSpec: XCTestCase {
    func testParseComputedVariables() {
        let testCases: [TestCase] = [
            .init(
                context: "has setter & getter variable, didSet variable, getter variable, no init",
                input: """
                struct Test {
                    private let dep1: String
                    var dep2: String {
                        get {
                            dep1
                        }
                        set {
                            dep1 = newValue
                        }
                    }
                    var dep3: String {
                        dep1
                    }
                    var dep4: String {
                        get {
                            dep1
                        }
                    }
                    var dep5: String {
                        didSet {
                            dep1 = dep5
                        }
                    }
                }
                """,
                expectedOutput: """
                struct Test {
                    private let dep1: String
                    var dep2: String {
                        get {
                            dep1
                        }
                        set {
                            dep1 = newValue
                        }
                    }
                    var dep3: String {
                        dep1
                    }
                    var dep4: String {
                        get {
                            dep1
                        }
                    }
                    var dep5: String {
                        didSet {
                            dep1 = dep5
                        }
                    }

                    init(dep1: String, dep5: String) {
                        self.dep1 = dep1
                        self.dep5 = dep5
                    }
                }
                """
            ),
        ]
        for testCase in testCases {
            let sut = Interlink(configuration: testCase.configuration)
            do {
                let output = try sut.interlink(input: testCase.input)
                XCTAssertEqual(output, testCase.expectedOutput, testCase.context)
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
    }

    func testMaintainInitializerStructure() {
        let testCases: [TestCase] = [
            .init(
                context: "has an optional initializer with a throws keyword",
                input: """
                struct Test {
                    private let dep1: String

                    init?(dep1: String) throws {
                        self.dep1 = dep1
                    }
                }
                """,
                expectedOutput: """
                struct Test {
                    private let dep1: String

                    init?(dep1: String) throws {
                        self.dep1 = dep1
                    }
                }
                """
            ),
            .init(
                context: "has an optional initializer with a throws keyword",
                input: """
                struct Test {
                    private let dep1: String

                    convenience public init?(dep1: String) async throws {
                        self.dep1 = dep1
                    }
                }
                """,
                expectedOutput: """
                struct Test {
                    private let dep1: String

                    convenience public init?(dep1: String) async throws {
                        self.dep1 = dep1
                    }
                }
                """
            )
        ]
        for testCase in testCases {
            let sut = Interlink(configuration: testCase.configuration)
            do {
                let output = try sut.interlink(input: testCase.input)
                XCTAssertEqual(output, testCase.expectedOutput, testCase.context)
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
    }

    func testSetVariablesFromIndirectParameter() {
        let testCases: [TestCase] = [
            .init(
                context: "has one variable and init that creates a local variable setter from 3 different ones",
                input: """
                class Test {
                    var dependency1: String

                    init(someValue: Int, otherValue: Int, someOtherValue: String) {
                        let computedValue = "\\(someValue) + \\(otherValue) + \\(someOtherValue)"
                        self.dependency1 = computedValue
                    }
                }
                """,
                expectedOutput: """
                class Test {
                    var dependency1: String

                    init(someValue: Int, otherValue: Int, someOtherValue: String) {
                        let computedValue = "\\(someValue) + \\(otherValue) + \\(someOtherValue)"
                        self.dependency1 = computedValue
                    }
                }
                """
            ),
            .init(
                context: "has two variables and init that sets it from an indirect parameter",
                input: """
                struct Dependency {
                    private let dep1: String = 1
                }
                struct Test {
                    private let dep1: String
                    private let dep2: String

                    init(dependency: Dependency) {
                        self.dep1 = dependency.dep1
                        self.dep2 = dependency.dep2
                    }
                }
                """,
                expectedOutput: """
                struct Dependency {
                    private let dep1: String = 1
                }
                struct Test {
                    private let dep1: String
                    private let dep2: String

                    init(dependency: Dependency) {
                        self.dep1 = dependency.dep1
                        self.dep2 = dependency.dep2
                    }
                }
                """
            ),
            .init(
                context: "has two variables and init that sets it from an indirect parameter",
                input: """
                struct Dependency {
                    private let dep1: String = 1
                }
                struct Test {
                    private let dep1: String
                    private let dep2: String
                    private let dep3: () -> Void

                    init(dependency: Dependency, dep3: @escaping () -> Void) {
                        self.dep1 = dependency.dep1
                        self.dep2 = dependency.dep2
                        self.dep3 = dep3
                    }
                }
                """,
                expectedOutput: """
                struct Dependency {
                    private let dep1: String = 1
                }
                struct Test {
                    private let dep1: String
                    private let dep2: String
                    private let dep3: () -> Void

                    init(dependency: Dependency, dep3: @escaping () -> Void) {
                        self.dep1 = dependency.dep1
                        self.dep2 = dependency.dep2
                        self.dep3 = dep3
                    }
                }
                """
            ),
            .init(
                context: "has one variable and 3 parameters, one direct and two indirect that are combined",
                input: """
                class Test {
                    private let value1: Int

                    init(value1: Int, value2: Int, value3: Int) {
                        self.value1 = value1 + value2 + value3
                    }
                }
                """,
                expectedOutput: """
                class Test {
                    private let value1: Int

                    init(value1: Int, value2: Int, value3: Int) {
                        self.value1 = value1 + value2 + value3
                    }
                }
                """
            ),
            .init(
                context: "has two variables and two inits that set some variables from an indirect parameter",
                input: """
                class Test {
                    struct Dependency {
                        let dep1: (() -> Void)?
                        let dep2: String

                        init(dep1: (() -> Void)?, dep2: String) {
                            self.dep1 = dep1
                            self.dep2 = dep2
                        }
                    }

                    var dep1: (() -> Void)?
                    var dep2: String

                    init(dep1: Dependency) {
                        self.dep1 = dep1.dep1
                    }

                    init(dependency: Dependency) {
                        self.dep1 = dependency.dep1
                    }
                }
                """,
                expectedOutput: """
                class Test {
                    struct Dependency {
                        let dep1: (() -> Void)?
                        let dep2: String

                        init(dep1: (() -> Void)?, dep2: String) {
                            self.dep1 = dep1
                            self.dep2 = dep2
                        }
                    }

                    var dep1: (() -> Void)?
                    var dep2: String

                    init(dep1: Dependency, dep2: String) {
                        self.dep1 = dep1.dep1
                        self.dep2 = dep2
                    }

                    init(dependency: Dependency, dep2: String) {
                        self.dep1 = dependency.dep1
                        self.dep2 = dep2
                    }
                }
                """
            ),
        ]
        for testCase in testCases {
            let sut = Interlink(configuration: testCase.configuration)
            do {
                let output = try sut.interlink(input: testCase.input)
                XCTAssertEqual(output, testCase.expectedOutput, testCase.context)
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
    }

    func testMakeInitForOptionalVariables() {
        let testCases: [TestCase] = [
            .init(
                context: "has one optional variable, no init",
                input: """
                struct Test {
                    var dep1: (() -> Void)?
                }
                """,
                expectedOutput: """
                struct Test {
                    var dep1: (() -> Void)?
                }
                """
            ),
            .init(
                context: "has two optional variables, init with one set",
                input: """
                struct Test {
                    var dep1: (() -> Void)?
                    fileprivate var dep2: (() -> Void)?

                    init(dep1: (() -> Void)?) {
                        self.dep1 = dep1
                    }
                }
                """,
                expectedOutput: """
                struct Test {
                    var dep1: (() -> Void)?
                    fileprivate var dep2: (() -> Void)?

                    init(dep1: (() -> Void)?) {
                        self.dep1 = dep1
                    }
                }
                """
            ),
            .init(
                context: "has one implicitly unwrapped optional variable, init with the same name but type not unwrapped",
                input: """
                struct Test {
                    var dep1: String!

                    init(dep1: String) {
                        self.dep1 = dep1
                    }
                }
                """,
                expectedOutput: """
                struct Test {
                    var dep1: String!

                    init(dep1: String) {
                        self.dep1 = dep1
                    }
                }
                """
            ),
            .init(
                context: "has one optional variable, init with the same name but type not optional",
                input: """
                struct Test {
                    var dep1: (() -> Void)?

                    init(dep1: @escaping () -> Void) {
                        self.dep1 = dep1
                    }
                }
                """,
                expectedOutput: """
                struct Test {
                    var dep1: (() -> Void)?

                    init(dep1: @escaping () -> Void) {
                        self.dep1 = dep1
                    }
                }
                """
            ),
        ]
        for testCase in testCases {
            let sut = Interlink(configuration: testCase.configuration)
            do {
                let output = try sut.interlink(input: testCase.input)
                XCTAssertEqual(output, testCase.expectedOutput, testCase.context)
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
    }

    func testNestedMembersWithMultipleInits() {
        let testCases: [TestCase] = [
            .init(
                context: "has one nested members, with one variable",
                input: """
                struct Test {
                    struct Test2 {
                        private let dep2: () -> Void
                    }
                    private let dep1: () -> Void
                }
                """,
                expectedOutput: """
                struct Test {
                    struct Test2 {
                        private let dep2: () -> Void

                        init(dep2: @escaping () -> Void) {
                            self.dep2 = dep2
                        }
                    }
                    private let dep1: () -> Void

                    init(dep1: @escaping () -> Void) {
                        self.dep1 = dep1
                    }
                }
                """
            ),
            .init(
                context: "has two nested members, with one variable",
                input: """
                struct Test {
                    struct Test2 {
                        class Test3 {
                            var dep3: String
                        }
                        private let dep2: () -> Void
                    }
                    private let dep1: () -> Void
                }
                """,
                expectedOutput: """
                struct Test {
                    struct Test2 {
                        class Test3 {
                            var dep3: String

                            init(dep3: String) {
                                self.dep3 = dep3
                            }
                        }
                        private let dep2: () -> Void

                        init(dep2: @escaping () -> Void) {
                            self.dep2 = dep2
                        }
                    }
                    private let dep1: () -> Void

                    init(dep1: @escaping () -> Void) {
                        self.dep1 = dep1
                    }
                }
                """
            ),
            .init(
                context: "has nested member placed below variables",
                input: """
                class Test {
                    fileprivate let dep1: String?

                    private let dep2: String

                    private struct Nest {}
                }
                """,
                expectedOutput: """
                class Test {
                    fileprivate let dep1: String?

                    private let dep2: String

                    init(dep1: String?, dep2: String) {
                        self.dep1 = dep1
                        self.dep2 = dep2
                    }

                    private struct Nest {}
                }
                """
            )
        ]
        for testCase in testCases {
            let sut = Interlink(configuration: testCase.configuration)
            do {
                let output = try sut.interlink(input: testCase.input)
                XCTAssertEqual(output, testCase.expectedOutput, testCase.context)
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
    }

    func testMaxLineLengthBreakInInit() {
        let testCases: [TestCase] = [
            .init(
                context: "has init longer then maxLineLength",
                configuration: Configuration(spacesPerTab: 4, maxLineLength: 50),
                input: """
                struct Test {
                    private let dep1: () -> Void
                    var dep2, dep3, dep4, dep5: String
                }
                """,
                expectedOutput: """
                struct Test {
                    private let dep1: () -> Void
                    var dep2, dep3, dep4, dep5: String

                    init(
                        dep1: @escaping () -> Void,
                        dep2: String,
                        dep3: String,
                        dep4: String,
                        dep5: String
                    ) {
                        self.dep1 = dep1
                        self.dep2 = dep2
                        self.dep3 = dep3
                        self.dep4 = dep4
                        self.dep5 = dep5
                    }
                }
                """
            ),
            .init(
                context: "has init shorter then maxLineLength",
                configuration: Configuration(spacesPerTab: 4, maxLineLength: 200),
                input: """
                struct Test {
                    private let dep1: () -> Void
                    var dep2, dep3, dep4, dep5: String
                }
                """,
                expectedOutput: """
                struct Test {
                    private let dep1: () -> Void
                    var dep2, dep3, dep4, dep5: String

                    init(dep1: @escaping () -> Void, dep2: String, dep3: String, dep4: String, dep5: String) {
                        self.dep1 = dep1
                        self.dep2 = dep2
                        self.dep3 = dep3
                        self.dep4 = dep4
                        self.dep5 = dep5
                    }
                }
                """
            ),
        ]
        for testCase in testCases {
            let sut = Interlink(configuration: testCase.configuration)
            do {
                let output = try sut.interlink(input: testCase.input)
                XCTAssertEqual(output, testCase.expectedOutput, testCase.context)
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
    }

    func testHasVariablesAndNoInit() {
        let testCases: [TestCase] = [
            .init(
                context: "has one dependency, no init",
                input: """
                struct Test {
                    private let dep1: () -> Void
                }
                """,
                expectedOutput: """
                struct Test {
                    private let dep1: () -> Void

                    init(dep1: @escaping () -> Void) {
                        self.dep1 = dep1
                    }
                }
                """
            ),
            .init(
                context: "has two dependencies, no init",
                input: """
                struct Test {
                    let dep2: String
                    private let dep1: () -> Void
                }
                """,
                expectedOutput: """
                struct Test {
                    let dep2: String
                    private let dep1: () -> Void

                    init(dep2: String, dep1: @escaping () -> Void) {
                        self.dep2 = dep2
                        self.dep1 = dep1
                    }
                }
                """
            ),
            .init(
                context: "has three dependencies, one preset, no init",
                input: """
                struct Test {
                    let dep2: String
                    private let dep1: () -> Void
                    internal var dep3: String = "Valueeee"
                }
                """,
                expectedOutput: """
                struct Test {
                    let dep2: String
                    private let dep1: () -> Void
                    internal var dep3: String = "Valueeee"

                    init(dep2: String, dep1: @escaping () -> Void) {
                        self.dep2 = dep2
                        self.dep1 = dep1
                    }
                }
                """
            ),
            .init(
                context: "has three dependencies, one preset, no init",
                input: """
                struct Test {
                    let dep2: String
                    private let dep1: () -> Void
                    internal var dep3: String = "Valueeee"
                }
                """,
                expectedOutput: """
                struct Test {
                    let dep2: String
                    private let dep1: () -> Void
                    internal var dep3: String = "Valueeee"

                    init(dep2: String, dep1: @escaping () -> Void) {
                        self.dep2 = dep2
                        self.dep1 = dep1
                    }
                }
                """
            ),
            .init(
                context: "has three dependencies, one preset, one lazy, no init",
                input: """
                struct Test {
                    lazy var dep2: String = "42"
                    private let dep1: () -> Void
                    internal var dep3: String = "42"
                }
                """,
                expectedOutput: """
                struct Test {
                    lazy var dep2: String = "42"
                    private let dep1: () -> Void
                    internal var dep3: String = "42"

                    init(dep1: @escaping () -> Void) {
                        self.dep1 = dep1
                    }
                }
                """
            ),
            .init(
                context: "has four dependencies, two inlined, no init",
                input: """
                struct Test {
                    let dep3, dep4: String
                    private let dep1, dep2: () -> Void
                }
                """,
                expectedOutput: """
                struct Test {
                    let dep3, dep4: String
                    private let dep1, dep2: () -> Void

                    init(dep3: String, dep4: String, dep1: @escaping () -> Void, dep2: @escaping () -> Void) {
                        self.dep3 = dep3
                        self.dep4 = dep4
                        self.dep1 = dep1
                        self.dep2 = dep2
                    }
                }
                """
            ),
        ]
        for testCase in testCases {
            let sut = Interlink(configuration: testCase.configuration)
            do {
                let output = try sut.interlink(input: testCase.input)
                XCTAssertEqual(output, testCase.expectedOutput, testCase.context)
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
    }

    func testHasVariablesAndInit() {
        let testCases: [TestCase] = [
            .init(
                context: "has one dependency and init",
                input: """
                struct Test {
                    private let dep1: () -> Void

                    init(dep1: @escaping () -> Void) {
                        self.dep1 = dep1
                    }
                }
                """,
                expectedOutput: """
                struct Test {
                    private let dep1: () -> Void

                    init(dep1: @escaping () -> Void) {
                        self.dep1 = dep1
                    }
                }
                """
            ),
            .init(
                context: "has one dependency and init with wrong parameter name",
                input: """
                struct Test {
                    private let dep1: () -> Void

                    init(dep2: @escaping () -> Void) {
                        self.dep1 = dep1
                    }
                }
                """,
                expectedOutput: """
                struct Test {
                    private let dep1: () -> Void

                    init(dep1: @escaping () -> Void) {
                        self.dep1 = dep1
                    }
                }
                """
            ),
            .init(
                context: "has one dependency and init with wrong assignment name",
                input: """
                struct Test {
                    private let dep1: () -> Void

                    init(dep1: @escaping () -> Void) {
                        self.dep2 = dep1
                    }
                }
                """,
                expectedOutput: """
                struct Test {
                    private let dep1: () -> Void

                    init(dep1: @escaping () -> Void) {
                        self.dep1 = dep1
                    }
                }
                """
            ),
            .init(
                context: "has one dependency and init with wrong parameter and assignment name",
                input: """
                struct Test {
                    private let dep1: () -> Void

                    init(dep2: @escaping () -> Void) {
                        self.dep3 = dep1
                    }
                }
                """,
                expectedOutput: """
                struct Test {
                    private let dep1: () -> Void

                    init(dep1: @escaping () -> Void) {
                        self.dep1 = dep1
                    }
                }
                """
            ),
            .init(
                context: "has one dependency and init with additional parameters and assignments",
                input: """
                struct Test {
                    private let dep1: () -> Void

                    init(dep2: String?, dep1: @escaping () -> Void) {
                        self.dep3 = dep3
                        self.dep1 = dep1
                    }
                }
                """,
                expectedOutput: """
                struct Test {
                    private let dep1: () -> Void

                    init(dep1: @escaping () -> Void) {
                        self.dep1 = dep1
                    }
                }
                """
            ),
            .init(
                context: "has multiple dependencies and init with correct parameters and assignments, unordered",
                input: """
                struct Test {
                    private let dep1: () -> Void
                    let dep2: (String, Int?)
                    internal let dep3: (() -> Void)?

                    init(dep3: (() -> Void)?, dep2: (String, Int?), dep1: @escaping () -> Void) {
                        self.dep2 = dep2
                        self.dep3 = dep3
                        self.dep1 = dep1
                    }
                }
                """,
                expectedOutput: """
                struct Test {
                    private let dep1: () -> Void
                    let dep2: (String, Int?)
                    internal let dep3: (() -> Void)?

                    init(dep1: @escaping () -> Void, dep2: (String, Int?), dep3: (() -> Void)?) {
                        self.dep1 = dep1
                        self.dep2 = dep2
                        self.dep3 = dep3
                    }
                }
                """
            ),
        ]
        for testCase in testCases {
            let sut = Interlink(configuration: testCase.configuration)
            do {
                let output = try sut.interlink(input: testCase.input)
                XCTAssertEqual(output, testCase.expectedOutput, testCase.context)
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
    }

    func testHasDanglingParametersAndAssignments() {
        let testCases: [TestCase] = [
            .init(
                context: "has dangling parameter and assignemnt, and unset variable",
                input: """
                struct Test {
                    private let dep1: String?

                    init(dep3: Int?) {
                        self.dep2 = dep2
                    }
                }
                """,
                expectedOutput: """
                struct Test {
                    private let dep1: String?

                    init(dep1: String?) {
                        self.dep1 = dep1
                    }
                }
                """
            ),
            .init(
                context: "has multiple dangling parameters and assignemnts, and unset variable",
                input: """
                struct Test {
                    private let dep1: String?

                    init(dep3: Int?, dep2: @escaping () -> Void) {
                        self.dep2 = dep2
                        self.dep4 = dep4
                    }
                }
                """,
                expectedOutput: """
                struct Test {
                    private let dep1: String?

                    init(dep1: String?) {
                        self.dep1 = dep1
                    }
                }
                """
            ),
            .init(
                context: "has multiple dangling parameters and assignments, and one set variable, one unset variable",
                input: """
                struct Test {
                    private let dep1: String?
                    private let dep5: (() -> Void)?

                    init(dep3: Int?, dep2: @escaping () -> Void, dep5: (() -> Void)?) {
                        self.dep2 = dep2
                        self.dep4 = dep4
                        self.dep5 = dep5
                    }
                }
                """,
                expectedOutput: """
                struct Test {
                    private let dep1: String?
                    private let dep5: (() -> Void)?

                    init(dep1: String?, dep5: (() -> Void)?) {
                        self.dep1 = dep1
                        self.dep5 = dep5
                    }
                }
                """
            ),
            .init(
                context: "has multiple dangling parameters and assignments, and one set variable, one unset variable, function calls within init",
                input: """
                class Test {
                    private let dep1: String?
                    private let dep5: (() -> Void)?

                    init(dep3: Int?, dep2: @escaping () -> Void, dep5: (() -> Void)?) {
                        let value = ""
                        self.dep2 = dep2
                        self.dep4 = dep4
                        self.dep5 = dep5

                        configure()
                    }

                    func configure() {}
                }
                """,
                expectedOutput: """
                class Test {
                    private let dep1: String?
                    private let dep5: (() -> Void)?

                    init(dep1: String?, dep5: (() -> Void)?) {
                        self.dep1 = dep1
                        self.dep5 = dep5

                        configure()
                    }

                    func configure() {}
                }
                """
            ),
        ]
        for testCase in testCases {
            let sut = Interlink(configuration: testCase.configuration)
            do {
                let output = try sut.interlink(input: testCase.input)
                XCTAssertEqual(output, testCase.expectedOutput, testCase.context)
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
    }

    func testMiscellaneous() {
        let testCases: [TestCase] = [
            .init(
                context: "has 1 nested member, nested init with incorrect parameter and assignment, nested optional variable",
                input: """
                class Test {
                    struct NestTest {
                        var optionalString: String?
                        var forcedUnwrapString: String!

                        init(optionalLet: (() -> Void)?) {
                            self.optionalLet = optionalLet
                        }
                    }

                    var optionalString: String?

                    init(optionalLet: (() -> Void)?) {
                        self.optionalLet = optionalLet
                    }
                }
                """,
                expectedOutput: """
                class Test {
                    struct NestTest {
                        var optionalString: String?
                        var forcedUnwrapString: String!
                    }

                    var optionalString: String?
                }
                """
            ),
            .init(
                context: "has 2 members, one with nested member, another with incorrect init",
                input: """
                class Test {
                    var optionalString: String?

                    init(
                        dep1: Int?,
                        dep2: String??,
                        dep0: (() -> Void)?,
                    ) {
                        self.random = random
                    }

                    struct NestTest {
                        private let dep1: Int?
                        var forcedUnwrapString: String!
                        open var dep3: String?
                    }
                }

                struct Test2 {
                    private let string: String?

                    init(optionalLet: (() -> Void)?) {
                        self.optionalLet = optionalLet
                    }
                }
                """,
                expectedOutput: """
                class Test {
                    var optionalString: String?

                    struct NestTest {
                        private let dep1: Int?
                        var forcedUnwrapString: String!
                        open var dep3: String?

                        init(dep1: Int?) {
                            self.dep1 = dep1
                        }
                    }
                }

                struct Test2 {
                    private let string: String?

                    init(string: String?) {
                        self.string = string
                    }
                }
                """
            ),
            .init(
                context: "has multiple members, with various configurations",
                input: """
                class Test {
                    var optionalString: String?

                    init(
                        dep1: Int?,
                        dep2: String??,
                        dep0: (() -> Void)?,
                    ) {
                        self.random = random
                    }

                    struct NestTest {
                        private let dep1: Int?
                        var forcedUnwrapString: String!
                        open var dep3: String?
                    }
                }

                struct Test2 {
                    private let string: String?

                    init(optionalLet: (() -> Void)?) {
                        self.optionalLet = optionalLet
                    }
                }

                actor Test3 {

                    init(optionalLet: (() -> Void)?) {
                        self.optionalLet = optionalLet
                    }

                    private struct NestTest {

                        private let dep1: String

                        private class NestNestTest {
                            private var dep1: Int
                        }

                        init(dep2: String) {
                            self.dep2 = dep2
                            configure()
                        }
                    }
                }
                """,
                expectedOutput: """
                class Test {
                    var optionalString: String?

                    struct NestTest {
                        private let dep1: Int?
                        var forcedUnwrapString: String!
                        open var dep3: String?

                        init(dep1: Int?) {
                            self.dep1 = dep1
                        }
                    }
                }

                struct Test2 {
                    private let string: String?

                    init(string: String?) {
                        self.string = string
                    }
                }

                actor Test3 {

                    private struct NestTest {

                        private let dep1: String

                        private class NestNestTest {
                            private var dep1: Int

                            init(dep1: Int) {
                                self.dep1 = dep1
                            }
                        }

                        init(dep1: String) {
                            self.dep1 = dep1
                            configure()
                        }
                    }
                }
                """
            ),

            .init(
                context: "has custom code while loop that modifies a local variable",
                input: """
                class Test {
                    let newVal: String

                    init(newVal: String, computed: String) {
                        var computed = ""
                        var idx = 0
                        while idx < 10 && computed.count < 10 {
                            idx += 1
                            computed += "\\(idx),"
                        }
                        self.newVal = newVal + computed
                        struct Test {

                        }
                    }
                }
                """,
                expectedOutput: """
                class Test {
                    let newVal: String

                    init(newVal: String) {
                        var computed = ""
                        var idx = 0
                        while idx < 10 && computed.count < 10 {
                            idx += 1
                            computed += "\\(idx),"
                        }
                        self.newVal = newVal + computed
                    }
                }
                """
            ),
            .init(
                context: "has multiple computed values & functions",
                input: """
                class Test {
                    var dependency1: String
                    private let dep2: Int

                    init(valuer1: Int, valuer2: Int, computer1: String, computer2: String) {
                        struct Model {
                            let val: String
                        }
                        let val = ""
                        let computedValue = "\\(computer1) + \\(computer2)"
                        self.dependency1 = computedValue
                        func dependencyCompute(valuer1: Int, valuer2: Int) -> Int {
                            return valuer1 + valuer2
                        }
                        self.dep2 = dependencyCompute(valuer1: Model(val: "\\(valuer1)").val, valuer2: valuer2)
                    }
                }
                """,
                expectedOutput: """
                class Test {
                    var dependency1: String
                    private let dep2: Int

                    init(computer1: String, computer2: String, valuer1: Int, valuer2: Int) {
                        let computedValue = "\\(computer1) + \\(computer2)"
                        self.dependency1 = computedValue
                        struct Model {
                            let val: String

                            init(val: String) {
                                self.val = val
                            }
                        }
                        func dependencyCompute(valuer1: Int, valuer2: Int) -> Int {
                            return valuer1 + valuer2
                        }
                        self.dep2 = dependencyCompute(valuer1: Model(val: "\\(valuer1)").val, valuer2: valuer2)
                    }
                }
                """
            ),
            .init(
                context: "has local variable that gets mutated in a conditional statement",
                input: """
                struct Test {
                    typealias Closure = () -> String

                    fileprivate let clos: Closure
                    let value: String

                    init(clos: @escaping Closure, value: String) {
                        print("lolol")
                        self.clos = clos
                        var valuer = value
                        if valuer == "" {
                            valuer = "Margo"
                        }
                        self.value = valuer
                        print("lolol")
                        print("lolol")
                    }
                }
                """,
                expectedOutput: """
                struct Test {
                    typealias Closure = () -> String

                    fileprivate let clos: Closure
                    let value: String

                    init(clos: @escaping Closure, value: String) {
                        print("lolol")
                        self.clos = clos
                        var valuer = value
                        if valuer == "" {
                            valuer = "Margo"
                        }
                        self.value = valuer
                        print("lolol")
                        print("lolol")
                    }
                }
                """
            ),
            .init(
                context: "test",
                input: """
                struct Test {
                    typealias Closure = () -> String
                    let val: String
                    let computer: (() -> String)?
                    init(val2: String, computer: (() -> String)?) {
                        let lol = ""
                        print("asdasd")
                        func val(lol: String) -> String {
                            computer?() ?? ""
                        }
                        self.val = val(lol: val2)
                        self.computer = computer
                    }
                }
                """,
                expectedOutput: """
                struct Test {
                    typealias Closure = () -> String
                    let val: String
                    let computer: (() -> String)?
                    init(val2: String, computer: (() -> String)?) {
                        print("asdasd")
                        func val(lol: String) -> String {
                            computer?() ?? ""
                        }
                        self.val = val(lol: val2)
                        self.computer = computer
                    }
                }
                """
            ),
            .init(
                context: "has custom code at the end",
                input: """
                private struct NestTest {
                    private let dep1: String

                    init(dep2: String) {
                        self.dep2 = dep2
                        configure()
                    }
                }
                """,
                expectedOutput: """
                private struct NestTest {
                    private let dep1: String

                    init(dep1: String) {
                        self.dep1 = dep1
                        configure()
                    }
                }
                """
            ),
            .init(
                context: "has unused assignments that use soon-to-be unused variables and declarations",
                input: """
                private struct Test {
                    private let storedLet: String
                    var storedVar: () -> Void
                    var varWithDidSet: String {
                        willSet {

                        }
                        didSet {

                        }
                    }
                    init(
                        randomParameter: String,
                        varWithDidSet: String,
                        storedVar: @escaping () -> Void
                    ) {
                        struct Model {
                            let value: String

                            init(
                                value: String
                            ) {
                                self.value = value
                            }
                        }
                        print("A side effect function call placed before assignments")
                        let localVariable = randomParameter + "random Value"
                        print("A side effect function call placed in the middle")
                        self.storedVar = storedVar
                        self.varWithDidSet = varWithDidSet
                        print("A side effect function call placed after assignments")
                    }
                }
                """,
                expectedOutput: """
                private struct Test {
                    private let storedLet: String
                    var storedVar: () -> Void
                    var varWithDidSet: String {
                        willSet {

                        }
                        didSet {

                        }
                    }
                    init(
                        storedLet: String,
                        storedVar: @escaping () -> Void,
                        varWithDidSet: String
                    ) {
                        print("A side effect function call placed before assignments")
                        print("A side effect function call placed in the middle")
                        self.storedLet = storedLet
                        self.storedVar = storedVar
                        self.varWithDidSet = varWithDidSet
                        print("A side effect function call placed after assignments")
                    }
                }
                """
            ),
        ]
        for testCase in testCases {
            let sut = Interlink(configuration: testCase.configuration)
            do {
                let output = try sut.interlink(input: testCase.input)
                XCTAssertEqual(output, testCase.expectedOutput, testCase.context)
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
    }

    func testConditionalAssignments() {
        let testCases: [TestCase] = [
            .init(
                context: "has 1 if statement with assignments defined by users",
                input: """
                class Test {
                    let val: String
                    init(newVal: String) {
                        var currentVal = 0
                        while currentVal < 100 {
                            currentVal += 1
                        }
                        if currentVal == 100 {
                            self.val = "\\(currentVal)"
                        } else {
                            self.val = "\\(newVal)"
                        }
                    }
                }
                """,
                expectedOutput: """
                class Test {
                    let val: String
                    init(newVal: String) {
                        var currentVal = 0
                        while currentVal < 100 {
                            currentVal += 1
                        }
                        if currentVal == 100 {
                            self.val = "\\(currentVal)"
                        } else {
                            self.val = "\\(newVal)"
                        }
                    }
                }
                """
            ),
            .init(
                context: "has custom parameter that sets a custom value which sets a variable",
                input: """
                class Test {
                    let storedLet: String

                    init(someValue: String?) {
                        let value: String
                        if let newValue = someValue {
                            value = newValue
                        } else {
                            value = "String"
                        }
                        self.storedLet = value
                    }
                }
                """,
                expectedOutput: """
                class Test {
                    let storedLet: String

                    init(someValue: String?) {
                        let value: String
                        if let newValue = someValue {
                            value = newValue
                        } else {
                            value = "String"
                        }
                        self.storedLet = value
                    }
                }
                """
            ),
        ]
        
        for testCase in testCases {
            let sut = Interlink(configuration: testCase.configuration)
            do {
                let output = try sut.interlink(input: testCase.input)
                XCTAssertEqual(output, testCase.expectedOutput, testCase.context)
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
    }
}
