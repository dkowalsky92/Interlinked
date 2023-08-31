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
        storedVar: @escaping () -> Void,
        varWithDidSet: String,
        storedLet: String
    ) {
        print("A side effect function call placed before assignments")
        print("A side effect function call placed in the middle")
        self.storedVar = storedVar
        self.varWithDidSet = varWithDidSet
        self.storedLet = storedLet
        print("A side effect function call placed after assignments")
    }
}

//struct Test {
//    /// Immutable property
//    let storedLet: String
//    /// Mutable property
//    var storedVar: () -> Void /// Non-optional function types will be attributed with @escaping attribute
//    /// Optional property
//    var optionalVar: (() -> Void)? /// Optional values will not be generated, unless defined by the user (you can pass either an assignment or a parameter and run the extension to generate the remaining part)
//    /// Implicit property
//    var implicitVar: (() -> Void)! /// Same as above
//    /// Computed property
//    var computedVar: String { /// Computed values won't be generated
//        "value"
//    }
//    /// Computed property with get/set pair
//    var computedVar2: String { /// Computed values won't be generated
//        get {
//            "value"
//        }
//
//        set {
//
//        }
//    }
//    /// Lazy property
//    lazy var lazyVar: String = { /// Lazy property values won't be generated
//        "value"
//    }()
//    /// Mutable property with didSet/willSet accessors
//    var varWithDidSet: String { /// Will be generated
//        willSet {
//
//        }
//        didSet {
//
//        }
//    }
//    /// In the example below, we will compute the value for `storedLet` within the initializer,
//    /// generate the remaining values that required assignment,
//    /// The extensions will also remove some leftover assignments and declarations (possibly left after removing some stored variable).
//    /// All values will be sorted in the order of stored variables.
//    /// The sideeffect (print call) is assumed to be run after assignments and will be placed right after the generated ones as well.
//    /// Finally, the parameters will be formatted with the currently selected (In a Menu Bar companion App) formatting style.
//    init(
//        randomParameter: String,
//        storedVar: @escaping () -> Void,
//        varWithDidSet: String
//    ) {
//        struct Model {
//            let value: String /// Extension runs for all structs/classes/actors found in the file, so this local struct will also be generated.
//
//            init(
//                value: String
//            ) {
//                self.value = value
//            }
//        }
//        print("A side effect function call placed before assignments")
//        let localVariable = randomParameter + "random Value"
//        print("A side effect function call placed in the middle")
//        //self.storedLet = Model(value: localVariable).value
//        self.storedVar = storedVar
//        self.varWithDidSet = varWithDidSet
//        print("A side effect function call placed after assignments")
//    }
//}
