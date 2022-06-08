//: [Previous](@previous)

import Foundation
import UIKit
import XCTest
//: # Day Four - Mirroring / Reflection
//:
//: We are going to talk about
//: Mirrors (or Reflection) which is a capability of the swift language to be META
//: It means we can get information from the code that composes the classes in runtime
//: And access things like parameter names, types, values, etc.
//:
//: - How can we use reflection to help our tests?
//:
class X {
    var a: Int?
}

final class Builder {
    func build() -> Any {
        let presenter = Presenter()
        let interactor = Interactor(presenter: presenter)
        let controller = Controller(interactor: interactor)

        presenter.controller = controller

        return controller
    }
}
//: Let's try adding tests to this Builder / Configurator
//: > What do you think that would be a nice thing to test in here?
final class BuilderTests: XCTestCase {
    private let sut = Builder()

    func test_returnIsCorrect() {
        let value = sut.build()

        XCTAssertEqual(value is Controller, true)
    }

    func test_build_shouldLinkElementsCorrectly() throws {
        // We are gonna use reflection to access internal properties
        let controller = try XCTUnwrap(sut.build() as? Controller)

        // Mirror struct
        let interactor = try XCTUnwrap(Mirror(reflecting: controller).children.first { $0.label == "interactor" }?.value as? Interactor)

        let presenter = try XCTUnwrap(Mirror(reflecting: interactor).children.first { $0.label == "presenter" }?.value as? Presenter)

        // =   : attribution
        // ==  : function / compared Equatable objects
        // === : Pointer comparison / the same instance
        XCTAssertEqual(presenter.controller === controller, true)
    }

    func test_usingAuxFunction() throws {
        let controller = try XCTUnwrap(sut.build() as? Controller)

        let reflectedInteractor: Interactor? = reflect(from: controller, propertyName: "interactor")
        let interactor = try XCTUnwrap(reflectedInteractor)

        let reflectedResenter: Presenter? = reflect(from: interactor, propertyName: "presenter")
        let presenter = try XCTUnwrap(reflectedResenter)

        XCTAssertEqual(presenter.controller === controller, true)
    }

    // Check this helper method
    func reflect<T>(from item: Any, propertyName: String) -> T? {
        Mirror(reflecting: item)
            .children
            .first { $0.label == propertyName } as? T
    }
}

// Reflectable protocol - enable interoperation between languages
@dynamicMemberLookup
public struct Reflected<Base> {
    private let base: Base

    public init(_ base: Base) {
        self.base = base
    }

    public subscript<T>(dynamicMember label: String) -> T? {
        return reflect(from: self, propertyName: label)
    }

    func reflect<T>(from item: Any, propertyName: String) -> T? {
        Mirror(reflecting: item)
            .children
            .first { $0.label == propertyName } as? T
    }
}

public protocol Reflectable {
    associatedtype Base

    var reflected: Reflected<Base> { get }
}

extension Reflectable {
    public var reflected: Reflected<Self> {
        Reflected(self)
    }
}

extension Controller: Reflectable {}
extension Interactor: Reflectable {}
extension Presenter: Reflectable {}

extension BuilderTests {
    func test_usingReflectable() throws {
        let controller = try XCTUnwrap(sut.build() as? Controller)

        let interactor: Interactor? = controller.reflected.interactor
    }
}
//: > [Testing Gestures and Actions](https://medium.com/macoclock/testing-gestures-and-actions-8235188434f3)
//: [Next](@next)
