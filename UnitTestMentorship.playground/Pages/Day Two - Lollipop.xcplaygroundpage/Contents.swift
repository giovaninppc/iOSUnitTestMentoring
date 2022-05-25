//: [Previous](@previous)
import Foundation
import XCTest
//: # Day 2 - XCTestCase lifecycle
//:
//: - When you run the tests, what actually happens?
final class Test: XCTestCase {
    // This is a test func
    // - If the func does not start with tests: It will not be tested
    // - If the func is private
    func test_() {}
//: Everytime we run a different test function
//: It makes a new instance of the class
//: So, for every new test, it will recreate all the properties you have instantiated on the class.
    var a: Int = 0

    func test_a() {
        a = 1

        XCTAssertEqual(a, 1)
    }
    //: This next test will fail!
    func test_b() {
        XCTAssertEqual(a, 1)
    }
//: Remember from the last day:
//: AAA
//: - Arrange (Repeat every test case!)
//: - Act - what we are testing
//: - Assert - make sure it works
//:
//: Here, we are using a `lazy var` to instatiate the `sut` (Subject Under Tests)
    private var intSpy: Int = 0
    private lazy var sut = Add(
        value: intSpy
    )
//: > This variable (sut) will be instantiated **the first time it's called**!
    func test_c() {
        intSpy = 5

        _ = sut

        // correct
        XCTAssertEqual(sut.value, 5)
    }
}

struct Add {
    let value: Int

    func add(_ newValue: Int) -> Int {
        return value + newValue
    }
}
//: ### Now, let's get into some setUp and tearDown shenanigans
final class Test2: XCTestCase {
    // Lifecycle:
    // - find a test func
    // BEFORE - it calls setUp
    // runs the test
    // AFTER - it calls tearDown

    private let valueProvider = HoldValue.shared
    private lazy var sut = Doug(valueProvider: valueProvider)

    override func setUp() {
        super.setUp()
        valueProvider.value = 10
        // reset static changes
        // make initial state - outside of the test class
    }

    override func tearDown() {
        super.tearDown()
        valueProvider.value = 0 // something like this
        // remove the document
        // undo static changes
    }

    func test_a() {
        valueProvider.value = 30
    }

    func test_b() {
        XCTAssertEqual(valueProvider.value, 10) // Fail
    }
}

// Singleton
// Class or static methods
class HoldValue {
    var value: Int = 10

    static let shared: HoldValue = .init()

    private init() {}
}

struct Doug {
    private let valueProvider: HoldValue

    init(valueProvider: HoldValue = .shared) {
        self.valueProvider = valueProvider
    }
}

//: ## How we can properly create spies for static methods?
protocol StaticProtocol {
    static var value: Int { get }
    // Type property
    // It belongs to the type, not the instance
}

class ValueProvider: StaticProtocol {
    static var value: Int = 10
}

// This is the one we want to test
struct Doug2 {
    private let valueProvider: StaticProtocol.Type

    init(valueProvider: StaticProtocol.Type = ValueProvider.self) {
        self.valueProvider = valueProvider
    }
}

class StaticProtocolSpy: StaticProtocol {
    static var valueToBeReturned: Int = 0
    static var valuePassed: Int?
    static var value: Int {
        get {
            return valueToBeReturned
        } set {
            valuePassed = newValue
        }
    }

    static func reset() {
        valueToBeReturned = 0
        valuePassed = nil
    }
}

final class Doug2Tests: XCTestCase {
    let valueProviderSpy = StaticProtocolSpy.self // STATICALY
    lazy var sut = Doug2(valueProvider: valueProviderSpy)

    override func setUp() {
        super.setUp()
        valueProviderSpy.reset()
    }
}
//: [Next](@next)
